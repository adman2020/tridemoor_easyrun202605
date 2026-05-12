import 'package:freezed_annotation/freezed_annotation.dart';

part 'run_split.freezed.dart';

/// 跑步分段数据（每1km）
///
/// 【注意】手写 fromJson 以正确映射后端 snake_case 字段
@freezed
class RunSplit with _$RunSplit {
  const factory RunSplit({
    required String id,
    required String runId,
    required int splitIndex,
    /// 分段距离（米）
    @Default(1000) double distance,
    /// 分段用时（秒）
    required int time,
    /// 分段配速（秒/公里）
    int? pace,
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
  }) = _RunSplit;

  /// 手写 fromJson —— 后端返回 snake_case
  factory RunSplit.fromJson(Map<String, dynamic> json) {
    return RunSplit(
      id: json['id'] as String? ?? '',
      runId: json['run_id'] as String? ?? '',
      splitIndex: (json['split_index'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 1000,
      time: (json['time'] as num?)?.toInt() ?? 0,
      pace: (json['pace'] as num?)?.toInt(),
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt(),
      avgCadence: (json['avg_cadence'] as num?)?.toInt(),
      avgStrideLength: (json['avg_stride_length'] as num?)?.toDouble(),
      elevationGain: (json['elevation_gain'] as num?)?.toDouble() ?? 0,
      elevationLoss: (json['elevation_loss'] as num?)?.toDouble() ?? 0,
    );
  }
}
// refresh