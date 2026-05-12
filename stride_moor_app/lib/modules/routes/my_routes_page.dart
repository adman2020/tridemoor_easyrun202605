import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/models/route.dart' as app_route;
import '../../core/providers/route_provider.dart';
import '../../l10n/app_localizations.dart';

/// 我的跑迹 —— 列表展示个人所有跑迹
class MyRoutesPage extends ConsumerWidget {
  const MyRoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final routesAsync = ref.watch(myRoutesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myRoutes)),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (routes) {
          if (routes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48.sp, color: context.textTertiary),
                  SizedBox(height: 12.h),
                  Text('暂无路线', style: TextStyle(color: context.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return _RouteListTile(
                route: route,
                onTap: () => context.push('/route/${route.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _RouteListTile extends StatelessWidget {
  final app_route.Route route;
  final VoidCallback onTap;

  const _RouteListTile({required this.route, required this.onTap});

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
          '${(route.distance / 1000).toStringAsFixed(1)}${l10n.km} · ${l10n.elevation}${route.elevationGain.toStringAsFixed(0)}m · ${_formatDate(route.createdAt)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
