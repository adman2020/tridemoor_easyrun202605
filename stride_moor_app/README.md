# 驰陌 / StrideMoor

> **驰于阡陌，自在奔跑**  
> **Stride in Moor, Run at Ease**

社交跑步教练 APP —— 以路线为锚点，用数据对比帮助朋友改进跑步技术，有目标地跑步。

---

## 核心闭环

```
跑者A跑完路线 → 保存为路线 → 分享路线卡
    ↓
跑者B看到 → 导入收藏到自己跑迹 → 随时可开始伴跑
    ↓
跑者B到起点 → 选择伴跑模式 → 实时影子伴跑 + 语音解说
    ↓
跑者B完成 → 自动生成对比报告 → 诊断建议 → 分享进步
```

---

## 技术栈

| 层级 | 技术选型 |
|------|---------|
| 框架 | Flutter 3.x (Dart) |
| 状态管理 | Riverpod 2.x |
| 路由 | GoRouter |
| 本地存储 | Hive + SQLite |
| 地图 | 高德地图 Flutter 插件 (国内) / MapBox (海外) |
| BLE | flutter_blue_plus |
| 传感器 | sensors_plus + pedometer |
| 音频 | just_audio + flutter_tts |
| 网络 | Dio |

---

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # MaterialApp 配置
├── config/
│   ├── constants.dart        # 全局常量、枚举
│   ├── routes.dart           # GoRouter 路由配置
│   └── theme.dart            # 主题与配色
├── core/
│   ├── models/               # 数据模型 (Freezed)
│   │   ├── user.dart
│   │   ├── route.dart
│   │   ├── run.dart
│   │   ├── run_split.dart
│   │   └── challenge.dart
│   ├── providers/            # Riverpod 状态管理
│   │   ├── app_providers.dart
│   │   ├── run_provider.dart
│   │   ├── route_provider.dart
│   │   └── user_provider.dart
│   ├── services/             # 业务服务层
│   │   ├── api_service.dart
│   │   ├── storage_service.dart
│   │   ├── location_service.dart
│   │   ├── audio_service.dart
│   │   └── ble_service.dart
│   └── utils/                # 工具类
│       ├── formatters.dart
│       ├── gps_utils.dart
│       └── route_matcher.dart
├── modules/                  # 功能模块 (按 Tab 划分)
│   ├── discover/             # 发现模块
│   ├── run/                  # 运动模块 (核心)
│   ├── routes/               # 跑迹模块
│   └── profile/              # 我的模块
└── widgets/                  # 通用组件
    └── shell_scaffold.dart   # 底部导航壳
```

---

## 快速开始

### 1. 环境准备

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0
- Android Studio / Xcode

### 2. 依赖安装

```bash
cd stride_moor_app
flutter pub get
```

### 3. 代码生成（模型序列化）

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. 运行

```bash
# Android
flutter run

# iOS
flutter run -d ios
```

---

## 四大模块

| Tab | 模块 | 核心页面 |
|-----|------|---------|
| 🏠 发现 | 内容入口 + 个人记录 | 首页Feed、运动记录、跑迹广场、跑步详情 |
| 🏃 运动 | 运动全流程 | 跑步准备、GPS搜星、跑步中、跑步结束 |
| 📁 跑迹 | 跑迹管理中心 | 我的跑迹、附近推荐、上传跑迹、对比报告 |
| 👤 我的 | 个人中心 + 设置 | 个人主页、播报设置、设备管理、跑步统计 |

---

## MVP 核心功能

- [x] GPS 轨迹实时采集与记录
- [x] 跑步数据面板（配速/距离/用时/心率）
- [x] 路线保存与分享
- [x] 影子伴跑模式（真实回放 + 匀速目标）
- [x] 实时语音播报系统
- [x] 跑完后多维对比报告
- [ ] 高德地图 SDK 接入（需配置 Key）
- [ ] BLE 心率设备连接
- [ ] 后端 API 对接
- [ ] GPX 导入/导出

---

## 配置说明

### 高德地图 Key

在 `lib/config/constants.dart` 中配置：

```dart
static const String amapAndroidKey = 'YOUR_AMAP_ANDROID_KEY';
static const String amapIOSKey = 'YOUR_AMAP_IOS_KEY';
```

同时在 `AndroidManifest.xml` 和 `Info.plist` 中配置对应 Key。

### 后端 API

在 `lib/config/constants.dart` 中配置：

```dart
static const String baseUrl = 'https://api.stridemoor.com/v1';
```

---

## 开发规范

- 使用 **Riverpod** 进行状态管理，避免 StatefulWidget 嵌套过深
- 数据模型使用 **Freezed** + **json_serializable** 生成不可变模型
- 页面间传参使用 **GoRouter** 的 `extra` 或 `pathParameters`
- 通用组件放在 `widgets/` 目录，业务组件放在各自模块内
- 服务层保持纯 Dart，不依赖 Flutter 特定 API（便于单元测试）

---

*文档版本: v0.1 | 更新日期: 2026-04-25*
