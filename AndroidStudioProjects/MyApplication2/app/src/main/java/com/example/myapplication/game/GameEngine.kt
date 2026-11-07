package com.example.myapplication.game

import kotlin.math.max

class GameEngine(
    seed: Long = 42L,
    val fieldWidth: Float = 1f,
    val fieldHeight: Float = 1f,
    val ballRadius: Float = 0.035f,
    initialBallPosition: Vec2 = Vec2(0.5f, 0.85f),
    obstacleRng: Rng = DefaultRng(seed),
    starRng: Rng = DefaultRng(seed + 1),
) {
    var status: GameStatus = GameStatus.RUNNING
        private set
    var score: Int = 0
        private set
    var elapsed: Float = 0f
        private set
    var collectedStars: Int = 0
        private set

    val difficulty: Int
        get() = 1 + (elapsed / DIFFICULTY_SECONDS).toInt()

    val spawnInterval: Float
        get() = max(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL / difficulty)

    val ball = Ball(initialBallPosition, ballRadius)
    val obstacles = mutableListOf<Obstacle>()
    val stars = mutableListOf<Star>()

    private val startBallPosition = initialBallPosition
    private var obstacleRng = obstacleRng
    private var starRng = starRng
    private var tilt = Vec2(0f, 0f)
    private var obstacleTimer = 0f
    private var starTimer = STAR_EVERY

    fun onTiltChanged(tiltX: Float, tiltY: Float) {
        tilt = Vec2(tiltX.coerceIn(-1f, 1f), tiltY.coerceIn(-1f, 1f))
    }

    fun update(dt: Float) {
        if (status != GameStatus.RUNNING) return
        val step = dt.coerceIn(0f, MAX_STEP)
        if (step <= 0f) return
        elapsed += step
        updateBall(step)
        updateSpawns(step)
        updateObstacles(step)
        updateStars(step)
    }

    fun reset(seed: Long) {
        status = GameStatus.RUNNING
        score = 0
        elapsed = 0f
        collectedStars = 0
        obstacleRng = DefaultRng(seed)
        starRng = DefaultRng(seed + 1)
        obstacles.clear()
        stars.clear()
        obstacleTimer = 0f
        starTimer = STAR_EVERY
        ball.position = startBallPosition
        ball.velocity = Vec2(0f, 0f)
    }

    private fun updateBall(step: Float) {
        val accel = tilt * TILT_ACCEL
        var v = ball.velocity + accel * step
        v *= (1f - DAMPING * step).coerceAtLeast(0f)
        ball.velocity = v
        ball.position = ball.position + v * step

        val minX = ball.radius
        val maxX = fieldWidth - ball.radius
        val minY = ball.radius
        val maxY = fieldHeight - ball.radius
        val p = ball.position
        var newX = p.x
        var newY = p.y
        var newVx = v.x
        var newVy = v.y
        if (newX < minX || newX > maxX) {
            newX = newX.coerceIn(minX, maxX)
            newVx = -newVx * WALL_BOUNCE
        }
        if (newY < minY || newY > maxY) {
            newY = newY.coerceIn(minY, maxY)
            newVy = -newVy * WALL_BOUNCE
        }
        ball.position = Vec2(newX, newY)
        ball.velocity = Vec2(newVx, newVy)
    }

    private fun updateSpawns(step: Float) {
        obstacleTimer -= step
        while (obstacleTimer <= 0f) {
            obstacles.add(
                Obstacle(
                    x = obstacleRng.nextFloat(),
                    y = -OBSTACLE_RADIUS,
                    radius = OBSTACLE_RADIUS,
                    speed = OBSTACLE_BASE_SPEED + OBSTACLE_SPEED_PER_LEVEL * (difficulty - 1),
                )
            )
            obstacleTimer += spawnInterval
        }
        starTimer -= step
        while (starTimer <= 0f) {
            stars.add(
                Star(
                    x = starRng.nextFloat(),
                    y = -STAR_RADIUS,
                    radius = STAR_RADIUS,
                    speed = STAR_SPEED,
                )
            )
            starTimer += STAR_EVERY
        }
    }

    private fun updateObstacles(step: Float) {
        val iterator = obstacles.iterator()
        while (iterator.hasNext()) {
            val obstacle = iterator.next()
            val pos = Vec2(obstacle.x, obstacle.y + obstacle.speed * step)
            if (pos.y > fieldHeight + obstacle.radius) {
                iterator.remove()
                score += 1
                continue
            }
            obstacle.y = pos.y
            if (pos.distanceTo(ball.position) < ballRadius + obstacle.radius) {
                status = GameStatus.GAME_OVER
                return
            }
        }
    }

    private fun updateStars(step: Float) {
        val iterator = stars.iterator()
        while (iterator.hasNext()) {
            val star = iterator.next()
            val pos = Vec2(star.x, star.y + star.speed * step)
            if (pos.y > fieldHeight + star.radius) {
                iterator.remove()
                continue
            }
            star.y = pos.y
            if (pos.distanceTo(ball.position) < ballRadius + star.radius) {
                iterator.remove()
                score += STAR_POINTS
                collectedStars += 1
            }
        }
    }

    companion object {
        const val MAX_STEP = 0.05f
        const val TILT_ACCEL = 4.2f
        const val DAMPING = 3.0f
        const val WALL_BOUNCE = 0.3f
        const val BASE_SPAWN_INTERVAL = 1.0f
        const val MIN_SPAWN_INTERVAL = 0.35f
        const val OBSTACLE_BASE_SPEED = 0.32f
        const val OBSTACLE_SPEED_PER_LEVEL = 0.08f
        const val OBSTACLE_RADIUS = 0.05f
        const val STAR_EVERY = 6f
        const val STAR_RADIUS = 0.03f
        const val STAR_SPEED = 0.3f
        const val STAR_POINTS = 5
        const val DIFFICULTY_SECONDS = 20f
    }
}
