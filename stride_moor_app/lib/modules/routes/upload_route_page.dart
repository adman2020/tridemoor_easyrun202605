import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/models/run.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/run_provider.dart';
import '../../core/providers/route_provider.dart';
import '../../l10n/app_localizations.dart';

/// 上传跑迹 —— 从历史跑步记录中生成路线
class UploadRoutePage extends ConsumerStatefulWidget {
  const UploadRoutePage({super.key});

  @override
  ConsumerState<UploadRoutePage> createState() => _UploadRoutePageState();
}

class _UploadRoutePageState extends ConsumerState<UploadRoutePage> {
  String? _loadingRunId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final runsAsync = ref.watch(recentRunsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadRoute)),
      body: runsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (runs) {
          if (runs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run_outlined, size: 48.sp, color: context.textTertiary),
                  SizedBox(height: 12.h),
                  Text('暂无跑步记录', style: TextStyle(color: context.textSecondary)),
                  SizedBox(height: 8.h),
                  Text('先去跑一场吧！', style: TextStyle(color: context.textTertiary, fontSize: 12.sp)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: runs.length,
            itemBuilder: (context, index) {
              final run = runs[index];
              return _RunRecordCard(
                run: run,
                isLoading: _loadingRunId == run.id,
                onTap: () => _onGenerateRoute(run),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onGenerateRoute(Run run) async {
    setState(() => _loadingRunId = run.id);
    try {
      final runDetail = await ref.read(runDetailProvider(run.id).future);
      if (!mounted) return;

      if (runDetail.samples.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该跑步记录GPS点不足，无法生成路线')),
        );
        return;
      }

      _showCreateRouteSheet(runDetail);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取跑步详情失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRunId = null);
    }
  }

  void _showCreateRouteSheet(Run run) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(
      text: '${_formatDate(run.startTime)} 跑步路线',
    );
    final descController = TextEditingController(
      text: _buildDescription(run),
    );
    final tagsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.h,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.dividerColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  '生成路线',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                SizedBox(height: 8.h),
                Text(
                  '基于 ${(run.totalDistance / 1000).toStringAsFixed(1)}km 跑步记录',
                  style: TextStyle(fontSize: 14.sp, color: context.textSecondary),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '路线名称',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    prefixIcon: const Icon(Icons.edit_road),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: descController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: '路线描述',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    prefixIcon: const Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: tagsController,
                  decoration: InputDecoration(
                    labelText: '标签（用逗号分隔）',
                    hintText: '例如: 公园, 晨跑, 环线',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _submitCreateRoute(ctx, run, nameController, descController, tagsController),
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(l10n.generate),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitCreateRoute(
    BuildContext ctx,
    Run run,
    TextEditingController nameCtrl,
    TextEditingController descCtrl,
    TextEditingController tagsCtrl, {
    bool skipValidation = false,
    bool forceCreate = false,
  }) async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('请输入路线名称')),
      );
      return;
    }

    final api = ref.read(apiServiceProvider);

    // 计算中心点
    final latSum = run.samples.map((s) => s.latitude).reduce((a, b) => a + b);
    final lngSum = run.samples.map((s) => s.longitude).reduce((a, b) => a + b);
    final centerLat = latSum / run.samples.length;
    final centerLng = lngSum / run.samples.length;

    // 提取轨迹点
    final points = run.samples.map((s) {
      final point = <String, dynamic>{
        'latitude': s.latitude,
        'longitude': s.longitude,
      };
      if (s.altitude != null) {
        point['altitude'] = s.altitude;
      }
      return point;
    }).toList();

    // Phase 2: 规则校验
    if (!skipValidation && !forceCreate) {
      try {
        // 先检查 mounted，防止 bottom sheet 关闭后使用 context
        if (!mounted) return;
        final validateResp = await api.validateRoute({
          'name': name,
          'distance': run.totalDistance,
          'points': points,
        });

        // 再次检查
        if (!mounted) return;

        final data = validateResp.data;
        if (data == null) {
          _createRoute(ctx, run, name, descCtrl, tagsCtrl, centerLat, centerLng, points);
          return;
        }

        final passed = data['passed'] as bool? ?? true;
        final flags = (data['flags'] as List<dynamic>?)?.cast<String>() ?? [];
        final reason = data['reason'] as String? ?? '';
        final duplicates = (data['duplicates'] as List<dynamic>?) ?? [];

        if (!passed && !_hasOnlyDuplicateFlag(flags)) {
          // 有阻塞性错误（名称格式/GPS等）
          await _showValidationErrorDialog(ctx, reason, flags);
          return;
        }

        if (duplicates.isNotEmpty) {
          // 疑似重复，弹确认
          await _showDuplicateConfirmDialog(
            ctx, run, nameCtrl, descCtrl, tagsCtrl,
            centerLat, centerLng, points, duplicates,
          );
          return;
        }

        // 全部通过，直接创建
        _createRoute(ctx, run, name, descCtrl, tagsCtrl, centerLat, centerLng, points);
      } catch (e) {
        // 校验失败，走正常流程（不阻塞用户）
        _createRoute(ctx, run, name, descCtrl, tagsCtrl, centerLat, centerLng, points);
      }
      return;
    }

    // 强制创建（用户在确认弹框里点了继续）
    _createRoute(ctx, run, name, descCtrl, tagsCtrl, centerLat, centerLng, points);
  }

  bool _hasOnlyDuplicateFlag(List<String> flags) {
    if (flags.isEmpty) return true;
    return flags.every((f) => f == 'duplicate');
  }

  Future<void> _showValidationErrorDialog(BuildContext ctx, String reason, List<String> flags) async {
    // 根据不同错误类型给出更友好的提示
    String hint;
    if (flags.contains('name_too_short')) {
      hint = '请输入至少4个字符的路线名称';
    } else if (flags.contains('name_too_long')) {
      hint = '路线名称不能超过30个字符';
    } else if (flags.contains('name_pure_number')) {
      hint = '路线名称不能是纯数字，请包含地名或描述';
    } else if (flags.contains('invalid_name')) {
      hint = '路线名称必须包含中文或英文字符';
    } else if (flags.contains('name_no_distance')) {
      hint = '请在名称中加入距离，如「5公里」或「5km」';
    } else if (flags.contains('no_gps')) {
      hint = 'GPS轨迹点不足，请检查跑步记录';
    } else if (flags.contains('distance_zero')) {
      hint = '距离数据异常，请重新选择跑步记录';
    } else {
      hint = reason;
    }

    await showDialog<void>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: const Text('路线信息不规范'),
        content: Text(hint.isNotEmpty ? hint : '请检查路线名称和GPS数据后重试'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDuplicateConfirmDialog(
    BuildContext ctx,
    Run run,
    TextEditingController nameCtrl,
    TextEditingController descCtrl,
    TextEditingController tagsCtrl,
    double centerLat,
    double centerLng,
    List<Map<String, dynamic>> points,
    List<dynamic> duplicates,
  ) async {
    if (duplicates.isEmpty) {
      _createRoute(ctx, run, nameCtrl.text.trim(), descCtrl, tagsCtrl, centerLat, centerLng, points);
      return;
    }

    final dupInfo = duplicates.first as Map<String, dynamic>;
    final dupName = dupInfo['name'] as String? ?? '相似路线';
    final dupDist = (dupInfo['distance'] as num?)?.toDouble() ?? 0;
    final diff = (dupInfo['diff'] as num?)?.toDouble() ?? 0;

    await showDialog<void>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: const Text('发现相似路线'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('系统中已有相似路线：'),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4.h),
                  Text('距离: ${(dupDist / 1000).toStringAsFixed(1)}km  |  差异: ${diff.toStringAsFixed(1)}%'),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            const Text(
              '是否为同一条路线？',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // 忽略重复警告，强制创建
              _submitCreateRoute(ctx, run, nameCtrl, descCtrl, tagsCtrl, skipValidation: true, forceCreate: true);
            },
            child: const Text('仍要发布'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('返回修改'),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoute(
    BuildContext ctx,
    Run run,
    String name,
    TextEditingController descCtrl,
    TextEditingController tagsCtrl,
    double centerLat,
    double centerLng,
    List<Map<String, dynamic>> points,
  ) async {
    final api = ref.read(apiServiceProvider);

    // 解析标签
    final tags = tagsCtrl.text
        .trim()
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    try {
      final response = await api.createRoute({
        'name': name,
        'description': descCtrl.text.trim(),
        'distance': run.totalDistance,
        'elevation_gain': run.elevationGain,
        'avg_pace': run.avgPace ?? 0,
        'avg_cadence': run.avgCadence ?? 0,
        'avg_stride': run.avgStrideLength ?? 0.0,
        'calories': run.calories ?? 0,
        'avg_heart_rate': run.avgHeartRate ?? 0,
        'elevation_loss': 0,
        'difficulty': _difficultyFromDistance(run.totalDistance),
        if (tags.isNotEmpty) 'tags': tags,
        'start_lat': run.samples.first.latitude,
        'start_lng': run.samples.first.longitude,
        'center_lat': centerLat,
        'center_lng': centerLng,
        'points': points,
      });

      if (!response.isSuccess) {
        throw Exception(response.message);
      }

      if (!mounted) return;
      // 刷新上传管理列表
      ref.invalidate(uploadRecordsProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('路线创建成功！'), behavior: SnackBarBehavior.floating),
      );

      // 跳转到新生成的路线详情
      final routeId = response.data?['id'] as String?;
      if (routeId != null) {
        context.push('/route/$routeId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建路线失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    // date 已由 fromJson 从 ISO 字符串提取纯日期，不依赖时区
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _buildDescription(Run run) {
    final buffer = StringBuffer('由跑步记录自动生成\n');
    buffer.writeln('时长: ${_formatDuration(run.totalTime)}');
    if (run.avgPace != null && run.avgPace! > 0) {
      buffer.writeln('平均配速: ${_formatPace(run.avgPace!)}/km');
    }
    if (run.avgHeartRate != null && run.avgHeartRate! > 0) {
      buffer.writeln('平均心率: ${run.avgHeartRate} bpm');
    }
    if (run.avgCadence != null && run.avgCadence! > 0) {
      buffer.writeln('平均步频: ${run.avgCadence} 步/分钟');
    }
    if (run.avgStrideLength != null && run.avgStrideLength! > 0) {
      buffer.writeln('平均步幅: ${run.avgStrideLength!.toStringAsFixed(2)} m');
    }
    if (run.calories != null && run.calories! > 0) {
      buffer.writeln('消耗卡路里: ${run.calories} kcal');
    }
    return buffer.toString().trim();
  }

  String _formatDuration(int seconds) {
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

  int _difficultyFromDistance(double distanceMeters) {
    if (distanceMeters < 3000) return 1;
    if (distanceMeters < 10000) return 2;
    return 3;
  }
}

class _RunRecordCard extends StatelessWidget {
  final Run run;
  final bool isLoading;
  final VoidCallback onTap;

  const _RunRecordCard({
    required this.run,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // run.startTime 已由 fromJson 提取纯日期
    final dateStr = '${run.startTime.year}-${run.startTime.month.toString().padLeft(2, '0')}-${run.startTime.day.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.directions_run, color: AppColors.orange),
        ),
        title: Text('${(run.totalDistance / 1000).toStringAsFixed(1)}${l10n.km} ${l10n.runs}'),
        subtitle: Text(
          '$dateStr · ${l10n.pace} ${_formatPace(run.avgPace ?? 0)} · ${_formatDuration(run.totalTime)}',
        ),
        trailing: isLoading
            ? null
            : ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                ),
                child: Text(l10n.generate),
              ),
        onTap: isLoading ? null : onTap,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(int paceSecondsPerKm) {
    if (paceSecondsPerKm <= 0) return '--';
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }
}
