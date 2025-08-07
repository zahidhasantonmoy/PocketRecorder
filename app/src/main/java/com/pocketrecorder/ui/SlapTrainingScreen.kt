package com.pocketrecorder.ui

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.RadioButton
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
    var selectedAction by remember { mutableStateOf("audio") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text("Slap Training")
        Spacer(modifier = Modifier.height(16.dp))
        if (!isTraining) {
            Button(onClick = {
                isTraining = true
                val intent = Intent("com.pocketrecorder.ACTION_START_SLAP_TRAINING")
                context.sendBroadcast(intent)
            }) {
                Text("Start Training")
            }
        } else {
            Button(onClick = {
                isTraining = false
                val intent = Intent("com.pocketrecorder.ACTION_STOP_SLAP_TRAINING")
                context.sendBroadcast(intent)
            }) {
                Text("Stop Training")
            }
        }
        Spacer(modifier = Modifier.height(16.dp))
        Text("Select Action:")
        Row(verticalAlignment = Alignment.CenterVertically) {
            RadioButton(
                selected = selectedAction == "audio",
                onClick = { selectedAction = "audio" }
            )
            Text("Audio")
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            RadioButton(
                selected = selectedAction == "video",
                onClick = { selectedAction = "video" }
            )
            Text("Video")
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            RadioButton(
                selected = selectedAction == "image",
                onClick = { selectedAction = "image" }
            )
            Text("Image")
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            RadioButton(
                selected = selectedAction == "emergency",
                onClick = { selectedAction = "emergency" }
            )
            Text("Emergency")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = {
            val intent = Intent("com.pocketrecorder.ACTION_SAVE_SLAP_PATTERN")
            intent.putExtra("action", selectedAction)
            context.sendBroadcast(intent)
        }) {
            Text("Save Pattern")
        }
    }
}
