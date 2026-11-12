package com.example.flutter_framework

import android.graphics.Color
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 启用 Edge-to-Edge 模式以支持 Android 15+ 的无边框画面要求
        // 使用 WindowCompat 实现向后兼容；状态栏显隐由 Flutter 侧 SystemChrome 控制
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // 设置状态栏和导航栏为透明
        @Suppress("DEPRECATION")
        window.statusBarColor = Color.TRANSPARENT
        @Suppress("DEPRECATION")
        window.navigationBarColor = Color.TRANSPARENT
    }
}
