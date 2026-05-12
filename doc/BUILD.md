# 驰陌 / StrideMoor — 构建指南

## 环境要求

| 工具 | 版本 |
|------|------|
| Flutter | 3.41.7 (Dart 3.11.5) |
| JDK | 17+ (Android Gradle Plugin 兼容) |
| Android SDK | 34 (compileSdk) |
| Gradle | 8.7 (wrapper 管理) |

## 快速构建

在项目根目录（`D:\AI\StrideMoor\stride_moor_app\`）双击或运行：

```cmd
build_app.bat
```

它会自动完成三步：

```
[1/4] 递增版本号  →  pubspec.yaml versionCode +1
[2/4] 清理缓存     →  flutter clean
[3/4] 构建 APK     →  flutter build apk --release
[4/4] ✅ 构建完成  →  输出 APK 路径
```

产物位置：`build\app\outputs\flutter-apk\app-release.apk`

## 版本号规则

```
version: 2.0.0+2003
         ──┬──  ─┬─
           │     └── versionCode（Android 判断版本高低，必须递增）
           └──────── versionName（展示用）
```

- **versionCode**（`+` 后面的数字）：**每次构建自动 +1**，永远比上次大
- **versionName**：手动升级，对应功能迭代里程碑

## 手动构建

如果不想用脚本，逐条执行：

```cmd
cd D:\AI\StrideMoor\stride_moor_app
pwsh -NoProfile -File scripts\bump_version.ps1 build
flutter clean
flutter build apk --release
```

## 版本升级

推送大版本时（如 `2.0.0 → 2.1.0`）：

```cmd
pwsh -NoProfile -File scripts\bump_version.ps1 minor
flutter build apk --release
```

| 参数 | 效果 | 示例 |
|------|------|------|
| `build`（默认） | versionCode +1 | `2.0.0+2003 → 2.0.0+2004` |
| `patch` | patch +1, build 重置 | `2.0.0+2003 → 2.0.1+2004` |
| `minor` | minor +1, patch/build 重置 | `2.0.0+2003 → 2.1.0+2004` |
| `major` | major +1, 其余重置 | `2.0.0+2003 → 3.0.0+2004` |

## 常见问题

### R8 报错 `NoSuchFileException`

```
R8: com.android.tools.r8.ResourceException: ... NoSuchFileException ...
```

原因：构建缓存文件缺失/损坏。

解决：`flutter clean` 后重新构建（`build_app.bat` 默认已带 clean 步骤）。

### 覆盖安装提示"有更高版本"

原因：手机上已安装的 APK 的 versionCode ≥ 当前 APK 的 versionCode。

解决：运行 `pwsh scripts\bump_version.ps1 build` 确保 versionCode 比安装的高。

### 签名相关

当前构建使用 **debug 签名**（Android 默认 debug.keystore），适合开发测试。
正式发布时需替换为 release 签名，配置 `android/app/build.gradle.kts` 的 `signingConfigs`。
