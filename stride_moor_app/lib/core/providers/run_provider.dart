import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/constants.dart';
import '../models/device.dart';
import '../models/route.dart' as app_route;
import '../models/run.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/run_goal.dart';
import '../models/run_split.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/step_counter_service.dart';
import 'app_providers.dart';
import 'user_provider.dart';
import '../services/debug_step_logger.dart';
import '../services/voice_broadcast_service.dart';

/// 跑步详情（按 runId）
/// 注意：后端返回结构为 { run: Run, samples: [...], opponent_run: Run? }，需将数据注入 runJson 一并解析
/// 404 / not found 时返回空 Run 对象（用于友好空状态），不抛异常
/// 认证错误（401）直接抛异常，由 UI 层显示登录过期提示
final runDetailProvider = FutureProvider.family<Run, String>((ref, runId) async {
  // 监听用户状态，切换用户时自动刷新
  ref.watch(userProvider);

  final api = ref.read(apiServiceProvider);
  final resp = await api.getRunDetail(runId);
  if (!resp.isSuccess || resp.data == null) {
    // 记录不存在时返回空 Run，其他错误抛异常
    if (resp.message.contains('不存在') || resp.message.contains('not found')) {
      return Run(id: runId, userId: '', startTime: DateTime.now());
    }
    throw Exception(resp.message);
  }
  final runJson = resp.data!['run'] as Map<String, dynamic>? ?? {};
  final samples = resp.data!['samples'] as List<dynamic>?;
  if (samples != null && samples.isNotEmpty) {
    runJson['samples'] = samples;
  }
  final opponentRun = resp.data!['opponent_run'] as Map<String, dynamic>?;
  if (opponentRun != null && opponentRun.isNotEmpty) {
    runJson['opponent_run'] = opponentRun;
  }
  final opponentSamples = resp.data!['opponent_samples'] as List<dynamic>?;
  if (opponentSamples != null && opponentSamples.isNotEmpty) {
    runJson['opponent_samples'] = opponentSamples;
  }
  final goalMetric = resp.data!['goal_metric'] as String?;
  if (goalMetric != null) {
    runJson['goal_metric'] = goalMetric;
  }
  final run = Run.fromJson(runJson);

  // 如果后端没有保存分段数据但有 GPS 采样点，本地实时计算
  Run result = run;
  if (result.splits.isEmpty && samples != null && samples.length >= 2) {
    final sampleList = samples
        .map((e) => RunSample.fromJson(e as Map<String, dynamic>))
        .toList();
    final computedSplits = _computeSplitsFromSamples(run.id, sampleList);
    result = result.copyWith(splits: computedSplits);
  }
  // 对手跑也做同样的回退计算
  if (result.opponentRun != null && result.opponentRun!.splits.isEmpty && result.opponentSamples.length >= 2) {
    final oppSplits = _computeSplitsFromSamples(
      result.opponentRun!.id,
      result.opponentSamples,
    );
    result = result.copyWith(opponentRun: result.opponentRun!.copyWith(splits: oppSplits));
  }

  return result;
});

/// 从 GPS 采样点列表计算每公里分段数据
List<RunSplit> _computeSplitsFromSamples(String runId, List<RunSample> sampleList) {
  if (sampleList.length < 2) return [];
  final sorted = [...sampleList]..sort((a, b) => a.distanceFromStart.compareTo(b.distanceFromStart));
  final computedSplits = <RunSplit>[];
  const splitInterval = 1000.0;
  double lastSplitDist = 0.0;
  int lastSplitTime = 0;
  final startSampleTime = sorted.first.timestamp;

  for (int i = 1; i < sorted.length; i++) {
    final curSplitIdx = computedSplits.length;
    final dist = sorted[i].distanceFromStart;
    if (dist >= splitInterval * (curSplitIdx + 1)) {
      final splitDist = dist - lastSplitDist;
      final curSplitTime = sorted[i].timestamp
          .difference(startSampleTime)
          .inSeconds;
      final splitTime = curSplitTime - lastSplitTime;
      if (splitDist > 0 && splitTime > 0) {
        computedSplits.add(RunSplit(
          id: '${runId}_split_${computedSplits.length}',
          runId: runId,
          splitIndex: computedSplits.length,
          distance: splitDist,
          time: splitTime,
          pace: (splitTime / (splitDist / 1000)).round(),
        ));
        lastSplitDist = dist;
        lastSplitTime = curSplitTime;
      }
    }
  }
  return computedSplits;
}

/// 最近跑步列表（用于首页 DiscoverPage）
final recentRunsProvider = FutureProvider<List<Run>>((ref) async {
  // 监听用户状态，切换用户时自动刷新
  ref.watch(userProvider);
  final api = ref.read(apiServiceProvider);
  final resp = await api.getRunList(page: 1, pageSize: 10);
  if (!resp.isSuccess || resp.data == null) {
    throw Exception(resp.message);
  }
  final list = resp.data!['list'] as List<dynamic>? ?? [];
  return list.map((e) => Run.fromJson(e as Map<String, dynamic>)).toList();
});

/// 跑步历史记录列表（用于 RunHistoryPage，支持分页）
final runHistoryProvider = FutureProvider<List<Run>>((ref) async {
  // 监听用户状态，切换用户时自动刷新
  ref.watch(userProvider);
  final api = ref.read(apiServiceProvider);
  final resp = await api.getRunList(page: 1, pageSize: 100);
  if (!resp.isSuccess || resp.data == null) {
    throw Exception(resp.message);
  }
  final list = resp.data!['list'] as List<dynamic>? ?? [];
  return list.map((e) => Run.fromJson(e as Map<String, dynamic>)).toList();
});

/// 当前跑步状态管理
/// 
/// 职责：
/// - 管理跑步会话状态（开始/暂停/恢复/结束）
/// - 驱动 LocationService 进行 GPS 采集
/// - 实时计算距离/配速/时长
/// - 每5秒批量上传采样点到后端
/// - 开始和结束时调用后端 API
final runSessionProvider = StateNotifierProvider<RunSessionNotifier, RunSessionState>((ref) {
  final api = ref.read(apiServiceProvider);
  ref.keepAlive();
  return RunSessionNotifier(ref, apiService: api);
});

/// 跑步会话状态
class RunSessionState {
  final bool isRunning;
  final bool isPaused;
  final Run? currentRun;
  final List<RunSample> samples;
  final List<RunSplit> splits;
  final RunMode runMode;
  final GhostMode? ghostMode;
  final app_route.Route? selectedRoute;
  /// 伴跑/挑战跑的对手跑迹（已收藏的跑友跑步记录）
  final Run? opponentRun;
  final ChallengeMetric? challengeMetric;
  /// 跑步目标（单独跑时可选）
  final RunGoal? runGoal;
  /// 自动路线匹配结果
  final RouteMatchResult? matchedRoute;
  final BroadcastFrequency broadcastFrequency;
  final List<String> broadcastItems;
  final String voiceStyle;
  /// 用户历史跑步平均值（用于语音播报对比）
  final Map<String, dynamic>? historicalAverages;
  /// 是否首次跑步
  final bool isFirstRun;

  const RunSessionState({
    this.isRunning = false,
    this.isPaused = false,
    this.currentRun,
    this.samples = const [],
    this.splits = const [],
    this.runMode = RunMode.solo,
    this.ghostMode,
    this.selectedRoute,
    this.opponentRun,
    this.challengeMetric,
    this.runGoal,
    this.matchedRoute,
    this.broadcastFrequency = BroadcastFrequency.every1000m,
    this.broadcastItems = const ['pace', 'distance', 'duration', 'heart_rate', 'cadence', 'stride_length', 'calories'],
    this.voiceStyle = 'standard',
    this.historicalAverages,
    this.isFirstRun = false,
  });

  RunSessionState copyWith({
    bool? isRunning,
    bool? isPaused,
    Run? currentRun,
    List<RunSample>? samples,
    List<RunSplit>? splits,
    RunMode? runMode,
    GhostMode? ghostMode,
    app_route.Route? selectedRoute,
    Run? opponentRun,
    ChallengeMetric? challengeMetric,
    RouteMatchResult? matchedRoute,
    RunGoal? runGoal,
    BroadcastFrequency? broadcastFrequency,
    List<String>? broadcastItems,
    String? voiceStyle,
    Map<String, dynamic>? historicalAverages,
    bool? isFirstRun,
  }) {
    return RunSessionState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      currentRun: currentRun ?? this.currentRun,
      samples: samples ?? this.samples,
      splits: splits ?? this.splits,
      runMode: runMode ?? this.runMode,
      ghostMode: ghostMode ?? this.ghostMode,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      opponentRun: opponentRun ?? this.opponentRun,
      challengeMetric: challengeMetric ?? this.challengeMetric,
      matchedRoute: matchedRoute ?? this.matchedRoute,
      runGoal: runGoal ?? this.runGoal,
      broadcastFrequency: broadcastFrequency ?? this.broadcastFrequency,
      broadcastItems: broadcastItems ?? this.broadcastItems,
      voiceStyle: voiceStyle ?? this.voiceStyle,
      historicalAverages: historicalAverages ?? this.historicalAverages,
      isFirstRun: isFirstRun ?? this.isFirstRun,
    );
  }
}

class RunSessionNotifier extends StateNotifier<RunSessionState> {
  final Ref _ref;
  final ApiService _apiService;
  final LocationService _locationService = LocationService.instance;
  final StepCounterService _stepCounterService = StepCounterService.instance;
  Timer? _uploadTimer;
  Timer? _durationTimer;
  DateTime? _runStartTime;
  DateTime? _pauseStartTime;
  int _totalPauseSeconds = 0;
  int _elapsedSeconds = 0;
  int _lastUploadedIndex = 0;

  static const _prefsKeyFreq = 'broadcast_frequency';
  static const _prefsKeyItems = 'broadcast_items';
  static const _prefsKeyVoice = 'voice_style';
  static const _prefsKeyRunMode = 'run_mode';
  static const _prefsKeyGhostMode = 'ghost_mode';
  static const _prefsKeyChallengeMetric = 'challenge_metric';

  RunSessionNotifier(this._ref, {required ApiService apiService})
      : _apiService = apiService,
        super(const RunSessionState()) {
    _locationService.addListener(_onLocationUpdate);
    _stepCounterService.addListener(_onStepUpdate);
    _loadPreferences();
  }

  /// 从 SharedPreferences 加载已保存的设置
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final freqIndex = prefs.getInt(_prefsKeyFreq);
      final itemsJson = prefs.getString(_prefsKeyItems);
      final voice = prefs.getString(_prefsKeyVoice);
      final modeIndex = prefs.getInt(_prefsKeyRunMode);
      final ghostIndex = prefs.getInt(_prefsKeyGhostMode);
      final metricIndex = prefs.getInt(_prefsKeyChallengeMetric);

      state = state.copyWith(
        broadcastFrequency: freqIndex != null
            ? BroadcastFrequency.values[freqIndex]
            : null,
        broadcastItems: itemsJson != null
            ? (jsonDecode(itemsJson) as List).cast<String>()
            : null,
        voiceStyle: voice,
        runMode: modeIndex != null ? RunMode.values[modeIndex] : null,
        ghostMode: ghostIndex != null ? GhostMode.values[ghostIndex] : null,
        challengeMetric: metricIndex != null ? ChallengeMetric.values[metricIndex] : null,
      );
    } catch (e) {
      // 加载失败忽略，使用默认值
    }
  }

  /// 将用户设置保存到 SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyFreq, state.broadcastFrequency.index);
      await prefs.setString(_prefsKeyItems, jsonEncode(state.broadcastItems));
      await prefs.setString(_prefsKeyVoice, state.voiceStyle);
      await prefs.setInt(_prefsKeyRunMode, state.runMode.index);
      if (state.ghostMode != null) {
        await prefs.setInt(_prefsKeyGhostMode, state.ghostMode!.index);
      }
      if (state.challengeMetric != null) {
        await prefs.setInt(_prefsKeyChallengeMetric, state.challengeMetric!.index);
      }
    } catch (e) {
      // 保存失败忽略
    }
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    _durationTimer?.cancel();
    _locationService.removeListener(_onLocationUpdate);
    _stepCounterService.removeListener(_onStepUpdate);
    _locationService.stopTracking();
    _stepCounterService.stop();
    super.dispose();
  }

  /// 配置跑步参数（准备页调用）
  void configure({
    RunMode? mode,
    app_route.Route? route,
    /// 伴跑/挑战跑对手的跑步记录
    Run? opponentRun,
    GhostMode? ghost,
    ChallengeMetric? metric,
    RunGoal? goal,
    BroadcastFrequency? frequency,
    List<String>? items,
    String? voice,
  }) {
    state = state.copyWith(
      runMode: mode,
      selectedRoute: route,
      opponentRun: opponentRun,
      ghostMode: ghost,
      challengeMetric: metric,
      runGoal: goal,
      broadcastFrequency: frequency,
      broadcastItems: items,
      voiceStyle: voice,
    );
    _savePreferences();
  }

  /// 开始跑步 —— 调用后端创建记录 + 启动定位追踪 + 启动定时上传
  Future<void> startRun() async {
    String runId;
    DateTime startTime;

    // 尝试调用后端创建跑步记录
    try {
      final resp = await _apiService.startRun(routeId: state.selectedRoute?.id);
      if (resp.isSuccess && resp.data != null) {
        runId = resp.data!['run_id'] as String;
        final st = resp.data!['start_time'] as String?;
        startTime = st != null ? DateTime.parse(st) : DateTime.now();
      } else {
        debugPrint('startRun 后端返回失败: ${resp.message}，回退到本地模式');
        runId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        startTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('startRun API 异常，回退到本地模式: $e');
      runId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      startTime = DateTime.now();
    }

    // 加载历史平均数据（用于语音播报对比）
    Map<String, dynamic>? historicalAverages;
    bool isFirstRun = false;
    try {
      final avgResp = await _apiService.getRunAverages();
      if (avgResp.isSuccess && avgResp.data != null) {
        final avgData = avgResp.data!;
        final runCount = avgData['run_count'];
        if (runCount is int && runCount > 0) {
          historicalAverages = avgData;
        } else {
          isFirstRun = true;
        }
      } else {
        isFirstRun = true;
      }
    } catch (_) {
      // 加载失败不影响跑步
    }

    final run = Run(
      id: runId,
      userId: 'current_user',
      routeId: state.selectedRoute?.id,
      startTime: startTime,
      mode: state.runMode.name,
    );

    _runStartTime = DateTime.now();
    _pauseStartTime = null;
    _totalPauseSeconds = 0;
    _elapsedSeconds = 0;
    _lastUploadedIndex = 0;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      currentRun: run,
      samples: const [],
      splits: const [],
    );

    // 首次触发语音播报（重置播报状态 + 初始日志）
    VoiceBroadcastService.current?.reset();
    VoiceBroadcastService.current?.onStateUpdate(state);

    // 启动定位追踪（含前台服务保活）
    await DebugStepLogger.step(26, 'startTracking before');
    try {
      await _locationService.startTracking();
      await DebugStepLogger.step(27, 'startTracking ok');
    } catch (e) {
      debugPrint('⚠️ 定位追踪启动失败: $e');
      await DebugStepLogger.step(27, 'startTracking failed: $e');
    }
    // 启动计步器
    await DebugStepLogger.step(28, 'stepCounter start before');
    try {
      await _stepCounterService.start();
      await DebugStepLogger.step(29, 'stepCounter start ok');
    } catch (e) {
      debugPrint('⚠️ 计步器启动失败: $e');
      await DebugStepLogger.step(29, 'stepCounter start failed: $e');
    }

    // 每秒更新时长和实时统计数据
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isRunning || state.isPaused) return;
      _elapsedSeconds = _getRealElapsedSeconds();
      final distance = _locationService.totalDistance;
      final avgPace = distance > 0 ? (_elapsedSeconds / (distance / 1000)).round() : 0;
      state = state.copyWith(
        currentRun: state.currentRun?.copyWith(
          totalTime: _elapsedSeconds,
          totalDistance: distance,
          avgPace: avgPace,
        ),
      );
      // 直接触发语音播报（绕过 ref.listen 可能的失效问题）
      VoiceBroadcastService.current?.onStateUpdate(state);
    });

    // 每5秒批量上传采样点
    _uploadTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _uploadPendingSamples();
    });
  }

  /// 暂停
  void pauseRun() {
    _stepCounterService.pause();
    _pauseStartTime = DateTime.now();
    state = state.copyWith(isPaused: true);
  }

  /// 恢复
  void resumeRun() {
    _stepCounterService.resume();
    if (_pauseStartTime != null) {
      _totalPauseSeconds += DateTime.now().difference(_pauseStartTime!).inSeconds;
      _pauseStartTime = null;
    }
    state = state.copyWith(isPaused: false);
  }

  /// 结束跑步 —— 停止追踪 + 调用后端结束 + 返回最终 Run
  Future<Run?> finishRun() async {
    _uploadTimer?.cancel();
    _durationTimer?.cancel();
    await _locationService.stopTracking();
    _stepCounterService.stop();

    final run = state.currentRun;
    if (run == null) return null;

    // 最终数据
    final distance = _locationService.totalDistance;

    // 🚫 距离小于 10 米视为无效奔跑，不保存记录
    if (distance < 10) {
      debugPrint('⚠️ 距离过短（${distance.toStringAsFixed(1)}m），不保存记录');
      if (!run.id.startsWith('local_')) {
        // 删除后端已创建的记录
        try {
          await _apiService.deleteRun(run.id);
          debugPrint('✅ 已删除无效的跑步记录: ${run.id}');
        } catch (e) {
          debugPrint('⚠️ 删除无效记录失败: $e');
        }
      }
      state = const RunSessionState();
      return null;
    }

    final realElapsed = _getRealElapsedSeconds();
    final avgPace = distance > 0 ? (realElapsed / (distance / 1000)).round() : 0;
    // 步数传感器：真实步频和步幅
    final realCadence = _stepCounterService.cadence(realElapsed);
    final realStride = _stepCounterService.strideLength(distance);

    // 先上传剩余未上传的采样点
    await _uploadPendingSamples();

    // 从 GPS 采样点计算每公里分段数据（用于详情页配速曲线+后端存储）
    if (state.samples.length >= 2) {
      final computedSplits = <RunSplit>[];
      final sortedSamples = [...state.samples]
        ..sort((a, b) => a.distanceFromStart.compareTo(b.distanceFromStart));
      const splitInterval = 1000.0;
      double lastSplitDist = 0.0;
      int lastSplitTime = 0;
      final startSampleTime = sortedSamples.first.timestamp;

      for (int i = 1; i < sortedSamples.length; i++) {
        final curSplitIdx = computedSplits.length;
        final dist = sortedSamples[i].distanceFromStart;
        if (dist >= splitInterval * (curSplitIdx + 1)) {
          final splitDist = dist - lastSplitDist;
          final curSplitTime = sortedSamples[i].timestamp
              .difference(startSampleTime)
              .inSeconds;
          final splitTime = curSplitTime - lastSplitTime;
          if (splitDist > 0 && splitTime > 0) {
            computedSplits.add(RunSplit(
              id: '${run.id}_split_${computedSplits.length}',
              runId: run.id,
              splitIndex: computedSplits.length,
              distance: splitDist,
              time: splitTime,
              pace: (splitTime / (splitDist / 1000)).round(),
            ));
            lastSplitDist = dist;
            lastSplitTime = curSplitTime;
          }
        }
      }
      state = state.copyWith(splits: computedSplits);
    }

    // 调用后端结束（本地模式跳过）
    if (!run.id.startsWith('local_')) {
      RouteMatchResult? matchResult;
      try {
        final modeName = state.runMode == RunMode.companion
            ? 'companion'
            : state.runMode == RunMode.challenge
                ? 'challenge'
                : 'solo';
        final opponentRunId = state.opponentRun?.id;

        final body = <String, dynamic>{
          'end_time': DateTime.now().toUtc().toIso8601String(),
          'total_distance': distance,
          'total_time': realElapsed,
          'avg_pace': avgPace,
          'elevation_gain': run.elevationGain,
          'avg_cadence': run.avgCadence,
          'avg_stride_length': run.avgStrideLength,
          'calories': run.calories ?? 0,
          'mode': modeName,
        };
        if (opponentRunId != null) {
          body['opponent_run_id'] = opponentRunId;
        }
        // 发送分段数据（每公里配速），详情页展示用
        if (state.splits.isNotEmpty) {
          body['splits'] = state.splits.map((s) => <String, dynamic>{
            'split_index': s.splitIndex,
            'distance': s.distance,
            'time': s.time,
            'pace': s.pace,
            'avg_heart_rate': s.avgHeartRate,
            'avg_cadence': s.avgCadence,
            'avg_stride_length': s.avgStrideLength,
          }).toList();
        }
        final resp = await _apiService.finishRun(run.id, body);
        if (resp.isSuccess && resp.data != null) {
          if (resp.data!['match'] is Map<String, dynamic>) {
            final matchData = Map<String, dynamic>.from(resp.data!['match'] as Map<String, dynamic>);
            // 从独立的 route 对象中提取路线名称
            if (resp.data!['route'] is Map<String, dynamic>) {
              final routeData = resp.data!['route'] as Map<String, dynamic>;
              matchData['route_name'] = routeData['name'];
            }
            matchResult = RouteMatchResult.fromJson(matchData);
          }
        } else {
          debugPrint('finishRun API 返回错误: code=${resp.code}, msg=${resp.message}');
        }
      } catch (e) {
        debugPrint('finishRun API 异常: $e');
      }

      // 保存匹配结果到状态
      if (matchResult != null) {
        state = state.copyWith(matchedRoute: matchResult);
      }
      // 跑完后刷新运动记录列表
      _ref.invalidate(runHistoryProvider);
    }

    // 步频、步幅：优先用传感器真实数据，否则回退估算
    final cadenceToUse = realCadence ??
        (avgPace > 0 && realElapsed > 0
            ? (110 + (600 - avgPace) / 4.5).round().clamp(100, 220)
            : null);
    final strideToUse = realStride ??
        (cadenceToUse != null && distance > 0 && realElapsed > 0
            ? (distance / (cadenceToUse * realElapsed / 60.0)).clamp(0.3, 3.0)
            : null);

    final finishedRun = run.copyWith(
      endTime: DateTime.now(),
      totalTime: realElapsed,
      totalDistance: distance,
      avgPace: avgPace,
      avgCadence: cadenceToUse,
      avgStrideLength: strideToUse,
      calories: run.calories ?? 0,
      samples: state.samples,
      splits: state.splits,
    );

    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      currentRun: finishedRun,
    );

    return finishedRun;
  }

  /// 模拟跑步 —— 生成逼真曲线轨迹（无需 GPS、无需后端）
  /// 用于开发调试和 APK 验证
  /// 使用余弦插值路标点 + 正弦横向摇摆 + GPS 噪声模拟真实跑步
  Future<Run?> startMockRun() async {
    final runId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    const weight = 70.0;  // TODO: 后续从用户数据读取

    final run = Run(
      id: runId,
      userId: 'mock_user',
      startTime: startTime,
      mode: 'solo',
    );

    _elapsedSeconds = 0;
    _lastUploadedIndex = 0;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      currentRun: run,
      samples: const [],
      splits: const [],
    );

    // ============================================================
    // 1. 路标点：深圳湾公园沿海环路（闭合曲线）
    // ============================================================
    const waypoints = <List<double>>[
      [22.5431, 114.0579],  // 起点：深圳湾公园
      [22.5415, 114.0595],  // → 沿海岸线东南
      [22.5398, 114.0612],  // → 继续沿海
      [22.5375, 114.0628],  // → 最东南点
      [22.5360, 114.0605],  // → 折返
      [22.5372, 114.0580],  // → 回程
      [22.5395, 114.0565],  // → 回程
      [22.5418, 114.0572],  // → 回到起点附近
    ];

    // ============================================================
    // 2. 余弦插值生成平滑路径
    // ============================================================
    const pointsPerSegment = 28;
    final totalPoints = (waypoints.length - 1) * pointsPerSegment;
    final lats = <double>[];
    final lngs = <double>[];

    for (int seg = 0; seg < waypoints.length - 1; seg++) {
      final lat0 = waypoints[seg][0], lat1 = waypoints[seg + 1][0];
      final lng0 = waypoints[seg][1], lng1 = waypoints[seg + 1][1];
      for (int i = 0; i < pointsPerSegment; i++) {
        final t = i / pointsPerSegment;
        final ct = (1 - cos(t * pi)) / 2;  // 余弦插值
        lats.add(lat0 + (lat1 - lat0) * ct);
        lngs.add(lng0 + (lng1 - lng0) * ct);
      }
    }

    // ============================================================
    // 3. 叠加横向摇摆 + GPS 噪声
    // ============================================================
    final random = Random(42);  // 固定种子保证可复现
    for (int i = 0; i < totalPoints; i++) {
      final t = i / totalPoints;
      final wobble = 0.000025 * sin(2 * pi * 2.5 * t + 1.2);  // ~2.5m 横向摇摆
      lats[i] += wobble + (random.nextDouble() - 0.5) * 0.00003;
      lngs[i] += wobble * 0.6 + (random.nextDouble() - 0.5) * 0.00003;
    }

    // ============================================================
    // 4. 海拔（沿海平坦，缓慢起伏）
    // ============================================================
    final altitudes = List<double>.generate(totalPoints, (i) {
      final t = i / totalPoints;
      return 5.0 + 3.0 * sin(2 * pi * 1.5 * t) + (random.nextDouble() - 0.5) * 0.6;
    });

    // ============================================================
    // 5. 计算总距离
    // ============================================================
    const targetPace = 330;  // 5:30/km 放松跑
    double cumulativeDist = 0.0;
    for (int i = 0; i < totalPoints; i++) {
      if (i == 0) continue;
      cumulativeDist += _haversine(lats[i - 1], lngs[i - 1], lats[i], lngs[i]);
    }
    final totalDist = cumulativeDist;
    final totalSeconds = (totalDist / 1000 * targetPace).round();

    // ============================================================
    // 6. 生成采样点
    // ============================================================
    final now = DateTime.now();
    final adjustedIntervalMs = totalSeconds > 0
        ? (totalSeconds * 1000 / totalPoints).round()
        : 300;
    final mockSamples = <RunSample>[];
    cumulativeDist = 0.0;

    for (int i = 0; i < totalPoints; i++) {
      if (i > 0) {
        cumulativeDist += _haversine(lats[i - 1], lngs[i - 1], lats[i], lngs[i]);
      }

      final t = i / totalPoints;
      // 心率自然波动，145±10
      final hr = (145 + 8 * sin(2 * pi * 3.0 * t)).round().clamp(135, 160);
      // 步频 170±6
      final cad = (173 + 4 * sin(2 * pi * 2.0 * t + 0.5)).round();

      mockSamples.add(RunSample(
        timestamp: now.add(Duration(milliseconds: i * adjustedIntervalMs)),
        latitude: lats[i],
        longitude: lngs[i],
        altitude: altitudes[i],
        distanceFromStart: cumulativeDist,
        heartRate: hr,
        cadence: cad,
      ));
    }

    // ============================================================
    // 7. 生成分段数据（每 500m 一个 split）
    // ============================================================
    const splitInterval = 500.0;
    final splits = <RunSplit>[];
    double lastSplitDist = 0.0;
    int lastSplitTime = 0;

    for (int i = 1; i < mockSamples.length; i++) {
      final curSplitIdx = splits.length;
      if (mockSamples[i].distanceFromStart >= splitInterval * (curSplitIdx + 1)) {
        final splitDist = mockSamples[i].distanceFromStart - lastSplitDist;
        final splitTime = mockSamples[i].timestamp
            .difference(mockSamples[0].timestamp)
            .inSeconds - lastSplitTime;
        if (splitDist > 0 && splitTime > 0) {
          splits.add(RunSplit(
            id: 'mock_split_${splits.length}',
            runId: runId,
            splitIndex: splits.length,
            distance: splitDist,
            time: splitTime,
            pace: (splitTime / (splitDist / 1000)).round(),
            avgHeartRate: (mockSamples[i].heartRate ?? 145),
            avgCadence: (mockSamples[i].cadence ?? 170),
          ));
          lastSplitDist = mockSamples[i].distanceFromStart;
          lastSplitTime = splitTime;
        }
      }
    }

    // ============================================================
    // 8. 统计汇总
    // ============================================================
    _elapsedSeconds = totalSeconds;
    final avgPace = totalDist > 0 ? (_elapsedSeconds / (totalDist / 1000)).round() : 0;

    final validHr = mockSamples.where((s) => s.heartRate != null).map((s) => s.heartRate!).toList();
    final validCad = mockSamples.where((s) => s.cadence != null).map((s) => s.cadence!).toList();
    final avgHr = validHr.isEmpty ? 0 : validHr.reduce((a, b) => a + b) ~/ validHr.length;
    final avgCad = validCad.isEmpty ? 0 : validCad.reduce((a, b) => a + b) ~/ validCad.length;
    final avgStride = (avgPace > 0 && avgCad > 0)
        ? 60000.0 / (avgPace * avgCad)
        : 0.0;
    final calories = (weight * totalDist / 1000 * 1.036).round();
    final elevGain = altitudes.last - altitudes.first;

    final finishedRun = run.copyWith(
      endTime: startTime.add(Duration(seconds: _elapsedSeconds)),
      totalTime: _elapsedSeconds,
      totalDistance: totalDist,
      avgPace: avgPace,

      avgHeartRate: avgHr,
      maxHeartRate: avgHr + 12,
      avgCadence: avgCad,
      maxCadence: avgCad + 6,
      avgStrideLength: avgStride,
      elevationGain: elevGain > 0 ? elevGain : 0,
      elevationLoss: 0,
      calories: calories,
      temperature: 26,
      samples: mockSamples,
      splits: splits,
    );

    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      currentRun: finishedRun,
      samples: mockSamples,
    );

    debugPrint('🏃 模拟跑步完成:'
        ' ${(totalDist / 1000).toStringAsFixed(2)}km'
        ' / ${_formatDuration(_elapsedSeconds)}'
        ' / ${_formatPace(avgPace)}'
        ' / ❤️ $avgHr'
        ' / ${calories}kcal'
        ' / 🦶 $avgCad spm');
    return finishedRun;
  }

  /// 计算两点间距离（米，Haversine 公式）
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // 地球半径
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final sinDLat = sin(dLat / 2);
    final sinDLon = sin(dLon / 2);
    final a = sinDLat * sinDLat +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sinDLon * sinDLon;
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  String _formatPace(int paceSeconds) {
    if (paceSeconds <= 0) return "--'--\"";
    final m = paceSeconds ~/ 60;
    final s = paceSeconds % 60;
    return "${m}'${s.toString().padLeft(2, '0')}\"";
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      return '${h}:${(m % 60).toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 重置状态（结束页返回首页后调用）
  void reset() {
    final runId = state.currentRun?.id;
    // 如果创建了后端记录但未完成（未跑/空跑），删除它
    if (runId != null &&
        !runId.startsWith('local_') &&
        !runId.startsWith('mock_') &&
        state.isRunning) {
      _deleteBackendRun(runId);
    }

    _uploadTimer?.cancel();
    _durationTimer?.cancel();
    _locationService.stopTracking();
    _stepCounterService.stop();
    _runStartTime = null;
    _pauseStartTime = null;
    _totalPauseSeconds = 0;
    _elapsedSeconds = 0;
    _lastUploadedIndex = 0;
    state = const RunSessionState();
  }

  /// 基于墙钟时间获取真实运行时长（不受 Dart Timer 后台节流影响）
  int _getRealElapsedSeconds() {
    if (_runStartTime == null) return _elapsedSeconds; // fallback for mock runs
    final totalElapsed = DateTime.now().difference(_runStartTime!).inSeconds;
    final pauseDuration = _pauseStartTime != null
        ? _totalPauseSeconds + DateTime.now().difference(_pauseStartTime!).inSeconds
        : _totalPauseSeconds;
    final real = totalElapsed - pauseDuration;
    return real < 0 ? 0 : real;
  }

  /// 异步删除后端跑步记录（fire-and-forget）
  void _deleteBackendRun(String runId) {
    try {
      _apiService.deleteRun(runId).then((resp) {
        if (!resp.isSuccess) {
          debugPrint('删除空跑记录失败: code=${resp.code}, msg=${resp.message}');
        }
      });
    } catch (e) {
      debugPrint('删除空跑记录异常: $e');
    }
  }

  /// 计步器数据更新回调
  void _onStepUpdate() {
    if (!state.isRunning || state.isPaused) return;
    final steps = _stepCounterService.steps;
    if (steps <= 0) return;

    final distance = _locationService.totalDistance;
    final nowElapsed = _getRealElapsedSeconds();
    final cadence = _stepCounterService.cadence(nowElapsed);
    final stride = _stepCounterService.strideLength(distance);
    if (cadence == null && stride == null) return;

    state = state.copyWith(
      currentRun: state.currentRun?.copyWith(
        avgCadence: cadence,
        avgStrideLength: stride,
      ),
    );
  }

  /// 定位数据更新回调
  void _onLocationUpdate() {
    if (!state.isRunning || state.isPaused) return;
    final samples = _locationService.samples;
    if (samples.isEmpty) return;

    final currentCount = state.samples.length;
    if (samples.length <= currentCount) return;

    final newSamples = samples.sublist(currentCount);
    final allSamples = [...state.samples, ...newSamples];
    final distance = _locationService.totalDistance;
    final nowElapsed = _getRealElapsedSeconds();
    final avgPace = distance > 0 ? (nowElapsed / (distance / 1000)).round() : 0;

    // 计算卡路里：简单估算 ≈ 体重65kg × 距离km × 1.036
    final calories = (distance / 1000 * 65 * 1.036).round();

    // 步频、步幅：优先用传感器真实数据，否则回退估算
    final steps = _stepCounterService.steps;
    int? cadenceToUse;
    double? strideToUse;
    if (steps > 0 && nowElapsed > 0) {
      // 真实计步器数据
      cadenceToUse = (steps / (nowElapsed / 60.0)).round();
      strideToUse = (distance / steps).clamp(0.3, 3.0);
    } else if (avgPace > 0 && nowElapsed > 0) {
      // 回退估算
      cadenceToUse = (110 + (600 - avgPace) / 4.5).round().clamp(100, 220);
      final minutes = nowElapsed / 60.0;
      strideToUse = (distance / (cadenceToUse * minutes)).clamp(0.3, 3.0);
    }

    state = state.copyWith(
      samples: allSamples,
      currentRun: state.currentRun?.copyWith(
        totalDistance: distance,
        avgPace: avgPace,
        avgCadence: cadenceToUse,
        avgStrideLength: strideToUse,
        calories: calories,
      ),
    );
  }

  /// 批量上传未上传的采样点
  Future<void> _uploadPendingSamples() async {
    final run = state.currentRun;
    if (run == null || run.id.startsWith('local_')) return;
    if (_lastUploadedIndex >= state.samples.length) return;

    final pending = state.samples.sublist(_lastUploadedIndex);
    if (pending.isEmpty) return;

    final sampleMaps = pending.map((s) => {
      'sample_time': s.timestamp.toUtc().toIso8601String(),
      'latitude': s.latitude,
      'longitude': s.longitude,
      'altitude': s.altitude,
      'distance_from_start': s.distanceFromStart,
    }).toList();

    try {
      await _apiService.uploadSamples(run.id, sampleMaps);
      _lastUploadedIndex = state.samples.length;
    } catch (e) {
      debugPrint('上传采样点失败: $e');
    }
  }
}
