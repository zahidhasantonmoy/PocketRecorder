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
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
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

    // For sensor data visualization
    companion object {
        private val _currentAcceleration = MutableStateFlow(0f)
        val currentAcceleration: StateFlow<Float> = _currentAcceleration.asStateFlow()

        private val _accelerationHistory = MutableStateFlow<List<Float>>(emptyList())
        val accelerationHistory: StateFlow<List<Float>> = _accelerationHistory.asStateFlow()
    }

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

    private var isTrainingSlap = false
    private val slapTrainingData = mutableListOf<FloatArray>()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        startForeground(1, createNotification())
        accelerometer?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }
        proximitySensor?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }
        rotationVectorSensor?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }

        if (sharedPreferences.getBoolean("voice_command_enabled", false)) {
            voiceUtil.startListening()
        } else {
            voiceUtil.stopListening()
        }

        when (intent?.action) {
            "ACTION_START_SLAP_TRAINING" -> {
                isTrainingSlap = true
                slapTrainingData.clear()
                Log.d("TapDetectionService", "Slap training started.")
            }
            "ACTION_STOP_SLAP_TRAINING" -> {
                isTrainingSlap = false
                Log.d("TapDetectionService", "Slap training stopped. Analyzing data...")
                // Data analysis will happen when ACTION_SAVE_SLAP_PATTERN is called
            }
            "ACTION_SAVE_SLAP_PATTERN" -> {
                analyzeAndSaveSlapPattern()
                Log.d("TapDetectionService", "Slap pattern saved.")
            }
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

        val acceleration = Math.sqrt((x * x + y * y + z * z).toDouble()) - SensorManager.GRAVITY_EARTH
        _currentAcceleration.value = acceleration.toFloat()

        // Update acceleration history for visualization
        val newHistory = _accelerationHistory.value.toMutableList()
        newHistory.add(acceleration.toFloat())
        if (newHistory.size > 100) { // Keep last 100 data points for visualization
            newHistory.removeAt(0)
        }
        _accelerationHistory.value = newHistory

        if (isTrainingSlap) {
            slapTrainingData.add(floatArrayOf(x, y, z))
            Log.d("TapDetectionService", "Training data added: %.2f".format(acceleration))
            return // Don't process as a tap during training
        }

        // Slap detection
        val savedSlapPeakAcceleration = sharedPreferences.getFloat("slap_peak_acceleration", 0f)
        if (savedSlapPeakAcceleration > 0 && acceleration > savedSlapPeakAcceleration * 0.8 && acceleration < savedSlapPeakAcceleration * 1.2) { // Within 20% tolerance
            Log.d("TapDetectionService", "Slap detected! Triggering audio recording.")
            startAudioRecording()
            return
        }

        val sensitivity = sharedPreferences.getString("sensitivity", "medium")
        val threshold = when (sensitivity) {
            "low" -> 8
            "medium" -> 12
            "high" -> 16
            else -> 12
        }

        if (acceleration > threshold) {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastTapTime > 1000) { // 1-second threshold for a new sequence
                tapCount = 0
                Log.d("PocketRecorder", "Tap sequence reset due to timeout.")
            }
            lastTapTime = currentTime
            tapCount++
            Log.d("PocketRecorder", "Acceleration: %.2f, Tap Count: %d".format(acceleration, tapCount))

            if (shouldTriggerAction()) {
                Log.d("PocketRecorder", "Should trigger action is true. Current tap count: $tapCount")
                handleTapAction()
            } else {
                Log.d("PocketRecorder", "Should trigger action is false. isDeviceInPocket: $isDeviceInPocket, isDeviceUpright: $isDeviceUpright")
            }
        }
    }

    private fun analyzeAndSaveSlapPattern() {
        if (slapTrainingData.isEmpty()) {
            Log.d("TapDetectionService", "No slap training data to analyze.")
            return
        }

        val accelerations = mutableListOf<Float>()
        for (data in slapTrainingData) {
            val x = data[0]
            val y = data[1]
            val z = data[2]
            val acceleration = Math.sqrt((x * x + y * y + z * z).toDouble()) - SensorManager.GRAVITY_EARTH
            accelerations.add(acceleration.toFloat())
        }

        // Simple approach: store the average of the top N peaks, or just the top peak
        // For now, let's just store the max acceleration as a float
        val maxAcceleration = accelerations.maxOrNull() ?: 0f

        sharedPreferences.edit().putFloat("slap_peak_acceleration", maxAcceleration).apply()
        Log.d("TapDetectionService", "Slap pattern saved with peak acceleration: %.2f".format(maxAcceleration))
        slapTrainingData.clear()
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