package com.aixauusd.analyzer.ui.dashboard.components

import android.content.Context
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import coil.compose.rememberAsyncImagePainter
import com.aixauusd.analyzer.R
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatInputBar(
    pendingUris: List<Uri>,
    onAddUri: (Uri) -> Unit,
    onRemoveUri: (Uri) -> Unit,
    onSend: (String) -> Unit,
    textInputState: MutableState<String>
) {
    val context = LocalContext.current
    var showAttachmentMenu by remember { mutableStateOf(false) }
    var tempCameraUri by remember { mutableStateOf<Uri?>(null) }

    val galleryLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { onAddUri(it) }
    }

    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success && tempCameraUri != null) {
            onAddUri(tempCameraUri!!)
        }
    }

    fun launchCamera() {
        val file = File(context.cacheDir, "camera_snap_${System.currentTimeMillis()}.jpg")
        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file
        )
        tempCameraUri = uri
        cameraLauncher.launch(uri)
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(colorResource(R.color.surface_dark))
            .padding(8.dp)
    ) {
        // Pending Image Thumbnails Preview
        if (pendingUris.isNotEmpty()) {
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(pendingUris) { uri ->
                    Box(modifier = Modifier.size(60.dp)) {
                        Image(
                            painter = rememberAsyncImagePainter(uri),
                            contentDescription = "Attachment preview",
                            modifier = Modifier
                                .fillMaxSize()
                                .clip(RoundedCornerShape(8.dp)),
                            contentScale = ContentScale.Crop
                        )
                        IconButton(
                            onClick = { onRemoveUri(uri) },
                            modifier = Modifier
                                .size(20.dp)
                                .align(Alignment.TopEnd)
                                .background(Color.Black.copy(alpha = 0.7f), CircleShape)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = "Remove",
                                tint = Color.White,
                                modifier = Modifier.size(12.dp)
                            )
                        }
                    }
                }
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box {
                IconButton(onClick = { showAttachmentMenu = true }) {
                    Icon(
                        imageVector = Icons.Default.AttachFile,
                        contentDescription = "Attach image",
                        tint = colorResource(R.color.text_secondary)
                    )
                }

                DropdownMenu(
                    expanded = showAttachmentMenu,
                    onDismissRequest = { showAttachmentMenu = false },
                    modifier = Modifier.background(colorResource(R.color.surface_variant_dark))
                ) {
                    DropdownMenuItem(
                        text = { Text("Galeri", color = Color.White) },
                        leadingIcon = { Icon(Icons.Default.Image, contentDescription = null, tint = Color.White) },
                        onClick = {
                            showAttachmentMenu = false
                            galleryLauncher.launch("image/*")
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Kamera", color = Color.White) },
                        leadingIcon = { Icon(Icons.Default.CameraAlt, contentDescription = null, tint = Color.White) },
                        onClick = {
                            showAttachmentMenu = false
                            launchCamera()
                        }
                    )
                }
            }

            OutlinedTextField(
                value = textInputState.value,
                onValueChange = { textInputState.value = it },
                placeholder = { Text(stringResource(R.string.chat_hint), color = colorResource(R.color.text_secondary), fontSize = 14.sp) },
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 4.dp),
                maxLines = 4,
                shape = RoundedCornerShape(20.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = colorResource(R.color.accent_blue),
                    unfocusedBorderColor = colorResource(R.color.border_color),
                    focusedContainerColor = colorResource(R.color.bg_dark),
                    unfocusedContainerColor = colorResource(R.color.bg_dark),
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                )
            )

            IconButton(
                onClick = {
                    val txt = textInputState.value
                    if (txt.isNotBlank() || pendingUris.isNotEmpty()) {
                        onSend(txt)
                        textInputState.value = ""
                    }
                },
                modifier = Modifier
                    .size(44.dp)
                    .background(colorResource(R.color.accent_blue), CircleShape)
            ) {
                Icon(
                    imageVector = Icons.Default.Send,
                    contentDescription = "Send",
                    tint = Color.White,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}
