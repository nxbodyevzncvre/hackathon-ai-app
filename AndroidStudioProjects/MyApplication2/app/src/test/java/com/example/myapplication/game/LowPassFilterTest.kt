package com.example.myapplication.game

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LowPassFilterTest {

    private val dt = 1f / 60f

    @Test
    fun firstSamplePassesThrough() {
        val filter = LowPassFilter()
        val out = filter.filter(Vec2(2f, -1f), dt)
        assertEquals(2f, out.x, 1e-4f)
        assertEquals(-1f, out.y, 1e-4f)
    }

    @Test
    fun outputConvergesToConstantInput() {
        val filter = LowPassFilter()
        var out = filter.filter(Vec2(0.8f, -0.4f), dt)
        repeat(100) { out = filter.filter(Vec2(0.8f, -0.4f), dt) }
        assertEquals(0.8f, out.x, 1e-2f)
        assertEquals(-0.4f, out.y, 1e-2f)
    }

    @Test
    fun outputFollowsInputSmoothly() {
        val filter = LowPassFilter()
        filter.filter(Vec2(0f, 0f), dt)
        val out = filter.filter(Vec2(1f, 1f), dt)
        assertTrue(out.x in 0f..1f)
        assertTrue(out.y in 0f..1f)
        assertTrue(out.x > 0f)
    }

    @Test
    fun stepResponseReaches63PercentWithinTau() {
        val filter = LowPassFilter(tau = 0.07f)
        filter.filter(Vec2(0f, 0f), dt)
        // ~4-5 events is 70 ms at 60 Hz.
        var out = filter.filter(Vec2(1f, 0f), dt)
        repeat(3) { out = filter.filter(Vec2(1f, 0f), dt) }
        assertTrue(out.x in 0.5f..0.75f)
    }

    @Test
    fun sameRealTimeResponseWhenSensorRateChanges() {
        // With the same tau, at 20 Hz one event must move the filter MORE
        // than at 60 Hz, because more real time passes between events.
        // That keeps real-time latency identical across sensor rates.
        val fast = LowPassFilter()
        fast.filter(Vec2(0f, 0f), dt)
        val outFast = fast.filter(Vec2(1f, 1f), dt)

        val slow = LowPassFilter()
        slow.filter(Vec2(0f, 0f), 1f / 20f)
        val outSlow = slow.filter(Vec2(1f, 1f), 1f / 20f)

        assertTrue(outSlow.x > outFast.x)
    }

    @Test
    fun resetClearsState() {
        val filter = LowPassFilter()
        repeat(50) { filter.filter(Vec2(1f, 1f), dt) }
        filter.reset()
        val out = filter.filter(Vec2(0f, 0f), dt)
        assertEquals(0f, out.x, 1e-4f)
        assertEquals(0f, out.y, 1e-4f)
    }
}
