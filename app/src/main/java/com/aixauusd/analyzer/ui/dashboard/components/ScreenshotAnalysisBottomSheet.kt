package com.aixauusd.analyzer.ui.dashboard.components

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aixauusd.analyzer.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScreenshotAnalysisBottomSheet(
    bitmap: Bitmap?,
    onDismiss: () -> Unit,
    onAnalyze: (String, Bitmap) -> Unit
) {
    if (bitmap == null) return

    var promptText by remember { mutableStateOf("") }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = colorResource(R.color.surface_dark)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .navigationBarsPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = stringResource(R.string.analysis_prompt_title),
                style = MaterialTheme.typography.titleMedium,
                color = Color.White,
                fontWeight = FontWeight.Bold
            )

            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = "Chart Screenshot",
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp)
                    .clip(RoundedCornerShape(8.dp))
            )

            OutlinedTextField(
                value = promptText,
                onValueChange = { promptText = it },
                placeholder = {
                    Text(
                        "Masukkan instruksi analisa (opsional, misal: 'Analisa trend & support resistance')...",
                        color = colorResource(R.color.text_secondary),
                        fontSize = 13.sp
                    )
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = colorResource(R.color.accent_blue),
                    unfocusedBorderColor = colorResource(R.color.border_color),
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                )
            )

            Button(
                onClick = {
                    val finalPrompt = if (promptText.isNotBlank()) promptText else "Tolong analisa chart TradingView XAUUSD ini."
                    onAnalyze(finalPrompt, bitmap)
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = colorResource(R.color.accent_blue)
                )
            ) {
                Text(stringResource(R.string.btn_analyze_ai), color = Color.White)
            }
        }
    }
}
