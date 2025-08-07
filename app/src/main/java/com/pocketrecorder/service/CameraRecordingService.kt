package com.pocketrecorder.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleService
import androidx.lifecycle.lifecycleScope
import com.google.common.util.concurrent.ListenableFuture
import com.pocketrecorder.R
import com.pocketrecorder.utils.RecorderUtil
import kotlinx.coroutines.launch
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class CameraRecordingService : LifecycleService() {

    private lateinit var cameraExecutor: ExecutorService
    private var imageCapture: ImageCapture? = null
    private var videoCapture: VideoCapture<Recorder>? = null
    private var recording: Recording? = null
    private lateinit var cameraProviderFuture: ListenableFuture<ProcessCameraProvider>

    override fun onCreate() {
        super.onCreate()
        cameraExecutor = Executors.newSingleThreadExecutor()
        cameraProviderFuture = ProcessCameraProvider.getInstance(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        startForeground(2, createNotification())

        when (intent?.action) {
            ACTION_START_VIDEO_RECORDING -> startVideoRecording()
            ACTION_CAPTURE_IMAGE -> captureImage()
            ACTION_STOP_VIDEO_RECORDING -> stopVideoRecording()
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent): IBinder? {
        super.onBind(intent)
        return null
    }

    private fun createNotification(): Notification {
        val channelId = "camera_recording_channel"
        val channelName = "Camera Recording"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("PocketRecorder")
            .setContentText("Camera recording in progress...")
            .setSmallIcon(R.drawable.ic_launcher_foreground) // Replace with your app's icon
            .build()
    }

    private fun startVideoRecording() {
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            val preview = Preview.Builder().build()
            val recorder = Recorder.Builder()
                .setQualitySelector(androidx.camera.video.QualitySelector.from(androidx.camera.video.Quality.HIGHEST))
                .build()
            videoCapture = VideoCapture.withOutput(recorder)

            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

            try {
                cameraProvider.unbindAll()
                val camera = cameraProvider.bindToLifecycle(this, cameraSelector, preview, videoCapture)

                val videoFile = RecorderUtil.createVideoFile(applicationContext)
                val outputOptions = FileOutputOptions.Builder(videoFile).build()

                recording = videoCapture!!.output
                    .prepareRecording(this, outputOptions)
                    .withAudioEnabled()
                    .start(ContextCompat.getMainExecutor(this)) { recordEvent ->
                        // Handle recording events here
                        Log.d(TAG, "Video recording event: $recordEvent")
                    }
                Log.d(TAG, "Video recording started: ${videoFile.absolutePath}")

                // Stop recording after a certain duration (e.g., from shared preferences)
                val sharedPreferences = applicationContext.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)
                val videoDuration = sharedPreferences.getInt("video_duration", 30) // Default to 30 seconds
                lifecycleScope.launch {
                    kotlinx.coroutines.delay(videoDuration * 1000L)
                    stopVideoRecording()
                }

            } catch (exc: Exception) {
                Log.e(TAG, "Error starting video recording", exc)
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun stopVideoRecording() {
        recording?.stop()
        recording = null
        Log.d(TAG, "Video recording stopped.")
    }

    private fun captureImage() {
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            val imageCapture = ImageCapture.Builder().build()

            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(this, cameraSelector, imageCapture)

                val imageFile = RecorderUtil.createImageFile(applicationContext)
                val outputOptions = ImageCapture.OutputFileOptions.Builder(imageFile).build()

                imageCapture.takePicture(
                    outputOptions,
                    ContextCompat.getMainExecutor(this),
                    object : ImageCapture.OnImageSavedCallback {
                        override fun onError(exc: ImageCaptureException) {
                            Log.e(TAG, "Photo capture failed: ${exc.message}", exc)
                        }

                        override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                            val msg = "Photo capture succeeded: ${imageFile.absolutePath}"
                            Log.d(TAG, msg)
                        }
                    }
                )
            } catch (exc: Exception) {
                Log.e(TAG, "Error capturing image", exc)
            }
        }, ContextCompat.getMainExecutor(this))
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
        recording?.stop()
        stopForeground(true)
    }

    companion object {
        private const val TAG = "CameraRecordingService"
        const val ACTION_START_VIDEO_RECORDING = "com.pocketrecorder.ACTION_START_VIDEO_RECORDING"
        const val ACTION_CAPTURE_IMAGE = "com.pocketrecorder.ACTION_CAPTURE_IMAGE"
        const val ACTION_STOP_VIDEO_RECORDING = "com.pocketrecorder.ACTION_STOP_VIDEO_RECORDING"
    }
}
