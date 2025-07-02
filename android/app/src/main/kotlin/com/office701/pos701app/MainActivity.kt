package com.office701.pos701app

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 12+ splash screen'i install et ve hemen gizle
        val splashScreen = installSplashScreen()
        
        super.onCreate(savedInstanceState)
        
        // Splash screen'i hemen gizle
        splashScreen.setKeepOnScreenCondition { false }
    }
}
