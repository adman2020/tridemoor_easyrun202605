import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';
import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';

import '../../config/theme.dart';
import '../../core/models/run.dart';
import '../../core/models/run_split.dart';
import '../../core/models/user.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/run_provider.dart';
import '../../core/providers/route_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/amap_map_view.dart';

/// 跑步详情页 —— 单次跑步完整数据
class RunDetailPage extends ConsumerWidget {
  final String runId;

  const RunDetailPage({super.key, required this.runId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runAsync = ref.watch(runDetailProvider(runId));

    return runAsync.when(
      data: (run) => Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          title: Text(l10n.runDetail),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: '发跑友动态',
              onPressed: () => _showSharePostDialog(context, ref, l10n, run),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              tooltip: '收藏我的跑迹',
              onPressed: () => _showSaveRouteDialog(context, ref, l10n, run),
            ),
          ],
        ),
        body: _buildContent(context, ref, l10n, run),
      ),
      loading: () => Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          title: Text(l10n.runDetail),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          title: Text(l10n.runDetail),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
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

  void _showSaveRouteDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n, Run run) {
    final nameController = TextEditingController(
      text: '我的路迹 ${_formatDate(run.startTime)}',
    );
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgColor,
        title: const Text('收藏我的跑迹', style: TextStyle(color: Colors.white)),
        actionsAlignment: MainAxisAlignment.center,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                labelText: '路迹名称',
                labelStyle: TextStyle(color: context.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.dividerColor)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.pace)),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: descController,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                labelText: '描述（可选）',
                labelStyle: TextStyle(color: context.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.dividerColor)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.pace)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: context.textSecondary)),
          ),
          SizedBox(width: 12.w),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请输入路迹名称')),
                );
                return;
              }
              final validSamples = run.samples
                  .where((s) => s.latitude.abs() <= 90 && s.longitude.abs() <= 180 && s.latitude.isFinite && s.longitude.isFinite)
                  .toList();
              if (validSamples.length < 2) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('轨迹点不足，无法收藏为跑迹')),
                );
                return;
              }
              Navigator.of(ctx).pop();

              final api = ref.read(apiServiceProvider);
              final points = validSamples.map((s) => {
                'latitude': s.latitude,
                'longitude': s.longitude,
                if (s.altitude != null) 'altitude': s.altitude,
              }).toList();

              final startPoint = validSamples.first;
              final centerLat = validSamples.map((s) => s.latitude).reduce((a, b) => a + b) / validSamples.length;
              final centerLng = validSamples.map((s) => s.longitude).reduce((a, b) => a + b) / validSamples.length;

              final data = {
                'name': name,
                if (descController.text.trim().isNotEmpty) 'description': descController.text.trim(),
                'distance': run.totalDistance,
                'elevation_gain': run.elevationGain,
                'elevation_loss': run.elevationLoss,
                'avg_pace': run.avgPace ?? 0,
                'avg_cadence': run.avgCadence ?? 0,
                'avg_stride': run.avgStrideLength ?? 0.0,
                'calories': run.calories ?? 0,
                'avg_heart_rate': run.avgHeartRate ?? 0,
                'total_time': run.totalTime ?? 0,
                'max_heart_rate': run.maxHeartRate ?? 0,
                'max_cadence': run.maxCadence ?? 0,
                'points': points,
                'start_lat': startPoint.latitude,
                'start_lng': startPoint.longitude,
                'center_lat': centerLat,
                'center_lng': centerLng,
              };

              try {
                final response = await api.createRoute(data);
                if (response.isSuccess) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已收藏到"我的跑迹"')),
                    );
                  }
                  ref.invalidate(myRoutesProvider);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('收藏失败: ${response.message}')),
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pace),
            child: Text(l10n.confirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSharePostDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n, Run run) {
    final contentController = TextEditingController(
      text: '刚刚完成了一次 ${(run.totalDistance / 1000).toStringAsFixed(2)} 公里的跑步，用时 ${_formatTime(run.totalTime)}，配速 ${run.avgPace != null && run.avgPace! > 0 ? _formatPace(run.avgPace!) : '--'}。',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgColor,
        title: const Text('发跑友动态', style: TextStyle(color: Colors.white)),
        actionsAlignment: MainAxisAlignment.center,
        content: TextField(
          controller: contentController,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            labelText: '动态描述',
            labelStyle: TextStyle(color: context.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.dividerColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.pace)),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: context.textSecondary)),
          ),
          SizedBox(width: 12.w),
          ElevatedButton(
            onPressed: () async {
              final content = contentController.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请输入动态描述')),
                );
                return;
              }
              Navigator.of(ctx).pop();

              final api = ref.read(apiServiceProvider);
              try {
                final response = await api.createPost(content: content, runId: run.id);
                if (response.isSuccess) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已分享到跑友动态')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('分享失败: ${response.message}')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('分享失败: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pace),
            child: Text(l10n.confirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAIAnalysis(BuildContext context, WidgetRef ref, Run run) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AIAnalysisSheet(runId: run.id),
    );
  }

  /// AI 跑情分析按钮 —— 所有用户可用
  Widget _buildAIVipButton(BuildContext context, WidgetRef ref, Run run) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _showAIAnalysis(context, ref, run),
          icon: Icon(Icons.auto_awesome, size: 16.sp),
          label: Text('AI 跑情分析', style: TextStyle(fontSize: 13.sp)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            padding: EdgeInsets.symmetric(vertical: 10.h),
          ),
        ),
      ),
    );
  }

  /// 显示升级 VIP 弹窗
  void _showUpgradeVipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgColor,
        title: Row(
          children: [
            Icon(Icons.star, color: AppColors.orange, size: 24.sp),
            SizedBox(width: 8.w),
            Text('开通VIP', style: TextStyle(color: AppColors.orange)),
          ],
        ),
        content: Text(
          'AI 跑情分析是VIP专属功能，开通后可享受：\n\n✅ AI 智能跑情分析\n✅ 更多路面类型建议\n✅ 天气差异化提醒\n\n· · · ·\n\n敬请期待！',
          style: TextStyle(color: context.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('知道了', style: TextStyle(color: context.textSecondary)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // date 已由 fromJson 从 ISO 字符串提取纯日期，不依赖时区
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AppLocalizations l10n, Run run) {
    final distanceKm = run.totalDistance / 1000;
    final duration = run.totalTime;
    final avgPace = run.avgPace;

    return SingleChildScrollView(
      child: Column(
        children: [
          // GPS 轨迹地图
          SizedBox(
            height: 240.h,
            child: _buildMap(context, run),
          ),

          // 核心数据
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DataItem(
                  label: l10n.distance,
                  value: distanceKm.toStringAsFixed(2),
                  unit: l10n.km,
                  color: AppColors.pace,
                ),
                _DataItem(
                  label: l10n.duration,
                  value: _formatTime(duration),
                  unit: '',
                  color: context.textPrimary,
                ),
                _DataItem(
                  label: l10n.pace,
                  value: avgPace != null && avgPace > 0 ? _formatPace(avgPace) : '--',
                  unit: '/km',
                  color: AppColors.pace,
                ),
              ],
            ),
          ),

          // 操作按钮：分享 / 收藏
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSharePostDialog(context, ref, l10n, run),
                    icon: Icon(Icons.share_outlined, size: 16.sp, color: AppColors.orange),
                    label: Text('发跑友动态', style: TextStyle(fontSize: 13.sp, color: AppColors.orange)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.orange.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSaveRouteDialog(context, ref, l10n, run),
                    icon: Icon(Icons.bookmark_border, size: 16.sp, color: AppColors.orange),
                    label: Text('收藏我的跑迹', style: TextStyle(fontSize: 13.sp, color: AppColors.orange)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.orange.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10.h),

          // AI 跑情分析按钮（所有用户可用）
          _buildAIVipButton(context, ref, run),

          const Divider(),

          // 详细数据
          _buildDetailSection(context, l10n, run),

          // 分段配速
          if (run.splits.isNotEmpty) _buildSplitsSection(context, l10n, run),

          // 伴跑/挑战对比
          if (run.opponentRun != null)
            _buildComparisonSection(context, l10n, run, run.opponentRun!, goalMetric: run.goalMetric),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context, Run run) {
    // 过滤有效坐标
    final trackPoints = run.samples
        .where((s) {
          return s.latitude.abs() <= 90 &&
              s.longitude.abs() <= 180 &&
              s.latitude.isFinite &&
              s.longitude.isFinite;
        })
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    // 对手轨迹
    final opponentPoints = run.opponentSamples
        .where((s) {
          return s.latitude.abs() <= 90 &&
              s.longitude.abs() <= 180 &&
              s.latitude.isFinite &&
              s.longitude.isFinite;
        })
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    if (trackPoints.isEmpty && opponentPoints.isEmpty) {
      return _buildMapPlaceholder(context);
    }

    // 是否伴跑（非挑战），使用幻影样式
    final isCompanion = run.mode == 'companion';

    final polylines = <Polyline>{};
    if (trackPoints.length >= 2) {
      polylines.add(buildTrackPolyline(trackPoints));
    }
    if (opponentPoints.length >= 2) {
      polylines.add(buildTrackPolyline(
        opponentPoints,
        color: isCompanion
            ? context.textSecondary.withValues(alpha: 0.25)
            : context.textSecondary.withValues(alpha: 0.5),
        width: isCompanion ? 2.5 : 3,
      ));
    }

    return Stack(
      children: [
        AmapMapView(
          initialCameraPosition: CameraPosition(
            target: trackPoints.isNotEmpty ? trackPoints.first : opponentPoints.first,
            zoom: 15,
          ),
          polylines: polylines,
        ),
        // 地图图例
        Positioned(
          left: 12.w,
          top: 12.h,
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: context.surfaceColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendItem(color: AppColors.orange, label: '我的轨迹'),
                SizedBox(height: 4.h),
                _LegendItem(
                  color: isCompanion
                      ? context.textSecondary.withValues(alpha: 0.4)
                      : context.textSecondary.withValues(alpha: 0.6),
                  label: isCompanion ? '🫧 幻影伴侣' : '对手轨迹',
                  dashed: isCompanion,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder(BuildContext context) {
    return Container(
      color: context.surfaceElevatedColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 48.sp, color: context.textTertiary),
          SizedBox(height: 8.h),
          Text('轨迹地图', style: TextStyle(color: context.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, AppLocalizations l10n, Run run) {
    final chips = <Widget>[];

    if (run.avgHeartRate != null && run.avgHeartRate! > 0) {
      chips.add(_DetailChip(
        icon: Icons.favorite,
        label: l10n.heartRate,
        value: '${run.avgHeartRate} bpm',
        color: AppColors.heartRate,
      ));
    }
    if (run.avgCadence != null && run.avgCadence! > 0) {
      chips.add(_DetailChip(
        icon: Icons.sync,
        label: l10n.cadence,
        value: '${run.avgCadence} spm',
        color: AppColors.cadence,
      ));
    }
    if (run.avgStrideLength != null && run.avgStrideLength! > 0) {
      chips.add(_DetailChip(
        icon: Icons.expand,
        label: l10n.strideLength,
        value: '${run.avgStrideLength!.toStringAsFixed(2)} m',
        color: AppColors.stride,
      ));
    }
    if (run.elevationGain > 0) {
      chips.add(_DetailChip(
        icon: Icons.terrain,
        label: l10n.elevation,
        value: '${run.elevationGain.toStringAsFixed(0)} m',
        color: AppColors.elevation,
      ));
    }
    if (run.calories != null && run.calories! > 0) {
      chips.add(_DetailChip(
        icon: Icons.local_fire_department,
        label: l10n.calories,
        value: '${run.calories} kcal',
        color: AppColors.orange,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.details, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.textPrimary)),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: chips,
          ),
        ],
      ),
    );
  }

  Widget _buildSplitsSection(BuildContext context, AppLocalizations l10n, Run run) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.splitPace, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.textPrimary)),
          SizedBox(height: 12.h),
          ...run.splits.map((split) => _SplitRow(
                index: split.splitIndex + 1,
                pace: (split.pace ?? 0) > 0 ? _formatPace(split.pace!) : '--',
              )),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(BuildContext context, AppLocalizations l10n, Run myRun, Run opponentRun, {String? goalMetric}) {
    // 按 split_index 对齐两个人的分段数据
    final mySplits = myRun.splits;
    final oppSplits = opponentRun.splits;
    final maxSplits = mySplits.length > oppSplits.length ? mySplits.length : oppSplits.length;

    if (maxSplits == 0) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Text('暂无分段对比数据', style: TextStyle(color: context.textSecondary)),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.comparisonPK, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.textPrimary)),
              if (goalMetric != null) ...[              
                SizedBox(width: 8.w),
                _ChallengeMetricBadge(metric: goalMetric),
              ],
            ],
          ),
          SizedBox(height: 4.h),
          // 模式副标题
          Text(
            myRun.mode == 'companion'
                ? '🫧 跟随幻影，同步奔跑'
                : goalMetric != null
                    ? '🎯 比拼指标见上方标签，其余指标仅供参考'
                    : '📊 分段对比',
            style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
          ),
          SizedBox(height: 12.h),
          // 挑战跑：总体指标胜负卡片
          if (goalMetric != null) _buildGoalMetricOverallCard(context, myRun, opponentRun, goalMetric),
          // 表头
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: context.surfaceElevatedColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                SizedBox(width: 50.w, child: Text('公里', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondary))),
                Expanded(child: Text('我', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.orange))),
                Expanded(child: Text('对手', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondary))),
              ],
            ),
          ),
          // 数据行
          ...List.generate(maxSplits, (i) {
            final mySplit = i < mySplits.length ? mySplits[i] : null;
            final oppSplit = i < oppSplits.length ? oppSplits[i] : null;
            return _ComparisonSplitRow(
              index: i + 1,
              mySplit: mySplit,
              oppSplit: oppSplit,
              goalMetric: goalMetric,
            );
          }),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  /// 挑战跑总体指标胜负卡片
  Widget _buildGoalMetricOverallCard(BuildContext context, Run myRun, Run opponentRun, String goalMetric) {
    // 从总数据提取
    final (myTotal, oppTotal) = _extractOverallMetric(myRun, opponentRun, goalMetric);
    final lowerIsBetter = goalMetric == 'pace' || goalMetric == 'heart_rate';
    String? winner;
    if (myTotal != null && oppTotal != null) {
      if (lowerIsBetter) {
        winner = myTotal < oppTotal ? 'me' : (myTotal > oppTotal ? 'opponent' : null);
      } else {
        winner = myTotal > oppTotal ? 'me' : (myTotal < oppTotal ? 'opponent' : null);
      }
    }

    final (metricLabel, _) = _ChallengeMetricBadge._metricInfo(goalMetric);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: winner == 'me'
            ? AppColors.success.withValues(alpha: 0.1)
            : winner == 'opponent'
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: winner == 'me'
              ? AppColors.success.withValues(alpha: 0.3)
              : winner == 'opponent'
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('比拼 ', style: TextStyle(fontSize: 13.sp, color: context.textSecondary)),
              Icon(Icons.emoji_events, size: 16.sp, color: AppColors.orange),
              SizedBox(width: 4.w),
              Text(metricLabel, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.orange)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverallMetricValue(context, '我', myTotal, goalMetric, winner == 'me'),
              Text('VS', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.textSecondary)),
              _buildOverallMetricValue(context, '对手', oppTotal, goalMetric, winner == 'opponent'),
            ],
          ),
          if (winner != null) ...[   
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: winner == 'me'
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                winner == 'me' ? '🏆 你赢了！' : '🏆 对手领先',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: winner == 'me' ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 提取某项指标的总体数值
  (num?, num?) _extractOverallMetric(Run myRun, Run oppRun, String metric) {
    switch (metric) {
      case 'pace':
        // 配速越低越好：取平均配速
        return (myRun.avgPace, oppRun.avgPace);
      case 'heart_rate':
        // 心率取平均值，越低越好
        final myHr = myRun.splits.where((s) => s.avgHeartRate != null).map((s) => s.avgHeartRate!).toList();
        final oppHr = oppRun.splits.where((s) => s.avgHeartRate != null).map((s) => s.avgHeartRate!).toList();
        return (myHr.isEmpty ? null : myHr.reduce((a, b) => a + b) ~/ myHr.length,
                oppHr.isEmpty ? null : oppHr.reduce((a, b) => a + b) ~/ oppHr.length);
      case 'cadence':
        final myCad = myRun.splits.where((s) => s.avgCadence != null).map((s) => s.avgCadence!).toList();
        final oppCad = oppRun.splits.where((s) => s.avgCadence != null).map((s) => s.avgCadence!).toList();
        return (myCad.isEmpty ? null : myCad.reduce((a, b) => a + b) ~/ myCad.length,
                oppCad.isEmpty ? null : oppCad.reduce((a, b) => a + b) ~/ oppCad.length);
      case 'stride':
      case 'stride_length':
        final myStr = myRun.splits.where((s) => s.avgStrideLength != null).map((s) => s.avgStrideLength!).toList();
        final oppStr = oppRun.splits.where((s) => s.avgStrideLength != null).map((s) => s.avgStrideLength!).toList();
        return (myStr.isEmpty ? null : myStr.reduce((a, b) => a + b) / myStr.length,
                oppStr.isEmpty ? null : oppStr.reduce((a, b) => a + b) / oppStr.length);
      default:
        return (null, null);
    }
  }

  Widget _buildOverallMetricValue(BuildContext context, String label, num? value, String metric, bool isWinner) {
    final (_, icon) = _ChallengeMetricBadge._metricInfo(metric);
    final valueStr = value != null
        ? metric == 'pace'
            ? _formatPace(value.toInt())
            : metric == 'stride' || metric == 'stride_length'
                ? value.toStringAsFixed(2)
                : value.toStringAsFixed(0)
        : '--';
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
        SizedBox(height: 4.h),
        Icon(icon, size: 20.sp, color: isWinner ? AppColors.success : context.textSecondary),
        SizedBox(height: 2.h),
        Text(valueStr, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isWinner ? AppColors.success : context.textPrimary)),
      ],
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(int paceSecondsPerKm) {
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }
}

/// 挑战跑指标徽章
class _ChallengeMetricBadge extends StatelessWidget {
  final String metric;

  const _ChallengeMetricBadge({required this.metric});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = _metricInfo(metric);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.orange),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.orange)),
          SizedBox(width: 4.w),
          Icon(Icons.emoji_events, size: 14.sp, color: AppColors.orange),
        ],
      ),
    );
  }

  static (String, IconData) _metricInfo(String metric) {
    switch (metric) {
      case 'pace':
        return ('配速', Icons.speed);
      case 'heart_rate':
        return ('心率', Icons.favorite);
      case 'cadence':
        return ('步频', Icons.directions_run);
      case 'stride':
      case 'stride_length':
        return ('步幅', Icons.straighten);
      case 'distance':
        return ('距离', Icons.straighten);
      default:
        return (metric, Icons.flag);
    }
  }
}

/// 地图图例项
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16.w,
          height: dashed ? 1.h : 3.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(fontSize: 11.sp, color: context.textSecondary)),
      ],
    );
  }
}

class _DataItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _DataItem({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: color)),
              TextSpan(text: ' $unit', style: TextStyle(fontSize: 14.sp, color: context.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Text('$label $value', style: TextStyle(fontSize: 13.sp, color: color)),
        ],
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  final int index;
  final String pace;

  const _SplitRow({required this.index, required this.pace});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          SizedBox(
            width: 50.w,
            child: Text('第$index公里', style: TextStyle(fontSize: 13.sp, color: context.textSecondary)),
          ),
          Expanded(child: Container()),
          Text(pace, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: context.textPrimary)),
        ],
      ),
    );
  }
}

class _ComparisonSplitRow extends StatelessWidget {
  final int index;
  final RunSplit? mySplit;
  final RunSplit? oppSplit;
  final String? goalMetric;

  const _ComparisonSplitRow({
    required this.index,
    this.mySplit,
    this.oppSplit,
    this.goalMetric,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 公里标识
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text('$index km', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.orange)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // 四个维度对比
          _MetricRow(label: l10n.pace, myValue: _formatPace(mySplit?.pace), oppValue: _formatPace(oppSplit?.pace), lowerIsBetter: true, isGoal: goalMetric == 'pace'),
          _MetricRow(label: l10n.cadence, myValue: _formatInt(mySplit?.avgCadence), oppValue: _formatInt(oppSplit?.avgCadence), lowerIsBetter: false, isGoal: goalMetric == 'cadence'),
          _MetricRow(label: l10n.strideLength, myValue: _formatDouble(mySplit?.avgStrideLength), oppValue: _formatDouble(oppSplit?.avgStrideLength), lowerIsBetter: false, isGoal: goalMetric == 'stride' || goalMetric == 'stride_length'),
          _MetricRow(label: l10n.heartRate, myValue: _formatInt(mySplit?.avgHeartRate), oppValue: _formatInt(oppSplit?.avgHeartRate), lowerIsBetter: true, isGoal: goalMetric == 'heart_rate'),
        ],
      ),
    );
  }

  String _formatPace(int? pace) {
    if (pace == null || pace <= 0) return '--';
    final m = pace ~/ 60;
    final s = pace % 60;
    return "$m'${s.toString().padLeft(2, '0')}";
  }

  String _formatInt(int? value) {
    if (value == null || value <= 0) return '--';
    return '$value';
  }

  String _formatDouble(double? value) {
    if (value == null || value <= 0) return '--';
    return value.toStringAsFixed(2);
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String myValue;
  final String oppValue;
  final bool lowerIsBetter;
  final bool isGoal;

  const _MetricRow({
    required this.label,
    required this.myValue,
    required this.oppValue,
    required this.lowerIsBetter,
    this.isGoal = false,
  });

  @override
  Widget build(BuildContext context) {
    // 判断胜负（仅在双方都有有效值时）
    String? winner;
    if (myValue != '--' && oppValue != '--') {
      final myNum = double.tryParse(myValue.replaceAll("'", '.'));
      final oppNum = double.tryParse(oppValue.replaceAll("'", '.'));
      if (myNum != null && oppNum != null) {
        if (lowerIsBetter) {
          winner = myNum < oppNum ? 'me' : (myNum > oppNum ? 'opponent' : null);
        } else {
          winner = myNum > oppNum ? 'me' : (myNum < oppNum ? 'opponent' : null);
        }
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isGoal ? AppColors.orange.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50.w,
            child: Text(label, style: TextStyle(fontSize: 12.sp, color: context.textTertiary)),
          ),
          Expanded(
            child: Text(
              myValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: winner == 'me' ? FontWeight.bold : FontWeight.normal,
                color: winner == 'me' ? AppColors.success : context.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              oppValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: winner == 'opponent' ? FontWeight.bold : FontWeight.normal,
                color: winner == 'opponent' ? AppColors.success : context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI 跑情分析 BottomSheet
/// 
class _AIAnalysisSheet extends ConsumerStatefulWidget {
  final String runId;
  const _AIAnalysisSheet({required this.runId});

  @override
  ConsumerState<_AIAnalysisSheet> createState() => _AIAnalysisSheetState();
}

class _AIAnalysisSheetState extends ConsumerState<_AIAnalysisSheet> {
  String _content = '';
  bool _loading = true;
  String? _error;
  String? _model;
  int? _tokens;
  double? _latency;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    // 第一步：尝试从数据库缓存读取
    try {
      final api = ref.read(apiServiceProvider);
      final cacheResp = await api.getAnalysis(widget.runId);
      if (!mounted) return;
      // 缓存命中（200），直接显示
      if (cacheResp.isSuccess && cacheResp.data != null) {
        setState(() {
          _content = cacheResp.data!['content'] as String? ?? '';
          _model = cacheResp.data!['model'] as String?;
          _tokens = cacheResp.data!['tokens'] as int?;
          _latency = cacheResp.data!['latency'] != null
              ? (cacheResp.data!['latency'] as num).toDouble()
              : null;
          _loading = false;
        });
        return; // 完成，不再调用 runAnalysis
      }
      // 缓存未命中（404），继续调用 runAnalysis 生成
    } catch (e) {
      // 网络错误，继续调用 runAnalysis 作为兜底
    }

    // 第二步：缓存未命中，调用 AI 实时生成
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.runAnalysis(widget.runId);
      if (!mounted) return;
      if (resp.isSuccess && resp.data != null) {
        setState(() {
          _content = resp.data!['content'] as String? ?? '';
          _model = resp.data!['model'] as String?;
          _tokens = resp.data!['tokens'] as int?;
          _latency = resp.data!['latency'] != null
              ? (resp.data!['latency'] as num).toDouble()
              : null;
          _loading = false;
        });
      } else {
        setState(() {
          _error = resp.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '网络错误，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          // 标题栏
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 20.sp, color: AppColors.orange),
                SizedBox(width: 8.w),
                Text(
                  'AI 跑情分析',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (!_loading && _model != null)
                  Text(
                  '${_latency != null ? '${_latency!.toStringAsFixed(1)}s' : ''}  ${_tokens ?? ''} tokens',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 20.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          // 内容区
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32.w,
                          height: 32.w,
                          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.orange),
                        ),
                        SizedBox(height: 16.h),
                        Text('正在生成跑情分析…', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 40.sp, color: Colors.red.shade300),
                            SizedBox(height: 12.h),
                            Text(_error!, style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                            SizedBox(height: 12.h),
                            TextButton(onPressed: _fetchAnalysis, child: Text('重试')),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                        child: SelectableText(
                          _content,
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: 1.7,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
          ),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}
