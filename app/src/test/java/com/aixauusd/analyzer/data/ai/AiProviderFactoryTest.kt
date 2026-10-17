package com.aixauusd.analyzer.data.ai

import com.aixauusd.analyzer.data.ai.api.GeminiApi
import com.aixauusd.analyzer.data.ai.provider.GeminiProvider
import com.aixauusd.analyzer.data.ai.provider.GroqProvider
import com.aixauusd.analyzer.data.ai.provider.OpenAiProvider
import com.aixauusd.analyzer.data.ai.provider.OpenRouterProvider
import com.aixauusd.analyzer.data.preferences.AppSettings
import okhttp3.OkHttpClient
import org.junit.Assert.assertTrue
import org.junit.Test

class AiProviderFactoryTest {

    private class FakeGeminiApi : GeminiApi {
        override suspend fun generateContent(
            model: String,
            apiKey: String,
            request: com.aixauusd.analyzer.data.ai.dto.GeminiRequest
        ): retrofit2.Response<com.aixauusd.analyzer.data.ai.dto.GeminiResponse> {
            return retrofit2.Response.success(com.aixauusd.analyzer.data.ai.dto.GeminiResponse())
        }
    }

    @Test
    fun testFactoryReturnsCorrectProviders() {
        val fakeGeminiApi = FakeGeminiApi()
        val okHttpClient = OkHttpClient()
        val factory = AiProviderFactory(fakeGeminiApi, okHttpClient)

        val geminiSettings = AppSettings(activeProvider = "GEMINI", geminiApiKey = "key1")
        val geminiProvider = factory.getProvider(geminiSettings)
        assertTrue(geminiProvider is GeminiProvider)

        val openAiSettings = AppSettings(activeProvider = "OPENAI", openAiApiKey = "key2")
        val openAiProvider = factory.getProvider(openAiSettings)
        assertTrue(openAiProvider is OpenAiProvider)

        val groqSettings = AppSettings(activeProvider = "GROQ", groqApiKey = "key3")
        val groqProvider = factory.getProvider(groqSettings)
        assertTrue(groqProvider is GroqProvider)

        val openRouterSettings = AppSettings(activeProvider = "OPENROUTER", openRouterApiKey = "key4")
        val openRouterProvider = factory.getProvider(openRouterSettings)
        assertTrue(openRouterProvider is OpenRouterProvider)
    }
}
