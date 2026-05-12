import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'ble_service.dart';

/// 预设的模拟设备列表
final List<MockDevicePreset> _mockPresets = [
  MockDevicePreset(
    id: 'mock:watch:huawei_gt4',
    name: 'HUAWEI GT 4',
    localName: 'HUAWEI Watch GT 4',
    deviceType: 'smartwatch',
    brand: 'Huawei',
    rssiBase: -55,
    typeLabel: '智能手表',
    baseHeartRate: 72,
    baseBattery: 78,
  ),
  MockDevicePreset(
    id: 'mock:watch:apple_ultra',
    name: 'Apple Watch Ultra 2',
    localName: "Apple Watch Ultra 2",
    deviceType: 'smartwatch',
    brand: 'Apple',
    rssiBase: -62,
    typeLabel: '智能手表',
    baseHeartRate: 68,
    baseBattery: 65,
  ),
  MockDevicePreset(
    id: 'mock:band:mi_band9',
    name: 'XiaoMi Band 9',
    localName: 'Mi Smart Band 9',
    deviceType: 'fitness_band',
    brand: 'Xiaomi',
    rssiBase: -70,
    typeLabel: '手环',
    baseHeartRate: 75,
    baseBattery: 90,
  ),
  MockDevicePreset(
    id: 'mock:band:huawei_band',
    name: 'HUAWEI Band 9',
    localName: 'HUAWEI Band 9',
    deviceType: 'fitness_band',
    brand: 'Huawei',
    rssiBase: -58,
    typeLabel: '手环',
    baseHeartRate: 74,
    baseBattery: 82,
  ),
  MockDevicePreset(
    id: 'mock:hr:polar_h10',
    name: 'Polar H10',
    localName: 'Polar H10',
    deviceType: 'hr_monitor',
    brand: 'Polar',
    rssiBase: -45,
    typeLabel: '心率带',
    baseHeartRate: 70,
    baseBattery: 95,
  ),
  MockDevicePreset(
    id: 'mock:watch:garmin_255',
    name: 'Garmin FR 255',
    localName: 'Forerunner 255',
    deviceType: 'smartwatch',
    brand: 'Garmin',
    rssiBase: -66,
    typeLabel: '智能手表',
    baseHeartRate: 71,
    baseBattery: 60,
  ),
  MockDevicePreset(
    id: 'mock:ring:oura_4',
    name: 'Oura Ring 4',
    localName: 'Oura Ring 4',
    deviceType: 'smart_ring',
    brand: 'Oura',
    rssiBase: -80,
    typeLabel: '智能戒指',
    baseHeartRate: 69,
    baseBattery: 50,
  ),
];

/// 模拟 BLE 设备预设参数
class MockDevicePreset {
  final String id;
  final String name;
  final String localName;
  final String deviceType;
  final String brand;
  final int rssiBase;
  final String typeLabel;
  final int baseHeartRate;
  final int baseBattery;

  const MockDevicePreset({
    required this.id,
    required this.name,
    required this.localName,
    required this.deviceType,
    required this.brand,
    required this.rssiBase,
    required this.typeLabel,
    required this.baseHeartRate,
    required this.baseBattery,
  });
}

/// 模拟 BLE 蓝牙设备服务
///
/// 模拟真实 BLE 设备扫描、连接、数据推送流程。
/// - 扫描：延迟 1-2 秒后逐步发现设备
/// - RSSI 随机抖动模拟真实信号波动
/// - 连接：延迟 1-3 秒后成功
/// - 心率：连接后每 2 秒推送一次随机心率值
/// - 电量：每 30 秒随机变化 ±1%
class MockBleService implements BleService {
  final Random _random = Random();
  bool _isScanning = false;
  bool _connected = false;
  String? _connectedDeviceId;
  MockDevicePreset? _connectedPreset;

  // Stream controllers
  final _scanResultsController = StreamController<BleScanResult>.broadcast();
  final _deviceStateController = StreamController<BleDeviceState>.broadcast();
  final _heartRateController = StreamController<int>.broadcast();
  final _batteryController = StreamController<int>.broadcast();

  // Timers
  Timer? _scanTimer;
  Timer? _heartRateTimer;
  Timer? _batteryTimer;

  int _currentBattery = 80;
  int _currentHeartRate = 72;

  @override
  Stream<BleScanResult> get scanResults => _scanResultsController.stream;

  @override
  Stream<BleDeviceState> get deviceStateStream => _deviceStateController.stream;

  @override
  Stream<int> get heartRateStream => _heartRateController.stream;

  @override
  Stream<int> get batteryStream => _batteryController.stream;

  @override
  bool get isConnected => _connected;

  @override
  String? get connectedDeviceName => _connectedPreset?.name;

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) return;
    _isScanning = true;
    _deviceStateController.add(BleDeviceState.scanning);
    debugPrint('[MockBLE] 开始扫描...');

    // 逐个设备模拟扫描发现（延迟不同，模拟真实发现顺序）
    for (int i = 0; i < _mockPresets.length; i++) {
      await Future.delayed(Duration(milliseconds: 400 + _random.nextInt(800)));
      if (!_isScanning) break; // 扫描被停止

      final preset = _mockPresets[i];
      // RSSI 随机抖动 ±5
      final rssi = preset.rssiBase + _random.nextInt(11) - 5;

      _scanResultsController.add(BleScanResult(
        id: preset.id,
        name: preset.name,
        localName: preset.localName,
        rssi: rssi,
        deviceType: preset.deviceType,
        brand: preset.brand,
        typeLabel: preset.typeLabel,
      ));
      debugPrint('[MockBLE] 发现设备: ${preset.name} (${rssi}dBm)');
    }

    debugPrint('[MockBLE] 扫描完成，共 ${_mockPresets.length} 个设备');
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
    _scanTimer?.cancel();
    _scanTimer = null;
    debugPrint('[MockBLE] 停止扫描');
  }

  @override
  Future<bool> connect(String deviceId) async {
    // 查找预设
    final preset = _mockPresets.cast<MockDevicePreset?>().firstWhere(
      (p) => p!.id == deviceId,
      orElse: () => null,
    );
    if (preset == null) {
      debugPrint('[MockBLE] 未知设备: $deviceId');
      _deviceStateController.add(BleDeviceState.error);
      return false;
    }

    _deviceStateController.add(BleDeviceState.connecting);
    debugPrint('[MockBLE] 正在连接 ${preset.name}...');

    // 模拟连接过程 1-3 秒
    await Future.delayed(Duration(seconds: 1 + _random.nextInt(3)));

    // 80% 概率成功
    if (_random.nextDouble() < 0.8) {
      _connected = true;
      _connectedDeviceId = deviceId;
      _connectedPreset = preset;
      _currentHeartRate = preset.baseHeartRate;
      _currentBattery = preset.baseBattery;

      _deviceStateController.add(BleDeviceState.connected);
      _heartRateController.add(_currentHeartRate);
      _batteryController.add(_currentBattery);
      debugPrint('[MockBLE] ${preset.name} 连接成功!');

      // 启动心率模拟
      _startHeartRateSimulation();
      // 启动电量模拟
      _startBatterySimulation();
      return true;
    } else {
      _deviceStateController.add(BleDeviceState.error);
      debugPrint('[MockBLE] ${preset.name} 连接失败 (模拟)');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _connectedDeviceId = null;
    _connectedPreset = null;
    _heartRateTimer?.cancel();
    _heartRateTimer = null;
    _batteryTimer?.cancel();
    _batteryTimer = null;
    _deviceStateController.add(BleDeviceState.disconnected);
    debugPrint('[MockBLE] 已断开连接');
  }

  /// 模拟心率数据（每 2 秒变化一次）
  void _startHeartRateSimulation() {
    _heartRateTimer?.cancel();
    _heartRateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_connected) return;
      // 心率在基础值周围 ±8 跳动，偶尔跳变模拟运动变化
      final delta = _random.nextInt(17) - 8;
      _currentHeartRate = (_currentHeartRate + delta).clamp(55, 200);
      _heartRateController.add(_currentHeartRate);
    });
  }

  /// 模拟电量变化（每 30 秒变化 ±1%）
  void _startBatterySimulation() {
    _batteryTimer?.cancel();
    _batteryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_connected) return;
      final delta = _random.nextInt(3) - 1; // -1, 0, +1
      _currentBattery = (_currentBattery + delta).clamp(0, 100);
      _batteryController.add(_currentBattery);
    });
  }

  @override
  Future<void> dispose() async {
    _scanTimer?.cancel();
    _heartRateTimer?.cancel();
    _batteryTimer?.cancel();
    _isScanning = false;
    _connected = false;
    _connectedPreset = null;
    await _scanResultsController.close();
    await _deviceStateController.close();
    await _heartRateController.close();
    await _batteryController.close();
  }
}
