import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/route.dart' as app_route;
import '../../core/providers/route_provider.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/amap_map_view.dart';
import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';
import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';

/// 跑迹首页 —— Tab 结构：我的跑迹 / 跑友跑迹 / 上传管理 / 我的热度
class RoutesHomePage extends ConsumerStatefulWidget {
  const RoutesHomePage({super.key});

  @override
  ConsumerState<RoutesHomePage> createState() => _RoutesHomePageState();
}

class _RoutesHomePageState extends ConsumerState<RoutesHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.routeRoutes, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF8533),
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: const Color(0xFFFF8533),
          unselectedLabelColor: Colors.white38,
          labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: l10n.routesTabMy),
            Tab(text: l10n.routesTabFriends),
            Tab(text: l10n.routesTabUpload),
            Tab(text: '我的热度'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyRoutesTab(),
          _FriendsRoutesTab(),
          _UploadManageTab(),
          const _StatsDashboardTab(),
        ],
      ),
    );
  }
}

// ==================== 轨迹数据转换 ====================

/// 将 [{lat, lng}] 转为 AMap LatLng
List<LatLng> _toLatLngList(List<Map<String, double>> geometry) {
  return geometry.map((p) => LatLng(p['lat'] ?? 0, p['lng'] ?? 0)).toList();
}

/// 根据轨迹点计算初始相机位置（居中 + 自适应缩放）
CameraPosition _buildCameraPosition(List<Map<String, double>> geometry) {
  if (geometry.isEmpty) {
    return const CameraPosition(target: LatLng(35.86, 104.19), zoom: 5);
  }
  double minLat = geometry[0]['lat'] ?? 0;
  double maxLat = geometry[0]['lat'] ?? 0;
  double minLng = geometry[0]['lng'] ?? 0;
  double maxLng = geometry[0]['lng'] ?? 0;
  for (final p in geometry) {
    final lat = p['lat'] ?? 0;
    final lng = p['lng'] ?? 0;
    minLat = minLat < lat ? minLat : lat;
    maxLat = maxLat > lat ? maxLat : lat;
    minLng = minLng < lng ? minLng : lng;
    maxLng = maxLng > lng ? maxLng : lng;
  }
  final centerLat = (minLat + maxLat) / 2;
  final centerLng = (minLng + maxLng) / 2;

  // 粗略估算缩放级别
  final latDiff = maxLat - minLat;
  final lngDiff = maxLng - minLng;
  final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
  int zoom = 13;
  if (maxDiff < 0.005) zoom = 16;
  else if (maxDiff < 0.01) zoom = 15;
  else if (maxDiff < 0.02) zoom = 14;

  return CameraPosition(target: LatLng(centerLat, centerLng), zoom: zoom.toDouble());
}

// ==================== 统一路线卡片 ====================

class RouteCard extends StatelessWidget {
  final String name;
  final String? creatorLabel;
  final double distance;
  final int pace;
  final int totalTime;
  final int cadence;
  final double strideLength;
  final double elevationGain;
  final int? calories;
  final int? heartRate;
  final List<Map<String, double>> geometry;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  const RouteCard({
    super.key,
    required this.name,
    this.creatorLabel,
    required this.distance,
    required this.pace,
    this.totalTime = 0,
    required this.cadence,
    required this.strideLength,
    required this.elevationGain,
    this.calories,
    this.heartRate,
    this.geometry = const [],
    required this.onTap,
    required this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行 + 取消收藏按钮
              Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8533).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(Icons.map, color: Color(0xFFFF8533), size: 18),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600)),
                        if (creatorLabel != null) ...[
                          SizedBox(height: 2.h),
                          Text(creatorLabel!, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                        ],
                      ],
                    ),
                  ),
                  // 取消收藏 X 按钮
                  InkWell(
                    onTap: onUnfavorite,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.close, color: Colors.white38, size: 16.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // 迷你轨迹地图（AMap 高德地图）
              Container(
                height: 140.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: AmapMapView(
                  polylines: geometry.isEmpty ? <Polyline>{} : {
                    buildTrackPolyline(_toLatLngList(geometry)),
                  },
                  initialCameraPosition: _buildCameraPosition(geometry),
                ),
              ),
              SizedBox(height: 12.h),
              // 数据行
              _buildDataRow(l10n),
              SizedBox(height: 12.h),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // 第一行：距离 配速 用时
          Row(
            children: [
              Expanded(child: _dataItem('${(distance / 1000).toStringAsFixed(1)}', l10n.unitKm, Colors.white)),
              _dataDivider(),
              Expanded(child: _dataItem(_formatPace(pace), '/km', Colors.white)),
              _dataDivider(),
              Expanded(child: _dataItem(_formatDuration(totalTime), '用时', Colors.white)),
            ],
          ),
          SizedBox(height: 8.h),
          // 第二行：步频 步幅 心率
          Row(
            children: [
              Expanded(child: _dataItem('$cadence', l10n.spm, Colors.white70)),
              _dataDivider(),
              Expanded(child: _dataItem('${strideLength.toStringAsFixed(2)}', 'm', Colors.white70)),
              _dataDivider(),
              Expanded(child: _dataItem('$heartRate', l10n.bpm, Colors.white70)),
            ],
          ),
          // 第三行：爬升 & 卡路里（有数据才显示）
          if (elevationGain > 0 || (calories != null && calories! > 0)) SizedBox(height: 8.h),
          if (elevationGain > 0 || (calories != null && calories! > 0))
            Row(
              children: [
                Expanded(child: _dataItem('${elevationGain.toStringAsFixed(0)}', 'm ⛰', Colors.white70)),
                if (calories != null && calories! > 0) ...[
                  _dataDivider(),
                  Expanded(child: _dataItem('$calories', l10n.kcal, Colors.white70)),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _dataItem(String value, String unit, Color valueColor) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: TextStyle(color: valueColor, fontSize: 15.sp, fontWeight: FontWeight.w700)),
              TextSpan(text: ' $unit', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dataDivider() {
    return Container(width: 1.h, height: 20.h, color: Colors.white10);
  }

  String _formatPace(int paceSecondsPerKm) {
    if (paceSecondsPerKm <= 0) return '--';
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }
  String _formatDuration(int seconds) {
    if (seconds <= 0) return '--';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h${m}m';
    }
    return '${m}min';
  }
}

// ==================== Tab 1: 我的跑迹 ====================

class _MyRoutesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final routesAsync = ref.watch(myRoutesProvider);

    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF8533))),
      error: (e, _) => _buildMyRoutesFallback(ref, l10n),
      data: (routes) {
        if (routes.isEmpty) {
          return _buildEmpty(
            icon: Icons.folder_open_outlined,
            title: '暂无跑迹',
            subtitle: '从运动记录中收藏路线\n或上传跑迹后即可在这里查看',
            action: '从运动记录收藏',
            onAction: () => context.push('/history'),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index];
            return RouteCard(
              name: route.name,
              creatorLabel: l10n.myRoute,
              distance: route.distance,
              pace: route.avgPace ?? 0,
              totalTime: route.totalTime ?? 0,
              cadence: route.avgCadence ?? 0,
              strideLength: route.avgStride ?? 0.0,
              elevationGain: route.elevationGain,
              calories: route.calories,
              heartRate: route.avgHeartRate,
              geometry: route.geometry,
              onTap: () => _showRouteDetailSheet(context, route, l10n),
              onUnfavorite: () async {
                final api = ref.read(apiServiceProvider);
                try {
                  await api.deleteRoute(route.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已删除'), behavior: SnackBarBehavior.floating),
                    );
                  }
                  ref.invalidate(myRoutesProvider);
                } catch (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('删除失败: $err'), behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  /// API 加载失败时的回退：尝试使用种子数据（防止白屏）
  Widget _buildMyRoutesFallback(WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(36.r),
              ),
              child: const Icon(Icons.cloud_off, color: Color(0xFFFF3B30), size: 32),
            ),
            SizedBox(height: 16.h),
            Text('无法连接服务器', style: TextStyle(color: Colors.white54, fontSize: 15.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            Text('下拉刷新重试', style: TextStyle(color: Colors.white30, fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }
}

// ==================== Tab 2: 跑友跑迹 ====================

class _FriendsRoutesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final routesAsync = ref.watch(friendsRoutesProvider);

    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF8533))),
      error: (e, _) => _buildFriendsRoutesFallback(ref, l10n),
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return _buildEmpty(
            icon: Icons.people_outline,
            title: '暂无跑友跑迹',
            subtitle: '在跑友动态或排行榜上\n收藏跑友的具体跑步记录即可查看',
            action: '去发现',
            onAction: () => context.push('/discover'),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bm = bookmarks[index];
            final bmId = bm['id'] as String? ?? '';
            final run = bm['run'] as Map<String, dynamic>? ?? {};
            final runUser = run['user'] as Map<String, dynamic>? ?? {};
            final runRoute = run['route'] as Map<String, dynamic>?;

            final nickname = runUser['nickname'] as String? ?? '跑友';
            final avatar = runUser['avatar'] as String?;
            final routeName = runRoute?['name'] as String? ?? '未知路线';
            final distance = (run['total_distance'] as num?)?.toDouble() ?? 0.0;
            final totalTime = (run['total_time'] as num?)?.toInt() ?? 0;
            final avgPace = (run['avg_pace'] as num?)?.toInt() ?? 0;
            final cadence = (run['avg_cadence'] as num?)?.toInt() ?? 0;
            final strideLength = (run['avg_stride_length'] as num?)?.toDouble() ?? 0.0;
            final heartRate = (run['avg_heart_rate'] as num?)?.toInt() ?? 0;

            final runId = bm['run_id'] as String? ?? '';

            // 从路线坐标点解析轨迹（RoutePoint: latitude, longitude, point_index）
            final routePoints = runRoute?['points'] as List<dynamic>?;
            final geometry = (routePoints?.map((p) {
              final m = p as Map<String, dynamic>;
              return (idx: (m['point_index'] as num?)?.toInt() ?? 0,
                  lat: (m['latitude'] as num?)?.toDouble() ?? 0.0,
                  lng: (m['longitude'] as num?)?.toDouble() ?? 0.0);
            }).toList()
              ?..sort((a, b) => a.idx.compareTo(b.idx)))
              ?.map((p) => <String, double>{'lat': p.lat, 'lng': p.lng})
              .toList()
              ?? <Map<String, double>>[];

            return _RunBookmarkCard(
              nickname: nickname,
              avatar: avatar,
              routeName: routeName,
              distance: distance,
              totalTime: totalTime,
              avgPace: avgPace,
              cadence: cadence,
              strideLength: strideLength,
              elevationGain: (run['elevation_gain'] as num?)?.toDouble() ?? 0.0,
              calories: (run['calories'] as num?)?.toInt(),
              heartRate: heartRate,
              geometry: geometry,
              onTap: () {
                final routeId = runRoute?['id'] as String?;
                if (routeId != null && routeId.isNotEmpty) {
                  context.push('/route/$routeId');
                }
              },
              onRemove: () async {
                final api = ref.read(apiServiceProvider);
                try {
                  final resp = await api.unbookmarkRun(runId);
                  if (context.mounted && resp.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已取消收藏'), behavior: SnackBarBehavior.floating),
                    );
                    ref.invalidate(friendsRoutesProvider);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('取消收藏失败'), behavior: SnackBarBehavior.floating),
                    );
                  }
                } catch (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('取消收藏失败: $err'), behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFriendsRoutesFallback(WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(36.r),
              ),
              child: const Icon(Icons.cloud_off, color: Color(0xFFFF3B30), size: 32),
            ),
            SizedBox(height: 16.h),
            Text('无法连接服务器', style: TextStyle(color: Colors.white54, fontSize: 15.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            Text('下拉刷新重试', style: TextStyle(color: Colors.white30, fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }
}

// ==================== 跑友跑迹卡片 ====================

class _RunBookmarkCard extends StatelessWidget {
  final String nickname;
  final String? avatar;
  final String routeName;
  final double distance;
  final int totalTime;
  final int avgPace;
  final int cadence;
  final double strideLength;
  final double elevationGain;
  final int? calories;
  final int heartRate;
  final List<Map<String, double>> geometry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RunBookmarkCard({
    required this.nickname,
    this.avatar,
    required this.routeName,
    required this.distance,
    required this.totalTime,
    required this.avgPace,
    required this.cadence,
    required this.strideLength,
    this.elevationGain = 0.0,
    this.calories,
    required this.heartRate,
    this.geometry = const [],
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像 + 昵称 + 路线名
              Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: const Color(0xFFFF8533).withValues(alpha: 0.12),
                  backgroundImage: avatar != null ? NetworkImage(avatar!) : null,
                  child: avatar == null
                      ? Text(nickname.isNotEmpty ? nickname[0] : '友',
                          style: TextStyle(color: const Color(0xFFFF8533), fontSize: 14.sp, fontWeight: FontWeight.w600))
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nickname, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2.h),
                      Text(routeName, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                    ],
                  ),
                ),
                // 删除按钮
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.close, color: Colors.white38, size: 16.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // 路线轨迹预览图
            if (geometry.isNotEmpty)
              Container(
                height: 120.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: AmapMapView(
                  polylines: {
                    buildTrackPolyline(_toLatLngList(geometry)),
                  },
                  initialCameraPosition: _buildCameraPosition(geometry),
                ),
              ),
            // 跑迹数据面板
            _buildDataPanel(),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildDataPanel() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // 第一行：距离 配速 用时
          Row(
            children: [
              Expanded(child: _dataItem('${(distance / 1000).toStringAsFixed(1)}', 'km')),
              _dataDivider(),
              Expanded(child: _dataItem(_formatPace(avgPace), '/km')),
              _dataDivider(),
              Expanded(child: _dataItem(_formatDuration(totalTime), '用时')),
            ],
          ),
          SizedBox(height: 8.h),
          // 第二行：步频 步幅 心率
          Row(
            children: [
              Expanded(child: _dataItem('$cadence', '步频')),
              _dataDivider(),
              Expanded(child: _dataItem('${strideLength.toStringAsFixed(2)}', 'm')),
              _dataDivider(),
              Expanded(child: _dataItem('$heartRate', '心率')),
            ],
          ),
          // 第三行：爬升 & 卡路里（有数据才显示）
          if (elevationGain > 0 || (calories != null && calories! > 0)) SizedBox(height: 8.h),
          if (elevationGain > 0 || (calories != null && calories! > 0))
            Row(
              children: [
                Expanded(child: _dataItem('${elevationGain.toStringAsFixed(0)}', 'm 爬升')),
                if (calories != null && calories! > 0) ...[
                  _dataDivider(),
                  Expanded(child: _dataItem('$calories', 'kcal')),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _dataItem(String value, String unit) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(color: Colors.white38, fontSize: 11.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dataDivider() {
    return Container(width: 1.h, height: 20.h, color: Colors.white10);
  }

  String _formatPace(int paceSecondsPerKm) {
    if (paceSecondsPerKm <= 0) return '--';
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '--';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h${m}m';
    }
    return '${m}min';
  }
}

// ==================== Tab 3: 上传管理 ====================

class _UploadManageTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uploadsAsync = ref.watch(uploadRecordsProvider);

    return uploadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF8533))),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Color(0xFFFF3B30), size: 48),
            SizedBox(height: 12.h),
            Text('加载失败', style: TextStyle(color: Colors.white54, fontSize: 15.sp)),
          ],
        ),
      ),
      data: (uploads) {
        if (uploads.isEmpty) {
          return _buildEmpty(
            icon: Icons.cloud_upload_outlined,
            title: '暂无上传记录',
            subtitle: '将从运动记录生成的路线\n上传到平台即可分享给跑友',
            action: '上传新跑迹',
            onAction: () => context.push('/routes/upload'),
          );
        }
        return Column(
          children: [
            // 顶部"上传新跑迹"按钮
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/routes/upload'),
                  icon: const Icon(Icons.add, color: Color(0xFFFF8533)),
                  label: Text(l10n.uploadNew, style: TextStyle(color: const Color(0xFFFF8533))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFFFF8533).withValues(alpha: 0.4)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                ),
              ),
            ),
            // 上传记录列表
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: uploads.length,
                itemBuilder: (context, index) {
                  final upload = uploads[index];
                  return _buildUploadRecord(l10n, upload);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadRecord(AppLocalizations l10n, UploadRecord upload) {
    final statusIcon = upload.status == 'approved' ? Icons.check_circle
        : upload.status == 'pending' ? Icons.schedule
        : upload.status == 'failed' ? Icons.error_outline
        : Icons.cloud_upload;

    final statusColor = upload.status == 'approved' ? const Color(0xFF34C759)
        : upload.status == 'pending' ? const Color(0xFFFF8533)
        : upload.status == 'failed' ? const Color(0xFFFF3B30)
        : Colors.white38;

    final statusLabel = upload.status == 'approved' ? l10n.uploadApproved
        : upload.status == 'pending' ? l10n.uploadPending
        : l10n.uploadFailed;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(upload.name, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 2.h),
                Text(
                  '${(upload.distance / 1000).toStringAsFixed(1)}${l10n.km} · ${upload.date}',
                  style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11.sp)),
                    ),
                    if (upload.status == 'pending' && upload.remainingHours != null) ...[
                      SizedBox(width: 6.w),
                      Text(
                        '${l10n.uploadRemaining} ${upload.remainingHours}h',
                        style: TextStyle(color: Colors.white24, fontSize: 11.sp),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (upload.status == 'failed')
            TextButton(
              onPressed: () {},
              child: Text(l10n.uploadRetry, style: TextStyle(color: const Color(0xFFFF8533), fontSize: 13.sp)),
            ),
          if (upload.status == 'pending')
            TextButton(
              onPressed: () {},
              child: Text(l10n.uploadCancel, style: TextStyle(color: Colors.white38, fontSize: 13.sp)),
            ),
        ],
      ),
    );
  }
}

// ==================== Tab 4: 我的热度 ====================

class _StatsDashboardTab extends ConsumerStatefulWidget {
  const _StatsDashboardTab();

  @override
  ConsumerState<_StatsDashboardTab> createState() => _StatsDashboardTabState();
}

class _StatsDashboardTabState extends ConsumerState<_StatsDashboardTab> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.getHeatStats();
      if (resp.isSuccess && resp.data != null) {
        if (mounted) setState(() => _stats = resp.data);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkCount = _stats?['bookmark_count'] ?? '--';
    final companionCount = _stats?['companion_count'] ?? '--';
    final followerCount = _stats?['follower_count'] ?? '--';
    final challengeCount = _stats?['challenge_count'] ?? '--';
    final challengeWins = _stats?['challenge_wins'] ?? 0;
    final challengeLosses = _stats?['challenge_losses'] ?? 0;
    final myChallengeCount = _stats?['my_challenge_count'] ?? '--';
    final myChallengeWins = _stats?['my_challenge_wins'] ?? 0;
    final myChallengeLosses = _stats?['my_challenge_losses'] ?? 0;

    String challengeLabel;
    if (challengeCount == '--') {
      challengeLabel = '被挑战次数';
    } else {
      challengeLabel = '被挑战 $challengeCount 次';
      final parts = <String>[];
      if (challengeWins > 0) parts.add('胜 $challengeWins');
      if (challengeLosses > 0) parts.add('负 $challengeLosses');
      if (parts.isNotEmpty) challengeLabel += '（${parts.join(' / ')}）';
    }

    String myChallengeLabel;
    if (myChallengeCount == '--') {
      myChallengeLabel = '我的挑战';
    } else {
      myChallengeLabel = '我的挑战 $myChallengeCount 次';
      final parts = <String>[];
      if (myChallengeWins > 0) parts.add('胜 $myChallengeWins');
      if (myChallengeLosses > 0) parts.add('负 $myChallengeLosses');
      if (parts.isNotEmpty) myChallengeLabel += '（${parts.join(' / ')}）';
    }

    if (_loading) {
      return ListView(
        padding: EdgeInsets.all(16.w),
        children: List.generate(4, (i) => _skeletonItem()),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFFFF8533),
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _listItem(
            icon: Icons.bookmark,
            iconColor: const Color(0xFFFF8533),
            label: '被收藏次数（总计）',
            value: '$bookmarkCount',
            unit: '次',
          ),
          _listItem(
            icon: Icons.directions_run,
            iconColor: const Color(0xFF34C759),
            label: '伴跑次数',
            value: '$companionCount',
            unit: '次',
            iconWidget: SizedBox(
              width: 28.w,
              height: 28.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, size: 16, color: const Color(0xFF34C759)),
                  Icon(Icons.directions_run, size: 16, color: const Color(0xFF34C759)),
                ],
              ),
            ),
          ),
          _listItem(
            icon: Icons.people,
            iconColor: const Color(0xFF5AC8FA),
            label: '被关注次数',
            value: '$followerCount',
            unit: '人',
          ),
          // 被挑战（别人挑战我）
          _listItem(
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFFF6B6B),
            label: challengeLabel,
            value: '$challengeCount',
            unit: '次',
            iconWidget: SizedBox(
              width: 26.w,
              height: 30.w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(bottom: 0, left: 2, child: Icon(Icons.directions_run, size: 20, color: const Color(0xFFFF6B6B))),
                  Positioned(bottom: 20, left: 6, child: Icon(Icons.emoji_events, size: 11, color: const Color(0xFFFF6B6B))),
                ],
              ),
            ),
          ),
          // 我的挑战（我挑战别人）
          _listItem(
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFFFD700),
            label: myChallengeLabel,
            value: '$myChallengeCount',
            unit: '次',
            iconWidget: SizedBox(
              width: 26.w,
              height: 30.w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(bottom: 0, left: 2, child: Icon(Icons.directions_run, size: 20, color: const Color(0xFFFFD700))),
                  Positioned(bottom: 20, left: 6, child: Icon(Icons.emoji_events, size: 11, color: const Color(0xFFFFD700))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(14.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Container(
              height: 14.h,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 40.w,
            height: 14.h,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    String? sub,
    Widget? iconWidget,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: iconWidget ?? Icon(icon, color: iconColor, size: 22),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(label,
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w500),
              ),
            ),
            Text(value,
              style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w700),
            ),
            if (unit.isNotEmpty) SizedBox(width: 4.w),
            if (unit.isNotEmpty)
              Text(unit,
                style: TextStyle(color: Colors.white38, fontSize: 13.sp),
              ),
            if (sub != null) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(sub,
                  style: TextStyle(color: const Color(0xFFFF3B30), fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== 路线详情弹窗 ====================

void _showRouteDetailSheet(BuildContext context, app_route.Route route, AppLocalizations l10n) {
  final _formatPace = (int paceSecondsPerKm) {
    if (paceSecondsPerKm <= 0) return '--';
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 拖拽指示条
            Padding(
              padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
              child: Container(width: 40.w, height: 4.h,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            // 标题
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(route.name,
                      style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            if (route.creatorName != null)
              Padding(
                padding: EdgeInsets.only(left: 20.w, bottom: 12.h),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.white38, size: 14),
                    SizedBox(width: 6.w),
                    Text('创建人：${route.creatorName}',
                      style: TextStyle(color: Colors.white38, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
            // 大轨迹图（AMap 高德地图）
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AmapMapView(
                    polylines: route.geometry.isEmpty ? <Polyline>{} : {
                      buildTrackPolyline(
                        _toLatLngList(route.geometry),
                        width: 5,
                      ),
                    },
                    initialCameraPosition: _buildCameraPosition(route.geometry),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // 数据面板
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _detailItem('${(route.distance / 1000).toStringAsFixed(1)}', l10n.km),
                      _detailItem(_formatPace(route.avgPace), '/km'),
                      _detailItem('${route.avgCadence}', l10n.spm),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _detailItem('${route.avgStride.toStringAsFixed(2)}', 'm'),
                      _detailItem('${route.elevationGain.toStringAsFixed(0)}', 'm ⛰'),
                      if (route.calories > 0) _detailItem('${route.calories}', l10n.kcal),
                      if (route.avgHeartRate > 0) _detailItem('${route.avgHeartRate}', l10n.bpm),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // 标签
            if (route.tags.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: route.tags.map((tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8533).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text('#$tag',
                        style: TextStyle(color: const Color(0xFFFF8533), fontSize: 12.sp),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            SizedBox(height: 20.h),
          ],
        ),
      );
    },
  );
}

Widget _detailItem(String value, String unit) {
  return Expanded(
    child: Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 2.h),
        Text(unit, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
      ],
    ),
  );
}

// ==================== 空状态 ====================

Widget _buildEmpty({
  required IconData icon,
  required String title,
  required String subtitle,
  required String action,
  required VoidCallback onAction,
}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8533).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(36.r),
            ),
            child: Icon(icon, color: const Color(0xFFFF8533).withValues(alpha: 0.4), size: 32.sp),
          ),
          SizedBox(height: 16.h),
          Text(title, style: TextStyle(color: Colors.white54, fontSize: 15.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white30, fontSize: 13.sp, height: 1.5)),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8533),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text(action, style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    ),
  );
}
