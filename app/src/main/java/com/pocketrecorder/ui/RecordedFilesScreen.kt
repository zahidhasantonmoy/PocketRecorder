package com.pocketrecorder.ui

import android.content.Context
import android.media.MediaPlayer
import android.net.Uri
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
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
        LazyColumn(modifier = Modifier.padding(paddingValues).padding(16.dp)) {
            if (audioFiles.isNotEmpty()) {
                item { Text("Audio Recordings", style = MaterialTheme.typography.titleMedium) }
                items(audioFiles) { file ->
                    FileItem(file) { playAudio(context, file) }
                }
                item { Spacer(modifier = Modifier.height(16.dp)) }
            }
            if (videoFiles.isNotEmpty()) {
                item { Text("Video Recordings", style = MaterialTheme.typography.titleMedium) }
                items(videoFiles) { file ->
                    FileItem(file) { /* TODO: Implement video playback */ }
                }
                item { Spacer(modifier = Modifier.height(16.dp)) }
            }
            if (imageFiles.isNotEmpty()) {
                item { Text("Image Captures", style = MaterialTheme.typography.titleMedium) }
                items(imageFiles) { file ->
                    FileItem(file) { /* TODO: Implement image viewing */ }
                }
                item { Spacer(modifier = Modifier.height(16.dp)) }
            }
            if (audioFiles.isEmpty() && videoFiles.isEmpty() && imageFiles.isEmpty()) {
                item { Text("No recorded files yet.", style = MaterialTheme.typography.bodyLarge) }
            }
        }
    }
}

@Composable
fun FileItem(file: File, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text(text = file.name, style = MaterialTheme.typography.bodyLarge)
            Text(text = "Size: ${file.length() / 1024} KB", style = MaterialTheme.typography.bodySmall)
        }
        IconButton(onClick = onClick) {
            Icon(Icons.Filled.PlayArrow, contentDescription = "Play/View")
        }
    }
}

private fun getRecordedFiles(context: Context, type: String): List<File> {
    val directory = File(context.filesDir, type)
    return directory.listFiles()?.filter { it.isFile }?.toList() ?: emptyList()
}

private fun playAudio(context: Context, file: File) {
    val mediaPlayer = MediaPlayer().apply {
        setDataSource(context, Uri.fromFile(file))
        prepare()
        start()
    }
    mediaPlayer.setOnCompletionListener { it.release() }
}
