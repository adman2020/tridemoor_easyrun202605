import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';

/// 计步器服务 —— 使用 Android TYPE_STEP_COUNTER 传感器
///
/// 提供跑步期间的步数统计，用于计算步频和步幅。
/// Android 上基于硬件步数传感器（无需 GPS），iOS 上基于 CoreMotion。
class StepCounterService extends ChangeNotifier {
  static final StepCounterService instance = StepCounterService._();
  StepCounterService._();

  StreamSubscription<StepCount>? _subscription;

  /// 基准步数（开始监听时记录）
  int _baselineSteps = 0;

  /// 跑步期间累计步数
  int _steps = 0;

  /// 传感器是否可用
  bool _available = false;

  /// 是否正在监听
  bool _isRunning = false;

  /// 跑步期间累计步数
  int get steps => _steps;

  /// 传感器是否可用
  bool get available => _available;

  /// 步频（步/分），基于当前步数和已用秒数
  int? cadence(int elapsedSeconds) {
    if (_steps <= 0 || elapsedSeconds <= 0) return null;
    final minutes = elapsedSeconds / 60.0;
    return minutes > 0 ? (_steps / minutes).round() : null;
  }

  /// 步幅（米/步），基于当前步数和距离
  double? strideLength(double distanceMeters) {
    if (_steps <= 0 || distanceMeters <= 0) return null;
    return (distanceMeters / _steps).clamp(0.3, 3.0);
  }

  /// 开始监听步数
  Future<void> start() async {
    _baselineSteps = 0;
    _steps = 0;
    _isRunning = true;

    try {
      _subscription = Pedometer.stepCountStream.listen(
        (StepCount stepCount) {
          final currentSteps = stepCount.steps;
          if (!_isRunning) return;

          if (_baselineSteps == 0) {
            // 第一个事件：记录基准
            _baselineSteps = currentSteps;
            _steps = 0;
          } else {
            _steps = currentSteps - _baselineSteps;
          }

          if (!_available) {
            _available = true;
            debugPrint('👟 计步器传感器可用');
          }
          notifyListeners();
        },
        onError: (error) {
          debugPrint('⚠️ 计步器错误: $error');
          _available = false;
        },
      );
      debugPrint('👟 计步器开始监听...');
    } catch (e) {
      debugPrint('⚠️ 计步器启动失败: $e');
      _available = false;
    }
  }

  /// 停止监听并重置
  void stop() {
    _isRunning = false;
    _steps = 0;
    _baselineSteps = 0;
    _subscription?.cancel();
    _subscription = null;
    notifyListeners();
  }

  /// 暂停但不重置（保留当前步数）
  void pause() {
    _isRunning = false;
  }

  /// 恢复监听
  void resume() {
    _isRunning = true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
