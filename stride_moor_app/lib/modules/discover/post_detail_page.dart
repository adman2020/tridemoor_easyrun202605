import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config/theme.dart';
import '../../core/models/post.dart';
import '../../core/models/user.dart';
import '../../core/models/run.dart';
import '../../core/models/route.dart' as app_route;
import '../../core/providers/post_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/amap_map_view.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/route_provider.dart';
import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';
import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';

/// 动态详情页 —— 展示帖子内容 + 评论列表 + 点赞/评论交互
class PostDetailPage extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    await ref.read(createCommentProvider(widget.postId).notifier).submit(text);
    _commentController.clear();
    // 刷新评论列表和帖子详情（更新commentCount）
    ref.invalidate(postCommentsProvider(widget.postId));
    ref.invalidate(postDetailProvider(widget.postId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(l10n.postDetail),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: postAsync.when(
        data: (post) => Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _PostContent(post: post)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                      child: Text(
                        '${l10n.comments} (${post.commentCount})',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: context.textPrimary),
                      ),
                    ),
                  ),
                  commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.w),
                            child: Center(
                              child: Text(l10n.noComments, style: TextStyle(fontSize: 14.sp, color: context.textSecondary)),
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _CommentItem(comment: comments[index]),
                          childCount: comments.length,
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(child: _LoadingComments()),
                    error: (err, _) => SliverToBoxAdapter(
                      child: Center(child: Text('$err', style: TextStyle(color: context.textSecondary))),
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(bottom: 16.h)),
                ],
              ),
            ),
            _CommentInput(
              controller: _commentController,
              onSubmit: _submitComment,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$err', style: TextStyle(color: context.textSecondary)),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () => ref.invalidate(postDetailProvider(widget.postId)),
                child: Text(l10n.retry, style: TextStyle(color: AppColors.orange)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 帖子内容区
class _PostContent extends ConsumerWidget {
  final Post post;
  const _PostContent({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = post.user;
    final run = post.run;

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

    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, user, ref),
          SizedBox(height: 12.h),
          if (post.content != null && post.content!.isNotEmpty)
            Text(post.content!, style: TextStyle(fontSize: 15.sp, color: context.textPrimary, height: 1.6)),
          if (trackPoints != null && trackPoints.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _buildTrackPreview(context, trackPoints),
          ],
          if (run != null) ...[
            SizedBox(height: 12.h),
            _buildRunStats(context, run, l10n),
          ],
          SizedBox(height: 16.h),
          Divider(color: context.dividerColor, height: 1),
          SizedBox(height: 12.h),
          _buildActions(context, ref, l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user, WidgetRef ref) {
    final name = user?.nickname ?? '跑友';
    final avatarUrl = user?.avatarUrl;
    final userId = user?.id;
    final followedIds = ref.watch(followedUserIdsProvider);
    final isFollowed = userId != null && followedIds.contains(userId);
    // 跑迹收藏按钮：有跑步记录即可收藏，不要求有关联路线
    final hasRun = post.run != null;
    // 检查当前跑迹是否已收藏
    final bookmarkedRunIds = ref.watch(bookmarkedRunIdsProvider);
    final isRunBookmarked = post.run?.id != null && bookmarkedRunIds.contains(post.run!.id);


    return Row(
      children: [
        CircleAvatar(
          radius: 22.r,
          backgroundColor: AppColors.orange.withValues(alpha: 0.1),
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Text(name[0], style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 18.sp))
              : null,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: context.textPrimary)),
                  if (userId != null && userId.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: () {
                        ref.read(followedUserIdsProvider.notifier).toggle(userId);
                      },
                      borderRadius: BorderRadius.circular(4.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isFollowed ? Colors.transparent : AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                          border: isFollowed
                              ? Border.all(color: context.dividerColor)
                              : null,
                        ),
                        child: Text(
                          isFollowed ? '已关注' : '关注',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isFollowed ? context.textTertiary : AppColors.orange,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (hasRun) ...[
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: isRunBookmarked ? null : () => _onCollectRun(context, ref, post.run?.id),
                      borderRadius: BorderRadius.circular(4.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isRunBookmarked
                              ? Colors.transparent
                              : AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                          border: isRunBookmarked
                              ? Border.all(color: context.dividerColor)
                              : null,
                        ),
                        child: Text(
                          isRunBookmarked ? '已收藏' : '跑迹收藏',
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: isRunBookmarked ? context.textTertiary : AppColors.orange),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(_formatTime(post.createdAt), style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onCollectRun(BuildContext context, WidgetRef ref, String? runId) async {
    // 调用后端 API 收藏路线
    final api = ref.read(apiServiceProvider);
    if (runId == null || runId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('该动态没有跑步记录'), duration: const Duration(seconds: 1)),
        );
      }
      return;
    }
    try {
      final resp = await api.bookmarkRun(runId);
      if (context.mounted) {
        if (resp.isSuccess) {
          ref.refresh(friendsRoutesProvider);
          ref.read(bookmarkedRunIdsProvider.notifier).add(runId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('跑迹收藏成功'), duration: const Duration(seconds: 1)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('收藏失败: ${resp.message}'), duration: const Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('收藏失败: $e')),
        );
      }
    }
  }

  Widget _buildTrackPreview(BuildContext context, List<LatLng> points) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        color: context.surfaceElevatedColor,
        child: AmapMapView(
          initialCameraPosition: CameraPosition(target: points.first, zoom: 15),
          polylines: {buildTrackPolyline(points, color: AppColors.orange, width: 4)},
        ),
      ),
    );
  }

  Widget _buildRunStats(BuildContext context, Run run, AppLocalizations l10n) {
    final distanceKm = (run.totalDistance / 1000).toStringAsFixed(1);
    final pace = run.avgPace != null && run.avgPace! > 0 ? _formatPace(run.avgPace!) : '--';
    final duration = _formatDuration(run.totalTime);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(label: l10n.distance, value: '$distanceKm ${l10n.km}'),
          _StatColumn(label: l10n.pace, value: pace),
          _StatColumn(label: l10n.duration, value: duration),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final likeState = ref.watch(likePostProvider(post.id));
    final isLiked = likeState.whenOrNull(data: (v) => v) ?? post.isLiked;
    final likeCount = isLiked != post.isLiked
        ? (isLiked ? post.likeCount + 1 : post.likeCount - 1).clamp(0, 999999)
        : post.likeCount;

    return Row(
      children: [
        Expanded(
          child: _DetailActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            iconColor: isLiked ? AppColors.error : context.textSecondary,
            label: likeCount > 0 ? '${l10n.like} $likeCount' : l10n.like,
            onTap: () {
              ref.read(likePostProvider(post.id).notifier).toggle(isLiked);
            },
          ),
        ),
        Expanded(
          child: _DetailActionButton(
            icon: Icons.chat_bubble_outline,
            label: post.commentCount > 0 ? '${l10n.comment} ${post.commentCount}' : l10n.comment,
            onTap: () {
              // 滚动到评论区域由外部处理
            },
          ),
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

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.textPrimary)),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(fontSize: 11.sp, color: context.textTertiary)),
      ],
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  const _DetailActionButton({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20.sp, color: iconColor ?? context.textSecondary),
            SizedBox(width: 6.w),
            Text(label, style: TextStyle(fontSize: 14.sp, color: iconColor ?? context.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// 评论条目
class _CommentItem extends StatelessWidget {
  final PostComment comment;
  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    final user = comment.user;
    final name = user?.nickname ?? '跑友';
    final avatarUrl = user?.avatarUrl;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: AppColors.orange.withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(name[0], style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 12.sp))
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: context.textPrimary)),
                    SizedBox(width: 8.w),
                    Text(_formatTime(comment.createdAt), style: TextStyle(fontSize: 11.sp, color: context.textTertiary)),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(comment.content, style: TextStyle(fontSize: 14.sp, color: context.textPrimary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
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
}

/// 评论输入区
class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _CommentInput({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, MediaQuery.of(context).padding.bottom + 8.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l10n.enterComment,
                  hintStyle: TextStyle(fontSize: 14.sp, color: context.textTertiary),
                  filled: true,
                  fillColor: context.surfaceElevatedColor,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(fontSize: 14.sp, color: context.textPrimary),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onSubmit,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Icon(Icons.send, color: Colors.white, size: 20.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingComments extends StatelessWidget {
  const _LoadingComments();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32.w),
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
