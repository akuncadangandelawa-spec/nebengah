package com.aixauusd.analyzer.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aixauusd.analyzer.R
import com.aixauusd.analyzer.data.preferences.AppSettings
import kotlinx.coroutines.flow.collectLatest

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel,
    onNavigateBack: () -> Unit
) {
    val settings by viewModel.settingsState.collectAsState()
    val isTesting by viewModel.isTestingEndpoint.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(key1 = true) {
        viewModel.uiEvent.collectLatest { event ->
            when (event) {
                is SettingsUiEvent.ShowSnackbar -> {
                    snackbarHostState.showSnackbar(event.message)
                }
                is SettingsUiEvent.SettingsSaved -> {
                    onNavigateBack()
                }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings_title), color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = Color.White
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = colorResource(R.color.bg_dark)
                )
            )
        },
        bottomBar = {
            Surface(
                color = colorResource(R.color.surface_dark),
                shadowElevation = 8.dp
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    OutlinedButton(
                        onClick = onNavigateBack,
                        modifier = Modifier.weight(1f).padding(end = 8.dp)
                    ) {
                        Text(stringResource(R.string.btn_cancel), color = Color.White)
                    }
                    Button(
                        onClick = { viewModel.saveSettings() },
                        modifier = Modifier.weight(1f).padding(start = 8.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = colorResource(R.color.accent_blue)
                        )
                    ) {
                        Text(stringResource(R.string.btn_save), color = Color.White)
                    }
                }
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = colorResource(R.color.bg_dark)
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Section A: Model AI Active
            Text(
                text = stringResource(R.string.section_ai_model),
                style = MaterialTheme.typography.titleMedium,
                color = colorResource(R.color.accent_blue),
                fontWeight = FontWeight.Bold
            )

            Column(Modifier.selectableGroup()) {
                val radioOptions = listOf(
                    "Gemini Flash (Free)" to ("GEMINI" to "gemini-1.5-flash"),
                    "Gemini Pro Preview (Free)" to ("GEMINI" to "gemini-1.5-pro"),
                    "Gemini Flash Preview (Free)" to ("GEMINI" to "gemini-2.0-flash-exp"),
                    "Custom Gemini API" to ("GEMINI" to "custom"),
                    "OpenAI" to ("OPENAI" to "gpt-4o-mini"),
                    "Groq (Free tier)" to ("GROQ" to "llama-3.3-70b-versatile"),
                    "OpenRouter" to ("OPENROUTER" to "google/gemini-flash-1.5")
                )

                radioOptions.forEach { (label, optionPair) ->
                    val (provider, model) = optionPair
                    val isSelected = settings.activeProvider == provider &&
                            (model == "custom" || settings.activeModel == model || (provider != "GEMINI"))

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp)
                            .selectable(
                                selected = isSelected,
                                onClick = {
                                    viewModel.updateSettings {
                                        it.copy(
                                            activeProvider = provider,
                                            activeModel = if (model != "custom") model else it.activeModel
                                        )
                                    }
                                },
                                role = Role.RadioButton
                            ),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = isSelected,
                            onClick = null,
                            colors = RadioButtonDefaults.colors(selectedColor = colorResource(R.color.accent_blue))
                        )
                        Text(
                            text = label,
                            color = Color.White,
                            modifier = Modifier.padding(start = 12.dp)
                        )
                    }
                }
            }

            // Provider Configurations
            Text(
                text = stringResource(R.string.section_additional_providers),
                style = MaterialTheme.typography.titleMedium,
                color = colorResource(R.color.accent_blue),
                fontWeight = FontWeight.Bold
            )

            // Gemini API Key Field
            OutlinedTextField(
                value = settings.geminiApiKey,
                onValueChange = { key -> viewModel.updateSettings { it.copy(geminiApiKey = key) } },
                label = { Text("Gemini API Key") },
                modifier = Modifier.fillMaxWidth(),
                colors = customTextFieldColors()
            )

            HorizontalDivider(color = colorResource(R.color.border_color))

            // OpenAI Fields
            Text("OpenAI Configuration", color = Color.White, fontWeight = FontWeight.SemiBold)
            OutlinedTextField(
                value = settings.openAiApiKey,
                onValueChange = { key -> viewModel.updateSettings { it.copy(openAiApiKey = key) } },
                label = { Text(stringResource(R.string.label_api_key)) },
                modifier = Modifier.fillMaxWidth(),
                colors = customTextFieldColors()
            )
            OutlinedTextField(
                value = settings.openAiBaseUrl,
                onValueChange = { url -> viewModel.updateSettings { it.copy(openAiBaseUrl = url) } },
                label = { Text(stringResource(R.string.label_base_url)) },
                modifier = Modifier.fillMaxWidth(),
                colors = customTextFieldColors()
            )
            OutlinedTextField(
                value = settings.openAiModel,
                onValueChange = { model -> viewModel.updateSettings { it.copy(openAiModel = model) } },
                label = { Text(stringResource(R.string.label_model_name)) },
                modifier = Modifier.fillMaxWidth(),
                colors = customTextFieldColors()
            )

            HorizontalDivider(color = colorResource(R.color.border_color))

            // Groq Fields
            Text("Groq Configuration (Free Tier)", color = Color.White, fontWeight = FontWeight.SemiBold)
            OutlinedTextField(
                value = settings.groqApiKey,
                onValueChange = { key -> viewModel.updateSettings { it.copy(groqApiKey = key) } },
                label = { Text(stringResource(R.string.label_api_key)) },
                modifier = Modifier.fillMaxWidth(),
                colors = customTextFieldColors()
            )
            OutlinedTextField(
                value = settings.groqBaseUrl,
                onValueChange = { url -> viewModel.updateSettings { it.copy(groqBaseUrl = url) } },
                label = { Text(stringResource(R.string.label_base_url)) },
                modifier = Modifier.fillMaxWidth(),
                colors = customTextFieldColors()
            )
            OutlinedTextField(
                value = settings.groqModel,
                onValueChange = { model -> viewModel.updateSettings { it.copy(groqModel = model) } },
                label = { Text(stringResource(R.string.label_model_name)) },
                modifier = Modifier.fillMaxWidth(),
                colors = customTextFieldColors()
            )

            HorizontalDivider(color = colorResource(R.color.border_color))

            // OpenRouter Fields
            Text("OpenRouter Configuration", color = Color.White, fontWeight = FontWeight.SemiBold)
            OutlinedTextField(
                value = settings.openRouterApiKey,
                onValueChange = { key -> viewModel.updateSettings { it.copy(openRouterApiKey = key) } },
                label = { Text(stringResource(R.string.label_api_key)) },
                modifier = Modifier.fillMaxWidth(),
                colors = customTextFieldColors()
            )
            OutlinedTextField(
                value = settings.openRouterModel,
                onValueChange = { model -> viewModel.updateSettings { it.copy(openRouterModel = model) } },
                label = { Text(stringResource(R.string.label_model_name)) },
                modifier = Modifier.fillMaxWidth(),
                colors = customTextFieldColors()
            )

            HorizontalDivider(color = colorResource(R.color.border_color))

            // Section B: Kreativitas AI
            Text(
                text = stringResource(R.string.section_creativity),
                style = MaterialTheme.typography.titleMedium,
                color = colorResource(R.color.accent_blue),
                fontWeight = FontWeight.Bold
            )

            Text(
                text = stringResource(R.string.label_temperature, settings.temperature),
                color = Color.White
            )
            Slider(
                value = settings.temperature,
                onValueChange = { temp -> viewModel.updateSettings { it.copy(temperature = temp) } },
                valueRange = 0.0f..2.0f,
                steps = 20,
                colors = SliderDefaults.colors(
                    thumbColor = colorResource(R.color.accent_blue),
                    activeTrackColor = colorResource(R.color.accent_blue)
                )
            )

            Text(
                text = stringResource(R.string.label_max_tokens, settings.maxTokens),
                color = Color.White
            )
            Slider(
                value = settings.maxTokens.toFloat(),
                onValueChange = { tokens -> viewModel.updateSettings { it.copy(maxTokens = tokens.toInt()) } },
                valueRange = 256f..4096f,
                steps = 15,
                colors = SliderDefaults.colors(
                    thumbColor = colorResource(R.color.accent_blue),
                    activeTrackColor = colorResource(R.color.accent_blue)
                )
            )

            HorizontalDivider(color = colorResource(R.color.border_color))

            // Section C: System Instruction
            Text(
                text = stringResource(R.string.section_system_instruction),
                style = MaterialTheme.typography.titleMedium,
                color = colorResource(R.color.accent_blue),
                fontWeight = FontWeight.Bold
            )

            OutlinedTextField(
                value = settings.systemInstruction,
                onValueChange = { inst -> viewModel.updateSettings { it.copy(systemInstruction = inst) } },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                colors = customTextFieldColors()
            )

            TextButton(onClick = { viewModel.resetSystemInstructionToDefault() }) {
                Text(stringResource(R.string.btn_reset_default), color = colorResource(R.color.accent_blue))
            }

            HorizontalDivider(color = colorResource(R.color.border_color))

            // Section D: Uji Endpoint
            Button(
                onClick = { viewModel.testEndpoint() },
                enabled = !isTesting,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = colorResource(R.color.accent_blue)
                )
            ) {
                if (isTesting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(stringResource(R.string.btn_test_endpoint), color = Color.White)
                }
            }
        }
    }
}

@Composable
private fun customTextFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedBorderColor = colorResource(R.color.accent_blue),
    unfocusedBorderColor = colorResource(R.color.border_color),
    focusedLabelColor = colorResource(R.color.accent_blue),
    unfocusedLabelColor = colorResource(R.color.text_secondary),
    focusedTextColor = Color.White,
    unfocusedTextColor = Color.White
)
