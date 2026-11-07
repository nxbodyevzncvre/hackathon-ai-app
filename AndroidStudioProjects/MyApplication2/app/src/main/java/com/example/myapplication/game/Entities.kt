package com.example.myapplication.game

enum class GameStatus { RUNNING, GAME_OVER }

class Ball(
    var position: Vec2,
    val radius: Float,
) {
    var velocity: Vec2 = Vec2(0f, 0f)
}

data class Obstacle(val x: Float, var y: Float, val radius: Float, val speed: Float)

class Star(val x: Float, var y: Float, val radius: Float, val speed: Float)
