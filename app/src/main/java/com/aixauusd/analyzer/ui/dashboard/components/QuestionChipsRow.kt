package com.aixauusd.analyzer.ui.dashboard.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.SuggestionChip
import androidx.compose.material3.SuggestionChipDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aixauusd.analyzer.R

@Composable
fun QuestionChipsRow(
    onChipClick: (String) -> Unit
) {
    val templates = listOf(
        "Analisa trend saat ini",
        "Cari area support & resistance",
        "Ada pola candlestick penting?",
        "Sinyal entry buy/sell?",
        "Rekomendasi SL & TP",
        "Kondisi overbought/oversold?",
        "Breakout atau fakeout?"
    )

    LazyRow(
        modifier = Modifier
            .fillMaxWidth()
            .background(colorResource(R.color.bg_dark))
            .padding(horizontal = 8.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(templates) { template ->
            SuggestionChip(
                onClick = { onChipClick(template) },
                label = {
                    Text(
                        text = template,
                        color = Color.White,
                        fontSize = 12.sp
                    )
                },
                colors = SuggestionChipDefaults.suggestionChipColors(
                    containerColor = colorResource(R.color.surface_variant_dark)
                ),
                border = SuggestionChipDefaults.suggestionChipBorder(
                    enabled = true,
                    borderColor = colorResource(R.color.border_color)
                ),
                shape = RoundedCornerShape(16.dp)
            )
        }
    }
}
