import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/theme.dart';
import '../../core/models/route.dart' as app_route;
import '../../core/providers/route_provider.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';

/// 路线完整排行榜页
class RouteLeaderboardPage extends ConsumerStatefulWidget {
  final String routeId;
  const RouteLeaderboardPage({super.key, required this.routeId});

  @override
  ConsumerState<RouteLeaderboardPage> createState() => _RouteLeaderboardPageState();
}

class _RouteLeaderboardPageState extends ConsumerState<RouteLeaderboardPage> {
  final List<app_route.RouteLeaderboardEntry> _entries = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _entries.clear();
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final newEntries = await ref.read(routeLeaderboardProvider((widget.routeId, 'time')).future);
      // 去重：同一用户只保留最好成绩
      final existingUserIds = _entries.map((e) => e.userId).toSet();
      final uniqueNewEntries = newEntries.where((e) => !existingUserIds.contains(e.userId)).toList();
      
      setState(() {
        _entries.addAll(uniqueNewEntries);
        _hasMore = uniqueNewEntries.length >= 20;
      });
    } catch (e) {
      // error handled by UI
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(l10n.leaderboard),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.orange,
        child: _entries.isEmpty && !_isLoadingMore
            ? _buildEmptyState(l10n)
            : ListView.builder(
                padding: EdgeInsets.all(20.w),
                itemCount: _entries.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _entries.length) {
                    _loadMore();
                    return _buildLoadingFooter();
                  }
                  return _LeaderboardListItem(
                    rank: index + 1,
                    entry: _entries[index],
                    routeId: widget.routeId,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: context.textTertiary),
          SizedBox(height: 16.h),
          Text('暂无排行数据，快去跑一条吧！', style: TextStyle(fontSize: 16.sp, color: context.textSecondary)),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: _refresh,
            child: Text(l10n.retry, style: TextStyle(fontSize: 14.sp, color: AppColors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingFooter() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Center(
        child: SizedBox(
          width: 24.w,
          height: 24.w,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
        ),
      ),
    );
  }
}

class _LeaderboardListItem extends ConsumerWidget {
  final int rank;
  final app_route.RouteLeaderboardEntry entry;
  final String routeId;

  const _LeaderboardListItem({required this.rank, required this.entry, required this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTop3 = rank <= 3;
    final medalColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : null;

    // 检查当前路线是否已收藏
    final favRouteIds = ref.watch(favoritedRouteIdsProvider);
    final isRouteFavorited = favRouteIds.contains(routeId);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isTop3 ? medalColor!.withValues(alpha: 0.5) : context.dividerColor,
          width: isTop3 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // 排名
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: isTop3 ? medalColor!.withValues(alpha: 0.15) : Colors.transparent,
              shape: BoxShape.circle,
              border: isTop3
                  ? Border.all(color: medalColor!, width: 2)
                  : Border.all(color: context.dividerColor),
            ),
            child: Center(
              child: isTop3
                  ? Icon(
                      Icons.emoji_events,
                      color: medalColor,
                      size: 20.sp,
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 14.w),
          // 用户头像 + 昵称
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.orange.withValues(alpha: 0.1),
            backgroundImage: entry.userAvatar != null && entry.userAvatar!.isNotEmpty
                ? NetworkImage(entry.userAvatar!)
                : null,
            child: entry.userAvatar == null || entry.userAvatar!.isEmpty
                ? Text(
                    (entry.userNickname ?? '跑')[0],
                    style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 15.sp),
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          // 昵称 + 用时
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userNickname ?? '跑者',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimary),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatTime(entry.totalTime),
                  style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
                ),
              ],
            ),
          ),
          // 打卡次数
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.runCount}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isTop3 ? AppColors.orange : context.textPrimary,
                ),
              ),
              Text(
                '次打卡',
                style: TextStyle(fontSize: 10.sp, color: context.textTertiary),
              ),
            ],
          ),
          SizedBox(width: 8.w),
          // 跑迹收藏按钮
          InkWell(
            onTap: isRouteFavorited ? null : () => _onCollectRoute(context, ref),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: isRouteFavorited
                                  ? Colors.transparent
                                  : AppColors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: isRouteFavorited
                                  ? Border.all(color: context.dividerColor)
                                  : null,
                            ),
                            child: Text(
                              isRouteFavorited ? '已收藏' : '跑迹收藏',
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isRouteFavorited ? context.textTertiary : AppColors.orange),
                            ),
                          ),
                        ),
        ],
      ),
    );
  }

  Future<void> _onCollectRoute(BuildContext context, WidgetRef ref) async {
    // 调用后端 API 收藏路线
    final api = ref.read(apiServiceProvider);
    try {
      final resp = await api.favoriteRoute(routeId);
      if (context.mounted) {
        ref.invalidate(myFavoriteRoutesProvider);
        ref.read(favoritedRouteIdsProvider.notifier).add(routeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp.isSuccess ? '跑迹收藏成功' : '收藏失败: '),
            duration: const Duration(seconds: 1),
          ),
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
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}
