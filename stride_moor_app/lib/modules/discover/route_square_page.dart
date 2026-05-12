import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/models/route.dart' as app_route;
import '../../core/providers/route_provider.dart';
import '../../l10n/app_localizations.dart';

/// 跑迹广场 —— 浏览所有跑迹（城市筛选 + 人气/最新/评分 tabs）
class RouteSquarePage extends ConsumerStatefulWidget {
  const RouteSquarePage({super.key});

  @override
  ConsumerState<RouteSquarePage> createState() => _RouteSquarePageState();
}

class _RouteSquarePageState extends ConsumerState<RouteSquarePage> {
  String? _selectedCity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 获取所有城市列表
    final groupedAsync = ref.watch(routesByCityProvider);
    final cities = <String>[];
    final grouped = groupedAsync.valueOrNull;
    if (grouped != null) {
      cities.addAll(grouped.keys);
      cities.sort();
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.routeSquare),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.searchDev),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(42.h),
            child: Row(
              children: [
                // 左侧城市下拉
                PopupMenuButton<String>(
                  onSelected: (city) {
                    setState(() => _selectedCity = city == '全部' ? null : city);
                  },
                  offset: Offset(0, 42.h),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCity ?? '全部',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Icon(Icons.arrow_drop_down, color: AppColors.orange, size: 20.sp),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: '全部', child: Text('全部')),
                    ...cities.map((city) => PopupMenuItem(value: city, child: Text(city))),
                  ],
                ),
                // 右侧 TabBar
                Expanded(
                  child: TabBar(
                    isScrollable: true,
                    labelColor: AppColors.orange,
                    unselectedLabelColor: context.textSecondary,
                    indicatorColor: AppColors.orange,
                    tabs: [
                      Tab(text: l10n.hot),
                      Tab(text: l10n.latest),
                      Tab(text: l10n.rating),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _RouteListTab(sortBy: 'popularity', cityFilter: _selectedCity),
            _RouteListTab(cityFilter: _selectedCity),
            _RouteListTab(sortBy: 'rating', cityFilter: _selectedCity),
          ],
        ),
      ),
    );
  }
}

class _RouteListTab extends ConsumerWidget {
  final String? sortBy;
  final bool nearby;
  final String? cityFilter;

  const _RouteListTab({this.sortBy, this.nearby = false, this.cityFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<app_route.Route>> routesAsync;
    if (nearby) {
      routesAsync = ref.watch(nearbyRoutesProvider);
    } else {
      routesAsync = ref.watch(routeListProvider(sortBy));
    }

    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (routes) {
        // 城市全局筛选
        var filtered = routes;
        if (cityFilter != null && cityFilter!.isNotEmpty) {
          filtered = routes.where((r) => r.city == cityFilter).toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Text(cityFilter != null ? '该城市暂无路线' : '暂无路线'),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _RouteListCard(
              route: filtered[index],
              onTap: () => context.push('/route/${filtered[index].id}'),
            );
          },
        );
      },
    );
  }
}

class _RouteListCard extends StatelessWidget {
  final app_route.Route route;
  final VoidCallback onTap;
  final bool showCity;

  const _RouteListCard({required this.route, required this.onTap, this.showCity = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String difficultyLabel;
    switch (route.difficulty) {
      case 'hard':
        difficultyLabel = l10n.hard;
      case 'moderate':
        difficultyLabel = l10n.moderate;
      default:
        difficultyLabel = l10n.easy;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Icon(Icons.map, color: Colors.white.withValues(alpha: 0.8), size: 32.sp),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showCity && route.city != null && route.city!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          route.city!,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    route.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${(route.distance / 1000).toStringAsFixed(1)}km · $difficultyLabel · ${l10n.elevation}${route.elevationGain.toStringAsFixed(0)}m',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14.sp, color: context.textTertiary),
                      SizedBox(width: 4.w),
                      Text(
                        '${route.popularity} ${l10n.peopleRan}',
                        style: TextStyle(fontSize: 12.sp, color: context.textTertiary),
                      ),
                      SizedBox(width: 12.w),
                      Icon(Icons.star, size: 14.sp, color: AppColors.orange),
                      SizedBox(width: 4.w),
                      Text(
                        route.rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12.sp, color: context.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textTertiary),
          ],
        ),
      ),
    );
  }
}
