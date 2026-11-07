package com.example.myapplication.game

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class TiltMapperTest {

    private val dt = 1f / 60f

    private fun TiltMapper.warmUp(neutral: Vec2) {
        repeat(TiltMapper.CALIBRATION_SAMPLES) { map(neutral, dt) }
    }

    @Test
    fun calibrationPeriodProducesZeroInput() {
        val mapper = TiltMapper()
        var out = Vec2(0f, 0f)
        repeat(TiltMapper.CALIBRATION_SAMPLES - 1) {
            out = mapper.map(Vec2(0.4f, -0.3f), dt)
        }
        assertEquals(0f, out.x)
        assertEquals(0f, out.y)
    }

    @Test
    fun holdingPhoneAtAngleDoesNotDrift() {
        val mapper = TiltMapper()
        mapper.warmUp(Vec2(0.25f, -0.15f)) // phone held at an angle
        val out = mapper.map(Vec2(0.25f, -0.15f), dt)
        assertEquals(0f, out.x, 1e-4f)
        assertEquals(0f, out.y, 1e-4f)
    }

    @Test
    fun deadZoneSuppressesJitter() {
        val mapper = TiltMapper()
        val neutral = Vec2(0f, 0f)
        mapper.warmUp(neutral)
        // Hand jitter well below the dead zone.
        val out = mapper.map(Vec2(TiltMapper.DEAD_ZONE * 0.5f, 0f), dt)
        assertEquals(0f, out.x)
        assertEquals(0f, out.y)
    }

    @Test
    fun moderateTiltRespondsPromptly() {
        // ~14 degrees of tilt: a comfortable, quick dodge. The old tuning
        // (dead zone 0.10 + curve 1.3) produced only ~0.09 output for it —
        // the game felt sluggish. It must now give a solid, immediate input.
        val mapper = TiltMapper()
        mapper.warmUp(Vec2(0f, 0f))
        val out = mapper.map(Vec2(0.25f, 0f), dt)
        assertTrue("moderate tilt too weak: out.x = ${out.x}", out.x > 0.15f)
    }

    @Test
    fun fullTiltSaturatesAtOne() {
        val mapper = TiltMapper()
        mapper.warmUp(Vec2(0f, 0f))
        val out = mapper.map(Vec2(1f, -1f), dt)
        assertEquals(1f, out.x, 0.02f)
        assertEquals(-1f, out.y, 0.02f)
    }

    @Test
    fun responseCurveIsSofterNearCenter() {
        val mapper = TiltMapper()
        mapper.warmUp(Vec2(0f, 0f))
        // Halfway through the active range: output must be less than halfway
        // because curveExponent > 1.
        val halfInput = TiltMapper.DEAD_ZONE + (1f - TiltMapper.DEAD_ZONE) * 0.5f
        val out = mapper.map(Vec2(halfInput, 0f), dt)
        assertTrue(out.x in 0f..0.5f)
        assertTrue(out.x > 0f)
    }

    @Test
    fun baselineRecentersWhileIdle() {
        val mapper = TiltMapper()
        mapper.warmUp(Vec2(0f, 0f))
        // Simulate slow drift: baseline stays, readings move slightly,
        // but they are inside the dead zone AND inside recenter delay region.
        var out = Vec2(0f, 0f)
        val drifted = Vec2(TiltMapper.DEAD_ZONE * 0.6f, 0f)
        repeat(N) { out = mapper.map(drifted, dt) }
        // After enough idle time the input returns to zero despite the drift.
        assertEquals(0f, out.x, 0.02f)
    }

    @Test
    fun resetRestartsCalibration() {
        val mapper = TiltMapper()
        mapper.warmUp(Vec2(0f, 0f))
        mapper.reset()
        val out = mapper.map(Vec2(0.5f, 0f), dt)
        assertEquals(0f, out.x)
        assertEquals(0f, out.y)
    }

    private companion object {
        // > RECENTER_DELAY seconds of idle at 60 fps.
        const val N = 120
    }
}
