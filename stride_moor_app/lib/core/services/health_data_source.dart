import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:huawei_health/huawei_health.dart';

import 'health_sync_service.dart';
import 'hms_health_sync_service.dart';

/// 导出类型（便于外部引用）
export 'health_sync_service.dart' show HealthWorkoutData, HealthImportResult;
export 'hms_health_sync_service.dart' show HmsWorkoutData, HmsHealthImportResult;

/// 健康数据平台类型
enum HealthPlatform {
  /// Apple Health (iOS)
  appleHealth,

  /// Google Health Connect (Android 有 Google 服务)
  healthConnect,

  /// HMS Health Kit (华为设备)
  hmsHealthKit,

  /// 未知/不支持
  unknown,
}

/// 健康数据源抽象接口
///
/// 统一 Apple Health、Health Connect 和 HMS Health Kit 的数据访问。
abstract class HealthDataSource {
  /// 获取数据源类型
  HealthPlatform get platform;

  /// 请求授权
  Future<bool> requestPermissions();

  /// 获取跑步记录
  Future<List<HealthWorkoutData>> fetchWorkouts({
    DateTime? since,
    DateTime? until,
  });

  /// 同步近期跑步记录
  Future<HealthImportResult> syncRecentWorkouts({
    required Future<bool> Function(HealthWorkoutData data) onImport,
  });
}

/// 自动检测并选择合适的健康数据源
class HealthDataSourceManager {
  static HealthPlatform? _cachedPlatform;

  /// 检测当前设备支持的健康数据平台
  static Future<HealthPlatform> detectPlatform() async {
    if (_cachedPlatform != null) return _cachedPlatform!;

    if (!kIsWeb && Platform.isIOS) {
      _cachedPlatform = HealthPlatform.appleHealth;
      return _cachedPlatform!;
    }

    if (!kIsWeb && Platform.isAndroid) {
      final hmsAvailable = await _checkHmsAvailable();
      if (hmsAvailable) {
        _cachedPlatform = HealthPlatform.hmsHealthKit;
        return _cachedPlatform!;
      }

      _cachedPlatform = HealthPlatform.healthConnect;
      return _cachedPlatform!;
    }

    _cachedPlatform = HealthPlatform.unknown;
    return _cachedPlatform!;
  }

  /// 检测 HMS Health Kit 是否可用
  static Future<bool> _checkHmsAvailable() async {
    try {
      await DataController.init();
      debugPrint('[HealthDS] HMS Health Kit 可用');
      return true;
    } catch (e) {
      debugPrint('[HealthDS] HMS Health Kit 不可用: $e');
      return false;
    }
  }

  /// 创建对应的数据源实例
  static Future<HealthDataSource?> createDataSource() async {
    final platform = await detectPlatform();

    switch (platform) {
      case HealthPlatform.appleHealth:
        return _HealthConnectDataSource();
      case HealthPlatform.healthConnect:
        return _HealthConnectDataSource();
      case HealthPlatform.hmsHealthKit:
        return _HmsDataSource();
      case HealthPlatform.unknown:
        return null;
    }
  }

  /// 清除缓存的平台检测结果
  static void clearCache() {
    _cachedPlatform = null;
  }
}

/// Health Connect (或 Apple Health) 数据源适配器
class _HealthConnectDataSource implements HealthDataSource {
  final HealthSyncService _service = HealthSyncService();

  @override
  HealthPlatform get platform => HealthPlatform.healthConnect;

  @override
  Future<bool> requestPermissions() => _service.requestPermissions();

  @override
  Future<List<HealthWorkoutData>> fetchWorkouts({
    DateTime? since,
    DateTime? until,
  }) =>
      _service.fetchWorkouts(since: since, until: until);

  @override
  Future<HealthImportResult> syncRecentWorkouts({
    required Future<bool> Function(HealthWorkoutData data) onImport,
  }) =>
      _service.syncRecentWorkouts(onImport: onImport);
}

/// HMS Health Kit 数据源适配器
///
/// 包装 [HmsHealthSyncService] 以符合 [HealthDataSource] 接口。
/// 将 HmsWorkoutData 转换为 HealthWorkoutData 以保持兼容。
class _HmsDataSource implements HealthDataSource {
  final HmsHealthSyncService _service = HmsHealthSyncService();

  @override
  HealthPlatform get platform => HealthPlatform.hmsHealthKit;

  @override
  Future<bool> requestPermissions() => _service.requestPermissions();

  @override
  Future<List<HealthWorkoutData>> fetchWorkouts({
    DateTime? since,
    DateTime? until,
  }) async {
    final hmsWorkouts = await _service.fetchWorkouts(since: since, until: until);
    return hmsWorkouts.map(_toHealthWorkoutData).toList();
  }

  @override
  Future<HealthImportResult> syncRecentWorkouts({
    required Future<bool> Function(HealthWorkoutData data) onImport,
  }) async {
    final workouts = await fetchWorkouts();
    int imported = 0;
    final errors = <String>[];

    for (final w in workouts) {
      try {
        final success = await onImport(w);
        if (success) imported++;
      } catch (e) {
        errors.add('${w.startTime}: $e');
      }
    }

    return HealthImportResult(imported: imported, errors: errors);
  }

  /// 将 HmsWorkoutData 转换为 HealthWorkoutData
  HealthWorkoutData _toHealthWorkoutData(HmsWorkoutData data) {
    return HealthWorkoutData(
      sourceId: data.sourceId,
      startTime: data.startTime,
      endTime: data.endTime,
      totalDistance: data.totalDistance,
      totalTime: data.totalTime,
      avgHeartRate: data.avgHeartRate,
      maxHeartRate: data.maxHeartRate,
      avgCadence: data.avgCadence,
      calories: data.calories,
      elevationGain: data.elevationGain,
    );
  }
}

