package com.pocketrecorder.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.pocketrecorder.data.FileRepository
import java.io.File

@Composable
fun RecordedFilesScreen(viewModel: RecordedFilesViewModel = viewModel(factory = RecordedFilesViewModelFactory(FileRepository(LocalContext.current)))) {
    val recordedFiles by viewModel.recordedFiles.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadRecordedFiles()
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Text("Recorded Files", modifier = Modifier.padding(16.dp))
        LazyColumn(modifier = Modifier.weight(1f)) {
            items(recordedFiles) { file ->
                FileListItem(file, onDelete = { viewModel.deleteFile(file) })
            }
        }
    }
}

@Composable
fun FileListItem(file: File, onDelete: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Filled.PlayArrow, contentDescription = "Play")
            Spacer(modifier = Modifier.size(16.dp))
            Text(file.name, modifier = Modifier.weight(1f))
            IconButton(onClick = onDelete) {
                Icon(Icons.Filled.Delete, contentDescription = "Delete")
            }
        }
    }
}
