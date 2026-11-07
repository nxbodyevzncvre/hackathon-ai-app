package com.example.myapplication.game

interface Rng {
    fun nextFloat(): Float
}

class DefaultRng(seed: Long) : Rng {
    private val random = kotlin.random.Random(seed)
    override fun nextFloat(): Float = random.nextFloat()
}
