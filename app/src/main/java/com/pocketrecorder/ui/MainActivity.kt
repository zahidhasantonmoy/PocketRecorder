package com.pocketrecorder.ui

import android.Manifest
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.pocketrecorder.service.TapDetectionService
import com.pocketrecorder.ui.theme.PocketRecorderTheme

@OptIn(ExperimentalPermissionsApi::class)
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            PocketRecorderTheme {
                val permissionsState = rememberMultiplePermissionsState(
                    permissions = listOf(
                        Manifest.permission.RECORD_AUDIO,
                        Manifest.permission.CAMERA,
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.SEND_SMS
                    )
                )

                if (permissionsState.allPermissionsGranted) {
                    PocketRecorderApp()
                    startService(Intent(this, TapDetectionService::class.java))
                } else {
                    Column {
                        Text("Permissions required")
                        Button(onClick = { permissionsState.launchMultiplePermissionRequest() }) {
                            Text("Request permissions")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun PocketRecorderApp() {
    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = "home") {
        composable("home") { HomeScreen(navController) }
        composable("settings") { SettingsScreen() }
    }
}

@Composable
fun HomeScreen(navController: NavController) {
    Column(modifier = Modifier.fillMaxSize()) {
        Text(text = "PocketRecorder is active.")
        Button(onClick = { navController.navigate("settings") }) {
            Text("Settings")
        }
    }
}