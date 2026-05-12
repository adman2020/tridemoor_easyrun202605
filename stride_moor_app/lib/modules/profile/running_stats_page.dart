import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

/// 跑步统计页 —— 周/月/年汇总
class RunningStatsPage extends ConsumerWidget {
  const RunningStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.runningStats),
          bottom: const TabBar(
            tabs: [
              Tab(text: '周'),
              Tab(text: '月'),
              Tab(text: '年'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStatsView(context, l10n, '本周'),
            _buildStatsView(context, l10n, '本月'),
            _buildStatsView(context, l10n, '本年'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsView(BuildContext context, AppLocalizations l10n, String period) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(color: context.dividerColor),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(label: l10n.totalDistance, value: '32.5', unit: l10n.km),
                  _StatBox(label: l10n.totalRuns, value: '5', unit: l10n.times),
                  _StatBox(label: l10n.pace, value: '6:08', unit: '/km'),
                  _StatBox(label: 'PB', value: '5:30', unit: '/km'),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text('$period跑量趋势', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.dividerColor),
            ),
            alignment: Alignment.center,
            child: Text('柱状图组件', style: TextStyle(color: context.textTertiary)),
          ),
          SizedBox(height: 24.h),
          Text('配速变化', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.dividerColor),
            ),
            alignment: Alignment.center,
            child: Text('折线图组件', style: TextStyle(color: context.textTertiary)),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatBox({required this.label, required this.value, required this.unit});

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
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.orange),
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
