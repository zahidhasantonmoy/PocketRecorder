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
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.pocketrecorder.ActionType
import com.example.pocketrecorder.R

class TapDetectionService : Service(), SensorEventListener {

    private val CHANNEL_ID = "PocketRecorderServiceChannel"
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var proximitySensor: Sensor? = null
    private var orientationSensor: Sensor? = null
    private lateinit var vibrator: Vibrator

    // Sensor states
    private var isNear: Boolean = false
    private var isUpright: Boolean = false

    // Tap detection variables
    private val ACCELERATION_THRESHOLD = 10.0f // m/s^2, adjust as needed
    private val TAP_TIME_WINDOW_MS = 1000L // 1 second
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

                    val acceleration = Math.sqrt((deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ).toDouble()).toFloat()

                    if (acceleration > ACCELERATION_THRESHOLD) {
                        val currentTime = System.currentTimeMillis()
                        if (currentTime - lastTapTime < TAP_TIME_WINDOW_MS) {
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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(100)
            }
            // Reset tap count after action is triggered
            tapCount = 0
        }
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