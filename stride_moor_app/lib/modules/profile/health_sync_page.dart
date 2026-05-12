import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config/theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/device_provider.dart';
import '../../core/services/health_data_source.dart';

/// 健康数据同步页
///
/// 自动检测设备上的健康数据平台：
/// - 华为/HarmonyOS 设备 → HMS Health Kit
/// - 有 Google 服务的 Android 设备 → Health Connect
/// - iOS 设备 → Apple Health
///
/// 用户勾选跑步记录后提交到后端 /runs/import。
class HealthSyncPage extends ConsumerStatefulWidget {
  final String? deviceId;
  final String? connType;

  const HealthSyncPage({super.key, this.deviceId, this.connType});

  @override
  ConsumerState<HealthSyncPage> createState() => _HealthSyncPageState();
}

class _HealthSyncPageState extends ConsumerState<HealthSyncPage> {
  HealthDataSource? _dataSource;
  HealthPlatform? _platform;
  bool _permissionsGranted = false;
  bool _isLoading = false;
  bool _isImporting = false;
  bool _isDetecting = true;
  Set<String> _selected = {};
  List<HealthWorkoutData> _workouts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _initDataSource();
  }

  Future<void> _initDataSource() async {
    setState(() => _isDetecting = true);

    try {
      _dataSource = await HealthDataSourceManager.createDataSource();
      if (_dataSource == null) {
        setState(() {
          _isDetecting = false;
          _error = '当前设备不支持健康数据同步。\n需要 HMS Core (华为) 或 Google Play 服务。';
        });
        return;
      }

      _platform = _dataSource!.platform;
      setState(() => _isDetecting = false);

      // 自动开始请求授权并加载数据
      _requestAndLoad();
    } catch (e) {
      setState(() {
        _isDetecting = false;
        _error = '检测健康平台失败: $e';
      });
    }
  }

  /// 获取数据平台对应的显示名称
  String _getPlatformName(HealthPlatform platform) {
    switch (platform) {
      case HealthPlatform.appleHealth:
        return 'Apple Health';
      case HealthPlatform.healthConnect:
        return 'Health Connect';
      case HealthPlatform.hmsHealthKit:
        return '华为 Health Kit';
      case HealthPlatform.unknown:
        return '未知';
    }
  }

  /// 获取数据平台对应的图标
  IconData _getPlatformIcon(HealthPlatform platform) {
    switch (platform) {
      case HealthPlatform.appleHealth:
        return Icons.favorite;
      case HealthPlatform.healthConnect:
        return Icons.health_and_safety;
      case HealthPlatform.hmsHealthKit:
        return Icons.shield;
      case HealthPlatform.unknown:
        return Icons.help_outline;
    }
  }

  Future<void> _requestAndLoad() async {
    if (_dataSource == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 请求健康权限
      final granted = await _dataSource!.requestPermissions();
      if (!granted) {
        setState(() {
          _isLoading = false;
          _error = '健康数据授权被拒绝，请在系统设置中开启。';
        });
        return;
      }

      // 读取最近 30 天的跑步记录
      final workouts = await _dataSource!.fetchWorkouts(
        since: DateTime.now().subtract(const Duration(days: 30)),
      );

      setState(() {
        _workouts = workouts;
        _isLoading = false;
        _permissionsGranted = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '读取健康数据失败: $e';
      });
    }
  }

  Future<void> _doImport() async {
    if (_selected.isEmpty) return;

    setState(() => _isImporting = true);

    final api = ref.read(apiServiceProvider);
    int success = 0;
    int failed = 0;

    for (final w in _workouts) {
      if (!_selected.contains(w.sourceId)) continue;

      try {
        final json = w.toImportJson();
        // 如果有关联设备，添加上
        if (widget.deviceId != null) {
          json['device_id'] = widget.deviceId;
        }
        final resp = await api.importRun(json);
        if (resp.isSuccess) {
          success++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }

    setState(() => _isImporting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '导入完成：成功 $success 条${failed > 0 ? '，失败 $failed 条' : ''}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: failed > 0 ? Colors.orange : Colors.green,
      ),
    );

    if (success > 0) {
      // 刷新设备列表（可能设备有变化）
      ref.invalidate(deviceListProvider);
      // 返回上一页
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据数据源类型设置不同的标题
    String title = '健康数据同步';
    if (_platform != null) {
      title = _getPlatformName(_platform!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_permissionsGranted && _workouts.isNotEmpty)
            TextButton(
              onPressed: _isImporting ? null : _doImport,
              child: _isImporting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child:
                          CircularProgressIndicator(strokeWidth: 2.w),
                    )
                  : Text(
                      '导入选中 (${_selected.length})',
                      style: TextStyle(
                        color: _selected.isEmpty
                            ? context.textTertiary
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 检测平台中
    if (_isDetecting) {
      return const Center(child: CircularProgressIndicator());
    }

    // 加载中
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 错误状态
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64.w, color: context.textSecondary),
              SizedBox(height: 16.h),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15.sp, color: context.textSecondary)),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () async {
                  HealthDataSourceManager.clearCache();
                  setState(() => _isDetecting = true);
                  await _initDataSource();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 无数据
    if (_workouts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_run,
                  size: 64.w, color: context.textSecondary),
              SizedBox(height: 16.h),
              Text(
                '近 30 天没有找到可导入的跑步记录',
                style: TextStyle(
                    fontSize: 15.sp, color: context.textSecondary),
              ),
              SizedBox(height: 8.h),
              if (_platform != null)
                Text(
                  '数据来源: ${_getPlatformName(_platform!)}',
                  style: TextStyle(
                      fontSize: 13.sp, color: context.textTertiary),
                ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: _requestAndLoad,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 顶部提示
        Container(
          width: double.infinity,
          margin: EdgeInsets.all(20.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              if (_platform != null) ...[
                Icon(_getPlatformIcon(_platform!),
                    color: AppColors.info, size: 20.sp),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text:
                        '找到 ${_workouts.length} 条跑步记录，勾选后点击右上角"导入选中"',
                    style: TextStyle(fontSize: 13.sp, color: AppColors.info),
                    children: [
                      TextSpan(
                        text: ' 来自 ${_getPlatformName(_platform!)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 全选/取消
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (_selected.length == _workouts.length) {
                      _selected.clear();
                    } else {
                      _selected =
                          _workouts.map((w) => w.sourceId).toSet();
                    }
                  });
                },
                icon: Icon(
                  _selected.length == _workouts.length
                      ? Icons.deselect
                      : Icons.select_all,
                  size: 18.sp,
                ),
                label: Text(
                  _selected.length == _workouts.length ? '取消全选' : '全选',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              const Spacer(),
              Text(
                '$_selected / ${_workouts.length} 已选',
                style: TextStyle(
                    fontSize: 13.sp, color: context.textSecondary),
              ),
            ],
          ),
        ),

        SizedBox(height: 8.h),

        // 跑步记录列表
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: _workouts.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final w = _workouts[index];
              final isSelected = _selected.contains(w.sourceId);
              return _buildWorkoutItem(w, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutItem(HealthWorkoutData w, bool isSelected) {
    // 格式化距离
    final distanceKm = w.totalDistance / 1000;
    final distanceStr = distanceKm >= 10
        ? '${distanceKm.toStringAsFixed(1)} km'
        : '${distanceKm.toStringAsFixed(2)} km';

    // 格式化时间
    final minutes = w.totalTime ~/ 60;
    final seconds = w.totalTime % 60;
    final timeStr = '${minutes}分${seconds.toString().padLeft(2, '0')}秒';

    // 格式化配速
    final paceSec =
        w.totalTime > 0 ? w.totalTime / (w.totalDistance / 1000) : 0;
    final paceMin = paceSec ~/ 60;
    final paceSecRem = paceSec.round() % 60;
    final paceStr =
        paceSec > 0 ? '${paceMin}:${paceSecRem.toString().padLeft(2, '0')}/km' : '--';

    // 日期
    final dateStr =
        '${w.startTime.month}/${w.startTime.day} ${w.startTime.hour.toString().padLeft(2, '0')}:${w.startTime.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.dividerColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selected.remove(w.sourceId);
            } else {
              _selected.add(w.sourceId);
            }
          });
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // 选中框
              Container(
                width: 24.w,
                height: 24.w,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : context.dividerColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check,
                        color: Colors.white, size: 16.sp)
                    : null,
              ),

              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: context.textTertiary)),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(distanceStr,
                            style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 16.w),
                        Text(timeStr,
                            style: TextStyle(
                                fontSize: 13.sp,
                                color: context.textSecondary)),
                        SizedBox(width: 12.w),
                        Text(paceStr,
                            style: TextStyle(
                                fontSize: 13.sp,
                                color: context.textTertiary)),
                      ],
                    ),
                    if (w.avgHeartRate != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.favorite,
                              size: 14.sp, color: Colors.red[300]),
                          SizedBox(width: 4.w),
                          Text('${w.avgHeartRate} bpm',
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: context.textSecondary)),
                          if (w.calories != null) ...[
                            SizedBox(width: 16.w),
                            Icon(Icons.local_fire_department,
                                size: 14.sp, color: Colors.orange[300]),
                            SizedBox(width: 4.w),
                            Text('${w.calories} kcal',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    color: context.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                    if (w.sourceId.startsWith('huawei_'))
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Row(
                          children: [
                            Icon(Icons.shield,
                                size: 12.sp,
                                color: Colors.blue[300]),
                            SizedBox(width: 4.w),
                            Text('来自华为健康',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.blue[300],
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
