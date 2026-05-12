import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';
import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/models/run.dart';
import '../../core/models/run_goal.dart';
import '../../core/models/route.dart' as app_route;
import '../../core/providers/app_providers.dart';
import '../../core/providers/run_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/services/debug_step_logger.dart';

import '../../core/services/voice_broadcast_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/amap_map_view.dart';
import 'friends_route_select_page.dart';
import 'run_finish_page.dart';
import 'run_preparation_page.dart';

/// 跑中页面
const Color warmOrange = Color(0xFFFF6B00);
const Color warmOrangeLight = Color(0xFFFF8C33);
const Color huaweiRed = Color(0xFFE53935);

class RunningPage extends ConsumerStatefulWidget {
  const RunningPage({super.key});
  static void Function(Run?)? onFinishRun;
  @override
  ConsumerState<RunningPage> createState() => _RunningPageState();
}

class _RunningPageState extends ConsumerState<RunningPage>
    with TickerProviderStateMixin {
  // ---------- Panel state ----------
  double _panelHeight = 0;
  double _panelDragStart = 0;
  double _panelDragStartY = 0;
  double _panelMinHeight = 0;
  double _panelMaxHeight = 0;
  double _buttonAreaHeight = 0;
  final List<double> _snapFractions = [0.15, 0.60];

  // ---------- Animations ----------
  late AnimationController _pulseController;
  late AnimationController _countdownAnimController;
  int _countdownValue = 3;

  // ---------- State ----------
  bool _isLocked = false;
  bool _initError = false;
  String _initErrorMsg = '';
  bool _locationInitialized = false;
  bool _countdownOverlayVisible = true;
  bool _countdownOverlayRemoved = false;
  final VoiceBroadcastService _voiceService = VoiceBroadcastService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _countdownAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // 3个数，每个约1.67s，更有节奏感
    );


    // 倒计时监听：根据动画进度更新数值
    _countdownAnimController.addListener(() {
      final progress = _countdownAnimController.value;
      final newValue = 3 - (progress * 3).floor();
      if (newValue != _countdownValue) {
        setState(() {
          _countdownValue = newValue.clamp(0, 3);
        });
      }
    });
    _countdownAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _countdownValue = 0;
        });
        // 语音播报开始运动
        if (_voiceService.enabled) {
          _voiceService.speakStartText(ref.read(runSessionProvider).voiceStyle);
        }
        // 显示"开始运动！"持续 2000ms，然后隐藏覆盖层露出地图
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _countdownOverlayVisible = false;
            });
          }
        });
        // 淡出动画加速（200ms），看清后快消失
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) {
            setState(() {
              _countdownOverlayRemoved = true;
            });
          }
        });
        _startRunning();
      }
    });

    // 等第一帧渲染后再启动倒计时，确保UI准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doInit();
    });
    // TTS初始化完成后播报倒计时语音（确保引擎就绪）
    _voiceService.init().then((_) {
      if (!mounted || !_voiceService.enabled) return;
      _voiceService.speakNumber('3');
      // 语音与5秒动画同步：3个数各约1.67s
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _voiceService.enabled) _voiceService.speakNumber('2');
      });
      Future.delayed(const Duration(milliseconds: 2800), () {
        if (mounted && _voiceService.enabled) _voiceService.speakNumber('1');
      });
    });

    // 跑步中播报由 runSessionProvider 的定时器直接触发
    // （见 run_provider.dart _durationTimer 中的 VoiceBroadcastService.current?.onStateUpdate）
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownAnimController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  void _doInit() {
    // 标记位置已初始化（位置服务由 runSessionProvider 管理）
    _locationInitialized = true;
    // 开始倒计时动画（视觉同步）
    _countdownAnimController.forward();
  }

  void _startRunning() {
    ref.read(runSessionProvider.notifier).startRun();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(runSessionProvider);
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // Main content (map + panel + buttons)
          _buildRunningContent(session, l10n, screenHeight),

          // 倒计时覆盖层（完全淡出后彻底移除，避免Positioned.fill干扰触控）
          if (!_initError && !_countdownOverlayRemoved) _buildCountdownOverlay(),

          // Init error overlay
          if (_initError) _buildInitErrorOverlay(),

          // Lock screen overlay
          if (_isLocked) _buildLockScreen(session, l10n),

          // GPS 搜索覆盖层（位置由 runSessionProvider管理，默认不显示；倒计时期间不叠加干扰）
          if (!_initError && !_countdownOverlayVisible && !_locationInitialized) _buildGpsOverlay(l10n),
        ],
      ),
    );
  }

  Widget _buildRunningContent(RunSessionState session, AppLocalizations l10n, double screenHeight) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    _buttonAreaHeight = 48.h + bottomInset;
    _panelMinHeight = screenHeight * 0.22;
    _panelMaxHeight = screenHeight * 0.60;

    if (_panelHeight <= 0) {
      _panelHeight = _panelMinHeight;
    }

    // 地图始终立即创建（倒计时期间用户可见地图加载），面板倒计时结束后才渲染
    return Stack(
      children: [
        // Map layer (full screen) — 立即创建，不等倒计时结束
        Positioned.fill(child: _buildMapLayer(session)),

        // 底部一体式容器（面板 + 按钮）— 倒计时期间不渲染，结束后才显示
        if (!_countdownOverlayVisible)
          Positioned(
            left: 0, right: 0,
            bottom: 0,
            child: _buildCustomPanel(session, l10n),
          ),
      ],
    );
  }

  Color _hrZoneColor(int hr) {
    if (hr >= 165) return const Color(0xFFFF3B30);
    if (hr >= 140) return const Color(0xFFFF6B35);
    if (hr >= 120) return const Color(0xFFFF9500);
    return const Color(0xFF34C759);
  }

Widget _buildCustomPanel(RunSessionState session, AppLocalizations l10n) {
    final screenHeight = MediaQuery.of(context).size.height;
    _panelMinHeight = screenHeight * 0.22;
    _panelMaxHeight = screenHeight * 0.60;

    if (_panelHeight <= 0) {
      _panelHeight = _panelMinHeight;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: _panelHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A1A),
            const Color(0xFF000000),
            const Color(0xFF000000),
          ],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      child: Column(
        children: [
          // 拖拽条（独立手势，不跟滚动冲突）
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_panelHeight > _panelMinHeight + 20.h) {
                _snapPanel(-1000);
              } else {
                _snapPanel(1000);
              }
            },
            onVerticalDragStart: (d) {
              _panelDragStart = _panelHeight;
              _panelDragStartY = d.globalPosition.dy;
            },
            onVerticalDragUpdate: (d) {
              final delta = _panelDragStartY - d.globalPosition.dy;
              setState(() {
                _panelHeight = (_panelDragStart + delta).clamp(_panelMinHeight, _panelMaxHeight);
              });
            },
            onVerticalDragEnd: (d) {
              _snapPanel(d.primaryVelocity ?? 0);
            },
            child: Container(
              height: 60.h,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16.h),
                  Container(
                    width: 72.w, height: 7.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Container(
                    width: 72.w, height: 7.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 可滚动内容区
          if (_panelHeight > _panelMinHeight + 20.h)
            Expanded(
              child: Container(
                color: const Color(0xFF000000),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: _buildPanelContent(session, l10n),
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                color: const Color(0xFF000000),
                child: Center(
                  child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 距离
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
            ((session.currentRun?.totalDistance ?? 0) / 1000).toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 22.sp, fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'km',
                            style: TextStyle(
                              fontSize: 11.sp, fontWeight: FontWeight.w500,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      // 配速
                      Padding(
                        padding: EdgeInsets.only(left: 4.w),
                        child: Text(
                          session.currentRun?.avgPace != null
                              ? _formatPace(session.currentRun!.avgPace!)
                              : "--'",
                          style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // 时间
                      Padding(
                        padding: EdgeInsets.only(left: 4.w),
                        child: Text(
                          _formatTime(session.currentRun?.totalTime ?? 0),
                          style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          // 底部固定按钮区（始终在最底，不透过地图）
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF000000),
            ),
            child: _buildBottomControls(session, l10n),
          ),
        ],
      ),
    );
  }Widget _buildPanelContent(RunSessionState session, AppLocalizations l10n) {
    final distance = session.currentRun?.totalDistance ?? 0;
    final duration = session.currentRun?.totalTime ?? 0;
    final pace = session.currentRun?.avgPace;
    final heartRate = session.currentRun?.avgHeartRate;
    final cadence = session.currentRun?.avgCadence;
    final stride = session.currentRun?.avgStrideLength;
    final calories = session.currentRun?.calories ?? 0;

    final zone2Color = const Color(0xFF34C759);
    final zone3Color = const Color(0xFFFF9500);
    final zone4Color = const Color(0xFFFF6B35);
    final zone5Color = const Color(0xFFFF3B30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40.h), // 避开拖拽区

        if (session.runGoal != null) _buildGoalProgressCompact(session),

        // 伴跑/挑战：目标进度下方紧接对手信息
        if (session.runMode != RunMode.solo && session.opponentRun != null)
          _buildGhostSection(session),

        SizedBox(height: 8.h),

        // Distance (居中大字)
        Center(
          child: Column(
            children: [
              Text(
                (distance / 1000).toStringAsFixed(2),
                style: TextStyle(fontSize: 52.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 0.95),
              ),
              Text("公里", style: TextStyle(fontSize: 16.sp, color: Colors.white38, letterSpacing: 3, fontWeight: FontWeight.w700)),
            ],
          ),
        ),

        SizedBox(height: 10.h),

        // Row 1: Pace | Time
        Row(children: [
          Expanded(child: _dataMetric(icon: Icons.directions_run, label: "配速", value: pace != null ? _formatPace(pace) : "--'--")),
          _vertDivider(),
          Expanded(child: _dataMetric(icon: Icons.timer_outlined, label: "时间", value: _formatTime(duration))),
        ]),

        SizedBox(height: 8.h),

        // Row 2: HR | Cadence | Stride
        Row(children: [
          Expanded(child: _dataMetric(icon: Icons.favorite_outline, label: "心率", value: heartRate != null && heartRate > 0 ? "$heartRate" : "--", valueColor: heartRate != null ? _hrZoneColor(heartRate) : null)),
          _vertDivider(),
          Expanded(child: _dataMetric(icon: Icons.speed, label: "步频", value: cadence != null && cadence > 0 ? "$cadence" : "--")),
          _vertDivider(),
          Expanded(child: _dataMetric(icon: Icons.straighten, label: "步幅", value: stride != null && stride > 0 ? stride.toStringAsFixed(2) + "m" : "--")),
        ]),

        SizedBox(height: 8.h),

        // Row 3: Calories | Elevation (独跑显示，伴跑/挑战没太多空间)
        if (session.runMode == RunMode.solo)
          Row(children: [
            Expanded(child: _dataMetric(icon: Icons.local_fire_department, label: "消耗", value: "$calories")),
            _vertDivider(),
            Expanded(child: _dataMetric(icon: Icons.terrain, label: "海拔", value: "--")),
          ]),

        SizedBox(height: 8.h),

        // HR zone
        if (heartRate != null && heartRate > 0)
          Row(children: [
            _hrZoneDot(zone2Color, "燃脂", heartRate < 120),
            SizedBox(width: 8.w),
            _hrZoneDot(zone3Color, "有氧", heartRate >= 120 && heartRate < 140),
            SizedBox(width: 8.w),
            _hrZoneDot(zone4Color, "无氧", heartRate >= 140 && heartRate < 165),
            SizedBox(width: 8.w),
            _hrZoneDot(zone5Color, "极限", heartRate >= 165),
          ]),

        SizedBox(height: 40.h),
      ],
    );
  }

  // ==================== 面板吸附 ====================
      void _snapPanel(double velocity) {
    final screenHeight = MediaQuery.of(context).size.height;
    final snapHeights = <double>[
      screenHeight * _snapFractions[0],
      _panelMaxHeight,
    ];

    double target;
    if (velocity.abs() > 300) {
      target = velocity < 0 ? snapHeights.last : snapHeights.first;
    } else {
      target = snapHeights.first;
      for (final h in snapHeights) {
        if ((_panelHeight - h).abs() < (_panelHeight - target).abs()) {
          target = h;
        }
      }
    }

    setState(() {
      _panelHeight = target.clamp(_panelMinHeight, _panelMaxHeight);
    });
  }

Widget _dataMetric({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22.sp, color: Colors.white70),
            SizedBox(width: 8.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 30.sp,
                fontWeight: FontWeight.w900,
                color: valueColor ?? Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 15.sp, color: Colors.white54, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _vertDivider() {
    return Container(
      width: 1,
      height: 42.h,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _hrZoneDot(Color color, String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18.w, height: 18.w,
              decoration: BoxDecoration(
                color: isActive ? color : color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: isActive ? Colors.white : Colors.white54,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 底部控制按钮（华为风格） ====================

  void _showRunSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (context, setSheetState) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w, height: 4.h,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.r)),
                ),
                SizedBox(height: 20.h),
                Text('跑步设置', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: 24.h),
                // 语音播报开关
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('语音播报', style: TextStyle(fontSize: 16.sp, color: Colors.white)),
                    Switch(
                      value: _voiceService.enabled,
                      activeColor: warmOrange,
                      onChanged: (v) {
                        _voiceService.enabled = v;
                        setState(() {});
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // 调试日志入口
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.bug_report, size: 16.sp, color: Colors.white54),
                    label: Text('调试日志', style: TextStyle(fontSize: 14.sp, color: Colors.white54)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white12),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showDebugLog();
                    },
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showDebugLog() {
    final log = VoiceBroadcastService.current?.getDebugLog() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🎙️ 调试日志', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
            Text('${log.split('\n').length} 条', style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400.h,
          child: log.isEmpty
            ? Center(child: Text('暂无日志，请先跑步', style: TextStyle(color: Colors.white38, fontSize: 14.sp)))
            : GestureDetector(
                onLongPress: () {
                  // 长按复制
                  Clipboard.setData(ClipboardData(text: log));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('日志已复制到剪贴板'), duration: Duration(seconds: 2)),
                  );
                },
                child: SingleChildScrollView(
                  child: SelectableText(
                    log,
                    style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontFamily: 'monospace', height: 1.4),
                  ),
                ),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('关闭', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(RunSessionState session, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(top: 4.h, bottom: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 16.w),

            // 锁屏（左边）
            _ctrlBtn(
              _isLocked ? Icons.lock : Icons.lock_open,
              () => setState(() => _isLocked = true),
              Colors.white54,
            ),

              const Spacer(),

              // 暂停/继续（大圆形，居中 — 华为风格实心橙）
              GestureDetector(
                onTap: () {
                  if (session.isPaused) {
                    ref.read(runSessionProvider.notifier).resumeRun();
                  } else {
                    ref.read(runSessionProvider.notifier).pauseRun();
                  }
                },
                child: Container(
                  width: 68.w,
                  height: 68.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: warmOrange,
                    boxShadow: [
                      BoxShadow(
                        color: warmOrange.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    session.isPaused ? Icons.play_arrow : Icons.pause,
                    size: 40.sp,
                    color: Colors.white,
                  ),
                ),
              ),

              // 暂停后才显示结束按钮
              if (session.isPaused) ...[SizedBox(width: 28.w), _endBtn(session, l10n)],

              const Spacer(),

              // 设置（右边）
              _ctrlBtn(
                Icons.tune,
                _showRunSettings,
                Colors.white54,
              ),

            SizedBox(width: 16.w),
          ],
        ),
      ),
    );
  }

  Widget _endBtn(RunSessionState session, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _showFinishDialog(session, l10n),
      child: Container(
        width: 68.w,
        height: 68.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: huaweiRed,
          boxShadow: [
            BoxShadow(
              color: huaweiRed.withValues(alpha: 0.40),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stop, size: 24.sp, color: Colors.white),
            Text('结束', style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.w),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Icon(icon, size: 20.sp, color: color.withValues(alpha: 0.70)),
      ),
    );
  }

  // ==================== 目标进度条（紧凑） ====================

  Widget _buildGoalProgressCompact(RunSessionState session) {
    final goal = session.runGoal!;
    final distance = session.currentRun?.totalDistance ?? 0;
    final duration = session.currentRun?.totalTime ?? 0;
    const weight = 65.0;
    final estCalories = (weight * distance / 1000 * 1.036).round();

    double progress;
    String currentStr, goalStr;

    switch (goal.type) {
      case RunGoalType.distance:
        final targetMeters = goal.value * 1000;
        progress = (distance / targetMeters).clamp(0.0, 1.0);
        currentStr = '${(distance / 1000).toStringAsFixed(1)}';
        goalStr = '${goal.value.toStringAsFixed(goal.value == goal.value.roundToDouble() ? 0 : 1)}km';
        break;
      case RunGoalType.duration:
        final targetSecs = goal.value * 60;
        progress = (duration / targetSecs).clamp(0.0, 1.0);
        currentStr = _formatTime(duration);
        goalStr = '${goal.value.round()}分钟';
        break;
      case RunGoalType.calories:
        progress = (estCalories / goal.value).clamp(0.0, 1.0);
        currentStr = '$estCalories';
        goalStr = '${goal.value.round()}千卡';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.h,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? const Color(0xFF4CAF50) : warmOrange,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(currentStr, style: TextStyle(fontSize: 14.sp, color: warmOrangeLight, fontWeight: FontWeight.w700)),
              if (progress < 1.0)
                Text(goalStr, style: TextStyle(fontSize: 13.sp, color: Colors.white54, fontWeight: FontWeight.w600))
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, size: 12.sp, color: const Color(0xFFFFD700)),
                    SizedBox(width: 3.w),
                    Text('目标达成!', style: TextStyle(fontSize: 13.sp, color: const Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 幽灵对手对比栏 ====================

  Widget _buildGhostSection(RunSessionState session) {
    final opponent = session.opponentRun!;
    final opponentPace = opponent.avgPace ?? 0;
    final currentPace = session.currentRun?.avgPace;
    final opponentDistance = opponent.totalDistance;
    final currentDistance = session.currentRun?.totalDistance ?? 0;

    // 进度百分比
    final progress = opponentDistance > 0
        ? (currentDistance / opponentDistance).clamp(0.0, 1.0)
        : 0.0;

    // 配速差
    String paceDiffStr = '';
    Color diffColor = Colors.grey;
    if (currentPace != null && opponentPace > 0) {
      final diff = opponentPace - currentPace;
      if (diff.abs() < 5) {
        paceDiffStr = '持平';
        diffColor = Colors.white70;
      } else if (diff > 0) {
        paceDiffStr = '快${(diff / 60).toStringAsFixed(1)}';
        diffColor = const Color(0xFF34C759); // 绿色=领先
      } else {
        paceDiffStr = '慢${(diff.abs() / 60).toStringAsFixed(1)}';
        diffColor = const Color(0xFFFF6B6B); // 红色=落后
      }
    }

    return Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, size: 18.sp, color: Colors.white70),
                SizedBox(width: 6.w),
                Text(
                  session.runMode == RunMode.challenge ? '挑战' : '伴跑',
                  style: TextStyle(fontSize: 15.sp, color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                Text(
                  ' · $paceDiffStr',
                  style: TextStyle(fontSize: 15.sp, color: diffColor, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '目标 ${(opponentDistance / 1000).toStringAsFixed(1)}km',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white54, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  session.runMode == RunMode.challenge
                      ? const Color(0xFFFF6B6B)
                      : warmOrangeLight,
                ),
                minHeight: 6.h,
              ),
            ),
          ],
        ),
      );
  }

  // ==================== 地图层（用于卡片4） ====================

  Widget _buildMapLayer(RunSessionState session) {
    final points = session.samples
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    return AmapMapView(
      myLocationEnabled: true,
      followMyLocation: true,
      polylines: points.length >= 2 ? {buildTrackPolyline(points)} : {},
    );
  }

  // ==================== GPS 搜星遮罩 ====================

  Widget _buildGpsOverlay(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // 脉冲动画圆圈
            SizedBox(
              width: 140.w,
              height: 140.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_pulseController != null)
                    AnimatedBuilder(
                      animation: _pulseController!,
                      builder: (ctx, child) {
                        return Container(
                          width: 140.w * (0.4 + _pulseController!.value * 0.5),
                          height: 140.w * (0.4 + _pulseController!.value * 0.5),
                          decoration: BoxDecoration(
                            color: Colors.orange
                                .withValues(alpha: 0.06 * (1 - _pulseController!.value)),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                          width: 2.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 26.w,
                            height: 26.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'GPS',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'GPS 搜星中',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '请保持在开阔地带\n正在搜索卫星信号…',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
            const Spacer(flex: 1),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                '取消',
                style: TextStyle(fontSize: 16.sp, color: Colors.white54),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // ==================== 初始化错误遮罩 ====================

  Widget _buildInitErrorOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.redAccent),
            SizedBox(height: 16.h),
            Text(
              '启动失败',
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            if (_initErrorMsg.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Text(
                  _initErrorMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                ),
              ),
            ],
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _initError = false;
                  _initErrorMsg = '';
                });
                _doInit();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: warmOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 倒计时遮罩 ====================

  Widget _buildCountdownOverlay() {
    final isGo = _countdownValue == 0;

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _countdownOverlayVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_countdownOverlayVisible,
          child: Center(
            child: isGo ? _buildGoText() : _buildCountdownNumber(),
          ),
        ),
      ),
    );
  }

  /// 分段倒计时数字动画：3→2→1，每个数字独立从大→小→淡出
  Widget _buildCountdownNumber() {
    return AnimatedBuilder(
      animation: _countdownAnimController!,
      builder: (context, _) {
        final progress = _countdownAnimController!.value;

        // 将5秒动画平分为3段（0→0.33→0.67→1.0），每段对应一个数字
        final segment = (progress * 3).floor().clamp(0, 2);
        final segStart = segment / 3.0;
        final segEnd = (segment + 1) / 3.0;
        // 段内进度 0→1：每个数字从大到小独立播放
        final localProgress = ((progress - segStart) / (segEnd - segStart)).clamp(0.0, 1.0);

        final number = 3 - segment;
        final scale = 2.2 - (localProgress * 1.9);  // 2.2 → 0.3
        final opacity = 1.0 - (localProgress * 1.0); // 1.0 → 0.0

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 180.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 24, offset: const Offset(0, 3)),
                  Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 50, offset: const Offset(0, 0)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// "开始运动！" 缓慢放大淡入：从一点大 → 铺满屏幕 → 淡出消失
  Widget _buildGoText() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200), // 慢放1.2秒逐步显现
      curve: Curves.easeOut,
      builder: (context, value, child) {
        // 从半透明微缩 → 清晰可见（不换行）
        return Opacity(
          opacity: 0.3 + (value * 0.7), // 0.3 → 1.0，先透明显出轮廓
          child: Transform.scale(
            scale: 0.5 + (value * 1.0), // 0.5 → 1.5，适中大小不换行
            child: child,
          ),
        );
      },
      child: Text(
        '开始运动！',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 72.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2979FF),
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 24, offset: const Offset(0, 3)),
            Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 50, offset: const Offset(0, 0)),
          ],
        ),
      ),
    );
  }

  // ==================== 锁屏 ====================

  Widget _buildLockScreen(RunSessionState session, AppLocalizations l10n) {
    final distance = session.currentRun?.totalDistance ?? 0;
    final duration = session.currentRun?.totalTime ?? 0;

    return SizedBox.expand(
      child: Stack(
        children: [
          // 全屏触摸拦截层：tap+longPress 全吃，兄弟组件摸不到
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              onLongPressStart: (_) {
                setState(() => _isLocked = false);
              },
              child: Container(color: Colors.black.withValues(alpha: 0.88)),
            ),
          ),
          // 内容层
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 36.sp, color: Colors.white54),
                  SizedBox(height: 40.h),
                  Text(
                    (distance / 1000).toStringAsFixed(2),
                    style: TextStyle(fontSize: 72.sp, fontWeight: FontWeight.w200, color: Colors.white, height: 1.1),
                  ),
                  Text(l10n.km, style: TextStyle(fontSize: 18.sp, color: Colors.white54, letterSpacing: 2)),
                  SizedBox(height: 24.h),
                  Text(_formatTime(duration), style: TextStyle(fontSize: 28.sp, color: Colors.white60, fontWeight: FontWeight.w300)),
                  SizedBox(height: 60.h),
                  Text('长按解锁', style: TextStyle(fontSize: 14.sp, color: Colors.white38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 结束弹窗 ====================

  void _showFinishDialog(RunSessionState session, AppLocalizations l10n) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 40.w),
              padding: EdgeInsets.only(top: 32.h, bottom: 24.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: warmOrange.withValues(alpha: 0.12),
                    ),
                    child: Icon(Icons.flag_outlined, size: 28.sp, color: warmOrange),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.finish,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      l10n.finishRunConfirm,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 14.sp, height: 1.5),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white60,
                              side: BorderSide(color: Colors.white24),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            ),
                            child: Text(l10n.cancel, style: TextStyle(fontSize: 15.sp)),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                await _completeRunWithMode();
                              } catch (e) {
                                debugPrint('💥 完成跑步异常: $e');
                                if (context.mounted) {
                                  RunningPage.onFinishRun?.call(null);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: warmOrange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                              elevation: 0,
                            ),
                            child: Text(l10n.confirm, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
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
      },
    );
  }

  // ==================== 工具方法 ====================

  Future<void> _completeRunWithMode() async {
    final api = ref.read(runSessionProvider.notifier);
    final session = ref.read(runSessionProvider);
    final opponentRun = session.opponentRun;

    Run? run;
    try {
      run = await api.finishRun();
    } catch (e) {
      debugPrint('⚠️ finishRun 异常: $e');
    }

    if (run != null) {
      try {
        final api = ref.read(apiServiceProvider);
        if (session.runMode == RunMode.companion && opponentRun != null) {
          await api.companionRun(opponentRun.id);
          debugPrint('✅ 伴跑完成，热度+1: ${opponentRun.id}');
        } else if (session.runMode == RunMode.challenge && opponentRun != null) {
          final createResp = await api.createChallenge({
            'route_id': session.selectedRoute?.id ?? '',
            'target_run_id': opponentRun.id,
            'ghost_mode': session.ghostMode?.name ?? 'real_replay',
            'goal_metric': session.challengeMetric?.name,
          });
          if (createResp.isSuccess) {
            final challengeId = createResp.data!['id'] as String;
            final startResp = await api.startChallenge(challengeId);
            if (startResp.isSuccess && run.id.isNotEmpty) {
              await api.completeChallenge(challengeId, {
                'run_id': run.id,
                'result': {},
              });
              debugPrint('✅ 挑战跑完成: $challengeId / run: ${run.id}');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ 伴跑/挑战跑后处理失败: $e');
      }
    }

    if (context.mounted) {
      RunningPage.onFinishRun?.call(run);
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(int paceSeconds) {
    final m = paceSeconds ~/ 60;
    final s = paceSeconds % 60;
    return "${m}'${s.toString().padLeft(2, '0')}\"";
  }
}
