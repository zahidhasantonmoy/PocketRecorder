package com.pocketrecorder.ui

import android.Manifest
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import android.content.Context
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.pocketrecorder.service.TapDetectionService
import com.pocketrecorder.ui.theme.PocketRecorderTheme

private const val TAG = "MainActivity"

@OptIn(ExperimentalPermissionsApi::class)
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate called")
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

                Log.d(TAG, "All permissions granted: ${permissionsState.allPermissionsGranted}")

                if (permissionsState.allPermissionsGranted) {
                    val sharedPrefs = getSharedPreferences("PocketRecorderPrefs", Context.MODE_PRIVATE)
                    val tutorialShown = sharedPrefs.getBoolean("tutorial_shown", false)

                    PocketRecorderApp(tutorialShown) {
                        sharedPrefs.edit().putBoolean("tutorial_shown", true).apply()
                    }
                    startService(Intent(this, TapDetectionService::class.java))
                } else {
                    Column {
                        Text("Permissions required")
                        Button(onClick = {
                            Log.d(TAG, "Request permissions button clicked")
                            permissionsState.launchMultiplePermissionRequest()
                        }) {
                            Text("Request permissions")
                        }
                    }
                }
            }
        }
    }
}

sealed class Screen(val route: String, val title: String, val icon: @Composable () -> Unit) {
    object Home : Screen("home", "Home", { Icon(Icons.Filled.Home, contentDescription = "Home") })
    object Settings : Screen("settings", "Settings", { Icon(Icons.Filled.Settings, contentDescription = "Settings") })
    object RecordedFiles : Screen("recorded_files", "Files", { Icon(Icons.Filled.List, contentDescription = "Recorded Files") })
    object Tutorial : Screen("tutorial", "Tutorial", { Icon(Icons.Filled.Home, contentDescription = "Tutorial") }) // No icon for tutorial
}

@Composable
fun PocketRecorderApp(tutorialShown: Boolean, onTutorialComplete: () -> Unit) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            if (currentRoute != Screen.Tutorial.route) { // Hide bottom bar on tutorial screen
                NavigationBar {
                    val items = listOf(Screen.Home, Screen.RecordedFiles, Screen.Settings)
                    items.forEach { screen ->
                        NavigationBarItem(
                            icon = { screen.icon() },
                            label = { Text(screen.title) },
                            selected = currentRoute == screen.route,
                            onClick = {
                                navController.navigate(screen.route) {
                                    // Pop up to the start destination of the graph to
                                    // avoid building up a large stack of destinations
                                    // on the back stack as users select items
                                    popUpTo(navController.graph.startDestinationId) {
                                        saveState = true
                                    }
                                    // Avoid multiple copies of the same destination when
                                    // reselecting the same item
                                    launchSingleTop = true
                                    // Restore state when reselecting a previously selected item
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(navController = navController, startDestination = if (tutorialShown) Screen.Home.route else Screen.Tutorial.route) {
            composable(Screen.Home.route) { HomeScreen(navController) }
            composable(Screen.Settings.route) { SettingsScreen() }
            composable(Screen.RecordedFiles.route) { RecordedFilesScreen() }
            composable(Screen.Tutorial.route) { TutorialScreen(onTutorialComplete = { navController.navigate(Screen.Home.route) }) }
        }
    }
}

