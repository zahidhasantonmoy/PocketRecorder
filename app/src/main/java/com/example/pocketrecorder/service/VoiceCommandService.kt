package com.example.pocketrecorder.service

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.IBinder
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import com.example.pocketrecorder.ActionType
import com.example.pocketrecorder.data.AppDatabase
import com.example.pocketrecorder.data.RecordedFile
import com.example.pocketrecorder.security.FileEncryptionManager
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.util.Locale

class VoiceCommandService : Service(), RecognitionListener {

    private lateinit var speechRecognizer: SpeechRecognizer
    private lateinit var speechRecognizerIntent: Intent
    private lateinit var db: AppDatabase
    private lateinit var fileEncryptionManager: FileEncryptionManager
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    // Customizable settings
    private var voiceCommandEnabled: Boolean = false
    private var customPassphrase: String = "start recording"
    private var voiceSensitivity: Float = 0.5f // Placeholder for actual sensitivity

    override fun onCreate() {
        super.onCreate()
        db = AppDatabase.getDatabase(this)
        fileEncryptionManager = FileEncryptionManager(this)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer.setRecognitionListener(this)

        speechRecognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }
        loadSettings()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (voiceCommandEnabled) {
            startListening()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun startListening() {
        speechRecognizer.startListening(speechRecognizerIntent)
        Log.d("VoiceCommandService", "Started listening for voice commands.")
    }

    private fun stopListening() {
        speechRecognizer.stopListening()
        Log.d("VoiceCommandService", "Stopped listening for voice commands.")
    }

    private fun loadSettings() {
        val sharedPreferences = getSharedPreferences("PocketRecorderSettings", Context.MODE_PRIVATE)
        voiceCommandEnabled = sharedPreferences.getBoolean("voice_command_enabled", false)
        customPassphrase = sharedPreferences.getString("custom_passphrase", "start recording") ?: "start recording"
        voiceSensitivity = sharedPreferences.getFloat("voice_sensitivity", 0.5f)
        Log.d("VoiceCommandService", "Settings loaded: voiceCommandEnabled=$voiceCommandEnabled, customPassphrase=$customPassphrase, voiceSensitivity=$voiceSensitivity")
    }

    override fun onReadyForSpeech(params: Bundle?) {
        Log.d("VoiceCommandService", "onReadyForSpeech")
    }

    override fun onBeginningOfSpeech() {
        Log.d("VoiceCommandService", "onBeginningOfSpeech")
    }

    override fun onRmsChanged(rmsdB: Float) {
        // Log.d("VoiceCommandService", "onRmsChanged: $rmsdB")
    }

    override fun onBufferReceived(buffer: ByteArray?) {
        Log.d("VoiceCommandService", "onBufferReceived")
    }

    override fun onEndOfSpeech() {
        Log.d("VoiceCommandService", "onEndOfSpeech")
    }

    override fun onError(error: Int) {
        val errorMessage = when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "No match"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "RecognitionService busy"
            SpeechRecognizer.ERROR_SERVER -> "Server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
            else -> "Unknown error"
        }
        Log.e("VoiceCommandService", "onError: $errorMessage ($error)")
        // Restart listening if an error occurs, unless it's a permission error
        if (error != SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
            startListening()
        }
    }

    override fun onResults(results: Bundle?) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (!matches.isNullOrEmpty()) {
            val recognizedText = matches[0]
            Log.d("VoiceCommandService", "onResults: $recognizedText")
            if (recognizedText.contains(customPassphrase, ignoreCase = true)) {
                Log.d("VoiceCommandService", "Passphrase detected! Triggering audio recording.")
                triggerAudioRecording()
            }
        }
        startListening() // Continue listening
    }

    override fun onPartialResults(partialResults: Bundle?) {
        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (!matches.isNullOrEmpty()) {
            Log.d("VoiceCommandService", "onPartialResults: ${matches[0]}")
        }
    }

    override fun onEvent(eventType: Int, params: Bundle?) {
        Log.d("VoiceCommandService", "onEvent: $eventType")
    }

    private fun triggerAudioRecording() {
        // This is a simplified placeholder. In a real app, you'd start actual audio recording.
        // For now, we'll just create a dummy encrypted file and save metadata.
        if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            fusedLocationClient.lastLocation
                .addOnSuccessListener { location ->
                    val currentTime = System.currentTimeMillis()
                    val fileExtension = ".mp3"
                    val directory = File(filesDir, ActionType.AUDIO_RECORDING.name.toLowerCase())
                    if (!directory.exists()) directory.mkdirs()
                    val originalFile = File(directory, "voice_recording_${currentTime}${fileExtension}")
                    FileOutputStream(originalFile).use { it.write("This is a dummy voice recording.".toByteArray()) }

                    val encryptedFilePath = File(directory, "encrypted_voice_recording_${currentTime}${fileExtension}.enc").absolutePath
                    val encryptedFile = File(encryptedFilePath)
                    fileEncryptionManager.encryptFile(originalFile, encryptedFile)
                    originalFile.delete() // Delete original unencrypted file
                    Log.d("VoiceCommandService", "Dummy voice recording encrypted to ${encryptedFile.absolutePath}")

                    val recordedFile = RecordedFile(
                        filePath = encryptedFilePath,
                        fileType = ActionType.AUDIO_RECORDING.name,
                        timestamp = currentTime,
                        latitude = location?.latitude,
                        longitude = location?.longitude,
                        isEncrypted = true
                    )
                    CoroutineScope(Dispatchers.IO).launch {
                        db.recordedFileDao().insertRecordedFile(recordedFile)
                        Log.d("VoiceCommandService", "Recorded voice file metadata saved: $recordedFile")
                    }
                }
                .addOnFailureListener { e ->
                    Log.e("VoiceCommandService", "Failed to get location for voice recording: ${e.message}")
                }
        } else {
            Log.w("VoiceCommandService", "RECORD_AUDIO permission not granted. Cannot trigger voice recording.")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        speechRecognizer.destroy()
        Log.d("VoiceCommandService", "VoiceCommandService destroyed.")
    }
}