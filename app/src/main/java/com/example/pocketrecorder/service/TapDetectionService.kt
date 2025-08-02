package com.example.pocketrecorder.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.pocketrecorder.ActionType
import com.example.pocketrecorder.R
import com.example.pocketrecorder.data.AppDatabase
import com.example.pocketrecorder.data.RecordedFile
import com.example.pocketrecorder.security.FileEncryptionManager
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import kotlin.math.sqrt

class TapDetectionService : Service(), SensorEventListener {

    private val CHANNEL_ID = "PocketRecorderServiceChannel"
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var proximitySensor: Sensor? = null
    private var orientationSensor: Sensor? = null
    private lateinit var vibrator: Vibrator
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var db: AppDatabase
    private lateinit var fileEncryptionManager: FileEncryptionManager

    // Sensor states
    private var isNear: Boolean = false
    private var isUpright: Boolean = false

    // Tap detection variables
    private var sensitivityThreshold: Float = 10f // m/s^2
    private var timeWindow: Long = 1000 // milliseconds
    private var lastTapTime: Long = 0L
    private var tapCount: Int = 0
    private var lastX: Float = 0f
    private var lastY: Float = 0f
    private var lastZ: Float = 0f
    private var isFirstShake: Boolean = true

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        proximitySensor = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
        orientationSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ORIENTATION)

        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
        proximitySensor?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
        orientationSensor?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }

        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        db = AppDatabase.getDatabase(this)
        fileEncryptionManager = FileEncryptionManager(this)
        loadSettings()
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("PocketRecorder")
            .setContentText("Tap detection service is running")
            .setSmallIcon(R.mipmap.ic_launcher_round) // Use a suitable icon
            .build()

        startForeground(1, notification)

        return START_STICKY
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event?.let {
            when (it.sensor.type) {
                Sensor.TYPE_ACCELEROMETER -> {
                    val x = it.values[0]
                    val y = it.values[1]
                    val z = it.values[2]

                    if (isFirstShake) {
                        lastX = x
                        lastY = y
                        lastZ = z
                        isFirstShake = false
                    }

                    val deltaX = x - lastX
                    val deltaY = y - lastY
                    val deltaZ = z - lastZ

                    lastX = x
                    lastY = y
                    lastZ = z

                    val acceleration = sqrt((deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ).toDouble()).toFloat()

                    if (acceleration > sensitivityThreshold) {
                        val currentTime = System.currentTimeMillis()
                        if (currentTime - lastTapTime < timeWindow) {
                            tapCount++
                        } else {
                            tapCount = 1 // Start a new tap sequence
                        }
                        lastTapTime = currentTime
                        Log.d("TapDetectionService", "Tap detected! Tap count: $tapCount")
                        handleTapAction(tapCount)
                    }
                }
                Sensor.TYPE_PROXIMITY -> {
                    isNear = it.values[0] < proximitySensor?.maximumRange ?: 0f
                    Log.d("TapDetectionService", "Proximity: isNear=$isNear")
                }
                Sensor.TYPE_ORIENTATION -> {
                    // Orientation sensor values: azimuth, pitch, roll
                    // For simplicity, we'll consider it upright if pitch and roll are within a certain range
                    val pitch = it.values[1] // Rotation around X-axis
                    val roll = it.values[2] // Rotation around Y-axis
                    isUpright = pitch > -45 && pitch < 45 && roll > -45 && roll < 45
                    Log.d("TapDetectionService", "Orientation: isUpright=$isUpright (pitch=$pitch, roll=$roll)")
                }
                else -> {
                    // Do nothing for other sensor types
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used for accelerometer
    }

    private fun handleTapAction(count: Int) {
        if (!isNear || !isUpright) {
            Log.d("TapDetectionService", "Conditions not met: isNear=$isNear, isUpright=$isUpright. Resetting tap count.")
            tapCount = 0
            return
        }

        val action = when (count) {
            2 -> ActionType.IMAGE_CAPTURE
            3 -> ActionType.AUDIO_RECORDING
            4 -> ActionType.VIDEO_RECORDING
            5 -> ActionType.EMERGENCY_MODE
            else -> ActionType.NONE
        }

        if (action != ActionType.NONE) {
            Log.d("TapDetectionService", "Triggering action: $action")
            // Vibrate to confirm action
            val notificationEnabled = sharedPreferences.getBoolean("notification_enabled", true)
            if (notificationEnabled) {
                val startVibrationPattern = sharedPreferences.getString("start_vibration_pattern", "short")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    when (startVibrationPattern) {
                        "short" -> vibrator.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE))
                        "long" -> vibrator.vibrate(VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE))
                        else -> vibrator.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE))
                    }
                } else {
                    @Suppress("DEPRECATION")
                    when (startVibrationPattern) {
                        "short" -> vibrator.vibrate(100)
                        "long" -> vibrator.vibrate(500)
                        else -> vibrator.vibrate(100)
                    }
                }
            }

            // Get location and save to database
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                fusedLocationClient.lastLocation
                    .addOnSuccessListener { location: Location? ->
                        val currentTime = System.currentTimeMillis()
                        val fileExtension = when (action) {
                            ActionType.IMAGE_CAPTURE -> ".jpg"
                            ActionType.AUDIO_RECORDING -> ".mp3"
                            ActionType.VIDEO_RECORDING -> ".mp4"
                            else -> ".bin"
                        }
                        val directory = File(filesDir, action.name.toLowerCase())
                        if (!directory.exists()) directory.mkdirs()
                        val originalFile = File(directory, "recording_${currentTime}${fileExtension}")
                        FileOutputStream(originalFile).use { it.write("This is a dummy recording.".toByteArray()) }

                        val encryptedFilePath = File(directory, "encrypted_recording_${currentTime}${fileExtension}.enc").absolutePath
                        val encryptedFile = File(encryptedFilePath)
                        fileEncryptionManager.encryptFile(originalFile, encryptedFile)
                        originalFile.delete() // Delete original unencrypted file
                        Log.d("TapDetectionService", "Dummy file encrypted to ${encryptedFile.absolutePath}")

                        val recordedFile = RecordedFile(
                            filePath = encryptedFilePath,
                            fileType = action.name,
                            timestamp = currentTime,
                            latitude = location?.latitude,
                            longitude = location?.longitude,
                            isEncrypted = true
                        )
                        CoroutineScope(Dispatchers.IO).launch {
                            db.recordedFileDao().insertRecordedFile(recordedFile)
                            Log.d("TapDetectionService", "Recorded file metadata saved: $recordedFile")
                        }
                    .addOnFailureListener { e ->
                        Log.e("TapDetectionService", "Failed to get location: ${e.message}")
                    }
            } else {
                Log.w("TapDetectionService", "Location permissions not granted. Cannot save location metadata.")
            }

            // Reset tap count after action is triggered
            tapCount = 0
        } else {
            // Do nothing if action is NONE
        }
    }

    private fun loadSettings() {
        val sharedPreferences = getSharedPreferences("PocketRecorderSettings", Context.MODE_PRIVATE)
        sensitivityThreshold = sharedPreferences.getFloat("sensitivity_threshold", 10f)
        timeWindow = sharedPreferences.getLong("time_window", 1000L)
        Log.d("TapDetectionService", "Settings loaded: sensitivityThreshold=$sensitivityThreshold, timeWindow=$timeWindow")
    }

    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(this)
        stopForeground(true)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "PocketRecorder Service Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}