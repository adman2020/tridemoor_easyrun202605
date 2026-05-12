import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';

/// 设备类型枚举（避免与 ScreenUtil 的 DeviceType 冲突）
class DeviceCategory {
  static const smartwatch = 'smartwatch';
  static const fitnessBand = 'fitness_band';
  static const hrMonitor = 'hr_monitor';
  static const smartRing = 'smart_ring';
  static const other = 'other';

  static String label(String type) {
    switch (type) {
      case smartwatch:
        return '智能手表';
      case fitnessBand:
        return '手环';
      case hrMonitor:
        return '心率带';
      case smartRing:
        return '智能戒指';
      default:
        return '其他';
    }
  }
}

/// 连接方式枚举
class ConnType {
  static const ble = 'ble';
  static const appleHealth = 'apple_health';
  static const huaweiHealth = 'huawei_health';
  static const garmin = 'garmin';
  static const healthConnect = 'health_connect';

  static String label(String type) {
    switch (type) {
      case ble:
        return '蓝牙';
      case appleHealth:
        return 'Apple Health';
      case huaweiHealth:
        return '华为运动健康';
      case garmin:
        return 'Garmin Connect';
      case healthConnect:
        return 'Health Connect';
      default:
        return type;
    }
  }
}

/// 用户绑定的可穿戴设备
@freezed
class Device with _$Device {
  const factory Device({
    required String id,
    required String name,
    required String deviceType,
    required String brand,
    @Default('') String model,
    required String connType,
    @Default('') String macAddr,
    @Default(true) bool isConnected,
    int? battery,
    DateTime? lastSyncAt,
    required DateTime createdAt,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      deviceType: json['device_type'] as String? ?? 'other',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      connType: json['conn_type'] as String? ?? 'ble',
      macAddr: json['mac_addr'] as String? ?? '',
      isConnected: json['is_connected'] as bool? ?? false,
      battery: json['battery'] as int?,
      lastSyncAt: json['last_sync_at'] != null ? DateTime.parse(json['last_sync_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 导入记录
@freezed
class ImportRecord with _$ImportRecord {
  const factory ImportRecord({
    required String id,
    required String source,
    required String sourceId,
    required String runId,
    String? deviceId,
    required DateTime importedAt,
  }) = _ImportRecord;

  factory ImportRecord.fromJson(Map<String, dynamic> json) {
    return ImportRecord(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      sourceId: json['source_id'] as String? ?? '',
      runId: json['run_id'] as String? ?? '',
      deviceId: json['device_id'] as String?,
      importedAt: DateTime.parse(json['imported_at'] as String),
    );
  }
}

/// 路线匹配结果（跑步完成后自动匹配）
class RouteMatchResult {
  final String routeId;
  final double overlap;
  final int matched;
  final int total;
  final String? routeName;

  const RouteMatchResult({
    required this.routeId,
    required this.overlap,
    required this.matched,
    required this.total,
    this.routeName,
  });

  factory RouteMatchResult.fromJson(Map<String, dynamic> json) {
    return RouteMatchResult(
      routeId: json['route_id'] as String,
      overlap: (json['overlap'] as num).toDouble(),
      matched: json['matched'] as int,
      total: json['total'] as int,
      routeName: json['route_name'] as String?,
    );
  }
}
