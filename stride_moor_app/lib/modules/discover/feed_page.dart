import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/models/post.dart';
import '../../core/models/user.dart';
import '../../core/models/run.dart';
import '../../core/providers/post_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/amap_map_view.dart';
import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';
import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';

/// 跑友动态页 —— 全量动态流
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  int _currentPage = 1;
  final List<Post> _posts = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 1;
      _posts.clear();
      _hasMore = true;
    });
    // 清除缓存，防止发动态回来读旧数据
    ref.invalidate(postListProvider);
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final posts = await ref.read(postListProvider(_currentPage).future);
      setState(() {
        _posts.addAll(posts);
        _currentPage++;
        _hasMore = posts.length >= 10;
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
        title: Text(l10n.feed),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.orange,
        child: _posts.isEmpty && !_isLoadingMore
            ? _buildEmptyState(l10n)
            : ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: _posts.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _posts.length) {
                    _loadMore();
                    return _buildLoadingFooter();
                  }
                  return FeedCard(
                    post: _posts[index],
                    onTap: () => context.push('/post/${_posts[index].id}'),
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
          Icon(Icons.feed_outlined, size: 64, color: context.textTertiary),
          SizedBox(height: 16.h),
          Text(l10n.noData, style: TextStyle(fontSize: 16.sp, color: context.textSecondary)),
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

/// 动态卡片（Feed 列表 + 发现页共用）
class FeedCard extends ConsumerWidget {
  final Post post;
  final VoidCallback onTap;

  const FeedCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = post.user;
    final run = post.run;

    // 轨迹预览来源优先级：run.samples > route.geometry (from route_points)
    List<LatLng>? trackPoints;
    if (run != null && run.samples.isNotEmpty) {
      trackPoints = run.samples
          .where((s) => s.latitude != 0 && s.longitude != 0)
          .map((s) => LatLng(s.latitude, s.longitude))
          .toList();
    } else if (post.route != null && post.route!.geometry.isNotEmpty) {
      trackPoints = post.route!.geometry
          .where((g) => g['lat'] != 0 && g['lng'] != 0)
          .map((g) => LatLng(g['lat']!, g['lng']!))
          .toList();
    }
    debugPrint('FeedCard: post=${post.id}, samples=${run?.samples.length ?? 0}, geometry=${post.route?.geometry.length ?? 0}, trackPoints=${trackPoints?.length ?? 0}');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, user),
              SizedBox(height: 12.h),
              if (post.content != null && post.content!.isNotEmpty)
                Text(post.content!, style: TextStyle(fontSize: 14.sp, color: context.textPrimary, height: 1.5)),
              if (trackPoints != null && trackPoints.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _buildTrackPreview(context, trackPoints),
              ],
              if (run != null) ...[
                SizedBox(height: 8.h),
                _buildRunStats(context, run, l10n),
              ],
              SizedBox(height: 12.h),
              _buildActions(context, ref, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    final name = user?.nickname ?? '跑友';
    final avatarUrl = user?.avatarUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.orange.withValues(alpha: 0.1),
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Text(name[0], style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 16.sp))
              : null,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimary)),
              Text(_formatTime(post.createdAt), style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackPreview(BuildContext context, List<LatLng> points) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 120.h,
        color: context.surfaceElevatedColor,
        child: AmapMapView(
          initialCameraPosition: CameraPosition(target: points.first, zoom: 15),
          polylines: {buildTrackPolyline(points, color: AppColors.orange)},
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: false,
        ),
      ),
    );
  }

  Widget _buildRunStats(BuildContext context, Run run, AppLocalizations l10n) {
    final distanceKm = (run.totalDistance / 1000).toStringAsFixed(1);
    final pace = run.avgPace != null && run.avgPace! > 0
        ? _formatPace(run.avgPace!)
        : '--';
    final duration = _formatDuration(run.totalTime);

    return Row(
      children: [
        _StatBadge(icon: Icons.straighten, value: '$distanceKm ${l10n.km}'),
        SizedBox(width: 12.w),
        _StatBadge(icon: Icons.timer_outlined, value: pace),
        SizedBox(width: 12.w),
        _StatBadge(icon: Icons.schedule, value: duration),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Row(
      children: [
        _ActionButton(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: post.isLiked ? AppColors.error : context.textTertiary,
          label: post.likeCount > 0 ? '${post.likeCount}' : l10n.like,
          onTap: () {
            ref.read(likePostProvider(post.id).notifier).toggle(post.isLiked);
          },
        ),
        SizedBox(width: 24.w),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: post.commentCount > 0 ? '${post.commentCount}' : l10n.comment,
          onTap: onTap,
        ),
        SizedBox(width: 24.w),
        _ActionButton(
          icon: Icons.share_outlined,
          label: l10n.share,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.shareDev), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${dt.month}月${dt.day}日';
  }

  String _formatPace(int paceSecondsPerKm) {
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}";
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h${m}m';
    return '${m}m${s}s';
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  const _StatBadge({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: context.textTertiary),
          SizedBox(width: 4.w),
          Text(value, style: TextStyle(fontSize: 11.sp, color: context.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.sp, color: iconColor ?? context.textTertiary),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 12.sp, color: context.textTertiary)),
        ],
      ),
    );
  }
}
