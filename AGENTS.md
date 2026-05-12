# AGENTS.md — 驰陌 / StrideMoor 开发助手指南

## 经验教训

### 1. 修改共用页面前，先检查所有入口引用

**场景**：修改 Profile → "挑战记录" 时，直接将 `ChallengeHistoryPage` 从"挑战榜（排名榜）"重写为"个人挑战历史"，结果导致 Discover → "挑战榜" 也被错误覆盖。

**根因**：Discover 页的快捷入口和 Profile 页共用同一个 Widget（`ChallengeHistoryPage`）和同一个路由（`/profile/challenges`）。

**正确做法**：
1. 先用 Grep 全局搜索该 Widget/Router 的所有引用点，确认是否有其他入口也在使用
2. 如果多个入口需要不同的 UI，**新建独立的 Widget 和路由**，而不是直接覆盖共用组件
3. 修改后再验证所有相关入口的行为

**本次修复**：
- 新建 `ChallengeRankingPage`（恢复原来的挑战榜代码）
- 分配独立路由 `/ranking`
- Discover 页跳转到 `/ranking`
- Profile 页继续指向 `/profile/challenges`（个人挑战历史）

---

## 项目惯例

### 代码风格
- Flutter：使用 `flutter_screenutil` 做屏幕适配，所有尺寸用 `.w`、`.h`、`.sp`、`.r`
- Go：使用 GORM + 手写 fromJson 映射 snake_case 字段
- 状态管理：Riverpod（`FutureProvider` + `StateNotifierProvider`）
- 路由：GoRouter

## 快速验证流程

### Flutter 真机调试（无需手动拷贝 APK）

当手机通过无线/有线 adb 连接时，可用一条命令链完成编译 + 安装：

```bash
# 1. 编译 Release APK
flutter build apk --release

# 2. 查看已连接设备（获取 deviceId）
flutter devices

# 3. 指定设备安装（自动卸载旧版 + 安装新版）
flutter install -d "<deviceId>"
```

**实际示例**：
```bash
cd d:\AI\StrideMoor\stride_moor_app
flutter build apk --release
flutter install -d "adb-AYASGL5115000012-5mGgMA._adb-tls-connect._tcp"
```

> 比手动 `adb install` 更省事：`flutter install` 会自动处理卸载旧版本、权限弹窗等，且不需要配置 adb 环境变量。

---

### 修改流程 checklist
- [ ] 用 Grep 搜索所有调用/引用点，确认影响范围
- [ ] 修改后运行 `flutter analyze --no-pub` 检查编译
- [ ] 如涉及后端接口，同步更新 `requirements.md` 和 `design.md`
- [ ] 如涉及多入口共用组件，确认每个入口的行为
