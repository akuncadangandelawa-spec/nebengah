package com.aixauusd.analyzer.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.aixauusd.analyzer.data.local.dao.AnalysisHistoryDao
import com.aixauusd.analyzer.data.local.dao.ChatDao
import com.aixauusd.analyzer.data.local.entity.AnalysisHistoryEntity
import com.aixauusd.analyzer.data.local.entity.ChatMessageEntity

@Database(
    entities = [ChatMessageEntity::class, AnalysisHistoryEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun chatDao(): ChatDao
    abstract fun analysisHistoryDao(): AnalysisHistoryDao
}
