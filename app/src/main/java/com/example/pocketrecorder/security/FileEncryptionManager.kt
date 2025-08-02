package com.example.pocketrecorder.security

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.security.crypto.EncryptedFile
import androidx.security.crypto.MasterKey
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class FileEncryptionManager(private val context: Context) {

    private val masterKey: MasterKey by lazy {
        val keyGenParameterSpec = KeyGenParameterSpec.Builder(
            MasterKey.DEFAULT_MASTER_KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(MasterKey.DEFAULT_AES_GCM_MASTER_KEY_SIZE)
            .build()
        MasterKey.Builder(context)
            .setKeyGenParameterSpec(keyGenParameterSpec)
            .build()
    }

    fun encryptFile(inputFile: File, outputFile: File) {
        val encryptedFile = EncryptedFile.Builder(
            context,
            outputFile,
            masterKey,
            EncryptedFile.FileEncryptionScheme.AES256_GCM_HKDF_4KB
        ).build()

        inputFile.inputStream().use { inputStream ->
            encryptedFile.openFileOutput().use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        }
    }

    fun decryptFile(encryptedFile: File, outputFile: File) {
        val encryptedFileInstance = EncryptedFile.Builder(
            context,
            encryptedFile,
            masterKey,
            EncryptedFile.FileEncryptionScheme.AES256_GCM_HKDF_4KB
        ).build()

        encryptedFileInstance.openFileInput().use { inputStream ->
            outputFile.outputStream().use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        }
    }
}