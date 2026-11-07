package com.example.myapplication.game


object AxisRemapper {

    fun remapFromDeviceReading(deviceX: Float, deviceY: Float, rotation: Int): Vec2 =
        remap(deviceX, deviceY, rotation)

    fun remap(deviceX: Float, deviceY: Float, rotation: Int): Vec2 = when (rotation) {
        90 -> Vec2(-deviceY, deviceX)
        180 -> Vec2(-deviceX, -deviceY)
        270 -> Vec2(deviceY, -deviceX)
        else -> Vec2(deviceX, deviceY) // 0 and any unexpected value
    }
}
