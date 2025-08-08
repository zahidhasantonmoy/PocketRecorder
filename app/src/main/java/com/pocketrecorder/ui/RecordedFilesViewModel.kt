package com.pocketrecorder.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pocketrecorder.data.FileRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import androidx.documentfile.provider.DocumentFile

class RecordedFilesViewModel(private val fileRepository: FileRepository) : ViewModel() {

    private val _recordedFiles = MutableStateFlow<List<DocumentFile>>(emptyList())
    val recordedFiles: StateFlow<List<DocumentFile>> = _recordedFiles.asStateFlow()

    fun loadRecordedFiles() {
        viewModelScope.launch {
            _recordedFiles.value = fileRepository.getRecordedFiles()
        }
    }

    fun deleteFile(file: DocumentFile) {
        viewModelScope.launch {
            fileRepository.deleteFile(file)
            loadRecordedFiles() // Refresh the list
        }
    }
}
