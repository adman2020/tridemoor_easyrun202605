/// 跑步目标模型
enum RunGoalType {
  none,     // 无目标
  distance, // 距离目标
  duration, // 时间目标
  calories, // 消耗目标
}

class RunGoal {
  final RunGoalType type;
  final double value; // km / 分钟 / kcal

  const RunGoal({required this.type, required this.value});

  /// 目标描述文案
  String get label {
    switch (type) {
      case RunGoalType.none:
        return '';
      case RunGoalType.distance:
        return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}公里';
      case RunGoalType.duration:
        final h = value ~/ 60;
        final m = (value % 60).round();
        if (h > 0) return '${h}小时${m}分钟';
        return '${m}分钟';
      case RunGoalType.calories:
        return '${value.round()}千卡';
    }
  }

  /// 预设快捷选项
  static const distancePresets = [5.0, 10.0, 21.0975, 42.195];
  static const durationPresets = [15.0, 30.0, 45.0, 60.0];
  static const caloriePresets = [100, 200, 300, 500];
}
