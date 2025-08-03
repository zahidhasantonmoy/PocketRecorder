package com.pocketrecorder.ui

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen() {
    val context = LocalContext.current
    val sharedPreferences = context.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        Text(text = "Settings", style = MaterialTheme.typography.headlineMedium)

        Spacer(modifier = Modifier.height(16.dp))

        // Tap Pattern Settings
        TapSettings(sharedPreferences)

        Spacer(modifier = Modifier.height(16.dp))

        // Other settings...
    }
}

@Composable
fun TapSettings(sharedPreferences: SharedPreferences) {
    var audioTaps by remember { mutableStateOf(sharedPreferences.getInt("audio_taps", 3)) }
    var videoTaps by remember { mutableStateOf(sharedPreferences.getInt("video_taps", 4)) }
    var imageTaps by remember { mutableStateOf(sharedPreferences.getInt("image_taps", 2)) }
    var emergencyTaps by remember { mutableStateOf(sharedPreferences.getInt("emergency_taps", 5)) }

    Column {
        Text(text = "Tap Patterns", style = MaterialTheme.typography.titleMedium)

        SliderSetting("Audio Taps", audioTaps, 2, 5) { newValue ->
            audioTaps = newValue
            sharedPreferences.edit().putInt("audio_taps", newValue).apply()
        }
        SliderSetting("Video Taps", videoTaps, 2, 5) { newValue ->
            videoTaps = newValue
            sharedPreferences.edit().putInt("video_taps", newValue).apply()
        }
        SliderSetting("Image Taps", imageTaps, 2, 5) { newValue ->
            imageTaps = newValue
            sharedPreferences.edit().putInt("image_taps", newValue).apply()
        }
        SliderSetting("Emergency Taps", emergencyTaps, 2, 5) { newValue ->
            emergencyTaps = newValue
            sharedPreferences.edit().putInt("emergency_taps", newValue).apply()
        }
    }
}

@Composable
fun SliderSetting(label: String, value: Int, from: Int, to: Int, onValueChange: (Int) -> Unit) {
    Column(modifier = Modifier.padding(vertical = 8.dp)) {
        Text(text = "$label: $value")
        Slider(
            value = value.toFloat(),
            onValueChange = { onValueChange(it.toInt()) },
            valueRange = from.toFloat()..to.toFloat(),
            steps = to - from - 1
        )
    }
}