# 驰陌 / StrideMoor — 社交跑步教练 APP 产品技术文档

> 核心理念：**"驰于阡陌，自在奔跑"**
> 以路线为锚点，用数据对比帮助朋友改进跑步技术，有目标地跑步。
> 
> 文档版本：v2.1 | 更新日期：2026-05-11 | 更新内容：v2.2.4 发版 | bugfix: realm_badges/vip_features JSON字符串←→List类型不匹配崩溃（_parseStringList安全解析）；finishRun()发送splits分段数据（修复每公里配速+伴跑对比缺失）；模式图标优化（伴跑双人居中Row、挑战跑奖杯Positioned头顶）；我的热度图标居中修复；骑境字段users表预留；注册邮件逻辑改进

---

## 一、产品定位

**英文 Slogan：** *Stride in Moor, Run at Ease*

| 项目 | 描述 |
|------|------|
| 产品名 | 驰陌 / StrideMoor（暂定） |
| 一句话定位 | 社交跑步教练——分享路线，导入收藏，伴跑进步 |
| 目标用户 | 跑步爱好者（初级~中级），有运动社交需求 |
| 核心差异 | 不做赛事/跑团，以**路线**为锚点建圈子——围绕路线分享、收藏、伴跑形成社交闭环 |

---

## 二、核心功能模块

### 2.1 运动记录（基础层）

实时采集跑步过程中的全部数据，是后续对比和诊断的基础。

#### 🗺 地图与轨迹

| 功能 | 说明 | 技术要点 |
|------|------|---------|
| 实时轨迹绘制 | 跑步中在地图上实时画线 | GPS 定位 + 地图 SDK |
| 轨迹回放 | 跑完后 3D/2D 回放轨迹 | 轨迹数据存储 + 动画渲染 |
| 路线保存 | 将轨迹保存为"路线"（可被他人挑战） | 轨迹简化算法（Douglas-Peucker） |
| **路线分享** | 一键分享路线卡片到微信/QQ/链接，含路线地图+关键数据+难度标签 | 深度链接(Deeplink) + 分享SDK |
| **路线导入** | 从他人分享/社区发现/外部GPX文件导入路线到自己的收藏 | GPX解析 + 轨迹标准化 |
| **路线收藏** | 收藏感兴趣的路线，建立个人跑迹，按距离/难度/位置分类管理 | 收藏夹CRUD + 标签系统 + LBS推荐 |
| 路线导航 | 沿路线跑，语音导航，偏航提醒 | 实时偏航检测 + TTS |

#### 📊 实时数据采集

| 数据 | 采集方式 | 精度要求 |
|------|---------|---------|
| **配速** | GPS 位移 / 时间 | 每秒采样，5秒滑动平均 |
| **步频** | 手机加速度计（计步器）或连接运动手表 | 每步检测，每分钟统计 |
| **步幅** | GPS距离 / 步数（间接计算） | 依赖GPS+步频，需平滑滤波 |
| **心率** | 蓝牙连接运动手表/手环/心率带（实时）；Health Connect / Apple Health / HMS Health Kit 跑后导入 | 每秒或每5秒更新（实时），跑后批量导入（精度取决于设备） |
| **海拔/爬升** | 手机气压计 + GPS高程 | 气压计为主，GPS辅助校准 |
| **卡路里** | 基于体重+配速+心率估算 | 仅供参考 |

#### ⌚ 多设备支持

| 设备类型 | 连接方式 | 可获取数据 |
|---------|---------|-----------|
| Apple Watch | 🔵 HealthKit 同步 / WatchOS 伴生APP（`health: ^13.1.4`） | 心率、步频、步幅、GPS轨迹、卡路里 |
| Garmin | Garmin Connect API（OAuth） | 全量数据 |
| 华为手环/手表 | 🔵 HMS Health Kit（`agconnect-services.json`已配置，`huawei_health: ^6.16.0+300`） | 心率、步频、GPS轨迹、卡路里 |
| 小米手环 | Zepp Life / 小米运动 API | 心率、步频 |
| 心率带（Polar/H10等） | BLE 蓝牙直连 | 高精度心率 |
| 其他 BLE 设备 | 通用 BLE HRM 协议 | 心率 |
| Android Health Connect | 🔵 Flutter `health` 包。华为健康App支持向Health Connect写数据 | 心率、步频、GPS轨迹、卡路里 |
| **跑后自动导入** | 🔵 `HealthDataSource` 抽象工厂自动检测平台（Apple Health / Health Connect / HMS Health Kit），请求授权后拉取近30天跑步记录，勾选导入后端 | 全量数据（含心率采样） |

---

### 2.2 路线生态（社交层）

核心理念：**分享 → 导入收藏 → 伴跑**，完整闭环

```
跑者A跑完路线 → 保存为路线 → 分享路线卡（含地图/数据/难度）
    ↓
跑者B看到 → 导入收藏到自己跑迹 → 随时可开始伴跑
    ↓
跑者B到起点 → 选择伴跑模式 → 实时影子伴跑 + 语音解说
    ↓
跑者B完成 → 自动生成对比报告 → 诊断建议 → 分享进步
    ↓
跑者B也分享路线 → 更多朋友加入 → 路线热度增长
```

#### 路线分享

| 功能 | 说明 |
|------|------|
| 分享路线卡 | 一键生成精美路线卡片（地图缩略图+距离+爬升+难度标签+创造者信息），分享到微信/QQ/朋友圈 |
| 深度链接 | 点击分享链接直接打开APP进入路线详情页（未安装跳应用商店） |
| 分享到社区 | 路线发布到驰陌 / StrideMoor社区，按城市/距离/难度浏览 |
| GPX导出 | 导出路线GPX文件，方便在Garmin等设备上使用 |
| GPX导入 | 从外部导入GPX文件（从其他APP/手表导出的路线），自动识别并标准化 |

#### 路线收藏与管理

| 功能 | 说明 |
|------|------|
| 收藏路线 | 一键收藏感兴趣的路线到个人跑迹 |
| 跑迹 | 个人收藏的所有路线，按列表/地图模式查看 |
| 智能分类 | 按距离（3km/5km/10km/半马/全马）、难度（轻松/中等/挑战）、位置（附近/收藏城市）自动标签 |
| 路线热度 | 每条路线显示被伴跑次数、评分、难度评级 |
| 距离排序 | 按离当前位置距离排序，优先推荐附近的收藏路线 |
| 待跑清单 | 标记"想去跑"，建立跑步愿望清单 |

#### 路线发现

| 功能 | 说明 |
|------|------|
| 附近热门 | 基于LBS推荐附近跑者常跑的路线 |
| 好友路线 | 好友最近跑过的路线，一键导入收藏 |
| 路线挑战榜 | 同一路线的伴跑成绩排行榜（不是竞速，是进步排行） |
| 难度推荐 | 根据你的历史数据推荐适合难度的路线 |

#### 路线排行榜

| 功能 | 说明 |
|------|------|
| **打卡榜** | 按用户在该路线的跑步次数（`run_count DESC`）排名，展示活跃度 |
| **成绩榜** | 按用户在该路线的最佳总用时（`total_time ASC`，保留历史PB而非最新成绩）排名 |
| **数据规则** | 成绩榜每人保留该路线的最好成绩（最小 `total_time`）；每次完成跑步时自动触发 Upsert，仅当新成绩优于历史最佳时才更新 |
| 一键挑战 | 从排行榜选择任意跑者，点击"向他挑战"，选择挑战目标维度后生成伴跑邀请 |
| **挑战目标** | 不止竞速，可选择：总用时/平均心率/平均步频/平均步幅等维度，达到对手水平即算成功 |

#### 👻 伴跑模式（核心体验）

用户从收藏跑迹选择一条路线，点击"开始伴跑"，即可体验与原跑者的影子对决。

**影子伴跑（跑伴 Run）**

地图上显示原跑者的"跑伴"标记，实时同步移动。当用户跑过某个位置时，跑伴也显示在该位置原跑者当时的状态，形成直观的视觉对比。

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| **真实回放** | 跑伴严格按原跑者的实际配速推进，全程体验原跑者的节奏变化 | 体验朋友的真实跑法，学习节奏控制 |
| **目标挑战** | 选择挑战维度（配速/心率/步频/步幅），跑伴按该维度的对手水平推进，达标即成功 | 不比速度比技术，不同水平也能公平挑战 |
| **匀速目标** | 跑伴以原跑者的平均配速匀速前进 | 作为稳定目标，训练节奏一致性 |
| **兔子模式** | 跑伴比原跑者快5%，始终在前方引导 | 冲击更好成绩，有目标感 |
| **龟兔模式** | 跑伴前半程比原跑者快，后半程比原跑者慢（负分段） | 练习负分段策略，前慢后快 |

**多人影子**

支持同时显示多个跑伴（多位朋友的同路线数据），每个人用不同颜色区分。可以和跑得最快的朋友比，也可以和水平接近的朋友比。

#### 🔊 语音播报系统（核心体验）

**实现状态：✅ 已实现**（基于 flutter_tts + TTS 中文语音引擎）

**三种播报模式**

| 模式 | 场景 | 播报内容 |
|------|------|----------|
| **独自跑** | 跑自己的路线，无对手 | 自身数据播报（配速/心率/步频/距离/用时） |
| **伴跑** | 跑他人路线，影子跟随 | 自身数据 + 与跑伴的对比数据（待接入） |
| **挑战跑** | 向排行榜对手发起挑战 | 自身数据 + 实时达标/未达标提醒（待接入） |

**播报频率（可自定义）**

| 选项 | 类型 | 间隔 |
|------|------|------|
| 每 200 米 | 距离触发 | 每200米播报一次 |
| 每 500 米 | 距离触发 | 每500米播报一次 |
| 每 1 公里 | 距离触发 | 每1公里播报一次（默认） |
| 每 5 分钟 | 时间触发 | 每5分钟播报一次 |
| 每 10 分钟 | 时间触发 | 每10分钟播报一次 |
| 仅异常 | 异常触发 | 仅在配速/心率偏离目标时播报 |

**播报内容（可多选勾选，默认全部勾选）**

- 距离："已跑x公里"
- 配速："当前配速x分x秒"
- 用时："用时x分x秒"
- 心率："心率x"（有设备时）
- 步频："步频x"
- 步幅："步幅x厘米"
- 卡路里："消耗x千卡"

**语音风格（4种，已实现）**

| 风格 | 语气 | 示例 |
|------|------|------|
| 标准 🎤 | 中性播报 | "已跑1公里，用时5分30秒，当前配速5'30"" |
| 江湖 🥋 | 武侠风 | "道友！已行二里，配速五分三十，步频稳健！" |
| 教练 📣 | 激励/指导 | "加油！已跑1公里，配速5'30"，保持节奏" |
| 毒舌 😏 | 调侃鞭策 | "才1公里，配速5'30"？隔壁大妈走得比你快" |

**目标达成播报**

跑步目标（距离/时长/卡路里）达成时自动触发一次语音祝贺，不同风格有不同祝贺词。

**实现方式**

- 技术：`flutter_tts ^4.2.5`，中文语音引擎
- 触发机制：`RunSessionNotifier` 状态监听 → `VoiceBroadcastService.onStateUpdate()` 检测频率阈值 → TTS 播报
- 频率检测：距离模式下按 `floor(distance / interval)` 变化触发，时间模式下按 `floor(duration / interval)` 变化触发
- 异常模式：不主动触发，仅在目标偏离时播报（预留）

---

### 2.3 技术诊断（价值层）

跑完后自动生成的诊断报告，帮助用户找到提升空间。

#### 分段配速分析

| 分析项 | 说明 |
|--------|------|
| 每公里配速 | 显示每公里的配速，标记最快/最慢段 |
| 配速稳定性 | 标准差计算，判断节奏控制水平 |
| 负分段检测 | 后半程是否比前半程快（理想状态） |
| 掉速预警 | 某段配速比平均慢10%以上，标记为"注意段" |

#### 对比诊断

| 对比维度 | 诊断内容 |
|----------|----------|
| **vs 自己历史** | 同路线多次跑的进步曲线，标记PB |
| **vs 跑伴** | 每公里配速对比图，找出差距大的段落 |
| **vs 平均水平** | 同距离/难度的用户平均数据对比 |

#### 智能建议

基于对比数据生成具体建议：

```
示例诊断：
"你的前3公里配速很稳，但第4公里明显掉速（慢了23秒）。
 建议：第4公里有个小上坡，下次提前100米稍微放慢节奏储备体力。
 你的心率控制很好，全程在燃脂区间，可以尝试稍微提速到有氧区间。"
```

---

## 三、产品形态

### 3.1 功能架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      用户界面层                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  发现页   │  │  运动页   │  │  跑迹页   │  │  我的页   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      核心业务层                              │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐           │
│  │运动记录 │  │路线生态 │  │影子伴跑 │  │技术诊断 │           │
│  │• GPS   │  │• 分享   │  │• 回放  │  │• 分段  │           │
│  │• 传感器│  │• 导入   │  │• 对比  │  │• 对比  │           │
│  │• 设备  │  │• 收藏   │  │• 语音  │  │• 建议  │           │
│  └────────┘  └────────┘  └────────┘  └────────┘           │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      数据服务层                              │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐           │
│  │用户数据 │  │路线数据 │  │跑步数据 │  │社交数据 │           │
│  └────────┘  └────────┘  └────────┘  └────────┘           │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 核心场景用户旅程

#### 场景一：发现路线 → 收藏 → 伴跑（核心闭环）

```
[跑者B打开APP]
  ↓
发现页 → 看到跑者A分享的路线卡片
  ↓
点击路线 → 查看详情（地图/数据/难度/评论）
  ↓
"收藏到我的跑迹" → 选择分类标签
  ↓
[下次跑步时]
  ↓
运动页 → 选择"伴跑模式" → 从跑迹选这条路线
  ↓
选择"真实回放" → 搜星 → 开始跑步
  ↓
跑步中：地图显示跑伴A的位置，语音播报对比数据
  ↓
结束 → 自动生成对比报告
  ↓
查看诊断建议 → 分享到社区/保存进步记录
```

#### 场景二：跑完自己的路线 → 保存 → 分享

```
[跑者A跑完5公里]
  ↓
结束页 → 数据总览 → "保存为路线"
  ↓
编辑路线信息（名称/难度/描述/标签）
  ↓
生成分享卡片 → 分享到微信/社区
  ↓
[其他跑者看到] → 导入收藏 → 场景一
```

#### 场景三：挑战排行榜对手

```
[跑者C在跑迹详情页]
  ↓
查看排行榜 → 看到跑者A的成绩
  ↓
点击"向他挑战" → 选择挑战维度（如"平均步频"）
  ↓
系统生成伴跑邀请 → 跑者C开始跑步
  ↓
跑步中：语音实时播报"你的步频比A高2步，达标！"
  ↓
结束 → 显示挑战结果（达标/未达标）+ 对比报告
  ↓
自动发布挑战结果到跑友动态
```

### 3.3 信息流设计

### 3.4 发现页每日金句（v1.5 重构）

**定位**: 首页跑境区+金句区，让用户每天看到一句有共鸣的话。

**按境界分层**:

| 境界段位 | 境界索引 | 金句风格 | 贴士风格 |
|:---------|:--------|:---------|:---------|
| 🟢 新手 | realm 0-2（气筑丹） | "跑两公里也是英雄" 型 | 励志起步型 |
| 🟦 进阶 | realm 3-5（婴化虚） | "真正的对手是昨天的自己" 型 | 半马/步频/积累型 |
| 🟧 高手 | realm 6-8（合乘真） | "配速是数字，心境才是境界" 型 | 全马/配速/PB型 |
| 🔥 巅峰 | realm 9-12（金太罗道） | "十三境之上，仍有星辰大海" 型 | 修行/自由/超越型 |

**算法逻辑**:
1. 每层 10 条金句 / 10 条贴士
2. 按当天日期偏移取 4 条候选池（金句: `day * 3 % (len-4)`，贴士: `day * 7 % (len-4)`）
3. `Random().nextInt(4)` 随机取 1 条展示
4. 每次页面加载（`setState`）重新随机

**互动**:
- 跑境卡片 → 点击进入跑境详情页
- 金句区 → 点击刷新换一句

---

#### 跑友动态（社区信息流）

**内容类型：**

| 类型 | 展示内容 | 互动 |
|------|----------|------|
| 跑步成绩 | 地图缩略图 + 距离/配速/用时 | 点赞、评论 |
| 路线分享 | 路线卡片 + 创造者信息 | 收藏、挑战 |
| 挑战结果 | 挑战双方对比 + 达标状态 | 点赞、评论、发起反向挑战 |
| 个人感悟 | 文字/图片 + 跑步标签 | 点赞、评论 |
| 进步记录 | 同路线多次对比 + 进步幅度 | 点赞、鼓励 |

**排序策略：**

1. 时间倒序（最新优先）
2. 热度加权（点赞/评论/收藏多的优先）
3. 关系加权（好友的内容优先）

---

## 四、MVP 范围

### 第一期（MVP，3个月）

只做核心闭环，验证"分享→收藏→伴跑"的价值。

| 模块 | 功能 | 优先级 |
|------|------|-------|
| 运动记录 | GPS轨迹、配速、步频、步幅 | P0 |
| 运动记录 | 心率（Apple Watch / Health Connect / HMS Health Kit / BLE心率带） | P0 |
| 运动记录 | 跑步中实时地图显示 | P0 |
| 路线分享 | 保存路线、生成分享卡片 | P0 |
| 路线导入 | 从分享链接/GPX导入路线 | P0 |
| 路线收藏 | 收藏路线、跑迹管理 | P0 |
| **伴跑** | 影子伴跑（真实回放+匀速目标模式） | P0 |
| **伴跑** | ✅ 语音播报系统（频率/内容/风格 TTS） | P0 |
| **伴跑** | 跑完后多维对比报告 | P0 |
| 技术诊断 | 分段配速对比 + 基础诊断建议 | P1 |
| 暗色主题 | 亮色模式已可用；暗色主题结构已预留（darkTheme），待精细调优后开放系统跟随切换 | P0 |
| 国际化(i18n) | 字符串资源化（l10n）+ 中英双语，P0 一步到位结构 | P0 |
| 社交 | 好友系统、挑战通知 | P1 |
| 进步追踪 | 同路线多次成绩对比 | P2 |

### 第二期（6个月）

| 模块 | 功能 |
|------|------|
| 伴跑增强 | 兔子模式、龟兔模式、多人影子 |
| 设备扩展 | Garmin、小米手环数据同步（Health Connect / HMS Health Kit 一期已接入） |
| AI教练 | 基于历史数据生成训练计划 |
| 社交增强 | 挑战赛、接力赛、路线排行榜 |
| 分享增强 | 轨迹海报、PK视频自动生成 |
| 路线发现 | 附近热门路线、好友路线推荐 |
| 训练计划 | 基于路线数据的阶段训练 + 周期计划 |

---

## 五、技术风险与难点

| 难点 | 风险等级 | 应对策略 |
|------|---------|---------|
| GPS精度/漂移 | 🔴高 | Kalman滤波 + 地图匹配 + 静态点过滤 |
| 室内/隧道GPS丢失 | 🟡中 | 加速度计推算补位，标注"估算段" |
| 步幅计算不准 | 🟡中 | 多源融合（GPS+加速度计），平滑滤波 |
| 路线匹配算法 | 🔴高 | 先用起终点+距离粗筛（50m 偏航容差），再用 DTW 精匹配 |
| BLE心率连接稳定性 | 🟡中 | 重连机制 + 缓存最近心率 + 断连提示 |
| 电池续航 | 🔴高 | GPS高精度模式耗电大，需优化采样策略 |
| 影子同步精度 | 🔴高 | 路线距离插值+GPS位置匹配，而非时间线对齐 |
| 实时语音播报延迟 | 🟡中 | 预加载语音包，TTS本地化 |
| 自定义语音包 | 🟡中 | 涉及音频存储、TTS替换、内容审核，MVP阶段仅做预设风格包，自定义录制列为二期 |

---

## 六、竞品对比

| 特性 | 华为运动健康 | 第一赛道 | Keep | 悦跑圈 | NRC | Strava | RQrun | **驰陌 / StrideMoor** |
|------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| GPS轨迹 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 步频/步幅 | ✅ | ⚠️ | ❌ | ⚠️ | ✅ | ✅ | ⚠️ | ✅ |
| 路线分享 | ❌ | ✅ | ❌ | ⚠️ | ❌ | ✅ | ❌ | **✅核心** |
| 路线导入收藏 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | **✅核心** |
| **影子伴跑** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **✅核心** |
| **实时语音对比** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **✅核心** |
| **技术诊断** | ⚠️AI教练 | ❌ | ❌ | ❌ | ⚠️指导 | ❌ | ❌ | **✅核心** |
| 语音指导跑步 | ✅ | ❌ | ✅课程 | ❌ | **✅最强** | ❌ | ❌ | ✅ |
| 社交社区 | 弱 | 中 | 强 | 强 | 弱 | 强 | 弱 | 强 |
| 赛事服务 | ❌ | ✅ | ❌ | ✅ | ⚠️ | ❌ | ❌ | ❌不做 |
| 设备生态 | 华为 | 通用 | 多设备 | 通用 | Apple | 通用 | Apple | 多设备 |

**核心差异**：现有产品要么重赛事（第一赛道），要么重社区（Keep/悦跑圈），要么重设备（华为）。没有人围绕"路线"做社交闭环。驰陌 / StrideMoor不做赛事、不做跑团，专注**路线**——围绕路线分享、收藏、伴跑，让路线本身成为社交纽带。

**重点参考**：
- **第一赛道**：路线分享+排行榜的思路值得借鉴，但我们不走赛事服务路线
- **华为运动健康**：设备生态、数据可视化、简洁体验值得参考

---

## 七、商业模式

| 阶段 | 模式 | 说明 |
|------|------|------|
| 早期 | 免费 | 积累用户，打磨体验 |
| 成长期 | 会员订阅 | 高级诊断、AI训练计划、无限挑战 |
| 成熟期 | 装备电商 | 跑鞋/手表推荐（基于步态数据） |
| 成熟期 | 赛事合作 | 马拉松官方合作，成绩同步 |

---

## 八、前端架构（Flutter）

### 8.1 技术选型

| 项目 | 方案 | 版本/说明 |
|------|------|----------|
| 框架 | Flutter | 3.41.7 stable, Dart 3.11.5 |
| 状态管理 | Riverpod + flutter_riverpod | ^2.4.9 |
| 路由 | go_router | ^13.0.1 |
| 本地存储 | Hive（配置/缓存） | ^2.2.3 |
| 国际化 | flutter_localizations + intl | 强制 `Locale('zh')`，ARB 覆盖 50+ 文案键 |
| 地图 | 高德地图 Flutter SDK（`gmm_amap_flutter_map` 社区版） | ^3.1.4，Android Key: `f50e31d4bd4b6cb53cbf2a019d9be9ba` |
| BLE | flutter_blue_plus | — |
| 传感器 | sensors_plus + pedometer | — |
| 音频 | flutter_tts | ^4.2.5，TTS 语音播报已实现（中文语音引擎） |
| 网络 | dio | ^5.4.0 |
| 推送 | firebase_messaging + 极光推送 | 极光待升级兼容 AGP 8.x |

**主题策略**：
- 当前强制亮色模式（`ThemeMode.light`）
- 暗色主题（`darkTheme`）已定义但尚未精细调优，待完善后开放系统跟随切换
- 原因：暗色模式下部分文字对比度不足，先保证可读性

### 8.2 四大模块总览

```
底部 Tab 导航（已实現）：
┌─────────┬─────────┬──────────┬─────────┐
│  🏠发现  │  🏃运动  │  📁跑迹  │  👤我的  │
└─────────┴─────────┴──────────┴─────────┘
              ↑
         底部凹陷 FAB（悬浮按钮）
```

### 8.3 模块一：发现（首页）

**定位**：内容入口+个人记录，让用户看到动态、找到跑迹、被激发去跑。

| 页面 | 功能点 | 实现状态 |
|------|--------|---------|
| **首页 Feed** | 跑友动态流 / 推荐挑战 / 官方活动 | UI 骨架完成 |
| **运动记录** | 个人所有跑步记录列表，按时间倒序；显示距离/配速/用时；点击进入跑步详情 | UI 完成，API 待对接 |
| **跑步详情** | 单次跑步的完整数据：轨迹地图 + 分段配速 + 心率曲线 + 步频/步幅 + 爬升；如有伴跑则展示对比；支持"收藏我的跑迹"（从跑步记录生成路线）和"发跑友动态"（关联本次跑步） | UI 完成 |
| **跑迹广场** | 浏览所有跑迹，查看我参与过的跑迹；每条跑迹显示双Tab排行榜（打卡榜按次数/成绩榜按最佳用时），可选择跑伴发起挑战 | UI 完成 |
| **跑迹详情** | 跑迹地图 + 数据（距离/爬升/难度/评分）+ 双Tab排行榜（打卡榜/成绩榜）+ 5星评分（1.0-5.0，0.5步进）+ 参与人数 + 一键挑战 | UI 完成 |
| **跑友动态** | 所有跑友可发动态（无需关注/加好友）；跑步成绩、跑迹分享、挑战结果、个人感悟；点赞/评论 | UI 骨架完成 |
| **跑迹搜索** | 按城市/距离/难度/关键词搜索跑迹 | P1，UI 骨架 |
| **附近跑迹地图** | 地图模式查看周边所有跑迹，点击查看详情 | P1，UI 骨架 |

**发现页快捷入口（3个卡片式按钮）**：
1. **运动记录**（蓝色）→ 跑步历史
2. **跑迹广场**（绿色）→ 路线社区
3. **挑战榜**（橙色）→ 挑战排名榜

### 8.4 模块二：运动（核心体验）

**定位**：运动全流程——从准备到结束，三种模式统一入口。

| 页面 | 功能点 | 实现状态 |
|------|--------|---------|
| **跑步准备页** | 选择模式（独自跑/伴跑/挑战跑）→ 选择路线（伴跑/挑战跑从"跑友跑迹"选）→ 配置语音播报（频率/内容/风格）→ 连接设备 | ✅ UI 完成，含播报设置面板 |
| **GPS搜星页** | 实时显示GPS精度，信号稳定后显示"可以开始" | UI 骨架完成 |
| **跑步中主界面** | 实时地图（含跑伴标记）+ 核心数据面板（配速/距离/用时/心率）+ 底部播报快捷设置；**倒计时动画**：GPS就绪后屏幕中央3→2→1数字由大变小(2.0→0.6)缩放淡出，随后显示蓝色发光"开始运动！"，完毕后自动锁屏 | ✅ UI 完成 |
| **跑步中锁屏** | 常亮显示核心数据（距离/用时），全屏`GestureDetector(onTap+onLongPress)`吸收所有触摸事件，防止底下暂停/结束按钮被误触；**长按任意位置解锁**（非旧版上滑），口袋摩擦不会触发 | ✅ UI 完成 |
| **分段播报浮窗** | 播报时顶部弹出卡片，显示当前段数据+对比数据，3秒后自动收起 | P1 |
| **暂停/继续** | 暂停后显示本次已跑数据摘要 | UI 完成 |
| **跑步结束页** | 完成动效 + 本次数据总览（用时/配速/心率/步频/步幅/卡路里/爬升）→ 保存为路线 → 分享 | UI 完成 |

**独自跑流程**：
```
准备页 → 选路线(可选) → 搜星 → 开始 → 跑步中(语音播报个人数据) → 结束
```

**伴跑流程**：
```
准备页 → 从"跑友跑迹"选路线 → 选伴跑模式(真实回放/匀速/兔子/龟兔) → 搜星 → 开始
→ 跑步中(地图跑伴+语音对比) → 结束 → 对比报告
```

**挑战跑流程**：
```
[入口A] 准备页 → 从"跑友跑迹"选择路线 → 选挑战维度(配速/心率/步频/步幅) → 搜星 → 开始
[入口B] 跑迹详情页排行榜 → 点击"向他挑战" → 自动带入路线+对手信息 → 跳转准备页
→ 跑步中(跑伴+达标提醒) → 结束 → 挑战结果(达标/未达标) + 对比报告
```

### 8.5 模块三：跑迹

**定位**：跑迹管理中心，四个 Tab 作为核心入口。

| 页面 | 功能点 | 实现状态 |
|------|--------|---------|
| **跑迹首页** | 四个 Tab：我的跑迹 / 跑友跑迹 / 上传管理 / 我的热度 | ✅ UI 完成 |
| **我的跑迹** | 列表展示个人上传的跑迹，每张卡片含 AMap 迷你轨迹地图 + 数据（距离/配速/步频/爬升）；点击弹出 BottomSheet 详情 | ✅ UI 完成 |
| **跑友跑迹** | 展示收藏的跑友路线，卡片布局与我的跑迹一致 | ✅ UI 完成 |
| **上传管理** | 上传跑迹记录列表，按状态（已通过/审核中/已拒绝）分类，带状态标签 | ✅ UI 完成 |
| **我的热度** | 数据看板：被收藏次数（总计）、伴跑次数、被关注次数、被挑战次数（胜/负），列表形式展示 | ✅ UI 完成 |
| **跑迹详情页** | 跑迹地图（AMap）+ 数据总览 + 跑步历史 + 排行榜 + 操作 | ✅ UI 完成 |
| **附近推荐** | 基于LBS展示周边热门跑迹（跑的人多/被收藏多），地图/列表切换 | P1 |
| **上传跑迹** | 从历史运动记录中选择，一键上传生成跑迹 | P1 |
| **对比报告页** | 伴跑/挑战跑结束后自动生成；展示多维对比看板 + 智能诊断建议 + 下次目标 | UI 骨架完成 |

### 8.6 模块四：我的

**定位**：个人中心、设置、数据统计。

| 页面 | 功能点 | 实现状态 |
|------|--------|---------|
| **个人主页** | 头像/昵称/跑步数据总览（总里程/总次数/总时长）+ 成就徽章；头像裁剪：InteractiveViewer缩放拖动→圆形裁剪框→Canvas.drawImageRect输出512x512 PNG；上传后本地缓存优先显示，服务器同步做后台备份 | UI 完成，裁剪+缓存逻辑已实现 |
| **挑战记录** | 个人挑战历史统计（总次数/胜利/失败）+ 已完成挑战明细列表（路线/对手/结果/时间）| UI 完成 |
| **跑步统计** | 周/月/年汇总：跑量、次数、平均配速、PB（个人最佳） | P1 |
| **播报设置** | 默认播报频率 / 默认播报内容 / 语音风格切换 / 音量；跑步准备页快捷面板 + 独立设置页（三行布局：播放频率→播报参数→语音风格，含描述文字） | P0，UI 完成 |
| **设备管理** | ✅ 已连接设备列表（图标/类型/电量/连接状态）/ BLE扫描 / 手动绑定（选择设备类型+同步方式）/ 解绑确认 / 健康平台同步入口 / 导入历史 | P0，UI完成 |
| **关注跑友** | 已关注的跑友列表 / 最近动态 / 关注/取关 / 点击查看跑友详情（跑境/里程/次数/时长/卡路里） | P1，UI 完成 |
| **健康数据同步** | ✅ 自动检测健康平台（Apple Health / Health Connect / HMS Health Kit）→ 请求权限 → 读取30天内运动记录 → 勾选导入后端 `POST /api/v1/runs/import`。显示距离/时间/配速/心率/卡路里，华为记录标记
| **帮助菜单** | 伴跑规则 / 跑境规则（13境递进表含配速要求）/ 挑战跑规则（7项规则）/ 关于（版本/协议/反馈） | P0，UI 完成 |
| **通知设置** | P2，未实现，暂不显示 | P2 |
| **账号设置** | P2，未实现，暂不显示 | P2 |

### 8.7 页面清单汇总

| # | 页面 | 模块 | 优先级 | 实现状态 |
|---|------|------|--------|---------|
| 1 | 登录/注册页 | 账号 | P0 | ✅ UI 完成 |
| 2 | 首页 Feed | 发现 | P0 | ✅ UI 骨架 |
| 3 | 运动记录 | 发现 | P0 | ✅ UI 完成 |
| 4 | 跑步详情 | 发现 | P0 | ✅ UI 完成 |
| 5 | 跑迹广场 | 发现 | P0 | ✅ UI 完成 |
| 6 | 跑迹详情 | 发现 | P0 | ✅ UI 完成 |
| 7 | 跑步准备页 | 运动 | P0 | ✅ UI 骨架 |
| 8 | GPS搜星页 | 运动 | P0 | ✅ UI 骨架 |
| 9 | 跑步中主界面 | 运动 | P0 | ✅ UI 完成（含倒计时动画+自动锁屏） |
| 10 | 跑步中锁屏 | 运动 | P0 | ✅ UI 完成（长按解锁+全屏触摸拦截） |
| 11 | 跑步结束页 | 运动 | P0 | ✅ UI 完成 |
| 12 | 跑迹首页（4 Tab：我的跑迹/跑友跑迹/上传管理/我的热度） | 跑迹 | P0 | ✅ UI 完成 |
| 13 | 跑迹详情页 | 跑迹 | P0 | ✅ UI 完成 |
| 14 | 播报设置（已合并到跑步准备页，播报设置页保留为默认值配置入口） | 我的/运动 | P0 | ✅ UI 完成（准备页面板 + 独立设置页） |
| 15 | 跑友动态 | 发现 | P1 | ✅ UI 骨架 |
| 16 | 跑迹搜索 | 发现 | P1 | 🔄 UI 骨架 |
| 17 | 附近跑迹地图 | 发现 | P1 | 🔄 UI 骨架 |
| 18 | 分段播报浮窗 | 运动 | P1 | 🔄 未开始 |
| 19 | 我的跑迹 | 跑迹 | P1 | ✅ UI 完成 |
| 20 | 附近推荐 | 跑迹 | P1 | 🔄 UI 骨架 |
| 21 | 上传跑迹 | 跑迹 | P1 | 🔄 未开始 |
| 22 | 对比报告页 | 跑迹 | P1 | ✅ UI 骨架 |
| 23 | 个人主页 | 我的 | P1 | ✅ UI 完成 |
| 24 | 挑战记录 | 我的 | P1 | ✅ UI 完成 |
| 25 | 跑步统计 | 我的 | P1 | 🔄 未开始 |
| 26 | 设备管理 | 我的 | P0 | ✅ UI 完成 |
| 27 | 健康数据同步 | 我的 | P0 | ✅ UI 完成 |
| 28 | 导入历史 | 我的 | P0 | ✅ UI 完成 |
| 29 | 关注跑友 | 我的 | P1 | ✅ UI 完成（含跑友详情页friend_detail_page.dart） |
| 30 | 跑境规则页 | 我的 | P0 | ✅ 新增（13境递进表含配速要求） |
| 31 | 挑战跑规则页 | 我的 | P0 | ✅ 新增（7项规则说明） |
| 32 | 伴跑规则页 | 我的 | P0 | ✅ 已有 |
| 33 | **头像裁剪页** | 我的 | P0 | ✅ 新增（InteractiveViewer+圆形裁剪框+缩放拖动+本地缓存） |
| 34 | **QR扫描页** | 发现 | P0 | ✅ 新增（独立页面，替换原ModalBottomSheet） |
| 35 | 通知设置 | 我的 | P2 | 🔄 未开始（已移除占位） |
| 36 | 账号设置 | 我的 | P2 | 🔄 未开始（已移除占位） |

**MVP一期（P0）**：17个核心页面（登录/发现页/运动记录/跑步详情/跑迹广场/跑迹详情/跑步准备页/GPS搜星/跑步中主界面/锁屏/跑步结束/跑迹首页/跑迹详情/播报设置/设备管理/健康数据同步/导入历史），覆盖 登录→发现→运动→跑迹→设备→健康同步 完整闭环。当前 UI 骨架已全部完成，大部分页面 UI 细节较完善。


---

## 九、后端架构（Go）

### 9.1 技术选型

| 层级 | 技术方案 | 版本 | 说明 |
|------|---------|------|------|
| 语言 | Go | 1.22 | 模块名 `stridemoor-api` |
| Web 框架 | Gin | v1.9.1 | HTTP 路由 + 中间件 |
| ORM | GORM + MySQL driver | v1.25.12 | `gorm.io/gorm` + `gorm.io/driver/mysql` |
| 数据库 | MySQL 8.0 | 8.0 | 业务数据 + 时序分区表 |
| 缓存 | Redis 7 | 7-alpine | 会话、热数据缓存 |
| 对象存储 | MinIO（自建） | — | 开发阶段用本地文件系统占位 |
| 配置 | YAML | — | `configs/config.yaml` |
| JWT | golang-jwt/jwt/v5 | — | Access Token + Refresh Token 双令牌 |
| 密码哈希 | bcrypt | — | `golang.org/x/crypto/bcrypt` |
| UUID | google/uuid | — | 实体主键 |

### 9.2 项目目录结构

```
backend/
├── cmd/server/              # 服务入口
│   └── main.go              # 加载配置、初始化依赖、注册路由、启动 HTTP
├── configs/
│   └── config.yaml          # 服务端口号、数据库DSN、JWT密钥、MinIO配置
├── internal/
│   ├── handler/             # HTTP Handler（Controller）
│   │   ├── user.go          # 用户注册/登录/Profile
│   │   ├── run.go           # 跑步开始/采样上传/结束/列表/详情
│   │   ├── route.go         # 路线 CRUD + 收藏 + 排行榜(双Tab) + 评分 + 附近搜索
│   │   ├── friendship.go    # 好友申请/列表/接受/拒绝/删除
│   │   ├── challenge.go     # 挑战/伴跑PK：发起/列表/详情/接受/开始/完成/取消/对比报告
│   │   └── upload.go        # 头像/GPX 文件上传
│   ├── service/             # 业务逻辑层
│   │   ├── user.go
│   │   ├── run.go
│   │   ├── route.go
│   │   ├── friendship.go
│   │   ├── challenge.go
│   │   └── upload.go
│   ├── repository/          # 数据访问层
│   │   ├── user.go
│   │   ├── run.go
│   │   ├── route.go
│   │   ├── friendship.go
│   │   ├── challenge.go
│   │   └── leaderboard.go   # 路线排行榜自动计算
│   ├── model/               # 数据库模型（GORM struct）
│   │   ├── user.go
│   │   ├── run.go
│   │   ├── route.go
│   │   ├── friendship.go
│   │   ├── challenge.go
│   │   └── upload.go
│   ├── dto/                 # 请求/响应 DTO
│   │   ├── user.go
│   │   ├── run.go
│   │   ├── route.go
│   │   ├── friendship.go
│   │   └── challenge.go
│   ├── router/              # 路由注册
│   │   └── router.go        # Gin 路由配置 + 中间件
│   └── middleware/          # 通用中间件
│       ├── jwt.go           # JWT 认证
│       ├── cors.go          # 跨域
│       ├── logger.go        # 请求日志
│       └── recovery.go      # Panic 恢复
├── pkg/
│   ├── database/
│   │   ├── database.go      # GORM MySQL 初始化
│   │   └── minio.go         # MinIO 客户端（开发阶段本地文件占位）
│   ├── jwt/
│   │   └── jwt.go           # JWT 生成与验证
│   └── response/
│       └── response.go      # 统一响应封装
├── uploads/                 # 开发阶段本地文件存储
│   ├── avatars/             # 头像上传目录
│   └── gpx/                 # GPX 文件上传目录
└── go.mod                   # Go 模块定义
```

### 9.3 分层架构

```
HTTP Request
    ↓
┌─────────────┐
│   Router    │  → 路由分发、中间件（JWT/CORS/日志/恢复）
└──────┬──────┘
       ↓
┌─────────────┐
│   Handler   │  → 参数校验、调用 Service、返回 response
└──────┬──────┘
       ↓
┌─────────────┐
│   Service   │  → 业务逻辑、事务控制、DTO ↔ Model 转换
└──────┬──────┘
       ↓
┌─────────────┐
│ Repository  │  → 数据库操作（GORM）
└──────┬──────┘
       ↓
┌─────────────┐
│    Model    │  → GORM 结构体定义
└─────────────┘
```

### 9.4 中间件

| 中间件 | 说明 | 应用范围 |
|--------|------|---------|
| JWTAuth | 从 `Authorization: Bearer <token>` 解析用户ID，注入 `gin.Context` | 所有 `/api/v1/*` 非公开路由 |
| CORS | 允许跨域请求 | 全局 |
| Logger | 请求耗时、状态码、路径记录 | 全局 |
| Recovery | Panic 捕获，返回 500 统一错误 | 全局 |

### 9.5 配置文件 (`configs/config.yaml`)

```yaml
server:
  port: "8080"

database:
  driver: "mysql"
  host: "localhost"
  port: 3308
  username: "stridemoor"
  password: "stridemoor_pass_2026"
  database: "stridemoor"
  charset: "utf8mb4"
  parse_time: true
  loc: "Local"

jwt:
  secret: "stridemoor_jwt_secret_key_2026"
  access_expire_hours: 24
  refresh_expire_days: 7

minio:
  endpoint: "localhost:9002"
  access_key: "minioadmin"
  secret_key: "minioadmin"
  bucket: "stridemoor"
  use_ssl: false
  # 开发阶段：use_local_storage = true 时走本地文件系统
```

---

## 十、数据库设计

### 10.1 ER 关系图

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│    users    │       │    runs     │       │   routes    │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id (PK)     │◄──────┤ user_id(FK) │       │ id (PK)     │
│ phone       │       │ route_id(FK)├──────►│ user_id(FK) │
│ nickname    │       │ ...         │       │ ...         │
│ avatar      │       └─────────────┘       └─────────────┘
│ ...         │              │                    ▲
└─────────────┘              │                    │
       ▲                     │              ┌────┴─────────┐
       │                     │              │ route_favs   │
       │              ┌──────┴─────────┐    ├──────────────┤
       │              │  run_samples   │    │ user_id(FK)  │
       │              │ (按月RANGE分区) │    │ route_id(FK) │
       │              ├────────────────┤    └──────────────┘
       │              │ run_id(FK)     │
       │              │ ...            │
       │              └────────────────┘
       │
       │         ┌─────────────┐       ┌──────────────────┐
       │         │ friendships │       │ route_leaderboards│
       └────────►├─────────────┤       ├──────────────────┤
                 │ user_id(FK) │       │ route_id(FK)     │
                 │ friend_id   │       │ user_id(FK)      │
                 │ status      │       │ total_time       │
                 └─────────────┘       └──────────────────┘

       ┌─────────────┐       ┌─────────────┐
       │ challenges  │       │challenge_runs│
       ├─────────────┤       ├─────────────┤
       │ id (PK)     │◄──────┤challenge_id │
       │ route_id(FK)│       │ run_id(FK)  │
       │ inviter_id  │       └─────────────┘
       │ invitee_id  │
       │ status      │
       └─────────────┘
```

### 10.2 表结构定义

#### `users` — 用户表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | VARCHAR(36) | PK | UUID |
| phone | VARCHAR(20) | UNIQUE, NOT NULL | 手机号 |
| email | VARCHAR(100) | UNIQUE, NOT NULL | 邮箱（找回密码用） |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt 哈希 |
| nickname | VARCHAR(50) | | 昵称 |
| avatar | VARCHAR(500) | | 头像 URL |
| bio | TEXT | | 个人简介 |
| gender | TINYINT | | 0=未知, 1=男, 2=女 |
| birthday | DATE | | 生日 |
| height | SMALLINT | | 身高(cm) |
| weight | DECIMAL(5,2) | NOT NULL, DEFAULT 60.0 | 体重(kg) — 卡路里计算依赖 |
| total_distance | DECIMAL(10,2) | DEFAULT 0 | 累计跑步距离(m) |
| total_runs | BIGINT | DEFAULT 0 | 累计跑步次数 |
| total_time | BIGINT | DEFAULT 0 | 累计跑步时长(s) |
| total_calories | INT | DEFAULT 0 | 累计消耗卡路里 |
| realm | TINYINT | DEFAULT 0 | 跑境索引 0=炼气~12=道祖 |
| realm_badges | JSON | | 已获得跑境勋章列表 |
| best_5k_time | INT | | 5km PB(s) |
| best_10k_time | INT | | 10km PB(s) |
| best_half_marathon_time | INT | | 半马 PB(s) |
| best_marathon_time | INT | | 全马 PB(s) |
| companion_runs | INT | DEFAULT 0 | 伴跑完成次数 |
| challenges_won | INT | DEFAULT 0 | 挑战胜利次数 |
| post_count | INT | DEFAULT 0 | 已发动态数 |
| device_info | JSON | | 设备信息 |
| settings | JSON | | 用户设置 |
| is_vip | TINYINT(1) | DEFAULT 0 | VIP状态 |
| vip_tier | TINYINT | DEFAULT 0 | 0=非会员 1=标准 2=Pro 3=Ultra |
| vip_expires_at | DATETIME(3) | | VIP到期时间 |
| vip_features | JSON | | 已解锁功能列表 |
| cycling_realm | TINYINT | DEFAULT 0 | 骑境索引 0~12 |
| cycling_realm_badges | JSON | | 骑行已获勋章列表 |
| cycling_best_20k_time | INT | | 20km PB(s) |
| cycling_best_40k_time | INT | | 40km PB(s) |
| cycling_best_80k_time | INT | | 80km PB(s) |
| cycling_best_100k_time | INT | | 百公里计时(s) |
| cycling_best_160k_time | INT | | 160km PB(s) |
| cycling_best_speed | DECIMAL(6,2) | | 最佳均速(km/h) |
| cycling_best_distance | DECIMAL(10,2) | DEFAULT 0 | 最佳单次骑行距离(km) |
| cycling_companions | INT | DEFAULT 0 | 伴骑次数 |
| cycling_challenges_won | INT | DEFAULT 0 | 挑战骑胜利次数 |
| cycling_dual_badges | JSON | | 双修成就列表 |
| cycling_total_distance | DECIMAL(10,2) | DEFAULT 0 | 累计骑行距离(km) |
| created_at | DATETIME(3) | DEFAULT CURRENT_TIMESTAMP(3) | |
| updated_at | DATETIME(3) | DEFAULT CURRENT_TIMESTAMP(3) | |

> **后端模型**：Email、Weight 改为非指针 NOT NULL。Avatar、Gender、Birthday、Height 保持指针类型 nullable。
> **VIP预留**：is_vip 向下兼容，新加 vip_tier/vip_expires_at/vip_features 为扩展。
> **骑境字段**：待骑行模块上线启用，目前仅预留空位。

#### `routes` — 路线表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | VARCHAR(36) | PK | UUID |
| user_id | VARCHAR(36) | FK → users.id, INDEX | 创建者 |
| name | VARCHAR(100) | NOT NULL | 路线名称 |
| description | TEXT | | 描述 |
| distance | DECIMAL(10,2) | NOT NULL | 距离(m) |
| elevation_gain | DECIMAL(10,2) | | 爬升(m) |
| difficulty | TINYINT | DEFAULT 1 | 1=轻松, 2=中等, 3=挑战 |
| avg_pace | DECIMAL(6,2) | | 平均配速(s/km) |
| points_json | LONGTEXT | NOT NULL | 轨迹点数组(JSON) |
| cover_image | VARCHAR(500) | | 封面图 URL |
| is_public | BOOLEAN | DEFAULT true | 是否公开 |
| created_at | DATETIME | DEFAULT NOW() | |
| updated_at | DATETIME | DEFAULT NOW() | |

#### `route_favs` — 路线收藏表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| user_id | VARCHAR(36) | PK, FK → users.id | |
| route_id | VARCHAR(36) | PK, FK → routes.id | |
| created_at | DATETIME | DEFAULT NOW() | |

#### `runs` — 跑步记录表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | VARCHAR(36) | PK | UUID |
| user_id | VARCHAR(36) | FK → users.id, INDEX | |
| route_id | VARCHAR(36) | FK → routes.id, NULLABLE | 关联路线（可选） |
| start_time | DATETIME | NOT NULL | 开始时间 |
| end_time | DATETIME | | 结束时间 |
| total_distance | DECIMAL(10,2) | | 总距离(m) |
| total_time | INT | | 总用时(s) |
| avg_pace | DECIMAL(6,2) | | 平均配速(s/km) |
| avg_heart_rate | SMALLINT | | 平均心率 |
| avg_cadence | SMALLINT | | 平均步频(步/分钟) |
| avg_stride | DECIMAL(5,2) | | 平均步幅(m) |
| calories | INT | | 消耗卡路里 |
| elevation_gain | DECIMAL(10,2) | | 爬升(m) |
| status | TINYINT | DEFAULT 0 | 0=进行中, 1=已完成, 2=已取消 |
| created_at | DATETIME | DEFAULT NOW() | |
| updated_at | DATETIME | DEFAULT NOW() | |

#### `run_samples` — 跑步采样数据表（按月 RANGE 分区）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | |
| run_id | VARCHAR(36) | FK → runs.id, INDEX | |
| timestamp | DATETIME | NOT NULL | 采样时间 |
| latitude | DECIMAL(10,8) | | 纬度 |
| longitude | DECIMAL(11,8) | | 经度 |
| altitude | DECIMAL(8,2) | | 海拔(m) |
| pace | DECIMAL(6,2) | | 瞬时配速(s/km) |
| heart_rate | SMALLINT | | 心率 |
| cadence | SMALLINT | | 步频 |
| stride | DECIMAL(5,2) | | 步幅(m) |
| distance | DECIMAL(10,2) | | 累计距离(m) |

**分区策略**：
```sql
PARTITION BY RANGE (YEAR(timestamp) * 100 + MONTH(timestamp)) (
    PARTITION p202604 VALUES LESS THAN (202605),
    PARTITION p202605 VALUES LESS THAN (202606),
    ...
);
```

**自动扩分区 Event**（每月自动创建下下个月分区）：
```sql
CREATE EVENT auto_add_run_samples_partition
ON SCHEDULE EVERY 1 MONTH
DO CALL add_next_run_samples_partition();
```

#### `route_leaderboards` — 路线排行榜表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | VARCHAR(36) | PK | UUID |
| route_id | VARCHAR(36) | FK → routes.id, INDEX | |
| user_id | VARCHAR(36) | FK → users.id | 复合唯一键 `(route_id, user_id)` |
| run_id | VARCHAR(36) | FK → runs.id | 最好成绩对应的 run |
| total_time | INT | NOT NULL | 最佳总用时(s)，成绩榜排名依据 |
| avg_pace | INT | | 平均配速(s/km) |
| run_count | INT | DEFAULT 0 | 该路线跑步次数，打卡榜排名依据 |
| recorded_at | DATETIME | NOT NULL | 最佳成绩记录时间 |
| created_at | DATETIME | DEFAULT NOW() | |
| updated_at | DATETIME | DEFAULT NOW() | |

> **数据规则**：
> - 成绩榜：同一用户同一路线只保留最好成绩（最小 `total_time`）。跑步结束时自动触发 `Upsert`，仅当新成绩优于历史最佳时才更新 `total_time`。
> - 打卡榜：`run_count` 每次完成跑步时自动 `+1`。
> - 复合唯一索引：`(route_id, user_id)` 确保每用户每路线仅一条记录。

#### `friendships` — 好友关系表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | VARCHAR(36) | PK | UUID |
| user_id | VARCHAR(36) | FK → users.id, INDEX | 发起者 |
| friend_id | VARCHAR(36) | FK → users.id, INDEX | 接收者 |
| status | TINYINT | DEFAULT 0 | 0=待处理, 1=已接受, 2=已拒绝 |
| created_at | DATETIME | DEFAULT NOW() | |
| updated_at | DATETIME | DEFAULT NOW() | |

> 唯一索引：`(LEAST(user_id, friend_id), GREATEST(user_id, friend_id))` 防止重复关系。

#### `challenges` — 挑战/伴跑PK表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | VARCHAR(36) | PK | UUID |
| route_id | VARCHAR(36) | FK → routes.id | 关联路线 |
| inviter_id | VARCHAR(36) | FK → users.id | 发起者 |
| invitee_id | VARCHAR(36) | FK → users.id, NULLABLE | 被邀请者（自发伴跑为 NULL） |
| challenge_type | TINYINT | DEFAULT 0 | 0=配速, 1=心率, 2=步频, 3=步幅 |
| target_value | DECIMAL(10,2) | | 目标值 |
| status | TINYINT | DEFAULT 0 | 0=pending, 1=accepted, 2=running, 3=completed, 4=cancelled |
| result | TINYINT | | 0=失败, 1=成功 |
| started_at | DATETIME | | 开始时间 |
| completed_at | DATETIME | | 完成时间 |
| created_at | DATETIME | DEFAULT NOW() | |
| updated_at | DATETIME | DEFAULT NOW() | |

**状态机**：
```
pending → accepted → running → completed
                    ↘ cancelled
```

> 自发伴跑（无对手）时 `invitee_id` 为 NULL，创建时直接 `accepted`。

#### `challenge_runs` — 挑战关联跑步记录表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| challenge_id | VARCHAR(36) | PK, FK → challenges.id | |
| run_id | VARCHAR(36) | PK, FK → runs.id | |
| is_inviter | BOOLEAN | DEFAULT true | 是否为发起者的跑步 |
| created_at | DATETIME | DEFAULT NOW() | |

---

## 十一、API 设计规范

### 11.1 统一响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

### 11.2 错误码定义

| 错误码 | 含义 | 场景 |
|--------|------|------|
| 0 | 成功 | — |
| 1001 | 参数错误 | 请求参数校验失败 |
| 1002 | 未授权 | Token 缺失或无效 |
| 1003 | 禁止访问 | 无权操作该资源 |
| 1004 | 资源不存在 | 查询的数据不存在 |
| 2001 | 用户已存在 | 注册时手机号已注册 |
| 2002 | 用户不存在 | 登录时手机号未注册 |
| 2003 | 密码错误 | 登录密码不匹配 |
| 3001 | 路线不存在 | 查询/操作路线时 |
| 3002 | 已收藏 | 重复收藏路线 |
| 3003 | 未收藏 | 取消收藏时未收藏 |
| 4001 | 上传失败 | 文件上传错误 |
| 5000 | 服务器内部错误 | 未预期异常 |

### 11.3 认证机制

**双令牌策略**：
- **Access Token**：JWT，有效期 24 小时，放在 `Authorization: Bearer <token>` 请求头中
- **Refresh Token**：JWT，有效期 7 天，用于在 Access Token 过期后获取新令牌

**登录流程**：
```
POST /api/v1/auth/login
Request: { "phone": "13800138000", "password": "xxx" }
Response: { "code": 0, "data": { "access_token": "...", "refresh_token": "...", "expires_in": 86400 } }
```

**Token 刷新**：
```
POST /api/v1/auth/refresh
Request: { "refresh_token": "..." }
Response: { "code": 0, "data": { "access_token": "...", "refresh_token": "..." } }
```

### 11.4 完整 API 接口列表

#### 认证模块 (`/api/v1/auth`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/register` | 用户注册（phone + password + email + weight） | 公开 |
| POST | `/login` | 用户登录（手机号+密码） | 公开 |
| POST | `/refresh` | 刷新 Token | 公开 |

#### 用户模块 (`/api/v1/user`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | `/profile` | 获取当前用户信息 | JWT |
| PUT | `/profile` | 更新用户资料 | JWT |
| PUT | `/password` | 修改密码 | JWT |
| GET | `/:id/profile` | 获取指定用户公开资料 | JWT |
| GET | `/:id/stats` | 获取指定用户统计数据（总里程/次数/时长/卡路里/跑境/徽章） | JWT |

#### 跑步记录模块 (`/api/v1/runs`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/start` | 开始跑步 | JWT |
| POST | `/import` | 批量导入健康平台跑步记录（Health Connect/HMS/Apple Health） | JWT |
| POST | `/:id/samples` | 上传采样数据 | JWT |
| POST | `/:id/finish` | 结束跑步 | JWT |
| GET | `/` | 获取跑步历史列表 | JWT |
| GET | `/:id` | 获取跑步详情 | JWT |

#### 路线模块 (`/api/v1/routes`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/` | 创建路线 | JWT |
| GET | `/` | 获取路线列表（分页） | JWT |
| GET | `/nearby` | 附近路线搜索 | JWT |
| GET | `/:id` | 获取路线详情 | JWT |
| PUT | `/:id` | 更新路线 | JWT |
| DELETE | `/:id` | 删除路线 | JWT |
| POST | `/:id/favorite` | 收藏路线 | JWT |
| DELETE | `/:id/favorite` | 取消收藏 | JWT |
| GET | `/:id/leaderboard` | 获取路线排行榜（支持 `?sort_by=time_asc` 切换成绩榜，默认打卡榜） | JWT |
| POST | `/:id/rating` | 为路线评分 | JWT |
| GET | `/favorites` | 获取我的收藏列表 | JWT |

#### 好友模块 (`/api/v1/friends`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/request` | 发送好友申请 | JWT |
| GET | `/pending` | 获取待处理申请列表 | JWT |
| POST | `/:id/accept` | 接受好友申请 | JWT |
| POST | `/:id/reject` | 拒绝好友申请 | JWT |
| GET | `/` | 获取好友列表 | JWT |
| DELETE | `/:id` | 删除好友 | JWT |

#### 挑战/伴跑PK模块 (`/api/v1/challenges`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/` | 发起挑战/伴跑 | JWT |
| GET | `/` | 获取挑战列表 | JWT |
| GET | `/:id` | 获取挑战详情 | JWT |
| POST | `/:id/accept` | 接受挑战 | JWT |
| POST | `/:id/start` | 开始挑战 | JWT |
| POST | `/:id/complete` | 完成挑战 | JWT |
| POST | `/:id/cancel` | 取消挑战 | JWT |
| GET | `/:id/comparison` | 获取对比报告 | JWT |

#### 跑友动态模块 (`/api/v1/posts`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/` | 发布动态（内容 + 可选关联 `run_id`） | JWT |
| GET | `/` | 获取动态列表（分页） | JWT |
| GET | `/:id` | 获取动态详情 | JWT |
| DELETE | `/:id` | 删除动态 | JWT |

#### 文件上传模块 (`/api/v1/upload`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/avatar` | 上传头像 | JWT |
| POST | `/gpx` | 上传 GPX 文件 | JWT |

> 开发阶段文件存储使用本地文件系统（`./uploads/avatars`, `./uploads/gpx`），通过 `/static` 静态文件服务访问。后续切换至真实 MinIO。

### 11.5 静态文件服务

| 路径 | 说明 |
|------|------|
| `/static/avatars/{filename}` | 头像文件访问 |
| `/static/gpx/{filename}` | GPX 文件访问 |
| `/health` | 服务健康检查 |


---

## 十二、数据模型

### 12.1 后端核心模型（Go）

#### User 模型

```go
type User struct {
    ID           string     `gorm:"type:varchar(36);primaryKey" json:"id"`
    Phone        string     `gorm:"type:varchar(20);uniqueIndex;not null" json:"phone"`
    PasswordHash string     `gorm:"type:varchar(255);not null" json:"-"`
    Nickname     *string    `gorm:"type:varchar(50)" json:"nickname"`
    Avatar       *string    `gorm:"type:varchar(500)" json:"avatar"`
    Gender       *int8      `gorm:"type:tinyint" json:"gender"`
    Birthday     *string    `gorm:"type:date" json:"birthday"`
    Height       *int16     `gorm:"type:smallint" json:"height"`
    Weight       *int16     `gorm:"type:smallint" json:"weight"`
    Bio          *string    `gorm:"type:varchar(255)" json:"bio"`
    CreatedAt    time.Time  `json:"created_at"`
    UpdatedAt    time.Time  `json:"updated_at"`
}
```

> **注意**：`Avatar`, `Gender`, `Birthday`, `Height`, `Weight` 均为指针类型，支持 NULL。Service 层 `toUserInfo` 需做 nil 检查。`Birthday` 为 `*string`（DATE 格式），转 DTO 时用 `time.Parse` 转 `*time.Time`。

#### Run 模型

```go
type Run struct {
    ID             string          `gorm:"type:varchar(36);primaryKey" json:"id"`
    UserID         string          `gorm:"type:varchar(36);index;not null" json:"user_id"`
    RouteID        *string         `gorm:"type:varchar(36);index" json:"route_id"`
    StartTime      time.Time       `gorm:"not null" json:"start_time"`
    EndTime        *time.Time      `json:"end_time"`
    TotalDistance  *float64        `gorm:"type:decimal(10,2)" json:"total_distance"`
    TotalTime      *int            `json:"total_time"`
    AvgPace        *float64        `gorm:"type:decimal(6,2)" json:"avg_pace"`
    AvgHeartRate   *int16          `json:"avg_heart_rate"`
    AvgCadence     *int16          `json:"avg_cadence"`
    AvgStride      *float64        `gorm:"type:decimal(5,2)" json:"avg_stride"`
    Calories       *int            `json:"calories"`
    ElevationGain  *float64        `gorm:"type:decimal(10,2)" json:"elevation_gain"`
    Status         int8            `gorm:"type:tinyint;default:0" json:"status"`
    CreatedAt      time.Time       `json:"created_at"`
    UpdatedAt      time.Time       `json:"updated_at"`
}
```

#### Route 模型

```go
type Route struct {
    ID            string     `gorm:"type:varchar(36);primaryKey" json:"id"`
    UserID        string     `gorm:"type:varchar(36);index;not null" json:"user_id"`
    Name          string     `gorm:"type:varchar(100);not null" json:"name"`
    Description   *string    `gorm:"type:text" json:"description"`
    Distance      float64    `gorm:"type:decimal(10,2);not null" json:"distance"`
    ElevationGain *float64   `gorm:"type:decimal(10,2)" json:"elevation_gain"`
    Difficulty    int8       `gorm:"type:tinyint;default:1" json:"difficulty"`
    AvgPace       *float64   `gorm:"type:decimal(6,2)" json:"avg_pace"`
    PointsJSON    string     `gorm:"type:longtext;not null" json:"points_json"`
    CoverImage    *string    `gorm:"type:varchar(500)" json:"cover_image"`
    IsPublic      bool       `gorm:"default:true" json:"is_public"`
    CreatedAt     time.Time  `json:"created_at"`
    UpdatedAt     time.Time  `json:"updated_at"`
}
```

### 12.2 前端核心模型（Dart / Freezed）

#### User 模型

```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String phone,
    String? nickname,
    String? avatar,
    int? gender,
    DateTime? birthday,
    int? height,
    int? weight,
    String? bio,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

> **注意**：前端 `birthday` 为 `DateTime?`，后端为 `*string`（DATE 格式）。API 对接时需做格式转换。

#### Run 模型

```dart
@freezed
class Run with _$Run {
  const factory Run({
    required String id,
    required String userId,
    String? routeId,
    required DateTime startTime,
    DateTime? endTime,
    double? totalDistance,
    int? totalTime,
    double? avgPace,
    int? avgHeartRate,
    int? avgCadence,
    double? avgStride,
    int? calories,
    double? elevationGain,
    required int status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Run;

  factory Run.fromJson(Map<String, dynamic> json) => _$RunFromJson(json);
}
```

#### Route 模型

```dart
@freezed
class Route with _$Route {
  const factory Route({
    required String id,
    required String userId,
    required String name,
    String? description,
    required double distance,
    double? elevationGain,
    required int difficulty,
    double? avgPace,
    required String pointsJson,
    String? coverImage,
    required bool isPublic,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Route;

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
}
```

#### Challenge 模型

```dart
@freezed
class Challenge with _$Challenge {
  const factory Challenge({
    required String id,
    required String routeId,
    required String inviterId,
    String? inviteeId,
    required int challengeType,
    double? targetValue,
    required int status,
    int? result,
    DateTime? startedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Challenge;

  factory Challenge.fromJson(Map<String, dynamic> json) => _$ChallengeFromJson(json);
}
```

#### ComparisonReport 模型（伴跑PK对比报告）

```dart
@freezed
class ComparisonReport with _$ComparisonReport {
  const factory ComparisonReport({
    required String challengeId,
    required Run myRun,
    required Run opponentRun,
    required ComparisonMetrics metrics,
    required String diagnosis,
    DateTime? generatedAt,
  }) = _ComparisonReport;

  factory ComparisonReport.fromJson(Map<String, dynamic> json) => _$ComparisonReportFromJson(json);
}

@freezed
class ComparisonMetrics with _$ComparisonMetrics {
  const factory ComparisonMetrics({
    required MetricComparison pace,
    required MetricComparison heartRate,
    required MetricComparison cadence,
    required MetricComparison stride,
  }) = _ComparisonMetrics;

  factory ComparisonMetrics.fromJson(Map<String, dynamic> json) => _$ComparisonMetricsFromJson(json);
}

@freezed
class MetricComparison with _$MetricComparison {
  const factory MetricComparison({
    required double myValue,
    required double opponentValue,
    required double difference,
    required bool isBetter,
  }) = _MetricComparison;

  factory MetricComparison.fromJson(Map<String, dynamic> json) => _$MetricComparisonFromJson(json);
}
```

---

## 十三、开发环境

### 13.1 Docker 服务配置

使用 `docker-compose.yml` 启动开发依赖：

| 服务 | 镜像 | 容器端口 | 宿主机端口 | 说明 |
|------|------|---------|-----------|------|
| MySQL | mysql:8.0 | 3306 | 3308 | 数据库 `stridemoor` |
| Redis | redis:7-alpine | 6379 | 6380 | 缓存 |
| MinIO | minio/minio | 9000/9001 | 9002/9003 | 对象存储（S3 API） |

**启动脚本**（`start-dev-env.bat` / `start-dev-env.sh`）：
```bash
docker-compose up -d
```

### 13.2 数据库连接信息

| 项目 | 值 |
|------|-----|
| 主机 | localhost |
| 端口 | 3308 |
| 数据库 | stridemoor |
| 用户名 | stridemoor |
| 密码 | stridemoor_pass_2026 |
| 字符集 | utf8mb4 |

### 13.3 后端启动步骤

```bash
cd D:\AI\StrideMoor\backend

# 1. 确保 Docker 服务已启动（MySQL 3308, Redis 6380）

# 2. 首次运行需创建数据库表（GORM AutoMigrate）
# 在 main.go 中已配置 db.AutoMigrate(...) 自动迁移

# 3. 编译并运行
go build -o stridemoor-api.exe cmd/server/main.go
.\stridemoor-api.exe

# 服务默认监听 :8080
```

### 13.4 前端启动步骤

```bash
cd D:\AI\StrideMoor\stride_moor_app

# 确保 Flutter 环境已配置
flutter doctor

# 安装依赖
flutter pub get

# 运行（Android）
flutter run

# 或指定设备
flutter run -d <device_id>
```

### 13.5 高德地图 SDK 配置

已在 `AndroidManifest.xml` 中配置：
```xml
<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="f50e31d4bd4b6cb53cbf2a019d9be9ba" />
```

包名：`com.example.stride_moor`

---

## 十四、已知问题与待办

### 14.1 当前已知问题

| # | 问题 | 严重程度 | 说明 |
|---|------|---------|------|
| 1 | Go 编译环境网络超时 | 🔴 高 | `go build`/`go version` 均超时（60s~180s），疑似代理/网络阻塞 Go 工具链初始化。需用户在本地终端验证编译。 |
| 2 | MinIO SDK 未引入 | 🟡 中 | 因网络问题无法 `go get github.com/minio/minio-go/v7`，当前上传实现为本地文件系统占位（标准库实现），后续需切换真实 MinIO。 |
| 3 | 前端 API 路径不一致 | 🟡 中 | `api_service.dart` 中部分接口与后端实际路由不完全对齐（如登录用 `code` 而非 `password`，部分路径缺少 `/api/v1` 前缀）。需前后端对齐。 |
| 4 | 前端 Token 注入未完成 | 🟡 中 | Dio Interceptor 中 TODO: 注入 Token，当前未实现自动 Token 刷新。 |
| 5 | 上传 Handler `gin` import | 🟢 低 | `upload.go` 使用 `gin.H` 但未显式 import `github.com/gin-gonic/gin`。实际通过 `response` 包间接引用，需确认编译。 |
| 6 | 暗色主题未调优 | 🟢 低 | `darkTheme` 已定义但部分文字对比度不足，待完善后开放切换。 |

### 14.2 待办清单

#### 后端

| # | 任务 | 优先级 | 状态 |
|---|------|--------|------|
| 1 | 修复 Go 编译环境问题，验证 `go build` 通过 | P0 | 🔴 阻塞 |
| 2 | 引入 MinIO SDK，替换本地文件存储 | P1 | 🔄 待网络恢复 |
| 3 | 添加单元测试和集成测试 | P1 | 🔄 未开始 |
| 4 | 实现 Redis 缓存层（热点数据、会话） | P1 | 🔄 未开始 |
| 5 | 添加 API 限流和防刷机制 | P2 | 🔄 未开始 |
| 6 | 配置日志切割和监控（Prometheus） | P2 | 🔄 未开始 |

#### 前端

| # | 任务 | 优先级 | 状态 |
|---|------|--------|------|
| 1 | 对齐 `api_service.dart` 与后端路由 | P0 | 🔄 进行中 |
| 2 | 实现 Token 自动注入和刷新机制 | P0 | 🔄 进行中 |
| 3 | 完成各页面的真实数据对接 | P0 | 🔄 进行中 |
| 4 | 高德地图定位权限和实际轨迹绘制 | P0 | ✅ 跑迹页面已集成AMap，定位和轨迹绘制待完善 |
| 5 | 跑步中实时数据采集和上传 | P0 | 🔄 UI 骨架完成，业务逻辑待实现 |
| 6 | 暗色主题精细调优 | P1 | 🔄 未开始 |
| 7 | BLE 设备连接和心率数据读取 | P1 | 🔄 未开始 |
| 8 | 语音播报系统（TTS + 预设风格） | P1 | 🔄 未开始 |
| 9 | 跑友动态（点赞/评论/发布） | P1 | 🔄 UI 骨架完成 |
| 10 | 分享卡片生成（截图/深度链接） | P1 | 🔄 未开始 |

#### 数据库

| # | 任务 | 优先级 | 状态 |
|---|------|--------|------|
| 1 | 创建初始数据库和表（GORM AutoMigrate） | P0 | ✅ 代码完成，待首次运行 |
| 2 | 验证 `run_samples` 分区表创建和 Event 调度 | P1 | 🔄 待首次运行验证 |

---

## 十五、版本历史

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| v0.1 | 2026-04-20 | 初始产品需求文档，包含产品定位、核心功能、MVP范围 |
| v0.2 | 2026-04-22 | 新增技术风险、竞品对比、商业模式 |
| v0.3 | 2026-04-23 | 新增前端架构章节（Flutter 模块设计、页面清单） |
| v0.4 | 2026-04-25 | 技术选型表新增国际化(i18n)架构行；MVP P0 新增暗色主题 + 国际化 |
| **v1.0** | **2026-04-27** | **重大更新：同步代码库实际状态，新增后端架构、数据库设计、API规范、数据模型、开发环境、已知问题与待办。前端页面清单增加"实现状态"列。覆盖前后端完整技术实现。** |
| v1.1 | 2026-04-28 | 新增跑步中锁屏（长按解锁+全屏触摸拦截）；倒计时3-2-1缩放淡出动画；默认语音播报内容新增步频/步幅/卡路里；路线GPS匹配容差从30m提升到50m |
| v1.2 | 2026-04-29 | 语音播报系统完整实现（4种风格+目标达成+倒计时播报）；RunNotifier 状态管理重构；locales 文案覆盖50+键 |
| v1.3 | 2026-05-04 | 健康数据同步基础设施搭建（health_sync_service, health_data_source抽象工厂, hms_health_sync_service）; RunFinishPage 心率UI显示（有数据展示，无数据"--"）；后端Run模型新增 avg_heart_rate/max_heart_rate；设备管理页UI完成 |
| **v1.4** | **2026-05-07** | **健康数据同步平台接入打通（Health Connect / Apple Health / HMS Health Kit）；设备管理页完成（绑定/解绑/健康平台关联）；HealthSyncPage 完整导入流程（检测→授权→拉取→勾选→入库）；华为 agconnect-services.json 配置；`huawei_health: ^6.16.0+300` 插件集成（自含HMS SDK，无需AGConnect Gradle插件）；构建验证通过 |

---

*文档版本：v1.4 | 更新日期：2026-05-07 | 状态：与代码库同步*

