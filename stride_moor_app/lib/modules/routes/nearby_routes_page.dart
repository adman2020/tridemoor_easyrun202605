import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';
import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';

import '../../config/theme.dart';
import '../../core/models/route.dart' as app_route;
import '../../core/providers/route_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/amap_map_view.dart';

/// 附近推荐 —— 基于LBS展示周边热门跑迹
class NearbyRoutesPage extends ConsumerWidget {
  const NearbyRoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final routesAsync = ref.watch(nearbyRoutesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nearbyRoutes)),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (routes) => Column(
          children: [
            // 地图
            Expanded(
              flex: 2,
              child: _buildMap(context, routes),
            ),
            // 列表
            Expanded(
              flex: 3,
              child: _buildRouteList(context, l10n, routes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context, List<app_route.Route> routes) {
    bool isValidLatLng(double? lat, double? lng) {
      return lat != null &&
          lng != null &&
          lat.abs() <= 90 &&
          lng.abs() <= 180 &&
          lat.isFinite &&
          lng.isFinite;
    }

    final markers = <Marker>{};
    for (final route in routes) {
      final point = route.centerPoint ?? route.startPoint;
      if (point != null && isValidLatLng(point['lat'], point['lng'])) {
        markers.add(Marker(
          position: LatLng(point['lat']!, point['lng']!),
          infoWindow: InfoWindow(title: route.name),
        ));
      }
    }

    return AmapMapView(markers: markers);
  }

  Widget _buildRouteList(BuildContext context, AppLocalizations l10n, List<app_route.Route> routes) {
    if (routes.isEmpty) {
      return Center(child: Text('附近暂无路线', style: TextStyle(color: context.textSecondary)));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return ListTile(
          leading: Icon(Icons.location_on, color: AppColors.primary),
          title: Text(route.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${(route.distance / 1000).toStringAsFixed(1)}km · ${l10n.elevation}${route.elevationGain.toStringAsFixed(0)}m · ${route.popularity}${l10n.peopleRan}',
          ),
          trailing: Icon(Icons.chevron_right, color: context.textTertiary),
          onTap: () => context.push('/route/${route.id}'),
        );
      },
    );
  }
}
