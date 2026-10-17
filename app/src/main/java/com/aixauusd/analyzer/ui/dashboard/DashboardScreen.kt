package com.aixauusd.analyzer.ui.dashboard

import android.webkit.WebView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aixauusd.analyzer.R
import com.aixauusd.analyzer.ui.dashboard.components.*
import com.aixauusd.analyzer.util.WebViewBitmapCapture
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    viewModel: MainViewModel,
    onNavigateToSettings: () -> Unit
) {
    val chatMessages by viewModel.chatMessages.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val timeframe by viewModel.selectedTimeframe.collectAsState()
    val indicators by viewModel.selectedIndicators.collectAsState()
    val pendingUris by viewModel.pendingImageUris.collectAsState()
    val capturedBitmap by viewModel.capturedChartBitmap.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    var activeWebView by remember { mutableStateOf<WebView?>(null) }
    val textInputState = remember { mutableStateOf("") }

    LaunchedEffect(key1 = true) {
        viewModel.uiEvent.collectLatest { event ->
            when (event) {
                is DashboardUiEvent.ShowSnackbar -> {
                    snackbarHostState.showSnackbar(event.message)
                }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.dashboard_title), color = Color.White) },
                actions = {
                    IconButton(onClick = { activeWebView?.reload() }) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = stringResource(R.string.reload_chart),
                            tint = Color.White
                        )
                    }
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(
                            imageVector = Icons.Default.Settings,
                            contentDescription = "Settings",
                            tint = Color.White
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = colorResource(R.color.bg_dark)
                )
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = colorResource(R.color.bg_dark)
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Chart Section
            TradingViewChartWidget(
                timeframe = timeframe,
                selectedIndicators = indicators,
                onTimeframeChange = { viewModel.updateTimeframe(it) },
                onIndicatorToggle = { viewModel.toggleIndicator(it) },
                onWebViewCreated = { webView -> activeWebView = webView }
            )

            // Button Snapshot Chart
            Button(
                onClick = {
                    activeWebView?.let { webView ->
                        scope.launch {
                            val bitmap = WebViewBitmapCapture.captureWebView(webView)
                            if (bitmap != null) {
                                viewModel.setCapturedBitmap(bitmap)
                            } else {
                                snackbarHostState.showSnackbar("Gagal mengambil gambar chart")
                            }
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = colorResource(R.color.surface_variant_dark)
                )
            ) {
                Text(stringResource(R.string.btn_screenshot), color = Color.White)
            }

            // Question Chips Row
            QuestionChipsRow(
                onChipClick = { templateText ->
                    textInputState.value = templateText
                }
            )

            // Chat Messages List
            ChatMessageList(
                messages = chatMessages,
                isLoading = isLoading,
                modifier = Modifier.weight(1f)
            )

            // Chat Input Bar
            ChatInputBar(
                pendingUris = pendingUris,
                onAddUri = { viewModel.addPendingImage(it) },
                onRemoveUri = { viewModel.removePendingImage(it) },
                onSend = { userText ->
                    viewModel.sendChatMessage(
                        text = userText,
                        imageUrisStrings = pendingUris.map { it.toString() }
                    )
                },
                textInputState = textInputState
            )
        }
    }

    // BottomSheet for Screenshot analysis
    if (capturedBitmap != null) {
        ScreenshotAnalysisBottomSheet(
            bitmap = capturedBitmap,
            onDismiss = { viewModel.dismissScreenshotBottomSheet() },
            onAnalyze = { manualPrompt, bitmap ->
                viewModel.dismissScreenshotBottomSheet()
                viewModel.sendChatMessage(
                    text = manualPrompt,
                    images = listOf(bitmap)
                )
            }
        )
    }
}
