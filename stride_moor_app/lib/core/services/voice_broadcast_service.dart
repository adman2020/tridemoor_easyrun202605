import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/run_provider.dart';
import '../models/run.dart';
import '../models/run_goal.dart';
import '../../../config/constants.dart';

/// 语音播报服务
class VoiceBroadcastService {
  final FlutterTts _tts = FlutterTts();
  RunSessionState? _lastState;
  double _lastTriggerDistance = 0; // 上次播报时的距离（米）
  int _lastTriggerTime = 0;        // 上次播报时的耗时（秒）
  bool _isSpeaking = false;
  bool _goalAnnounced = false;     // 目标达成已播报
  int _motivationIndex = 0;        // 鼓励语录轮播索引
  int _currentSplitIndex = 0;      // 当前分段索引（用于伴跑/挑战跑同段对比）
  double? _prevElevation;          // 上次爬升检测值
  bool _sprintAnnounced = false;   // 冲刺已播报
  bool _abnormalPaceAnnounced = false; // 配速异常已播报
  bool _abnormalHrAnnounced = false;   // 心率异常已播报
  int _consecutiveWins = 0;            // 连续领先段数（伴跑）
  int _consecutiveLosses = 0;          // 连续落后段数（伴跑）
  int? _lastSegmentPaceDiff;           // 上段配速差（正=我快，负=我慢）
  double _cumulativeTimeGap = 0;        // 累计时间差（秒，正=领先，负=落后，挑战跑）

  // ─── 鼓励语录池（4 种风格） ──────────────────────────────

  static const _motivations = {
    'standard': [
      '加油，继续坚持！',
      '你已经很棒了，保持节奏！',
      '每一步都在超越自己！',
      '坚持就是胜利！',
      '跑起来，就对了！',
    ],
    'jianghu': [
      '道友道心坚定，大道可期！',
      '练气化神，神凝于足下！',
      '一步一修行，此乃修仙真意！',
      '磨砺筋骨，方成大器！',
      '心无旁骛，脚踏青云！',
    ],
    'coach': [
      '节奏保持得很好，注意呼吸！',
      '核心收紧，摆臂有力！',
      '调整呼吸，三步一呼！',
      '距离不远了，加油！',
      '收腹挺胸，保持跑姿！',
    ],
    'toxic': [
      '就这？再加把劲！',
      '别停下来，跑了就好好跑！',
      '速度呢？今天没吃饭？',
      '跑得太轻松了说明没尽全力！',
      '出汗了吗？没出汗等于白跑！',
    ],
  };

  static const _sprintTexts = {
    'standard': '最后冲刺！全力加速！',
    'jianghu': '冲鸭道友！最后的爆发，一飞冲天！',
    'coach': '最后一段了！调整呼吸，全力冲刺！',
    'toxic': '最后了还不冲？留着体力过年？',
  };

  /// 当前活跃实例（用于调试日志导出）
  static VoiceBroadcastService? current;

  VoiceBroadcastService() {
    _prevElevation = null;
    current = this;
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 全局开关（由 RunningPage 控制，provider 直接调用时也会检查）
  bool enabled = true;

  /// debug 日志缓存
  final List<String> _debugLog = [];

  void _log(String msg) {
    print(msg);
    _debugLog.add(msg);
    if (_debugLog.length > 500) _debugLog.removeAt(0);
  }

  /// 获取 debug 日志文本
  String getDebugLog() => _debugLog.join('\n');

  /// 初始化 TTS（配置语言/语速）
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
      });
      _isInitialized = true;
    } catch (e) {
      // TTS 初始化失败（如缺少语音包），不影响跑步功能
    }
  }

  /// 停止播报
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
  }

  /// 释放资源
  Future<void> dispose() async {
    await stop();
    _tts.setCompletionHandler(() {});
    _tts.setErrorHandler((_) {});
  }

  /// 每次状态更新时调用，触发播报条件检测
  Future<void> onStateUpdate(RunSessionState state) async {
    if (!enabled) return;
    // 暂停时不播报
    if (state.isPaused) {
      _log('🎙️ VOICE: paused, skip');
      return;
    }

    final run = state.currentRun;
    if (run == null) {
      _log('🎙️ VOICE: no currentRun, skip');
      return;
    }

    final distance = run.totalDistance;
    final duration = run.totalTime;
    final frequency = state.broadcastFrequency;

    _log('🎙️ VOICE: onStateUpdate dist=$distance duration=$duration freq=$frequency');

    // ── 异常检测（所有模式都检测） ──
    await _checkAnomalies(state);

    // ── 仅异常模式：不主动播报 ──
    if (frequency == BroadcastFrequency.abnormalOnly) {
      _log('🎙️ VOICE: abnormalOnly mode, no regular broadcast');
      return;
    }

    // ── 冲刺检测 ──
    if (state.broadcastItems.contains('sprint')) {
      await _checkSprint(state);
    }

    // ── 更新当前分段索引（伴跑/挑战跑用于同段对比） ──
    final splitKm = (distance / 1000).floor();
    if (splitKm > _currentSplitIndex) {
      _currentSplitIndex = splitKm;
    }

    // ── 定时/定距触发 ──
    bool shouldBroadcast = false;

    if (frequency.isDistance) {
      final interval = frequency.interval;
      final currentTrigger = (distance / interval).floor();
      final lastTrigger = (_lastTriggerDistance / interval).floor();
      if (currentTrigger > lastTrigger) {
        shouldBroadcast = true;
      }
    } else if (frequency.isTime) {
      final interval = frequency.interval;
      final currentTrigger = (duration / interval).floor();
      final lastTrigger = (_lastTriggerTime / interval).floor();
      if (currentTrigger > lastTrigger) {
        shouldBroadcast = true;
      }
    }

    // ── 目标达成播报（仅一次） ──
    if (state.runGoal != null && !_goalAnnounced) {
      final goal = state.runGoal!;
      bool achieved = false;
      switch (goal.type) {
        case RunGoalType.distance:
          achieved = distance >= goal.value * 1000;
        case RunGoalType.duration:
          achieved = duration >= goal.value * 60;
        case RunGoalType.calories:
          const weight = 65.0;
          final est = (weight * distance / 1000 * 1.036).round();
          achieved = est >= goal.value;
        default:
          break;
      }
      if (achieved) {
        _goalAnnounced = true;
        await _speak(_buildGoalAchievedText(state));
        return;
      }
    }

    if (shouldBroadcast) {
      final text = _buildBroadcastText(state);
      _log('🎙️ VOICE: shouldBroadcast! text="$text"');
      if (text.isNotEmpty) {
        _log('🎙️ VOICE: calling _speak...');
        await _speak(text);
        _log('🎙️ VOICE: _speak done');
      } else {
        _log('🎙️ VOICE: text is empty, skipped');
      }
    } else {
      _log('🎙️ VOICE: shouldBroadcast=false');
    }

    _lastTriggerDistance = distance;
    _lastTriggerTime = duration;
    _lastState = state;
  }

  /// 开始跑步时重置播报状态
  void reset() {
    _lastTriggerDistance = 0;
    _lastTriggerTime = 0;
    _goalAnnounced = false;
    _isSpeaking = false;
    _motivationIndex = 0;
    _prevElevation = null;
    _sprintAnnounced = false;
    _abnormalPaceAnnounced = false;
    _abnormalHrAnnounced = false;
    _currentSplitIndex = 0;
    _consecutiveWins = 0;
    _consecutiveLosses = 0;
    _lastSegmentPaceDiff = null;
    _cumulativeTimeGap = 0;
  }

  // ────────────────────────────────────────────────────
  //  异常检测（仅异常模式 / 所有模式通用）
  // ────────────────────────────────────────────────────

  Future<void> _checkAnomalies(RunSessionState state) async {
    final run = state.currentRun;
    if (run == null) return;

    final pace = run.avgPace;
    final hr = run.avgHeartRate;
    final items = state.broadcastItems;
    final style = state.voiceStyle;

    // 配速偏离报警（检测骤升骤降）
    if (items.contains('pace_deviation') && pace != null && _lastState != null) {
      final lastRun = _lastState!.currentRun;
      if (lastRun != null && lastRun.avgPace != null && lastRun.avgPace! > 0) {
        final change = ((pace - lastRun.avgPace!) / lastRun.avgPace!);
        if (change.abs() > 0.15 && !_abnormalPaceAnnounced) {
          // 配速变化超过15%
          _abnormalPaceAnnounced = true;
          String msg;
          if (change > 0) {
            switch (style) {
              case 'jianghu': msg = '道友慢下来了，稳住道心'; break;
              case 'coach':   msg = '配速下降了，调整呼吸'; break;
              case 'toxic':   msg = '慢这么多？今天没睡醒？'; break;
              default:        msg = '配速下降，注意调整'; break;
            }
          } else {
            switch (style) {
              case 'jianghu': msg = '道友突然加速，真气不可耗竭'; break;
              case 'coach':   msg = '配速突然加快，注意节奏'; break;
              case 'toxic':   msg = '哟突然快了？别撑不过两分钟'; break;
              default:        msg = '配速加快，保持节奏'; break;
            }
          }
          await _speak(msg);
          return;
        } else if (change.abs() < 0.05) {
          // 恢复正常后重置标记
          _abnormalPaceAnnounced = false;
        }
      }
    }

    // 心率异常报警
    if (items.contains('heart_rate') && hr != null && !_abnormalHrAnnounced) {
      if (hr > 175) {
        _abnormalHrAnnounced = true;
        String msg;
        switch (style) {
          case 'jianghu': msg = '道友心率过高，速速调息！'; break;
          case 'coach':   msg = '心率偏高，请降低速度'; break;
          case 'toxic':   msg = '心率$hr，你是跑还是拼命？'; break;
          default:        msg = '心率过高，注意安全'; break;
        }
        await _speak(msg);
        return;
      }
      if (hr < 175) {
        _abnormalHrAnnounced = false;
      }
    }
  }

  /// 冲刺检测（最后阶段全力加速提示）
  Future<void> _checkSprint(RunSessionState state) async {
    final run = state.currentRun;
    if (run == null || state.runGoal == null || _sprintAnnounced) return;

    final distance = run.totalDistance;
    final goal = state.runGoal!;

    if (goal.type == RunGoalType.distance) {
      final targetMeters = goal.value * 1000;
      final remaining = targetMeters - distance;
      // 剩余距离不到200米且已跑超过80%，触发冲刺提示
      if (remaining > 0 && remaining < 200 && distance > targetMeters * 0.8) {
        _sprintAnnounced = true;
        final style = state.voiceStyle;
        await _speak(_sprintTexts[style] ?? _sprintTexts['standard']!);
        return;
      }
    }

    if (goal.type == RunGoalType.duration) {
      final totalSec = goal.value * 60;
      final remaining = totalSec - run.totalTime;
      if (remaining > 0 && remaining < 30 && run.totalTime > totalSec * 0.8) {
        _sprintAnnounced = true;
        final style = state.voiceStyle;
        await _speak(_sprintTexts[style] ?? _sprintTexts['standard']!);
        return;
      }
    }
  }

  // ────────────────────────────────────────────────────
  //  TTS 执行
  // ────────────────────────────────────────────────────

  Future<void> _speak(String text) async {
    _log('🎙️ _speak: text="$text" _isInitialized=$_isInitialized _isSpeaking=$_isSpeaking');
    // 懒初始化：每次说话前尝试初始化
    if (!_isInitialized) {
      try {
        _log('🎙️ _speak: lazy init starting');
        await _tts.setLanguage('zh-CN');
        await _tts.setSpeechRate(0.5);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        _tts.setCompletionHandler(() { _isSpeaking = false; });
        _tts.setErrorHandler((_) { _isSpeaking = false; });
        _isInitialized = true;
        _log('🎙️ _speak: lazy init done');
      } catch (_) { _log('🎙️ _speak: lazy init failed'); }
    }
    try {
      if (_isSpeaking) {
        _log('🎙️ _speak: stopping previous speech');
        await _tts.stop();
      }
      _isSpeaking = true;
      _log('🎙️ _speak: calling tts.speak...');
      await _tts.speak(text);
      _log('🎙️ _speak: tts.speak returned');
    } catch (e) {
      _log('🎙️ _speak: exception: $e');
      _isSpeaking = false;
    }
  }

  /// 语音播报单个数字（倒计时用）
  Future<void> speakNumber(String number) async {
    await _speak(number);
  }

  /// 语音播报"开始运动"（倒计时结束后）
  Future<void> speakStartText(String style) async {
    final text = _startTextForStyle(style);
    await _speak(text);
  }

  /// 根据语音风格返回开始运动播报文本
  String _startTextForStyle(String style) {
    switch (style) {
      case 'jianghu':
        return '开始运动，道友迈步！';
      case 'coach':
        return '开始运动，注意呼吸，保持节奏！';
      case 'toxic':
        return '开始了，别偷懒！';
      default:
        return '开始运动！';
    }
  }

  // ────────────────────────────────────────────────────
  //  构建播报文本
  // ────────────────────────────────────────────────────

  String _buildBroadcastText(RunSessionState state) {
    final run = state.currentRun;
    if (run == null) return '';

    // 按模式路由
    if (state.runMode == RunMode.companion && state.opponentRun != null) {
      return _buildCompanionText(state);
    }
    if (state.runMode == RunMode.challenge && state.opponentRun != null) {
      return _buildChallengeText(state);
    }
    return _buildSoloText(state);
  }

  /// ── 独跑模式播报 ────────────────────────────────────────
  /// 跟历史平均比，鼓励为主
  String _buildSoloText(RunSessionState state) {
    final run = state.currentRun!;
    final distance = run.totalDistance;
    final duration = run.totalTime;
    final pace = run.avgPace;
    final hr = run.avgHeartRate;
    final cadence = run.avgCadence;
    final stride = run.avgStrideLength;
    final climb = run.elevationGain;
    final items = state.broadcastItems;
    final style = state.voiceStyle;
    final isFirstRun = state.isFirstRun;
    final hist = state.historicalAverages;

    final parts = <String>[];

    for (final item in items) {
      switch (item) {
        case 'distance':
          parts.add(_formatDistance(distance, style));
          break;
        case 'duration':
          parts.add(_formatDuration(duration, style));
          break;
        case 'pace':
          parts.add(_formatPace(pace, style,
              histAvgPace: hist?['avg_pace'] as int?,
              isFirstRun: isFirstRun));
          break;
        case 'heart_rate':
          if (hr != null && hr > 0) {
            parts.add(_formatHeartRate(hr, style,
                histAvgHr: hist?['avg_heart_rate'] as int?,
                isFirstRun: isFirstRun));
          }
          break;
        case 'cadence':
          if (cadence != null && cadence > 0) {
            parts.add(_formatCadence(cadence, style,
                histAvgCadence: hist?['avg_cadence'] as int?,
                isFirstRun: isFirstRun));
          }
          break;
        case 'stride_length':
          if (stride != null && stride > 0) {
            parts.add(_formatStride(stride, style,
                histAvgStride: hist?['avg_stride_length'] as double?,
                isFirstRun: isFirstRun));
          }
          break;
        case 'calories':
          final cal = run.calories;
          if (cal != null && cal > 0) {
            parts.add(_formatCalories(cal, style));
          }
          break;
        case 'goal_status':
          if (state.runGoal != null) {
            parts.add(_formatGoalStatus(distance, duration, state.runGoal!, style));
          }
          break;
        case 'climb':
          if (climb > 0 && _prevElevation != null) {
            final diff = climb - _prevElevation!;
            if (diff.abs() > 5) {
              parts.add(_formatClimb(climb, diff, style));
            }
          }
          _prevElevation = climb;
          break;
        case 'motivation':
          parts.add(_formatMotivation(style));
          break;
        default:
          break;
      }
    }

    final text = parts.join('，');
    if (text.isEmpty) return '';

    switch (style) {
      case 'jianghu':
        return '道友！$text';
      case 'coach':
        return '加油！$text';
      default:
        return text;
    }
  }

  /// ── 伴跑模式播报 ────────────────────────────────────────
  /// 三段式：[当前数据] → [对手此段对比] → [幻影模式特定内容]
  String _buildCompanionText(RunSessionState state) {
    final run = state.currentRun!;
    final opp = state.opponentRun!;
    final style = state.voiceStyle;
    final ghost = state.ghostMode ?? GhostMode.realReplay;
    final distance = run.totalDistance;
    final duration = run.totalTime;
    final pace = run.avgPace;
    final items = state.broadcastItems;

    // ── ① 当前数据（按播报参数拼接） ──
    final dataParts = <String>[];
    for (final item in items) {
      if (item == 'lag' || item == 'opponent_pace' || item == 'motivation' ||
          item == 'sprint' || item == 'pace_deviation') continue;
      switch (item) {
        case 'distance':
          dataParts.add(_formatDistance(distance, style));
          break;
        case 'duration':
          dataParts.add(_formatDuration(duration, style));
          break;
        case 'pace':
          if (pace != null && pace > 0) {
            dataParts.add(_formatPaceStr(pace) + '配速');
          }
          break;
        case 'heart_rate':
          if (run.avgHeartRate != null && run.avgHeartRate! > 0) {
            dataParts.add('心率${run.avgHeartRate}');
          }
          break;
        case 'cadence':
          if (run.avgCadence != null && run.avgCadence! > 0) {
            dataParts.add('步频${run.avgCadence}');
          }
          break;
        case 'stride_length':
          if (run.avgStrideLength != null && run.avgStrideLength! > 0) {
            final cm = (run.avgStrideLength! * 100).round();
            dataParts.add('步幅$cm厘米');
          }
          break;
        case 'calories':
          if (run.calories != null && run.calories! > 0) {
            dataParts.add('消耗${run.calories}千卡');
          }
          break;
        case 'climb':
          if (run.elevationGain > 0 && _prevElevation != null) {
            final diff = run.elevationGain - _prevElevation!;
            if (diff.abs() > 5) {
              dataParts.add(_formatClimb(run.elevationGain, diff, style));
            }
          }
          _prevElevation = run.elevationGain;
          break;
      }
    }

    // ── ② 对手此段对比（核心：当前分段 vs 对手同分段） ──
    final oppSeg = _buildOpponentSegmentText(state);

    // ── ③ 幻影模式内容 ──
    final ghostText = _buildGhostModeText(state);

    // ── 组装 ──
    final allParts = <String>[];
    if (dataParts.isNotEmpty) {
      allParts.add(dataParts.join('，'));
    }
    if (oppSeg.isNotEmpty) {
      allParts.add(oppSeg);
    }
    if (ghostText.isNotEmpty) {
      allParts.add(ghostText);
    }

    final text = allParts.join('，');
    if (text.isEmpty) return '';

    switch (style) {
      case 'jianghu':
        return '道友！$text';
      case 'coach':
        return '加油！$text';
      default:
        return text;
    }
  }

  /// 伴跑：对手分段对比（配速 + 心率 + 步频学习建议 + 趋势）
  String _buildOpponentSegmentText(RunSessionState state) {
    final opp = state.opponentRun;
    if (opp == null) return '';

    final run = state.currentRun!;
    final pace = run.avgPace;
    final style = state.voiceStyle;

    // 找对手同分段数据
    final oppSplit = opp.splits.where((s) => s.splitIndex == _currentSplitIndex).firstOrNull;

    final parts = <String>[];

    // ═══ 配速对比 ═══
    if (oppSplit != null && oppSplit.pace != null && oppSplit.pace! > 0) {
      final oppPaceStr = _formatPaceStr(oppSplit.pace!);

      if (pace != null && pace > 0) {
        final diff = oppSplit.pace! - pace; // 正=我快，负=我慢
        if (diff.abs() < 5) {
          parts.add('此段对手$oppPaceStr，几乎同步');
        } else if (diff > 0) {
          parts.add('此段你快了${diff}秒');
        } else {
          parts.add('此段慢了${-diff}秒');
        }

        // 更新连续趋势
        if (diff > 5) {
          _consecutiveWins++;
          _consecutiveLosses = 0;
        } else if (diff < -5) {
          _consecutiveLosses++;
          _consecutiveWins = 0;
        } else {
          _consecutiveWins = 0;
          _consecutiveLosses = 0;
        }
        _lastSegmentPaceDiff = diff;
      } else {
        parts.add('对手配速$oppPaceStr');
      }
    } else if (opp.avgPace != null && opp.avgPace! > 0) {
      // 无分段→全程平均
      final oppPaceStr = _formatPaceStr(opp.avgPace!);
      if (pace != null && pace > 0) {
        final diff = opp.avgPace! - pace;
        final diffStr = (diff.abs() / 60).toStringAsFixed(1);
        if (diff.abs() < 5) {
          parts.add('与对手配速持平');
        } else if (diff > 0) {
          parts.add('比对手每公里快$diffStr分钟');
        } else {
          parts.add('比对手每公里慢$diffStr分钟');
        }
      } else {
        parts.add('对手平均配速$oppPaceStr');
      }
    }

    // ═══ 心率对比（学习点） ═══
    if (oppSplit != null && oppSplit.avgHeartRate != null && oppSplit.avgHeartRate! > 0 &&
        run.avgHeartRate != null && run.avgHeartRate! > 0) {
      final hrDiff = run.avgHeartRate! - oppSplit.avgHeartRate!;
      if (hrDiff.abs() > 5) {
        if (hrDiff > 0) {
          parts.add('你心率${run.avgHeartRate}高于对手${oppSplit.avgHeartRate}，注意调匀呼吸');
        } else {
          parts.add('你心率${run.avgHeartRate}低于对手${oppSplit.avgHeartRate}，心肺状态不错');
        }
      } else {
        parts.add('心率${run.avgHeartRate}，与对手相仿');
      }
    }

    // ═══ 步频对比（学习点） ═══
    if (oppSplit != null && oppSplit.avgCadence != null && oppSplit.avgCadence! > 0 &&
        run.avgCadence != null && run.avgCadence! > 0) {
      final cadDiff = run.avgCadence! - oppSplit.avgCadence!;
      if (cadDiff.abs() > 10) {
        if (cadDiff > 0) {
          parts.add('你步频${run.avgCadence}高于对手${oppSplit.avgCadence}');
        } else {
          parts.add('你步频${run.avgCadence}低于对手${oppSplit.avgCadence}');
        }
      }
    }

    // ═══ 连续趋势总结 ═══
    if (_consecutiveWins >= 3) {
      parts.add('连续${_consecutiveWins}公里领先，节奏保持得不错');
    } else if (_consecutiveLosses >= 3) {
      parts.add('连续${_consecutiveLosses}公里落后，可以找找原因调整一下');
    }

    if (parts.isEmpty) return '';

    final text = parts.join('，');
    switch (style) {
      case 'jianghu':
        return '道友，$text';
      case 'coach':
        return '加油，$text';
      default:
        return text;
    }
  }

  /// 按幻影模式生成特定内容
  String _buildGhostModeText(RunSessionState state) {
    final run = state.currentRun!;
    final opp = state.opponentRun!;
    final ghost = state.ghostMode ?? GhostMode.realReplay;
    final style = state.voiceStyle;
    final myDist = run.totalDistance;
    final oppDist = opp.totalDistance;

    switch (ghost) {
      case GhostMode.realReplay:
        // 真实回放：累计差距变化 + 鼓励
        final diff = oppDist - myDist;
        if (diff.abs() < 20) {
          return _stylePhrase(style, '并驾齐驱', '与对手并驾齐驱', '和对手跑在一起了');
        } else if (diff > 0) {
          final m = diff.round();
          return _stylePhrase(style,
            '差距${m}米，道法自然',
            '还差${m}米追上对手，保持节奏',
            '差${m}米，追上他！');
        } else {
          final m = (-diff).round();
          return _stylePhrase(style,
            '领先${m}米，道友修为更高',
            '领先${m}米，表现不错',
            '领先${m}米，对手在后面呢');
        }

      case GhostMode.constantPace:
        // 恒定配速：跟目标配速比
        final oppAvgPace = opp.avgPace;
        final myPace = run.avgPace;
        if (oppAvgPace == null || oppAvgPace <= 0) break;
        if (myPace == null || myPace <= 0) break;
        final diff = oppAvgPace - myPace;
        if (diff.abs() < 5) {
          return _stylePhrase(style, '配速精准，与目标一致', '配速完美保持住了', '节奏稳得像钟表');
        } else if (diff > 0) {
          return _stylePhrase(style,
            '比目标快${diff}秒，节奏偏快了',
            '比目标配速快了${diff}秒，可以稳一稳',
            '冲太猛了，比目标快${diff}秒');
        } else {
          return _stylePhrase(style,
            '比目标慢了${-diff}秒，可以提一提',
            '比目标配速慢了${-diff}秒，稍微加速',
            '慢${-diff}秒了，追回来');
        }

      case GhostMode.rabbit:
        // 领跑兔：追逐距离
        final diff = oppDist - myDist;
        if (diff.abs() < 20) {
          return _stylePhrase(style,
            '道友追上领跑兔了！超越！',
            '追上兔子了！现在是你在领跑！',
            '哟，兔子都被你追上了！');
        } else if (diff > 0) {
          final m = diff.round();
          return _stylePhrase(style,
            '兔子在前${m}米处',
            '兔子还在前方${m}米',
            '兔子在前面${m}米，冲过去！');
        } else {
          final m = (-diff).round();
          return _stylePhrase(style,
            '道友已将兔子甩开${m}米',
            '你已经领先兔子${m}米',
            '兔子在后面${m}米，厉害了');
        }

      case GhostMode.tortoiseHare:
        // 龟兔赛跑：强调当前分段对手快还是慢
        final oppSplit = opp.splits.where((s) => s.splitIndex == _currentSplitIndex).firstOrNull;
        final mySplit = run.splits.where((s) => s.splitIndex == _currentSplitIndex).firstOrNull;
        if (oppSplit != null && mySplit != null &&
            oppSplit.pace != null && mySplit.pace != null &&
            oppSplit.pace! > 0 && mySplit.pace! > 0) {
          final diff = oppSplit.pace! - mySplit.pace!;
          if (diff > 5) {
            return _stylePhrase(style,
              '对手此段慢了，道友拉开差距',
              '对手这个分段慢下来了，你在拉开距离',
              '对手这轮磨蹭了，把握机会拉开');
          } else if (diff < -5) {
            return _stylePhrase(style,
              '对手此段快了，道友稳住节奏',
              '对手这个分段加速了，保持自己的节奏',
              '对手突然加速了，别被他带偏');
          }
        }
        // 无分段数据用累计距离
        final d = oppDist - myDist;
        if (d.abs() < 30) {
          return _stylePhrase(style, '势均力敌', '与对手势均力敌', '难分难解啊');
        } else if (d > 0) {
          return _stylePhrase(style, '稍落后，待机反超', '暂时落后，找机会反超', '落后一点，问题不大');
        } else {
          return _stylePhrase(style, '占优中，不可松懈', '目前领先，保持状态', '领先中，继续施压');
        }

      case GhostMode.goalChallenge:
        // 目标挑战：跟目标配速比
        if (state.runGoal != null) {
          return _formatGoalStatus(run.totalDistance, run.totalTime, state.runGoal!, style);
        }
        // 无目标时退化为配速对比
        return _buildOpponentSegmentText(state);
    }
    return '';
  }

  /// ── 挑战跑模式播报 ──────────────────────────────────────
  /// 只播选中的比拼指标，不播其他
  String _buildChallengeText(RunSessionState state) {
    final run = state.currentRun!;
    final opp = state.opponentRun!;
    final metric = state.challengeMetric;
    final style = state.voiceStyle;
    final items = state.broadcastItems;

    if (metric == null) return _buildSoloText(state);

    // 当前数据（只播距离/用时/目标等基本信息，不播其他指标）
    final dataParts = <String>[];
    for (final item in items) {
      switch (item) {
        case 'distance':
          dataParts.add(_formatDistance(run.totalDistance, style));
          break;
        case 'duration':
          dataParts.add(_formatDuration(run.totalTime, style));
          break;
        case 'goal_status':
          if (state.runGoal != null) {
            dataParts.add(_formatGoalStatus(
                run.totalDistance, run.totalTime, state.runGoal!, style));
          }
          break;
        case 'climb':
          if (run.elevationGain > 0 && _prevElevation != null) {
            final diff = run.elevationGain - _prevElevation!;
            if (diff.abs() > 5) {
              dataParts.add(_formatClimb(run.elevationGain, diff, style));
            }
          }
          _prevElevation = run.elevationGain;
          break;
        default:
          break;
      }
    }

    // 核心：只播选中的指标对比
    final metricText = _buildChallengeMetricCompare(state);

    // 累计时间差（协助跑者了解战况）
    final gap = _calcCumulativeGap(run, opp);

    final allParts = <String>[];
    if (dataParts.isNotEmpty) allParts.add(dataParts.join('，'));
    if (metricText.isNotEmpty) allParts.add(metricText);

    // 累计差距
    if (gap.abs() > 3) {
      if (gap > 0) {
        allParts.add('累计领先${gap.round()}秒');
      } else {
        allParts.add('累计落后${(-gap).round()}秒');
      }
    } else if (gap.abs() <= 3 && gap != 0) {
      allParts.add('几乎打平');
    }

    // 本段追赶/被拉开趋势
    if (_cumulativeTimeGap != 0) {
      final delta = gap - _cumulativeTimeGap;
      if (delta.abs() > 2) {
        if (delta > 0) {
          allParts.add('这一公里追回${delta.round()}秒');
        } else {
          allParts.add('这一公里被拉开${(-delta).round()}秒');
        }
      }
    }
    _cumulativeTimeGap = gap;

    final text = allParts.join('，');
    if (text.isEmpty) return '';

    switch (style) {
      case 'jianghu':
        return '道友！$text';
      case 'coach':
        return '加油！$text';
      default:
        return text;
    }
  }

  /// 计算累计时间差（正=领先，负=落后）
  double _calcCumulativeGap(Run run, Run opp) {
    double gap = 0;
    for (int i = 0; i <= _currentSplitIndex; i++) {
      final my = run.splits.where((s) => s.splitIndex == i).firstOrNull;
      final op = opp.splits.where((s) => s.splitIndex == i).firstOrNull;
      if (my != null && op != null && op.time > 0) {
        gap += (op.time - my.time).toDouble();
      }
    }
    return gap;
  }

  /// 挑战跑 — 选中指标对比
  String _buildChallengeMetricCompare(RunSessionState state) {
    final run = state.currentRun!;
    final opp = state.opponentRun!;
    final metric = state.challengeMetric;
    final style = state.voiceStyle;

    if (metric == null) return '';

    // 找双方当前分段数据，优先用分段级做同段对比
    final oppSplit = opp.splits.where((s) => s.splitIndex == _currentSplitIndex).firstOrNull;
    final mySplit = run.splits.where((s) => s.splitIndex == _currentSplitIndex).firstOrNull;

    switch (metric) {
      case ChallengeMetric.pace:
        // 用分段数据 vs 对手同段数据
        final myVal = mySplit?.pace ?? run.avgPace;
        final oppVal = oppSplit?.pace ?? opp.avgPace;
        if (myVal == null || myVal <= 0 || oppVal == null || oppVal <= 0) break;
        final diff = oppVal - myVal; // 正=我快，负=我慢
        final myStr = _formatPaceStr(myVal);
        final oppStr = _formatPaceStr(oppVal);
        if (diff.abs() < 5) {
          return '配速$myStr，对手$oppStr，不分伯仲';
        } else if (diff > 0) {
          return _stylePhrase(style,
            '配速$myStr，对手$oppStr，此段快${diff}秒',
            '配速$myStr，对手$oppStr，此段领先${diff}秒',
            '配速$myStr，对手$oppStr，赢了${diff}秒');
        } else {
          return _stylePhrase(style,
            '配速$myStr，对手$oppStr，此段慢${-diff}秒',
            '配速$myStr，对手$oppStr，此段落后${-diff}秒',
            '配速$myStr，对手$oppStr，输了${-diff}秒，追回来');
        }

      case ChallengeMetric.heartRate:
        final myVal = mySplit?.avgHeartRate ?? run.avgHeartRate;
        final oppVal = oppSplit?.avgHeartRate ?? opp.avgHeartRate;
        if (myVal == null || myVal <= 0 || oppVal == null || oppVal <= 0) break;
        final diff = myVal - oppVal; // 正=我心跳高（通常差），负=我心跳低（好）
        if (diff.abs() < 5) {
          return '心率$myVal，对手$oppVal，相近';
        } else if (diff > 0) {
          return _stylePhrase(style,
            '心率$myVal，对手$oppVal，你偏高${diff}，注意调息',
            '心率$myVal，对手$oppVal，偏高${diff}，放慢呼吸',
            '心率$myVal，对手$oppVal，你心跳比人快${diff}，悠着点');
        } else {
          return _stylePhrase(style,
            '心率$myVal，对手$oppVal，你低${-diff}，心肺状态更好',
            '心率$myVal，对手$oppVal，低${-diff}，有氧能力更优',
            '心率$myVal，对手$oppVal，比你高${-diff}，你稳赢了');
        }

      case ChallengeMetric.cadence:
        final myVal = mySplit?.avgCadence ?? run.avgCadence;
        final oppVal = oppSplit?.avgCadence ?? opp.avgCadence;
        if (myVal == null || myVal <= 0 || oppVal == null || oppVal <= 0) break;
        final diff = myVal - oppVal;
        if (diff.abs() < 5) {
          return '步频$myVal，对手$oppVal，步频相当';
        } else if (diff > 0) {
          return _stylePhrase(style,
            '步频$myVal，对手$oppVal，步频更高',
            '步频$myVal，对手$oppVal，领先${diff}步',
            '步频$myVal，对手$oppVal，你更快${diff}步');
        } else {
          return _stylePhrase(style,
            '步频$myVal，对手$oppVal，步频低${-diff}',
            '步频$myVal，对手$oppVal，低${-diff}步，可加快些',
            '步频$myVal，对手$oppVal，慢${-diff}步，跟上');
        }

      case ChallengeMetric.strideLength:
        final myVal = mySplit?.avgStrideLength ?? run.avgStrideLength;
        final oppVal = oppSplit?.avgStrideLength ?? opp.avgStrideLength;
        if (myVal == null || myVal <= 0 || oppVal == null || oppVal <= 0) break;
        final myCm = (myVal * 100).round();
        final oppCm = (oppVal * 100).round();
        final diff = myCm - oppCm;
        if (diff.abs() < 5) {
          return '步幅${myCm}厘米，对手${oppCm}厘米，步幅相近';
        } else if (diff > 0) {
          return _stylePhrase(style,
            '步幅${myCm}厘米，对手${oppCm}厘米，跨幅更大',
            '步幅${myCm}厘米，对手${oppCm}厘米，领先${diff}厘米',
            '步幅${myCm}厘米，对手${oppCm}厘米，赢了${diff}厘米');
        } else {
          return _stylePhrase(style,
            '步幅${myCm}厘米，对手${oppCm}厘米，跨幅小${-diff}厘米',
            '步幅${myCm}厘米，对手${oppCm}厘米，差${-diff}厘米',
            '步幅${myCm}厘米，对手${oppCm}厘米，输了${-diff}厘米');
        }
    }
    return '';
  }

  /// 按风格返回短语（江湖/教练/毒舌）
  String _stylePhrase(String style, String jianghu, String coach, String toxic) {
    switch (style) {
      case 'jianghu': return jianghu;
      case 'coach':   return coach;
      case 'toxic':   return toxic;
      default:        return jianghu;
    }
  }

  // ────────────────────────────────────────────────────
  //  目标达成播报
  // ────────────────────────────────────────────────────

  String _buildGoalAchievedText(RunSessionState state) {
    final goal = state.runGoal;
    if (goal == null) return '';

    switch (state.voiceStyle) {
      case 'jianghu':
        return '恭喜道友达成${goal.label}！修为大进，可喜可贺！';
      case 'coach':
        return '太棒了！你已完成${goal.label}目标！休息一下，做几个拉伸。';
      case 'toxic':
        return '呵，${goal.label}跑完了？还行吧，明天继续别偷懒。';
      default:
        return '恭喜你完成了${goal.label}的目标！';
    }
  }

  // ────────────────────────────────────────────────────
  //  格式化函数（分风格）
  // ────────────────────────────────────────────────────

  String _formatDistance(double meters, String style) {
    final km = meters / 1000;
    switch (style) {
      case 'jianghu':
        final li = (meters / 500).round();
        return '已行$li里';
      case 'toxic':
        return '才${km.toStringAsFixed(1)}公里';
      default:
        return '已跑${km.toStringAsFixed(1)}公里';
    }
  }

  String _formatDuration(int seconds, String style) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String timeStr;
    if (h > 0) {
      timeStr = '${h}小时${m}分钟';
    } else if (m > 0) {
      timeStr = '${m}分${s}秒';
    } else {
      timeStr = '${s}秒';
    }

    switch (style) {
      case 'toxic':
        return '耗时$timeStr';
      default:
        return '用时$timeStr';
    }
  }

  String _formatPace(int? paceSeconds, String style, {int? histAvgPace, bool isFirstRun = false}) {
    if (paceSeconds == null || paceSeconds <= 0) return '';
    final m = paceSeconds ~/ 60;
    final s = paceSeconds % 60;
    final paceStr = "${m}'${s.toString().padLeft(2, '0')}\"";

    // 首次跑：全程鼓励，不提快慢
    if (isFirstRun) {
      switch (style) {
        case 'jianghu':
          return '配速$paceStr，道友好根基！';
        case 'coach':
          return '配速$paceStr，第一次跑这个配速很稳';
        default:
          return '配速$paceStr，第一次跑就很棒了';
      }
    }

    // 有历史平均值：跟自己的平均比，采用鼓励性语言
    if (histAvgPace != null && histAvgPace > 0) {
      final diff = histAvgPace - paceSeconds; // 正数=比平时快，负数=比平时慢
      if (diff > 20) {
        // 比平时快了不少
        switch (style) {
          case 'jianghu':
            return '配速$paceStr，较往日精进不少';
          case 'toxic':
            return '配速$paceStr，今天状态在线';
          case 'coach':
            return '配速$paceStr，状态不错保持住';
          default:
            return '配速$paceStr，比平时快了一些';
        }
      } else if (diff < -20) {
        // 比平时慢了一些，但健康跑不需要追求速度
        switch (style) {
          case 'jianghu':
            return '配速$paceStr，道法自然，不必强求';
          case 'toxic':
            return '配速$paceStr，今天走养生路线';
          case 'coach':
            return '配速$paceStr，保持节奏就好';
          default:
            return '配速$paceStr，健康跑重在坚持';
        }
      }
      // 差异不大时：肯定节奏
      if (paceSeconds > 420) {
        // 非常慢的配速（>7min/km）更注重鼓励
        return '配速$paceStr，稳扎稳打';
      }
    }

    // 默认轻柔播报
    switch (style) {
      case 'jianghu':
        return '配速$paceStr';
      default:
        return '当前配速$paceStr';
    }
  }

  String _formatHeartRate(int hr, String style, {int? histAvgHr, bool isFirstRun = false}) {
    // 首次跑：安全提醒即可
    if (isFirstRun) {
      if (hr > 160) return '心率$hr，初次跑注意别太猛';
      return '心率$hr，正常范围';
    }

    // 安全警戒：不管什么模式，高心率都要提醒
    if (hr > 175) return '心率$hr，偏高注意安全';

    // 有历史平均值：跟自己比，不评判
    if (histAvgHr != null && histAvgHr > 0) {
      final diff = hr - histAvgHr;
      if (diff > 20) {
        switch (style) {
          case 'toxic':
            return '心率$hr，今天心跳有点快';
          case 'coach':
            return '心率$hr，比平时高了一些，注意呼吸';
          default:
            return '心率$hr，比平时偏高';
        }
      } else if (diff < -20) {
        switch (style) {
          case 'toxic':
            return '心率$hr，今天很轻松啊';
          case 'coach':
            return '心率$hr，比平时低，状态轻松';
          default:
            return '心率$hr，比平时偏低，跑得很轻松';
        }
      }
    }

    return '心率$hr';
  }

  String _formatCadence(int cadence, String style, {int? histAvgCadence, bool isFirstRun = false}) {
    final label = '步频$cadence';

    // 首次跑：不评价
    if (isFirstRun) return label;

    // 有历史平均值：跟自己比，健康跑不强调速度
    if (histAvgCadence != null && histAvgCadence > 0) {
      final diff = cadence - histAvgCadence;
      if (diff > 20) {
        return '$label，步频比平时快了一些';
      } else if (diff < -20) {
        return '$label，步频比平时慢了一些';
      }
      return label;
    }

    // 无历史数据时仅极低步频才提示
    if (cadence < 130) return '$label，步频偏低';
    return label;
  }

  String _formatCalories(int calories, String style) {
    switch (style) {
      case 'jianghu':
        return '消耗${calories}灵气的热量';
      case 'toxic':
        return '消耗${calories}卡路里，继续坚持';
      case 'coach':
        return '消耗$calories卡路里，不错哦';
      default:
        return '消耗${calories}千卡';
    }
  }

  String _formatStride(double stride, String style, {double? histAvgStride, bool isFirstRun = false}) {
    final cm = (stride * 100).round();

    // 首次跑：不评价
    if (isFirstRun) {
      return style == 'jianghu' ? '步幅${cm}寸' : '步幅$cm厘米';
    }

    // 有历史平均值：跟自己比
    if (histAvgStride != null && histAvgStride > 0) {
      final histCm = (histAvgStride * 100).round();
      final diff = cm - histCm;
      if (diff > 15) {
        return '步幅$cm厘米，比平时大了${diff}厘米';
      } else if (diff < -15) {
        return '步幅$cm厘米，比平时小了${-diff}厘米，可以试试加大';
      }
    }

    if (style == 'jianghu') return '步幅${cm}寸';
    return '步幅$cm厘米';
  }

  String _formatLag(double myDist, double opponentDist, String style) {
    if (opponentDist <= 0) return '';
    final diff = opponentDist - myDist;
    if (diff.abs() < 10) {
      switch (style) {
        case 'jianghu': return '与对手并驾齐驱';
        case 'toxic':   return '和对手差不多嘛';
        default:        return '并驾齐驱';
      }
    }
    final meters = diff.abs().round();
    if (diff > 0) {
      switch (style) {
        case 'jianghu': return '落后$meters丈';
        case 'toxic':   return '落后${meters}米了，加油啊';
        default:        return '落后${meters}米';
      }
    } else {
      switch (style) {
        case 'jianghu': return '领先${meters}丈';
        case 'toxic':   return '领先${meters}米，还行还行';
        default:        return '领先${meters}米';
      }
    }
  }

  String _formatOpponentPace(int? myPace, int? oppPace, String style) {
    if (oppPace == null || oppPace <= 0) return '';
    final oppStr = _formatPaceStr(oppPace);

    if (myPace == null || myPace <= 0) {
      return '对手配速$oppStr';
    }

    final diff = oppPace - myPace;
    final diffStr = (diff.abs() / 60).toStringAsFixed(1);

    if (diff.abs() < 5) {
      switch (style) {
        case 'jianghu': return '与对手配速持平';
        case 'toxic':   return '配速和对手一样，没拉开差距';
        default:        return '配速持平';
      }
    } else if (diff > 0) {
      // 对手比我慢 → 我领先
      switch (style) {
        case 'jianghu': return '比对手每公里快$diffStr分';
        case 'coach':   return '比对手快$diffStr分配速，保持！';
        case 'toxic':   return '对手配速$oppStr，你比他快$diffStr分，还行';
        default:        return '比对手快$diffStr分配速';
      }
    } else {
      // 对手比我快 → 我落后
      switch (style) {
        case 'jianghu': return '比对手每公里慢${diffStr}分，道友需加把劲';
        case 'coach':   return '比对手慢$diffStr分配速，可以稍微加速';
        case 'toxic':   return '对手配速$oppStr，你慢${diffStr}分，就这？';
        default:        return '比对手慢$diffStr分配速';
      }
    }
  }

  String _formatGoalStatus(double distance, int duration, RunGoal goal, String style) {
    double progress;
    String targetStr;

    switch (goal.type) {
      case RunGoalType.distance:
        progress = (distance / (goal.value * 1000)).clamp(0.0, 1.0);
        targetStr = goal.label;
      case RunGoalType.duration:
        progress = (duration / (goal.value * 60)).clamp(0.0, 1.0);
        targetStr = goal.label;
      case RunGoalType.calories:
        const weight = 65.0;
        final est = (weight * distance / 1000 * 1.036).round();
        progress = (est / goal.value).clamp(0.0, 1.0);
        targetStr = goal.label;
      default:
        return '';
    }

    final pct = (progress * 100).round();

    if (style == 'toxic') {
      if (pct < 30) return '才完成$pct%，还差得远呢';
      if (pct < 70) return '完成$pct%，继续别停';
      return '完成$pct%，目标$targetStr';
    }

    if (style == 'jianghu') {
      if (pct < 30) return '目标$targetStr，已修$pct%';
      if (pct < 70) return '道途过半，已修$pct%';
      return '目标$targetStr，已修$pct%，近在咫尺';
    }

    return '目标$targetStr，已完成$pct%';
  }

  String _formatClimb(double totalClimb, double diff, String style) {
    switch (style) {
      case 'jianghu':
        return '爬升$totalClimb丈，一路登高';
      case 'coach':
        return '累计爬升${totalClimb.round()}米，注意调整跑姿';
      case 'toxic':
        if (diff > 20) return '爬升$totalClimb米，坡不少，悠着点';
        return '爬升$totalClimb米，还行不算太陡';
      default:
        return '累计爬升${totalClimb.round()}米';
    }
  }

  String _formatMotivation(String style) {
    final pool = _motivations[style] ?? _motivations['standard']!;
    final text = pool[_motivationIndex % pool.length];
    _motivationIndex++;
    return text;
  }

  // ─── 工具函数 ───────────────────────────────────────

  String _formatPaceStr(int paceSeconds) {
    final m = paceSeconds ~/ 60;
    final s = paceSeconds % 60;
    return "${m}'${s.toString().padLeft(2, '0')}\"";
  }
}

