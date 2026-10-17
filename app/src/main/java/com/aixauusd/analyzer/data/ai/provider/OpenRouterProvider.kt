package com.aixauusd.analyzer.data.ai.provider

import android.graphics.Bitmap
import com.aixauusd.analyzer.data.ai.AiProvider
import com.aixauusd.analyzer.data.ai.ChatMessage
import com.aixauusd.analyzer.data.ai.api.OpenAiCompatibleApi
import com.aixauusd.analyzer.data.ai.dto.*
import com.aixauusd.analyzer.util.BitmapUtils

class OpenRouterProvider(
    private val api: OpenAiCompatibleApi,
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

            val apiMessages = mutableListOf<OpenAiMessage>()

            if (systemInstruction.isNotBlank()) {
                apiMessages.add(OpenAiMessage(role = "system", content = systemInstruction))
            }

            messages.forEachIndexed { index, msg ->
                val role = if (msg.sender == "USER") "user" else "assistant"
                val allImages = mutableListOf<Bitmap>()
                allImages.addAll(msg.images)

                if (index == messages.lastIndex && msg.sender == "USER") {
                    allImages.addAll(images)
                }

                if (allImages.isEmpty()) {
                    apiMessages.add(OpenAiMessage(role = role, content = msg.text))
                } else {
                    val parts = mutableListOf<OpenAiContentPart>()
                    if (msg.text.isNotBlank()) {
                        parts.add(OpenAiContentPart(type = "text", text = msg.text))
                    }
                    allImages.forEach { bmp ->
                        val base64 = BitmapUtils.bitmapToBase64(bmp)
                        parts.add(
                            OpenAiContentPart(
                                type = "image_url",
                                imageUrl = OpenAiImageUrl(url = "data:image/jpeg;base64,$base64")
                            )
                        )
                    }
                    apiMessages.add(OpenAiMessage(role = role, content = parts))
                }
            }

            val req = OpenAiRequest(
                model = modelName.ifBlank { "google/gemini-flash-1.5" },
                messages = apiMessages,
                temperature = temperature
            )

            val authHeader = if (apiKey.startsWith("Bearer ")) apiKey else "Bearer $apiKey"
            val response = api.chatCompletions(authorization = authHeader, request = req)

            if (response.isSuccessful) {
                val reply = response.body()?.choices?.firstOrNull()?.message?.content
                if (reply != null) {
                    Result.success(reply)
                } else {
                    Result.failure(Exception("Response text is null"))
                }
            } else {
                val errorStr = response.errorBody()?.string() ?: "HTTP ${response.code()}"
                Result.failure(Exception("OpenRouter Error: $errorStr"))
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
