import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

/// 个人挑战记录项（从后端 /challenges 原始 JSON 解析）
class ChallengeHistoryItem {
  final String id;
  final String routeId;
  final String challengerId;
  final String? inviteeId;
  final String? winnerId;
  final String status;
  final String ghostMode;
  final String? goalMetric;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? route;
  final Map<String, dynamic>? challenger;
  final Map<String, dynamic>? invitee;

  ChallengeHistoryItem({
    required this.id,
    required this.routeId,
    required this.challengerId,
    this.inviteeId,
    this.winnerId,
    required this.status,
    required this.ghostMode,
    this.goalMetric,
    this.createdAt,
    this.completedAt,
    this.route,
    this.challenger,
    this.invitee,
  });

  factory ChallengeHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChallengeHistoryItem(
      id: json['id'] as String? ?? '',
      routeId: json['route_id'] as String? ?? '',
      challengerId: json['challenger_id'] as String? ?? '',
      inviteeId: json['invitee_id'] as String?,
      winnerId: json['winner_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      ghostMode: json['ghost_mode'] as String? ?? 'real_replay',
      goalMetric: json['goal_metric'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      route: json['route'] as Map<String, dynamic>?,
      challenger: json['challenger'] as Map<String, dynamic>?,
      invitee: json['invitee'] as Map<String, dynamic>?,
    );
  }

  String get routeName => route?['name'] as String? ?? '未知路线';
  String get challengerName => challenger?['nickname'] as String? ?? '未知用户';
  String get inviteeName => invitee?['nickname'] as String? ?? '未知用户';

  /// 相对于当前用户的对手昵称
  String opponentName(String currentUserId) {
    if (challengerId == currentUserId) {
      return inviteeName;
    }
    return challengerName;
  }

  /// 判断当前用户的挑战结果
  /// - win : 当前用户获胜
  /// - lose: 当前用户失败
  /// - draw: 无胜负（自发陪跑等）
  String resultFor(String currentUserId) {
    if (winnerId == null) return 'draw';
    if (winnerId == currentUserId) return 'win';
    return 'lose';
  }
}

/// 个人挑战记录 Provider（已完成状态）
final myChallengesProvider =
    FutureProvider<List<ChallengeHistoryItem>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.getChallengeList(
    status: 'completed',
    page: 1,
    pageSize: 100,
  );
  if (!resp.isSuccess) return [];
  final list = (resp.data?['list'] as List<dynamic>?) ?? [];
  return list
      .map((e) => ChallengeHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});
