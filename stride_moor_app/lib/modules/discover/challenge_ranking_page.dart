import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

/// 挑战榜页面（排名榜）
class ChallengeRankingPage extends ConsumerWidget {
  const ChallengeRankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.challengeRanking),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.challengerRank),
              Tab(text: l10n.defenderRank),
            ],
            labelColor: AppColors.orange,
            unselectedLabelColor: context.textSecondary,
            indicatorColor: AppColors.orange,
          ),
        ),
        body: TabBarView(
          children: [
            _buildChallengerRank(context),
            _buildDefenderRank(context),
          ],
        ),
      ),
    );
  }

  /// 挑战者排名 Tab
  Widget _buildChallengerRank(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 10,
      itemBuilder: (context, index) {
        final data = _challengerData[index];
        final l10n = AppLocalizations.of(context);
        return _RankItem(
          rank: index + 1,
          name: data['name'] as String,
          avatar: data['avatar'] as String,
          primaryLabel: l10n.challengeCount,
          primaryValue: '${data['challenges']}',
          secondaryLabel: l10n.successCount,
          secondaryValue: '${data['success']}',
        );
      },
    );
  }

  /// 被挑战者排名 Tab
  Widget _buildDefenderRank(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 10,
      itemBuilder: (context, index) {
        final data = _defenderData[index];
        final l10n = AppLocalizations.of(context);
        return _RankItem(
          rank: index + 1,
          name: data['name'] as String,
          avatar: data['avatar'] as String,
          primaryLabel: l10n.defended,
          primaryValue: '${data['defended']}',
          secondaryLabel: l10n.defendSuccess,
          secondaryValue: '${data['success']}',
        );
      },
    );
  }
}

/// 排名列表项
class _RankItem extends StatelessWidget {
  final int rank;
  final String name;
  final String avatar;
  final String primaryLabel;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;

  const _RankItem({
    required this.rank,
    required this.name,
    required this.avatar,
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
  });

  @override
  Widget build(BuildContext context) {

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
          // 排名
          SizedBox(
            width: 36.w,
            child: _buildRankBadge(context, rank),
          ),
          SizedBox(width: 12.w),
          // 头像
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                avatar,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // 昵称
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 统计数据
          _buildStatColumn(context, primaryLabel, primaryValue),
          SizedBox(width: 20.w),
          _buildStatColumn(context, secondaryLabel, secondaryValue),
        ],
      ),
    );
  }

  Widget _buildRankBadge(BuildContext ctx, int rank) {
    Color bgColor;
    Color textColor = Colors.white;
    if (rank == 1) {
      bgColor = const Color(0xFFFFB800); // 金
    } else if (rank == 2) {
      bgColor = const Color(0xFFC0C0C0); // 银
    } else if (rank == 3) {
      bgColor = const Color(0xFFCD7F32); // 铜
    } else {
      bgColor = ctx.dividerColor;
      textColor = ctx.textSecondary;
    }

    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: rank <= 3 ? 14.sp : 12.sp,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext ctx, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.orange,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: ctx.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 挑战者排名模拟数据
final _challengerData = [
  {'name': '大衍神君', 'avatar': '大', 'challenges': 58, 'success': 49},
  {'name': '韩立', 'avatar': '韩', 'challenges': 52, 'success': 41},
  {'name': '南宫婉', 'avatar': '南', 'challenges': 47, 'success': 38},
  {'name': '厉飞雨', 'avatar': '厉', 'challenges': 43, 'success': 32},
  {'name': '墨大夫', 'avatar': '墨', 'challenges': 38, 'success': 28},
  {'name': '红拂', 'avatar': '红', 'challenges': 35, 'success': 26},
  {'name': '李化元', 'avatar': '李', 'challenges': 31, 'success': 22},
  {'name': '令狐老祖', 'avatar': '令', 'challenges': 28, 'success': 19},
  {'name': '云露老魔', 'avatar': '云', 'challenges': 25, 'success': 17},
  {'name': '合欢老魔', 'avatar': '合', 'challenges': 22, 'success': 14},
];

/// 被挑战者排名模拟数据
final _defenderData = [
  {'name': '南宫婉', 'avatar': '南', 'defended': 45, 'success': 40},
  {'name': '大衍神君', 'avatar': '大', 'defended': 42, 'success': 35},
  {'name': '韩立', 'avatar': '韩', 'defended': 38, 'success': 31},
  {'name': '红拂', 'avatar': '红', 'defended': 34, 'success': 29},
  {'name': '厉飞雨', 'avatar': '厉', 'defended': 30, 'success': 24},
  {'name': '墨大夫', 'avatar': '墨', 'defended': 27, 'success': 21},
  {'name': '李化元', 'avatar': '李', 'defended': 24, 'success': 19},
  {'name': '令狐老祖', 'avatar': '令', 'defended': 21, 'success': 16},
  {'name': '云露老魔', 'avatar': '云', 'defended': 18, 'success': 14},
  {'name': '合欢老魔', 'avatar': '合', 'defended': 15, 'success': 11},
];
