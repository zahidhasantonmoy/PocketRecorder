package com.pocketrecorder.ui

import android.content.Context
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController

@Composable
fun SettingsScreen(navController: NavController) {
    val context = LocalContext.current
    val sharedPreferences = remember { context.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE) }

    var audioTaps by remember { mutableStateOf(sharedPreferences.getInt("audio_taps", 3).toString()) }
    var videoTaps by remember { mutableStateOf(sharedPreferences.getInt("video_taps", 4).toString()) }
    var imageTaps by remember { mutableStateOf(sharedPreferences.getInt("image_taps", 2).toString()) }
    var emergencyTaps by remember { mutableStateOf(sharedPreferences.getInt("emergency_taps", 5).toString()) }
    var sensitivity by remember { mutableStateOf(sharedPreferences.getString("sensitivity", "medium") ?: "medium") }
    var locationTracking by remember { mutableStateOf(sharedPreferences.getBoolean("location_tracking", true)) }
    var encryption by remember { mutableStateOf(sharedPreferences.getBoolean("encryption", true)) }
    var smartNotifications by remember { mutableStateOf(sharedPreferences.getBoolean("smart_notifications", true)) }
    var automaticFileManagement by remember { mutableStateOf(sharedPreferences.getBoolean("automatic_file_management", true)) }
    var voiceCommand by remember { mutableStateOf(sharedPreferences.getBoolean("voice_command", true)) }
    var smartSensor by remember { mutableStateOf(sharedPreferences.getBoolean("smart_sensor", true)) }
    var emergencyMode by remember { mutableStateOf(sharedPreferences.getBoolean("emergency_mode", true)) }
    var batteryOptimization by remember { mutableStateOf(sharedPreferences.getBoolean("battery_optimization", true)) }
    var tutorialMode by remember { mutableStateOf(sharedPreferences.getBoolean("tutorial_mode", true)) }
    var multilingualSupport by remember { mutableStateOf(sharedPreferences.getBoolean("multilingual_support", true)) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Text("Settings", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(16.dp))
        TextField(value = audioTaps, onValueChange = { audioTaps = it }, label = { Text("Audio Taps") })
        Spacer(modifier = Modifier.height(16.dp))
        TextField(value = videoTaps, onValueChange = { videoTaps = it }, label = { Text("Video Taps") })
        Spacer(modifier = Modifier.height(16.dp))
        TextField(value = imageTaps, onValueChange = { imageTaps = it }, label = { Text("Image Taps") })
        Spacer(modifier = Modifier.height(16.dp))
        TextField(value = emergencyTaps, onValueChange = { emergencyTaps = it }, label = { Text("Emergency Taps") })
        Spacer(modifier = Modifier.height(16.dp))
        Text("Sensitivity")
        Row {
            Button(onClick = { sensitivity = "low" }) { Text("Low") }
            Button(onClick = { sensitivity = "medium" }) { Text("Medium") }
            Button(onClick = { sensitivity = "high" }) { Text("High") }
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = locationTracking, onCheckedChange = { locationTracking = it })
            Text("Location Tracking")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = encryption, onCheckedChange = { encryption = it })
            Text("Encryption")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = smartNotifications, onCheckedChange = { smartNotifications = it })
            Text("Smart Notifications")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = automaticFileManagement, onCheckedChange = { automaticFileManagement = it })
            Text("Automatic File Management")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = voiceCommand, onCheckedChange = { voiceCommand = it })
            Text("Voice Command")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = smartSensor, onCheckedChange = { smartSensor = it })
            Text("Smart Sensor")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = emergencyMode, onCheckedChange = { emergencyMode = it })
            Text("Emergency Mode")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = batteryOptimization, onCheckedChange = { batteryOptimization = it })
            Text("Battery Optimization")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = tutorialMode, onCheckedChange = { tutorialMode = it })
            Text("Tutorial Mode")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = multilingualSupport, onCheckedChange = { multilingualSupport = it })
            Text("Multilingual Support")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = {
            sharedPreferences.edit()
                .putInt("audio_taps", audioTaps.toInt())
                .putInt("video_taps", videoTaps.toInt())
                .putInt("image_taps", imageTaps.toInt())
                .putInt("emergency_taps", emergencyTaps.toInt())
                .putString("sensitivity", sensitivity)
                .putBoolean("location_tracking", locationTracking)
                .putBoolean("encryption", encryption)
                .putBoolean("smart_notifications", smartNotifications)
                .putBoolean("automatic_file_management", automaticFileManagement)
                .putBoolean("voice_command", voiceCommand)
                .putBoolean("smart_sensor", smartSensor)
                .putBoolean("emergency_mode", emergencyMode)
                .putBoolean("battery_optimization", batteryOptimization)
                .putBoolean("tutorial_mode", tutorialMode)
                .putBoolean("multilingual_support", multilingualSupport)
                .apply()
        }) {
            Text("Save")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = { navController.navigate("slap_training") }) {
            Text("Slap Training")
        }
    }
}
