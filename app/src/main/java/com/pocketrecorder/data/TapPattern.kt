package com.pocketrecorder.data

data class TapPattern(
    val id: String,
    val intervals: List<Long>, // Time differences between taps
    val action: String // "audio", "video", "image"
)