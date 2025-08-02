package com.example.pocketrecorder

import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.ui.semantics.Role
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.TextField
import androidx.compose.ui.res.stringResource
import androidx.compose.material3.Switch
import com.example.pocketrecorder.ui.theme.PocketRecorderTheme

class SettingsActivity : ComponentActivity() {

    private lateinit var sharedPreferences: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sharedPreferences = getSharedPreferences("PocketRecorderSettings", Context.MODE_PRIVATE)

        setContent {
            PocketRecorderTheme {
                SettingsScreen(sharedPreferences)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(sharedPreferences: SharedPreferences) {
    var sensitivity by remember { mutableStateOf(sharedPreferences.getFloat("sensitivity_threshold", 10f)) }
    var timeWindow by remember { mutableStateOf(sharedPreferences.getLong("time_window", 1000L).toFloat()) }
    var notificationEnabled by remember { mutableStateOf(sharedPreferences.getBoolean("notification_enabled", true)) }
    val vibrationOptions = listOf("short", "long")
    var selectedVibrationPattern by remember { mutableStateOf(sharedPreferences.getString("start_vibration_pattern", "short") ?: "short") }
    val retentionPeriods = listOf(7, 30, 60)
    var selectedRetentionPeriod by remember { mutableStateOf(sharedPreferences.getInt("retention_period_days", 30)) }
    var expandedRetention by remember { mutableStateOf(false) }
    val recordingQualities = listOf("low", "medium", "high")
    var selectedRecordingQuality by remember { mutableStateOf(sharedPreferences.getString("recording_quality", "medium") ?: "medium") }
    var expandedQuality by remember { mutableStateOf(false) }

    var voiceCommandEnabled by remember { mutableStateOf(sharedPreferences.getBoolean("voice_command_enabled", false)) }
    var customPassphrase by remember { mutableStateOf(sharedPreferences.getString("custom_passphrase", "start recording") ?: "start recording") }
    var voiceSensitivity by remember { mutableStateOf(sharedPreferences.getFloat("voice_sensitivity", 0.5f)) }

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Settings") })
        }
    ) {
        paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text("Tap Sensitivity: ${"%.1f".format(sensitivity)}")
            Slider(
                value = sensitivity,
                onValueChange = { sensitivity = it },
                valueRange = 5f..20f,
                steps = 15,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            Text("Time Window: ${timeWindow.toInt()} ms")
            Slider(
                value = timeWindow,
                onValueChange = { timeWindow = it },
                valueRange = 500f..2000f,
                steps = 150,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("Enable Notifications")
                Spacer(Modifier.weight(1f))
                Switch(
                    checked = notificationEnabled,
                    onCheckedChange = { notificationEnabled = it }
                )
            }
            Spacer(modifier = Modifier.height(16.dp))

            Text("Vibration Pattern for Start")
            Row(Modifier.selectableGroup()) {
                vibrationOptions.forEach { text ->
                    Row(
                        Modifier
                            .selectable(
                                selected = (text == selectedVibrationPattern),
                                onClick = { selectedVibrationPattern = text },
                                role = Role.RadioButton
                            )
                            .padding(horizontal = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = (text == selectedVibrationPattern),
                            onClick = null // null recommended for accessibility with screenreaders
                        )
                        Text(text = text)
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))

            ExposedDropdownMenuBox(
                expanded = expandedRetention,
                onExpandedChange = { expandedRetention = !expandedRetention }
            ) {
                TextField(
                    value = "$selectedRetentionPeriod days",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Retention Period") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedRetention) },
                    modifier = Modifier.fillMaxWidth().menuAnchor()
                )
                ExposedDropdownMenu(
                    expanded = expandedRetention,
                    onDismissRequest = { expandedRetention = false }
                ) {
                    retentionPeriods.forEach { selectionOption ->
                        DropdownMenuItem(
                            text = { Text("$selectionOption days") },
                            onClick = {
                                selectedRetentionPeriod = selectionOption
                                expandedRetention = false
                            }
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))

            ExposedDropdownMenuBox(
                expanded = expandedQuality,
                onExpandedChange = { expandedQuality = !expandedQuality }
            ) {
                TextField(
                    value = selectedRecordingQuality,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Recording Quality") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedQuality) },
                    modifier = Modifier.fillMaxWidth().menuAnchor()
                )
                ExposedDropdownMenu(
                    expanded = expandedQuality,
                    onDismissRequest = { expandedQuality = false }
                ) {
                    recordingQualities.forEach { selectionOption ->
                        DropdownMenuItem(
                            text = { Text(selectionOption) },
                            onClick = {
                                selectedRecordingQuality = selectionOption
                                expandedQuality = false
                            }
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))

            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("Enable Voice Command")
                Spacer(Modifier.weight(1f))
                Switch(
                    checked = voiceCommandEnabled,
                    onCheckedChange = { voiceCommandEnabled = it }
                )
            }
            Spacer(modifier = Modifier.height(16.dp))

            TextField(
                value = customPassphrase,
                onValueChange = { customPassphrase = it },
                label = { Text("Custom Passphrase") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            Text("Voice Sensitivity: ${"%.1f".format(voiceSensitivity)}")
            Slider(
                value = voiceSensitivity,
                onValueChange = { voiceSensitivity = it },
                valueRange = 0.1f..1.0f,
                steps = 9,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            Button(onClick = {
                with(sharedPreferences.edit()) {
                    putFloat("sensitivity_threshold", sensitivity)
                    putLong("time_window", timeWindow.toLong())
                    putBoolean("notification_enabled", notificationEnabled)
                    putString("start_vibration_pattern", selectedVibrationPattern)
                    putInt("retention_period_days", selectedRetentionPeriod)
                    putString("recording_quality", selectedRecordingQuality)
                    putBoolean("voice_command_enabled", voiceCommandEnabled)
                    putString("custom_passphrase", customPassphrase)
                    putFloat("voice_sensitivity", voiceSensitivity)
                    apply()