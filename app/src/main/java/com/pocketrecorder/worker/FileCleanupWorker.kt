package com.pocketrecorder.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import java.io.File

class FileCleanupWorker(appContext: Context, workerParams: WorkerParameters) :
    CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val context = applicationContext
        val audioDir = File(context.filesDir, "audio")
        val videoDir = File(context.filesDir, "video")
        val imageDir = File(context.filesDir, "image")

        val thirtyDaysAgo = System.currentTimeMillis() - 30 * 24 * 60 * 60 * 1000

        try {
            cleanupDirectory(audioDir, thirtyDaysAgo)
            cleanupDirectory(videoDir, thirtyDaysAgo)
            cleanupDirectory(imageDir, thirtyDaysAgo)
        } catch (e: Exception) {
            return Result.failure()
        }

        return Result.success()
    }

    private fun cleanupDirectory(directory: File, threshold: Long) {
        if (directory.exists()) {
            directory.listFiles()?.forEach { file ->
                if (file.lastModified() < threshold) {
                    file.delete()
                }
            }
        }
    }
}