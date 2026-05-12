/// 格式化工具类
class Formatters {
  Formatters._();

  /// 从后端返回的 ISO 8601 时间字符串中提取日期部分（不依赖时区）
  ///
  /// 后端始终返回带 +08:00 时区偏移的 ISO 字符串，如：
  ///   "2026-05-01T06:10:54.344+08:00"
  /// ISO 字符串的前10个字符永远是 YYYY-MM-DD 格式的日期，
  /// 直接取日期部分可以避免 DateTime.parse 的手机时区依赖问题。
  ///
  /// [dateStr] 是原始 JSON 中的 start_time 或 end_time 字符串
  /// 返回 dateOnly 的 DateTime（年月日在设备本地时区的午夜）
  static DateTime dateFromIso(String? dateStr) {
    if (dateStr == null || dateStr.length < 10) return DateTime.now();
    // 只取前10个字符，这是时区无关的日期部分
    final isoDate = dateStr.substring(0, 10); // "2026-05-01"
    // DateTime.parse("2026-05-01") 创建本地时区午夜，年月日永远正确
    return DateTime.parse(isoDate);
  }

  /// 格式化配速 (秒/公里 → "m'ss\"")
  static String pace(int secondsPerKm) {
    if (secondsPerKm <= 0) return '--';
    final m = secondsPerKm ~/ 60;
    final s = secondsPerKm % 60;
    return "${m}'${s.toString().padLeft(2, '0')}\"";
  }

  /// 格式化时长 (秒 → "hh:mm:ss" 或 "mm:ss")
  static String duration(int totalSeconds) {
    if (totalSeconds < 0) return '--';
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 格式化距离 (米 → "x.xx km" 或 "x m")
  static String distance(double meters, {bool showUnit = true}) {
    if (meters < 0) return '--';
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(2);
      return showUnit ? '$km km' : km;
    }
    final m = meters.toStringAsFixed(0);
    return showUnit ? '$m m' : m;
  }

  /// 格式化心率
  static String heartRate(int? bpm) {
    return bpm != null && bpm > 0 ? '$bpm' : '--';
  }

  /// 格式化步频
  static String cadence(int? spm) {
    return spm != null && spm > 0 ? '$spm' : '--';
  }

  /// 格式化步幅
  static String strideLength(double? meters) {
    return meters != null && meters > 0 ? '${meters.toStringAsFixed(2)} m' : '--';
  }
}
