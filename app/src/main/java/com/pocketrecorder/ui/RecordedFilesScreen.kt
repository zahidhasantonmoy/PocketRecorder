package com.pocketrecorder.ui

import android.content.Intent
import android.net.Uri
import android.os.Parcelable
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.MaterialTheme
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
import androidx.documentfile.provider.DocumentFile

@Composable
fun RecordedFilesScreen(viewModel: RecordedFilesViewModel) {
    val recordedFiles by viewModel.recordedFiles.collectAsState(initial = emptyList())
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.loadRecordedFiles()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text("Recorded Files", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.size(16.dp))

        if (recordedFiles.isEmpty()) {
            Text("No recorded files found.", style = MaterialTheme.typography.bodyMedium)
        } else {
            LazyColumn {
                items(recordedFiles) { file ->
                    FileListItem(file = file, onDelete = {
                        viewModel.deleteFile(file)
                    })
                }
            }
        }
    }
}

@Composable
fun FileListItem(file: DocumentFile, onDelete: () -> Unit) {
    val context = LocalContext.current
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(file.name ?: "Unknown Name", style = MaterialTheme.typography.titleMedium)
            Text(file.uri.toString(), style = MaterialTheme.typography.bodySmall)
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = {
                    val uri = file.uri
                    val mimeType = context.contentResolver.getType(uri)
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, mimeType)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    context.startActivity(intent)
                }) {
                    Icon(Icons.Filled.PlayArrow, contentDescription = "Play/View")
                }
                IconButton(onClick = {
                    val uri = file.uri
                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = context.contentResolver.getType(uri)
                        putExtra(Intent.EXTRA_STREAM, uri as Parcelable)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    context.startActivity(Intent.createChooser(shareIntent, "Share File"))
                }) {
                    Icon(Icons.Filled.Share, contentDescription = "Share")
                }
                Spacer(modifier = Modifier.weight(1f))
                IconButton(onClick = onDelete) {
                    Icon(Icons.Filled.Delete, contentDescription = "Delete")
                }
            }
        }
    }
}