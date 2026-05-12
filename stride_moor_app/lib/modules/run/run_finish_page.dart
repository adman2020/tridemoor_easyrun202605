import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';
import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';

import '../../config/constants.dart';
import '../../core/models/device.dart';
import '../../core/models/run.dart';
import '../../core/providers/run_provider.dart';
import '../../widgets/amap_map_view.dart';

/// 暖金橘
const Color _warmOrange = Color(0xFFFF8533);
const Color _warmOrangeLight = Color(0xFFFFAA66);

/// 跑步完成页 —— 华为运动健康风格
class RunFinishPage extends ConsumerWidget {
  final Run? run;

  const RunFinishPage({super.key, this.run});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(runSessionProvider);
    final runMode = session.runMode;
    final opponentRun = session.opponentRun;
    final distance = run?.totalDistance ?? 0;
    final duration = run?.totalTime ?? 0;
    final pace = run?.avgPace;
    final heartRate = run?.avgHeartRate;
    final cadence = run?.avgCadence;
    final stride = run?.avgStrideLength;
    final calories = run?.calories ?? 0;
    final elevation = run?.elevationGain ?? 0;
    final samples = run?.samples ?? [];

    // 构建轨迹点
    final points = samples
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, size: 20.sp, color: Colors.white70),
                    onPressed: () {
                      ref.read(runSessionProvider.notifier).reset();
                      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                    },
                  ),
                  const Spacer(),
                  Icon(Icons.more_horiz, color: Colors.white38),
                ],
              ),
            ),

            // 滚动内容
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ====== 轨迹迷你地图 ======
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      height: 200.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: points.length >= 2
                          ? AmapMapView(
                              myLocationEnabled: false,
                              followMyLocation: false,
                              polylines: {
                                buildTrackPolyline(
                                  points,
                                  color: _warmOrange,
                                  width: 4,
                                ),
                              },
                              initialCameraPosition: CameraPosition(
                                target: points.first,
                                zoom: 15,
                              ),
                            )
                          : Container(
                              color: const Color(0xFF1A1A1D),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map_outlined, size: 40.sp, color: Colors.white24),
                                    SizedBox(height: 8.h),
                                    Text('无轨迹数据', style: TextStyle(fontSize: 13.sp, color: Colors.white38)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    SizedBox(height: 20.h),

                    // ====== 核心数据（三列） ======
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Expanded(child: _BigCard(label: '距离', value: '${(distance / 1000).toStringAsFixed(2)}', unit: '公里')),
                          SizedBox(width: 12.w),
                          Expanded(child: _BigCard(label: '用时', value: _formatTime(duration), unit: '')),
                          SizedBox(width: 12.w),
                          Expanded(child: _BigCard(label: '配速', value: pace != null && pace > 0 ? _formatPace(pace) : '--\'--"', unit: '/公里')),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ====== 详细指标网格 ======
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1D),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.favorite,
                              iconColor: const Color(0xFFFF6B6B),
                              label: '心率',
                              value: heartRate != null && heartRate > 0 ? '$heartRate' : '--',
                              unit: 'bpm',
                            ),
                            Divider(color: Colors.white10, height: 24.h),
                            _DetailRow(
                              icon: Icons.directions_run,
                              iconColor: _warmOrange,
                              label: '步频',
                              value: cadence != null && cadence > 0 ? '$cadence' : '--',
                              unit: '步/分',
                            ),
                            Divider(color: Colors.white10, height: 24.h),
                            _DetailRow(
                              icon: Icons.straighten,
                              iconColor: _warmOrangeLight,
                              label: '步幅',
                              value: stride != null && stride > 0 ? stride.toStringAsFixed(2) : '--',
                              unit: '米',
                            ),
                            Divider(color: Colors.white10, height: 24.h),
                            _DetailRow(
                              icon: Icons.terrain,
                              iconColor: Colors.blueGrey,
                              label: '爬升',
                              value: '$elevation',
                              unit: '米',
                            ),
                            Divider(color: Colors.white10, height: 24.h),
                            _DetailRow(
                              icon: Icons.local_fire_department,
                              iconColor: const Color(0xFFFF6B35),
                              label: '消耗',
                              value: '$calories',
                              unit: '千卡',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ====== 路线匹配结果 ======
                    if (runMode == RunMode.solo && session.matchedRoute != null)
                      _buildRouteMatch(session.matchedRoute!, run ?? session.currentRun),

                    SizedBox(height: 16.h),

                    // ====== 伴跑/挑战跑对比 ======
                    if (runMode != RunMode.solo && opponentRun != null)
                      _buildComparison(session, runMode, opponentRun, run, distance, duration, pace),

                    SizedBox(height: 16.h),

                    // 返回首页
                    TextButton(
                      onPressed: () {
                        ref.read(runSessionProvider.notifier).reset();
                        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                      },
                      child: Text('返回首页', style: TextStyle(fontSize: 13.sp, color: Colors.white38)),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  /// 伴跑/挑战跑对比面板
  Widget _buildComparison(
    RunSessionState session,
    RunMode mode,
    Run opponent,
    Run? currentRun,
    double distance,
    int duration,
    int? pace,
  ) {
    final opponentPace = opponent.avgPace ?? 0;
    final isChallenge = mode == RunMode.challenge;
    final modeLabel = isChallenge ? '挑战跑' : '伴跑';

    // 判断胜负（仅挑战跑）
    // 规则：配速越小越好
    String? resultLabel;
    Color? resultColor;
    if (isChallenge && pace != null && opponentPace > 0) {
      if (pace < opponentPace) {
        resultLabel = '🏆 你赢了！';
        resultColor = const Color(0xFF34C759);
      } else if (pace > opponentPace) {
        resultLabel = '💪 再接再厉';
        resultColor = const Color(0xFFFF6B6B);
      } else {
        resultLabel = '🤝 平局！';
        resultColor = Colors.white70;
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1D),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isChallenge ? const Color(0xFFFF6B6B).withOpacity(0.3) : _warmOrangeLight.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                // 伴跑：双人并排 / 挑战跑：人+奖杯
                isChallenge
                    ? SizedBox(
                        width: 22.sp,
                        height: 26.sp,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(bottom: 0, left: 1, child: Icon(Icons.directions_run, size: 18.sp, color: const Color(0xFFFF6B6B))),
                            Positioned(top: -2, left: 6, child: Icon(Icons.emoji_events, size: 10.sp, color: const Color(0xFFFFD700))),
                          ],
                        ),
                      )
                    : SizedBox(
                        width: 24.sp,
                        height: 20.sp,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.directions_run, size: 16.sp, color: _warmOrangeLight),
                            Positioned(left: 10, child: Icon(Icons.directions_run, size: 16.sp, color: _warmOrangeLight)),
                          ],
                        ),
                      ),
                SizedBox(width: 8.w),
                Text(
                  modeLabel,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (resultLabel != null)
                  Text(
                    resultLabel,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: resultColor,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            // 对比表头
            Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                  child: Text(
                    '你',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.sp, color: _warmOrange, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Text(
                    '对手',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.sp, color: Colors.white54),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // 距离
            _compareRow(
              '距离',
              '${(distance / 1000).toStringAsFixed(2)}km',
              '${(opponent.totalDistance / 1000).toStringAsFixed(2)}km',
              distance > opponent.totalDistance,
            ),
            Divider(color: Colors.white10, height: 20.h),
            // 用时
            _compareRow(
              '用时',
              _formatTime(duration),
              _formatTime(opponent.totalTime),
              isChallenge && (session.challengeMetric == null || session.challengeMetric == ChallengeMetric.pace)
                  ? duration < opponent.totalTime
                  : duration < opponent.totalTime,
            ),
            Divider(color: Colors.white10, height: 20.h),
            // 配速
            _compareRow(
              '配速',
              pace != null && pace > 0 ? _formatPace(pace) : "--'--",
              opponentPace > 0 ? _formatPace(opponentPace) : "--'--",
              isChallenge && (session.challengeMetric == null || session.challengeMetric == ChallengeMetric.pace)
                  ? (pace ?? 9999) < opponentPace
                  : (pace ?? 9999) < opponentPace,
            ),
          ],
        ),
      ),
    );
  }

  Widget _compareRow(String label, String myValue, String opponentValue, bool iAmBetter) {
    return Row(
      children: [
        SizedBox(
          width: 44.w,
          child: Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: Colors.white54),
          ),
        ),
        Expanded(
          child: Text(
            myValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: iAmBetter ? const Color(0xFF34C759) : Colors.white,
            ),
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Text(
            opponentValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
        ),
      ],
    );
  }

  /// 路线匹配结果面板
  Widget _buildRouteMatch(RouteMatchResult match, Run? run) {
    final overlapPercent = (match.overlap * 100).toStringAsFixed(1);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1D),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: match.overlap >= 0.8 ? const Color(0xFF34C759).withOpacity(0.3) : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, size: 18.sp, color: const Color(0xFF34C759)),
                SizedBox(width: 8.w),
                Text('路线匹配', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text('重合 $overlapPercent%', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF34C759))),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              match.routeName ?? '未命名路线',
              style: TextStyle(fontSize: 14.sp, color: Colors.white70),
            ),
            SizedBox(height: 4.h),
            Text(
              'GPS 采样点匹配 ${match.matched}/${match.total}',
              style: TextStyle(fontSize: 12.sp, color: Colors.white38),
            ),
            if (match.overlap >= 0.8) ...[SizedBox(height: 8.h),
              Text('✅ 已自动关联路线并更新排行榜',
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFF34C759))),
            ],
          ],
        ),
      ),
    );
  }
}

/// 大号数据卡片
class _BigCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _BigCard({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: _warmOrange,
              height: 1.1,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: TextStyle(fontSize: 11.sp, color: Colors.white38, height: 1.3),
            ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.white54, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// 指标行
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16.sp, color: iconColor),
        ),
        SizedBox(width: 12.w),
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.white60)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        SizedBox(width: 4.w),
        Text(unit, style: TextStyle(fontSize: 12.sp, color: Colors.white38)),
      ],
    );
  }
}
