import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'run_finish_page.dart';
import 'run_trace_select_page.dart';
import 'running_page.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/models/run.dart';
import '../../core/models/run_goal.dart';
import '../../core/models/route.dart' as app_route;
import '../../core/providers/run_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/services/debug_step_logger.dart';
/// 跑步准备页 —— 紧凑美观，伴跑/挑战跑一屏内完成所有操作
class RunPreparationPage extends ConsumerStatefulWidget {
  const RunPreparationPage({super.key});

  @override
  ConsumerState<RunPreparationPage> createState() => _RunPreparationPageState();
}

class _RunPreparationPageState extends ConsumerState<RunPreparationPage> {
  RunMode _selectedMode = RunMode.solo;
  GhostMode? _selectedGhostMode;
  ChallengeMetric? _selectedMetric;
  app_route.Route? _selectedRoute;
  Map<String, dynamic>? _selectedBookmark;

  // 跑步目标
  RunGoalType _goalType = RunGoalType.none;
  double _goalValue = 5.0;

  // 语音播报（从 runSessionProvider 加载已保存配置）
  late BroadcastFrequency _broadcastFreq;
  late List<String> _broadcastItems;
  late String _voiceStyle;

  @override
  void initState() {
    super.initState();
    _syncFromProvider();
  }

  void _syncFromProvider() {
    final saved = ref.read(runSessionProvider);
    _selectedMode = saved.runMode;
    _broadcastFreq = saved.broadcastFrequency;
    _broadcastItems = List.from(saved.broadcastItems);
    _voiceStyle = saved.voiceStyle;
    _selectedGhostMode = saved.ghostMode;
    _selectedMetric = saved.challengeMetric;
  }

  /// 将当前设置保存到 Provider 并持久化到 SharedPreferences
  void _saveRunPrefs() {
    ref.read(runSessionProvider.notifier).configure(
      mode: _selectedMode,
      ghost: _selectedGhostMode,
      metric: _selectedMetric,
      frequency: _broadcastFreq,
      items: _broadcastItems,
      voice: _voiceStyle,
    );
  }

  Run? get _opponentRun {
    final runJson = _selectedBookmark?['run'] as Map<String, dynamic>?;
    if (runJson == null) return null;
    return Run.fromJson(runJson);
  }

  @override
  Widget build(BuildContext context) {
    // 监听 provider 变化，同步到本地状态
    ref.listen(runSessionProvider, (prev, next) {
      if (next.broadcastFrequency != _broadcastFreq ||
          next.broadcastItems != _broadcastItems ||
          next.voiceStyle != _voiceStyle ||
          next.runMode != _selectedMode ||
          next.ghostMode != _selectedGhostMode ||
          next.challengeMetric != _selectedMetric) {
        setState(() => _syncFromProvider());
      }
    });
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('运动'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          TextButton(
            onPressed: _showDebugLog,
            child: Text(
              '日志',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              // 模式选择 —— 紧凑药丸
              _buildModePills(),
              SizedBox(height: 20.h),
              // 附属选项 + 跑迹选择 + 开始按钮
              Expanded(
                child: _selectedMode == RunMode.companion
                    ? _buildCompanionContent()
                    : _selectedMode == RunMode.challenge
                        ? _buildChallengeContent()
                        : _buildSoloContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 模式药丸 ───────────────────────────────────────────────

  Widget _buildModePills() {
    final modes = <(RunMode, String)>[
      (RunMode.solo, '独自跑'),
      (RunMode.companion, '伴跑'),
      (RunMode.challenge, '挑战跑'),
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        children: modes.map((m) {
          final active = _selectedMode == m.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = m.$1;
                  // 切换模式时设置默认选项
                  if (m.$1 == RunMode.companion && _selectedGhostMode == null) {
                    _selectedGhostMode = GhostMode.realReplay;
                  }
                  if (m.$1 == RunMode.challenge && _selectedMetric == null) {
                    _selectedMetric = ChallengeMetric.pace;
                  }
                  // 非伴跑模式时清空 ghost 选择（下次切回时重新设置默认）
                  if (m.$1 != RunMode.companion) {
                    _selectedGhostMode = null;
                  }
                  // 非挑战跑模式时清空 metric 选择
                  if (m.$1 != RunMode.challenge) {
                    _selectedMetric = null;
                  }
                });
                _saveRunPrefs();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: active ? AppColors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeIcon(m.$1, 18.sp, active ? Colors.white : context.textSecondary),
                    SizedBox(width: 6.w),
                    Text(
                      m.$2,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                        color: active ? Colors.white : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 为每种跑步模式构建图标（自定义组合图标）
  Widget _buildModeIcon(RunMode mode, double size, Color color) {
    switch (mode) {
      case RunMode.companion:
        // 两个奔跑小人并排紧靠（同一基线）→ 伴跑
        return SizedBox(
          width: size * 1.2,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.directions_run, size: size * 0.85, color: color),
              Positioned(
                left: size * 0.50,
                child: Icon(Icons.directions_run, size: size * 0.85, color: color),
              ),
            ],
          ),
        );
      case RunMode.challenge:
        // 奔跑小人头顶举奖杯 → 挑战跑
        return SizedBox(
          width: size * 1.2,
          height: size * 1.3,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 跑步小人在底部
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Icon(Icons.directions_run, size: size * 0.85, color: color),
              ),
              // 奖杯紧贴头顶上方
              Positioned(
                bottom: size * 0.85,
                left: 0, right: 0,
                child: Icon(Icons.emoji_events, size: size * 0.40, color: Colors.amber),
              ),
            ],
          ),
        );
      default:
        return Icon(Icons.directions_run, size: size, color: color);
    }
  }

  // ─── 独自跑 ────────────────────────────────────────────────

  Widget _buildSoloContent() {
    return Column(
      children: [
        // 目标选择
        _buildGoalSelector(),
        SizedBox(height: 12.h),
        // 语音播报设置
        _buildBroadcastSettings(),
        const Spacer(),
        _buildStartButton(),
        SizedBox(height: 30.h),
      ],
    );
  }

  // ─── 伴跑 ──────────────────────────────────────────────────

  Widget _buildCompanionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 幻影模式
        _sectionLabel('幻影模式'),
        SizedBox(height: 8.h),
        _buildGhostModeSelector(),
        SizedBox(height: 16.h),
        // 选择跑迹
        _buildTraceSelector(),
        const Spacer(),
        // 开始按钮
        Center(child: _buildStartButton()),
        SizedBox(height: 16.h),
      ],
    );
  }

  // ─── 挑战跑 ────────────────────────────────────────────────

  Widget _buildChallengeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 比拼指标
        _sectionLabel('比拼指标'),
        SizedBox(height: 8.h),
        _buildChallengeMetricSelector(),
        SizedBox(height: 16.h),
        // 选择跑迹
        _buildTraceSelector(),
        const Spacer(),
        // 开始按钮
        Center(child: _buildStartButton()),
        SizedBox(height: 16.h),
      ],
    );
  }

  // ─── 通用小组件 ────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: context.textSecondary,
      ),
    );
  }

  Widget _buildGhostModeSelector() {
    final modes = [
      (GhostMode.realReplay, '真实回放'),
      (GhostMode.constantPace, '恒定配速'),
      (GhostMode.rabbit, '领跑兔'),
      (GhostMode.tortoiseHare, '龟兔赛跑'),
      (GhostMode.goalChallenge, '目标挑战'),
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: modes.map((m) {
        final active = _selectedGhostMode == m.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedGhostMode = active ? null : m.$1);
              _saveRunPrefs();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: active ? AppColors.orange.withValues(alpha: 0.15) : context.surfaceColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: active ? AppColors.orange : context.dividerColor,
                  width: active ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                m.$2,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: active ? AppColors.orange : context.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
        );
      }).toList(),
    );
  }

  Widget _buildChallengeMetricSelector() {
    final metrics = [
      (ChallengeMetric.pace, '配速'),
      (ChallengeMetric.heartRate, '心率'),
      (ChallengeMetric.cadence, '步频'),
      (ChallengeMetric.strideLength, '步幅'),
    ];

    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final m = metrics[i];
          final active = _selectedMetric == m.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedMetric = active ? null : m.$1);
              _saveRunPrefs();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: active ? AppColors.orange.withValues(alpha: 0.15) : context.surfaceColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: active ? AppColors.orange : context.dividerColor,
                  width: active ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                m.$2,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: active ? AppColors.orange : context.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTraceSelector() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(builder: (_) => const RunTraceSelectPage()),
        );
        if (result != null) {
          final routeJson = result['route'] as Map<String, dynamic>?;
          final route = routeJson != null ? app_route.Route.fromJson(routeJson) : null;
          setState(() {
            _selectedBookmark = result;
            _selectedRoute = route;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.route_outlined, color: AppColors.orange, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedRoute?.name ?? '选择跑迹',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: _selectedRoute != null ? context.textPrimary : context.textTertiary,
                    ),
                  ),
                  if (_selectedBookmark != null)
                    Text(
                      '${_selectedRoute != null ? '${(_selectedRoute!.distance / 1000).toStringAsFixed(1)}km' : ''} · ${_selectedBookmark!['friend_name'] ?? '跑友'}',
                      style: TextStyle(fontSize: 11.sp, color: context.textTertiary),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18.sp, color: context.textTertiary),
          ],
        ),
      ),
    );
  }

  // ─── 目标选择器 ────────────────────────────────────────────

  Widget _buildGoalSelector() {
    final types = [
      (RunGoalType.none, '无目标'),
      (RunGoalType.distance, '距离'),
      (RunGoalType.duration, '时间'),
      (RunGoalType.calories, '热量'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('跑步目标'),
        SizedBox(height: 8.h),
        // 类型药丸
        SizedBox(
          height: 32.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: types.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, i) {
              final t = types[i];
              final active = _goalType == t.$1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _goalType = t.$1;
                    // 切换时设一个合理的默认值
                    switch (t.$1) {
                      case RunGoalType.distance:
                        _goalValue = 5.0;
                      case RunGoalType.duration:
                        _goalValue = 30.0;
                      case RunGoalType.calories:
                        _goalValue = 200.0;
                      default:
                        _goalValue = 0;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: active ? AppColors.orange.withValues(alpha: 0.15) : context.surfaceColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: active ? AppColors.orange : context.dividerColor,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t.$2,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: active ? AppColors.orange : context.textSecondary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 快捷数值选择
        if (_goalType != RunGoalType.none) ...[
          SizedBox(height: 12.h),
          SizedBox(
            height: 32.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _goalPresets.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (_, i) {
                final val = _goalPresets[i];
                final active = _goalValue == val;
                return GestureDetector(
                  onTap: () => setState(() => _goalValue = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: active ? AppColors.orange.withValues(alpha: 0.15) : context.surfaceColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: active ? AppColors.orange : context.dividerColor,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _goalLabel(val),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: active ? AppColors.orange : context.textSecondary,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  List<double> get _goalPresets {
    switch (_goalType) {
      case RunGoalType.distance:
        return [5.0, 10.0, 21.1, 42.2];
      case RunGoalType.duration:
        return [15, 30, 45, 60];
      case RunGoalType.calories:
        return [100, 200, 300, 500];
      default:
        return [];
    }
  }

  String _goalLabel(double val) {
    switch (_goalType) {
      case RunGoalType.distance:
        return val >= 42 ? '全马' : (val >= 21 ? '半马' : '${val.round()}km');
      case RunGoalType.duration:
        return val >= 60 ? '${(val / 60).round()}小时' : '${val.round()}分钟';
      case RunGoalType.calories:
        return '${val.round()}千卡';
      default:
        return '';
    }
  }

  // ─── 语音播报设置 ────────────────────────────────────────

  static const _allBroadcastKeys = [
    'distance','pace','duration','heart_rate',
    'cadence','stride_length','calories','climb','motivation',
  ];

  final Map<String, String> _broadcastChipLabels = {
    'distance': '距离',
    'pace': '配速',
    'duration': '用时',
    'heart_rate': '心率',
    'cadence': '步频',
    'stride_length': '步幅',
    'calories': '卡路里',
    'climb': '爬升',
    'motivation': '鼓励',
  };

  /// 通用 Chip 构建方法：active 时橙色高亮
  Widget _buildChip(String label, {required bool active, required VoidCallback onTap, bool compact = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14.w : 16.w,
          vertical: compact ? 7.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.orange.withValues(alpha: 0.15) : context.surfaceColor,
          borderRadius: BorderRadius.circular(compact ? 16.r : 18.r),
          border: Border.all(
            color: active ? AppColors.orange : context.dividerColor,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 13.sp : 14.sp,
            color: active ? AppColors.orange : context.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBroadcastSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('语音播报'),
        SizedBox(height: 8.h),
        // ── 第一行：播报频率 ──
        Text('播报频率', style: TextStyle(fontSize: 11.sp, color: context.textSecondary)),
        SizedBox(height: 4.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 5.h,
          children: BroadcastFrequency.values.map((f) {
            return _buildChip(f.label, active: _broadcastFreq == f, compact: true, onTap: () {
              setState(() => _broadcastFreq = f);
              _saveRunPrefs();
            });
          }).toList(),
        ),
        SizedBox(height: 10.h),
        // ── 第二行：播报参数 ──
        Text('播报参数', style: TextStyle(fontSize: 11.sp, color: context.textSecondary)),
        SizedBox(height: 4.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 5.h,
          children: _allBroadcastKeys.map((key) {
            final active = _broadcastItems.contains(key);
            return _buildChip(
              _broadcastChipLabels[key] ?? key,
              active: active,
              compact: true,
              onTap: () {
                setState(() {
                  if (active) {
                    _broadcastItems.remove(key);
                  } else {
                    _broadcastItems.add(key);
                  }
                });
                _saveRunPrefs();
              },
            );
          }).toList(),
        ),
        SizedBox(height: 10.h),
        // ── 第三行：语音风格 ──
        Text('语音风格', style: TextStyle(fontSize: 11.sp, color: context.textSecondary)),
        SizedBox(height: 4.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 5.h,
          children: AppConstants.voiceStyles.map((v) {
            final active = _voiceStyle == v['id'];
            return _buildChip(v['name']!, active: active, compact: true, onTap: () {
              setState(() => _voiceStyle = v['id']!);
              _saveRunPrefs();
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () async {
        // 伴跑/挑战跑：校验与对手跑迹范围的距离
        if (_selectedMode == RunMode.companion || _selectedMode == RunMode.challenge) {
          if (_opponentRun == null || _opponentRun!.bounds == null) {
            if (context.mounted) _showNoBoundsWarning();
            return;
          } else {
            // 显示 GPS loading
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9800)),
                      ),
                      SizedBox(width: 16.w),
                      const Text('正在获取GPS定位…', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              );
            }
            final loc = await LocationService.instance.requestLocation();
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            if (loc == null) {
              if (context.mounted) _showGpsUnavailable();
              return;
            }
            final dist = _distanceToBounds(loc.$1, loc.$2, _opponentRun!.bounds!);
            if (dist > 5000) {
              if (context.mounted) _showDistanceWarning(dist);
              return;
            }
          }
        }

        ref.read(runSessionProvider.notifier).configure(
          mode: _selectedMode,
          ghost: _selectedGhostMode,
          metric: _selectedMetric,
          route: _selectedRoute,
          opponentRun: _opponentRun,
          goal: _goalType != RunGoalType.none
              ? RunGoal(type: _goalType, value: _goalValue)
              : null,
          frequency: _broadcastFreq,
          items: _broadcastItems,
          voice: _voiceStyle,
        );
        RunningPage.onFinishRun = (run) {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => RunFinishPage(run: run)),
            );
          }
        };
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const RunningPage(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 1.0).animate(animation),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      },
      child: Container(
        width: 88.w,
        height: 88.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.4),
              blurRadius: 20.r,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.play_arrow_rounded, size: 42, color: Colors.white),
        ),
      ),
    );
  }

  // ─── Haversine 工具函数 ────────────────────────────────────

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  double _distanceToBounds(double userLat, double userLng, RunBounds bounds) {
    final nearLat = userLat.clamp(bounds.minLat, bounds.maxLat);
    final nearLng = userLng.clamp(bounds.minLng, bounds.maxLng);
    return _haversine(userLat, userLng, nearLat, nearLng);
  }

  // ─── 弹窗 ──────────────────────────────────────────────────

  void _showGpsUnavailable() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Row(
          children: [
            Icon(Icons.gps_off, color: Color(0xFFFF6B6B)),
            SizedBox(width: 8),
            Text('GPS信号弱', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          '无法获取当前位置，请确保GPS已开启，\n或在室外开阔地带重试。',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了', style: TextStyle(color: Color(0xFFFF9800))),
          ),
        ],
      ),
    );
  }

  void _showNoBoundsWarning() {
    if (!context.mounted) return;
    final msg = _selectedMode == RunMode.companion
        ? '请选择你的伴跑者跑迹！'
        : '请选择对手跑迹！';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2A2A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDistanceWarning(double distMeters) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Color(0xFFFF6B6B)),
            SizedBox(width: 8),
            Text('距离太远', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '该跑迹距您 ${(distMeters / 1000).toStringAsFixed(1)} 公里，\n请选择附近的跑迹。',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了', style: TextStyle(color: Color(0xFFFF9800))),
          ),
        ],
      ),
    );
  }

  /// <bug> 加载调试日志
  Future<void> _showDebugLog() async {
    final log = await DebugStepLogger.readLog();
    if (!mounted) return;
    if (log == null || log.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('暂无调试日志')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: const Text('调试日志', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Container(
          constraints: BoxConstraints(maxHeight: 400.h, maxWidth: 300.w),
          child: SingleChildScrollView(
            child: Text(
              log,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭', style: TextStyle(color: Color(0xFFFF9800))),
          ),
        ],
      ),
    );
  }
}
