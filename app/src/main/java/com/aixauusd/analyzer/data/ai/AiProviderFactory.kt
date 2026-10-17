package com.aixauusd.analyzer.data.ai

import com.aixauusd.analyzer.data.ai.api.GeminiApi
import com.aixauusd.analyzer.data.ai.api.OpenAiCompatibleApi
import com.aixauusd.analyzer.data.ai.provider.GeminiProvider
import com.aixauusd.analyzer.data.ai.provider.GroqProvider
import com.aixauusd.analyzer.data.ai.provider.OpenAiProvider
import com.aixauusd.analyzer.data.ai.provider.OpenRouterProvider
import com.aixauusd.analyzer.data.preferences.AppSettings
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

class AiProviderFactory(
    private val defaultGeminiApi: GeminiApi,
    private val okHttpClient: OkHttpClient
) {
    fun getProvider(settings: AppSettings): AiProvider {
        return when (settings.activeProvider.uppercase()) {
            "GEMINI" -> GeminiProvider(
                geminiApi = defaultGeminiApi,
                apiKey = settings.geminiApiKey,
                modelName = settings.activeModel
            )
            "OPENAI" -> {
                val retrofit = createRetrofit(settings.openAiBaseUrl)
                val api = retrofit.create(OpenAiCompatibleApi::class.java)
                OpenAiProvider(
                    api = api,
                    apiKey = settings.openAiApiKey,
                    modelName = settings.openAiModel
                )
            }
            "GROQ" -> {
                val retrofit = createRetrofit(settings.groqBaseUrl)
                val api = retrofit.create(OpenAiCompatibleApi::class.java)
                GroqProvider(
                    api = api,
                    apiKey = settings.groqApiKey,
                    modelName = settings.groqModel
                )
            }
            "OPENROUTER" -> {
                val retrofit = createRetrofit(settings.openRouterBaseUrl)
                val api = retrofit.create(OpenAiCompatibleApi::class.java)
                OpenRouterProvider(
                    api = api,
                    apiKey = settings.openRouterApiKey,
                    modelName = settings.openRouterModel
                )
            }
            else -> GeminiProvider(
                geminiApi = defaultGeminiApi,
                apiKey = settings.geminiApiKey,
                modelName = settings.activeModel
            )
        }
    }

    private fun createRetrofit(baseUrl: String): Retrofit {
        val validBaseUrl = if (baseUrl.isNotBlank()) {
            if (baseUrl.endsWith("/")) baseUrl else "$baseUrl/"
        } else {
            "https://api.openai.com/v1/"
        }

        return Retrofit.Builder()
            .baseUrl(validBaseUrl)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }
}
