package com.aixauusd.analyzer.ui.dashboard

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aixauusd.analyzer.data.ai.AiProviderFactory
import com.aixauusd.analyzer.data.ai.ChatMessage
import com.aixauusd.analyzer.data.local.entity.AnalysisHistoryEntity
import com.aixauusd.analyzer.data.local.entity.ChatMessageEntity
import com.aixauusd.analyzer.data.preferences.AppSettings
import com.aixauusd.analyzer.data.preferences.SettingsDataStore
import com.aixauusd.analyzer.data.repository.AppRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import javax.inject.Inject

sealed class DashboardUiEvent {
    data class ShowSnackbar(val message: String) : DashboardUiEvent()
}

@HiltViewModel
class MainViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val repository: AppRepository,
    private val settingsDataStore: SettingsDataStore,
    private val providerFactory: AiProviderFactory
) : ViewModel() {

    val chatMessages: StateFlow<List<ChatMessageEntity>> = repository.getChatMessages()
        .stateIn(viewModelScope, SharingStarted.WhileSubsubscribed(5000), emptyList())

    val settingsState: StateFlow<AppSettings> = settingsDataStore.settingsFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubsubscribed(5000), AppSettings())

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _selectedTimeframe = MutableStateFlow("1H")
    val selectedTimeframe: StateFlow<String> = _selectedTimeframe.asStateFlow()

    private val _selectedIndicators = MutableStateFlow(setOf("EMA_20"))
    val selectedIndicators: StateFlow<Set<String>> = _selectedIndicators.asStateFlow()

    private val _pendingImageUris = MutableStateFlow<List<Uri>>(emptyList())
    val pendingImageUris: StateFlow<List<Uri>> = _pendingImageUris.asStateFlow()

    private val _capturedChartBitmap = MutableStateFlow<Bitmap?>(null)
    val capturedChartBitmap: StateFlow<Bitmap?> = _capturedChartBitmap.asStateFlow()

    private val _showScreenshotBottomSheet = MutableStateFlow(false)
    val showScreenshotBottomSheet: StateFlow<Boolean> = _showScreenshotBottomSheet.asStateFlow()

    private val _uiEvent = MutableSharedFlow<DashboardUiEvent>()
    val uiEvent: SharedFlow<DashboardUiEvent> = _uiEvent.asSharedFlow()

    fun updateTimeframe(tf: String) {
        _selectedTimeframe.value = tf
    }

    fun toggleIndicator(indicator: String) {
        val current = _selectedIndicators.value.toMutableSet()
        if (current.contains(indicator)) {
            current.remove(indicator)
        } else {
            current.add(indicator)
        }
        _selectedIndicators.value = current
    }

    fun addPendingImage(uri: Uri) {
        _pendingImageUris.value = _pendingImageUris.value + uri
    }

    fun removePendingImage(uri: Uri) {
        _pendingImageUris.value = _pendingImageUris.value - uri
    }

    fun clearPendingImages() {
        _pendingImageUris.value = emptyList()
    }

    fun setCapturedBitmap(bitmap: Bitmap?) {
        _capturedChartBitmap.value = bitmap
        _showScreenshotBottomSheet.value = bitmap != null
    }

    fun dismissScreenshotBottomSheet() {
        _showScreenshotBottomSheet.value = false
        _capturedChartBitmap.value = null
    }

    fun sendChatMessage(
        text: String,
        images: List<Bitmap> = emptyList(),
        imageUrisStrings: List<String> = emptyList()
    ) {
        if (text.isBlank() && images.isEmpty() && imageUrisStrings.isEmpty()) return

        viewModelScope.launch {
            val settings = settingsState.value
            val activeKey = when (settings.activeProvider.uppercase()) {
                "GEMINI" -> settings.geminiApiKey
                "OPENAI" -> settings.openAiApiKey
                "GROQ" -> settings.groqApiKey
                "OPENROUTER" -> settings.openRouterApiKey
                else -> settings.geminiApiKey
            }

            if (activeKey.isBlank()) {
                _uiEvent.emit(DashboardUiEvent.ShowSnackbar("API Key belum diisi untuk provider aktif (${settings.activeProvider})"))
                return@launch
            }

            // Save user message to Room
            val imageUriStr = imageUrisStrings.firstOrNull()
            val userEntity = ChatMessageEntity(
                sender = "USER",
                text = text,
                imagePath = imageUriStr
            )
            repository.addChatMessage(userEntity)
            clearPendingImages()

            _isLoading.value = true

            // Convert image Uris to Bitmaps
            val resolvedBitmaps = withContext(Dispatchers.IO) {
                val list = mutableListOf<Bitmap>()
                list.addAll(images)
                imageUrisStrings.forEach { uriString ->
                    try {
                        val uri = Uri.parse(uriString)
                        context.contentResolver.openInputStream(uri)?.use { inputStream ->
                            val bmp = BitmapFactory.decodeStream(inputStream)
                            if (bmp != null) list.add(bmp)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
                list
            }

            // Build historical chat messages for AI context
            val currentList = chatMessages.value
            val aiChatMessages = currentList.map { entity ->
                ChatMessage(
                    sender = entity.sender,
                    text = entity.text
                )
            } + ChatMessage(sender = "USER", text = text, images = resolvedBitmaps)

            val provider = providerFactory.getProvider(settings)
            val result = provider.chat(
                messages = aiChatMessages,
                images = resolvedBitmaps,
                temperature = settings.temperature.toDouble(),
                systemInstruction = settings.systemInstruction
            )

            _isLoading.value = false

            if (result.isSuccess) {
                val aiResponseText = result.getOrNull() ?: ""
                val aiEntity = ChatMessageEntity(
                    sender = "AI",
                    text = aiResponseText
                )
                repository.addChatMessage(aiEntity)

                // Save analysis history
                repository.addAnalysisHistory(
                    AnalysisHistoryEntity(
                        imageUri = imageUriStr,
                        prompt = text,
                        response = aiResponseText,
                        provider = settings.activeProvider,
                        model = settings.activeModel
                    )
                )
            } else {
                val err = result.exceptionOrNull()?.message ?: "Unknown error"
                _uiEvent.emit(DashboardUiEvent.ShowSnackbar("Error AI: $err"))
                repository.addChatMessage(
                    ChatMessageEntity(
                        sender = "AI",
                        text = "⚠️ Gagal mendapatkan respon dari AI ($err)."
                    )
                )
            }
        }
    }
}
