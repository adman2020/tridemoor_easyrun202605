/// 开发阶段种子数据 Provider —— 不依赖后端 API
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/route.dart' as app_route;
import '../seed_data/routes_seed.dart';
import 'route_provider.dart' show UploadRecord;

/// 种子：我的跑迹（含删除功能）
class _MyRoutesNotifier extends Notifier<List<app_route.Route>> {
  @override
  List<app_route.Route> build() {
    ref.keepAlive();
    return myRoutesSeed;
  }

  void removeById(String id) {
    state = state.where((r) => r.id != id).toList();
  }
}

final seedMyRoutesProvider = NotifierProvider<_MyRoutesNotifier, List<app_route.Route>>(
  _MyRoutesNotifier.new,
);

/// 种子：跑友跑迹（含取消收藏功能）
class _FriendsRoutesNotifier extends Notifier<List<app_route.Route>> {
  @override
  List<app_route.Route> build() {
    ref.keepAlive();
    return friendsRoutesSeed;
  }

  void removeById(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  void addRoute(app_route.Route route) {
    // 避免重复收藏
    if (state.any((r) => r.id == route.id)) return;
    state = [...state, route];
  }
}

final seedFriendsRoutesProvider = NotifierProvider<_FriendsRoutesNotifier, List<app_route.Route>>(
  _FriendsRoutesNotifier.new,
);

/// 种子：上传记录
final seedUploadRecordsProvider = FutureProvider<List<UploadRecord>>((ref) async {
  return uploadRecordsSeed.map((s) => UploadRecord(
    id: s.id,
    name: s.name,
    distance: s.distance,
    date: s.date,
    status: s.status,
    remainingHours: s.remainingHours,
  )).toList();
});
