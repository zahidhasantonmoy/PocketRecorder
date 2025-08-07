package com.pocketrecorder.ui

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import android.content.Context
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.pocketrecorder.service.TapDetectionService
import com.pocketrecorder.ui.theme.PocketRecorderTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.IconButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.pocketrecorder.data.FileRepository
import java.io.File

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

                    val cameraActionViewModel: CameraActionViewModel = viewModel()

                    PocketRecorderApp(tutorialShown, cameraActionViewModel) {
                        sharedPrefs.edit().putBoolean("tutorial_shown", true).apply()
                    }
                    startService(Intent(this, TapDetectionService::class.java))

                    val cameraActionReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            when (intent?.action) {
                                "com.pocketrecorder.ACTION_START_VIDEO_RECORDING" -> {
                                    cameraActionViewModel.setCameraAction(CameraAction.VIDEO)
                                }
                                "com.pocketrecorder.ACTION_CAPTURE_IMAGE" -> {
                                    cameraActionViewModel.setCameraAction(CameraAction.IMAGE)
                                }
                            }
                        }
                    }

                    val filter = IntentFilter().apply {
                        addAction("com.pocketrecorder.ACTION_START_VIDEO_RECORDING")
                        addAction("com.pocketrecorder.ACTION_CAPTURE_IMAGE")
                    }
                    LocalBroadcastManager.getInstance(this).registerReceiver(cameraActionReceiver, filter)

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
    object Camera : Screen("camera", "Camera", { Icon(Icons.Filled.Home, contentDescription = "Camera") })
    object SlapTraining : Screen("slap_training", "Slap Training", { Icon(Icons.Filled.Settings, contentDescription = "Slap Training") })
}

@Composable
fun PocketRecorderApp(tutorialShown: Boolean, cameraActionViewModel: CameraActionViewModel, onTutorialComplete: () -> Unit) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    val cameraAction by cameraActionViewModel.cameraAction.collectAsState()

    LaunchedEffect(cameraAction) {
        when (cameraAction) {
            CameraAction.VIDEO -> {
                navController.navigate(Screen.Camera.route + "/video")
                cameraActionViewModel.resetCameraAction()
            }
            CameraAction.IMAGE -> {
                navController.navigate(Screen.Camera.route + "/image")
                cameraActionViewModel.resetCameraAction()
            }
            CameraAction.NONE -> { /* Do nothing */ }
        }
    }

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
                                    popUpTo(navController.graph.startDestinationId) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = if (tutorialShown) Screen.Home.route else Screen.Tutorial.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Home.route) { HomeScreen(navController) }
            composable(Screen.Settings.route) { SettingsScreen(navController) }
            composable(Screen.RecordedFiles.route) {
                val context = LocalContext.current
                val fileRepository = remember { FileRepository(context) }
                val viewModel: RecordedFilesViewModel = viewModel(factory = RecordedFilesViewModelFactory(fileRepository))
                RecordedFilesScreen(viewModel)
            }
            composable(Screen.Tutorial.route) { TutorialScreen(onTutorialComplete = { navController.navigate(Screen.Home.route) }) }
            composable(Screen.SlapTraining.route) { SlapTrainingScreen() }
            
        }
    }
}

