package com.example.pocketrecorder

import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.IBinder
import android.util.Log
import kotlin.math.sqrt

class TapDetectionService : Service(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null

    private var lastTapTime: Long = 0
    private var tapCount: Int = 0

    // Customizable settings (will be loaded from SharedPreferences)
    private var sensitivityThreshold: Float = 10f // m/s^2
    private var timeWindow: Long = 1000 // milliseconds

    override fun onCreate() {
        super.onCreate()
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        accelerometer?.let { 
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
        loadSettings()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // TODO: Implement foreground service notification
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]

            val acceleration = sqrt((x * x + y * y + z * z).toDouble()).toFloat()

            if (acceleration > sensitivityThreshold) {
                val currentTime = System.currentTimeMillis()
                if (currentTime - lastTapTime < timeWindow) {
                    tapCount++
                } else {
                    tapCount = 1 // Reset count if outside time window
                }
                lastTapTime = currentTime

                Log.d("TapDetectionService", "Tap detected! Count: $tapCount, Acceleration: $acceleration")

                // TODO: Trigger actions based on tapCount (e.g., start recording)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used for accelerometer
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
    }
}