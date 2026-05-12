import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/challenge_provider.dart';
import '../../core/providers/user_provider.dart';

/// 挑战记录页面（个人历史）
class ChallengeHistoryPage extends ConsumerWidget {
  const ChallengeHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final challengesAsync = ref.watch(myChallengesProvider);
    final userAsync = ref.watch(userProvider);
    final userId = userAsync.value?.id;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.challengeRecord)),
      body: challengesAsync.when(
        data: (items) {
          final total = items.length;
          int winCount = 0;
          int loseCount = 0;
          if (userId != null) {
            for (final item in items) {
              final result = item.resultFor(userId);
              if (result == 'win') winCount++;
              if (result == 'lose') loseCount++;
            }
          }
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildStatsCard(context, total, winCount, loseCount),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '暂无挑战记录',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return _ChallengeRecordTile(
                          item: item,
                          currentUserId: userId,
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('${l10n.loadFailed}: $err')),
      ),
    );
  }

  Widget _buildStatsCard(
      BuildContext context, int total, int win, int lose) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: context.dividerColor),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(value: '$total', label: '总次数'),
              _StatColumn(
                  value: '$win', label: '胜利', color: AppColors.success),
              _StatColumn(
                  value: '$lose', label: '失败', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _StatColumn({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.orange,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
        ),
      ],
    );
  }
}

class _ChallengeRecordTile extends StatelessWidget {
  final ChallengeHistoryItem item;
  final String? currentUserId;

  const _ChallengeRecordTile({required this.item, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final result =
        currentUserId != null ? item.resultFor(currentUserId!) : 'draw';
    final opponent =
        currentUserId != null ? item.opponentName(currentUserId!) : '未知';

    Color resultColor;
    String resultText;
    IconData resultIcon;
    switch (result) {
      case 'win':
        resultColor = AppColors.success;
        resultText = '胜利';
        resultIcon = Icons.emoji_events;
      case 'lose':
        resultColor = AppColors.error;
        resultText = '失败';
        resultIcon = Icons.sentiment_dissatisfied;
      default:
        resultColor = context.textSecondary;
        resultText = '无胜负';
        resultIcon = Icons.sports;
    }

    final dateStr = item.completedAt != null
        ? '${item.completedAt!.month}月${item.completedAt!.day}日'
        : '${item.createdAt?.month ?? '-'}月${item.createdAt?.day ?? '-'}日';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(resultIcon, color: resultColor, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.routeName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  'VS $opponent · $dateStr',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              resultText,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: resultColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
