package com.example.pocketrecorder.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "recorded_files")
data class RecordedFile(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val filePath: String,
    val fileType: String,
    val timestamp: Long,
    val latitude: Double?,
    val longitude: Double?,
    val isEncrypted: Boolean
)