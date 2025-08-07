package com.pocketrecorder.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pocketrecorder.data.FileRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File

class RecordedFilesViewModel(private val fileRepository: FileRepository) : ViewModel() {

    private val _recordedFiles = MutableStateFlow<List<File>>(emptyList())
    val recordedFiles: StateFlow<List<File>> = _recordedFiles.asStateFlow()

    fun loadRecordedFiles() {
        viewModelScope.launch {
            _recordedFiles.value = fileRepository.getRecordedFiles()
        }
    }

    fun deleteFile(file: File) {
        viewModelScope.launch {
            fileRepository.deleteFile(file)
            loadRecordedFiles() // Refresh the list
        }
    }
}
