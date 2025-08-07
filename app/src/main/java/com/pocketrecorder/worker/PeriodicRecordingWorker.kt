package com.pocketrecorder.worker

import android.content.Context
import android.content.Intent
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.pocketrecorder.service.TapDetectionService

class PeriodicRecordingWorker(appContext: Context, workerParams: WorkerParameters) :
    Worker(appContext, workerParams) {

    override fun doWork(): Result {
        val sharedPreferences = applicationContext.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)
        val periodicRecordingEnabled = sharedPreferences.getBoolean("periodic_recording_enabled", false)

        if (periodicRecordingEnabled) {
            // Trigger a recording action (e.g., audio recording)
            val intent = Intent("com.pocketrecorder.ACTION_START_AUDIO_RECORDING")
            applicationContext.sendBroadcast(intent)
        }
        return Result.success()
    }
}
