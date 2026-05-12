import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'core/services/location_service.dart';

class StrideMoorApp extends ConsumerStatefulWidget {
  const StrideMoorApp({super.key});

  @override
  ConsumerState<StrideMoorApp> createState() => _StrideMoorAppState();
}

class _StrideMoorAppState extends ConsumerState<StrideMoorApp> {
  @override
  void initState() {
    super.initState();
    // 等 runApp 完成后初始化定位相关（MethodChannel 可用后才能调用）
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissions());
  }

  Future<void> _requestPermissions() async {
    // 初始化高德 SDK
    LocationService.initSdk();

    // 启动时只请求定位权限
    // 运动健身权限（计步）由 pedometer 库内部处理
    // 通知权限在国产手机上不走标准弹窗，由系统管理
    final locStatus = await Permission.locationWhenInUse.request();
    if (locStatus == PermissionStatus.permanentlyDenied && mounted) {
      _showPermissionGuide('位置信息');
    }
  }

  void _showPermissionGuide(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('需要$name权限'),
        content: Text(
          '跑步功能需要获取您的$name。\n\n'
          '请前往系统设置 → 权限，手动开启。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    final Widget app = ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      ensureScreenSize: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: '驰陌 StrideMoor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh'),
            Locale('en'),
          ],
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
        );
      },
    );

    // Web 预览时限制最大宽度，避免宽屏放大
    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: app,
        ),
      );
    }

    return app;
  }
}
