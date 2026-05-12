import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';

/// 分步调试日志 —— 写入文件，闪退后重新打开 app 可以读取
class DebugStepLogger {
  static File? _file;
  static bool _enabled = true;

  static Future<void> init() async {
    if (!_enabled) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/stride_moor_init_steps.log');
      // 清空旧日志（如果有）
      await _file!.writeAsString('=== INIT DEBUG LOG ${DateTime.now()} ===\n');
    } catch (e) {
      _enabled = false;
      debugPrint('⚠️ 无法创建调试日志文件: $e');
    }
  }

  static Future<void> step(int n, String msg) async {
    if (!_enabled || _file == null) return;
    try {
      await _file!.writeAsString(
        'STEP $n: $msg\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  static Future<String?> readLog() async {
    if (!_enabled || _file == null) return null;
    try {
      if (await _file!.exists()) {
        return await _file!.readAsString();
      }
    } catch (_) {}
    return null;
  }
}
