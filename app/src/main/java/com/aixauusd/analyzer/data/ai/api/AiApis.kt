package com.aixauusd.analyzer.data.ai.api

import com.aixauusd.analyzer.data.ai.dto.GeminiRequest
import com.aixauusd.analyzer.data.ai.dto.GeminiResponse
import com.aixauusd.analyzer.data.ai.dto.OpenAiRequest
import com.aixauusd.analyzer.data.ai.dto.OpenAiResponse
import retrofit2.Response
import retrofit2.http.*

interface GeminiApi {
    @POST("v1beta/models/{model}:generateContent")
    suspend fun generateContent(
        @Path("model") model: String,
        @Query("key") apiKey: String,
        @Body request: GeminiRequest
    ): Response<GeminiResponse>
}

interface OpenAiCompatibleApi {
    @POST("chat/completions")
    suspend fun chatCompletions(
        @Header("Authorization") authorization: String,
        @Body request: OpenAiRequest
    ): Response<OpenAiResponse>
}
