package com.pocketrecorder.utils

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.io.File
import java.util.concurrent.Executor

object CameraUtil {

    private var recording: Recording? = null

    fun startRecordingVideo(
        context: Context,
        lifecycleOwner: LifecycleOwner,
        outputFile: File,
        onVideoRecorded: (Uri?) -> Unit
    ) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            onVideoRecorded(null)
            return
        }

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder().build()
            val recorder = Recorder.Builder().setQualitySelector(androidx.camera.video.QualitySelector.from(androidx.camera.video.Quality.HD)).build()
            val videoCapture = VideoCapture.withOutput(recorder)

            try {
                cameraProvider.unbindAll()
                val camera = cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    preview,
                    videoCapture
                )

                val mediaStoreOutputOptions = FileOutputOptions.Builder(outputFile).build()
                recording = videoCapture.output
                    .prepareRecording(context, mediaStoreOutputOptions)
                    .withAudioEnabled()
                    .start(ContextCompat.getMainExecutor(context)) { recordEvent ->
                        // Handle record event
                    }
                onVideoRecorded(Uri.fromFile(outputFile))

            } catch (exc: Exception) {
                onVideoRecorded(null)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    fun stopRecordingVideo() {
        recording?.stop()
        recording = null
    }

    fun captureImage(
        context: Context,
        lifecycleOwner: LifecycleOwner,
        outputFile: File,
        onImageCaptured: (Uri?) -> Unit
    ) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            onImageCaptured(null)
            return
        }

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder().build()
            val imageCapture = ImageCapture.Builder().build()

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    preview,
                    imageCapture
                )

                val outputFileOptions = ImageCapture.OutputFileOptions.Builder(outputFile).build()
                imageCapture.takePicture(
                    outputFileOptions,
                    ContextCompat.getMainExecutor(context),
                    object : ImageCapture.OnImageSavedCallback {
                        override fun onError(exception: ImageCaptureException) {
                            onImageCaptured(null)
                        }

                        override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                            onImageCaptured(outputFileResults.savedUri)
                        }
                    }
                )

            } catch (exc: Exception) {
                onImageCaptured(null)
            }
        }, ContextCompat.getMainExecutor(context))
    }
}