package com.example.myapplication.game

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * [MedianFilter] suppresses single-sample impulses (bumps, sensor glitches)
 * while reacting quickly to sustained changes. It must introduce much less
 * lag than a plain low-pass on spikes.
 */
class MedianFilterTest {

    private val filter = MedianFilter()

    @Test
    fun firstSamplePassesThroughUnchanged() {
        val out = filter.filter(Vec2(9.8f, -2f))
        assertEquals(9.8f, out.x, 1e-4f)
        assertEquals(-2f, out.y, 1e-4f)
    }

    @Test
    fun singleImpulseIsSuppressed() {
        filter.filter(Vec2(0f, 0f))
        val peak = filter.filter(Vec2(40f, 0f)) // glitch: 4 g spike
        // Two-sample median halves it at worst...
        assertTrue("spike leak too big: ${peak.x}", peak.x <= 20f)
        // ...and one sample later it is fully gone.
        val after = filter.filter(Vec2(0f, 0f))
        assertEquals(0f, after.x, 1e-4f)
    }

    @Test
    fun sustainedChangePassesThrough() {
        var out = filter.filter(Vec2(0f, 0f))
        repeat(8) { out = filter.filter(Vec2(7f, 0f)) }
        assertEquals(7f, out.x, 1e-4f)
    }

    @Test
    fun axesAreFilteredIndependently() {
        filter.filter(Vec2(0f, 0f))
        val out = filter.filter(Vec2(0f, 9f))
        assertEquals(0f, out.x, 1e-4f)
        assertEquals(4.5f, out.y, 1e-4f)
    }

    @Test
    fun resetClearsHistory() {
        repeat(5) { filter.filter(Vec2(5f, 0f)) }
        filter.reset()
        val out = filter.filter(Vec2(1f, 1f))
        assertEquals(1f, out.x, 1e-4f)
        assertEquals(1f, out.y, 1e-4f)
    }
}
