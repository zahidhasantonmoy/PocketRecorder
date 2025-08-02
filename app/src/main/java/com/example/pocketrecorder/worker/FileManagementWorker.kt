package com.example.pocketrecorder.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.pocketrecorder.data.AppDatabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class FileManagementWorker(appContext: Context, workerParams: WorkerParameters) :
    CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val db = AppDatabase.getDatabase(applicationContext)
        val recordedFileDao = db.recordedFileDao()

        val sharedPreferences = applicationContext.getSharedPreferences("PocketRecorderSettings", Context.MODE_PRIVATE)
        val retentionPeriodDays = sharedPreferences.getInt("retention_period_days", 30)

        val cutoffTime = System.currentTimeMillis() - (retentionPeriodDays * 24 * 60 * 60 * 1000L)

        withContext(Dispatchers.IO) {
            val oldFiles = recordedFileDao.getAllRecordedFiles().filter { it.timestamp < cutoffTime }
            oldFiles.forEach { recordedFile ->
                val file = File(recordedFile.filePath)
                if (file.exists()) {
                    file.delete()
                }
            }
            recordedFileDao.deleteOldFiles(cutoffTime)
        }

        return Result.success()
    }
}