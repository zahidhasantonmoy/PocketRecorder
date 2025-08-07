package com.pocketrecorder.ui

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

@Composable
fun SlapTrainingScreen() {
    val context = LocalContext.current
    var isTraining by remember { mutableStateOf(false) }
    var selectedAction by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("Slap Training", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(16.dp))

        if (!isTraining) {
            Text("Select an action to train a slap gesture for:")
            Spacer(modifier = Modifier.height(8.dp))
            Button(onClick = { selectedAction = "audio" }) { Text("Audio Recording") }
            Spacer(modifier = Modifier.height(8.dp))
            Button(onClick = { selectedAction = "video" }) { Text("Video Recording") }
            Spacer(modifier = Modifier.height(8.dp))
            Button(onClick = { selectedAction = "image" }) { Text("Image Capture") }
            Spacer(modifier = Modifier.height(8.dp))
            Button(onClick = { selectedAction = "emergency" }) { Text("Emergency SOS") }

            Spacer(modifier = Modifier.height(16.dp))

            if (selectedAction != null) {
                Button(onClick = {
                    isTraining = true
                    val intent = Intent("com.pocketrecorder.ACTION_START_SLAP_TRAINING")
                    context.sendBroadcast(intent)
                }) {
                    Text("Start Training for ${selectedAction?.replaceFirstChar { it.uppercase() }}")
                }
            }
        } else {
            Text("Perform the slap gesture now...")
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = {
                isTraining = false
                val intent = Intent("com.pocketrecorder.ACTION_STOP_SLAP_TRAINING")
                context.sendBroadcast(intent)
            }) {
                Text("Stop Training")
            }
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = {
                val intent = Intent("com.pocketrecorder.ACTION_SAVE_SLAP_PATTERN").apply {
                    putExtra("action", selectedAction)
                }
                context.sendBroadcast(intent)
                isTraining = false
                selectedAction = null
            }) {
                Text("Save Slap Pattern")
            }
        }
    }
}