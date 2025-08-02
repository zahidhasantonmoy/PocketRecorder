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

            Button(onClick = {
                with(sharedPreferences.edit()) {
                    putFloat("sensitivity_threshold", sensitivity)
                    putLong("time_window", timeWindow.toLong())
                    apply()
                }
            }) {
                Text("Save Settings")
            }
        }
    }
}