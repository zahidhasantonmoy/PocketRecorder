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
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Delete
import android.content.Intent
import androidx.core.content.FileProvider
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive

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
                    FileItem(file, onShare = { shareFile(context, it) }, onDelete = { fileToDelete ->
                        deleteFile(context, fileToDelete) { audioFiles = getRecordedFiles(context, "audio") }
                    })
                }
                item { Spacer(modifier = Modifier.height(16.dp)) }
            }
            if (videoFiles.isNotEmpty()) {
                item { Text("Video Recordings", style = MaterialTheme.typography.titleMedium) }
                items(videoFiles) { file ->
                    FileItem(file, onShare = { shareFile(context, it) }, onDelete = { fileToDelete ->
                        deleteFile(context, fileToDelete) { videoFiles = getRecordedFiles(context, "video") }
                    })
                }
                item { Spacer(modifier = Modifier.height(16.dp)) }
            }
            if (imageFiles.isNotEmpty()) {
                item { Text("Image Captures", style = MaterialTheme.typography.titleMedium) }
                items(imageFiles) { file ->
                    FileItem(file, onShare = { shareFile(context, it) }, onDelete = { fileToDelete ->
                        deleteFile(context, fileToDelete) { imageFiles = getRecordedFiles(context, "image") }
                    })
                }
            if (audioFiles.isEmpty() && videoFiles.isEmpty() && imageFiles.isEmpty()) {
                item { Text("No recorded files yet.", style = MaterialTheme.typography.bodyLarge) }
            }
        }
    }
}

@Composable
fun FileItem(file: File, onShare: (File) -> Unit, onDelete: (File) -> Unit) {
    val context = LocalContext.current
    var mediaPlayer by remember { mutableStateOf<MediaPlayer?>(null) }
    var isPlaying by remember { mutableStateOf(false) }
    var currentPosition by remember { mutableStateOf(0) }
    var duration by remember { mutableStateOf(0) }

    LaunchedEffect(mediaPlayer) {
        if (mediaPlayer != null) {
            while (isPlaying) {
                currentPosition = mediaPlayer?.currentPosition ?: 0
                delay(100)
            }
        }
    }

    DisposableEffect(file) {
        onDispose {
            mediaPlayer?.release()
            mediaPlayer = null
        }
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(text = file.name, style = MaterialTheme.typography.bodyLarge)
                Text(text = "Size: ${file.length() / 1024} KB", style = MaterialTheme.typography.bodySmall)
            }
            Row {
                // Play/Pause/Stop for audio files
                if (file.extension == "mp4" || file.extension == "aac") { // Assuming audio files are .mp4 or .aac
                    IconButton(onClick = {
                        if (isPlaying) {
                            mediaPlayer?.pause()
                        } else {
                            if (mediaPlayer == null) {
                                mediaPlayer = MediaPlayer().apply {
                                    setDataSource(context, Uri.fromFile(file))
                                    prepare()
                                    duration = mediaPlayer?.duration ?: 0
                                    setOnCompletionListener { 
                                        isPlaying = false
                                        currentPosition = 0
                                        it.release()
                                        mediaPlayer = null
                                    }
                                }
                            }
                            mediaPlayer?.start()
                        }
                        isPlaying = !isPlaying
                    }) {
                        Icon(if (isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow, contentDescription = "Play/Pause")
                    }
                    IconButton(onClick = {
                        mediaPlayer?.stop()
                        mediaPlayer?.release()
                        mediaPlayer = null
                        isPlaying = false
                        currentPosition = 0
                    }) {
                        Icon(Icons.Filled.Stop, contentDescription = "Stop")
                    }
                }
                IconButton(onClick = { onShare(file) }) {
                    Icon(Icons.Filled.Share, contentDescription = "Share")
                }
                IconButton(onClick = { onDelete(file) }) {
                    Icon(Icons.Filled.Delete, contentDescription = "Delete")
                }
            }
        }
        if (file.extension == "mp4" || file.extension == "aac") {
            Slider(
                value = currentPosition.toFloat(),
                onValueChange = {
                    currentPosition = it.toInt()
                    mediaPlayer?.seekTo(currentPosition)
                },
                valueRange = 0f..duration.toFloat(),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

private fun getRecordedFiles(context: Context, type: String): List<File> {
    val directory = File(context.filesDir, type)
    return directory.listFiles()?.filter { it.isFile }?.toList() ?: emptyList()
}

private fun shareFile(context: Context, file: File) {
    val uri = FileProvider.getUriForFile(context, context.applicationContext.packageName + ".provider", file)
    val shareIntent = Intent(Intent.ACTION_SEND).apply {
        type = context.contentResolver.getType(uri)
        putExtra(Intent.EXTRA_STREAM, uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(Intent.createChooser(shareIntent, "Share File"))
}

private fun deleteFile(context: Context, file: File, onFileDeleted: () -> Unit) {
    if (file.exists()) {
        file.delete()
        Toast.makeText(context, "File deleted: ${file.name}", Toast.LENGTH_SHORT).show()
        onFileDeleted()
    }
}
