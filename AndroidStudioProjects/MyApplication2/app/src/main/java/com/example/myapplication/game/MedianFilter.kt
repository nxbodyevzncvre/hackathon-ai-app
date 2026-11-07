package com.example.myapplication.game

import kotlin.math.abs

class MedianFilter(private val window: Int = 3) {

    private var hx: FloatArray? = null
    private var hy: FloatArray? = null

    fun filter(value: Vec2): Vec2 {
        val x = hx?.let { push(it, value.x) } ?: FloatArray(window) { Float.NaN }
        val y = hy?.let { push(it, value.y) } ?: FloatArray(window) { Float.NaN }
        if (hx == null) {
            x[0] = value.x
            y[0] = value.y
            hx = x
            hy = y
            return value
        }
        hx = x
        hy = y
        return Vec2(median(x), median(y))
    }

    fun reset() {
        hx = null
        hy = null
    }

    private fun push(history: FloatArray, value: Float): FloatArray {
        for (i in history.size - 1 downTo 1) history[i] = history[i - 1]
        history[0] = value
        return history
    }

    private fun median(history: FloatArray): Float {
        val sorted = history.filter { !it.isNaN() }.sorted()
        if (sorted.isEmpty()) return 0f
        val mid = sorted.size / 2
        return if (sorted.size % 2 == 1) {
            sorted[mid]
        } else {
            (sorted[mid - 1] + sorted[mid]) / 2f
        }
    }

    companion object {
        const val WINDOW_DEFAULT = 3
    }
}
