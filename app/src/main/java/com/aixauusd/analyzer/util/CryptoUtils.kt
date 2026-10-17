package com.aixauusd.analyzer.util

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

object CryptoUtils {

    private fun getEncryptedPreferences(context: Context) = EncryptedSharedPreferences.create(
        context,
        "secure_keys_prefs",
        MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun saveEncryptedKey(context: Context, keyName: String, value: String) {
        try {
            getEncryptedPreferences(context).edit().putString(keyName, value).apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun getEncryptedKey(context: Context, keyName: String, defaultValue: String = ""): String {
        return try {
            getEncryptedPreferences(context).getString(keyName, defaultValue) ?: defaultValue
        } catch (e: Exception) {
            defaultValue
        }
    }
}
