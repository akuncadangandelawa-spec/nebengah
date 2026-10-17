package com.aixauusd.analyzer.ui.dashboard.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.rememberAsyncImagePainter
import com.aixauusd.analyzer.R
import com.aixauusd.analyzer.data.local.entity.ChatMessageEntity
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun ChatMessageList(
    messages: List<ChatMessageEntity>,
    isLoading: Boolean,
    modifier: Modifier = Modifier
) {
    val listState = rememberLazyListState()

    LaunchedEffect(messages.size, isLoading) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    LazyColumn(
        state = listState,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(messages) { msg ->
            ChatMessageBubble(message = msg)
        }

        if (isLoading) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Start
                ) {
                    Box(
                        modifier = Modifier
                            .background(
                                colorResource(R.color.surface_dark),
                                RoundedCornerShape(12.dp)
                            )
                            .border(
                                1.dp,
                                colorResource(R.color.border_color),
                                RoundedCornerShape(12.dp)
                            )
                            .padding(12.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                color = colorResource(R.color.accent_blue),
                                strokeWidth = 2.dp
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                "AI sedang menganalisa...",
                                color = colorResource(R.color.text_secondary),
                                fontSize = 12.sp
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ChatMessageBubble(message: ChatMessageEntity) {
    val isUser = message.sender == "USER"
    val timeFormat = remember { SimpleDateFormat("HH:mm", Locale.getDefault()) }
    val formattedTime = remember(message.timestamp) { timeFormat.format(Date(message.timestamp)) }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start
    ) {
        Column(
            horizontalAlignment = if (isUser) Alignment.End else Alignment.Start,
            modifier = Modifier.widthIn(max = 280.dp)
        ) {
            Box(
                modifier = Modifier
                    .clip(
                        RoundedCornerShape(
                            topStart = 16.dp,
                            topEnd = 16.dp,
                            bottomStart = if (isUser) 16.dp else 4.dp,
                            bottomEnd = if (isUser) 4.dp else 16.dp
                        )
                    )
                    .background(
                        if (isUser) colorResource(R.color.user_bubble) else colorResource(R.color.ai_bubble)
                    )
                    .then(
                        if (!isUser) Modifier.border(
                            1.dp,
                            colorResource(R.color.border_color),
                            RoundedCornerShape(16.dp)
                        ) else Modifier
                    )
                    .padding(12.dp)
            ) {
                Column {
                    if (!message.imagePath.isNullByBlank()) {
                        Image(
                            painter = rememberAsyncImagePainter(message.imagePath),
                            contentDescription = "Attached image",
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(140.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .padding(bottom = 8.dp),
                            contentScale = ContentScale.Crop
                        )
                    }

                    Text(
                        text = message.text,
                        color = Color.White,
                        fontSize = 14.sp
                    )
                }
            }

            Text(
                text = formattedTime,
                color = colorResource(R.color.text_secondary),
                fontSize = 10.sp,
                modifier = Modifier.padding(top = 2.dp, start = 4.dp, end = 4.dp)
            )
        }
    }
}

private fun String?.isNullByBlank(): Boolean = this == null || this.isBlank()
