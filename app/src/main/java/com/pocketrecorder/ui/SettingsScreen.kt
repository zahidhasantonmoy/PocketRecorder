package com.pocketrecorder.ui

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.pocketrecorder.data.AppDatabase
import com.pocketrecorder.data.Contact
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen() {
    val context = LocalContext.current
    val sharedPreferences = context.getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(paddingValues)
                .padding(16.dp)
        ) {
            // Tap Pattern Settings
            TapSettings(sharedPreferences)

            Spacer(modifier = Modifier.height(16.dp))

            // Sensitivity Setting
            SensitivitySetting(sharedPreferences)

            Spacer(modifier = Modifier.height(16.dp))

            // Smart Sensor Settings
            SmartSensorSettings(sharedPreferences)

            Spacer(modifier = Modifier.height(16.dp))

            // Voice Command Settings
            VoiceCommandSettings(sharedPreferences)

            Spacer(modifier = Modifier.height(16.dp))

            // Emergency Contacts
            EmergencyContacts(context)
        }
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

@Composable
fun SensitivitySetting(sharedPreferences: SharedPreferences) {
    var sensitivity by remember { mutableStateOf(sharedPreferences.getString("sensitivity", "medium") ?: "medium") }

    Column {
        Text(text = "Tap Sensitivity", style = MaterialTheme.typography.titleMedium)
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceAround) {
            OutlinedButton(onClick = { sensitivity = "low"; sharedPreferences.edit().putString("sensitivity", "low").apply() }) {
                Text("Low")
            }
            OutlinedButton(onClick = { sensitivity = "medium"; sharedPreferences.edit().putString("sensitivity", "medium").apply() }) {
                Text("Medium")
            }
            OutlinedButton(onClick = { sensitivity = "high"; sharedPreferences.edit().putString("sensitivity", "high").apply() }) {
                Text("High")
            }
        }
        Text(text = "Current: $sensitivity", style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
fun SmartSensorSettings(sharedPreferences: SharedPreferences) {
    var pocketModeEnabled by remember { mutableStateOf(sharedPreferences.getBoolean("pocket_mode", true)) }
    var uprightModeEnabled by remember { mutableStateOf(sharedPreferences.getBoolean("upright_mode", true)) }

    Column {
        Text(text = "Smart Sensor Modes", style = MaterialTheme.typography.titleMedium)
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("Pocket Mode")
            Spacer(Modifier.weight(1f))
            Switch(checked = pocketModeEnabled, onCheckedChange = { isChecked ->
                pocketModeEnabled = isChecked
                sharedPreferences.edit().putBoolean("pocket_mode", isChecked).apply()
            })
        }
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("Upright Mode")
            Spacer(Modifier.weight(1f))
            Switch(checked = uprightModeEnabled, onCheckedChange = { isChecked ->
                uprightModeEnabled = isChecked
                sharedPreferences.edit().putBoolean("upright_mode", isChecked).apply()
            })
        }
    }
}

@Composable
fun VoiceCommandSettings(sharedPreferences: SharedPreferences) {
    var voiceCommandEnabled by remember { mutableStateOf(sharedPreferences.getBoolean("voice_command_enabled", false)) }
    var voicePassphrase by remember { mutableStateOf(sharedPreferences.getString("voice_passphrase", "start recording") ?: "start recording") }

    Column {
        Text(text = "Voice Commands", style = MaterialTheme.typography.titleMedium)
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("Enable Voice Commands")
            Spacer(Modifier.weight(1f))
            Switch(checked = voiceCommandEnabled, onCheckedChange = { isChecked ->
                voiceCommandEnabled = isChecked
                sharedPreferences.edit().putBoolean("voice_command_enabled", isChecked).apply()
            })
        }
        OutlinedTextField(
            value = voicePassphrase,
            onValueChange = { newValue ->
                voicePassphrase = newValue
                sharedPreferences.edit().putString("voice_passphrase", newValue).apply()
            },
            label = { Text("Voice Passphrase") },
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
fun EmergencyContacts(context: Context) {
    val contactDao = remember { AppDatabase.getDatabase(context).contactDao() }
    var contacts by remember { mutableStateOf(emptyList<Contact>()) }
    var newContactName by remember { mutableStateOf("") }
    var newContactNumber by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        contacts = contactDao.getAllContacts()
    }

    Column {
        Text(text = "Emergency Contacts", style = MaterialTheme.typography.titleMedium)

        contacts.forEach { contact ->
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("${contact.name} (${contact.phoneNumber})")
                Spacer(Modifier.weight(1f))
                IconButton(onClick = {
                    scope.launch {
                        contactDao.delete(contact)
                        contacts = contactDao.getAllContacts()
                    }
                }) {
                    Icon(Icons.Default.Delete, contentDescription = "Delete Contact")
                }
            }
        }

        OutlinedTextField(
            value = newContactName,
            onValueChange = { newContactName = it },
            label = { Text("Contact Name") },
            modifier = Modifier.fillMaxWidth()
        )
        OutlinedTextField(
            value = newContactNumber,
            onValueChange = { newContactNumber = it },
            label = { Text("Contact Number") },
            modifier = Modifier.fillMaxWidth()
        )
        Button(onClick = {
            if (newContactName.isNotBlank() && newContactNumber.isNotBlank()) {
                scope.launch {
                    contactDao.insert(Contact(name = newContactName, phoneNumber = newContactNumber))
                    contacts = contactDao.getAllContacts()
                    newContactName = ""
                    newContactNumber = ""
                }
            }
        }) {
            Text("Add Contact")
        }
    }
}