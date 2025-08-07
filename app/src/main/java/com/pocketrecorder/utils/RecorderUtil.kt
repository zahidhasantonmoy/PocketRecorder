package com.pocketrecorder.utils

import android.content.Context
import androidx.security.crypto.EncryptedFile
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
        val file = File.createTempFile("AUDIO_${timeStamp}_", ".mp3", storageDir)
        val sharedPreferences = context.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)
        return if (sharedPreferences.getBoolean("encryption", true)) {
            SecurityUtil.getEncryptedFile(context, file).let { encryptedFile ->
                // The EncryptedFile object doesn't directly expose the underlying file,
                // so we have to return the original file for now. The encryption will be
                // handled when writing to the file's output stream.
                file
            }
        } else {
            file
        }
    }

    fun createVideoFile(context: Context): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = getVideoDirectory(context)
        val file = File.createTempFile("VIDEO_${timeStamp}_", ".mp4", storageDir)
        val sharedPreferences = context.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)
        return if (sharedPreferences.getBoolean("encryption", true)) {
            SecurityUtil.getEncryptedFile(context, file)
            file
        } else {
            file
        }
    }

    fun createImageFile(context: Context): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = getImageDirectory(context)
        val file = File.createTempFile("IMAGE_${timeStamp}_", ".jpg", storageDir)
        val sharedPreferences = context.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)
        return if (sharedPreferences.getBoolean("encryption", true)) {
            SecurityUtil.getEncryptedFile(context, file)
            file
        } else {
            file
        }
    }
}