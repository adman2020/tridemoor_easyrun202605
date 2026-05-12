import '../../core/models/device.dart';
import '../../core/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 设备列表状态
final deviceListProvider = FutureProvider<List<Device>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final resp = await api.getDeviceList();
  if (!resp.isSuccess || resp.data == null) {
    throw Exception(resp.message);
  }
  final list = resp.data!['list'] as List<dynamic>? ?? [];
  return list
      .whereType<Map<String, dynamic>>()
      .map((e) => Device.fromJson(e))
      .toList();
});

/// 设备绑定请求
final deviceBindProvider = FutureProvider.family<Device, Map<String, dynamic>>((ref, data) async {
  final api = ref.watch(apiServiceProvider);
  final resp = await api.bindDevice(data);
  if (!resp.isSuccess || resp.data == null) {
    throw Exception(resp.message);
  }
  return Device.fromJson(resp.data!);
});

/// 设备解绑
final deviceUnbindProvider = FutureProvider.family<void, String>((ref, deviceId) async {
  final api = ref.watch(apiServiceProvider);
  final resp = await api.unbindDevice(deviceId);
  if (!resp.isSuccess) {
    throw Exception(resp.message);
  }
});

/// 设备更新
final deviceUpdateProvider = FutureProvider.family<Device, ({String id, Map<String, dynamic> data})>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final resp = await api.updateDevice(params.id, params.data);
  if (!resp.isSuccess || resp.data == null) {
    throw Exception(resp.message);
  }
  return Device.fromJson(resp.data!);
});

/// 导入历史列表状态
final importHistoryProvider = FutureProvider<List<ImportRecord>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final resp = await api.getImportHistory();
  if (!resp.isSuccess || resp.data == null) {
    throw Exception(resp.message);
  }
  final list = resp.data!['list'] as List<dynamic>? ?? [];
  return list
      .whereType<Map<String, dynamic>>()
      .map((e) => ImportRecord.fromJson(e))
      .toList();
});

/// 设备管理页面刷新控制器
final deviceRefreshProvider = StateProvider<int>((ref) => 0);
