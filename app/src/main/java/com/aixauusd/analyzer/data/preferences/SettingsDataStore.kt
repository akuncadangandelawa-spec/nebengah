package com.aixauusd.analyzer.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import com.aixauusd.analyzer.util.CryptoUtils
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "ai_xauusd_settings")

data class AppSettings(
    val activeProvider: String = "GEMINI", // GEMINI, OPENAI, GROQ, OPENROUTER
    val activeModel: String = "gemini-1.5-flash",
    val geminiApiKey: String = "",
    val openAiApiKey: String = "",
    val openAiBaseUrl: String = "https://api.openai.com/v1/",
    val openAiModel: String = "gpt-4o-mini",
    val groqApiKey: String = "",
    val groqBaseUrl: String = "https://api.groq.com/openai/v1/",
    val groqModel: String = "llama-3.3-70b-versatile",
    val openRouterApiKey: String = "",
    val openRouterBaseUrl: String = "https://openrouter.ai/api/v1/",
    val openRouterModel: String = "google/gemini-flash-1.5",
    val temperature: Float = 0.7f,
    val maxTokens: Int = 2048,
    val systemInstruction: String = "Kamu adalah analis forex profesional yang ahli membaca chart TradingView. Jawab ringkas, terstruktur, dan sertakan level harga konkret jika terlihat di chart."
)

@Singleton
class SettingsDataStore @Inject constructor(
    private val context: Context
) {
    private object Keys {
        val ACTIVE_PROVIDER = stringPreferencesKey("active_provider")
        val ACTIVE_MODEL = stringPreferencesKey("active_model")
        val OPENAI_BASE_URL = stringPreferencesKey("openai_base_url")
        val OPENAI_MODEL = stringPreferencesKey("openai_model")
        val GROQ_BASE_URL = stringPreferencesKey("groq_base_url")
        val GROQ_MODEL = stringPreferencesKey("groq_model")
        val OPENROUTER_BASE_URL = stringPreferencesKey("openrouter_base_url")
        val OPENROUTER_MODEL = stringPreferencesKey("openrouter_model")
        val TEMPERATURE = floatPreferencesKey("temperature")
        val MAX_TOKENS = intPreferencesKey("max_tokens")
        val SYSTEM_INSTRUCTION = stringPreferencesKey("system_instruction")
    }

    val settingsFlow: Flow<AppSettings> = context.dataStore.data.map { prefs ->
        AppSettings(
            activeProvider = prefs[Keys.ACTIVE_PROVIDER] ?: "GEMINI",
            activeModel = prefs[Keys.ACTIVE_MODEL] ?: "gemini-1.5-flash",
            geminiApiKey = CryptoUtils.getEncryptedKey(context, "gemini_api_key"),
            openAiApiKey = CryptoUtils.getEncryptedKey(context, "openai_api_key"),
            openAiBaseUrl = prefs[Keys.OPENAI_BASE_URL] ?: "https://api.openai.com/v1/",
            openAiModel = prefs[Keys.OPENAI_MODEL] ?: "gpt-4o-mini",
            groqApiKey = CryptoUtils.getEncryptedKey(context, "groq_api_key"),
            groqBaseUrl = prefs[Keys.GROQ_BASE_URL] ?: "https://api.groq.com/openai/v1/",
            groqModel = prefs[Keys.GROQ_MODEL] ?: "llama-3.3-70b-versatile",
            openRouterApiKey = CryptoUtils.getEncryptedKey(context, "openrouter_api_key"),
            openRouterBaseUrl = prefs[Keys.OPENROUTER_BASE_URL] ?: "https://openrouter.ai/api/v1/",
            openRouterModel = prefs[Keys.OPENROUTER_MODEL] ?: "google/gemini-flash-1.5",
            temperature = prefs[Keys.TEMPERATURE] ?: 0.7f,
            maxTokens = prefs[Keys.MAX_TOKENS] ?: 2048,
            systemInstruction = prefs[Keys.SYSTEM_INSTRUCTION]
                ?: "Kamu adalah analis forex profesional yang ahli membaca chart TradingView. Jawab ringkas, terstruktur, dan sertakan level harga konkret jika terlihat di chart."
        )
    }

    suspend fun saveSettings(settings: AppSettings) {
        CryptoUtils.saveEncryptedKey(context, "gemini_api_key", settings.geminiApiKey)
        CryptoUtils.saveEncryptedKey(context, "openai_api_key", settings.openAiApiKey)
        CryptoUtils.saveEncryptedKey(context, "groq_api_key", settings.groqApiKey)
        CryptoUtils.saveEncryptedKey(context, "openrouter_api_key", settings.openRouterApiKey)

        context.dataStore.edit { prefs ->
            prefs[Keys.ACTIVE_PROVIDER] = settings.activeProvider
            prefs[Keys.ACTIVE_MODEL] = settings.activeModel
            prefs[Keys.OPENAI_BASE_URL] = settings.openAiBaseUrl
            prefs[Keys.OPENAI_MODEL] = settings.openAiModel
            prefs[Keys.GROQ_BASE_URL] = settings.groqBaseUrl
            prefs[Keys.GROQ_MODEL] = settings.groqModel
            prefs[Keys.OPENROUTER_BASE_URL] = settings.openRouterBaseUrl
            prefs[Keys.OPENROUTER_MODEL] = settings.openRouterModel
            prefs[Keys.TEMPERATURE] = settings.temperature
            prefs[Keys.MAX_TOKENS] = settings.maxTokens
            prefs[Keys.SYSTEM_INSTRUCTION] = settings.systemInstruction
        }
    }
}
