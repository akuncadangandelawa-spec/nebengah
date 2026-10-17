package com.aixauusd.analyzer.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.aixauusd.analyzer.data.local.entity.AnalysisHistoryEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface AnalysisHistoryDao {
    @Query("SELECT * FROM analysis_history ORDER BY timestamp DESC")
    fun getAllHistory(): Flow<List<AnalysisHistoryEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHistory(history: AnalysisHistoryEntity): Long

    @Query("DELETE FROM analysis_history")
    suspend fun clearHistory()
}
