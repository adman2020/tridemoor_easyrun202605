import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/services/location_service.dart';
import 'core/services/storage_service.dart';
import 'core/providers/app_providers.dart';

void main() async {
  // 全局异常捕获 —— 防止闪退
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('🔥 FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔥 PlatformDispatcher.onError: $error\n$stack');
    return true;
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化 Hive 本地存储
    await Hive.initFlutter();

    // 初始化存储服务（单例，通过 ProviderScope override 全局共享）
    final storage = StorageService();
    await storage.init();

    // TODO: 注册 Hive TypeAdapters

    runApp(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const StrideMoorApp(),
      ),
    );

    // runApp 之后才初始化高德 SDK（runApp 前 MethodChannel 不可用，会静默失败）
    // 定位权限请求移动到 app.dart 中处理（带引导弹窗）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService.initSdk();
    });
  }, (error, stack) {
    debugPrint('🔥 runZonedGuarded caught: $error\n$stack');
  });
}
