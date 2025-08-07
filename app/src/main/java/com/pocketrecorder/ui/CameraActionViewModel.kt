package com.pocketrecorder.ui

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

enum class CameraAction {
    NONE,
    IMAGE,
    VIDEO
}

class CameraActionViewModel : ViewModel() {
    private val _cameraAction = MutableStateFlow(CameraAction.NONE)
    val cameraAction = _cameraAction.asStateFlow()

    fun setCameraAction(action: CameraAction) {
        _cameraAction.value = action
    }

    fun resetCameraAction() {
        _cameraAction.value = CameraAction.NONE
    }
}
