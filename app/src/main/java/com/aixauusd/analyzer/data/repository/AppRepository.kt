package com.aixauusd.analyzer.data.repository

import com.aixauusd.analyzer.data.local.dao.AnalysisHistoryDao
import com.aixauusd.analyzer.data.local.dao.ChatDao
import com.aixauusd.analyzer.data.local.entity.AnalysisHistoryEntity
import com.aixauusd.analyzer.data.local.entity.ChatMessageEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AppRepository @Inject constructor(
    private val chatDao: ChatDao,
    private val historyDao: AnalysisHistoryDao
) {
    fun getChatMessages(): Flow<List<ChatMessageEntity>> = chatDao.getAllMessages()

    suspend fun addChatMessage(message: ChatMessageEntity): Long = chatDao.insertMessage(message)

    suspend fun clearChat() = chatDao.clearChat()

    fun getAnalysisHistory(): Flow<List<AnalysisHistoryEntity>> = historyDao.getAllHistory()

    suspend fun addAnalysisHistory(history: AnalysisHistoryEntity): Long = historyDao.insertHistory(history)

    suspend fun clearHistory() = historyDao.clearHistory()
}
