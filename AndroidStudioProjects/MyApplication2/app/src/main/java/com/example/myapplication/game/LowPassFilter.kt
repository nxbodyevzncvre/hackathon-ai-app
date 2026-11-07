package com.example.myapplication.game


class LowPassFilter(private val tau: Float = TAU_SECONDS) {
    private var state: Vec2? = null

    fun filter(value: Vec2, dt: Float): Vec2 {
        val current = state
        val out = when {
            current == null -> value
            dt <= 0f -> current
            else -> {
                val alpha = dt / (dt + tau)
                current + (value - current) * alpha
            }
        }
        state = out
        return out
    }

    fun reset() {
        state = null
    }

    companion object {
        const val TAU_SECONDS = 0.05f
    }
}
