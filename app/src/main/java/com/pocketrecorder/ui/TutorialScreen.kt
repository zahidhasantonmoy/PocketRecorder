package com.pocketrecorder.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
fun TutorialScreen(onTutorialComplete: () -> Unit) {
    Column(modifier = Modifier.fillMaxSize()) {
        Text("Tutorial", style = MaterialTheme.typography.headlineMedium)
        Button(onClick = onTutorialComplete) {
            Text("Skip Tutorial")
        }
    }
}
