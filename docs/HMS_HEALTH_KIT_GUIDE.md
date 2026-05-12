# HMS Health Kit 集成指南

## 概述

StrideMoor 已集成 `huawei_health` Flutter 插件，支持从华为运动健康 App 导入跑步记录到 StrideMoor。

### 支持设备
- 华为手机 / HarmonyOS 设备
- 荣耀手机（需 HMS Core）
- 华为手表 / 手环（通过华为运动健康 App 同步数据）

## 接入步骤

### 1. AppGallery Connect 开通 Health Kit 服务

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 创建应用（如果已有，使用现有应用）
   - 包名必须与 Flutter 应用一致：`com.example.stride_moor`
3. 左侧菜单 → **项目管理** → 选择你的应用
4. 左侧菜单 → **增长** → **HMS Core** → **Health Kit**
5. 点击 **开通服务**
6. 按指引签署协议

### 2. 配置签名证书指纹

Health Kit 需要 SHA-256 证书指纹：

```bash
# 生成 debug 签名指纹
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep "SHA256"

# 或者使用你自己的签名文件
keytool -list -v -keystore your-release-key.jks -alias your-alias | grep "SHA256"
```

在 AppGallery Connect → 应用信息 → 添加 SHA-256 指纹。

### 3. 下载 agconnect-services.json

在 AppGallery Connect → 我的项目 → 应用 → **下载 agconnect-services.json**

放入项目目录：
```
stride_moor_app/android/app/agconnect-services.json
```

### 4. 代码已配置完成 ✅

以下文件已为您修改好：

| 文件 | 说明 |
|------|------|
| `pubspec.yaml` | 已添加 `huawei_health: ^6.16.0+300` |
| `android/settings.gradle.kts` | 已添加 `com.huawei.agconnect` 插件 + 华为 Maven 仓库 |
| `android/build.gradle.kts` | 已添加华为 Maven 仓库 |
| `android/app/build.gradle.kts` | 已应用 `com.huawei.agconnect` 插件 |
| `lib/core/services/hms_health_sync_service.dart` | HMS Health Kit 服务类 |
| `lib/core/services/health_data_source.dart` | 自动检测数据源（HMS / Health Connect / Apple Health） |
| `lib/modules/profile/health_sync_page.dart` | 支持所有数据源的同步页 |

### 5. 构建 APK

```bash
cd stride_moor_app
flutter clean
flutter pub get
flutter build apk --debug --target-platform android-arm64
```

> ⚠️ 注意：`agconnect-services.json` 文件需要自行从 AppGallery Connect 下载。
> 如果缺少该文件，HMS 功能将在运行时安全降级（自动回退到普通模式），
> 不会导致构建失败。

## 架构说明

### 数据源自动检测

```
HealthDataSourceManager.detectPlatform()
  ├── iOS → Apple Health (HealthKit)
  ├── Android + HMS Core → HMS Health Kit
  └── Android + Google Services → Health Connect
```

### 数据流程

1. 用户进入「健康数据同步」页面
2. 自动检测设备上的健康平台
3. 请求相应平台的授权（scope/permissions）
4. 读取华为运动健康的跑步活动记录
5. 提取距离、心率、卡路里等数据
6. 用户勾选后导入到 StrideMoor

### 华为数据读取策略

主路径（ActivityRecordsController）：
- 通过 `getActivityRecord()` 读取跑步活动记录
- 获取活动统计信息（距离、配速、心率等）

回退路径（DataController）：
- 如果活动记录读取失败，通过 `read()` 扫描步数数据
- 识别运动时间窗口（连续步数的时段）
- 读取对应时间段的距离、心率详情

## 权限说明

HMS Health Kit 所需权限 scope：
- `HEALTHKIT_ACTIVITY_READ` - 运动数据读取
- `HEALTHKIT_ACTIVITY_RECORD_READ` - 活动记录读取
- `HEALTHKIT_HEARTRATE_READ` - 心率数据读取
- `HEALTHKIT_DISTANCE_READ` - 距离数据读取
- `HEALTHKIT_STEP_READ` - 步数数据读取
- `HEALTHKIT_CALORIES_READ` - 卡路里数据读取
- `HEALTHKIT_SPEED_READ` - 速度数据读取
- `HEALTHKIT_LOCATION_READ` - 位置数据读取

## 排查问题

| 问题 | 可能原因 | 解决 |
|------|---------|------|
| 授权返回 null | 用户取消授权 | 重新请求 |
| PlatformException 2001 | 用户取消授权 | 提示用户重新授权 |
| PlatformException 2010 | 未安装 HMS Core | 从华为应用市场安装 HMS Core |
| PlatformException 2002 | 权限不足 | 检查 agconnect-services.json 配置 |
| NoSuchMethodError | 缺少 agconnect-services.json | 从 AppGallery Connect 下载 |
| 读取不到跑步记录 | 华为健康无跑步数据 | 先用华为健康 App 记录一次跑步 |

## 参考链接

- [华为 Health Kit 官方文档](https://developer.huawei.com/consumer/cn/doc/HMS-Plugin-Guides-V1/overview-0000001073780308-V1)
- [huawei_health Flutter 插件 (pub.dev)](https://pub.dev/packages/huawei_health)
- [HMS Core Flutter 插件 GitHub](https://github.com/HMS-Core/hms-flutter-plugin)
- [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
