package com.aixauusd.analyzer.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "chat_messages")
data class ChatMessageEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val sender: String, // "USER" or "AI"
    val text: String,
    val imagePath: String? = null,
    val timestamp: Long = System.currentTimeMillis()
)
