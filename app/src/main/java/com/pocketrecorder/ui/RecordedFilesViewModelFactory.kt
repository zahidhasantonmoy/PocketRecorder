package com.pocketrecorder.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.pocketrecorder.data.FileRepository

class RecordedFilesViewModelFactory(private val fileRepository: FileRepository) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(RecordedFilesViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return RecordedFilesViewModel(fileRepository) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
