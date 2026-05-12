import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';
import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';

import '../../config/theme.dart';
import '../../core/models/route.dart' as app_route;
import '../../core/providers/route_provider.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/amap_map_view.dart';

/// 跑迹详情页
class RouteDetailPage extends ConsumerStatefulWidget {
  final String routeId;

  const RouteDetailPage({super.key, required this.routeId});

  @override
  ConsumerState<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends ConsumerState<RouteDetailPage> {
  int selectedTab = 0; // 0=打卡榜, 1=成绩榜

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(routeDetailProvider(widget.routeId));

    return detailAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('加载失败: $e'))),
      data: (detail) {
        final route = detail.route;
        final favCount = detail.favCount;

        // 地图参数
        final trackPoints = route.geometry
            .map((p) => LatLng(p['lat']!, p['lng']!))
            .toList();
        final trackLines = trackPoints.length >= 2
            ? {buildTrackPolyline(trackPoints)}
            : <Polyline>{};

        String difficultyLabel;
        Color difficultyColor;
        switch (route.difficulty) {
          case 'hard':
            difficultyLabel = l10n.hard;
            difficultyColor = AppColors.error;
          case 'moderate':
            difficultyLabel = l10n.moderate;
            difficultyColor = AppColors.warning;
          default:
            difficultyLabel = l10n.easy;
            difficultyColor = AppColors.success;
        }

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.5,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: AmapMapView(
                    initialCameraPosition: trackPoints.isNotEmpty
                        ? CameraPosition(target: trackPoints.first, zoom: 15)
                        : null,
                    polylines: trackLines,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          _TagChip(
                            label: '${(route.distance / 1000).toStringAsFixed(1)}km',
                            color: AppColors.pace,
                          ),
                          SizedBox(width: 8.w),
                          _TagChip(label: difficultyLabel, color: difficultyColor),
                          SizedBox(width: 8.w),
                          _TagChip(
                            label: '${l10n.elevation}${route.elevationGain.toStringAsFixed(0)}m',
                            color: AppColors.elevation,
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      _buildCreatorInfo(context, route),
                      SizedBox(height: 24.h),
                      _buildDataGrid(context, ref, l10n, route, favCount),
                      SizedBox(height: 24.h),
                      _buildLeaderboard(context, ref, l10n, route),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 底部操作栏已移除：收藏和去伴跑按钮
        );
      },
    );
  }

  Widget _buildCreatorInfo(BuildContext context, app_route.Route route) {
    final displayName = route.creatorName ?? '跑者';
    final dateStr = route.createdAt != null
        ? '${route.createdAt!.year}-${route.createdAt!.month.toString().padLeft(2, '0')}-${route.createdAt!.day.toString().padLeft(2, '0')}'
        : '';

    return Row(
      children: [
        CircleAvatar(
          radius: 24.r,
          backgroundColor: AppColors.orange.withValues(alpha: 0.1),
          backgroundImage: route.creatorAvatar != null ? NetworkImage(route.creatorAvatar!) : null,
          child: route.creatorAvatar == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0] : '跑',
                  style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimary),
            ),
            if (dateStr.isNotEmpty)
              Text(
                '${AppLocalizations.of(context).createdAt} $dateStr',
                style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataGrid(BuildContext context, WidgetRef ref, AppLocalizations l10n, app_route.Route route, int favCount) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DataBox(label: l10n.distance, value: (route.distance / 1000).toStringAsFixed(1), unit: l10n.km),
          _DataBox(label: l10n.elevation, value: route.elevationGain.toStringAsFixed(0), unit: l10n.m),
          _DataBox(label: l10n.checkIns, value: '$favCount', unit: l10n.people),
          GestureDetector(
            onTap: () => _showRateDialog(context, ref, route),
            child: _DataBox(label: l10n.rating, value: route.rating.toStringAsFixed(1), unit: '⭐'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context, WidgetRef ref, app_route.Route route) {
    double selectedRating = route.rating > 0 ? route.rating : 5.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState) => AlertDialog(
          backgroundColor: context.bgColor,
          title: Text('为路线评分', style: TextStyle(color: context.textPrimary, fontSize: 16.sp)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(route.name, style: TextStyle(color: context.textSecondary, fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 24.h),
              Text(
                selectedRating.toStringAsFixed(1),
                style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.bold, color: AppColors.orange),
              ),
              SizedBox(height: 8.h),
              Slider(
                value: selectedRating,
                min: 1.0,
                max: 5.0,
                divisions: 8, // 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
                activeColor: AppColors.orange,
                inactiveColor: AppColors.orange.withValues(alpha: 0.2),
                onChanged: (value) => setState(() => selectedRating = value),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1.0', style: TextStyle(fontSize: 11.sp, color: context.textTertiary)),
                  Text('5.0', style: TextStyle(fontSize: 11.sp, color: context.textTertiary)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('取消', style: TextStyle(color: context.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final api = ref.read(apiServiceProvider);
                try {
                  final resp = await api.rateRoute(route.id, selectedRating);
                  if (resp.isSuccess) {
                    ref.invalidate(routeDetailProvider(widget.routeId));
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(resp.isSuccess ? '评分成功' : '评分失败: ${resp.message}')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('评分失败: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
              child: const Text('提交', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, WidgetRef ref, AppLocalizations l10n, app_route.Route currentRoute) {
    return StatefulBuilder(
      builder: (context, setState) {
        final sortBy = selectedTab == 0 ? '' : 'time_asc';
        final leaderboardAsync = ref.watch(routeLeaderboardProvider((widget.routeId, sortBy)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.leaderboard,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                _LeaderboardTab(
                  label: '打卡榜',
                  selected: selectedTab == 0,
                  onTap: () => setState(() => selectedTab = 0),
                ),
                SizedBox(width: 8.w),
                _LeaderboardTab(
                  label: '成绩榜',
                  selected: selectedTab == 1,
                  onTap: () => setState(() => selectedTab = 1),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            leaderboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('排行榜加载失败: $e', style: TextStyle(color: context.textSecondary)),
              data: (entries) {
                if (entries.isEmpty) {
                  return Text('暂无排行数据，快去跑一条吧！', style: TextStyle(color: context.textSecondary));
                }
                return Column(
                  children: entries.map((entry) {
                    final index = entries.indexOf(entry);
                    return _LeaderboardItem(
                      routeId: widget.routeId,
                      index: index,
                      nickname: entry.userNickname ?? '跑者',
                      runCount: entry.runCount,
                      time: entry.totalTime,
                      avgPace: entry.avgPace,
                      route: currentRoute,
                      isTimeRanking: selectedTab == 1,
                      runId: entry.runId,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _LeaderboardItem extends ConsumerWidget {
  final String routeId;
  final int index;
  final String nickname;
  final int runCount;
  final int time;
  final int? avgPace;
  final app_route.Route route;
  final bool isTimeRanking;
  final String runId;

  const _LeaderboardItem({
    required this.routeId,
    required this.index,
    required this.nickname,
    required this.runCount,
    required this.time,
    this.avgPace,
    required this.route,
    this.isTimeRanking = false,
    required this.runId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 检查当前跑迹是否已收藏
    final bookmarkedRunIds = ref.watch(bookmarkedRunIdsProvider);
    final isRunBookmarked = bookmarkedRunIds.contains(runId);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: index == 0 ? AppColors.orange : AppColors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: index == 0 ? Colors.white : AppColors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: TextStyle(fontSize: 15.sp, color: context.textPrimary),
                ),
                Text(
                  _formatTime(time),
                  style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isTimeRanking && avgPace != null && avgPace! > 0) ...[
                Text(
                  _formatPace(avgPace!),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
                Text(
                  '平均配速',
                  style: TextStyle(fontSize: 10.sp, color: context.textTertiary),
                ),
              ] else ...[
                Text(
                  '$runCount',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
                Text(
                  '次打卡',
                  style: TextStyle(fontSize: 10.sp, color: context.textTertiary),
                ),
              ],
            ],
          ),
          SizedBox(width: 8.w),
          InkWell(
            onTap: isRunBookmarked ? null : () => _onCollectRun(context, ref, runId),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: isRunBookmarked
                                  ? Colors.transparent
                                  : AppColors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: isRunBookmarked
                                  ? Border.all(color: context.dividerColor)
                                  : null,
                            ),
                            child: Text(
                              isRunBookmarked ? '已收藏' : '跑迹收藏',
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isRunBookmarked ? context.textTertiary : AppColors.orange),
                            ),
                          ),
                        ),
        ],
      ),
    );
  }

  Future<void> _onCollectRun(BuildContext context, WidgetRef ref, String runId) async {
    if (runId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可收藏的跑迹'), duration: Duration(seconds: 1)),
      );
      return;
    }
    final api = ref.read(apiServiceProvider);
    try {
      final resp = await api.bookmarkRun(runId);
      if (context.mounted && resp.isSuccess) {
        ref.refresh(friendsRoutesProvider);
        if (runId.isNotEmpty) {
          ref.read(bookmarkedRunIdsProvider.notifier).add(runId);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('跑迹收藏成功'), duration: Duration(seconds: 1)),
        );;
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('收藏失败: ${resp.message}'), duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('收藏失败: $e')),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(int paceSecondsPerKm) {
    if (paceSecondsPerKm <= 0) return '--';
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }
}

class _LeaderboardTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LeaderboardTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.orange),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.orange,
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _DataBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _DataBox({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
