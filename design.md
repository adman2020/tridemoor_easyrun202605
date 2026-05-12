# 驰陌 / StrideMoor — 系统设计文档 (Design.md)

> 本文档是 `requirements.md` 的技术实现蓝图，涵盖前端、后端、数据库的完整设计。
> 版本：v2.12 | 日期：2026-05-12
> 更新内容：运动记录筛选方案 + 跑迹广场方案B（独立运动类型下拉） + 个人中心统计卡片分两行（🏃跑步/🚴骑行） + 路线路线详情/上传/排行榜按sport_type动态展示

---

## 一、概述

### 1.1 文档目的

为「驰陌 StrideMoor」社交跑步教练 APP 提供一份可供全面开发阶段参考的技术设计文档。本文档与 `requirements.md` 对应，将产品需求转化为可执行的技术方案。

### 1.2 设计原则

| 原则 | 说明 |
|------|------|
| **移动优先** | 核心体验在手机上，Web 仅作辅助预览 |
| **离线可用** | 跑步记录本地存储，有网时自动同步 |
| **实时同步** | 影子伴跑、挑战状态需要低延迟同步 |
| **数据驱动** | 所有跑步数据结构化存储，支持后续 AI 分析 |
| **渐进增强** | MVP 先做核心闭环，二期扩展设备生态和 AI |

### 1.3 技术栈总览

| 层级 | 技术方案 | 版本 |
|------|---------|------|
| **客户端** | Flutter | 3.41.7 stable, Dart 3.11.5 |
| **状态管理** | Riverpod + flutter_riverpod | ^2.4.9 |
| **路由** | go_router | ^13.0.1 |
| **本地存储** | Hive（配置/缓存） | ^2.2.3 |
| **网络** | dio | ^5.4.0 |
| **地图** | 高德地图 SDK（`gmm_amap_flutter_map` 社区版） | ^3.1.4 |
| **后端服务** | Go | 1.22 |
| **Web 框架** | Gin | v1.9.1 |
| **ORM** | GORM + MySQL driver | v1.25.12 |
| **数据库** | MySQL 8.0（业务数据 + 时序分区表） | 8.0 |
| **缓存** | Redis 7 | 7-alpine |
| **对象存储** | MinIO（自建） | 开发阶段用本地文件系统占位 |
| **消息队列** | Redis Streams（二期） | — |
| **推送** | 极光推送 jpush（待升级兼容 AGP 8.x） | — |

---

## 二、系统架构总览

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              客户端层                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌──────────┐ │
│  │   Flutter   │    │   高德地图   │    │   BLE蓝牙   │    │  传感器   │ │
│  │   (UI)      │    │   (轨迹)     │    │  (心率带)   │    │ (GPS/计步)│ │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └────┬─────┘ │
│         │                  │                  │                │       │
│  ┌──────┴──────────────────┴──────────────────┴────────────────┴─────┐  │
│  │                         本地数据层                                  │  │
│  │  Hive(配置) │ SQLite(跑步记录) │ GPX文件(轨迹) │ 缓存图片           │  │
│  └──────────────────────────────┬────────────────────────────────────┘  │
└─────────────────────────────────┼───────────────────────────────────────┘
                                  │ HTTPS / WebSocket
┌─────────────────────────────────┼───────────────────────────────────────┐
│                              网关层                                       │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  Nginx / Traefik（反向代理 + SSL终止 + 静态资源）                  │   │
│  │  ├─ 限流（Rate Limiting）                                        │   │
│  │  ├─ JWT 认证校验                                                 │   │
│  │  └─ 请求路由分发                                                 │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────┼───────────────────────────────────────┐
│                              服务层                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ 用户服务  │  │ 路线服务  │  │ 跑步服务  │  │ 挑战服务  │  │ 文件服务  │  │
│  │ (User)   │  │ (Route)  │  │ (Run)    │  │(Challenge)│  │ (Upload) │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                          │
│  │ 社交服务  │  │ 排行榜   │  │ 推送服务  │                          │
│  │ (Social) │  │(Leader)  │  │ (Push)   │                          │
│  └──────────┘  └──────────┘  └──────────┘                          │
└─────────────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────┼───────────────────────────────────────┐
│                              数据层                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐  │
│  │    MySQL 8.0     │  │     Redis 7      │  │       MinIO             │  │
│  │  (业务数据)      │  │  (缓存/排行榜/会话)│  │  (头像/GPX/分享图片)      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 三、前端设计（Flutter）

### 3.1 项目目录结构（实际）

> 构建指南详见 [`BUILD.md`](../BUILD.md)，含版本号规则、自动构建脚本、常见问题。

```
lib/
├── app.dart                    # 根应用组件（ScreenUtilInit + MaterialApp）
├── main.dart                   # 入口（初始化 Hive + 定位 SDK）
│
├── config/                     # 全局配置
│   ├── constants.dart          # 常量（API 地址、超时、跑步模式枚举）
│   ├── routes.dart             # GoRouter 全局路由配置
│   └── theme.dart              # 亮色/暗色主题 + 自定义色板
│
├── core/                       # 核心层
│   ├── models/                 # 数据模型（Freezed + JSON Serializable）
│   │   ├── user.dart           # 用户模型
│   │   ├── route.dart          # 路线模型
│   │   ├── run.dart            # 跑步记录模型
│   │   ├── run_split.dart      # 分段数据模型
│   │   └── challenge.dart      # 挑战模型
│   ├── providers/              # Riverpod Providers
│   │   ├── app_providers.dart      # 全局 Provider 汇总
│   │   ├── user_provider.dart      # 用户认证状态
│   │   ├── run_provider.dart       # 跑步会话状态
│   │   └── route_provider.dart     # 路线数据
│   ├── services/               # 服务层
│   │   ├── api_service.dart        # Dio HTTP 客户端
│   │   ├── location_service.dart   # 高德定位 + GPS 工具
│   │   ├── storage_service.dart    # Hive 本地存储
│   │   ├── ble_service.dart        # BLE 蓝牙心率（占位）
│   │   ├── health_sync_service.dart    # Health Connect / Apple Health 数据同步
│   │   ├── health_data_source.dart     # ✅ 健康数据源抽象工厂（自动检测 iOS/Android/HMS）
│   │   ├── hms_health_sync_service.dart # 华为 HMS Health Kit 数据同步
│   │   └── voice_broadcast_service.dart  # ✅ 语音播报（flutter_tts TTS，已实现）
│   └── utils/                  # 工具函数
│       ├── formatters.dart         # 格式化（配速/时间/距离）
│       ├── gps_utils.dart          # GPS 计算工具
│       └── route_matcher.dart      # 轨迹匹配
│
├── modules/                    # 页面模块（按业务域划分）
│   ├── discover/               # 发现 Tab
│   │   ├── discover_page.dart
│   │   ├── feed_page.dart
│   │   ├── run_history_page.dart
│   │   ├── run_detail_page.dart
│   │   ├── route_square_page.dart
│   │   └── route_detail_page.dart
│   ├── activity/               # 运动入口（跑步/骑行二选一）
│   │   └── sport_mode_select_page.dart  # 运动模式选择页
│   ├── run/                    # 跑步流程
│   │   ├── run_preparation_page.dart
│   │   ├── gps_search_page.dart
│   │   ├── running_page.dart
│   │   └── run_finish_page.dart
│   ├── cycling/                # 骑行流程（新建模块）
│   │   ├── cycling_preparation_page.dart # 骑行准备（模式+路线+BLE连接）
│   │   ├── cycling_page.dart              # 骑行中（均速/踏频/心率/GPS）
│   │   └── cycling_finish_page.dart       # 骑行完成报告
│   ├── routes/                 # 跑迹 Tab（4 Tab 布局：我的跑迹/跑友跑迹/上传管理/我的热度）
│   │   ├── routes_home_page.dart  # 主页面 + 4 Tab + 详情 BottomSheet
│   │   └── comparison_report_page.dart
│   └── profile/                # 我的 Tab
│       ├── profile_page.dart
│       ├── challenge_history_page.dart
│       ├── broadcast_settings_page.dart
│       ├── running_stats_page.dart
│       ├── device_management_page.dart
│       ├── health_sync_page.dart        # ✅ 健康数据同步导入（自动检测平台+勾选记录+导入后端）
│       ├── friends_page.dart
│       ├── friend_detail_page.dart       # ✅ 跑友详情页（跑境/里程/次数/时长/卡路里）
│       ├── avatar_crop_page.dart        # ✅ 手动头像裁剪（InteractiveViewer+圆形框）
│       ├── paojing_rules_page.dart       # ✅ 跑境规则（13境递进表）
│       └── challenge_rules_page.dart     # ✅ 挑战跑规则（7项规则说明）
│
├── widgets/                    # 公共组件
│   ├── shell_scaffold.dart     # 底部导航壳（BottomAppBar + 凹陷 FAB）
│   ├── amap_map_view.dart      # 高德地图统一封装
│   └── common_widgets.dart     # 通用 UI 组件
│
└── l10n/                       # 国际化
    ├── app_localizations.dart
    ├── app_localizations_en.dart
    └── app_localizations_zh.dart
```

### 3.2 路由设计（已实现）

| 路径 | 页面 | 参数 | 说明 |
|------|------|------|------|
| `/` | DiscoverPage | — | 发现页（首页） |
| `/feed` | FeedPage | — | 跑友动态 |
| `/history` | RunHistoryPage | `sport_type`(可选) | 运动记录（统一列表，AppBar下拉筛选：全部/跑步/骑行/日期） |
| `/run/:runId` | RunDetailPage | `runId` | 跑步详情 |
| `/cycle/:cycleId` | CycleDetailPage | `cycleId` | 骑行详情（新建） |
| `/square` | RouteSquarePage | `sport_type`(可选) | 跑迹广场（新增运动类型下拉：全部/跑步/骑行） |
| `/route/:routeId` | RouteDetailPage | `routeId` | 路线详情（根据sport_type显示跑步/骑行指标） |
| `/activity` | SportModeSelectPage | — | 运动模式选择（跑步/骑行二选一） |
| `/activity/gps` | GpsSearchPage | — | GPS 搜星 |
| `/activity/ongoing` | RunningPage | `mode`, `route`, `ghostMode`, `challengeMetric` | 跑步中 |
| `/activity/finish` | RunFinishPage | `run` | 跑步结束 |
| `/activity/cycling/preparation` | CyclingPreparationPage | — | 骑行准备（模式选择+选路线+连接BLE） |
| `/activity/cycling/ongoing` | CyclingPage | `mode`, `route`, `ghostMode` | 骑行中 |
| `/activity/cycling/finish` | CyclingFinishPage | `cycle` | 骑行结束 |
| `/routes` | RoutesHomePage | — | 跑迹首页（4 Tab：我的跑迹/跑友跑迹/上传管理/我的热度） |
| `/routes/comparison` | ComparisonReportPage | `runA`, `runB` | 伴跑 PK 对比报告 |
| `/profile` | ProfilePage | — | 个人中心 |
| `/profile/broadcast` | BroadcastSettingsPage | — | 播报设置 |
| `/profile/challenges` | ChallengeHistoryPage | — | 挑战记录（个人历史统计：总次数/胜利/失败 + 已完成挑战明细列表） |
| `/profile/stats` | RunningStatsPage | — | 统计报表 |
| `/profile/devices` | DeviceManagementPage | — | 设备管理 |
| `/profile/health-sync` | HealthSyncPage | `deviceId`, `connType` | 健康数据同步导入（自动检测平台→授权→拉取→勾选→导入后端） |
| `/profile/friends` | FriendsPage | — | 跑友列表 |
| `/profile/friends/:userId` | FriendDetailPage | `userId` | 跑友详情（跑境/里程/次数/时长/卡路里） |
| `/profile/paojing` | PaojingRulesPage | — | 跑境规则（13境递进表） |
| `/profile/challenge` | ChallengeRulesPage | — | 挑战跑规则（7项规则说明） |

### 3.3 状态管理设计

采用 **Riverpod** 分层架构：

```
┌─────────────────────────────────────────┐
│           UI Layer (ConsumerWidget)      │
│  ┌───────────────────────────────────┐  │
│  │  pages / widgets 直接 watch/read   │  │
│  └───────────────────────────────────┘  │
├─────────────────────────────────────────┤
│        State Layer (StateNotifier)       │
│  ┌───────────────────────────────────┐  │
│  │  RunSessionNotifier               │  │
│  │  AuthNotifier                     │  │
│  │  RouteListNotifier                │  │
│  └───────────────────────────────────┘  │
├─────────────────────────────────────────┤
│       Repository Layer (Provider)        │
│  ┌───────────────────────────────────┐  │
│  │  apiServiceProvider               │  │
│  │  locationServiceProvider          │  │
│  │  storageServiceProvider           │  │
│  └───────────────────────────────────┘  │
├─────────────────────────────────────────┤
│          Data Source Layer               │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
│  │  HTTP API │ │ 本地存储  │ │ 定位SDK │ │
│  │  (Dio)   │ │ (Hive)   │ │ (高德)  │ │
│  └──────────┘ └──────────┘ └─────────┘ │
└─────────────────────────────────────────┘
```

### 3.4 高德地图封装 (`AmapMapView`)

```dart
class AmapMapView extends StatefulWidget {
  final Set<Polyline>? polylines;      // 轨迹折线
  final Set<Marker>? markers;          // 标记点
  final bool myLocationEnabled;        // 定位蓝点
  final bool followMyLocation;         // 跟随模式
  final MapType mapType;               // 地图类型
  final CameraPosition? initialCameraPosition;
  final void Function(AMapController)? onMapCreated;
}
```

**使用场景：**
- `RunningPage`：`myLocationEnabled=true, followMyLocation=true, polylines=轨迹点`
- `RouteDetailPage`：`myLocationEnabled=false, initialCameraPosition=路线中心点`
- `NearbyRoutesPage`：`markers=附近路线标记点`

### 3.5 语音播报服务 (`VoiceBroadcastService`)

**设计定位**: 跑步中实时 TTS 语音播报，支持自定义频率、播报内容和语音风格。

#### 核心类结构

```dart
/// 语音播报服务
class VoiceBroadcastService {
  final FlutterTts _tts = FlutterTts();
  double _lastTriggerDistance = 0;  // 上次播报时的距离（米）
  int _lastTriggerTime = 0;         // 上次播报时的耗时（秒）
  bool _goalAnnounced = false;      // 目标达成已播报

  Future<void> init();              // 初始化 TTS（中文语言/语速/音量）
  Future<void> onStateUpdate(RunSessionState state);  // 状态更新 → 触发播报
  Future<void> speakNumber(String number);  // 🆕 播报单个数字（倒计时用）
  Future<void> speakStartText(String style);  // 🆕 播报"开始运动"（各风格）
  Future<void> stop();              // 停止当前播报
  void reset();                     // 重置所有触发状态
  Future<void> dispose();           // 释放资源
}
```

#### 播报逻辑

```
每次状态更新:
1. 暂停状态 → 跳过
2. 异常模式 → 跳过（仅异常时播报，待接入）
3. 距离模式: floor(distance / interval) 变化 → 触发
4. 时间模式: floor(duration / interval) 变化 → 触发
5. 目标达成（仅一次）: 检查 runGoal 是否达成 → 触发祝贺
6. 更新 _lastTriggerDistance / _lastTriggerTime
```

#### 文案生成（分风格）

| 风格 | 距离 | 配速 | 心率 | 目标达成 |
|------|------|------|------|---------|
| **标准** | "已跑x公里" | "当前配速5'30\"" | "心率x" | "恭喜完成了x目标" |
| **江湖** | "已行x里" | "配速5'30\"" | "心率x" | "恭喜道友！修为大进" |
| **教练** | "已跑x公里" | (慢→建议加快 / 快→注意呼吸) | (高→偏高注意 / 低→偏低加加速) | "太棒了！做几个拉伸" |
| **毒舌** | "才x公里" | (慢→悠着点 / 快→太快了悠着点) | (高→偏高注意 / 低→可以加加速) | "呵，跑完了？明天继续" |

**v1.5 人性化改造**:
- **原则**: 健康跑不比快慢，只跟自己比，差异大了才提一句
- **首次跑**: 全程鼓励不评判（"第一次跑就很棒了"）
- **独跑比平时慢**: "道法自然，不必强求" / "保持节奏就好"（不再说"太慢了"）
- **独跑比平时快**: "较往日精进不少" / "状态不错"
- **心率偏高**: "今天心跳有点快" / "偏高注意安全"（不在说"不要命了？"）
- **步频/步幅**: 差异不大时只报数值，不评判
- **伴跑/挑战**: 保留原有逻辑（跟伴跑对象/对手相比）

#### 集成方式

**准备页** (`run_preparation_page.dart`):
- 添加状态变量：`_broadcastFreq`, `_broadcastItems`, `_voiceStyle`
- 调用 `session.configure(frequency:, items:, voice:)` 注入配置

**跑步中** (`running_page.dart`):
- `initState()` → `_voiceBroadcast.init()` 初始化 TTS
- `ref.listen(runSessionProvider)` → `_voiceBroadcast.onStateUpdate(next)` 触发播报
- `_initRun()` → 先播倒计时（`speakNumber`逐字播3-2-1 + `speakStartText`说"开始运动"），然后 `_voiceBroadcast.reset()` 重置状态
- `dispose()` → `_voiceBroadcast.dispose()` 释放

### 3.6 主题设计

```dart
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,        // #2E7D32 深绿
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.accent,       // #FF6D00 橙色
      surface: AppColors.surface,        // #FFFFFF
      background: AppColors.background,  // #F5F5F5
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    // ...
  );
  
  static ThemeData get darkTheme => ThemeData(
    // TODO: 精细调优暗色色板
  );
}
```

**当前策略：** 强制亮色模式（`ThemeMode.light`），暗色主题待完善。

### 3.7 国际化设计

- 强制 `locale: Locale('zh')`
- ARB 文件结构：`app_zh.arb` / `app_en.arb`
- 50+ 文案键，覆盖所有页面
- 后续扩展只需新增 `.arb` 文件

### 3.8 健康数据源架构 (`HealthDataSource`)

**设计定位**: 统一 Apple Health、Health Connect (Android) 和 HMS Health Kit (华为) 的数据访问，对上层提供一致接口。

#### 抽象工厂模式

```dart
/// 健康数据平台类型
enum HealthPlatform {
  appleHealth,      // iOS
  healthConnect,    // Android + Google 服务
  hmsHealthKit,     // 华为设备 + HMS Core
  unknown,
}

/// 抽象接口
abstract class HealthDataSource {
  HealthPlatform get platform;
  Future<bool> requestPermissions();
  Future<List<HealthWorkoutData>> fetchWorkouts({DateTime? since, DateTime? until});
}

/// 工厂方法
class HealthDataSourceFactory {
  static Future<HealthPlatform> detectPlatform() async { ... }
  // iOS → HealthSyncService (health 包)
  // 华为 → HmsHealthSyncService (huawei_health 插件)
  // 其他 Android → HealthSyncService (health 包 → Health Connect)
  static Future<HealthDataSource?> createDataSource() async { ... }
}
```

#### 平台检测逻辑

| 条件 | 平台 | 使用服务 |
|------|------|---------|
| `Platform.isIOS` | Apple Health | `health` 包 (`^13.1.4`) |
| HMS Core 可用 | HMS Health Kit | `huawei_health` 插件 (`^6.16.0+300`)，HMS SDK 自带 |
| 其他 Android | Health Connect | `health` 包 (`^13.1.4`) |
| 不满足以上 | 不支持 | 提示用户 |

#### 数据流

```
HealthSyncPage (UI)
  ↓ 调用
HealthDataSourceFactory.createDataSource()
  ↓ 自动检测平台
HealthDataSource (抽象)
  ├─ HealthSyncService (Apple Health / Health Connect)
  └─ HmsHealthSyncService (HMS Health Kit)
  ↓ requestPermissions()
  ↓ fetchWorkouts(since: 30天前)
健康平台返回 List<HealthWorkoutData>
  ↓ UI 展示列表（距离/时间/配速/心率/卡路里），华为记录标记
  ↓ 用户勾选 → 提交
POST /api/v1/runs/import → 后端入库
```

#### 华为 Health Kit 集成

| 项目 | 配置 |
|------|------|
| Flutter 插件 | `huawei_health: ^6.16.0+300` |
| Android 配置 | `agconnect-services.json` 已放置到 `android/app/` |
| AGConnect Gradle 插件 | ❌ **不需要** — `huawei_health` 插件自身已内嵌 HMS Health SDK 依赖 |
| 构建验证 | ✅ `flutter build apk --debug` 编译通过 |

---
### 3.9 数据模型安全反序列化 (_parseStringList)

**背景**: Go 后端将 RealmBadges string、VipFeatures string 等字段通过 GORM 	ype:json 存储为 JSON 字符串，Go 序列化后产生 JSON 字符串值（如 "realm_badges":"[\"气\",\"筑\"]"），但 Flutter 模型用 s List<dynamic>? 尝试强转为数组，当值为非空字符串时抛出 _CastError: type 'String' is not a subtype of type 'List<dynamic>?'。

**AutoMigrate 副作用**: 加新列时旧行默认值从 SQL NULL（
ull as List? 合法）变成 Go 零值 ""（"" as List? 非法），直接导致已登录用户下次启动崩溃。

**设计模式**:

`dart
/// 安全解析后端JSON字符串数组字段
/// Go 将 string(JSON数组) 序列化为 JSON 字符串，与 List 格式互转
static List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
  }
  return [];
}
`

**适用范围** (User.fromJson):
- 
ealmBadges / ipFeatures / deviceInfo

**教训**: Go 的 RealmBadges string json:"realm_badges" 与 GORM 	ype:json 组合时，序列化结果为 JSON 字符串。Flutter 反序列化不能硬用 s List，须先 is 检查类型，字符串则 jsonDecode 后再 map。

### 3.10 模式图标设计 (_buildModeIcon)

**定位**: 跑步模式选择器中的视觉图标，区分独自跑/伴跑/挑战跑三种模式。

| 模式 | 图标元素 | 布局方式 |
|------|----------|----------|
| 独自跑 | 单个人 Icons.directions_run | 直接 Icon |
| 伴跑 | 两个人并排 Icons.directions_run x2 | Row(mainAxisAlignment: center) 居中 |
| 挑战跑 | 小人 + 头顶奖杯 Icons.emoji_events | Stack: 小人 Positioned(bottom:0)，奖杯 Positioned(bottom: personHeight) |

**实现位置**:
- 准备页: 
un_preparation_page.dart::_buildModeIcon() (pill按钮内徽标)
- 运动记录: 
un_history_page.dart::_RunHistoryCard (模式小图标)
- 我的热度: 
outes_home_page.dart::_buildStatsContent (热度看板)

**注意事项**:
- 伴跑两个小人用 Row 居中替代旧版 Stack(默认左上)，避免偏移
- 挑战跑奖杯用 Positioned(bottom: size * 0.85) 替代旧版 Center + Padding，避免与小人重叠

---

## 四、后端设计

### 4.1 技术选型

| 项目 | 方案 | 版本 | 理由 |
|------|------|------|------|
| 语言 | Go | 1.22 | 高并发、编译快、部署轻 |
| Web 框架 | Gin | v1.9.1 | 成熟、性能好、生态丰富 |
| ORM | GORM | v1.25.12 | 支持 MySQL、自动迁移 |
| 数据库 | MySQL 8.0 | 8.0 | 业务数据 + RANGE 分区时序表 |
| 缓存 | Redis 7 | 7-alpine | 排行榜、会话、热点数据 |
| 对象存储 | MinIO（本地占位） | — | 开发阶段用本地文件系统，生产切 MinIO |
| 认证 | JWT (golang-jwt/jwt/v5) | v5.2.0 | 无状态认证 |
| 密码哈希 | bcrypt (golang.org/x/crypto) | v0.21.0 | 业界标准 |

### 4.2 项目目录结构（实际）

```
backend/
├── cmd/
│   └── server/
│       └── main.go             # 主入口
├── configs/
│   └── config.yaml             # 配置文件
├── internal/
│   ├── handler/                # HTTP Handler
│   │   ├── user.go
│   │   ├── run.go
│   │   ├── route.go
│   │   ├── friendship.go
│   │   ├── challenge.go
│   │   └── upload.go
│   ├── service/                # 业务逻辑层
│   │   ├── user.go
│   │   ├── run.go
│   │   ├── route.go
│   │   ├── friendship.go
│   │   ├── challenge.go
│   │   └── upload.go
│   ├── repository/             # 数据访问层（DAO）
│   │   ├── user.go
│   │   ├── run.go
│   │   ├── run_sample.go
│   │   ├── route.go
│   │   ├── friendship.go
│   │   └── challenge.go
│   ├── model/                  # GORM 领域模型
│   │   ├── user.go
│   │   ├── route.go
│   │   ├── run.go
│   │   └── challenge.go
│   ├── middleware/             # 中间件
│   │   └── auth.go             # JWT 认证
│   └── router/
│       └── router.go           # 路由注册
├── pkg/                        # 公共库
│   ├── database/
│   │   ├── database.go         # MySQL 连接初始化
│   │   └── minio.go            # 存储客户端（本地文件占位）
│   ├── jwt/
│   │   └── jwt.go              # JWT 生成/解析
│   ├── password/
│   │   └── password.go         # bcrypt 哈希
│   └── response/
│       └── response.go         # 统一响应封装
├── migrations/
│   ├── 001_init.up.sql         # 数据库初始化（10张表 + 分区）
│   └── 001_init.down.sql       # 回滚脚本
├── go.mod
└── Dockerfile
```

### 4.3 API 设计规范

**Base URL:** `http://localhost:8080/api/v1`

**通用响应格式：**

```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

**错误码规范：**

| Code | 含义 |
|------|------|
| 0 | 成功 |
| 1001 | 参数错误 |
| 1002 | 未授权 |
| 1003 | Token 已过期 |
| 1004 | 资源不存在 |
| 2001 | 用户已存在 |
| 2002 | 密码错误 |
| 3001 | 路线不存在 |
| 4001 | 挑战已过期 |

### 4.4 已实现 API 接口

#### 4.4.1 用户模块

```http
POST   /api/v1/auth/register          # 注册（手机号 + 密码 + 邮箱 + 体重）
POST   /api/v1/auth/login             # 登录（手机号 + 密码）
GET    /api/v1/user/profile           # 获取当前用户信息（Bearer Token）
```

**VIP 增值服务体系：**

| 用户类型 | AI 跑情分析 | 语音播报 | 说明 |
|---------|------------|---------|------|
| **VIP用户** | ✅ 可用 | ✅ 可用 | is_vip=true，显示橙色「AI 跑情分析」按钮 |
| **普通用户** | ❌ 不可用 | ✅ 可用 | is_vip=false，显示灰色「开通VIP解锁AI分析」按钮 |

**VIP 身份判断：**
- 字段：`users.is_vip` (TINYINT(1), DEFAULT 0)
- 判断逻辑：后端返回 `is_vip` 字段 → 前端根据值显示不同 UI
- VIP 等级管理：在管理台设置，不在 App 端

**请求/响应示例：**
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "123456",
  "email": "test@example.com",
  "weight": 65.0,
  "nickname": "测试用户"
}

# 响应
{
  "code": 0,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "expires_in": 604800
  }
}
```

**获取用户信息响应示例（含VIP/跑境）：**
```http
GET /api/v1/user/profile
Authorization: Bearer {token}

# 响应
{
  "code": 0,
  "data": {
    "id": "uuid",
    "phone": "13800138000",
    "nickname": "测试用户",
    "avatar": "https://...",
    "email": "user@example.com",
    "bio": "跑步爱好者",
    "gender": 1,
    "birthday": "1990-01-01",
    "height": 175,
    "weight": 70.0,
    "is_vip": true,
    "vip_tier": 2,
    "total_distance": 52000.5,
    "total_runs": 86,
    "total_time": 360000,
    "total_calories": 28000,
    "realm": 4,
    "realm_badges": "[\"气\",\"筑\",\"丹\",\"婴\"]",
    "companion_runs": 12,
    "challenges_won": 5,
    "best_marathon_time": 14400,
    "post_count": 28,
    "cycling_realm": 0,
    "created_at": "2026-01-15T10:30:00Z"
  }
}
```

**VIP 体系说明：**
| 字段 | 类型 | 说明 |
|------|------|------|
| is_vip | bool | VIP 状态标识 |
| vip_tier | int8 | 0=非会员 1=标准 2=Pro 3=Ultra |
| vip_expires_at | datetime | VIP 到期时间（null=无限期） |
| vip_features | JSON | 已解锁功能列表，如 ["no_ads","ai_coach","advanced_stats"] |

#### 4.4.2 跑步记录模块

```http
POST   /api/v1/runs/start             # 开始跑步（创建记录）
POST   /api/v1/runs/import            # 批量导入健康平台跑步记录（Health Connect / HMS / Apple Health）
POST   /api/v1/runs/:id/samples       # 批量上传 GPS 采样点
POST   /api/v1/runs/:id/finish        # 结束跑步（上传统计数据）
GET    /api/v1/runs                   # 跑步记录列表（分页）
GET    /api/v1/runs/:id               # 跑步详情（含分段 + GPS 轨迹）
```

**结束跑步请求示例：**
```http
POST /api/v1/runs/{run_id}/finish
Content-Type: application/json
Authorization: Bearer {token}

{
  "end_time": "2026-04-27T10:30:00Z",
  "total_distance": 5200.50,
  "total_time": 1800,
  "avg_pace": 5.77,
  "best_pace": 4.50,
  "avg_heart_rate": 150,
  "max_heart_rate": 175,
  "avg_cadence": 168,
  "max_cadence": 185,
  "avg_stride_length": 1.02,
  "elevation_gain": 25.5,
  "elevation_loss": 20.0,
  "calories": 320,
  "weather": "晴朗",
  "temperature": 22,
  "splits": [
    {
      "split_index": 1,
      "distance": 1000,
      "time": 330,
      "pace": 5.50
    }
  ]
}
```

#### 4.4.3 路线模块

```http
POST   /api/v1/routes                 # 创建路线（含坐标点数组）
GET    /api/v1/routes                 # 路线列表（分页 + 筛选）
       ?city=上海&difficulty=2&distance_min=3000&distance_max=10000
       &keyword=滨江&sort_by=popularity&page=1&page_size=10
GET    /api/v1/routes/:id             # 路线详情（含坐标点 + 收藏状态）
PUT    /api/v1/routes/:id             # 更新路线（仅创建者）
DELETE /api/v1/routes/:id             # 删除路线（仅创建者）
POST   /api/v1/routes/:id/favorite    # 收藏路线
DELETE /api/v1/routes/:id/favorite    # 取消收藏
GET    /api/v1/routes/favorites       # 我的收藏列表
GET    /api/v1/routes/nearby          # 附近路线搜索
       ?lat=31.23&lng=121.47&radius=5000&limit=20
POST   /api/v1/routes/:id/rate        # 评分路线（0-5分）
GET    /api/v1/routes/:id/leaderboard # 路线排行榜（默认打卡榜；?sort_by=time_asc 切换成绩榜）
```

#### 4.4.4 好友模块

```http
POST   /api/v1/friends/requests              # 发送好友申请
GET    /api/v1/friends/requests/pending      # 待处理申请列表
POST   /api/v1/friends/requests/:id/accept   # 接受申请
POST   /api/v1/friends/requests/:id/reject   # 拒绝申请
GET    /api/v1/friends                       # 好友列表
DELETE /api/v1/friends/:id                   # 删除好友
```

#### 4.4.5 挑战/伴跑PK模块

```http
POST   /api/v1/challenges                 # 发起挑战
GET    /api/v1/challenges                 # 挑战列表（我发起/收到的；?status=completed 筛选已完成）
GET    /api/v1/challenges/:id             # 挑战详情
POST   /api/v1/challenges/:id/accept      # 接受挑战
POST   /api/v1/challenges/:id/start       # 开始挑战（创建关联跑步记录）
POST   /api/v1/challenges/:id/complete    # 完成挑战（上传结果）
POST   /api/v1/challenges/:id/cancel      # 取消挑战
GET    /api/v1/challenges/:id/comparison  # 对比报告
```

#### 4.4.6 跑友动态模块

```http
POST   /api/v1/posts              # 发布动态（content + 可选 run_id）
GET    /api/v1/posts              # 动态列表（分页）
GET    /api/v1/posts/:id          # 动态详情
DELETE /api/v1/posts/:id          # 删除动态
```

**挑战状态流转：**
```
pending（待接受） → accepted（已接受） → running（进行中） → completed（已完成）
                    ↓
                cancelled（已取消）
```

#### 4.4.6 文件上传模块

```http
POST   /api/v1/upload/avatar        # 上传头像（multipart/form-data, jpg/png/webp, max 5MB）
POST   /api/v1/upload/gpx           # 上传 GPX 轨迹文件（multipart/form-data, .gpx, max 10MB）
```

**更新资料请求示例：**
```http
PUT /api/v1/user/profile
Content-Type: application/json
Authorization: Bearer {token}

{
  "nickname": "新昵称",
  "email": "new@example.com",
  "bio": "跑步爱好者",
  "gender": 1,
  "height": 175,
  "weight": 70.0,
  "birthday": "1990-01-01"
}
```

**静态文件访问：**
```
GET /static/avatars/{user_id}/{timestamp}.jpg
GET /static/gpx/{user_id}/{timestamp}.gpx
```

### 4.5 WebSocket 设计（实时同步）— 二期

**连接地址：** `wss://api.stridemoor.com/v1/ws`

**认证方式：** 连接时通过 Query Parameter 传递 `token`

**消息格式：**

```json
{
  "type": "challenge_update",
  "payload": {
    "challenge_id": "xxx",
    "status": "running",
    "progress": { ... }
  }
}
```

**消息类型：**

| Type | 方向 | 说明 |
|------|------|------|
| `challenge_invite` | S→C | 收到挑战邀请 |
| `challenge_accept` | S→C | 对方接受挑战 |
| `challenge_progress` | C→S / S→C | 实时进度同步（伴跑时） |
| `challenge_complete` | S→C | 挑战完成通知 |
| `friend_request` | S→C | 收到好友申请 |
| `heartbeat` | C→S | 心跳包（30s 间隔） |

### 4.6 推送服务设计 — 二期

| 场景 | 推送内容 | 触发条件 |
|------|---------|---------|
| 挑战邀请 | "大衍神君向你发起挑战，点击查看" | 收到 challenge_invite |
| 挑战结果 | "挑战完成！你成功击败了对手" | challenge 状态变为 completed |
| 好友申请 | "韩立请求添加你为跑友" | 收到 friend_request |
| 跑步完成 | "本次跑步 5.2km，配速 6:08" | run 状态变为 completed |
| 周报告 | "本周跑了 25km，比上月 +15%" | 每周一 9:00 定时推送 |

---

## 五、数据库设计

### 5.1 ERD 关系图

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   users     │────<│    runs     │>────│   routes    │
│  (用户)      │ 1:N │  (跑步记录)  │ N:1 │  (路线)      │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                    │
       │            ┌──────┴──────┐            │
       │            │ run_splits  │            │
       │            │ (分段数据)   │            │
       │            └─────────────┘            │
       │                   │                    │
       │            ┌──────┴──────┐            │
       │            │run_samples  │            │
       │            │(时序数据)    │            │
       │            └─────────────┘            │
       │                                       │
       │            ┌─────────────┐     ┌─────────────┐
       │            │ route_points│     │leaderboards │
       │            │ (路线坐标点) │     │ (排行榜快照) │
       │            └─────────────┘     └─────────────┘
       │
       │     ┌─────────────┐     ┌─────────────┐
       └───> │ challenges  │<────│ comparisons │
         1:N │  (挑战)      │ 1:1 │ (对比报告)   │
             └──────┬──────┘     └─────────────┘
                    │
             ┌──────┴──────┐     ┌─────────────┐
             │ friendships │     │route_favorites│
             │  (好友关系)  │     │ (路线收藏)    │
             └─────────────┘     └─────────────┘
```

### 5.2 核心表结构

详见 `backend/migrations/001_init.up.sql`，包含以下 10 张业务表：

| 表名 | 说明 | 关键设计 |
|------|------|---------|
| `users` | 用户表 | 手机号唯一索引，累计跑量统计 |
| `routes` | 路线表 | 全文搜索 `idx_name` (ngram)，坐标索引 |
| `route_points` | 路线坐标点 | 复合主键 `(route_id, point_index)`，GORM AutoMigrate |
| `runs` | 跑步记录 | 关联 route_id（可为 NULL），时间索引 |
| `run_splits` | 分段数据 | 复合唯一键 `(run_id, split_index)` |
| `run_samples` | 秒级采样 | `RANGE COLUMNS` 按月分区，Event 自动创建新分区 |
| `route_favorites` | 路线收藏 | 复合唯一键 `(user_id, route_id)` |
| `challenges` | 挑战表 | 状态机：pending → accepted → running → completed |
| `comparisons` | 对比报告 | 关联 challenge_id，JSON 存储差异数据 |
| `friendships` | 好友关系 | CHECK `user_id_a < user_id_b` 防重复 |

### 5.3 Redis 缓存设计 — 二期

| Key 模式 | 类型 | TTL | 说明 |
|----------|------|-----|------|
| `user:session:{token}` | String | 7d | JWT Token → user_id 映射 |
| `user:profile:{id}` | String | 1h | 用户基本信息缓存 |
| `route:detail:{id}` | String | 30m | 路线详情缓存 |
| `route:list:hot:{city}` | Sorted Set | 10m | 热门路线排行 |
| `route:list:nearby:{lat}:{lng}` | Sorted Set | 5m | 附近路线 |
| `leaderboard:route:{route_id}` | Sorted Set | 5m | 路线成绩排行 |
| `challenge:{id}:progress` | Hash | 1h | 挑战实时进度 |
| `rate_limit:{ip}:{path}` | String | 1m | API 限流计数 |

---

## 六、当前开发进度

### 6.1 后端完成度（100% MVP）

| 模块 | 状态 | 说明 |
|------|------|------|
| 用户模块 | ✅ | 注册/登录/JWT/个人信息 |
| 跑步记录模块 | ✅ | 开始/采样上传/结束/列表/详情 |
| 路线模块 | ✅ | CRUD/收藏/排行榜/附近搜索/评分/更新 |
| 好友模块 | ✅ | 申请/接受/拒绝/列表/删除 |
| 排行榜自动计算 | ✅ | 完成跑步关联路线时自动写入/更新 |
| 挑战/伴跑PK模块 | ✅ | 发起/接受/开始/完成/取消/对比报告 |
| 文件上传 | ✅ | 头像/GPX（开发阶段本地文件系统占位） |
| 零公里跑记录清理 | ✅ | Windows计划任务StrideMoor-CleanupZeroRuns，每日3:00执行；清理条件：total_distance=0 AND total_time IS NULL；PowerShell包裹脚本+日志 |
| 路线GPS数据修复 | ✅ | 大沙河生态长廊13.7km（深圳湾→长岭陂水库），137轨迹点；深圳湾公园晨跑线替换为GPX骑行数据（8.96km）；新建福田中心区骑行线路（13.37km） |
| 全库GPS轨迹补全 | ✅ | 批量补全223条原无GPS采样点的跑步记录（326/329条已有GPS轨迹），基于关联路线route_points进行轨迹点模拟 |

### 6.2 前端完成度（UI 骨架 + 基础服务）

| 模块 | 状态 | 说明 |
|------|------|------|
| UI 页面骨架 | ✅ | 25+ 页面（含avatar_crop_page裁剪页、qr_scanner_page扫码页、跑境规则页/挑战跑规则页/跑友详情页）；User 模型已补全跑境/VIP/骑境字段；模式图标修复（伴跑Row居中、挑战跑Positioned头顶）；我的热度图标居中 |
| 高德地图集成 | ✅ | `gmm_amap_flutter_map` ^3.1.4，Key 已填入；跑迹卡片、跑步详情、跑友动态均使用 AMap 真实地图底图 |
| 跑迹模块 | ✅ | 4 Tab 布局（我的跑迹/跑友跑迹/上传管理/我的热度），含种子数据 |
| 主题系统 | ✅ | 强制亮色模式，暗色主题结构预留 |
| 数据模型 | ✅ | Freezed + JSON Serializable（5个核心模型）；_parseStringList() 安全解析 Go JSON 字符串字段（realm_badges/vip_features/deviceInfo） |
| 状态管理 | ✅ | Riverpod Provider 框架搭建；finishRun() 发送 splits 分段数据 |
| API 服务 | ✅ | Dio 客户端已对接后端核心接口（跑步/路线/收藏/排行榜/评分/挑战/动态/上传） |
| 定位服务 | ✅ | 高德定位 SDK 集成，跑步中轨迹实时采集+5秒批量上传；GPS搜星延迟3秒后开始3-2-1倒计时动画 |
| 语音播报 | ✅ | flutter_tts TTS 已接入（VoiceBroadcastService），准备页配置面板+跑中自动触发完整链路已通；默认播报含距离/配速/用时/步频/步幅/卡路里/心率；4种风格文案（标准/江湖/教练/毒舌）；倒计时逐秒播+开始运动播报 **v1.5人性化改造**：只跟自己比、鼓励语气替代评判；**v2.0增强**：伴跑模式增加心率/步频/连续趋势判断（3公里领先/落后弹出趋势总结）；挑战跑模式增加累计时间差追踪（每公里gain/loss）
| 跑步中锁屏 | ✅ | 倒计时结束自动锁屏；全屏 `Positioned.fill` + `GestureDetector(onTap+onLongPressStart)` 吸收所有触摸事件，防止底下暂停/结束按钮被误触；**长按任意位置解锁**（非旧版上滑），口袋摩擦不会触发 |
| 倒计时动画 | ✅ | GPS 搜星完成后，屏幕中央 3→2→1 数字由大变小（2.0→0.6）缩放淡出，随后显示蓝色发光"开始运动！"，完毕后自动锁屏 |
| 健康数据同步 | ✅ | HealthDataSource 抽象工厂自动检测平台（Apple Health / Health Connect / HMS Health Kit）；`HealthSyncPage` 授权 → 拉取30天记录 → 列表展示（距离/时间/配速/心率/卡路里，华为标记）→ 勾选 → `POST /api/v1/runs/import` 导入后端；华为通过 `huawei_health` 插件直接调用 HMS SDK |
| 设备管理 | ✅ | 绑定 BLE 设备（设备类型+同步方式+命名）/ 解绑确认 / 健康平台同步入口（跳转 HealthSyncPage）/ 导入历史 |
| Profile页菜单 | ✅ | 移除占位项（通知/账号设置），添加帮助菜单（伴跑/跑境/挑战跑规则+关于），修改密码移至关注跑友下方 |
| 发现页每日金句 | ✅ | 境界分层（4层各10条）→ 每日候选池4条 → 随机取1条；跑境卡片点进详情，金句点刷新 |
| 运动页返回导航 | ✅ | AppBar leading 改为 `context.go('/')` 直达首页 |
| 播报设置页布局 | ✅ | 三行：播放频率→播报参数→语音风格，含描述文字 |
| 后端用户统计接口 | ✅ | GET /api/v1/users/:id/stats（总里程/次数/时长/卡路里/跑境/徽章） |
| 地图手势优化 | ✅ | 地图在ListView中拖动冲突修复：AmapMapView新增gestureRecognizers参数（EagerGestureRecognizer）；页面可独立控制scrollGesturesEnabled/zoomGesturesEnabled/rotateGesturesEnabled/tiltGesturesEnabled |
| 地图大小分层 | ✅ | 跑友动态卡片120px（原样），动态详情40%屏高，路迹广场详情50%屏高（SliverAppBar expandedHeight） |
| 运动准备页修复 | ✅ | 原有bug：ref.listen误写在initState中 → 移到build方法，解决运行时报错 |
| 收藏按钮修复 | ✅ | post_detail_page中收藏条件由post.route != null改为post.run != null，有跑迹即可收藏；**v2.0增强**：收藏/已收藏状态区分+置灰样式切换，BookmarkedRunIdsNotifier StateNotifier本地即时更新+后端同步 |
| 运动记录页优化 | ✅ | 移除initState中自动清理逻辑，保留右上角手动清理按钮 |
| 头像上传修复 | ✅ | 上传resp.data提取avatar URL→setUser(copyWith)即时更新；loadUserProfile后台同步 |
| 手动裁剪页面 | ✅ | avatar_crop_page.dart（InteractiveViewer+圆形裁剪框+缩放拖动+框外半透明遮罩）；坐标映射：viewport中心→矩阵逆变换→BoxFit.contain补偿→原始图片坐标；Canvas.drawImageRect输出512x512 PNG |
| 图片变形修复 | ✅ | RawImage→Image.file+BoxFit.contain（RawImage矩阵变换不兼容导致宽高比错误） |
| 裁切坐标偏移修复 | ✅ | 用_displaySize/2替代context.findRenderObject().size全屏中心作为裁剪中心；_centerImage改用单位矩阵（无偏移，由Center自动居中） |
| 头像本地缓存 | ✅ | 裁剪后立即写入Directory.systemTemp/avatar_cache.png；_buildUserHeader优先Image.file(cacheFile)；ValueKey('avatar_$_avatarCacheGen')强制重建解决二次更新Flutter内存缓存问题 |
| running_page修复 | ✅ | 删除build方法内重复_snapPanel；补bool _locationInitialized字段；duration→totalTime（Run模型字段名） |
| QR码扫描页 | ✅ | qr_scanner_page.dart独立页面（CameraPreview全屏+宽高配置），替代原ModalBottomSheet方案 |
| BLE 蓝牙 | ⏳ | 占位（心率设备连接） |
| 本地存储 | 🔄 | Hive 框架搭建，跑步数据离线存储待完善 |

### 6.3 待开发（二期）

| 功能 | 优先级 |
|------|--------|
| 前端 API 接口对接（ Dio → 后端 REST API） | P0 |
| 跑步中实时数据采集（GPS/配速/步频） | P0 |
| BLE 心率设备连接 | P1 |
| 跑步数据本地存储 + 离线同步 | P1 |
| WebSocket 实时同步（挑战进度） | P2 |
| 推送服务（极光推送） | P2 |
| AI 跑步诊断建议 | P2 |
| MinIO 对象存储（生产环境） | P2 |
| 暗色主题精细调优 | P3 |

---

## 七、部署说明

### 7.1 Docker 环境

```yaml
# docker-compose.yml
services:
  mysql:
    image: mysql:8.0
    ports: ["3308:3306"]
    environment:
      MYSQL_ROOT_PASSWORD: stridemoor_root_2026
      MYSQL_DATABASE: stridemoor
      MYSQL_USER: stridemoor
      MYSQL_PASSWORD: stridemoor_pass_2026
    volumes:
      - ./backend/migrations:/docker-entrypoint-initdb.d:ro
    command: >
      --default-authentication-plugin=mysql_native_password
      --event-scheduler=ON
      --innodb_buffer_pool_size=256M
  redis:
    image: redis:7-alpine
    ports: ["6380:6379"]
  minio:
    image: minio/minio
    ports: ["9002:9000", "9003:9001"]
```

### 7.2 启动命令

```bash
# 启动基础设施
docker-compose up -d

# 编译并启动后端
cd backend
go mod tidy
go run cmd/server/main.go

# 启动前端（真机/模拟器）
cd stride_moor_app
flutter pub get
flutter run
```

### 7.3 配置文件

```yaml
# backend/configs/config.yaml
server:
  port: "8080"
database:
  dsn: "stridemoor:stridemoor_pass_2026@tcp(localhost:3308)/stridemoor?charset=utf8mb4&parseTime=True&loc=Asia%2FShanghai"
redis:
  addr: "localhost:6380"
  password: ""
  db: 0
jwt:
  secret: "stridemoor_jwt_secret_key_2026"
  expire_hours: 168
  refresh_days: 30
minio:
  endpoint: "localhost:9002"
  access_key: "stridemoor"
  secret_key: "stridemoor_minio_2026"
  bucket: "stridemoor"
  use_ssl: false
```
