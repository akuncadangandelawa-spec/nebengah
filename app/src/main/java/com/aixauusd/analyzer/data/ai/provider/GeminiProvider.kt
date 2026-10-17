package com.aixauusd.analyzer.data.ai.provider

import android.graphics.Bitmap
import com.aixauusd.analyzer.data.ai.AiProvider
import com.aixauusd.analyzer.data.ai.ChatMessage
import com.aixauusd.analyzer.data.ai.api.GeminiApi
import com.aixauusd.analyzer.data.ai.dto.*
import com.aixauusd.analyzer.util.BitmapUtils

class GeminiProvider(
    private val geminiApi: GeminiApi,
    private val apiKey: String,
    private val modelName: String
) : AiProvider {

    override suspend fun chat(
        messages: List<ChatMessage>,
        images: List<Bitmap>,
        temperature: Double,
        systemInstruction: String
    ): Result<String> {
        return try {
            if (apiKey.isBlank()) {
                return Result.failure(IllegalArgumentException("API Key belum diisi"))
            }

            val contents = mutableListOf<GeminiContent>()

            messages.forEachIndexed { index, msg ->
                val role = if (msg.sender == "USER") "user" else "model"
                val parts = mutableListOf<GeminiPart>()

                if (msg.text.isNotBlank()) {
                    parts.add(GeminiPart(text = msg.text))
                }

                // Add message attached images if any
                msg.images.forEach { bmp ->
                    val base64 = BitmapUtils.bitmapToBase64(bmp)
                    parts.add(GeminiPart(inlineData = GeminiInlineData(data = base64)))
                }

                // Attach current snapshot images if this is the last user message
                if (index == messages.lastIndex && msg.sender == "USER") {
                    images.forEach { bmp ->
                        val base64 = BitmapUtils.bitmapToBase64(bmp)
                        parts.add(GeminiPart(inlineData = GeminiInlineData(data = base64)))
                    }
                }

                if (parts.isNotEmpty()) {
                    contents.add(GeminiContent(role = role, parts = parts))
                }
            }

            val systemInst = if (systemInstruction.isNotBlank()) {
                GeminiSystemInstruction(parts = listOf(GeminiPart(text = systemInstruction)))
            } else null

            val req = GeminiRequest(
                systemInstruction = systemInst,
                contents = contents,
                generationConfig = GeminiGenerationConfig(temperature = temperature)
            )

            val response = geminiApi.generateContent(model = modelName, apiKey = apiKey, request = req)
            if (response.isSuccessful) {
                val text = response.body()?.candidates?.firstOrNull()?.content?.parts?.firstOrNull()?.text
                if (text != null) {
                    Result.success(text)
                } else {
                    Result.failure(Exception("Response text is null"))
                }
            } else {
                val errorMsg = response.errorBody()?.string() ?: "HTTP ${response.code()}"
                Result.failure(Exception("Gemini Error: $errorMsg"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun testConnection(): Result<Long> {
        val startTime = System.currentTimeMillis()
        val testResult = chat(
            messages = listOf(ChatMessage(sender = "USER", text = "ping")),
            images = emptyList(),
            temperature = 0.1,
            systemInstruction = "Jawab 'pong'"
        )
        val latency = System.currentTimeMillis() - startTime
        return if (testResult.isSuccess) {
            Result.success(latency)
        } else {
            Result.failure(testResult.exceptionOrNull() ?: Exception("Unknown error"))
        }
    }
}
