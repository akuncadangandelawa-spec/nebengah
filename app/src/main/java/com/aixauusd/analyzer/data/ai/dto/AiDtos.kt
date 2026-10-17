package com.aixauusd.analyzer.data.ai.dto

import com.google.gson.annotations.SerializedName

data class GeminiRequest(
    @SerializedName("system_instruction") val systemInstruction: GeminiSystemInstruction? = null,
    @SerializedName("contents") val contents: List<GeminiContent>,
    @SerializedName("generationConfig") val generationConfig: GeminiGenerationConfig? = null
)

data class GeminiSystemInstruction(
    @SerializedName("parts") val parts: List<GeminiPart>
)

data class GeminiContent(
    @SerializedName("role") val role: String, // "user" or "model"
    @SerializedName("parts") val parts: List<GeminiPart>
)

data class GeminiPart(
    @SerializedName("text") val text: String? = null,
    @SerializedName("inline_data") val inlineData: GeminiInlineData? = null
)

data class GeminiInlineData(
    @SerializedName("mime_type") val mimeType: String = "image/jpeg",
    @SerializedName("data") val data: String
)

data class GeminiGenerationConfig(
    @SerializedName("temperature") val temperature: Double? = null,
    @SerializedName("maxOutputTokens") val maxOutputTokens: Int? = null
)

data class GeminiResponse(
    @SerializedName("candidates") val candidates: List<GeminiCandidate>? = null,
    @SerializedName("error") val error: GeminiError? = null
)

data class GeminiCandidate(
    @SerializedName("content") val content: GeminiContent? = null
)

data class GeminiError(
    @SerializedName("code") val code: Int,
    @SerializedName("message") val message: String
)

// OpenAI Compatible DTOs (OpenAI, Groq, OpenRouter)
data class OpenAiRequest(
    @SerializedName("model") val model: String,
    @SerializedName("messages") val messages: List<OpenAiMessage>,
    @SerializedName("temperature") val temperature: Double? = null,
    @SerializedName("max_tokens") val maxTokens: Int? = null
)

data class OpenAiMessage(
    @SerializedName("role") val role: String, // "system", "user", "assistant"
    @SerializedName("content") val content: Any // String or List<OpenAiContentPart>
)

data class OpenAiContentPart(
    @SerializedName("type") val type: String, // "text" or "image_url"
    @SerializedName("text") val text: String? = null,
    @SerializedName("image_url") val imageUrl: OpenAiImageUrl? = null
)

data class OpenAiImageUrl(
    @SerializedName("url") val url: String
)

data class OpenAiResponse(
    @SerializedName("choices") val choices: List<OpenAiChoice>? = null,
    @SerializedName("error") val error: OpenAiError? = null
)

data class OpenAiChoice(
    @SerializedName("message") val message: OpenAiResponseMessage? = null
)

data class OpenAiResponseMessage(
    @SerializedName("role") val role: String,
    @SerializedName("content") val content: String?
)

data class OpenAiError(
    @SerializedName("message") val message: String,
    @SerializedName("type") val type: String? = null,
    @SerializedName("code") val code: Any? = null
)
