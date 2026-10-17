package com.aixauusd.analyzer.di

import android.content.Context
import androidx.room.Room
import com.aixauusd.analyzer.data.ai.AiProviderFactory
import com.aixauusd.analyzer.data.ai.api.GeminiApi
import com.aixauusd.analyzer.data.local.AppDatabase
import com.aixauusd.analyzer.data.local.dao.AnalysisHistoryDao
import com.aixauusd.analyzer.data.local.dao.ChatDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        val logging = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
        return OkHttpClient.Builder()
            .addInterceptor(logging)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideGeminiApi(okHttpClient: OkHttpClient): GeminiApi {
        return Retrofit.Builder()
            .baseUrl("https://generativelanguage.googleapis.com/")
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(GeminiApi::class.java)
    }

    @Provides
    @Singleton
    fun provideAiProviderFactory(
        geminiApi: GeminiApi,
        okHttpClient: OkHttpClient
    ): AiProviderFactory {
        return AiProviderFactory(geminiApi, okHttpClient)
    }

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "ai_xauusd_db"
        ).fallbackToDestructiveMigration().build()
    }

    @Provides
    fun provideChatDao(database: AppDatabase): ChatDao = database.chatDao()

    @Provides
    fun provideAnalysisHistoryDao(database: AppDatabase): AnalysisHistoryDao = database.analysisHistoryDao()
}
