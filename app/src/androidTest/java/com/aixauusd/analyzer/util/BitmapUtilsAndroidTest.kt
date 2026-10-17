package com.aixauusd.analyzer.util

import android.graphics.Bitmap
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class BitmapUtilsAndroidTest {

    @Test
    fun testScaleBitmapToMaxDimension() {
        val original = Bitmap.createBitmap(3200, 2400, Bitmap.Config.ARGB_8888)
        val scaled = BitmapUtils.scaleBitmapToMaxDimension(original, 1600)
        assertEquals(1600, scaled.width)
        assertEquals(1200, scaled.height)
    }
}
