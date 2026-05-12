package com.example.stride_moor

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 高德定位SDK不支持x86_64模拟器，Java层抛NoClassDefFoundError会直接崩进程
        // 在模拟器上替换高德MethodChannel为安全桩，返回PlatformException而非崩溃
        if (isEmulator()) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "amap_flutter_location")
                .setMethodCallHandler { call, result ->
                    result.error(
                        "AMAP_UNAVAILABLE",
                        "高德定位SDK在模拟器上不可用，请使用真机测试定位功能",
                        null
                    )
                }
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "amap_flutter_location_stream")
                .setMethodCallHandler { call, result ->
                    result.error(
                        "AMAP_UNAVAILABLE",
                        "高德定位SDK在模拟器上不可用",
                        null
                    )
                }
        }
    }

    /** 检测是否运行在Android模拟器上 */
    private fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("sdk", ignoreCase = true)
                || Build.MODEL.contains("Emulator", ignoreCase = true)
                || Build.MODEL.contains("Android SDK", ignoreCase = true)
                || Build.PRODUCT.contains("sdk", ignoreCase = true)
                || Build.PRODUCT.contains("google_sdk", ignoreCase = true)
                || Build.PRODUCT.contains("sdk_gphone", ignoreCase = true)
                || Build.HARDWARE.contains("goldfish", ignoreCase = true)
                || Build.HARDWARE.contains("ranchu", ignoreCase = true))
    }
}
