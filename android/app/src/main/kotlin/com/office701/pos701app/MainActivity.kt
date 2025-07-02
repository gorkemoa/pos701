package com.office701.pos701app

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 12+ splash screen'i install et
        val splashScreen = installSplashScreen()
        
        // Görselin maksimum boyutta gösterilmesi için exit animasyonu kaldır
        splashScreen.setOnExitAnimationListener { splashScreenViewProvider ->
            // Animasyon olmadan ve tam ekran kapat
            splashScreenViewProvider.view.alpha = 1.0f
            splashScreenViewProvider.iconView.scaleX = 3.0f
            splashScreenViewProvider.iconView.scaleY = 3.0f
            splashScreenViewProvider.remove()
        }
        
        // Splash ekranının biraz daha uzun gösterilmesi için gecikme ekle (1000ms)
        splashScreen.setKeepOnScreenCondition { true }
        
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        handler.postDelayed({
            // 1000ms sonra splash screen'i kaldır
            splashScreen.setKeepOnScreenCondition { false }
        }, 1000)
        
        super.onCreate(savedInstanceState)
    }
}
