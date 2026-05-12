import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// 用户模型
///
/// 【注意】手写 fromJson 以正确映射后端 snake_case 字段
@freezed
class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String nickname,
    String? avatar,
    String? phone,
    String? email,
    String? bio,
    @Default([]) List<String> deviceInfo,
    @Default(0) double totalDistanceKm,
    @Default(0) int totalRuns,
    @Default(0) int totalDurationSeconds,
    @Default(0) int totalCalories,
    @Default(0) int companionRuns,
    @Default(0) int challengesWon,
    @Default(0) int bestMarathonTime,
    @Default(0) int postCount,
    @Default(0) int realm,
    @Default([]) List<String> realmBadges,
    @Default(0) int isVip,
    @Default(0) int vipTier,
    DateTime? vipExpiresAt,
    @Default([]) List<String> vipFeatures,
    @Default(0) int cyclingRealm,
    DateTime? createdAt,
  }) = _User;

  /// 手写 fromJson —— 后端返回 snake_case
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      deviceInfo: _parseStringList(json['device_info']),
      totalDistanceKm: (() {
      final val = (json['total_distance'] as num?)?.toDouble() ?? 0;
      // 旧 Docker 返回米（35740），新 Docker 返回公里（35.74）
      return val > 1000 ? val / 1000.0 : val;
    })(),
      totalRuns: (json['total_runs'] as num?)?.toInt() ?? 0,
      totalDurationSeconds: (json['total_time'] as num?)?.toInt() ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      companionRuns: (json['companion_runs'] as num?)?.toInt() ?? 0,
      challengesWon: (json['challenges_won'] as num?)?.toInt() ?? 0,
      bestMarathonTime: (json['best_marathon_time'] as num?)?.toInt() ?? 0,
      postCount: (json['post_count'] as num?)?.toInt() ?? 0,
      realm: (json['realm'] as num?)?.toInt() ?? 0,
      realmBadges: _parseStringList(json['realm_badges']),
      isVip: _toInt(json['is_vip']),
      vipTier: _toInt(json['vip_tier']),
      vipExpiresAt: json['vip_expires_at'] != null
          ? DateTime.tryParse(json['vip_expires_at'] as String)
          : null,
      vipFeatures: _parseStringList(json['vip_features']),
      cyclingRealm: (json['cycling_realm'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  /// 头像 URL 别名
  String? get avatarUrl => avatar;

  /// 兼容后端可能返回 int（0/1）或 bool（true/false）的布尔字段
  static int _toInt(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    return (value as num?)?.toInt() ?? 0;
  }

  /// 安全解析后端可能返回字符串或数组的字段
  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
  }
}
