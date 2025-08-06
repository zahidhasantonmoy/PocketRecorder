package com.pocketrecorder.ui

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import com.pocketrecorder.service.TapDetectionService

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(navController: NavController) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("PocketRecorder") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { navController.navigate("settings") }) {
                Icon(Icons.Filled.Settings, "Settings")
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "PocketRecorder is active.",
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier.padding(bottom = 16.dp)
            )
            Text(
                text = "Listening for tap patterns...",
                style = MaterialTheme.typography.bodyLarge
            )
            Spacer(modifier = Modifier.height(16.dp))
            SensorDataIndicator()
        }
    }
}

@Composable
fun SensorDataIndicator() {
    val context = LocalContext.current
    val serviceIntent = remember { Intent(context, TapDetectionService::class.java) }

    // Start the service if it's not already running (optional, depending on app lifecycle)
    // This ensures the service is running to provide sensor data
    DisposableEffect(Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
        onDispose { /* No explicit stop here, service manages its own lifecycle */ }
    }

    val acceleration by TapDetectionService.currentAcceleration.collectAsState()

    // In a real app, you'd get the StateFlow from the running service instance
    // For example, if TapDetectionService exposed a static accessor or a ViewModel
    // val acceleration by TapDetectionService.currentAcceleration.collectAsState()

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(text = "Current Acceleration: %.2f".format(acceleration), style = MaterialTheme.typography.bodyMedium)
        // You can add a visual element here, e.g., a colored circle or a bar
        // based on the acceleration value
    }
}