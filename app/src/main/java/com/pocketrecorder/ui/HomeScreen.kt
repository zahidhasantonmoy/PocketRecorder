package com.pocketrecorder.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.pocketrecorder.service.TapDetectionService

@Composable
fun HomeScreen(navController: NavController) {
    val isRecording by TapDetectionService.isRecording.collectAsState()
    val currentAcceleration by TapDetectionService.currentAcceleration.collectAsState()

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("Welcome to PocketRecorder", style = MaterialTheme.typography.headlineMedium)
            Spacer(modifier = Modifier.height(16.dp))
            if (isRecording) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(modifier = Modifier.size(24.dp))
                    Spacer(modifier = Modifier.size(8.dp))
                    Text("Recording...", style = MaterialTheme.typography.bodyMedium)
                }
            } else {
                Text("Tap the back of your phone to start recording.", style = MaterialTheme.typography.bodyMedium)
            }
            Spacer(modifier = Modifier.height(16.dp))
            Text("Current Acceleration: %.2f".format(currentAcceleration), style = MaterialTheme.typography.bodyMedium)
        }
    }
}
