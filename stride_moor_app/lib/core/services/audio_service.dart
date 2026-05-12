import 'dart:async';

import 'package:logger/logger.dart';

/// 语音播报服务 (Stub - Web/预览版暂不支持 TTS/音频播放)
/// 
/// TODO: 接入 flutter_tts + just_audio 以支持真机语音播报
class AudioService {
  final Logger _logger = Logger();
  
  final List<String> _queue = [];
  bool _isSpeaking = false;
  String _voiceStyle = 'standard';

  String get voiceStyle => _voiceStyle;

  Future<void> init() async {
    _logger.i('AudioService init (stub)');
  }

  Future<void> setVoiceStyle(String style) async {
    _voiceStyle = style;
  }

  Future<void> enqueue(String text) async {
    _logger.i('[TTS Stub] $text');
    _queue.add(text);
    if (!_isSpeaking) {
      await _processQueue();
    }
  }

  Future<void> speakImmediately(String text) async {
    _queue.clear();
    _logger.i('[TTS Stub] $text');
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty || _isSpeaking) return;
    final text = _queue.removeAt(0);
    _isSpeaking = true;
    _logger.i('[TTS Stub] $text');
    await Future.delayed(const Duration(seconds: 2));
    _isSpeaking = false;
    await _processQueue();
  }

  // ignore: unused_element
  String _applyVoiceStyle(String text) {
    switch (_voiceStyle) {
      case 'jianghu':
      case 'coach':
      case 'toxic':
      default:
        return text;
    }
  }

  /// 构建跑步数据播报文本（纯 Dart，无需原生插件）
  String buildBroadcastText({
    required double distanceMeters,
    required int durationSeconds,
    required int? pace,
    required int? heartRate,
    required int? cadence,
    required int? lagMeters,
    required String? opponentName,
    required bool isCompanion,
  }) {
    final distKm = (distanceMeters / 1000).toStringAsFixed(1);
    final durationStr = _formatDuration(durationSeconds);
    final paceStr = pace != null ? _formatPace(pace) : '--';
    
    final buffer = StringBuffer();
    buffer.write('已跑$distKm公里，用时$durationStr，配速$paceStr');
    
    if (heartRate != null) {
      buffer.write('，心率$heartRate');
    }
    if (cadence != null) {
      buffer.write('，步频$cadence');
    }
    
    if (isCompanion && opponentName != null && lagMeters != null) {
      final status = lagMeters > 0 ? '落后$lagMeters米' : '领先${-lagMeters}米';
      buffer.write('，$status');
    }
    
    return buffer.toString();
  }

  Future<void> playBeep() async {}

  Future<void> playMotivation() async {}

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}分${s.toString().padLeft(2, '0')}秒';
  }

  String _formatPace(int paceSecondsPerKm) {
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> dispose() async {
    _queue.clear();
  }
}
