import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 挑战跑规则说明页
class ChallengeRulesPage extends StatelessWidget {
  const ChallengeRulesPage({super.key});

  static const _rules = [
    _Rule(
      icon: Icons.compare_arrows,
      title: '什么是挑战跑',
      desc: '挑战跑是两位跑者在同一条路线上进行的异步竞技。每人用各自的配速跑完同一段路线，系统自动比较成绩，决出胜负。双方不需要同时跑。',
    ),
    _Rule(
      icon: Icons.sports_score,
      title: '胜负判定',
      desc: '根据单次完成的成绩排名：先比成绩（跑完全程时间），成绩相同则比较消耗的卡路里。如果一方中途放弃或失败，另一方自动获胜。',
    ),
    _Rule(
      icon: Icons.how_to_vote,
      title: '发起挑战',
      desc: '选择一条公开路线，设定挑战参数（伴跑模式/目标维度），发布到路线广场。其他跑者可以在路线详情页看到并接受挑战。挑战略伴模式可选：真实回放、匀速目标、兔子模式、龟兔模式、目标挑战。',
    ),
    _Rule(
      icon: Icons.sync_alt,
      title: '接受挑战',
      desc: '在路线广场或跑友详情页面，找到感兴趣的挑战，点击"接受"。系统会自动记录你的跑步数据，完成路线后与发起者进行对比。',
    ),
    _Rule(
      icon: Icons.emoji_events_outlined,
      title: '挑战奖励',
      desc: '挑战胜利可获得：经验值提升、赢取跑境所需的挑战胜利次数（晋升必要条件）、在个人页面展示挑战记录。',
    ),
    _Rule(
      icon: Icons.track_changes,
      title: '目标挑战模式',
      desc: '选择挑战维度（配速/心率/步频/步幅），跑伴按该维度的对手水平推进。不比速度比技术——不同水平的跑者也能公平竞技。',
    ),
    _Rule(
      icon: Icons.group,
      title: '公平竞技',
      desc: '系统会根据路线距离自动匹配相近水平的挑战。挑战胜利次数计入跑境晋升系统，是突破中高阶境界的关键条件之一。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text('挑战跑规则'),
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        children: [
          _buildIntroCard(),
          SizedBox(height: 24.h),
          for (int i = 0; i < _rules.length; i++) ...[
            _buildRuleCard(i, _rules[i]),
            if (i < _rules.length - 1) SizedBox(height: 14.h),
          ],
          SizedBox(height: 24.h),
          _buildFooter(),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFF8533).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: const Color(0xFFFF8533), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                '挑战跑',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            '和路线上的其他跑者异步竞技——用实力证明自己。'
            '不需要同时跑步，选同一条路线，完成即出成绩。',
            style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(int index, _Rule rule) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF2A2A2D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8533).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Icon(rule.icon, color: const Color(0xFFFF8533), size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  rule.desc,
                  style: TextStyle(color: Colors.white54, fontSize: 12.sp, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8533).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: const Color(0xFFFF8533), size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '挑战跑数据自动记录，无需手动上传。完成后可在"挑战记录"页面查看历史战绩。',
              style: TextStyle(color: Colors.white60, fontSize: 12.sp, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule {
  final IconData icon;
  final String title;
  final String desc;
  const _Rule({required this.icon, required this.title, required this.desc});
}
