package com.pocketrecorder.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun TutorialScreen(onTutorialComplete: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(text = "Welcome to PocketRecorder!\n\nThis app allows you to record audio, video, and capture images using tap patterns, even when your phone is in your pocket.")
        Text(text = "\nTap Pattern Detection:\n- 3 taps: Start audio recording\n- 4 taps: Start video recording\n- 2 taps: Capture image\n- 5 rapid taps: Trigger emergency mode (sends location and files via SMS)")
        Text(text = "\nCustomization:\nYou can customize tap counts, sensitivity, and other settings in the app's settings.")
        Text(text = "\nPrivacy and Security:\nAll your recordings are encrypted and hidden. You can secure access with biometric authentication.")
        Text(text = "\nGet Started!\nExplore the app and customize it to your needs. Enjoy discreet recording!")

        Button(onClick = onTutorialComplete, modifier = Modifier.padding(top = 16.dp)) {
            Text("Finish Tutorial")
        }
    }
}