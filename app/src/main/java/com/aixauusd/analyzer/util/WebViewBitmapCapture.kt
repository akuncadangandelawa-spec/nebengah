package com.aixauusd.analyzer.util

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.PixelCopy
import android.webkit.WebView
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

object WebViewBitmapCapture {

    suspend fun captureWebView(webView: WebView): Bitmap? {
        if (webView.width <= 0 || webView.height <= 0) return null

        val activity = findActivity(webView.context)

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && activity != null) {
            suspendCoroutine { continuation ->
                val bitmap = Bitmap.createBitmap(
                    webView.width,
                    webView.height,
                    Bitmap.Config.ARGB_8888
                )
                val locationOfViewInWindow = IntArray(2)
                webView.getLocationInWindow(locationOfViewInWindow)
                val rect = android.graphics.Rect(
                    locationOfViewInWindow[0],
                    locationOfViewInWindow[1],
                    locationOfViewInWindow[0] + webView.width,
                    locationOfViewInWindow[1] + webView.height
                )

                try {
                    PixelCopy.request(
                        activity.window,
                        rect,
                        bitmap,
                        { copyResult ->
                            if (copyResult == PixelCopy.SUCCESS) {
                                continuation.resume(bitmap)
                            } else {
                                continuation.resume(fallbackCanvasCapture(webView))
                            }
                        },
                        Handler(Looper.getMainLooper())
                    )
                } catch (e: Exception) {
                    continuation.resume(fallbackCanvasCapture(webView))
                }
            }
        } else {
            fallbackCanvasCapture(webView)
        }
    }

    private fun findActivity(context: Context): Activity? {
        var current = context
        while (current is ContextWrapper) {
            if (current is Activity) return current
            current = current.baseContext ?: break
        }
        return null
    }

    private fun fallbackCanvasCapture(webView: WebView): Bitmap? {
        return try {
            val bitmap = Bitmap.createBitmap(
                webView.width,
                webView.height,
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bitmap)
            webView.draw(canvas)
            bitmap
        } catch (e: Exception) {
            null
        }
    }
}
