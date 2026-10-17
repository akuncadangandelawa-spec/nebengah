package com.aixauusd.analyzer.ui.dashboard.components

import android.annotation.SuppressLint
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.aixauusd.analyzer.R

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun TradingViewChartWidget(
    timeframe: String,
    selectedIndicators: Set<String>,
    onTimeframeChange: (String) -> Unit,
    onIndicatorToggle: (String) -> Unit,
    onWebViewCreated: (WebView) -> Unit
) {
    var showTimeframeMenu by remember { mutableStateOf(false) }
    var showIndicatorDialog by remember { mutableStateOf(false) }

    val timeframeOptions = listOf("1m", "5m", "15m", "30m", "1H", "4H", "1D", "1W")
    val timeframeMap = mapOf(
        "1m" to "1",
        "5m" to "5",
        "15m" to "15",
        "30m" to "30",
        "1H" to "60",
        "4H" to "240",
        "1D" to "D",
        "1W" to "W"
    )

    val indicatorOptions = listOf(
        "EMA 20" to "EMA_20",
        "EMA 50" to "EMA_50",
        "EMA 200" to "EMA_200",
        "RSI" to "RSI",
        "MACD" to "MACD",
        "Bollinger Bands" to "BB",
        "Volume" to "VOLUME",
        "Stochastic" to "STOCH",
        "Fibonacci" to "FIB"
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(340.dp)
            .background(colorResource(R.color.bg_dark))
    ) {
        // Toolbar above Chart
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(colorResource(R.color.surface_dark))
                .padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // Timeframe Dropdown
            Box {
                OutlinedButton(
                    onClick = { showTimeframeMenu = true },
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                ) {
                    Text("TF: $timeframe", color = Color.White, fontSize = 12.sp)
                    Icon(
                        imageVector = Icons.Default.ArrowDropDown,
                        contentDescription = null,
                        tint = Color.White
                    )
                }

                DropdownMenu(
                    expanded = showTimeframeMenu,
                    onDismissRequest = { showTimeframeMenu = false },
                    modifier = Modifier.background(colorResource(R.color.surface_variant_dark))
                ) {
                    timeframeOptions.forEach { tf ->
                        DropdownMenuItem(
                            text = { Text(tf, color = Color.White) },
                            onClick = {
                                onTimeframeChange(tf)
                                showTimeframeMenu = false
                            }
                        )
                    }
                }
            }

            // Indicators Button
            OutlinedButton(
                onClick = { showIndicatorDialog = true },
                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.FilterList,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text("Indicators (${selectedIndicators.size})", color = Color.White, fontSize = 12.sp)
            }
        }

        // WebView TradingView Embedded Widget
        val intervalParam = timeframeMap[timeframe] ?: "60"
        val studiesParam = selectedIndicators.joinToString(",")
        val htmlUrl = "file:///android_asset/tradingview.html?symbol=OANDA:XAUUSD&interval=$intervalParam&studies=$studiesParam"

        AndroidView(
            factory = { context ->
                WebView(context).apply {
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    webViewClient = WebViewClient()
                    loadUrl(htmlUrl)
                    onWebViewCreated(this)
                }
            },
            update = { webView ->
                webView.loadUrl(htmlUrl)
            },
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
        )
    }

    // Multi-select Indicators Dialog
    if (showIndicatorDialog) {
        AlertDialog(
            onDismissRequest = { showIndicatorDialog = false },
            title = { Text("Pilih Indicators", color = Color.White) },
            text = {
                Column {
                    indicatorOptions.forEach { (label, key) ->
                        val isChecked = selectedIndicators.contains(key)
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp)
                        ) {
                            Checkbox(
                                checked = isChecked,
                                onCheckedChange = { onIndicatorToggle(key) },
                                colors = CheckboxDefaults.colors(
                                    checkedColor = colorResource(R.color.accent_blue)
                                )
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(label, color = Color.White)
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showIndicatorDialog = false }) {
                    Text("OK", color = colorResource(R.color.accent_blue))
                }
            },
            containerColor = colorResource(R.color.surface_dark)
        )
    }
}
