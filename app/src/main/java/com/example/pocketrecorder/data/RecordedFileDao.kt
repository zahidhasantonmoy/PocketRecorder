package com.example.pocketrecorder.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query

@Dao
interface RecordedFileDao {
    @Insert
    suspend fun insertRecordedFile(recordedFile: RecordedFile)

    @Query("SELECT * FROM recorded_files ORDER BY timestamp DESC")
    suspend fun getAllRecordedFiles(): List<RecordedFile>

    @Query("SELECT * FROM recorded_files WHERE fileType = :fileType ORDER BY timestamp DESC")
    suspend fun getRecordedFilesByType(fileType: String): List<RecordedFile>

    @Query("DELETE FROM recorded_files WHERE timestamp < :timestamp")
    suspend fun deleteOldFiles(timestamp: Long)
}