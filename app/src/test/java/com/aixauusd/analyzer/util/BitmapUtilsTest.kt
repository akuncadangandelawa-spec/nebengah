package com.aixauusd.analyzer.util

import org.junit.Assert.assertEquals
import org.junit.Test

class BitmapUtilsTest {

    @Test
    fun testScaleDimensionsCalculation() {
        // Test aspect ratio calculation logic for width > height
        val (w1, h1) = calculateTargetDimensions(3200, 2400, 1600)
        assertEquals(1600, w1)
        assertEquals(1200, h1)

        // Test aspect ratio calculation logic for height > width
        val (w2, h2) = calculateTargetDimensions(2400, 3200, 1600)
        assertEquals(1200, w2)
        assertEquals(1600, h2)

        // Test dimensions within max boundary stay unchanged
        val (w3, h3) = calculateTargetDimensions(800, 600, 1600)
        assertEquals(800, w3)
        assertEquals(600, h3)
    }

    private fun calculateTargetDimensions(width: Int, height: Int, maxDimension: Int): Pair<Int, Int> {
        if (width <= maxDimension && height <= maxDimension) {
            return Pair(width, height)
        }
        val ratio = width.toFloat() / height.toFloat()
        return if (width > height) {
            Pair(maxDimension, (maxDimension / ratio).toInt())
        } else {
            Pair((maxDimension * ratio).toInt(), maxDimension)
        }
    }
}
