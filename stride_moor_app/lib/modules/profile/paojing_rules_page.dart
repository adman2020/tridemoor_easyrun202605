import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 跑境晋升规则说明页
class PaojingRulesPage extends StatelessWidget {
  const PaojingRulesPage({super.key});

  static const _realmOrder = ['气', '筑', '丹', '婴', '化', '虚', '合', '乘', '真', '金', '太', '罗', '道'];
  static const _realmNames = [
    '气引勋章', '筑仙勋章', '丹凝勋章', '婴生勋章',
    '化神勋章', '炼虚勋章', '合元勋章', '大乘勋章',
    '真仙勋章', '金仙勋章', '太乙勋章', '大罗勋章', '道祖勋章',
  ];
  static const _realmDescriptions = [
    '初入跑境，注册即入。无门槛，开始即是第一步。',
    '完成单次5km跑步，并完成1次伴跑。迈向修行之路。',
    '完成单次10km跑步，并赢得2次挑战跑。凝结道心。',
    '完成半程马拉松（21.0975km），并赢得5次挑战跑。元神初成。',
    '完成全程马拉松（42.195km），并发1条动态。化神大成。',
    '全程马拉松 3小时内（≤3:00），并发1条动态。炼虚合道。',
    '全程马拉松 2小时45分内（≤2:45），并发1条动态。天地合元。',
    '全程马拉松 2小时30分内（≤2:30），并发1条动态。功成大乘。',
    '全程马拉松 2小时20分内（≤2:20），并发1条动态。超凡入仙。',
    '全程马拉松 2小时15分内（≤2:15），并发1条动态。金仙之体。',
    '全程马拉松 2小时10分内（≤2:10），并发1条动态。太乙真人。',
    '全程马拉松 2小时05分内（≤2:05），并发1条动态。大罗金仙。',
    '全程马拉松 2小时内（<2:00），并发1条动态。万法道祖。',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text('跑境晋升规则'),
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        children: [
          _buildIntroCard(),
          SizedBox(height: 24.h),
          for (int i = 0; i < _realmOrder.length; i++) ...[
            _buildRealmCard(i),
            if (i < _realmOrder.length - 1) SizedBox(height: 12.h),
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
              Icon(Icons.auto_awesome, color: const Color(0xFFFF8533), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                '十三境道',
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
            '跑境共分十三重境界——从炼气到道祖，每晋升一境，获得相应勋章。'
            '低阶境界靠跑量积累和完成挑战/伴跑突破，高阶境界需要全程马拉松时间和实力的证明。',
            style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRealmCard(int index) {
    final isEarned = index == 0; // 第一境已获得
    final color = index < 4
        ? const Color(0xFF4CAF50)
        : index < 8
            ? const Color(0xFF2196F3)
            : const Color(0xFFFF9800);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isEarned ? color.withValues(alpha: 0.3) : const Color(0xFF2A2A2D),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 境界字
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: isEarned ? color.withValues(alpha: 0.15) : const Color(0xFF2A2A2D),
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Text(
              _realmOrder[index],
              style: TextStyle(
                color: isEarned ? color : Colors.white38,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _realmNames[index],
                      style: TextStyle(
                        color: isEarned ? color : Colors.white54,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '第${index + 1}境',
                        style: TextStyle(color: Colors.white38, fontSize: 10.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  _realmDescriptions[index],
                  style: TextStyle(color: Colors.white54, fontSize: 12.sp, height: 1.4),
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
              '跑境晋升由系统根据跑步记录自动判定，达标后自动颁发勋章并发送动态。',
              style: TextStyle(color: Colors.white60, fontSize: 12.sp, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
