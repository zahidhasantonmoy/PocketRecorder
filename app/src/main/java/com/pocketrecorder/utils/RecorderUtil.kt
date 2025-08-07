package com.pocketrecorder.utils

import android.content.Context
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object RecorderUtil {

    fun getAudioDirectory(context: Context): File {
        val directory = File(context.filesDir, "audio")
        if (!directory.exists()) {
            directory.mkdirs()
        }
        return directory
    }

    fun getVideoDirectory(context: Context): File {
        val directory = File(context.filesDir, "video")
        if (!directory.exists()) {
            directory.mkdirs()
        }
        return directory
    }

    fun getImageDirectory(context: Context): File {
        val directory = File(context.filesDir, "image")
        if (!directory.exists()) {
            directory.mkdirs()
        }
        return directory
    }

    fun createAudioFile(context: Context): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = getAudioDirectory(context)
        return File.createTempFile("AUDIO_${timeStamp}_", ".mp3", storageDir)
    }

    fun createVideoFile(context: Context): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = getVideoDirectory(context)
        return File.createTempFile("VIDEO_${timeStamp}_", ".mp4", storageDir)
    }

    fun createImageFile(context: Context): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = getImageDirectory(context)
        return File.createTempFile("IMAGE_${timeStamp}_", ".jpg", storageDir)
    }
}
