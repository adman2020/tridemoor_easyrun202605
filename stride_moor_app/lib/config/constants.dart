/// 驰陌 / StrideMoor 全局常量
class AppConstants {
  AppConstants._();

  // 开发模式（无后端时使用 mock 数据）
  static const bool devMode = false;
  // 开发模式：自动用测试账号 13800000001 / test123456 登录后端
  static const bool autoLoginTestUser = true;

  // 应用信息
  static const String appNameCN = '驰陌';
  static const String appNameEN = 'StrideMoor';
  static const String slogan = '驰于阡陌，自在奔跑';
  static const String sloganEN = 'Stride in Moor, Run at Ease';

  // API 基础配置
  static const String baseUrl = 'https://api.8keya.com/api/v1';  // Cloudflare Tunnel（生产）
  // 旧地址: https://6775f80d.r17.cpolar.top/api/v1 (cpolar 已废弃)
  // 更旧: https://1a5f2c38.r7.vip.cpolar.cn
  // 局域网测试改回: http://192.168.1.105:8080/api/v1
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // GPS 配置
  static const double gpsMinAccuracy = 20.0; // 米，精度阈值
  static const int gpsSamplingIntervalMs = 1000; // GPS采样间隔
  static const double gpsStaticSpeedThreshold = 0.5; // m/s，静态过滤

  // 路线匹配算法参数
  static const double routeMatchEndpointThreshold = 100.0; // 起终点距离阈值(米)
  static const double routeMatchDistanceTolerance = 0.10; // 总距离偏差 < 10%
  static const double routeMatchSimilarityThreshold = 0.85; // DTW相似度阈值

  // 跑步分段
  static const double splitDistanceKm = 1.0; // 每1km一个分段

  // 播报默认配置
  static const int defaultBroadcastIntervalMeters = 1000;
  static const List<String> defaultBroadcastItems = [
    'pace',
    'distance',
    'duration',
    'heart_rate',
  ];

  // 存储 Keys
  static const String hiveSettingsBox = 'settings';
  static const String hiveRoutesBox = 'routes';
  static const String hiveRunsBox = 'runs';

  // 地图配置
  static const String amapAndroidKey = 'f50e31d4bd4b6cb53cbf2a019d9be9ba';
  static const String amapIOSKey = 'ba4ae4ccb77b7e8aa34ff999dae8e53c';

  // 语音风格
  static const List<Map<String, String>> voiceStyles = [
    {'id': 'standard', 'name': '标准', 'desc': '清晰准确的跑步数据播报'},
    {'id': 'jianghu', 'name': '江湖', 'desc': '道友已行五里，步频稳健，风采不减！'},
    {'id': 'coach', 'name': '教练', 'desc': '3公里完成，配速略快，注意控制节奏'},
    {'id': 'toxic', 'name': '毒舌', 'desc': '3公里了，配速6:08？隔壁大妈走得比你快'},
  ];
}

/// 跑步模式枚举
enum RunMode {
  solo('独自跑', '自由跑步，记录个人数据'),
  companion('陪跑', '选择路线，与跑伴影子同步'),
  challenge('挑战跑', '向排行榜对手发起挑战');

  final String label;
  final String description;

  const RunMode(this.label, this.description);
}

/// 陪跑模式枚举
enum GhostMode {
  realReplay('真实回放', '严格按原跑者实际配速推进'),
  constantPace('匀速目标', '以原跑者平均配速匀速前进'),
  rabbit('兔子模式', '比原跑者快5%，始终在前方引导'),
  tortoiseHare('龟兔模式', '前半程快，后半程慢（负分段）'),
  goalChallenge('目标挑战', '选择维度挑战对手水平');

  final String label;
  final String description;

  const GhostMode(this.label, this.description);
}

/// 挑战维度枚举
enum ChallengeMetric {
  pace('配速', 'min/km'),
  heartRate('心率', 'bpm'),
  cadence('步频', 'spm'),
  strideLength('步幅', 'm');

  final String label;
  final String unit;

  const ChallengeMetric(this.label, this.unit);
}

/// 广播触发类型
enum BroadcastTriggerType {
  distance,   // 按距离触发
  time,       // 按时间触发
  abnormal,   // 仅异常触发
}

/// 广播频率/周期枚举
/// 
/// 注意：触发逻辑由 [triggerType] + [interval] 共同决定：
/// - distance: 每跑够 interval 米触发一次
/// - time: 每经过 interval 秒触发一次
/// - abnormal: 不主动触发，仅在配速/心率偏离目标时播报
enum BroadcastFrequency {
  every200m(200, '每200米', BroadcastTriggerType.distance),
  every500m(500, '每500米', BroadcastTriggerType.distance),
  every1000m(1000, '每1000米', BroadcastTriggerType.distance),
  every5min(300, '每5分钟', BroadcastTriggerType.time),    // 300秒 = 5分钟
  every10min(600, '每10分钟', BroadcastTriggerType.time),  // 600秒 = 10分钟
  abnormalOnly(0, '仅异常', BroadcastTriggerType.abnormal);

  /// 间隔值：distance 模式下单位为米，time 模式下单位为秒，abnormal 模式下为 0
  final int interval;
  final String label;
  final BroadcastTriggerType triggerType;

  const BroadcastFrequency(this.interval, this.label, this.triggerType);

  /// 获取距离间隔（米），仅在 distance 模式下有效
  int? get distanceMeters => triggerType == BroadcastTriggerType.distance ? interval : null;

  /// 获取时间间隔（秒），仅在 time 模式下有效
  int? get timeSeconds => triggerType == BroadcastTriggerType.time ? interval : null;

  /// 是否按距离触发
  bool get isDistance => triggerType == BroadcastTriggerType.distance;

  /// 是否按时间触发
  bool get isTime => triggerType == BroadcastTriggerType.time;

  /// 是否仅异常触发
  bool get isAbnormal => triggerType == BroadcastTriggerType.abnormal;
}
