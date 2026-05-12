import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'
    show AndroidServiceInstance;
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart'
    show AndroidForegroundType;
import 'package:geolocator/geolocator.dart';
import 'package:gmm_amap_flutter_location/amap_location_option.dart';
import 'package:gmm_amap_flutter_location/gmm_amap_flutter_location.dart';


import '../models/run.dart';
import 'debug_step_logger.dart';

/// 前台服务启动回调（必须是顶层函数，供后台 isolate 调用）
@pragma('vm:entry-point')
void onRunningServiceStart(ServiceInstance service) {
  // Android 平台前台服务需要设置通知
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'StrideMoor 正在记录跑步',
      content: 'GPS 定位追踪中…',
    );
    service.setAsForegroundService();
  }
}

/// GPS 定位服务
///
/// 基于高德定位 SDK (gmm_amap_flutter_location)，负责：
/// - GPS 信号采集与精度过滤
/// - 静态漂移点过滤
/// - 轨迹点插值与平滑（Kalman 滤波）
/// - 距离、配速计算
class LocationService extends ChangeNotifier {
  /// 单例实例（用于地图跟随定位等场景）
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  /// 延迟初始化，避免首次访问时原生 AMap SDK 崩溃
  AMapFlutterLocation? _location;
  StreamSubscription? _locationSubscription;

  final List<RunSample> _rawSamples = [];
  final List<RunSample> _filteredSamples = [];

  /// 私有构造，确保通过 [instance] 获取单例
  LocationService._();

  /// 公开构造（RunSessionNotifier 直接创建用，_location 延迟初始化避免首次 native 崩溃）
  LocationService();

  bool _isTracking = false;
  double _totalDistance = 0.0;
  // Kalman 滤波状态
  double? _lastLat;
  double? _lastLng;
  final double _q = 0.01; // 过程噪声
  final double _r = 1.0;  // 观测噪声
  double _p = 1.0;  // 估计误差
  double _k = 0.0;  // Kalman增益

  bool get isTracking => _isTracking;
  List<RunSample> get samples => List.unmodifiable(_filteredSamples);
  double get totalDistance => _totalDistance;

  /// 最近一次定位坐标（用于地图初始定位）
  (double lat, double lng)? get lastKnownLocation {
    if (_lastLat == null || _lastLng == null) return null;
    return (_lastLat!, _lastLng!);
  }

  /// 主动请求一次 GPS 定位（先试高德SDK，超时后兜底 geolocator）
  Future<(double lat, double lng)?> requestLocation({Duration timeout = const Duration(seconds: 10)}) async {
    // 有缓存则直接返回
    final cached = lastKnownLocation;
    if (cached != null) return cached;

    // 先试高德SDK（如果有的话）
    if (_location != null && _sdkAvailable) {
      try {
        final amapResult = await _requestAmapLocation(timeout);
        if (amapResult != null) return amapResult;
      } catch (e) {
        debugPrint('⚠️ requestLocation: AMap失败: $e');
      }
    }

    // 兜底：geolocator 原生GPS
    debugPrint('📍 requestLocation: 使用 geolocator 原生GPS兜底');
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(timeout);
      if (pos != null) {
        // WGS84 转 GCJ-02（高德坐标系）
        final (lat, lng) = _wgs84ToGcj02(pos.latitude, pos.longitude);
        return (lat, lng);
      }
    } catch (e) {
      debugPrint('⚠️ requestLocation: geolocator 也失败了: $e');
    }

    return null;
  }

  /// 通过高德定位 SDK 请求一次位置
  Future<(double lat, double lng)?> _requestAmapLocation(Duration timeout) async {
    final completer = Completer<(double, double)?>();
    StreamSubscription<Map<String, Object>>? sub;

    try {
      sub = _location!.onLocationChanged().listen((data) {
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        if (lat != null && lng != null) {
          if (!completer.isCompleted) {
            completer.complete((lat, lng));
          }
        }
      });

      _location!.startLocation();

      Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      return await completer.future;
    } finally {
      await sub?.cancel();
    }
  }

  /// 定位SDK是否可用（模拟器或缺少原生库时为false）
  static bool _sdkAvailable = true;
  static bool get sdkAvailable => _sdkAvailable;

  /// 初始化定位 SDK（在 App 启动时调用一次）
  static void initSdk() {
    try {
      AMapFlutterLocation.setApiKey(
        'f50e31d4bd4b6cb53cbf2a019d9be9ba',
        'ba4ae4ccb77b7e8aa34ff999dae8e53c',
      );
      AMapFlutterLocation.updatePrivacyAgree(true);
      AMapFlutterLocation.updatePrivacyShow(true, true);
    } on PlatformException catch (e) {
      _sdkAvailable = false;
      debugPrint('⚠️ 高德定位SDK不可用: ${e.code} - ${e.message}');
    } catch (e) {
      _sdkAvailable = false;
      debugPrint('⚠️ 高德定位SDK初始化失败: $e');
    }
  }

  Timer? _gpsTimeout;

  /// 原生 GPS 定位（通过 geolocator 兜底）
  StreamSubscription<Position>? _nativeGpsSubscription;

  /// 开始定位追踪
  Future<void> startTracking() async {
    if (_isTracking) return;
    _instance = this;

    _isTracking = true;
    _rawSamples.clear();
    _filteredSamples.clear();
    _totalDistance = 0.0;
    _lastLat = null;
    _lastLng = null;

    // 安全冗余：startTracking 时再初始化一次 SDK
    //（main.dart 的首帧回调和这里双重保障）
    initSdk();

    // 初始化 AMap 定位
    await DebugStepLogger.step(41, 'startTracking: init AMap location');
    try {
      _location ??= AMapFlutterLocation();
      final option = AMapLocationOption(
        locationInterval: 1000,
        locationMode: AMapLocationMode.Hight_Accuracy,
      );
      _location!.setLocationOption(option);
      _locationSubscription = _location!.onLocationChanged().listen(_onAmapLocationUpdate);
      _location!.startLocation();
      await DebugStepLogger.step(42, 'AMap startLocation ok');

      // GPS 超时保护：10 秒无定位数据则切到原生 GPS
      _gpsTimeout?.cancel();
      _gpsTimeout = Timer(const Duration(seconds: 10), () {
        if (!_isTracking) return;
        debugPrint('⚠️ GPS 超时 10 秒无数据，切换到 geolocator 原生 GPS');
        _location?.stopLocation();
        _locationSubscription?.cancel();
        _startNativeGps();
      });
    } catch (e) {
      debugPrint('⚠️ AMap 启动异常，切换到 geolocator 原生 GPS: $e');
      await DebugStepLogger.step(42, 'AMap failed, fallback native gps: $e');
      _startNativeGps();
    }

    // 启动前台服务（常驻通知，防止熄屏后进程被杀死）
    await DebugStepLogger.step(44, 'foreground service before');
    await _startForegroundService();
    await DebugStepLogger.step(45, 'foreground service after');

    notifyListeners();
  }

  /// 原生 GPS 定位（geolocator 兜底，兼容 HarmonyOS）
  void _startNativeGps() {
    debugPrint('📍 启动 geolocator 原生 GPS 定位');
    _nativeGpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      if (!_isTracking) return;
      _onPositionUpdate(pos);
    });

    // 立刻获取一次当前位置
    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).then((pos) {
      if (_isTracking) _onPositionUpdate(pos);
    }).catchError((e) {
      debugPrint('⚠️ geolocator 首次定位失败: $e');
    });
  }

  /// 处理 geolocator 定位更新
  void _onPositionUpdate(Position pos) {
    // 取消 AMap 超时定时器
    _gpsTimeout?.cancel();
    _gpsTimeout = null;

    // WGS84 转 GCJ-02（高德地图坐标系）
    final (double lat, double lng) = _wgs84ToGcj02(pos.latitude, pos.longitude);
    final accuracy = pos.accuracy;

    // 精度过滤：精度 > 100 米视为不可信
    if (accuracy > 100) return;

    if (_lastLat == null || _lastLng == null) {
      // 第一个有效坐标
      _filteredSamples.add(RunSample(
        timestamp: DateTime.now(), latitude: lat, longitude: lng, altitude: pos.altitude,
      ));
      _lastLat = lat;
      _lastLng = lng;
      _totalDistance = 0.0;
    } else {
      _totalDistance += _haversineDistance(_lastLat!, _lastLng!, lat, lng);
      _lastLat = lat;
      _lastLng = lng;
      _filteredSamples.add(RunSample(
        timestamp: DateTime.now(),
        latitude: lat,
        longitude: lng,
        altitude: pos.altitude,
      ).copyWith(distanceFromStart: _totalDistance));
    }
    notifyListeners();
  }

  /// WGS84 �D GCJ-02 ���꣨������ͼ���꣩
  static const double _a = 6378245.0;
  static const double _ee = 0.00669342162296594323;

  static (double, double) _wgs84ToGcj02(double wgsLat, double wgsLng) {
    if (_outOfChina(wgsLat, wgsLng)) return (wgsLat, wgsLng);
    double dLat = _transformLat(wgsLng - 105.0, wgsLat - 35.0);
    double dLng = _transformLng(wgsLng - 105.0, wgsLat - 35.0);
    double radLat = wgsLat / 180.0 * 3.141592653589793;
    double magic = (1 - _ee * sin(radLat) * sin(radLat)).clamp(0.0, 1.0);
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * 3.141592653589793);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * 3.141592653589793);
    return (wgsLat + dLat, wgsLng + dLng);
  }

  static bool _outOfChina(double lat, double lng) {
    return lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271;
  }

  static double _transformLat(double x, double y) {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * 3.141592653589793) + 20.0 * sin(2.0 * x * 3.141592653589793)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * 3.141592653589793) + 40.0 * sin(y / 3.0 * 3.141592653589793)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * 3.141592653589793) + 320.0 * sin(y * 3.141592653589793 / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double _transformLng(double x, double y) {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * 3.141592653589793) + 20.0 * sin(2.0 * x * 3.141592653589793)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * 3.141592653589793) + 40.0 * sin(x / 3.0 * 3.141592653589793)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * 3.141592653589793) + 300.0 * sin(x / 30.0 * 3.141592653589793)) * 2.0 / 3.0;
    return ret;
  }

  /// 模拟 GPS 数据（旧兜底，保留仅防原生也失败）
  void _startFallbackGps() {
    debugPrint('📍 启动模拟 GPS 定位');
    const double mockLat = 22.5431;
    const double mockLng = 114.0579;

    // 初始点
    final now = DateTime.now();
    _filteredSamples.add(RunSample(
      timestamp: now, latitude: mockLat, longitude: mockLng, altitude: 0,
    ));
    _lastLat = mockLat;
    _lastLng = mockLng;
    _totalDistance = 0.0;

    // 每秒产生 0.5~2 米的随机位移
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isTracking) return;
      final dLat = (Random().nextDouble() - 0.5) * 0.00002;
      final dLng = (Random().nextDouble() - 0.5) * 0.00002;
      _lastLat = _lastLat! + dLat;
      _lastLng = _lastLng! + dLng;
      final newSample = RunSample(
        timestamp: DateTime.now(), latitude: _lastLat!, longitude: _lastLng!, altitude: 0,
      );
      _totalDistance += _haversineDistance(
        _lastLat! - dLat, _lastLng! - dLng, _lastLat!, _lastLng!,
      );
      _filteredSamples.add(newSample.copyWith(distanceFromStart: _totalDistance));
      notifyListeners();
    });
  }

  Timer? _fallbackTimer;

  /// 停止追踪
  Future<void> stopTracking() async {
    _isTracking = false;
    _gpsTimeout?.cancel();
    _gpsTimeout = null;
    _nativeGpsSubscription?.cancel();
    _nativeGpsSubscription = null;
    // 停止模拟 GPS
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    // 停止 AMap 定位
    try {
      _location?.stopLocation();
    } catch (e) {
      debugPrint('⚠️ stopLocation 异常: $e');
    }
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    // 停止前台服务
    try {
      await _stopForegroundService();
    } catch (e) {
      debugPrint('⚠️ 停止前台服务异常: $e');
    }
    notifyListeners();
  }

  /// 处理高德定位回调
  void _onAmapLocationUpdate(Map<String, Object> result) {
    // 收到首次定位数据时取消 GPS 超时定时器
    _gpsTimeout?.cancel();
    _gpsTimeout = null;

    if (!_isTracking) return;

    final lat = result['latitude'] as double?;
    final lng = result['longitude'] as double?;
    final accuracy = result['accuracy'] as double?;
    final altitude = result['altitude'] as double?;

    if (lat == null || lng == null) return;

    final data = LocationData(
      latitude: lat,
      longitude: lng,
      altitude: altitude,
      accuracy: accuracy,
      speed: result['speed'] as double?,
      heading: result['heading'] as double?,
      timestamp: DateTime.now(),
    );

    _onLocationUpdate(data);
  }

  /// 处理定位更新（精度过滤 → 静态点过滤 → Kalman 滤波 → 距离计算）
  void _onLocationUpdate(LocationData data) {
    if (!_isTracking) return;

    // 精度过滤：首点放宽到 50m，后续点严到 30m
    final threshold = _filteredSamples.isEmpty ? 50.0 : 30.0;
    if (data.accuracy != null && data.accuracy! > threshold) {
      return; // 精度太差，丢弃
    }

    final sample = RunSample(
      timestamp: data.timestamp ?? DateTime.now(),
      latitude: data.latitude!,
      longitude: data.longitude!,
      altitude: data.altitude,
    );

    _rawSamples.add(sample);

    // 静态点过滤：速度 < 0.5 m/s 且不在移动状态
    if (_filteredSamples.isNotEmpty) {
      final last = _filteredSamples.last;
      final dist = _haversineDistance(
        last.latitude, last.longitude,
        sample.latitude, sample.longitude,
      );
      final timeDiff = sample.timestamp.difference(last.timestamp).inMilliseconds / 1000.0;
      if (timeDiff > 0) {
        final speed = dist / timeDiff;
        if (speed < 0.5 && dist < 3.0) {
          // 可能是静态漂移，跳过
          return;
        }
      }
    }

    // Kalman 滤波平滑
    final smoothed = _kalmanFilter(sample);

    // 计算距离
    if (_filteredSamples.isNotEmpty) {
      final last = _filteredSamples.last;
      final segmentDist = _haversineDistance(
        last.latitude, last.longitude,
        smoothed.latitude, smoothed.longitude,
      );
      _totalDistance += segmentDist;
    }

    final enrichedSample = smoothed.copyWith(
      distanceFromStart: _totalDistance,
    );

    _filteredSamples.add(enrichedSample);
    notifyListeners();
  }

  /// Kalman 滤波（简化版，分别对 lat/lng 滤波）
  RunSample _kalmanFilter(RunSample sample) {
    if (_lastLat == null || _lastLng == null) {
      _lastLat = sample.latitude;
      _lastLng = sample.longitude;
      return sample;
    }

    // 对纬度滤波
    _p = _p + _q;
    _k = _p / (_p + _r);
    _lastLat = _lastLat! + _k * (sample.latitude - _lastLat!);
    _p = (1 - _k) * _p;

    // 对经度滤波
    _p = _p + _q;
    _k = _p / (_p + _r);
    _lastLng = _lastLng! + _k * (sample.longitude - _lastLng!);
    _p = (1 - _k) * _p;

    return sample.copyWith(
      latitude: _lastLat!,
      longitude: _lastLng!,
    );
  }

  /// Haversine 公式计算两点距离（米）
  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // 米
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180.0;

  /// 启动前台服务（常驻通知 + 后台保活）
  Future<void> _startForegroundService() async {
    try {
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onRunningServiceStart,
          initialNotificationTitle: 'StrideMoor 正在记录跑步',
          initialNotificationContent: 'GPS 定位追踪中…',
          foregroundServiceNotificationId: 888,
          autoStart: true,
          isForegroundMode: true,
          autoStartOnBoot: false,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
        ),
      );
      await service.startService();
      debugPrint('📱 前台服务已启动（常驻通知）');
    } catch (e) {
      debugPrint('⚠️ 前台服务启动失败（不影响跑步追踪）: $e');
    }
  }

  /// 停止前台服务
  Future<void> _stopForegroundService() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke('setForegroundMode', {'value': false});
      debugPrint('📱 前台服务已停止');
    } catch (e) {
      debugPrint('⚠️ 停止前台服务失败: $e');
    }
  }

  @override
  void dispose() {
    _gpsTimeout?.cancel();
    _gpsTimeout = null;
    _nativeGpsSubscription?.cancel();
    _nativeGpsSubscription = null;
    _fallbackTimer?.cancel();
    _location?.destroy();
    stopTracking();
    super.dispose();
  }
}

/// 定位数据包装（适配不同SDK）
class LocationData {
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime? timestamp;

  const LocationData({
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.timestamp,
  });
}
