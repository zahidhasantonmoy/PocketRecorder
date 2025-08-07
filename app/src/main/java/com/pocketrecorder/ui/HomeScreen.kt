import android.content.Intent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.pocketrecorder.service.TapDetectionService

@Composable
fun HomeScreen(navController: NavController) {
    val isRecording by TapDetectionService.isRecording.collectAsState()
    val currentAcceleration by TapDetectionService.currentAcceleration.collectAsState()
    val context = LocalContext.current

    var showRecordingDialog by remember { mutableStateOf(false) }

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
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = {
                    val intent = Intent("com.pocketrecorder.ACTION_STOP_RECORDING")
                    context.sendBroadcast(intent)
                }) {
                    Text("Stop Recording")
                }
            } else {
                Text("Tap the back of your phone to start recording.", style = MaterialTheme.typography.bodyMedium)
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { showRecordingDialog = true }) {
                    Text("Start Manual Recording")
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            Text("Current Acceleration: %.2f".format(currentAcceleration), style = MaterialTheme.typography.bodyMedium)
        }
    }

    if (showRecordingDialog) {
        AlertDialog(
            onDismissRequest = { showRecordingDialog = false },
            title = { Text("Select Recording Type") },
            text = {
                Column {
                    Button(onClick = {
                        val intent = Intent("com.pocketrecorder.ACTION_START_AUDIO_RECORDING")
                        context.sendBroadcast(intent)
                        showRecordingDialog = false
                    }) {
                        Text("Audio Recording")
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Button(onClick = {
                        val intent = Intent("com.pocketrecorder.ACTION_START_VIDEO_RECORDING")
                        context.sendBroadcast(intent)
                        showRecordingDialog = false
                    }) {
                        Text("Video Recording")
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Button(onClick = {
                        val intent = Intent("com.pocketrecorder.ACTION_CAPTURE_IMAGE")
                        context.sendBroadcast(intent)
                        showRecordingDialog = false
                    }) {
                        Text("Image Capture")
                    }
                }
            },
            confirmButton = {},
            dismissButton = {
                Button(onClick = { showRecordingDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
