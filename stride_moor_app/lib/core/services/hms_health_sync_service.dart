import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huawei_health/huawei_health.dart';

/// HMS Health Kit 健康数据导入结果
class HmsHealthImportResult {
  final int imported;
  final List<String> errors;

  const HmsHealthImportResult({this.imported = 0, this.errors = const []});
}

/// HMS Health Kit 跑步记录数据
class HmsWorkoutData {
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

  const HmsWorkoutData({
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

  /// 转换为后端导入 API 要求的 JSON 格式
  Map<String, dynamic> toImportJson() {
    return {
      'source': 'huawei_health',
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

/// HMS Health Kit 同步服务
///
/// 使用华为官方 huawei_health Flutter 插件访问 HMS Health Kit。
/// 仅在华为/HarmonyOS 设备上可用（需 HMS Core + 华为健康 App）。
///
/// 接入流程：
/// 1. 在 AppGallery Connect 开通 Health Kit 服务
/// 2. 下载 agconnect-services.json 放入 android/app/
/// 3. 配置签名证书指纹（SHA-256）
class HmsHealthSyncService {
  bool _isAuthorized = false;
  bool _isHmsAvailable = false;
  DataController? _dataController;

  /// 检测当前设备是否支持 HMS Health Kit
  Future<bool> isAvailable() async {
    try {
      if (_isHmsAvailable) return true;
      _dataController = await DataController.init();
      _isHmsAvailable = true;
      return true;
    } on MissingPluginException {
      debugPrint('[HMS] HMS Health Kit 插件不可用（非华为设备或缺少插件）');
      return false;
    } on PlatformException catch (e) {
      debugPrint('[HMS] HMS Health Kit 不可用: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[HMS] 检测 HMS 可用性失败: $e');
      return false;
    }
  }

  /// 请求 Health Kit 授权
  ///
  /// 需先在华为 AppGallery Connect 开通 Health Kit 服务，
  /// 并配置所需权限 scope。
  Future<bool> requestPermissions() async {
    if (_isAuthorized) return true;

    try {
      // 确保 HMS 可用
      if (!_isHmsAvailable) {
        final available = await isAvailable();
        if (!available) return false;
      }

      // 申请所需权限 scope
      // 跑步记录、心率、距离、步数、卡路里
      final authResult = await HealthAuth.signIn([
        Scope.HEALTHKIT_ACTIVITY_READ,
        Scope.HEALTHKIT_ACTIVITY_RECORD_READ,
        Scope.HEALTHKIT_HEARTRATE_READ,
        Scope.HEALTHKIT_DISTANCE_READ,
        Scope.HEALTHKIT_STEP_READ,
        Scope.HEALTHKIT_CALORIES_READ,
        Scope.HEALTHKIT_SPEED_READ,
        Scope.HEALTHKIT_LOCATION_READ,
      ]);

      _isAuthorized = authResult != null;
      if (_isAuthorized) {
        debugPrint('[HMS] 授权成功: openId=${authResult!.openId}');
      } else {
        debugPrint('[HMS] 授权失败: 用户取消或拒绝');
      }
      return _isAuthorized;
    } on PlatformException catch (e) {
      debugPrint('[HMS] 授权失败: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[HMS] 授权异常: $e');
      return false;
    }
  }

  /// 获取 HUAWEI Health Kit 中的跑步活动记录
  Future<List<HmsWorkoutData>> fetchWorkouts({
    DateTime? since,
    DateTime? until,
  }) async {
    if (!_isAuthorized) {
      final ok = await requestPermissions();
      if (!ok) return [];
    }

    final now = until ?? DateTime.now();
    final start = since ?? now.subtract(const Duration(days: 30));

    final results = <HmsWorkoutData>[];

    try {
      // 1. 读取跑步活动记录
      final records = await ActivityRecordsController.getActivityRecord(
        ActivityRecordReadOptions(
          startTime: start,
          endTime: now,
        ),
      );

      debugPrint('[HMS] 获取到 ${records.length} 条活动记录');

      for (final record in records) {
        if (record.activityTypeId != HiHealthActivities.running) continue;
        if (record.startTime == null || record.endTime == null) continue;

        try {
          final data = await _buildWorkoutFromRecord(record);
          if (data != null) results.add(data);
        } catch (e) {
          debugPrint('[HMS] 处理活动记录失败: $e');
        }
      }

      // 2. 如果 ActivityRecordsController 没有返回记录，
      //    回退到通过 DataController 按时间范围扫描健康数据
      if (results.isEmpty) {
        debugPrint('[HMS] 活动记录为空，尝试通过健康数据扫描...');
        final scanned = await _scanHealthData(start, now);
        results.addAll(scanned);
      }
    } on PlatformException catch (e) {
      debugPrint('[HMS] 读取活动记录失败: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('[HMS] 读取活动记录异常: $e');
    }

    // 去重
    final seen = <String>{};
    final unique = <HmsWorkoutData>[];
    for (final w in results) {
      if (seen.add(w.sourceId)) {
        unique.add(w);
      }
    }

    return unique;
  }

  /// 从 ActivityRecord 构建 HmsWorkoutData
  Future<HmsWorkoutData?> _buildWorkoutFromRecord(
    ActivityRecord record,
  ) async {
    final startTime = record.startTime!;
    final endTime = record.endTime!;
    final totalTime = endTime.difference(startTime).inSeconds;

    if (totalTime <= 0) return null;

    final sourceId =
        'huawei_${record.id ?? startTime.millisecondsSinceEpoch}';

    double? distance;
    int? avgHR;
    int? maxHR;
    int? calories;
    double? elevationGain;

    if (record.activitySummary != null) {
      final summary = record.activitySummary!;

      // 尝试从 dataSummary 提取距离、心率等
      if (summary.dataSummary != null) {
        for (final point in summary.dataSummary!) {
          final fieldValues = point.fieldValues;
          if (fieldValues == null) continue;

          final dataTypeString = point.dataType?.name ?? '';

          if (dataTypeString.contains('distance')) {
            distance ??= _extractDouble(fieldValues, 'distance');
          } else if (dataTypeString.contains('heart_rate')) {
            final hr = _extractDouble(fieldValues, 'bpm');
            if (hr != null) {
              avgHR ??= hr.round();
              if (hr > (maxHR ?? 0)) maxHR = hr.round();
            }
          } else if (dataTypeString.contains('calories')) {
            calories ??= _extractDouble(fieldValues, 'calories')?.round();
          }
        }
      }
    }

    // 如果统计数据不够，再去读取详细采样数据
    if (distance == null || avgHR == null) {
      final detailData = await _readDetailData(
        recordStart: startTime,
        recordEnd: endTime,
      );
      distance = (detailData['distance'] as double?) ?? 0.0;
      avgHR = detailData['avgHR'] as int?;
      maxHR = detailData['maxHR'] as int?;
      calories ??= detailData['calories'] as int?;
    }

    return HmsWorkoutData(
      sourceId: sourceId,
      startTime: startTime,
      endTime: endTime,
      totalDistance: distance,
      totalTime: totalTime,
      avgHeartRate: avgHR,
      maxHeartRate: maxHR,
      calories: calories,
      elevationGain: elevationGain,
    );
  }

  /// 读取活动时间范围内的详细健康数据
  Future<Map<String, dynamic>> _readDetailData({
    required DateTime recordStart,
    required DateTime recordEnd,
  }) async {
    double resultDistance = 0.0;
    final heartRates = <int>[];
    int? resultCalories;

    try {
      // 确保 DataController 已初始化
      _dataController ??= await DataController.init();

      // 读取距离
      final distanceReply = await _dataController!.read(
        ReadOptions(
          startTime: recordStart,
          endTime: recordEnd,
          dataTypes: [DataType.DT_CONTINUOUS_DISTANCE_DELTA],
        ),
      );
      if (distanceReply?.sampleSets != null) {
        for (final sampleSet in distanceReply!.sampleSets) {
          for (final point in sampleSet.samplePoints) {
            final val =
                _extractDouble(point.fieldValues ?? {}, 'distance_delta');
            resultDistance += val ?? 0.0;
          }
        }
      }

      // 读取心率
      final hrReply = await _dataController!.read(
        ReadOptions(
          startTime: recordStart,
          endTime: recordEnd,
          dataTypes: [DataType.DT_INSTANTANEOUS_HEART_RATE],
        ),
      );
      if (hrReply?.sampleSets != null) {
        for (final sampleSet in hrReply!.sampleSets) {
          for (final point in sampleSet.samplePoints) {
            final hr = _extractDouble(point.fieldValues ?? {}, 'bpm');
            if (hr != null) {
              heartRates.add(hr.round());
            }
          }
        }
      }

      // 读取卡路里
      final calReply = await _dataController!.read(
        ReadOptions(
          startTime: recordStart,
          endTime: recordEnd,
          dataTypes: [DataType.DT_CONTINUOUS_CALORIES_BURNT],
        ),
      );
      if (calReply?.sampleSets != null) {
        double totalCal = 0;
        for (final sampleSet in calReply!.sampleSets) {
          for (final point in sampleSet.samplePoints) {
            final val =
                _extractDouble(point.fieldValues ?? {}, 'calories');
            totalCal += val ?? 0.0;
          }
        }
        if (totalCal > 0) resultCalories = totalCal.round();
      }
    } catch (e) {
      debugPrint('[HMS] 读取详细信息失败: $e');
    }

    return {
      'distance': resultDistance,
      'avgHR':
          heartRates.isNotEmpty
              ? heartRates.reduce((a, b) => a + b) ~/ heartRates.length
              : null,
      'maxHR':
          heartRates.isNotEmpty
              ? heartRates.reduce((a, b) => a > b ? a : b)
              : null,
      'calories': resultCalories,
    };
  }

  /// 通过扫描健康数据发现跑步记录（回退策略）
  Future<List<HmsWorkoutData>> _scanHealthData(
    DateTime start,
    DateTime end,
  ) async {
    try {
      _dataController ??= await DataController.init();

      // 读取步数，使用 groupByTime 按分钟聚合
      final stepReadOptions = ReadOptions(
        startTime: start,
        endTime: end,
        dataTypes: [DataType.DT_CONTINUOUS_STEPS_DELTA],
      );
      stepReadOptions.groupByTime(60000); // 按分钟分组

      final stepReply = await _dataController!.read(stepReadOptions);

      if (stepReply?.sampleSets == null ||
          stepReply!.sampleSets.isEmpty) {
        return [];
      }

      // 找到有步数的连续时间段
      final activeWindows = <_ActiveWindow>[];
      _ActiveWindow? current;

      for (final sampleSet in stepReply.sampleSets) {
        for (final point in sampleSet.samplePoints) {
          final steps = _extractDouble(
            point.fieldValues ?? {},
            'steps_delta',
          );
          final stepCount = (steps ?? 0).round();

          if (stepCount > 0 && point.startTime != null) {
            if (current == null) {
              current = _ActiveWindow(
                startTime: point.startTime!,
                endTime: point.endTime ?? point.startTime!,
              );
            } else {
              final gap =
                  point.startTime!.difference(current.endTime).inMinutes;
              if (gap <= 5) {
                current.endTime = point.endTime ?? point.startTime!;
              } else {
                if (current.durationMinutes >= 10) {
                  activeWindows.add(current);
                }
                current = _ActiveWindow(
                  startTime: point.startTime!,
                  endTime: point.endTime ?? point.startTime!,
                );
              }
            }
          }
        }
      }
      if (current != null && current.durationMinutes >= 10) {
        activeWindows.add(current);
      }

      // 为每个有效时间段创建 HmsWorkoutData
      final results = <HmsWorkoutData>[];
      for (final window in activeWindows) {
        final totalTime =
            window.endTime.difference(window.startTime).inSeconds;

        final detail = await _readDetailData(
          recordStart: window.startTime,
          recordEnd: window.endTime,
        );

        results.add(
          HmsWorkoutData(
            sourceId:
                'huawei_scan_${window.startTime.millisecondsSinceEpoch}',
            startTime: window.startTime,
            endTime: window.endTime,
            totalDistance: (detail['distance'] as double?) ?? 0.0,
            totalTime: totalTime,
            avgHeartRate: detail['avgHR'] as int?,
            maxHeartRate: detail['maxHR'] as int?,
            calories: detail['calories'] as int?,
          ),
        );
      }

      return results;
    } catch (e) {
      debugPrint('[HMS] 扫描健康数据失败: $e');
      return [];
    }
  }

  /// 同步近期跑步记录
  Future<HmsHealthImportResult> syncRecentWorkouts({
    required Future<bool> Function(HmsWorkoutData data) onImport,
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

    return HmsHealthImportResult(imported: imported, errors: errors);
  }

  /// 从 fieldValues Map 中提取 double 值
  double? _extractDouble(Map<String, dynamic>? fieldValues, String key) {
    if (fieldValues == null) return null;
    final val = fieldValues[key];
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

/// 活跃时间段内部类
class _ActiveWindow {
  DateTime startTime;
  DateTime endTime;

  _ActiveWindow({required this.startTime, required this.endTime});

  int get durationMinutes => endTime.difference(startTime).inMinutes;
}
