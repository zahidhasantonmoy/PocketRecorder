
package com.pocketrecorder.utils

import android.content.Context
import androidx.security.crypto.EncryptedFile
import androidx.security.crypto.MasterKeys
import java.io.File

object SecurityUtil {

    private fun getMasterKeyAlias(context: Context): String {
        return MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
    }

    fun getEncryptedFile(context: Context, file: File): EncryptedFile {
        return EncryptedFile.Builder(
            file,
            context,
            getMasterKeyAlias(context),
            EncryptedFile.FileEncryptionScheme.AES256_GCM_HKDF_4KB
        ).build()
    }
}
