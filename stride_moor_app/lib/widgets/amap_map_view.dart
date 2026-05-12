import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';
import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';

import '../config/theme.dart';
import '../core/services/location_service.dart';

/// Android 高德 API Key
const _androidKey = 'f50e31d4bd4b6cb53cbf2a019d9be9ba';

/// iOS 高德 API Key
const _iosKey = 'ba4ae4ccb77b7e8aa34ff999dae8e53c';

/// 轨迹地图统一封装组件
///
/// 架构说明：
/// - 真机且 SDK 可用时 → 显示高德地图 AMapWidget
/// - 模拟器或 SDK 不可用时 → 显示主题化占位符，UI 流程照常走
///
/// 使用方式：
/// ```dart
/// AmapMapView(
///   polylines: {buildTrackPolyline(points)},
///   markers: myMarkerSet,
/// )
/// ```
class AmapMapView extends StatefulWidget {
  /// 轨迹线集合
  final Set<Polyline> polylines;

  /// 标记点集合
  final Set<Marker> markers;

  /// 是否显示我的位置（小蓝点）
  final bool myLocationEnabled;

  /// 是否跟随我的位置移动
  final bool followMyLocation;

  /// 初始相机位置
  final CameraPosition? initialCameraPosition;

  /// 是否启用拖拽手势
  final bool scrollGesturesEnabled;

  /// 是否启用缩放手势
  final bool zoomGesturesEnabled;

  /// 是否启用旋转手势
  final bool rotateGesturesEnabled;

  /// 是否启用倾斜手势
  final bool tiltGesturesEnabled;

  const AmapMapView({
    super.key,
    this.polylines = const {},
    this.markers = const {},
    this.myLocationEnabled = false,
    this.followMyLocation = false,
    this.initialCameraPosition,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = false,
  });

  @override
  State<AmapMapView> createState() => AmapMapViewState();
}

class AmapMapViewState extends State<AmapMapView> {
  AMapController? _mapController;
  StreamSubscription? _locationSub;
  bool _hasInitialZoom = false;

  @override
  void initState() {
    super.initState();
    if (widget.followMyLocation) {
      _subscribeLocation();
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  /// 订阅 LocationService 定位更新，自动驱动地图镜头跟随
  void _subscribeLocation() {
    // 通过监听 LocationService 来跟踪位置
    final locService = LocationService.instance;
    locService.addListener(_onLocationServiceUpdate);
  }

  void _onLocationServiceUpdate() {
    final loc = LocationService.instance.lastKnownLocation;
    if (loc == null) return;
    final (lat, lng) = loc;
    if (!_hasInitialZoom) {
      _hasInitialZoom = true;
      moveToPosition(LatLng(lat, lng), zoom: 16);
    } else if (widget.followMyLocation) {
      moveToPosition(LatLng(lat, lng), zoom: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 模拟器或 SDK 不可用时显示占位符
    if (!LocationService.sdkAvailable) {
      return const _MapPlaceholder();
    }

    // 真机：显示高德地图
    return AMapWidget(
      apiKey: const AMapApiKey(
        androidKey: _androidKey,
        iosKey: _iosKey,
      ),
      initialCameraPosition: widget.initialCameraPosition ??
          _defaultCameraPosition(),
      polylines: widget.polylines,
      markers: widget.markers,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      tiltGesturesEnabled: widget.tiltGesturesEnabled,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      myLocationStyleOptions: widget.myLocationEnabled
          ? MyLocationStyleOptions(
              true,
              circleStrokeColor: AppColors.primary,
              circleStrokeWidth: 1,
            )
          : null,
      onMapCreated: _onMapCreated,
    );
  }

  /// 地图创建完成回调，获取控制器并设置镜头跟随
  void _onMapCreated(AMapController controller) {
    _mapController = controller;
    _applyFollowMyLocation();
  }

  void _applyFollowMyLocation() {
    if (_mapController == null || !widget.followMyLocation) return;
    // 跟随定位模式：调用 AMap SDK 的 myLocationStyleOptions 自动跟随
    // gmm_amap 插件在 myLocationStyleOptions 配置后会自动显示蓝点
    // 初始镜头通过 initialCameraPosition 设置，持续跟随通过 moveToPosition 对外暴露
  }

  @override
  void didUpdateWidget(covariant AmapMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // followMyLocation 变化时更新
    if (oldWidget.followMyLocation != widget.followMyLocation) {
      _applyFollowMyLocation();
    }
  }

  /// 将镜头移动到指定位置（供外部调用方在定位更新时驱动）
  void moveToPosition(LatLng target, {double zoom = 16}) {
    _mapController?.moveCamera(
      CameraUpdate.newLatLngZoom(target, zoom),
    );
  }

  /// 根据传入数据计算默认视角
  CameraPosition _defaultCameraPosition() {
    if (widget.polylines.isNotEmpty) {
      final points = widget.polylines.first.points;
      if (points.isNotEmpty) {
        return CameraPosition(target: points.first, zoom: 15);
      }
    }
    if (widget.markers.isNotEmpty) {
      return CameraPosition(target: widget.markers.first.position, zoom: 15);
    }
    // 不硬编码默认位置，改为高缩放级别显示通用地图
    // myLocationEnabled=true 时 AMap SDK 会自动定位到用户位置
    return const CameraPosition(
      target: LatLng(35.86, 104.19), // 中国中心
      zoom: 5,
    );
  }
}

/// 根据轨迹点列表生成高德 Polyline
Polyline buildTrackPolyline(
  List<LatLng> points, {
  Color color = AppColors.primary,
  double width = 5,
}) {
  return Polyline(
    points: points,
    color: color,
    width: width,
  );
}

/// 模拟器地图占位符 — 深色/亮色跟随主题
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8F0FE);
    final iconColor = isDark ? Colors.white38 : Colors.blue.shade300;
    final textColor = isDark ? Colors.white54 : Colors.blueGrey.shade400;
    final gridColor =
        isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04);

    return CustomPaint(
      painter: _GridPainter(color: gridColor),
      child: Container(
        color: bgColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 64, color: iconColor),
              const SizedBox(height: 12),
              Text(
                '🗺️ 跑步路线',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '真机显示实际轨迹',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 网格线 painter（模拟地图瓦片纹理）
class _GridPainter extends CustomPainter {
  final Color color;
  static const double spacing = 60.0;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      color != oldDelegate.color;
}
