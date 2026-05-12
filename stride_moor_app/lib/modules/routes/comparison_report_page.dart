import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/theme.dart';
import '../../core/models/run.dart';
import '../../l10n/app_localizations.dart';

/// 伴跑PK页 —— 跑完后多维对比 + 智能诊断
class ComparisonReportPage extends ConsumerWidget {
  final Run? runA;
  final Run? runB;

  const ComparisonReportPage({super.key, this.runA, this.runB});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('伴跑PK')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOpponentHeader(context, l10n),
            SizedBox(height: 24.h),
            _buildCoreComparison(context, l10n),
            SizedBox(height: 24.h),
            _buildSplitComparison(context, l10n),
            SizedBox(height: 24.h),
            _buildDiagnosis(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildOpponentHeader(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: context.dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32.r,
                    backgroundColor: AppColors.orange.withValues(alpha: 0.1),
                    child: Text('我', style: TextStyle(fontSize: 18.sp, color: AppColors.orange, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 8.h),
                  Text('我', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.orange),
                  ),
                ),
                SizedBox(height: 4.h),
                Text('本次伴跑', style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32.r,
                    backgroundColor: AppColors.orange.withValues(alpha: 0.1),
                    child: Text('衍', style: TextStyle(fontSize: 18.sp, color: AppColors.orange, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 8.h),
                  Text('大衍神君', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreComparison(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: context.dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PK数据',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            SizedBox(height: 16.h),
            _ComparisonRow(label: '平均配速', me: '6:11', opponent: '6:05', better: 'opponent'),
            Divider(height: 24.h),
            _ComparisonRow(label: '平均心率', me: '152', opponent: '148', better: 'opponent'),
            Divider(height: 24.h),
            _ComparisonRow(label: '平均步幅', me: '1.05m', opponent: '1.12m', better: 'opponent'),
            Divider(height: 24.h),
            _ComparisonRow(label: '平均步频', me: '172', opponent: '168', better: 'me'),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitComparison(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: context.dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分段配速对比',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            SizedBox(height: 16.h),
            ...List.generate(5, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    SizedBox(width: 40.w, child: Text('${i + 1}km', style: TextStyle(fontSize: 13.sp, color: context.textSecondary))),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 24.h,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          Container(
                            height: 24.h,
                            width: (0.3 + i * 0.1) * 100.w,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text('6:0${i + 1}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosis(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: context.dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '智能诊断',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            SizedBox(height: 16.h),
            _DiagnosisItem(
              icon: Icons.check_circle,
              color: AppColors.success,
              title: l10n.advantage,
              content: '前5km配速稳定，节奏控制好；步频保持170+，跑步效率高。',
            ),
            SizedBox(height: 16.h),
            _DiagnosisItem(
              icon: Icons.warning,
              color: AppColors.warning,
              title: l10n.improvement,
              content: '第6-8km步频从172降到158，可能疲劳导致步幅放大。建议：后半程主动缩小步幅，维持高步频。',
            ),
            SizedBox(height: 16.h),
            _DiagnosisItem(
              icon: Icons.emoji_events,
              color: AppColors.orange,
              title: l10n.nextGoal,
              content: '保持前5km节奏；6km后步频不低于165；上坡配速衰减控制在30秒以内。',
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String me;
  final String opponent;
  final String better;

  const _ComparisonRow({
    required this.label,
    required this.me,
    required this.opponent,
    required this.better,
  });

  @override
  Widget build(BuildContext context) {







    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              me,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: better == 'me' ? FontWeight.bold : FontWeight.normal,
                color: better == 'me' ? AppColors.success : context.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: context.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              opponent,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: better == 'opponent' ? FontWeight.bold : FontWeight.normal,
                color: better == 'opponent' ? AppColors.success : context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String content;

  const _DiagnosisItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {







    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: color)),
              SizedBox(height: 4.h),
              Text(content, style: TextStyle(fontSize: 13.sp, color: context.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
