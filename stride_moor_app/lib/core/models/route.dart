import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'route.freezed.dart';
part 'route.g.dart';

/// 路线模型（由跑步轨迹抽象而来）
@freezed
class Route with _$Route {
  const factory Route({
    required String id,
    required String creatorId,
    String? creatorName,
    String? creatorAvatar,
    required String name,
    String? description,
    /// 简化后的轨迹几何数据（经纬度数组）
    @Default([]) List<Map<String, double>> geometry,
    /// 总距离（米）
    required double distance,
    /// 累计爬升（米）
    @Default(0) double elevationGain,
    /// 难度: easy, moderate, hard
    @Default('easy') String difficulty,
    /// 路面类型: 0=普通, 1=大马路, 2=绿道, 3=坡道, 4=跑道, 5=河边, 6=土路
    @Default(0) int roadType,
    /// 热度（被陪跑次数）
    @Default(0) int popularity,
    /// 起点 {lat, lng}
    Map<String, double>? startPoint,
    /// 中心点 {lat, lng}
    Map<String, double>? centerPoint,
    /// 标签
    @Default([]) List<String> tags,
    /// 评分 0-5
    @Default(0.0) double rating,
    /// 被收藏数
    @Default(0) int favoriteCount,
    DateTime? createdAt,

    /// 城市
    String? city,

    /// 来自原跑步记录的指标（可选）
    @Default(0) int avgPace,
    @Default(0) int avgCadence,
    @Default(0.0) double avgStride,
    @Default(0) int calories,
    @Default(0) int avgHeartRate,
    @Default(0.0) double elevationLoss,
    int? totalTime,
    int? maxHeartRate,
    int? maxCadence,
  }) = _Route;

  factory Route.fromJson(Map<String, dynamic> json) {
    // difficulty: backend is int (1/2/3), frontend expects String
    String difficultyStr;
    final diff = json['difficulty'];
    if (diff is int) {
      switch (diff) {
        case 1:
          difficultyStr = 'easy';
        case 2:
          difficultyStr = 'moderate';
        case 3:
          difficultyStr = 'hard';
        default:
          difficultyStr = 'easy';
      }
    } else if (diff is String) {
      difficultyStr = diff;
    } else {
      difficultyStr = 'easy';
    }

    // tags: backend stores as JSON string
    List<String> parseTags(dynamic value) {
      if (value is List) {
        return value.whereType<String>().toList();
      }
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.whereType<String>().toList();
          }
        } catch (_) {}
      }
      return const [];
    }

    // startPoint / centerPoint from separate lat/lng fields
    Map<String, double>? parsePoint(double? lat, double? lng) {
      if (lat == null || lng == null) return null;
      return {'lat': lat, 'lng': lng};
    }

    // creator info from nested creator object (detail API only)
    String? creatorName;
    String? creatorAvatar;
    final creator = json['creator'];
    if (creator is Map<String, dynamic>) {
      creatorName = creator['nickname'] as String? ?? creator['username'] as String?;
      creatorAvatar = creator['avatar'] as String?;
    }

    // geometry from points array (detail API)
    List<Map<String, double>> geometry = const [];
    final points = json['points'];
    if (points is List) {
      geometry = points
          .whereType<Map<String, dynamic>>()
          .map((p) => <String, double>{
                'lat': (p['latitude'] as num?)?.toDouble() ?? 0.0,
                'lng': (p['longitude'] as num?)?.toDouble() ?? 0.0,
              })
          .toList();
    }

    return Route(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      creatorName: creatorName,
      creatorAvatar: creatorAvatar,
      name: json['name'] as String,
      description: json['description'] as String?,
      geometry: geometry,
      distance: (json['distance'] as num).toDouble(),
      elevationGain: (json['elevation_gain'] as num?)?.toDouble() ?? 0,
      avgPace: (json['avg_pace'] as num?)?.toInt() ?? 0,
      avgCadence: (json['avg_cadence'] as num?)?.toInt() ?? 0,
      avgStride: (json['avg_stride'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt() ?? 0,
      elevationLoss: (json['elevation_loss'] as num?)?.toDouble() ?? 0.0,
      totalTime: (json['total_time'] as num?)?.toInt(),
      maxHeartRate: (json['max_heart_rate'] as num?)?.toInt(),
      maxCadence: (json['max_cadence'] as num?)?.toInt(),
      difficulty: difficultyStr,
      roadType: (json['road_type'] as num?)?.toInt() ?? 0,
      popularity: (json['popularity'] as num?)?.toInt() ?? 0,
      startPoint: parsePoint(
        (json['start_lat'] as num?)?.toDouble(),
        (json['start_lng'] as num?)?.toDouble(),
      ),
      centerPoint: parsePoint(
        (json['center_lat'] as num?)?.toDouble(),
        (json['center_lng'] as num?)?.toDouble(),
      ),
      tags: parseTags(json['tags']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      favoriteCount: (json['favorite_count'] as num?)?.toInt() ?? 0,
      city: json['city'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 路线收藏
@freezed
class RouteFavorite with _$RouteFavorite {
  const factory RouteFavorite({
    required String id,
    required String userId,
    required String routeId,
    /// 标签: want_to_run / completed
    @Default('want_to_run') String tag,
    DateTime? createdAt,
  }) = _RouteFavorite;

  factory RouteFavorite.fromJson(Map<String, dynamic> json) => RouteFavorite(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        routeId: json['route_id'] as String,
        tag: json['tag'] as String? ?? 'want_to_run',
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );
}

/// 路线排行榜条目
@freezed
class RouteLeaderboardEntry with _$RouteLeaderboardEntry {
  const factory RouteLeaderboardEntry({
    required String id,
    required String routeId,
    required String userId,
    String? userNickname,
    String? userAvatar,
    required String runId,
    /// 总用时（秒）
    required int totalTime,
    /// 平均配速（秒/公里）
    int? avgPace,
    /// 在此路线打卡次数
    @Default(0) int runCount,
    /// 平均心率
    int? avgHeartRate,
    /// 平均步频
    int? avgCadence,
    DateTime? recordedAt,
  }) = _RouteLeaderboardEntry;

  factory RouteLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    String? userNickname;
    String? userAvatar;
    final user = json['user'];
    if (user is Map<String, dynamic>) {
      userNickname = user['nickname'] as String? ?? user['username'] as String?;
      userAvatar = user['avatar'] as String?;
    }

    return RouteLeaderboardEntry(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      userId: json['user_id'] as String,
      userNickname: userNickname,
      userAvatar: userAvatar,
      runId: json['run_id'] as String,
      totalTime: (json['total_time'] as num).toInt(),
      avgPace: (json['avg_pace'] as num?)?.round(),
      runCount: (json['run_count'] as num?)?.toInt() ?? 0,
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt(),
      avgCadence: (json['avg_cadence'] as num?)?.toInt(),
      recordedAt: json['recorded_at'] == null
          ? null
          : DateTime.parse(json['recorded_at'] as String),
    );
  }
}
