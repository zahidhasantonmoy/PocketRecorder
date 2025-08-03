package com.pocketrecorder.utils

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object RecorderUtil {

    fun createAudioFile(context: Context): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val audioDir = File(context.filesDir, "audio")
        if (!audioDir.exists()) {
            audioDir.mkdirs()
        }
        return File(audioDir, "audio_$timeStamp.mp3")
    }

    fun createVideoFile(context: Context): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val videoDir = File(context.filesDir, "video")
        if (!videoDir.exists()) {
            videoDir.mkdirs()
        }
        return File(videoDir, "video_$timeStamp.mp4")
    }

    fun createImageFile(context: Context): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val imageDir = File(context.filesDir, "image")
        if (!imageDir.exists()) {
            imageDir.mkdirs()
        }
        return File(imageDir, "image_$timeStamp.jpg")
    }
}