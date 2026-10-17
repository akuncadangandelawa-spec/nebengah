package com.aixauusd.analyzer.util

import android.graphics.Bitmap
import android.util.Base64
import java.io.ByteArrayOutputStream

object BitmapUtils {

    fun scaleBitmapToMaxDimension(bitmap: Bitmap, maxDimension: Int = 1600): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        if (width <= maxDimension && height <= maxDimension) {
            return bitmap
        }

        val ratio = width.toFloat() / height.toFloat()
        val targetWidth: Int
        val targetHeight: Int

        if (width > height) {
            targetWidth = maxDimension
            targetHeight = (maxDimension / ratio).toInt()
        } else {
            targetHeight = maxDimension
            targetWidth = (maxDimension * ratio).toInt()
        }

        return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
    }

    fun bitmapToBase64(bitmap: Bitmap, quality: Int = 80): String {
        val scaled = scaleBitmapToMaxDimension(bitmap, 1600)
        val outputStream = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
        val bytes = outputStream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }
}
