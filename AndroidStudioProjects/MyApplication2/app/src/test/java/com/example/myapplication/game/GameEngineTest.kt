package com.example.myapplication.game

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GameEngineTest {

    private fun engine(
        ballPos: Vec2 = Vec2(0.5f, 0.85f),
        obstacleX: Float = 0.95f,
        starX: Float = 0.15f,
        seed: Long = 7,
    ) = GameEngine(
        seed = seed,
        initialBallPosition = ballPos,
        obstacleRng = FixedRng(obstacleX),
        starRng = FixedRng(starX),
    )

    private fun GameEngine.tick(seconds: Float, dt: Float = 1f / 60f) {
        var remaining = seconds
        while (remaining > 1e-6f) {
            val step = minOf(dt, remaining)
            update(step)
            remaining -= step
        }
    }

    @Test
    fun ballMovesRightWhenTiltedRight() {
        val game = engine()
        game.onTiltChanged(1f, 0f)
        game.tick(0.5f)
        assertTrue(game.ball.position.x > 0.5f)
    }

    @Test
    fun fullTiltAcceleratesPromptly() {
        // Full tilt must move the ball well over 30% of the screen width in
        // half a second: the old tuning (TILT_ACCEL=3.2, DAMPING=2.5) covered
        // only ~0.275 in that time and the response felt laggy.
        val game = engine()
        game.onTiltChanged(1f, 0f)
        game.tick(0.5f)
        val travelled = game.ball.position.x - 0.5f
        assertTrue("travelled only $travelled", travelled > 0.31f)
    }

    @Test
    fun ballNeverLeavesTheField() {
        val game = engine(obstacleX = 0.15f)
        game.onTiltChanged(1f, 0f)
        game.tick(1.2f)
        game.onTiltChanged(-1f, 0f)
        game.tick(1.8f)
        assertTrue(game.ball.position.x in 0f..game.fieldWidth)
        assertTrue(game.ball.position.y in 0f..game.fieldHeight)
        assertEquals(GameStatus.RUNNING, game.status)
    }

    @Test
    fun obstaclesSpawnAfterOneSecond() {
        val game = engine()
        game.tick(1.2f)
        assertTrue(game.obstacles.isNotEmpty())
    }

    @Test
    fun obstaclesFallDown() {
        val game = engine()
        game.tick(1.2f)
        val yBefore = game.obstacles.first().y
        game.tick(1f)
        val yAfter = game.obstacles.first().y
        assertTrue(yAfter > yBefore)
    }

    @Test
    fun collisionWithObstacleEndsGame() {
        val game = engine(ballPos = Vec2(0.15f, 0.85f), obstacleX = 0.15f)
        game.tick(5f)
        assertEquals(GameStatus.GAME_OVER, game.status)
    }

    @Test
    fun scoreIsFrozenAfterGameOver() {
        val game = engine(ballPos = Vec2(0.15f, 0.85f), obstacleX = 0.15f)
        game.tick(5f)
        val scoreAtDeath = game.score
        game.tick(3f)
        assertEquals(scoreAtDeath, game.score)
        assertEquals(GameStatus.GAME_OVER, game.status)
    }

    @Test
    fun dodgedObstaclesIncreaseScore() {
        val game = engine()
        game.tick(10f)
        assertEquals(GameStatus.RUNNING, game.status)
        assertTrue(game.score >= 5)
    }

    @Test
    fun starGivesBonusPoints() {
        val game = engine(ballPos = Vec2(0.15f, 0.85f), obstacleX = 0.95f, starX = 0.15f)
        game.tick(10f)
        assertEquals(GameStatus.RUNNING, game.status)
        assertEquals(1, game.collectedStars)
        assertTrue(game.score >= 5)
        assertTrue(game.stars.isEmpty())
    }

    @Test
    fun starSpawnsAtRngPosition() {
        val game = engine(starX = 0.8f)
        game.tick(7f)
        assertTrue(game.stars.isNotEmpty())
        assertEquals(0.8f, game.stars.first().x, 1e-5f)
    }

    @Test
    fun difficultyGrowsOverTime() {
        val game = engine()
        game.tick(25f)
        assertEquals(2, game.difficulty)
    }

    @Test
    fun sameSeedProducesSameWorld() {
        val a = GameEngine(seed = 77)
        val b = GameEngine(seed = 77)
        a.tick(3f)
        b.tick(3f)
        assertEquals(a.obstacles.map { it.x }, b.obstacles.map { it.x })
        assertEquals(a.obstacles.map { it.y }, b.obstacles.map { it.y })
    }

    @Test
    fun resetRestartsGame() {
        val game = engine(ballPos = Vec2(0.15f, 0.85f), obstacleX = 0.15f)
        game.tick(5f)
        assertEquals(GameStatus.GAME_OVER, game.status)
        game.reset(seed = 1)
        assertEquals(GameStatus.RUNNING, game.status)
        assertEquals(0, game.score)
        assertEquals(0, game.collectedStars)
        assertTrue(game.obstacles.isEmpty())
        assertTrue(game.stars.isEmpty())
        assertEquals(0f, game.elapsed, 1e-5f)
        assertEquals(0.15f, game.ball.position.x, 1e-5f)
        assertEquals(0.85f, game.ball.position.y, 1e-5f)
    }
}
