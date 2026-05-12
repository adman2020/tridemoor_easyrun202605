import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 伴跑模式规则说明页
class GhostModeRulesPage extends StatelessWidget {
  const GhostModeRulesPage({super.key});

  static const _rules = [
    _Rule(
      icon: Icons.replay,
      title: '真实回放',
      desc: '跑伴严格按原跑者的实际配速推进，全程复刻原跑者的节奏变化——哪里加速、哪里掉速、哪里缓一缓，全部忠实还原。',
      scenario: '体验朋友的真实跑法，学习节奏控制',
    ),
    _Rule(
      icon: Icons.speed,
      title: '匀速目标',
      desc: '跑伴以原跑者的平均配速匀速前进，不考虑原跑者的起伏快慢，只取全程平均配速做一条直线匀速推进。',
      scenario: '作为稳定目标，训练节奏一致性',
    ),
    _Rule(
      icon: Icons.directions_run,
      title: '兔子模式',
      desc: '跑伴比原跑者快5%，始终在前方引导。一个看得见但追不上的目标，让你不断突破自己的极限。',
      scenario: '冲击更好成绩，有目标感',
    ),
    _Rule(
      icon: Icons.swap_horiz,
      title: '龟兔模式',
      desc: '跑伴前半程比原跑者快（兔子），后半程比原跑者慢（乌龟），形成负分段节奏。前半程你要压住速度不被带快，后半程你有机会反超。',
      scenario: '练习负分段策略，前慢后快',
    ),
    _Rule(
      icon: Icons.track_changes,
      title: '目标挑战',
      desc: '选择挑战维度（配速/心率/步频/步幅），跑伴按该维度的对手水平推进。不比速度比技术——不同水平的跑者也能公平挑战。',
      scenario: '不只比速度，各维度公平竞技',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text('伴跑模式规则'),
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        children: [
          // 页面简介
          _buildIntroCard(),
          SizedBox(height: 24.h),
          // 5条规则
          for (int i = 0; i < _rules.length; i++) ...[
            _buildRuleCard(i, _rules[i]),
            if (i < _rules.length - 1) SizedBox(height: 16.h),
          ],
          SizedBox(height: 24.h),
          // 底部说明
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
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8533).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Icon(Icons.emoji_people, color: Color(0xFFFF8533), size: 18),
              ),
              SizedBox(width: 12.w),
              Text(
                '什么是伴跑？',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '从收藏跑迹中选择一条路线，点击"开始伴跑"，即可体验与原跑者的影子对决。'
            '地图上显示原跑者的"跑伴"标记，当您跑过某个位置时，跑伴也显示在该位置原跑者当时的状态，形成直观的视觉对比。',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13.sp,
              height: 1.6,
            ),
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
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 序号 + 标题行
          Row(
            children: [
              // 序号
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF8533),
                      const Color(0xFFFFAA66),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // 图标 + 标题
              Icon(rule.icon, color: const Color(0xFFFF8533), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                rule.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 定义描述
          Text(
            rule.desc,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.sp,
              height: 1.6,
            ),
          ),
          SizedBox(height: 8.h),
          // 适用场景标签
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8533).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, size: 12.sp, color: const Color(0xFFFFAA66)),
                SizedBox(width: 4.w),
                Text(
                  '适用：${rule.scenario}',
                  style: TextStyle(
                    color: const Color(0xFFFFAA66),
                    fontSize: 12.sp,
                  ),
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
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white38, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '多人影子：支持同时显示多个跑伴（多位朋友的同路线数据），每个人用不同颜色区分。可以和跑得最快的朋友比，也可以和水平接近的朋友比。',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12.sp,
                height: 1.5,
              ),
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
  final String scenario;

  const _Rule({
    required this.icon,
    required this.title,
    required this.desc,
    required this.scenario,
  });
}
