package com.pocketrecorder.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import kotlinx.coroutines.launch

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun TutorialScreen(onTutorialComplete: () -> Unit) {
    val pages = listOf(
        "Welcome to PocketRecorder!\n\nThis app allows you to record audio, video, and capture images using tap patterns, even when your phone is in your pocket.",
        "Tap Pattern Detection\n\n- 3 taps: Start audio recording\n- 4 taps: Start video recording\n- 2 taps: Capture image\n- 5 rapid taps: Trigger emergency mode (sends location and files via SMS)",
        "Customization\n\nYou can customize tap counts, sensitivity, and other settings in the app's settings.",
        "Privacy and Security\n\nAll your recordings are encrypted and hidden. You can secure access with biometric authentication.",
        "Get Started!\n\nExplore the app and customize it to your needs. Enjoy discreet recording!"
    )
    val pagerState = rememberPagerState(pageCount = { pages.size })
    val scope = rememberCoroutineScope()

    Column(modifier = Modifier.fillMaxSize()) {
        HorizontalPager(state = pagerState, modifier = Modifier.weight(1f)) {
            page ->
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(text = pages[page])
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (pagerState.currentPage > 0) {
                Button(onClick = {
                    scope.launch {
                        pagerState.animateScrollToPage(pagerState.currentPage - 1)
                    }
                }) {
                    Text("Previous")
                }
            }

            if (pagerState.currentPage < pages.size - 1) {
                Button(onClick = {
                    scope.launch {
                        pagerState.animateScrollToPage(pagerState.currentPage + 1)
                    }
                }) {
                    Text("Next")
                }
            } else {
                Button(onClick = onTutorialComplete) {
                    Text("Finish")
                }
            }
        }
    }
}