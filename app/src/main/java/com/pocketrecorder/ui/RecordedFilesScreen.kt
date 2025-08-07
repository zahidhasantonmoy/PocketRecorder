package com.pocketrecorder.ui

import android.content.Context
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.* // Import all Material3 components
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecordedFilesScreen() {
    val context = LocalContext.current
    var audioFiles by remember { mutableStateOf(emptyList<File>()) }
    var videoFiles by remember { mutableStateOf(emptyList<File>()) }
    var imageFiles by remember { mutableStateOf(emptyList<File>()) }

    LaunchedEffect(Unit) {
        audioFiles = getRecordedFiles(context, "audio")
        videoFiles = getRecordedFiles(context, "video")
        imageFiles = getRecordedFiles(context, "image")
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Recorded Files") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        }
    ) { paddingValues ->
        Column(modifier = Modifier.padding(paddingValues).padding(16.dp)) {
            if (audioFiles.isNotEmpty()) {
                Text("Audio Recordings", style = MaterialTheme.typography.titleMedium)
                audioFiles.forEach { file ->
                    Text(file.name)
                }
                Spacer(modifier = Modifier.height(16.dp))
            }
            if (videoFiles.isNotEmpty()) {
                Text("Video Recordings", style = MaterialTheme.typography.titleMedium)
                videoFiles.forEach { file ->
                    Text(file.name)
                }
                Spacer(modifier = Modifier.height(16.dp))
            }
            if (imageFiles.isNotEmpty()) {
                Text("Image Captures", style = MaterialTheme.typography.titleMedium)
                imageFiles.forEach { file ->
                    Text(file.name)
                }
                Spacer(modifier = Modifier.height(16.dp))
            }
            if (audioFiles.isEmpty() && videoFiles.isEmpty() && imageFiles.isEmpty()) {
                Text("No recorded files yet.", style = MaterialTheme.typography.bodyLarge)
            }
        }
    }
}

private fun getRecordedFiles(context: Context, type: String): List<File> {
    val directory = File(context.filesDir, type)
    return directory.listFiles()?.filter { it.isFile }?.toList() ?: emptyList()
}
