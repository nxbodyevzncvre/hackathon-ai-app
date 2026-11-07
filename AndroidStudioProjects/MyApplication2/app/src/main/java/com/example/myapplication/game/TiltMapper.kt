package com.example.myapplication.game

import kotlin.math.abs
import kotlin.math.pow
import kotlin.math.sign


class TiltMapper(
    private val deadZone: Float = DEAD_ZONE,
    private val curveExponent: Float = CURVE_EXPONENT,
) {
    private var neutral: Vec2 = Vec2(0f, 0f)
    private var calibrationSamples = 0
    private var idleTime = 0f


    fun map(raw: Vec2, dt: Float): Vec2 {
        if (calibrationSamples < CALIBRATION_SAMPLES) {
            neutral = neutral + (raw - neutral) * CALIBRATION_BLEND
            calibrationSamples++
            idleTime += dt
            return Vec2(0f, 0f)
        }

        val offset = raw - neutral

        if (abs(offset.x) < deadZone && abs(offset.y) < deadZone) {
            idleTime += dt
            if (idleTime > RECENTER_DELAY) {
                val k = (RECENTER_SPEED * dt).coerceIn(0f, 1f)
                neutral = neutral + offset * k
            }
        } else {
            idleTime = 0f
        }

        return Vec2(mapAxis(offset.x), mapAxis(offset.y))
    }

    private fun mapAxis(t: Float): Float {
        val value = abs(t)
        if (value <= deadZone) return 0f
        val normalized = (value - deadZone) / (1f - deadZone)
        return sign(t) * normalized.pow(curveExponent)
    }

    fun reset() {
        neutral = Vec2(0f, 0f)
        calibrationSamples = 0
        idleTime = 0f
    }

    companion object {
        const val DEAD_ZONE = 0.05f

        const val CURVE_EXPONENT = 1.15f

        const val CALIBRATION_SAMPLES = 3

        const val CALIBRATION_BLEND = 0.5f

        const val RECENTER_DELAY = 0.75f

        const val RECENTER_SPEED = 1.5f
    }
}
