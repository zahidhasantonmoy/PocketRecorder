package com.pocketrecorder.utils

import android.content.Context
import android.net.Uri
import android.os.Environment
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object RecorderUtil {

    private fun getBaseDocumentFile(context: Context): DocumentFile? {
        val sharedPreferences = context.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)
        val customSaveLocationUriString = sharedPreferences.getString("custom_save_location", null)

        return if (!customSaveLocationUriString.isNullOrEmpty()) {
            val treeUri = Uri.parse(customSaveLocationUriString)
            DocumentFile.fromTreeUri(context, treeUri)
        } else {
            // Fallback to public Downloads directory if no custom URI is set
            val baseDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val pocketRecorderDir = File(baseDir, "PocketRecorder")
            if (!pocketRecorderDir.exists()) {
                pocketRecorderDir.mkdirs()
            }
            DocumentFile.fromFile(pocketRecorderDir)
        }
    }

    private fun getOrCreateDirectory(context: Context, parent: DocumentFile?, directoryName: String): DocumentFile? {
        if (parent == null) return null
        var directory = parent.findFile(directoryName)
        if (directory == null || !directory.exists() || !directory.isDirectory) {
            directory = parent.createDirectory(directoryName)
        }
        return directory
    }

    fun getAudioDirectory(context: Context): DocumentFile? {
        return getOrCreateDirectory(context, getBaseDocumentFile(context), "Audio")
    }

    fun getVideoDirectory(context: Context): DocumentFile? {
        return getOrCreateDirectory(context, getBaseDocumentFile(context), "Video")
    }

    fun getImageDirectory(context: Context): DocumentFile? {
        return getOrCreateDirectory(context, getBaseDocumentFile(context), "Image")
    }

    fun createAudioFile(context: Context): DocumentFile? {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = getAudioDirectory(context)
        val fileName = "AUDIO_${timeStamp}.mp3"
        val file = storageDir?.createFile("audio/mpeg", fileName)
        Log.d("RecorderUtil", "Created audio DocumentFile: ${file?.uri}, exists: ${file?.exists()}")
        return file
    }

    fun createVideoFile(context: Context): DocumentFile? {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = getVideoDirectory(context)
        val fileName = "VIDEO_${timeStamp}.mp4"
        val file = storageDir?.createFile("video/mp4", fileName)
        Log.d("RecorderUtil", "Created video DocumentFile: ${file?.uri}, exists: ${file?.exists()}")
        return file
    }

    fun createImageFile(context: Context): DocumentFile? {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = getImageDirectory(context)
        val fileName = "IMAGE_${timeStamp}.jpg"
        val file = storageDir?.createFile("image/jpeg", fileName)
        Log.d("RecorderUtil", "Created image DocumentFile: ${file?.uri}, exists: ${file?.exists()}")
        return file
    }
}