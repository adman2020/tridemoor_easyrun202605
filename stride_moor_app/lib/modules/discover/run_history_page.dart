import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/run_provider.dart';
import '../../l10n/app_localizations.dart';

/// 运动记录页 —— 个人所有跑步记录列表
/// 数据源与发现页共用 recentRunsProvider，保持一致
class RunHistoryPage extends ConsumerStatefulWidget {
  const RunHistoryPage({super.key});

  @override
  ConsumerState<RunHistoryPage> createState() => _RunHistoryPageState();
}

class _RunHistoryPageState extends ConsumerState<RunHistoryPage> {
  bool _cleaning = false;
  int? _deletedCount;

  @override
  void initState() {
    super.initState();
    // 自动清理已由后端定时任务（每日凌晨3:00）处理，此处不再重复调用
  }

  Future<void> _cleanZeroRuns() async {
    if (_cleaning) return;
    setState(() => _cleaning = true);
    _deletedCount = null;
    try {
      final api = ref.read(apiServiceProvider);

      // 先尝试后端批量清理接口
      try {
        final resp = await api.cleanZeroRuns();
        if (resp.isSuccess && resp.data != null) {
          final count = resp.data!['deleted_count'] as int? ?? 0;
          if (count > 0) {
            setState(() => _deletedCount = count);
            ref.invalidate(runHistoryProvider);
            ref.invalidate(recentRunsProvider);
            return;
          }
        }
      } catch (_) {
        debugPrint('⚠️ 批量清理接口不可用，逐个删除');
      }

      // 回退：逐条获取列表，删除距离为 0 的记录
      final listResp = await api.getRunList(page: 1, pageSize: 100);
      if (listResp.isSuccess && listResp.data != null) {
        final list = listResp.data!['list'] as List<dynamic>? ?? [];
        int deleted = 0;
        for (final item in list) {
          final run = item as Map<String, dynamic>;
          final dist = (run['total_distance'] as num?)?.toDouble() ?? 0;
          final runId = run['id'] as String?;
          if (dist < 10 && runId != null) {
            try {
              await api.deleteRun(runId);
              deleted++;
            } catch (e) {
              debugPrint('⚠️ 删除记录 $runId 失败: $e');
            }
          }
        }
        if (deleted > 0) {
          setState(() => _deletedCount = deleted);
          ref.invalidate(runHistoryProvider);
          ref.invalidate(recentRunsProvider);
        }
      }
    } catch (e) {
      debugPrint('⚠️ 清理 0.0KM 记录失败: $e');
    } finally {
      setState(() => _cleaning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final runsAsync = ref.watch(runHistoryProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(l10n.runHistory),
        actions: [
          if (_deletedCount != null && _deletedCount! > 0)
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Text(
                  '已清理 $_deletedCount 条无效记录',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.orange),
                ),
              ),
            ),
          IconButton(
            icon: _cleaning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cleaning_services_outlined),
            tooltip: '清理 0.0KM 记录',
            onPressed: _cleaning ? null : _cleanZeroRuns,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: runsAsync.when(
        data: (runs) {
          if (runs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_run, size: 64.sp, color: context.textTertiary),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.noRunRecord,
                    style: TextStyle(fontSize: 15.sp, color: context.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: runs.length,
            itemBuilder: (context, index) {
              final run = runs[index];
              return _RunHistoryCard(run: run);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.orange)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: context.textTertiary),
              SizedBox(height: 12.h),
              Text(
                '${l10n.loadFailed}: $err',
                style: TextStyle(fontSize: 13.sp, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunHistoryCard extends StatelessWidget {
  final dynamic run; // Run model

  const _RunHistoryCard({required this.run});

  String _formatPace(int? paceSecondsPerKm) {
    if (paceSecondsPerKm == null || paceSecondsPerKm <= 0) return '--';
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date, BuildContext ctx) {
    // startTime 已由 fromJson 从 ISO 字符串提取纯日期，不依赖时区
    return DateFormat.yMMMd(Localizations.localeOf(ctx).languageCode).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final distanceKm = (run.totalDistance as num) / 1000;
    final durationSec = run.totalTime as int? ?? 0;
    final pace = run.avgPace as int?;

    return InkWell(
      onTap: () => context.push('/run/${run.id}'),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: run.mode == 'companion'
                    ? const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF30B650)])
                    : run.mode == 'challenge'
                        ? const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF4500)])
                        : const LinearGradient(colors: [AppColors.orange, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: run.mode == 'companion'
                  ? SizedBox(
                      width: 32.w,
                      height: 32.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_run, size: 18.w, color: Colors.white),
                          Icon(Icons.directions_run, size: 18.w, color: Colors.white),
                        ],
                      ),
                    )
                  : run.mode == 'challenge'
                      ? SizedBox(
                          width: 28.w,
                          height: 32.w,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(bottom: 0, left: 2.w, child: Icon(Icons.directions_run, size: 24.w, color: Colors.white)),
                              Positioned(top: -2.w, left: 6.w, child: Icon(Icons.emoji_events, size: 12.w, color: const Color(0xFFFFD700))),
                            ],
                          ),
                        )
                      : Icon(Icons.directions_run, size: 24.w, color: Colors.white),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDate(run.startTime as DateTime, context),
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimary),
                      ),
                      if (run.mode == 'companion')
                        Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text('伴跑', style: TextStyle(fontSize: 10.sp, color: Color(0xFF34C759))),
                          ),
                        ),
                      if (run.mode == 'challenge')
                        Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text('挑战', style: TextStyle(fontSize: 10.sp, color: Color(0xFFFF6B35))),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${distanceKm.toStringAsFixed(1)}km · ${_formatPace(pace)}${l10n.pace} · ${_formatDuration(durationSec)}${l10n.min}',
                    style: TextStyle(fontSize: 13.sp, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textTertiary),
          ],
        ),
      ),
    );
  }
}
