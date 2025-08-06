package com.pocketrecorder.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.telephony.SmsManager
import android.util.Log
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.NotificationCompat
import androidx.lifecycle.LifecycleService
import androidx.lifecycle.lifecycleScope
import androidx.work.Constraints
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.pocketrecorder.R
import com.pocketrecorder.data.AppDatabase
import com.pocketrecorder.data.Contact
import com.pocketrecorder.data.Location as AppLocation
import com.pocketrecorder.utils.CameraUtil
import com.pocketrecorder.utils.RecorderUtil

import com.pocketrecorder.utils.VoiceUtil
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.IOException
import java.util.concurrent.TimeUnit

class TapDetectionService : LifecycleService(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var proximitySensor: Sensor? = null
    private var rotationVectorSensor: Sensor? = null

    private var tapCount = 0
    private var lastTapTime: Long = 0

    private var isDeviceUpright = false
    private var isDeviceInPocket = false

    private lateinit var sharedPreferences: SharedPreferences

    private var mediaRecorder: MediaRecorder? = null
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var voiceUtil: VoiceUtil

    override fun onCreate() {
        super.onCreate()
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        proximitySensor = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
        rotationVectorSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        sharedPreferences = applicationContext.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(applicationContext)
        voiceUtil = VoiceUtil(applicationContext) { command ->
            handleVoiceCommand(command)
        }

        scheduleFileCleanupWorker()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        startForeground(1, createNotification())
        sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)
        sensorManager.registerListener(this, proximitySensor, SensorManager.SENSOR_DELAY_NORMAL)
        sensorManager.registerListener(this, rotationVectorSensor, SensorManager.SENSOR_DELAY_NORMAL)

        if (sharedPreferences.getBoolean("voice_command_enabled", false)) {
            voiceUtil.startListening()
        } else {
            voiceUtil.stopListening()
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent): IBinder? {
        super.onBind(intent)
        return null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        when (event?.sensor?.type) {
            Sensor.TYPE_ACCELEROMETER -> {
                handleAccelerometerEvent(event)
            }
            Sensor.TYPE_PROXIMITY -> {
                isDeviceInPocket = event.values[0] < proximitySensor?.maximumRange!!
            }
            Sensor.TYPE_ROTATION_VECTOR -> {
                val rotationMatrix = FloatArray(9)
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
                val orientationAngles = FloatArray(3)
                SensorManager.getOrientation(rotationMatrix, orientationAngles)
                val pitch = Math.toDegrees(orientationAngles[1].toDouble())
                isDeviceUpright = pitch > -45 && pitch < 45
            }
        }
    }

    private fun handleAccelerometerEvent(event: SensorEvent) {
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]

        val sensitivity = sharedPreferences.getString("sensitivity", "medium")
        val threshold = when (sensitivity) {
            "low" -> 8
            "medium" -> 12
            "high" -> 16
            else -> 12
        }

        val acceleration = Math.sqrt((x * x + y * y + z * z).toDouble()) - SensorManager.GRAVITY_EARTH

        if (acceleration > threshold) {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastTapTime > 1000) { // 1-second threshold
                tapCount = 0
            }
            lastTapTime = currentTime

            if (acceleration > threshold) { // Only increment if acceleration is above threshold
                tapCount++
            }

            if (shouldTriggerAction() && tapCount > 0) { // Only trigger if there are taps
                handleTapAction()
                tapCount = 0 // Reset tap count after action
            }
        }
    }

    private fun shouldTriggerAction(): Boolean {
        val pocketMode = sharedPreferences.getBoolean("pocket_mode", true)
        val uprightMode = sharedPreferences.getBoolean("upright_mode", true)

        return (!pocketMode || isDeviceInPocket) && (!uprightMode || isDeviceUpright)
    }

    private fun handleTapAction() {
        val audioTaps = sharedPreferences.getInt("audio_taps", 3)
        val videoTaps = sharedPreferences.getInt("video_taps", 4)
        val imageTaps = sharedPreferences.getInt("image_taps", 2)
        val emergencyTaps = sharedPreferences.getInt("emergency_taps", 5)

        when (tapCount) {
            audioTaps -> {
                startAudioRecording()
            }
            videoTaps -> {
                startVideoRecording()
            }
            imageTaps -> {
                captureImage()
            }
            emergencyTaps -> {
                triggerEmergencyMode()
            }
        }
    }

    private fun startAudioRecording() {
        if (mediaRecorder != null) {
            stopAudioRecording()
        }
        mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(applicationContext)
        } else {
            MediaRecorder()
        }
        mediaRecorder?.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            val audioFile = RecorderUtil.createAudioFile(applicationContext)
            setOutputFile(audioFile.absolutePath)
            try {
                prepare()
                start()
                saveLocation()
                updateNotification("Audio recording started.")
                // Stop recording after 30 seconds to prevent excessively long recordings
                val recordingDuration = sharedPreferences.getInt("recording_duration", 30) // Default to 30 seconds
                lifecycleScope.launch {
                    kotlinx.coroutines.delay(recordingDuration * 1000L) // Convert seconds to milliseconds
                    stopAudioRecording()
                }
            } catch (e: IOException) {
                Log.e("PocketRecorder", "Error starting audio recording", e)
            }
        }
    }

    private fun saveLocation() {
        if (checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                location?.let {
                    lifecycleScope.launch(Dispatchers.IO) {
                        val appLocation = AppLocation(latitude = it.latitude, longitude = it.longitude, timestamp = System.currentTimeMillis())
                        AppDatabase.getDatabase(applicationContext).locationDao().insert(appLocation)
                        Log.d("PocketRecorder", "Location saved: ${it.latitude}, ${it.longitude}")
                    }
                }
            }
        } else {
            Log.e("PocketRecorder", "Location permission not granted. Cannot save location.")
        }
    }

    private fun stopAudioRecording() {
        mediaRecorder?.apply {
            stop()
            release()
            updateNotification("Audio recording stopped.")
        }
        mediaRecorder = null
    }

    private fun startVideoRecording() {
        val videoFile = RecorderUtil.createVideoFile(applicationContext)
        CameraUtil.startRecordingVideo(applicationContext, this, videoFile) {
            // Handle video recorded callback
            saveLocation()
            updateNotification("Video recording started.")
        }
    }

    private fun stopVideoRecording() {
        CameraUtil.stopRecordingVideo()
        updateNotification("Video recording stopped.")
    }

    private fun captureImage() {
        val imageFile = RecorderUtil.createImageFile(applicationContext)
        CameraUtil.captureImage(applicationContext, this, imageFile) {
            // Handle image captured callback
            saveLocation()
            updateNotification("Image captured.")
        }
    }

    private fun triggerEmergencyMode() {
        lifecycleScope.launch(Dispatchers.IO) {
            val contacts = AppDatabase.getDatabase(applicationContext).contactDao().getAllContacts()
            if (checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                    location?.let {
                        val message = "Emergency! My location is: Lat ${it.latitude}, Lon ${it.longitude}"
                        if (checkSelfPermission(android.Manifest.permission.SEND_SMS) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                            val smsManager = SmsManager.getDefault()
                            contacts.forEach { contact ->
                                smsManager.sendTextMessage(contact.phoneNumber, null, message, null, null)
                            }
                        } else {
                            Log.e("PocketRecorder", "SMS permission not granted for emergency mode.")
                        }
                    }
                }
            } else {
                Log.e("PocketRecorder", "Location permission not granted for emergency mode.")
            }
        }
    }

    private fun handleVoiceCommand(command: String) {
        val passphrase = sharedPreferences.getString("voice_passphrase", "start recording")
        if (command.contains(passphrase!!, ignoreCase = true)) {
            startAudioRecording() // Example action
        }
    }

    private fun scheduleFileCleanupWorker() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
            .build()

        val cleanupRequest = PeriodicWorkRequestBuilder<com.pocketrecorder.worker.FileCleanupWorker>(
            1, TimeUnit.DAYS)
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(applicationContext).enqueue(cleanupRequest)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun createNotification(message: String = "Actively listening for tap patterns."): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("tap_detection", "Tap Detection", NotificationManager.IMPORTANCE_DEFAULT)
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, "tap_detection")
            .setContentTitle(getString(R.string.app_name))
            .setContentText(message)
            .build()
    }

    private fun updateNotification(message: String) {
        val notification = createNotification(message)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(1, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(this)
        stopAudioRecording()
        stopVideoRecording()
        // No explicit stop for image capture needed as it's a single shot
    }
}