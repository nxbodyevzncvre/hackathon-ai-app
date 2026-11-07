package com.example.myapplication.game

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * [AxisRemapper.remmap] must convert accelerometer components (device frame:
 * +X towards the right edge of the phone, +Y towards the top edge) into
 * PORTRAIT-SCREEN components (X to the screen right, Y to the screen top),
 * taking Android display rotation into account.
 *
 * Invariant under test: whichever way the phone physically points, a tilt of
 * the same screen edge must always produce the same sign of the remapped value.
 */
class AxisRemapperTest {

    @Test
    fun rotation0IsIdentity() {
        assertEquals(Vec2(1f, 2f), AxisRemapper.remap(1f, 2f, 0))
    }

    @Test
    fun rotation90SwapsAxes() {
        // ROTATION_90: screen right == device -Y, screen top == device +X.
        assertEquals(Vec2(-2f, 1f), AxisRemapper.remap(1f, 2f, 90))
    }

    @Test
    fun rotation180NegatesBoth() {
        assertEquals(Vec2(-1f, -2f), AxisRemapper.remap(1f, 2f, 180))
    }

    @Test
    fun rotation270SwapsBack() {
        // ROTATION_270: screen right == device +Y, screen top == device -X.
        assertEquals(Vec2(2f, -1f), AxisRemapper.remap(1f, 2f, 270))
    }

    @Test
    fun unknownRotationFallsBackToIdentity() {
        assertEquals(Vec2(1f, 2f), AxisRemapper.remap(1f, 2f, 555))
    }

    /**
     * Full transform used by MainActivity: screen readings remapped by
     * rotation, then game tilt = (-screenX/g, screenY/g).
     * Screen-right edge down must ALWAYS make the ball move right (tilt.x = +1),
     * whichever way the device is physically turned.
     */
    @Test
    fun rightEdgeDownMovesBallRightAtEveryRotation() {
        val g = 9.81f
        // Which device axis reads -g when the SCREEN's right edge points down:
        // r0: device +X down, r90: screen right == device -Y (so device +Y up -> ay=+g),
        // r180: screen right == device -X (device +X up -> ax=+g), r270: device +Y down.
        val readings = mapOf(
            0 to Vec2(-g, 0f),
            90 to Vec2(0f, g),
            180 to Vec2(g, 0f),
            270 to Vec2(0f, -g),
        )
        for ((rotation, reading) in readings) {
            val screen = AxisRemapper.remap(reading.x, reading.y, rotation)
            val tiltX = -screen.x / g
            assertEquals("rotation $rotation: right edge down must move ball right", 1f, tiltX, 0.01f)
        }
    }

    /**
     * Screen-top edge down must ALWAYS move the ball towards screen top
     * (game tilt.y = -1 in engine convention, because engine Y grows downwards).
     */
    @Test
    fun topEdgeDownMovesBallTowardsScreenTopAtEveryRotation() {
        val g = 9.81f
        // Screen top edge points down -> reading along screen top is -g:
        // r0: device +Y down (ay=-g), r90: screen top == device +X (ax=-g),
        // r180: screen top == device -Y (ay=+g along +/-, i.e. screenY=-g), r270: screen top == device -X (ax=+g).
        val readings = mapOf(
            0 to Vec2(0f, -g),
            90 to Vec2(-g, 0f),
            180 to Vec2(0f, g),
            270 to Vec2(g, 0f),
        )
        for ((rotation, reading) in readings) {
            val screen = AxisRemapper.remap(reading.x, reading.y, rotation)
            val tiltY = screen.y / g
            assertEquals("rotation $rotation: top edge down must move ball to screen top", -1f, tiltY, 0.01f)
        }
    }
}
