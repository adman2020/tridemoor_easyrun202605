import 'dart:async';

/// BLE 设备扫描结果
class BleScanResult {
  final String id;
  final String name;
  final String localName;
  final int rssi;
  final String deviceType; // smartwatch / fitness_band / hr_monitor / smart_ring
  final String brand;
  final String typeLabel;

  const BleScanResult({
    required this.id,
    required this.name,
    required this.localName,
    required this.rssi,
    this.deviceType = 'other',
    this.brand = '',
    this.typeLabel = '未知设备',
  });
}

/// BLE 设备连接状态
enum BleDeviceState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// BLE 服务抽象接口
///
/// 提供设备扫描、连接、心率/电量数据流。
/// MockBleService 实现模拟行为，真实接入替换为 flutter_blue_plus 实现。
abstract class BleService {
  /// 扫描结果流
  Stream<BleScanResult> get scanResults;

  /// 设备连接状态流
  Stream<BleDeviceState> get deviceStateStream;

  /// 心率数据流（bpm）
  Stream<int> get heartRateStream;

  /// 电量数据流（%）
  Stream<int> get batteryStream;

  /// 当前是否已连接
  bool get isConnected;

  /// 当前连接的设备名
  String? get connectedDeviceName;

  /// 开始扫描 BLE 设备
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)});

  /// 停止扫描
  Future<void> stopScan();

  /// 连接设备
  Future<bool> connect(String deviceId);

  /// 断开连接
  Future<void> disconnect();

  /// 释放资源
  Future<void> dispose();
}
