import 'package:hive_flutter/hive_flutter.dart';

import '../../config/constants.dart';

/// 本地存储服务封装
class StorageService {
  Box? _settingsBox;
  Box? _routesBox;
  Box? _runsBox;

  Future<void> init() async {
    _settingsBox = await Hive.openBox(AppConstants.hiveSettingsBox);
    _routesBox = await Hive.openBox(AppConstants.hiveRoutesBox);
    _runsBox = await Hive.openBox(AppConstants.hiveRunsBox);
  }

  // ===== Settings =====

  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
  }

  // ===== Routes Cache =====

  Future<void> cacheRoute(String routeId, Map<String, dynamic> data) async {
    await _routesBox?.put(routeId, data);
  }

  Map<String, dynamic>? getCachedRoute(String routeId) {
    return _routesBox?.get(routeId) as Map<String, dynamic>?;
  }

  Future<void> deleteCachedRoute(String routeId) async {
    await _routesBox?.delete(routeId);
  }

  // ===== Runs Cache =====

  Future<void> cacheRun(String runId, Map<String, dynamic> data) async {
    await _runsBox?.put(runId, data);
  }

  Map<String, dynamic>? getCachedRun(String runId) {
    return _runsBox?.get(runId) as Map<String, dynamic>?;
  }

  List<Map<String, dynamic>> getAllCachedRuns() {
    final values = _runsBox?.values;
    if (values == null) return [];
    return values.cast<Map<String, dynamic>>().toList();
  }

  Future<void> deleteCachedRun(String runId) async {
    await _runsBox?.delete(runId);
  }

  // ===== Token =====

  Future<void> setAccessToken(String token) async {
    await setSetting('access_token', token);
  }

  String? getAccessToken() {
    return getSetting<String>('access_token');
  }

  Future<void> setRefreshToken(String token) async {
    await setSetting('refresh_token', token);
  }

  String? getRefreshToken() {
    return getSetting<String>('refresh_token');
  }

  Future<void> clearTokens() async {
    await _settingsBox?.delete('access_token');
    await _settingsBox?.delete('refresh_token');
  }

  // ===== 开发模式用户缓存 =====

  Future<void> setNickname(String nickname) async {
    await setSetting('dev_nickname', nickname);
  }

  String? getNickname() {
    return getSetting<String>('dev_nickname');
  }

  // ===== 关注列表 =====

  Set<String> getFollowedUserIds() {
    final list = getSetting<List<dynamic>>('followed_users');
    if (list == null) return {};
    return list.whereType<String>().toSet();
  }

  Future<void> addFollowedUser(String userId) async {
    final current = getFollowedUserIds();
    current.add(userId);
    await setSetting('followed_users', current.toList());
  }

  Future<void> removeFollowedUser(String userId) async {
    final current = getFollowedUserIds();
    current.remove(userId);
    await setSetting('followed_users', current.toList());
  }

  // ===== 播报设置 =====

  int getBroadcastInterval() {
    return getSetting<int>('broadcast_interval', defaultValue: 1000) ?? 1000;
  }

  Future<void> setBroadcastInterval(int meters) async {
    await setSetting('broadcast_interval', meters);
  }

  List<String> getBroadcastItems() {
    return getSetting<List<String>>('broadcast_items')?.cast<String>() ??
        AppConstants.defaultBroadcastItems;
  }

  Future<void> setBroadcastItems(List<String> items) async {
    await setSetting('broadcast_items', items);
  }

  String getVoiceStyle() {
    return getSetting<String>('voice_style', defaultValue: 'standard') ?? 'standard';
  }

  Future<void> setVoiceStyle(String style) async {
    await setSetting('voice_style', style);
  }

  // ===== 头像 URL 持久化 =====

  /// 覆盖安装后 cache 文件丢失时，从 Hive 快速恢复头像
  Future<void> setCachedAvatarUrl(String url) async {
    await setSetting('cached_avatar_url', url);
  }

  String? getCachedAvatarUrl() {
    return getSetting<String>('cached_avatar_url');
  }

  // ===== 清空 =====

  Future<void> clearAll() async {
    await _settingsBox?.clear();
    await _routesBox?.clear();
    await _runsBox?.clear();
  }
}
