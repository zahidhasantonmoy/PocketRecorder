package com.pocketrecorder.data

import android.content.Context
import androidx.documentfile.provider.DocumentFile
import com.pocketrecorder.utils.RecorderUtil
import java.io.File

class FileRepository(private val context: Context) {

    fun getRecordedFiles(): List<DocumentFile> {
        val audioDir = RecorderUtil.getAudioDirectory(context)
        val videoDir = RecorderUtil.getVideoDirectory(context)
        val imageDir = RecorderUtil.getImageDirectory(context)

        val audioFiles = audioDir?.listFiles()?.toList() ?: emptyList()
        val videoFiles = videoDir?.listFiles()?.toList() ?: emptyList()
        val imageFiles = imageDir?.listFiles()?.toList() ?: emptyList()

        return audioFiles + videoFiles + imageFiles
    }

    fun deleteFile(file: DocumentFile): Boolean {
        return file.delete()
    }
}
