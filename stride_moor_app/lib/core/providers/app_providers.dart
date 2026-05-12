import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/ble_service.dart';
import '../services/mock_ble_service.dart';
import '../services/storage_service.dart';

/// 全局服务 Provider

/// API 服务（依赖 StorageService）
final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiService(storage: storage);
});

/// 本地存储服务
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// 当前主题模式
final themeModeProvider = StateProvider<bool>((ref) => false);

/// 当前登录用户ID（null 表示未登录）
final currentUserIdProvider = StateProvider<String?>((ref) => null);

/// BLE 蓝牙设备服务（目前使用 Mock 模式）
final bleServiceProvider = Provider<BleService>((ref) {
  return MockBleService();
});

/// 已关注用户ID集合（本地 Hive 缓存 + 后端同步）
final followedUserIdsProvider = StateNotifierProvider<FollowedUserIdsNotifier, Set<String>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final api = ref.watch(apiServiceProvider);
  return FollowedUserIdsNotifier(storage: storage, api: api);
});

class FollowedUserIdsNotifier extends StateNotifier<Set<String>> {
  final StorageService _storage;
  final ApiService _api;

  FollowedUserIdsNotifier({required StorageService storage, required ApiService api})
      : _storage = storage,
        _api = api,
        super(storage.getFollowedUserIds()) {
    // 初始化时尝试从后端同步关注列表
    _syncFromBackend();
  }

  /// 从后端同步关注列表到本地
  Future<void> _syncFromBackend() async {
    try {
      final resp = await _api.getFollowings(page: 1, pageSize: 1000);
      if (resp.isSuccess && resp.data != null) {
        final list = resp.data!['list'] as List<dynamic>? ?? [];
        final ids = list
            .whereType<Map<String, dynamic>>()
            .map((e) => e['following_id'] as String?)
            .whereType<String>()
            .toSet();
        // 更新内存状态
        state = ids;
        // 同步到本地缓存
        await _storage.setSetting('followed_users', ids.toList());
      }
    } catch (_) {
      // 同步失败则使用本地缓存，静默处理
    }
  }

  /// 切换关注状态（先调后端，成功后再更新本地）
  Future<void> toggle(String userId) async {
    final currentlyFollowing = state.contains(userId);
    // 乐观更新 UI
    final optimisticSet = Set<String>.from(state);
    if (currentlyFollowing) {
      optimisticSet.remove(userId);
    } else {
      optimisticSet.add(userId);
    }
    state = optimisticSet;

    try {
      if (currentlyFollowing) {
        final resp = await _api.unfollowUser(userId);
        if (!resp.isSuccess) throw Exception(resp.message);
        await _storage.removeFollowedUser(userId);
      } else {
        final resp = await _api.followUser(userId);
        if (!resp.isSuccess) throw Exception(resp.message);
        await _storage.addFollowedUser(userId);
      }
    } catch (_) {
      // 后端失败，回滚 UI 状态
      state = Set<String>.from(state)
        ..remove(userId)
        ..addAll(currentlyFollowing ? {userId} : {});
      rethrow;
    }
  }
}

/// GPS 信号状态/// GPS 信号状态/// GPS 信号状态
/// GPS 信号状态
final gpsStatusProvider = StateProvider<GpsStatus>((ref) => GpsStatus.searching);

enum GpsStatus {
  searching('搜星中', Icons.gps_not_fixed, false),
  weak('信号弱', Icons.gps_not_fixed, true),
  good('信号良好', Icons.gps_fixed, true),
  lost('信号丢失', Icons.gps_off, true);

  final String label;
  final IconData icon;
  final bool canStart;

  const GpsStatus(this.label, this.icon, this.canStart);
}

/// 关注数量 Provider — 每次刷新 Profile 页面重新加载
final followingCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final resp = await api.getFollowings(page: 1, pageSize: 1);
  if (resp.code == 0 && resp.data != null) {
    final total = resp.data!['total'];
    if (total is int) return total;
    if (total is String) return int.tryParse(total) ?? 0;
  }
  return 0;
});