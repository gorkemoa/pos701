package com.office701.pos701app

import android.os.Build
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 12+ için splash screen desteği
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val splashScreen = installSplashScreen()
            
            // Splash ekranının biraz daha uzun gösterilmesi için gecikme
            var keepSplashScreen = true
            splashScreen.setKeepOnScreenCondition { keepSplashScreen }
            
            // 1000ms sonra splash screen'i kaldır
            val handler = android.os.Handler(android.os.Looper.getMainLooper())
            handler.postDelayed({
                keepSplashScreen = false
            }, 1000)
        }
        
        super.onCreate(savedInstanceState)
    }
}