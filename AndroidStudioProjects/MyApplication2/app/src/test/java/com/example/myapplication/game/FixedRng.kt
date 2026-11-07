package com.example.myapplication.game

class FixedRng(private vararg val values: Float) : Rng {
    private var index = 0
    override fun nextFloat(): Float {
        val value = values[index % values.size]
        index++
        return value
    }
}
