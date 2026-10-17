package com.aixauusd.analyzer.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aixauusd.analyzer.data.ai.AiProviderFactory
import com.aixauusd.analyzer.data.preferences.AppSettings
import com.aixauusd.analyzer.data.preferences.SettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed class SettingsUiEvent {
    data class ShowSnackbar(val message: String) : SettingsUiEvent()
    object SettingsSaved : SettingsUiEvent()
}

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore,
    private val providerFactory: AiProviderFactory
) : ViewModel() {

    private val _settingsState = MutableStateFlow(AppSettings())
    val settingsState: StateFlow<AppSettings> = _settingsState.asStateFlow()

    private val _isTestingEndpoint = MutableStateFlow(false)
    val isTestingEndpoint: StateFlow<Boolean> = _isTestingEndpoint.asStateFlow()

    private val _uiEvent = MutableSharedFlow<SettingsUiEvent>()
    val uiEvent: SharedFlow<SettingsUiEvent> = _uiEvent.asSharedFlow()

    init {
        viewModelScope.launch {
            val initial = settingsDataStore.settingsFlow.first()
            _settingsState.value = initial
        }
    }

    fun updateSettings(update: (AppSettings) -> AppSettings) {
        _settingsState.value = update(_settingsState.value)
    }

    fun saveSettings() {
        viewModelScope.launch {
            settingsDataStore.saveSettings(_settingsState.value)
            _uiEvent.emit(SettingsUiEvent.SettingsSaved)
        }
    }

    fun resetSystemInstructionToDefault() {
        _settingsState.value = _settingsState.value.copy(
            systemInstruction = "Kamu adalah analis forex profesional yang ahli membaca chart TradingView. Jawab ringkas, terstruktur, dan sertakan level harga konkret jika terlihat di chart."
        )
    }

    fun testEndpoint() {
        viewModelScope.launch {
            _isTestingEndpoint.value = true
            val currentSettings = _settingsState.value
            val provider = providerFactory.getProvider(currentSettings)

            val result = provider.testConnection()
            _isTestingEndpoint.value = false

            if (result.isSuccess) {
                val latency = result.getOrNull() ?: 0L
                _uiEvent.emit(SettingsUiEvent.ShowSnackbar("200 OK — Latency: $latency ms"))
            } else {
                val err = result.exceptionOrNull()?.message ?: "Unknown error"
                _uiEvent.emit(SettingsUiEvent.ShowSnackbar("Error: $err"))
            }
        }
    }
}
