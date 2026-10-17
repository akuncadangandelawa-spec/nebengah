package com.aixauusd.analyzer.data.ai

import android.graphics.Bitmap

data class ChatMessage(
    val sender: String, // "USER" or "AI"
    val text: String,
    val images: List<Bitmap> = emptyList()
)

interface AiProvider {
    suspend fun chat(
        messages: List<ChatMessage>,
        images: List<Bitmap>,
        temperature: Double,
        systemInstruction: String
    ): Result<String>

    suspend fun testConnection(): Result<Long> // Returns latency in ms
}
