package com.example.pocketrecorder

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import com.example.pocketrecorder.ui.theme.PocketRecorderTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            PocketRecorderTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen()
                }
            }
        }
    }
}

@Composable
fun MainScreen() {
    val context = LocalContext.current
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("PocketRecorder App")
        Button(onClick = {
            context.startService(Intent(context, com.example.pocketrecorder.service.TapDetectionService::class.java))
        }) {
            Text("Start Tap Detection Service")
        }
        Button(onClick = {
            context.stopService(Intent(context, com.example.pocketrecorder.service.TapDetectionService::class.java))
        }) {
            Text("Stop Tap Detection Service")
        }
        Button(onClick = {
            context.startActivity(Intent(context, SettingsActivity::class.java))
        }) {
            Text("Open Settings")
        }
    }
}

@Preview(showBackground = true)
@Composable
fun DefaultPreview() {
    PocketRecorderTheme {
        MainScreen()
    }
}
