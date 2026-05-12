import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge.freezed.dart';
part 'challenge.g.dart';

/// 路线挑战（陪跑邀请）
///
/// 【注意】手写 fromJson 以正确映射后端 snake_case 字段
@freezed
class Challenge with _$Challenge {
  const factory Challenge({
    required String id,
    required String routeId,
    /// 挑战者
    required String challengerId,
    String? challengerRunId,
    /// 被邀请者
    String? inviteeId,
    /// 陪跑模式: real_replay / constant / rabbit / tortoise_hare / goal
    @Default('real_replay') String ghostMode,
    /// 目标挑战维度: pace / heart_rate / cadence / stride_length
    String? goalMetric,
    /// 状态: pending / running / completed
    @Default('pending') String status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) = _Challenge;

  /// 手写 fromJson —— 后端返回 snake_case
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String? ?? '',
      routeId: json['route_id'] as String? ?? '',
      challengerId: json['challenger_id'] as String? ?? '',
      challengerRunId: json['challenger_run_id'] as String?,
      inviteeId: json['invitee_id'] as String?,
      ghostMode: json['ghost_mode'] as String? ?? 'real_replay',
      goalMetric: json['goal_metric'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );
  }
}

/// 对比报告
///
/// 【注意】手写 fromJson 以正确映射后端 snake_case 字段
@freezed
class Comparison with _$Comparison {
  const factory Comparison({
    required String id,
    String? challengeId,
    required String runAId,
    required String runBId,
    /// 总体差异摘要
    Map<String, dynamic>? overallDiff,
    /// 分段对比详情 JSON
    @Default({}) Map<String, dynamic> splitsJson,
    /// AI诊断建议 JSON
    @Default({}) Map<String, dynamic> diagnosisJson,
    DateTime? createdAt,
  }) = _Comparison;

  /// 手写 fromJson —— 后端返回 snake_case
  factory Comparison.fromJson(Map<String, dynamic> json) {
    return Comparison(
      id: json['id'] as String? ?? '',
      challengeId: json['challenge_id'] as String?,
      runAId: json['run_a_id'] as String? ?? '',
      runBId: json['run_b_id'] as String? ?? '',
      overallDiff: json['overall_diff'] as Map<String, dynamic>?,
      splitsJson: json['splits_json'] as Map<String, dynamic>? ?? const {},
      diagnosisJson:
          json['diagnosis_json'] as Map<String, dynamic>? ?? const {},
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
