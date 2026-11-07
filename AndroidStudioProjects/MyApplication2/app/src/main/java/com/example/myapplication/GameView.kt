package com.example.myapplication

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.view.Choreographer
import android.view.MotionEvent
import android.view.View
import com.example.myapplication.game.GameEngine
import com.example.myapplication.game.GameStatus
import com.example.myapplication.game.Vec2
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin
import kotlin.random.Random

class GameView(context: Context) : View(context) {

    private val engine = GameEngine(seed = System.nanoTime())

    private var lastFrameTime = -1L
    private val choreographer = Choreographer.getInstance()
    private var lastCollectedStars = 0
    private var lastStatus = GameStatus.RUNNING


    private val bgPaint = Paint()
    private val vignettePaint = Paint()

    private val ballGlowPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val ballBodyPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val ballRingPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#BAE6FD")
        style = Paint.Style.STROKE
        strokeWidth = 4f
        alpha = 210
    }
    private val trailPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#38BDF8") }
    private val meteorGlowPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val meteorBodyPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val starHaloPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val starBodyPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val skyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }

    private val chipFillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#26FFFFFF") }
    private val chipStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = Color.parseColor("#63FFFFFF")
        strokeWidth = 2f
    }
    private val panelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.parseColor("#F2101828")
    }
    private val panelStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = Color.parseColor("#6638BDF8")
        strokeWidth = 2f
    }
    private val overlayPaint = Paint().apply { color = Color.parseColor("#99000000") }
    private val particlePaint = Paint(Paint.ANTI_ALIAS_FLAG)

    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = 56f
        isFakeBoldText = true
    }
    private val smallTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#94A3B8")
        textSize = 34f
    }
    private val smallCenteredTextPaint = Paint(smallTextPaint).apply {
        color = Color.parseColor("#7DD3FC")
        textSize = 30f
        textAlign = Paint.Align.CENTER
    }
    private val bigTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = 72f
        isFakeBoldText = true
        textAlign = Paint.Align.CENTER
    }
    private val statsTextPaint = Paint(bigTextPaint).apply { textSize = 52f }

    // Reusable scratch: copy state instead of allocating new Paints per frame.
    private val shadowPaint = Paint()

    private val panelRect = RectF()
    private val chipRect = RectF()


    private class SkyStar(val x: Float, val y: Float, val r: Float, val phase: Float, val speed: Float)

    private val skyStars = List(SKY_STAR_COUNT) { i ->
        val rnd = Random(i * 7919L)
        SkyStar(
            x = rnd.nextFloat(),
            y = rnd.nextFloat(),
            r = 0.0015f + rnd.nextFloat() * 0.0022f,
            phase = rnd.nextFloat() * 2f * Math.PI.toFloat(),
            speed = 1.5f + rnd.nextFloat() * 3f,
        )
    }
    private var skyTime = 0f


    private val trail = ArrayDeque<Vec2>(TRAIL_LENGTH)


    private class Particle(
        var x: Float,
        var y: Float,
        var vx: Float,
        var vy: Float,
        var life: Float,
        val maxLife: Float,
        val radius: Float,
        val color: Int,
    )

    private val particles = mutableListOf<Particle>()


    private var ballR = 0f
    private var trailMaxR = 0f
    private var ballGlowR = 0f
    private var ballBodyShader: Shader? = null
    private var ballGlowShader: Shader? = null
    private var meteorGlowShader: Shader? = null
    private var meteorBodyShader: Shader? = null
    private var starHaloR = 0f
    private var starHaloShader: Shader? = null
    private var starBodyShader: Shader? = null
    private val starBodyPath = Path()

    private val frameCallback = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) {
            choreographer.postFrameCallback(this)
            if (lastFrameTime >= 0L) {
                val dt = (frameTimeNanos - lastFrameTime) / 1_000_000_000f
                engine.update(dt)
                updateEffects(dt)
            }
            lastFrameTime = frameTimeNanos
            invalidate()
        }
    }

    fun start() {
        lastFrameTime = -1L
        choreographer.postFrameCallback(frameCallback)
    }

    fun stop() {
        choreographer.removeFrameCallback(frameCallback)
    }

    fun onTilt(tiltX: Float, tiltY: Float) {
        engine.onTiltChanged(tiltX, tiltY)
    }


    private fun updateEffects(dt: Float) {
        skyTime += dt

        if (engine.status == GameStatus.RUNNING) {
            trail.addFirst(Vec2(engine.ball.position.x, engine.ball.position.y))
            while (trail.size > TRAIL_LENGTH) trail.removeLast()
        }

        if (engine.collectedStars > lastCollectedStars) {
            burst(engine.ball.position, PARTICLE_COLORS_GOLD, count = 14, speed = 0.35f)
        }
        lastCollectedStars = engine.collectedStars

        if (engine.status == GameStatus.GAME_OVER && lastStatus == GameStatus.RUNNING) {
            burst(engine.ball.position, PARTICLE_COLORS_FIRE, count = 26, speed = 0.5f)
        }
        lastStatus = engine.status

        val iter = particles.iterator()
        while (iter.hasNext()) {
            val p = iter.next()
            p.life -= dt
            if (p.life <= 0f) {
                iter.remove()
                continue
            }
            p.x += p.vx * dt * width
            p.y += p.vy * dt * height
            p.vx *= (1f - 2.5f * dt).coerceAtLeast(0f)
            p.vy *= (1f - 2.5f * dt).coerceAtLeast(0f)
        }
    }

    private fun burst(center: Vec2, colors: IntArray, count: Int, speed: Float) {
        val rnd = Random(System.nanoTime())
        val scale = width / 1080f * 4.2f
        repeat(count) {
            val angle = rnd.nextFloat() * 2f * Math.PI.toFloat()
            val mag = speed * (0.35f + rnd.nextFloat() * 0.65f)
            particles.add(
                Particle(
                    x = center.x * width,
                    y = center.y * height,
                    vx = cos(angle) * mag,
                    vy = sin(angle) * mag,
                    life = 0.35f + rnd.nextFloat() * 0.4f,
                    maxLife = 0.75f,
                    radius = scale * (3f + rnd.nextFloat() * 4f),
                    color = colors[rnd.nextInt(colors.size)],
                )
            )
        }
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)

        bgPaint.shader = LinearGradient(
            0f, 0f, 0f, h.toFloat(),
            intArrayOf(
                Color.parseColor("#1B2735"),
                Color.parseColor("#0F1B2E"),
                Color.parseColor("#090E1A"),
            ),
            null,
            Shader.TileMode.CLAMP
        )

        vignettePaint.shader = RadialGradient(
            w / 2f, h * 0.4f, max(w, h) * 0.75f,
            intArrayOf(Color.TRANSPARENT, Color.TRANSPARENT, Color.parseColor("#B8060A12")),
            floatArrayOf(0f, 0.55f, 1f),
            Shader.TileMode.CLAMP
        )

        ballR = engine.ballRadius * w
        trailMaxR = 0.8f * ballR
        ballGlowR = 2.4f * ballR
        ballGlowShader = RadialGradient(
            0f, 0f, ballGlowR,
            intArrayOf(Color.parseColor("#7738BDF8"), Color.TRANSPARENT),
            null,
            Shader.TileMode.CLAMP
        )
        ballBodyShader = RadialGradient(
            -0.25f * ballR, -0.3f * ballR, 1.25f * ballR,
            intArrayOf(Color.WHITE, Color.parseColor("#E0F2FE"), Color.parseColor("#7EC8F5")),
            null,
            Shader.TileMode.CLAMP
        )

        meteorGlowShader = RadialGradient(
            0f, 0f, 2.1f * GameEngine.OBSTACLE_RADIUS * w,
            intArrayOf(Color.parseColor("#55FB923C"), Color.TRANSPARENT),
            null,
            Shader.TileMode.CLAMP
        )
        meteorBodyShader = RadialGradient(
            -0.3f * GameEngine.OBSTACLE_RADIUS * w, -0.3f * GameEngine.OBSTACLE_RADIUS * w,
            1.35f * GameEngine.OBSTACLE_RADIUS * w,
            intArrayOf(
                Color.parseColor("#FCA5A5"),
                Color.parseColor("#EF4444"),
                Color.parseColor("#7F1D1D"),
            ),
            null,
            Shader.TileMode.CLAMP
        )

        starHaloR = 2.2f * GameEngine.STAR_RADIUS * w
        starHaloShader = RadialGradient(
            0f, 0f, starHaloR,
            intArrayOf(Color.parseColor("#77FACC15"), Color.TRANSPARENT),
            null,
            Shader.TileMode.CLAMP
        )
        starBodyShader = RadialGradient(
            0f, 0f, 1.15f * GameEngine.STAR_RADIUS * w,
            intArrayOf(Color.parseColor("#FDE047"), Color.parseColor("#F59E0B")),
            null,
            Shader.TileMode.CLAMP
        )
        starBodyPath.reset()
        buildStarPath(starBodyPath, 1.05f * GameEngine.STAR_RADIUS * w, 0.45f * GameEngine.STAR_RADIUS * w)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        canvas.drawPaint(bgPaint)
        drawSky(canvas)
        canvas.drawPaint(vignettePaint)

        for (star in engine.stars) {
            drawAt(canvas, star.x * width, star.y * height) {
                canvas.drawCircle(0f, 0f, starHaloR, starHaloPaint)
                canvas.drawPath(starBodyPath, starBodyPaint)
            }
        }
        for (obstacle in engine.obstacles) {
            drawAt(canvas, obstacle.x * width, obstacle.y * height) {
                val r = obstacle.radius * width
                val glowR = r * 2.1f
                canvas.drawCircle(0f, 0f, glowR, meteorGlowPaint)
                canvas.drawCircle(0f, 0f, r, meteorBodyPaint)
            }
        }
        drawBall(canvas)

        drawParticles(canvas)
        drawHud(canvas)

        if (engine.status == GameStatus.GAME_OVER) {
            drawGameOver(canvas)
        } else if (engine.elapsed < 3f) {
            drawTextWithShadow(
                canvas, smallCenteredTextPaint,
                "Tilt your phone to dodge meteors", width / 2f, height - 60f
            )
        }
    }

    private inline fun drawAt(canvas: Canvas, x: Float, y: Float, block: () -> Unit) {
        canvas.save()
        canvas.translate(x, y)
        block()
        canvas.restore()
    }

    private fun drawSky(canvas: Canvas) {
        for (s in skyStars) {
            val w = 0.35f + 0.65f * abs(sin(skyTime * s.speed + s.phase))
            skyPaint.alpha = (90 * w).toInt()
            canvas.drawCircle(s.x * width, s.y * height, s.r * width, skyPaint)
        }
        skyPaint.alpha = 255
    }

    private fun drawBall(canvas: Canvas) {
        val cx = engine.ball.position.x * width
        val cy = engine.ball.position.y * height

        val size = trail.size
        if (size > 1) {
            val iterator = trail.iterator()
            iterator.next()
            var i = 1
            while (iterator.hasNext()) {
                val point = iterator.next()
                val a = 1f - i.toFloat() / size
                trailPaint.alpha = (110 * a * a).toInt()
                canvas.drawCircle(
                    point.x * width,
                    point.y * height,
                    trailMaxR * (0.45f + 0.55f * a),
                    trailPaint
                )
                i++
            }
        }

        ballGlowPaint.shader = ballGlowShader
        canvas.save()
        canvas.translate(cx, cy)
        canvas.drawCircle(0f, 0f, ballGlowR, ballGlowPaint)
        ballBodyPaint.shader = ballBodyShader
        canvas.drawCircle(0f, 0f, ballR, ballBodyPaint)
        canvas.drawCircle(0f, 0f, ballR - ballRingPaint.strokeWidth / 2f, ballRingPaint)
        canvas.restore()
    }

    private fun drawParticles(canvas: Canvas) {
        if (particles.isEmpty()) return
        var alpha: Int
        for (p in particles) {
            val a = (p.life / p.maxLife).coerceIn(0f, 1f)
            particlePaint.color = p.color
            alpha = (255 * a * a).toInt()
            particlePaint.alpha = alpha
            canvas.drawCircle(p.x, p.y, p.radius * max(a, 0.2f), particlePaint)
        }
        particlePaint.alpha = 255
    }

    private fun drawHud(canvas: Canvas) {
        val pad = 32f
        drawTextWithShadow(
            canvas, textPaint,
            "Score: ${engine.score}", pad, textPaint.textSize + pad
        )

        val levelText = "Level ${engine.difficulty}"
        val tw = smallTextPaint.measureText(levelText)
        chipRect.set(
            width - pad - tw - 28f, pad,
            width - pad, pad + smallTextPaint.textSize + 18f
        )
        canvas.drawRoundRect(chipRect, 14f, 14f, chipFillPaint)
        canvas.drawRoundRect(chipRect, 14f, 14f, chipStrokePaint)
        canvas.drawText(levelText, chipRect.left + 14f, chipRect.bottom - 12f, smallTextPaint)
    }

    private fun drawTextWithShadow(
        canvas: Canvas,
        paint: Paint,
        text: String,
        x: Float,
        y: Float,
    ) {
        shadowPaint.set(paint)
        shadowPaint.color = SHADOW_COLOR
        canvas.drawText(text, x + 3f, y + 3f, shadowPaint)
        canvas.drawText(text, x, y, paint)
    }

    private fun drawGameOver(canvas: Canvas) {
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), overlayPaint)

        val cx = width / 2f
        val cy = height / 2f
        panelRect.set(
            cx - width * 0.41f, cy - height * 0.17f,
            cx + width * 0.41f, cy + height * 0.17f
        )
        canvas.drawRoundRect(panelRect, 28f, 28f, panelPaint)
        canvas.drawRoundRect(panelRect, 28f, 28f, panelStrokePaint)

        val titleY = cy - panelRect.height() * 0.2f
        shadowPaint.set(bigTextPaint)
        shadowPaint.color = SHADOW_COLOR
        canvas.drawText("GAME OVER", cx + 3f, titleY + 3f, shadowPaint)
        canvas.drawText("GAME OVER", cx, titleY, bigTextPaint)

        statsTextPaint.color = Color.parseColor("#FACC15")
        canvas.drawText("Score  ${engine.score}", cx, cy + panelRect.height() * 0.03f, statsTextPaint)
        canvas.drawText("Tap to restart", cx, cy + panelRect.height() * 0.42f, smallCenteredTextPaint)
    }

    private fun buildStarPath(path: Path, outer: Float, inner: Float) {
        val start = -(Math.PI.toFloat() / 2f)
        for (i in 0 until 10) {
            val radius = if (i % 2 == 0) outer else inner
            val angle = start + i * (Math.PI.toFloat() / 5f)
            val x = radius * cos(angle)
            val y = radius * sin(angle)
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_DOWN && engine.status == GameStatus.GAME_OVER) {
            trail.clear()
            particles.clear()
            engine.reset(Random(System.nanoTime()).nextLong())
            return true
        }
        return super.onTouchEvent(event)
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        keepScreenOn = true
    }

    override fun onDetachedFromWindow() {
        stop()
        super.onDetachedFromWindow()
    }

    private companion object {
        const val TRAIL_LENGTH = 14
        const val SKY_STAR_COUNT = 60
        const val SHADOW_COLOR = 0x88000000.toInt()
        val PARTICLE_COLORS_GOLD = listOf(
            "#FACC15", "#FDE047", "#FB923C", "#FDE68A",
        ).map(Color::parseColor).toIntArray()
        val PARTICLE_COLORS_FIRE = listOf(
            "#F87171", "#FB923C", "#FCA5A5", "#F97316",
        ).map(Color::parseColor).toIntArray()
    }
}
