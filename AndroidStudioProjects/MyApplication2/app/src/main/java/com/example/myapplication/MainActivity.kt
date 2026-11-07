package com.example.myapplication

import android.content.pm.ActivityInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Bundle
import android.view.Display
import android.view.Surface
import android.view.ViewGroup
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.example.myapplication.game.AxisRemapper
import com.example.myapplication.game.LowPassFilter
import com.example.myapplication.game.MedianFilter
import com.example.myapplication.game.TiltMapper
import com.example.myapplication.game.Vec2

class MainActivity : AppCompatActivity(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private val tiltFilter = LowPassFilter()
    private val tiltMapper = TiltMapper()
    private val impulseFilter = MedianFilter()
    private var lastSensorTimestamp = -1L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        setContentView(GameView(this))
        hideSystemBars()
    }

    override fun onResume() {
        super.onResume()
        tiltFilter.reset()
        tiltMapper.reset()
        impulseFilter.reset()
        lastSensorTimestamp = -1L
        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        }
        contentGameView()?.start()
    }

    override fun onPause() {
        super.onPause()
        sensorManager.unregisterListener(this)
        impulseFilter.reset()
        contentGameView()?.stop()
    }

    override fun onConfigurationChanged(newConfig: android.content.res.Configuration) {
        super.onConfigurationChanged(newConfig)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    }

    override fun onSensorChanged(event: SensorEvent) {
        val ax = event.values[0]
        val ay = event.values[1]

        val cleaned = impulseFilter.filter(Vec2(ax, ay))

        val screen = AxisRemapper.remap(cleaned.x, cleaned.y, currentDisplayRotation())

        val raw = Vec2(-screen.x / SENSOR_SCALE, screen.y / SENSOR_SCALE)

        val dt = if (lastSensorTimestamp >= 0L) {
            ((event.timestamp - lastSensorTimestamp) / 1_000_000_000f).coerceIn(0f, 0.1f)
        } else 0f
        lastSensorTimestamp = event.timestamp

        val smoothed = tiltFilter.filter(raw, dt)
        val mapped = tiltMapper.map(smoothed, dt)
        contentGameView()?.onTilt(
            mapped.x.coerceIn(-1f, 1f),
            mapped.y.coerceIn(-1f, 1f)
        )
    }

    private fun currentDisplayRotation(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.rotation ?: Surface.ROTATION_0
        } else {
            @Suppress("DEPRECATION")
            (getSystemService(WINDOW_SERVICE) as WindowManager).defaultDisplay.rotation
        }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun contentGameView(): GameView? {
        val frame = findViewById<ViewGroup>(android.R.id.content)
        return if (frame.childCount > 0) frame.getChildAt(0) as? GameView else null
    }

    private fun hideSystemBars() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.hide(WindowInsetsCompat.Type.systemBars())
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }

    companion object {
        const val SENSOR_SCALE = 9.81f
    }
}
