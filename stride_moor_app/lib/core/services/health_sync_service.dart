import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// 健康数据导入结果
class HealthImportResult {
  final int imported;
  final List<String> errors;

  const HealthImportResult({this.imported = 0, this.errors = const []});
}

/// 健康平台数据同步服务
///
/// 统一接入 Apple Health (iOS) 和 Health Connect (Android)，
/// 读取跑步记录并导入到驰陌后端。
class HealthSyncService {
  final Health _health = Health();
  bool _isAuthorized = false;

  /// 检查并请求权限
  Future<bool> requestPermissions() async {
    if (_isAuthorized) return true;

    try {
      // 需要读取的健康数据类型
      final types = <HealthDataType>[
        HealthDataType.WORKOUT,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.FLIGHTS_CLIMBED,
        HealthDataType.RESTING_HEART_RATE,
      ];

      final hasPermissions = await _health.requestAuthorization(types);
      _isAuthorized = hasPermissions;
      return hasPermissions;
    } catch (e) {
      debugPrint('HealthKit 授权失败: $e');
      return false;
    }
  }

  /// 请求 Android 权限（Health Connect 需要额外系统权限）
  Future<bool> requestAndroidPermissions() async {
    try {
      var status = await Permission.activityRecognition.request();
      if (status != PermissionStatus.granted) {
        debugPrint('⚠️ 运动权限未授权');
        return false;
      }
      status = await Permission.sensors.request();
      if (status != PermissionStatus.granted) {
        debugPrint('⚠️ 传感器权限未授权');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Android 权限请求失败: $e');
      return false;
    }
  }

  /// 获取近期跑步记录
  ///
  /// [since] 开始时间（默认最近 7 天）
  /// [until] 结束时间（默认当前时间）
  Future<List<HealthWorkoutData>> fetchWorkouts({
    DateTime? since,
    DateTime? until,
  }) async {
    if (!_isAuthorized) {
      final ok = await requestPermissions();
      if (!ok) return [];
    }

    final now = until ?? DateTime.now();
    final start = since ?? now.subtract(const Duration(days: 7));

    // 读取锻炼记录（Apple Health 的 HKWorkout）
    final workouts = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: [HealthDataType.WORKOUT],
    );

    final results = <HealthWorkoutData>[];
    for (final w in workouts) {
      try {
        final workoutType = _parseWorkoutType(w.value as int? ?? 0);
        if (workoutType != 'running') continue; // 只导入跑步

        final data = await _fetchWorkoutDetail(
          startTime: w.dateFrom,
          endTime: w.dateFrom.add(const Duration(hours: 3)),
        );
        if (data != null) results.add(data);
      } catch (e) {
        debugPrint('跳过异常运动记录: $e');
      }
    }
    return results;
  }

  /// 读取指定时间段内的详细跑步数据（距离、心率、配速、GPS）
  Future<HealthWorkoutData?> _fetchWorkoutDetail({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // 批量读取各类数据
    final samples = await _health.getHealthDataFromTypes(
      startTime: startTime,
      endTime: endTime,
      types: [
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.FLIGHTS_CLIMBED,
        HealthDataType.SPEED,
      ],
    );

    if (samples.isEmpty) return null;

    // 解析数据
    double totalDistance = 0;
    int totalSeconds = endTime.difference(startTime).inSeconds;
    final heartRates = <int>[];
    double? calories;
    double? elevationGain;

    for (final s in samples) {
      switch (s.type) {
        case HealthDataType.DISTANCE_WALKING_RUNNING:
          totalDistance += s.value as double;
        case HealthDataType.HEART_RATE:
          heartRates.add((s.value as num).round());
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          calories = s.value as double;
        case HealthDataType.FLIGHTS_CLIMBED:
          elevationGain ??= 0.0;
          elevationGain = elevationGain! + (s.value as num).toDouble() * 3;
        default:
      }
    }

    final avgHR = heartRates.isNotEmpty
        ? heartRates.reduce((a, b) => a + b) ~/ heartRates.length
        : null;
    final maxHR = heartRates.isNotEmpty
        ? heartRates.reduce((a, b) => a > b ? a : b)
        : null;

    return HealthWorkoutData(
      sourceId: 'apple_health_${startTime.millisecondsSinceEpoch}',
      startTime: startTime,
      endTime: endTime,
      totalDistance: totalDistance,
      totalTime: totalSeconds,
      avgHeartRate: avgHR,
      maxHeartRate: maxHR,
      avgCadence: null,
      calories: calories != null ? calories.round() : null,
      elevationGain: elevationGain,
    );
  }

  /// HKWorkoutActivityType → 运动类型字符串
  String _parseWorkoutType(int value) {
    // 常用类型映射
    const types = {
      1: 'running', // HKWorkoutActivityTypeRunning (iOS)
      13: 'running', // Walking
      16: 'cycling',
      7: 'swimming',
      38: 'hiking',
    };
    return types[value] ?? 'other';
  }

  /// 同步最近 7 天的跑步记录
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
}

/// 健康平台跑步记录数据
class HealthWorkoutData {
  final String sourceId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalDistance;
  final int totalTime;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? avgCadence;
  final int? calories;
  final double? elevationGain;

  const HealthWorkoutData({
    required this.sourceId,
    required this.startTime,
    required this.endTime,
    required this.totalDistance,
    required this.totalTime,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgCadence,
    this.calories,
    this.elevationGain,
  });

  /// 转换为后端导入 API 所需的 JSON
  Map<String, dynamic> toImportJson() {
    return {
      'source': 'apple_health',
      'source_id': sourceId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'total_distance': totalDistance,
      'total_time': totalTime,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (avgCadence != null) 'avg_cadence': avgCadence,
      if (calories != null) 'calories': calories,
      if (elevationGain != null) 'elevation_gain': elevationGain,
    };
  }
}
