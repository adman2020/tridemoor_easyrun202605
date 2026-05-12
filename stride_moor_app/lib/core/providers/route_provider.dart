import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/route.dart' as app_route;
import '../services/location_service.dart';

import 'app_providers.dart';
import 'user_provider.dart';

// ==================== 路线列表 ====================

/// 路线列表（支持排序: popularity / rating / distance / null=最新）
final routeListProvider = FutureProvider.family<List<app_route.Route>, String?>((ref, sortBy) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.getRouteList(pageSize: 20, sortBy: sortBy);
  if (!response.isSuccess) throw Exception(response.message);
  final data = response.data!;
  final list = (data['list'] as List<dynamic>)
      .map((e) => app_route.Route.fromJson(e as Map<String, dynamic>))
      .toList();
  return list;
});

// ==================== 按地区分组 ====================

/// 按城市分组的路线列表，用于「按地区」浏览
final routesByCityProvider = FutureProvider<Map<String, List<app_route.Route>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  // 获取所有路线（不分页），客户端按 city 分组
  final response = await api.getRouteList(pageSize: 100);
  if (!response.isSuccess) throw Exception(response.message);
  final data = response.data!;
  final list = (data['list'] as List<dynamic>)
      .map((e) => app_route.Route.fromJson(e as Map<String, dynamic>))
      .toList();

  // 按城市分组
  final Map<String, List<app_route.Route>> grouped = {};
  for (final route in list) {
    final city = route.city?.isNotEmpty == true ? route.city! : '其他';
    grouped.putIfAbsent(city, () => []);
    grouped[city]!.add(route);
  }
  return grouped;
});

// ==================== 附近路线 ====================

/// 附近路线（基于真实定位，定位不可用时回退到用户所在城市）
final nearbyRoutesProvider = FutureProvider<List<app_route.Route>>((ref) async {
  final api = ref.read(apiServiceProvider);

  // 获取真实定位
  double lat;
  double lng;
  final loc = LocationService.instance.lastKnownLocation;
  if (loc != null) {
    (lat, lng) = loc;
  } else {
    // 没有定位权限时，默认显示深圳（用户所在地）
    lat = 22.5431;
    lng = 114.0579;
  }

  // 扩大搜索半径到 50km，保证能搜到本城市路线
  final response = await api.getNearbyRoutes(
    lat: lat,
    lng: lng,
    radius: 50000,
    limit: 20,
  );
  if (!response.isSuccess) throw Exception(response.message);
  final data = response.data!;
  final list = (data['routes'] as List<dynamic>)
      .map((e) => app_route.Route.fromJson(e as Map<String, dynamic>))
      .toList();
  return list;
});

// ==================== 路线详情 ====================

/// 路线详情包装类（包含收藏状态）
class RouteDetail {
  final app_route.Route route;
  final bool isFavorited;
  final int favCount;

  const RouteDetail({
    required this.route,
    required this.isFavorited,
    required this.favCount,
  });
}

/// 路线详情 Provider
final routeDetailProvider = FutureProvider.family<RouteDetail, String>((ref, routeId) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.getRouteDetail(routeId);
  if (!response.isSuccess) throw Exception(response.message);
  final data = response.data!;
  final routeJson = Map<String, dynamic>.from(data['route'] as Map<String, dynamic>);
  // 将后端的 points 数组合并到 routeJson，供 Route.fromJson 解析 geometry
  final points = data['points'] as List<dynamic>?;
  if (points != null && points.isNotEmpty) {
    routeJson['points'] = points;
  }
  final route = app_route.Route.fromJson(routeJson);
  final isFavorited = data['is_favorited'] as bool? ?? false;
  final favCount = (data['fav_count'] as num?)?.toInt() ?? route.favoriteCount;
  return RouteDetail(route: route, isFavorited: isFavorited, favCount: favCount);
});

/// 收藏/取消收藏动作 Provider
final favoriteActionProvider = Provider.family<Future<void> Function(), String>((ref, routeId) {
  final api = ref.read(apiServiceProvider);
  return () async {
    final response = await api.favoriteRoute(routeId);
    if (!response.isSuccess) throw Exception(response.message);
  };
});

final unfavoriteActionProvider = Provider.family<Future<void> Function(), String>((ref, routeId) {
  final api = ref.read(apiServiceProvider);
  return () async {
    final response = await api.unfavoriteRoute(routeId);
    if (!response.isSuccess) throw Exception(response.message);
  };
});

// ==================== 排行榜 ====================

/// 路线排行榜 Provider
/// params: (routeId, sortBy)  sortBy: 空=打卡榜, time_asc=成绩榜
final routeLeaderboardProvider = FutureProvider.family<List<app_route.RouteLeaderboardEntry>, (String routeId, String sortBy)>((ref, params) async {
  final (routeId, sortBy) = params;
  final api = ref.read(apiServiceProvider);
  final response = await api.getRouteLeaderboard(routeId, sortBy: sortBy.isEmpty ? null : sortBy);
  if (!response.isSuccess) throw Exception(response.message);
  final data = response.data!;
  final list = (data['list'] as List<dynamic>)
      .map((e) => app_route.RouteLeaderboardEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  return list;
});

// ==================== 我的路线 ====================

/// 我创建的路线（后端暂无 creator_id 筛选，前端过滤）
final myRoutesProvider = FutureProvider<List<app_route.Route>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final userAsync = ref.read(userProvider);
  final user = userAsync.value;
  if (user == null) return const [];

  final response = await api.getRouteList(pageSize: 100);
  if (!response.isSuccess) throw Exception(response.message);
  final data = response.data!;
  final list = (data['list'] as List<dynamic>)
      .map((e) => app_route.Route.fromJson(e as Map<String, dynamic>))
      .toList();
  return list.where((r) => r.creatorId == user.id).toList();
});

/// 我的收藏路线（从 Favorite 列表中提取嵌套的 Route）
final myFavoriteRoutesProvider = FutureProvider<List<app_route.Route>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.getFavoriteList(pageSize: 50);
  if (!response.isSuccess) throw Exception(response.message);
  final data = response.data!;
  final list = (data['list'] as List<dynamic>).map((e) {
    final fav = e as Map<String, dynamic>;
    final routeJson = fav['route'] as Map<String, dynamic>?;
    if (routeJson != null) {
      return app_route.Route.fromJson(routeJson);
    }
    return null;
  }).whereType<app_route.Route>().toList();
  return list;
});

// ==================== 跑友跑迹 ====================

/// 收藏的跑友跑步记录（跑迹收藏）
/// 返回原始 bookmark 条目，每项包含 run / run.user / run.route
final friendsRoutesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // 监听用户状态，用户切换时自动失效重取
  final user = ref.watch(userProvider);
  // 未登录 => 空列表，不发起请求
  if (user.valueOrNull == null) return [];

  final api = ref.read(apiServiceProvider);
  final response = await api.getBookmarkedRuns();
  if (!response.isSuccess) throw Exception(response.message);
  final data = response.data!;
  return (data['list'] as List<dynamic>).cast<Map<String, dynamic>>();
});

// ==================== 上传管理 ====================

/// 上传记录 Provider（从 routes 中过滤出我创建的）
/// 扩展 Route 为带上传状态的包装
class UploadRecord {
  final String id;
  final String name;
  final double distance;
  final String date;
  final String status; // approved | pending | failed
  final int? remainingHours;

  const UploadRecord({
    required this.id,
    required this.name,
    required this.distance,
    required this.date,
    this.status = 'pending',
    this.remainingHours,
  });
}

/// 上传记录列表 Provider
final uploadRecordsProvider = FutureProvider<List<UploadRecord>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final userAsync = ref.read(userProvider);
  final user = userAsync.value;
  if (user == null) return const [];

  final response = await api.getRouteList(pageSize: 100);
  if (!response.isSuccess) throw Exception(response.message);
  final data = response.data!;
  final list = (data['list'] as List<dynamic>)
      .map((e) => app_route.Route.fromJson(e as Map<String, dynamic>))
      .toList();
  return list.where((r) => r.creatorId == user.id).map((r) {
    return UploadRecord(
      id: r.id,
      name: r.name,
      distance: r.distance,
      date: r.createdAt != null
          ? '${r.createdAt!.year}-${r.createdAt!.month.toString().padLeft(2, '0')}-${r.createdAt!.day.toString().padLeft(2, '0')}'
          : '--',
      status: 'approved',
    );
  }).toList();
});
// ========== 收藏/已收藏状态管理 ==========

/// 已收藏跑迹ID集合（从 friendsRoutesProvider 同步，支持本地增量更新）
final bookmarkedRunIdsProvider = StateNotifierProvider<BookmarkedRunIdsNotifier, Set<String>>((ref) {
  final notifier = BookmarkedRunIdsNotifier();
  // 初始同步
  final current = ref.read(friendsRoutesProvider);
  if (current is AsyncData) {
    final ids = current.requireValue
        .map((m) => m['run_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    notifier.sync(ids);
  }
  // 监听后端更新
  ref.listen(friendsRoutesProvider, (prev, next) {
    next.whenData((list) {
      final ids = list
          .map((m) => m['run_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      notifier.sync(ids);
    });
  });
  return notifier;
});

class BookmarkedRunIdsNotifier extends StateNotifier<Set<String>> {
  BookmarkedRunIdsNotifier() : super({});

  void add(String runId) {
    state = {...state, runId};
  }

  void sync(Set<String> ids) {
    if (ids.isNotEmpty) state = ids;
  }
}

/// 已收藏路线ID集合（从 myFavoriteRoutesProvider 同步，支持本地增量更新）
final favoritedRouteIdsProvider = StateNotifierProvider<FavoritedRouteIdsNotifier, Set<String>>((ref) {
  final notifier = FavoritedRouteIdsNotifier();
  // 初始同步
  final current = ref.read(myFavoriteRoutesProvider);
  if (current is AsyncData) {
    final ids = current.requireValue.map((r) => r.id).toSet();
    notifier.sync(ids);
  }
  // 监听后端更新
  ref.listen(myFavoriteRoutesProvider, (prev, next) {
    next.whenData((list) {
      final ids = list.map((r) => r.id).toSet();
      notifier.sync(ids);
    });
  });
  return notifier;
});

class FavoritedRouteIdsNotifier extends StateNotifier<Set<String>> {
  FavoritedRouteIdsNotifier() : super({});

  void add(String routeId) {
    state = {...state, routeId};
  }

  void sync(Set<String> ids) {
    if (ids.isNotEmpty) state = ids;
  }
}