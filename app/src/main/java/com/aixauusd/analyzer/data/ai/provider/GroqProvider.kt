package com.aixauusd.analyzer.data.ai.provider

import android.graphics.Bitmap
import com.aixauusd.analyzer.data.ai.AiProvider
import com.aixauusd.analyzer.data.ai.ChatMessage
import com.aixauusd.analyzer.data.ai.api.OpenAiCompatibleApi
import com.aixauusd.analyzer.data.ai.dto.OpenAiMessage
import com.aixauusd.analyzer.data.ai.dto.OpenAiRequest

class GroqProvider(
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

            var effectiveSystemInstruction = systemInstruction
            val hasImages = images.isNotEmpty() || messages.any { it.images.isNotEmpty() }
            if (hasImages) {
                effectiveSystemInstruction += "\n[Catatan: User melampirkan gambar, tetapi model Groq ini tidak mendukung input vision. Harap berikan analisa umum berdasarkan teks yang diberikan user.]"
            }

            if (effectiveSystemInstruction.isNotBlank()) {
                apiMessages.add(OpenAiMessage(role = "system", content = effectiveSystemInstruction))
            }

            messages.forEach { msg ->
                val role = if (msg.sender == "USER") "user" else "assistant"
                apiMessages.add(OpenAiMessage(role = role, content = msg.text))
            }

            val req = OpenAiRequest(
                model = modelName.ifBlank { "llama-3.3-70b-versatile" },
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
                Result.failure(Exception("Groq Error: $errorStr"))
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
