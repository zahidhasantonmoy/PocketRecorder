package com.pocketrecorder.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Delete

@Dao
interface ContactDao {
    @Insert
    suspend fun insert(contact: Contact)

    @Query("SELECT * FROM contacts")
    suspend fun getAllContacts(): List<Contact>

    @Delete
    suspend fun delete(contact: Contact)
}