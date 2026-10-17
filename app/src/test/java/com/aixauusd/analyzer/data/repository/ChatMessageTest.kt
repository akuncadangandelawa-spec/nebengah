package com.aixauusd.analyzer.data.repository

import com.aixauusd.analyzer.data.local.entity.ChatMessageEntity
import org.junit.Assert.assertEquals
import org.junit.Test

class ChatMessageTest {
    @Test
    fun testChatMessageEntity() {
        val message = ChatMessageEntity(
            sender = "USER",
            text = "Analisa trend",
            imagePath = "/path/to/img.jpg"
        )
        assertEquals("USER", message.sender)
        assertEquals("Analisa trend", message.text)
        assertEquals("/path/to/img.jpg", message.imagePath)
    }
}
