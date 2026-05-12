# 语音播报系统 — 设计规格

> 路径: `stride_moor_app/lib/core/services/voice_broadcast_service.dart`
> 版本: v2.0 (2026-05-09) — 增强伴跑多维度对比 + 挑战跑累计时间差/追赶趋势

---

## 架构

```
_buildBroadcastText(state)
    ├── RunMode.solo       → _buildSoloText(state)
    ├── RunMode.companion  → _buildCompanionText(state)
    └── RunMode.challenge  → _buildChallengeText(state)
```

每个分支按播报参数（items）拼接段落后，再统一加风格前缀（道友！/ 加油！/ 无前缀）。

---

## 一、独自跑（Solo）

**参考系：跟自己历史平均比**

```
[当前数据] → [跟历史比（差异>阈值时）]
```

| 指标 | 播报逻辑 | 示例 |
|------|---------|------|
| 距离 | 播数值 | "已跑3.5公里" |
| 用时 | 播数值 | "用时18分30秒" |
| 配速 | 跟历史平均比 | 快→"较往日精进不少"，慢→"道法自然不必强求"，接近→"配速5分10" |
| 心率 | 跟历史平均比 + 安全警戒 | "心率152，比平时偏高" / >175→"偏高注意安全" |
| 步频 | 跟历史平均比 | 差异>20才提一句 |
| 步幅 | 跟历史平均比 | 差异>15cm才提一句 |
| 鼓励 | 轮播语录池 | 4种风格各有5条，按索引轮换 |

首次跑：全程鼓励不评判。

---

## 二、伴跑（Companion）

> **核心理念**: 伴跑 = 学习对手。对手不是敌人，是教练。告诉你对手怎么做、差距在哪、你可以怎么学。

**三段式播报结构：**

```
[当前数据] → [对手此段多维度对比 ⭐] → [幻影模式特定内容]
```

### 对手此段对比（核心）— 多维度 + 连续趋势

每段播报从三个维度做同一分段对比，加上连续趋势总结：

```
[配速对比] → [心率对比（学习点）] → [步频对比] → [连续趋势]
```

| 维度 | 数据源 | 判据 | 示例 |
|------|--------|------|------|
| **配速对比** | 双方分段 pace 或全程 avgPace | diff 阈值 5秒 | "此段快了10秒" / "几乎同步" / "此段慢了8秒" |
| **心率对比（学习点）** | 双方分段 avgHeartRate | diff 阈值 5bpm | "你心率152高于对手148，注意调匀呼吸" |
| | | | "你心率148低于对手152，心肺状态不错" |
| | | diff <5 | "心率152，与对手相仿" |
| **步频对比** | 双方分段 avgCadence | diff 阈值 10步 | "你步频180高于对手175" / "你步频168低于对手172" |
| **连续趋势** | `_consecutiveWins` / `_consecutiveLosses` | 连续3段触发 | "连续3公里领先，节奏保持得不错" |
| | | | "连续3公里落后，可以找找原因调整一下" |

数据回退层级：
- 优先取 `opponentRun.splits` 中 `splitIndex == _currentSplitIndex` 的分段数据
- 该分段无数据时退回到对手全程平均值 `opp.avgPace`
- 用户侧同理，分段 > 全程

```dart
// 连续趋势内部状态：每次配速对比后更新
diff = oppPace - myPace;
if (diff > 5) {
  _consecutiveWins++;     // 配速快于对手+5秒 → 赢
  _consecutiveLosses = 0;
} else if (diff < -5) {
  _consecutiveLosses++;   // 配速慢于对手-5秒 → 输
  _consecutiveWins = 0;
} else {
  _consecutiveWins = 0;   // 持平 → 重置
  _consecutiveLosses = 0;
}
```

### 按幻影模式区分

#### ① 真实回放（Real Replay）
- **核心**: 累计差距变化
- **内容**: 并驾齐驱 / 差X米追上 / 领先X米

#### ② 恒定配速（Constant Pace）
- **核心**: 跟对手平均配速（目标配速）比
- **内容**: 配速精准 / 比目标快X秒 / 比目标慢X秒

#### ③ 领跑兔（Rabbit）
- **核心**: 追逐距离
- **内容**: 追上并超越！/ 兔在前X米 / 甩开X米

#### ④ 龟兔赛跑（Tortoise & Hare）
- **核心**: 当前分段对手快/慢
- **内容**: 对手此段慢了拉开差距 / 对手加速稳住 / 势均力敌

#### ⑤ 目标挑战（Goal Challenge）
- **核心**: 目标达成进度
- **内容**: 调用 `_formatGoalStatus` + 对手对比

### 伴跑播报参数

伴跑模式下，`items` 中的 `lag` 和 `opponent_pace` 被忽略（已融入三段式结构），其余参数（distance/duration/pace/heart_rate/cadence/stride_length/calories/climb）正常播报。

---

## 三、挑战跑（Challenge）

> **核心理念**: 挑战跑 = 协助跑者超越对手。每一公里都在打比赛，跑者要实时知道自己在赢还是在输。

**只播选中的比拼指标，其他指标不出现。**

```
[基本信息] → [选中指标 vs 对手] → [累计时间差] + [本段追赶趋势]
```

基本信息只包含：距离、用时、目标进度、爬升。**不播配速/心率/步频/步幅。**

### 各指标对比

#### 配速（Pace）
```
"配速5分10，对手5分20，此段快10秒"
"配速5分30，对手5分20，此段慢10秒"
```

#### 心率（Heart Rate）
```
"心率152，对手158，你偏低6，心肺状态更好"
"心率168，对手158，你偏高10，注意调息"
```

#### 步频（Cadence）
```
"步频178，对手172，步频更高"
"步频168，对手172，步频低4，可加快些"
```

#### 步幅（Stride Length）
```
"步幅120厘米，对手110厘米，跨幅更大"
"步幅100厘米，对手110厘米，跨幅小10厘米"
```

### 每段对比取双方同分段数据

优先取双方 `splits` 中 `splitIndex == _currentSplitIndex` 的分段数据；
该分段无数据时退回到各自的全程平均值（`run.avgPace` / `opp.avgPace`）。

### 累计时间差

每次播报时通过 `_calcCumulativeGap` 计算累计领先/落后：

```dart
double _calcCumulativeGap(Run run, Run opp) {
  // 遍历 currentSplitIndex 以下所有完成分段
  // 累计 opp.time - my.time（正=领先，负=落后）
  double gap = 0;
  for (int i = 0; i <= _currentSplitIndex; i++) {
    final my = run.splits.where((s) => s.splitIndex == i).firstOrNull;
    final op = opp.splits.where((s) => s.splitIndex == i).firstOrNull;
    if (my != null && op != null && op.time > 0) {
      gap += (op.time - my.time).toDouble();
    }
  }
  return gap;
}
```

播报条件：
- 绝对值 >3秒 → "累计领先X秒" / "累计落后X秒"
- 绝对值 ≤3秒且 ≠0 → "几乎打平"

### 本段追赶趋势

每次播报时计算差值：

```
delta = gap - _cumulativeTimeGap   // 本次累计差 - 上次累计差
```

- diff 绝对值 >2秒触发播报
- delta >0 → "这一公里追回X秒"
- delta <0 → "这一公里被拉开X秒"
- 更新 `_cumulativeTimeGap = gap` 供下段使用

---

## 四、分段索引跟踪

`_currentSplitIndex` 在 `onStateUpdate` 中更新：
```dart
final splitKm = (distance / 1000).floor();
if (splitKm > _currentSplitIndex) {
  _currentSplitIndex = splitKm;
}
```

以公里为基准，每进入下一公里时递增。

---

## 五、语音风格

| 风格 | 前缀 | 特点 |
|------|------|------|
| standard | 无 | 简洁中性 |
| jianghu | "道友！" | 修仙用语（里/丈/道心/修为） |
| coach | "加油！" | 专业指导（呼吸/跑姿/核心） |
| toxic | 无 | 调侃幽默（不严厉批评） |

---

## 六、预设阈值（硬编码）

| 指标 | 阈值 | 触发场景 |
|------|------|---------|
| 配速偏离 | >15% 变化 | 骤升/骤降时报警 |
| 心率过高 | >175 bpm | 安全警戒 |
| 分段差异（配速） | <5秒 | "几乎同步" / "不分伯仲" |
| 心率对比 | <5 bpm | "相近" / "与对手相仿" |
| 步频对比 | <10步 | "步频相当" |
| 连续趋势 | ≥3段 | 连续领先/落后总结 |
| 累计时间差 | >3秒 | 播报累计领先/落后 |
| 追赶趋势 | >2秒 | 播报追回/被拉开 |
| 距离差距 | <10/20/30米 | "并驾齐驱"级别由各幻影模式自定 |

---

## 七、内部状态字段

| 字段 | 用途 | 模式 |
|------|------|------|
| `_currentSplitIndex` | 当前公里段索引 | 伴跑+挑战 |
| `_consecutiveWins` | 连续领先段数 | 伴跑 |
| `_consecutiveLosses` | 连续落后段数 | 伴跑 |
| `_lastSegmentPaceDiff` | 上段配速差 | 伴跑 |
| `_cumulativeTimeGap` | 累计时间差（秒，正=领先） | 挑战跑 |

所有字段在 `reset()` 中清零。

---

## 八、未来可扩展

- **个性化阈值**: 从后端用户配置读取配速/心率阈值
- **分段热图提醒**: 对手历史多个样本形成的"热图"，告知常见减速路段
- **赛后语音总结**: 跑完后自动生成一段总结语音
- **学习建议多样化**: 超过步频/心率/步幅对比，加入跑姿建议等
- **反超瞬间庆祝**: 从落后到领先的瞬间，特殊播报庆祝
