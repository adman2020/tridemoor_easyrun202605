import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/models/route.dart' as app_route;
import '../../core/providers/route_provider.dart';
import '../../l10n/app_localizations.dart';

/// 跑友跑迹选择页 —— 从收藏的跑友路线中选择一条作为伴跑/挑战路线
class FriendsRouteSelectPage extends ConsumerWidget {
  const FriendsRouteSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(friendsRoutesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('选择跑友跑迹')),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (items) {
          // 从 bookmark 条目中提取 route 数据
          final routes = items.map((item) {
            final routeJson = item['route'] as Map<String, dynamic>?;
            if (routeJson != null) {
              return app_route.Route.fromJson(routeJson);
            }
            return null;
          }).whereType<app_route.Route>().toList();

          if (routes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 48.sp, color: context.textTertiary),
                  SizedBox(height: 12.h),
                  Text('暂无跑友跑迹', style: TextStyle(color: context.textSecondary)),
                  SizedBox(height: 8.h),
                  Text(
                    '先去跑迹广场收藏跑友的路线吧',
                    style: TextStyle(color: context.textTertiary, fontSize: 12.sp),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return _RouteSelectCard(
                route: route,
                onTap: () => context.pop<app_route.Route>(route),
              );
            },
          );
        },
      ),
    );
  }
}

class _RouteSelectCard extends StatelessWidget {
  final app_route.Route route;
  final VoidCallback onTap;

  const _RouteSelectCard({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: const Icon(Icons.map, color: AppColors.orange),
        ),
        title: Text(route.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${(route.distance / 1000).toStringAsFixed(1)}${l10n.km} · ${l10n.elevation}${route.elevationGain.toStringAsFixed(0)}m · ${route.creatorName ?? '未知'}',
        ),
        trailing: const Icon(Icons.check_circle_outline, color: AppColors.orange),
        onTap: onTap,
      ),
    );
  }
}
