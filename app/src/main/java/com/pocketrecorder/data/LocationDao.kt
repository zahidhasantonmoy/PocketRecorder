package com.pocketrecorder.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query

@Dao
interface LocationDao {
    @Insert
    suspend fun insert(location: Location)

    @Query("SELECT * FROM locations ORDER BY timestamp DESC")
    suspend fun getAllLocations(): List<Location>
}