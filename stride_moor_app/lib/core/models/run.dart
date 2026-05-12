import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/formatters.dart';
import 'run_split.dart';

part 'run.freezed.dart';

/// 跑步记录模型
///
/// 【注意】手写 fromJson 以正确映射后端 snake_case 字段，
/// 特别是 `sample_time` → `timestamp`、`heart_rate` → `heartRate` 等特殊映射。
///
/// 关于时间处理：后端始终返回 +08:00 的 ISO 8601 字符串。
/// Dart 的 DateTime.parse 会按手机系统时区转换，导致日期偏移。
/// 为避免此问题，startTime/endTime 只从 ISO 字符串前10位提取日期部分
/// （YYYY-MM-DD），不依赖时区解析。需要精确时间应使用原始的
/// startTimeIso/endTimeIso 字符串。
@freezed
class Run with _$Run {
  const factory Run({
    required String id,
    required String userId,
    /// 关联路线ID（可选，独自跑可能无路线）
    String? routeId,
    /// 开始时间（仅日期有效，精确时间请用 startTimeIso）
    required DateTime startTime,
    /// 结束时间（仅日期有效，精确时间请用 endTimeIso）
    DateTime? endTime,
    /// 后端返回的原始 start_time ISO 字符串（时区信息完整）
    String? startTimeIso,
    /// 后端返回的原始 end_time ISO 字符串（时区信息完整）
    String? endTimeIso,
    /// 总距离（米）
    @Default(0) double totalDistance,
    /// 总用时（秒）
    @Default(0) int totalTime,
    /// 平均配速（秒/公里）
    int? avgPace,
    /// 平均心率
    int? avgHeartRate,
    /// 平均步频
    int? avgCadence,
    /// 平均步幅（米）
    double? avgStrideLength,
    /// 累计爬升（米）
    @Default(0) double elevationGain,
    /// 累计下降（米）
    @Default(0) double elevationLoss,
    /// 最大心率
    int? maxHeartRate,
    /// 最大步频
    int? maxCadence,
    /// 卡路里估算
    int? calories,
    /// 天气
    String? weather,
    /// 温度
    double? temperature,
    /// GPX文件URL
    String? gpxFileUrl,
    /// 设备类型
    String? deviceType,
    /// 跑步模式
    @Default('solo') String mode,
    /// 分段数据
    @Default([]) List<RunSplit> splits,
    /// 轨迹采样点（简化存储，完整数据存GPX）
    @Default([]) List<RunSample> samples,
    /// 挑战的比拼指标（如 pace / heart_rate / cadence 等），仅挑战跑有
    String? goalMetric,
    /// 伴跑/挑战跑的对手跑步记录（详情接口返回）
    Run? opponentRun,
    /// GPS采样点最小外接矩形（用于伴跑/挑战前距离校验）
    RunBounds? bounds,
    /// 伴跑/挑战跑的对手GPS轨迹采样点
    @Default([]) List<RunSample> opponentSamples,
  }) = _Run;

  /// 自定义 fromJson —— 正确处理后端 snake_case 字段 + null 安全
  /// 注意：列表接口(RunListItem)可能只返回部分字段，需对所有字段做缺失保护
  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      routeId: json['route_id'] as String?,
      // 从 ISO 字符串取前10位 YYYY-MM-DD，避免 DateTime.parse 的时区偏移
      startTime: Formatters.dateFromIso(json['start_time'] as String?),
      startTimeIso: json['start_time'] as String?,
      endTime: json['end_time'] != null
          ? Formatters.dateFromIso(json['end_time'] as String?)
          : null,
      endTimeIso: json['end_time'] as String?,
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0,
      totalTime: (json['total_time'] as num?)?.toInt() ?? 0,
      avgPace: (json['avg_pace'] as num?)?.toInt(),
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt(),
      avgCadence: (json['avg_cadence'] as num?)?.toInt(),
      avgStrideLength: (json['avg_stride_length'] as num?)?.toDouble(),
      elevationGain: (json['elevation_gain'] as num?)?.toDouble() ?? 0,
      elevationLoss: (json['elevation_loss'] as num?)?.toDouble() ?? 0,
      maxHeartRate: (json['max_heart_rate'] as num?)?.toInt(),
      maxCadence: (json['max_cadence'] as num?)?.toInt(),
      calories: (json['calories'] as num?)?.toInt(),
      weather: json['weather'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      gpxFileUrl: json['gpx_file_url'] as String?,
      deviceType: json['device_type'] as String?,
      mode: json['mode'] as String? ?? 'solo',
      goalMetric: json['goal_metric'] as String?,
      splits: (json['splits'] as List<dynamic>?)
              ?.map((e) => RunSplit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      samples: (json['samples'] as List<dynamic>?)
              ?.map((e) => RunSample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      opponentRun: json['opponent_run'] != null
          ? Run.fromJson(json['opponent_run'] as Map<String, dynamic>)
          : null,
      opponentSamples: (json['opponent_samples'] as List<dynamic>?)
              ?.map((e) => RunSample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bounds: json['bounds'] != null
          ? RunBounds.fromJson(json['bounds'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// GPS采样点最小外接矩形（用于伴跑/挑战前距离校验）
class RunBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const RunBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  factory RunBounds.fromJson(Map<String, dynamic> json) {
    return RunBounds(
      minLat: (json['min_lat'] as num).toDouble(),
      maxLat: (json['max_lat'] as num).toDouble(),
      minLng: (json['min_lng'] as num).toDouble(),
      maxLng: (json['max_lng'] as num).toDouble(),
    );
  }

  /// 中心点纬度
  double get centerLat => (minLat + maxLat) / 2;
  /// 中心点经度
  double get centerLng => (minLng + maxLng) / 2;
}

/// 跑步秒级采样点
@freezed
class RunSample with _$RunSample {
  const factory RunSample({
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    double? altitude,
    /// 瞬时配速（秒/公里）
    int? pace,
    int? heartRate,
    int? cadence,
    double? strideLength,
    /// 距起点距离（米）
    @Default(0) double distanceFromStart,
  }) = _RunSample;

  /// 自定义 fromJson —— 后端 `sample_time` → 前端 `timestamp`
  factory RunSample.fromJson(Map<String, dynamic> json) {
    return RunSample(
      timestamp: DateTime.parse(json['sample_time'] as String? ?? json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      pace: (json['pace'] as num?)?.toInt(),
      heartRate: (json['heart_rate'] as num?)?.toInt(),
      cadence: (json['cadence'] as num?)?.toInt(),
      strideLength: (json['stride_length'] as num?)?.toDouble(),
      distanceFromStart: (json['distance_from_start'] as num?)?.toDouble() ?? 0,
    );
  }
}
