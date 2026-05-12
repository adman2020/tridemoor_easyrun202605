# 驰陌 AI 功能集成方案

> **文档版本**: v2.3  
> **更新时间**: 2026-05-12  
> **变更**: VIP分级设计（is_vip: 0-5）、VIP+AI联动、ai_api_keys表结构更新、Phase 1路面类型+爬升增强完成

---

## 1. 功能清单与前端落点

### 1.1 App 端（全部改现有页面，零新增）

| # | AI功能 | 前端页面 | 改/新增 | 具体UI元素 | 触发时机 |
|---|--------|---------|--------|-----------|----------|
| 1 | AI跑情分析 | 运动记录 → 跑步详情页 | 改现有 | 详情页底部「AI跑情分析」卡片（结合历史成绩+跑境给出有参照的洞察）；详情页操作栏三个按钮：「发跑友动态」「收藏我的跑迹」「AI跑情分析」 | 用户查看历史跑步记录时 |
| 2 | AI跑步教练 | `running_page.dart` | 改现有 | 无新UI，AI文案替换/补充现有语音播报 | 每公里自动（与播报同步） |
| 3 | AI路线推荐 | `route_square_page.dart` | 改现有 | Tab栏新增"AI推荐"Tab | 进入路线广场按位置请求 |
| 4 | AI帮写评论 | `post_detail_page.dart` | 改现有 | 评论输入框旁新增"✨AI帮写"按钮 | 用户点击时 |
| 5 | AI找搭档 | `companion_select_page.dart` | 改现有 | 对手列表顶部新增AI推荐卡片 | 选择伴跑对手时 |
| 6 | AI每日金句 | `discover_page.dart` | 改现有 | 金句卡片样式不变，文案来源升级 | 每日首次打开发现页 |
| 7 | AI路线审核 | `route_upload_page.dart` | 改现有 | 上传提交时后端自动审核，不通过弹提示 | 用户上传路线到广场时 |
| 8 | AI功能开关 | `settings_page.dart` | 改现有 | 设置页新增"AI智能功能"分组 | 用户手动设置 |

### 1.2 管理端（扩展现有 AI服务管理 目录）

| # | 配置项 | 管理端页面 | 改/新增 | 说明 |
|---|--------|-----------|--------|------|
| 1 | API密钥管理 | AI服务管理 → 密钥管理 | 已有 | `ai_api_keys` 表，`usage_scope` 扩展值 |
| 2 | 调用日志 | AI服务管理 → 调用日志 | 已有 | `ai_call_logs` 表 |
| 3 | 功能总开关 | AI服务管理 → 功能配置 | 新增页 | 每个功能启用/禁用 + 模型选择 |
| 4 | 教练Prompt模板 | AI服务管理 → 教练模板 | 新增页 | 各跑步模式的Prompt编辑+预览 |
| 5 | 总结风格模板 | AI服务管理 → 总结模板 | 新增页 | 4种风格Prompt编辑 |
| 6 | 评论生成规则 | AI服务管理 → 评论配置 | 新增页 | 评论风格+长度+禁用词 |
| 7 | 审核规则配置 | AI服务管理 → 审核配置 | 新增页 | 路线命名规则+去重阈值+敏感词 |
| 8 | 推荐算法参数 | AI服务管理 → 推荐配置 | 新增页 | 匹配权重+推荐数量 |
| 9 | 金句模板管理 | AI服务管理 → 金句模板 | 新增页 | Prompt编辑+语料库管理 |

---

## 2. 技术架构

### 2.1 整体架构

```
Flutter App
    ↓ (HTTPS)
Go Backend (stridemoor-api)
    ↓
AI Service Layer (内部服务层)
    ├── 配置来源: 从 stridemoor 库 ai_api_keys 表读取（管理端维护）
    ├── 日志写入: 调用完成后写 ai_call_logs 表
    ↓
AI Provider (可插拔，管理端配置)
    ├── OpenAI Compatible (DeepSeek, Kimi, Qwen...)
    ├── 华为盘古 (HMS ML Kit)
    └── 本地小模型 (未来扩展)
```

### 2.2 关键设计：复用管理端 AI 基础设施

**不另建 `ai_model_configs` 表。** 直接复用管理端已有的 `ai_api_keys` 表：

| 字段 | 用途 | AI功能扩展 |
|------|------|-----------|
| `id` | 主键 | - |
| `provider` | 提供商 | deepseek/openai/moonshot/qwen |
| `name` | 密钥名称 | 管理端显示用 |
| `api_key` | API密钥 | - |
| `base_url` | API基础URL | - |
| `model` | 默认模型 | 各功能可用不同模型 |
| `usage_scope` | 使用范围 | run_coach/run_analysis/route_recommend/social_comment/daily_quote/route_review |
| `priority` | 优先级 | 多密钥轮换用 |
| `is_active` | 启禁 | 单个密钥可独立启禁 |
| `daily_limit` | 日限额 | 按功能独立限流 |
| `today_calls` | 今日调用次数 | 实时统计 |
| `remarks` | 备注 | 管理端显示用 |

#### VIP 分级设计（v2.3 新增）

**VIP 等级字段**：`users.is_vip` 从布尔值改为整数（0-5）

| 值 | 等级 | 说明 |
|----|------|------|
| 0 | 非VIP | 普通用户 |
| 1 | VIP Lv.1 | 基础VIP（待命名） |
| 2 | VIP Lv.2 | 进阶VIP（待命名） |
| 3 | VIP Lv.3 | 高级VIP（待命名） |
| 4 | VIP Lv.4 | 尊享VIP（待命名） |
| 5 | VIP Lv.5 | 至尊VIP（待命名） |

#### VIP + AI 功能联动设计（v2.3 新增）

**设计原则**：不额外加 `required_vip` 字段，直接用 `users.is_vip` + `ai_api_keys.is_active` 联动

| users.is_vip | ai_api_keys.is_active | 结果 |
|-------------|---------------------|------|
| > 0 (VIP) | 1 (启用) | ✅ 可使用AI功能 |
| > 0 (VIP) | 0 (禁用) | ❌ 功能已关闭 |
| 0 (非VIP) | 1 (启用) | ❌ 需要开通VIP |
| 0 (非VIP) | 0 (禁用) | ❌ 功能已关闭 |

**判断逻辑**：
```dart
// Flutter 前端
final isVip = (userAsync.valueOrNull?.isVip ?? 0) > 0;
```
```go
// Go 后端
if user.IsVip > 0 && apiKey.IsActive {
    // 允许调用AI
}
```

**Go 后端配置加载流程：**
```
1. 启动时从 stridemoor.ai_api_keys 读取 active=1 的配置
2. 缓存到 Redis（10分钟过期）
3. App 请求AI功能时，Go从缓存取对应 scope 的密钥
4. 调用AI后，写 ai_call_logs 表（通过回调接口写管理端）
```

### 2.3 后端目录规划

```
internal/
  service/
    ai_service.go          # AI统一调用入口（配置加载+降级+日志）
    ai_coach.go            # AI跑步教练（被voice_broadcast调用）
    ai_summary.go          # AI跑后总结
    ai_route.go            # AI路线推荐 + 路线审核
    ai_social.go           # AI社交（评论+搭档匹配）
    ai_quote.go            # AI每日金句
  handler/
    ai_handler.go          # AI相关API Handler
```

### 2.4 前端修改清单

```
lib/
  core/services/
    voice_broadcast_service.dart   # 改：新增AI教练增强层
    ai_service.dart               # 新增：AI统一调用服务
  modules/
    run/
      running_page.dart           # 改：播报系统接入AI教练
      run_finish_page.dart        # 改：新增AI总结卡片
    route/
      route_square_page.dart      # 改：Tab栏新增AI推荐
      route_upload_page.dart      # 改：提交时AI审核+命名建议
    social/
      post_detail_page.dart       # 改：评论框新增AI帮写按钮
      companion_select_page.dart  # 改：顶部新增AI推荐搭档卡片
    discover/
      discover_page.dart          # 改：每日金句AI增强
    settings/
      settings_page.dart          # 改：新增AI功能开关分组
```

---

## 3. AI 功能详细设计

---

### 3.1 AI跑步教练 — 改 `voice_broadcast_service.dart`

#### 核心理念

**AI教练不是独立模块，是现有播报系统的增强层。** 保留 `_buildBroadcastText(state)` 骨架，AI作为可选的文案生成引擎替换/补充规则文案。

#### 融合架构

```dart
// voice_broadcast_service.dart — 修改后的播报流程

String _buildBroadcastText(RunState state) {
  // 1. 先用规则引擎生成基础文案（即时可用，不等待AI）
  final ruleText = _buildRuleText(state);
  
  // 2. 如果AI教练开启，异步请求AI增强文案
  if (_aiCoachEnabled && _networkAvailable) {
    _requestAICoachAdvice(state);  // 异步，不阻塞当前播报
  }
  
  // 3. 如果有AI缓存文案，优先使用
  if (_cachedAIAdvice != null) {
    final aiText = _cachedAIAdvice!;
    _cachedAIAdvice = null;
    return aiText;
  }
  
  // 4. 降级：使用规则文案
  return ruleText;
}

// 异步请求AI教练建议（不阻塞GPS采样和播报）
Future<void> _requestAICoachAdvice(RunState state) async {
  try {
    final advice = await _aiService.getCoachAdvice(
      runId: state.runId,
      mode: state.runMode,        // solo/companion/challenge
      currentData: state.currentStats,
      historyData: state.historyStats,
      style: _voiceStyle,         // standard/jianghu/coach/toxic
    );
    // 缓存AI文案，下次播报时使用
    _cachedAIAdvice = advice;
  } catch (e) {
    // AI失败，静默降级，下次继续用规则文案
    _cachedAIAdvice = null;
  }
}
```

#### 三种跑步模式的 AI 增强逻辑

| 模式 | 现有播报内容 | AI增强侧重点 | Prompt上下文 |
|------|------------|-------------|-------------|
| **单独跑** | 配速/心率/步频 + 历史对比 + 鼓励 | 个性化分析 + 精准鼓励 | 用户历史数据、天气、目标 |
| **伴跑** | 三段式：当前数据→对手对比→幻影模式 | 对手分析 + 学习建议 + 战术指导 | 双方分段数据、连续趋势、幻影模式类型 |
| **挑战跑** | 选中指标对比 + 累计时间差 + 追赶趋势 | 赛况解读 + 策略建议 + 心理激励 | 双方累计差、剩余距离、节奏变化 |

#### AI 教练 Prompt 设计

**单独跑 Prompt：**
```
你是一位专业的跑步教练，正在指导一位跑者完成今日训练。

当前跑步数据：
- 已跑距离：{distance} km
- 当前配速：{pace} min/km
- 平均配速：{avg_pace} min/km
- 心率：{heart_rate} bpm（最大心率约 {max_hr}）
- 步频：{cadence} spm
- 天气：{weather}，{temperature}°C

历史对比：
- 最近7天平均配速：{weekly_avg_pace}
- 比上次同距离跑步：{pace_diff}（快/慢/持平）

语音风格：{style}
- standard：简洁中性
- jianghu：修仙用语（里/丈/道心/修为）
- coach：专业指导（呼吸/跑姿/核心）
- toxic：调侃幽默（不严厉批评）

要求：
1. 不超过50字
2. 有针对性，不要泛泛鼓励
3. 如果配速/心率异常，明确指出调整建议
4. 只输出播报文本，不要其他格式
```

**伴跑 Prompt：**
```
你是跑步教练，正在指导一位跑者进行伴跑训练。

跑者数据：配速{my_pace}，心率{my_hr}，步频{my_cadence}
对手数据：配速{opp_pace}，心率{opp_hr}，步频{opp_cadence}

当前对比：
- 配速差异：{pace_diff}秒/公里（{leading_or_trailing}）
- 心率差异：{hr_diff} bpm
- 步频差异：{cadence_diff} spm
- 连续趋势：{trend}（连续{n}公里领先/落后）

幻影模式：{ghost_mode}
- 真实回放：累计差距{cumulative_gap}米
- 恒定配速：比目标{target_pace_diff}秒
- 领跑兔：兔子在前{rabbit_gap}米
- 龟兔赛跑：对手此段{tortoise_hare_status}
- 目标挑战：目标进度{goal_progress}%

语音风格：{style}
要求：不超过60字，结合对比数据给出学习建议或战术指导。
```

**挑战跑 Prompt：**
```
你是跑步教练，正在指导一位跑者进行挑战赛。

比赛状态：
- 比拼指标：{metric}（配速/心率/步频/步幅）
- 我方：{my_value}，对手：{opp_value}
- 累计时间差：{cumulative_gap}秒（领先/落后）
- 本段追赶：{delta}秒（追回/被拉开）
- 剩余距离：约{remaining_km}公里

语音风格：{style}
要求：不超过50字，像赛场教练一样解读赛况，给出策略。
```

#### 后端 API

```
POST /api/v1/ai/coach/advice
Headers: Authorization: Bearer {token}
Body:
{
  "run_id": "xxx",
  "mode": "solo",              // solo/companion/challenge
  "current_data": {
    "distance": 3.5,
    "pace": 520,
    "avg_pace": 530,
    "heart_rate": 165,
    "cadence": 175,
    "temperature": 28,
    "weather": "晴"
  },
  "history_data": {
    "weekly_avg_pace": 535,
    "last_run_pace": 540,
    "max_hr": 190
  },
  "opponent_data": {            // 伴跑/挑战跑时
    "pace": 515,
    "heart_rate": 158,
    "cadence": 180,
    "cumulative_gap": 12,
    "trend": "consecutive_3_wins"
  },
  "ghost_mode": "real_replay",  // 伴跑时
  "style": "jianghu"            // 语音风格
}

Response:
{
  "code": 0,
  "data": {
    "advice": "道友配速精进，较往日快了10秒，道心稳固！",
    "priority": "info",
    "category": "pace"
  }
}
```

---

### 3.2 AI跑后总结 — 改 `run_finish_page.dart`

#### 前端位置

在现有数据面板（距离/配速/心率/步频等）**下方**，新增 AI 总结卡片：

```
┌─────────────────────────────┐
│ ✨ AI 跑后总结    [励志 ▾]   │  ← 风格切换下拉
│                              │
│ 今天5公里配速稳定在5:10，     │  ← AI生成文案
│ 比上周进步了15秒！爬升30米   │
│ 也没掉速，状态火热🔥         │
│                              │
│ 亮点：配速提升 · 爬升能力强   │  ← AI提取亮点标签
│                              │
│ [🔄 换一个]  [📤 分享]       │  ← 操作按钮
└─────────────────────────────┘
```

#### 前端集成

```dart
// run_finish_page.dart

@override
void initState() {
  super.initState();
  _loadRunData();
  if (_aiSummaryEnabled) {
    _generateAISummary();  // 异步，不阻塞UI
  }
}

Future<void> _generateAISummary() async {
  setState(() => _aiLoading = true);
  try {
    final result = await _aiService.generateSummary(
      runId: widget.run!.id,
      style: _selectedStyle,  // motivational/humorous/data/literary
    );
    setState(() => _aiSummary = result);
  } finally {
    setState(() => _aiLoading = false);
  }
}
```

#### Prompt 设计

```
你是跑步达人，为这次跑步生成总结文案。

跑步数据：
- 距离：{distance} km，用时：{duration}
- 平均配速：{avg_pace} min/km，最佳配速：{best_pace}
- 消耗：{calories} kcal，爬升：{elevation} m
- 平均心率：{avg_hr} bpm，步频：{cadence} spm
- 天气：{weather} {temperature}°C

历史对比：
- 本周第{weekly_count}次跑，累计{weekly_dist}km
- 比上次配速：{pace_change}

风格：{style}
- 励志：充满正能量
- 幽默：调侃+鼓励
- 数据：专业分析，突出亮点
- 文艺：诗意表达

要求：
1. 不超过100字
2. 有温度，不要像机器
3. 可加跑步"黑话"（破风/配速党/PB）
4. 有PB重点提

输出JSON：
{
  "summary": "文案",
  "highlights": ["亮点1", "亮点2"],
  "encouragement": "一句鼓励"
}
```

#### 后端 API

```
POST /api/v1/ai/summary/generate
Body: { "run_id": "xxx", "style": "motivational" }
Response:
{
  "code": 0,
  "data": {
    "summary": "今天5公里配速稳定在5:10，比上周进步了15秒！🔥",
    "highlights": ["配速提升", "爬升能力强"],
    "encouragement": "保持这个势头，下次挑战10公里！"
  }
}
```

---

### 3.3 AI路线推荐 — 改 `route_square_page.dart`

#### 前端位置

Tab 栏从 `全部 | 附近` 变为 `全部 | 附近 | ✨AI推荐`

```
┌──────────────────────────────────┐
│ [全部] [附近] [✨AI推荐]          │
├──────────────────────────────────┤
│ 🏃 西湖环线    匹配度 92分        │
│ 5.2km · 江景 · 适合晨跑          │
│ "距离刚好，你上周跑过反馈好"      │
├──────────────────────────────────┤
│ 🏃 钱塘江边    匹配度 85分        │
│ 8.1km · 平坦 · 适合练配速        │
│ "配速友好，适合突破训练"          │
└──────────────────────────────────┘
```

#### 后端 API

```
GET /api/v1/ai/routes/recommend?lat={lat}&lng={lng}&limit=10
Response:
{
  "code": 0,
  "data": {
    "recommendations": [
      {
        "route": { ... },
        "score": 92,
        "reason": "距离刚好5km，配速友好，你上周跑过",
        "tips": "早上6-7点人少景美"
      }
    ]
  }
}
```

---

### 3.4 AI帮写评论 — 改 `post_detail_page.dart`

#### 前端位置

评论输入框旁新增"✨AI帮写"按钮，点击弹出 BottomSheet：

```
┌──────────────────────────────────┐
│ [写评论...]              [✨AI]  │
├──────────────────────────────────┤
│ 💬 "恭喜PB！配速进5太强了💪"     │  ← 点击直接填入
│ 💬 "大神带带我！下次一起跑？"    │
│ 💬 "羡慕！我还在5:30挣扎😭"     │
│ [🔄 换一批]                      │
└──────────────────────────────────┘
```

#### 后端 API

```
POST /api/v1/ai/social/generate-comment
Body: { "post_id": "xxx", "post_content": "...", "relationship": "friend" }
Response:
{
  "code": 0,
  "data": {
    "comments": ["恭喜PB！💪", "大神带带我！", "羡慕！😭"]
  }
}
```

---

### 3.5 AI找搭档 — 改 `companion_select_page.dart`

#### 前端位置

伴跑对手选择页，列表顶部新增推荐卡片：

```
┌──────────────────────────────────┐
│ ✨ AI推荐搭档                     │
│ 🏃 跑友小明  配速5:30 · 晨跑     │
│ "配速相近，都在西湖区，常跑5km"  │
│ [选择伴跑]                       │
├──────────────────────────────────┤
│ 其他跑友列表...（原有列表不变）   │
└──────────────────────────────────┘
```

#### 后端 API

```
POST /api/v1/ai/social/match-partner
Body: { "my_profile": { "avg_pace": 530, "usual_distance": 5, "available_time": ["06:00-07:00"] } }
Response:
{
  "code": 0,
  "data": {
    "matches": [
      { "user": {...}, "match_score": 88, "reason": "配速相近，晨跑，距离3km" }
    ]
  }
}
```

---

### 3.6 AI每日金句 — 改 `discover_page.dart`

#### 前端位置

发现页每日金句卡片样式不变，文案来源从语料库 → AI生成（降级回语料库）

```
┌──────────────────────────────────┐
│ 📅 每日金句                      │
│                                  │
│ "晨风微凉，正是出门好时候"       │  ← AI生成或语料库
│                           ✨AI   │  ← AI生成时显示，语料库时不显示
└──────────────────────────────────┘
```

#### AI 生成维度

| 维度 | 数据源 | 示例 |
|------|--------|------|
| 天气/温度 | 和风天气API | "晨风微凉，正是出门好时候" |
| 节气/节日 | 日历 | "今日立夏，万物并秀" |
| 用户跑量 | 近7天数据 | "本周已跑3次，保持住！" |
| 当前时段 | 系统时间 | 晨跑："新的一天，从脚步开始" |

#### Prompt 设计

```
为跑步App生成一条每日金句，显示在发现页。

上下文：
- 日期：{date}，{solar_term}（如有节气/节日）
- 天气：{city} {weather} {temperature}°C
- 时段：{time_of_day}（早晨/上午/下午/傍晚/夜晚）
- 用户近况：{user_status}（如：本周跑3次/最近3天没跑/刚PB）

要求：
1. 不超过30字
2. 有温度，不像鸡汤
3. 结合上下文，个性化
4. 只输出金句文本
```

#### 后端 API

```
GET /api/v1/ai/daily-quote
Response:
{
  "code": 0,
  "data": {
    "quote": "晨风微凉，正是出门好时候",
    "source": "ai",         // "ai" 或 "library"
    "context_tags": ["晨跑", "微凉"]
  }
}
```

**缓存策略**：同一用户同一天只请求一次AI，结果缓存24小时。

---

### 3.7 AI路线审核 — 改 `route_upload_page.dart`

#### 核心理念

用户上传路线到跑迹广场时，**先过规则审核，再过AI辅助**，确保：
1. **不重复** — 与已有路线去重
2. **命名规范** — 包含地名+距离，合理描述
3. **内容质量** — 描述有意义，不含违规内容

#### 审核流程

```
用户点击"上传到广场"
    ↓
【第1层：规则审核（即时，本地+后端）】
    ├── 命名格式检查 → 不通过则提示修改
    ├── 必填项检查 → 不通过则提示补充
    └── 基础去重检查（同城市+距离差<20%）→ 疑似重复则弹确认
    ↓ 通过
【第2层：AI辅助审核（异步，后端）】
    ├── AI命名优化建议 → 返回建议名称
    ├── AI描述生成 → 辅助写路线描述
    └── AI语义去重 → 深度相似度检测
    ↓
【第3层：管理端终审（后台）】
    └── 人工审核（可选，高风险路线）
    ↓
发布到广场
```

#### 规则审核 — 命名规范

**路线命名规则（硬性）：**

| 规则 | 说明 | 示例 |
|------|------|------|
| 必含地名 | 至少包含一个可识别的地名 | ✅ "西湖环线" ❌ "今日跑步" |
| 必含距离 | 包含公里数或距离描述 | ✅ "西湖5公里环线" ❌ "西湖环线" |
| 长度4-30字 | 不宜过短或过长 | ✅ 4-30字 |
| 禁止纯符号 | 不能只有表情/标点 | ❌ "🏃💨🔥" |
| 禁止重复提交 | 同一用户同一轨迹不重复上传 | 检测 user_id + 轨迹相似度 |

**AI 命名优化：** 当用户填的名称不符合规范时，AI基于轨迹数据建议一个规范名称：

```
你是跑步路线命名助手。根据以下信息生成3个路线名称建议。

路线信息：
- 轨迹起点/终点：{start_address} → {end_address}
- 途经地标：{landmarks}（从轨迹点逆地理编码获取）
- 总距离：{distance} km
- 城市区域：{city} {district}
- 累计爬升：{elevation} m

命名要求：
1. 格式：地名+特征+距离（如"西湖湖滨5公里环线"）
2. 简洁明了，一看就知道在哪跑
3. 如果有明显地标（桥/公园/江边），要体现
4. 3个选项，风格各异

输出JSON：
{
  "suggestions": [
    {"name": "西湖湖滨5公里环线", "reason": "起点西湖湖滨，5km环形"},
    {"name": "断桥-苏堤5公里晨跑线", "reason": "途经断桥苏堤两大地标"},
    {"name": "西湖北线5公里轻跑", "reason": "北线平坦适合轻松跑"}
  ]
}
```

#### 规则审核 — 去重检测

**轻量去重（即时，上传时检查）：**

```go
// 同城市 + 距离差 < 20% 的路线，快速筛选候选
func QuickDuplicateCheck(route Route) ([]Route, error) {
    var candidates []Route
    db.Where("city = ? AND ABS(distance - ?) / ? < 0.2 AND deleted_at IS NULL",
        route.City, route.Distance, route.Distance).
        Find(&candidates)
    return candidates, nil
}
```

**深度去重（AI辅助，异步）：**

```
你是路线去重分析师。判断两条路线是否为重复路线。

路线A：{route_a_name}，{route_a_distance}km，途经{route_a_landmarks}
路线B：{route_b_name}，{route_b_distance}km，途经{route_b_landmarks}

轨迹相似度（算法计算）：{similarity}%

判断标准：
- 同一区域 + 距离接近 + 途经相似地标 → 可能重复
- 方向不同/起点终点不同 → 可能不重复

输出JSON：
{
  "is_duplicate": true/false,
  "confidence": 0.85,
  "reason": "两条路线都在西湖周边，距离接近，途经苏堤白堤，高度相似"
}
```

#### 前端交互

```dart
// route_upload_page.dart — 上传提交时的审核流程

Future<void> _submitToSquare() async {
  // 1. 本地规则检查（即时）
  final ruleResult = _checkNamingRules(_routeName);
  if (!ruleResult.passed) {
    _showRuleWarning(ruleResult);  // 弹出修改提示
    return;
  }
  
  // 2. 后端快速去重检查
  final dupCheck = await _api.quickDuplicateCheck(widget.route);
  if (dupCheck.hasSimilar) {
    // 弹出确认：发现相似路线，是否继续？
    final confirm = await _showDuplicateConfirm(dupCheck.similarRoutes);
    if (!confirm) return;
  }
  
  // 3. AI命名建议（如果名称质量不高）
  if (_needsNameSuggestion) {
    final suggestions = await _api.getAISuggestedNames(widget.route);
    if (suggestions != null && suggestions.isNotEmpty) {
      _showNameSuggestionSheet(suggestions);  // 弹出AI建议
      return;  // 用户选择后再次提交
    }
  }
  
  // 4. 提交
  await _api.uploadRouteToSquare(widget.route);
  _showSuccess();
}
```

**AI 命名建议 BottomSheet：**

```
┌──────────────────────────────────┐
│ ✨ AI 建议路线名称                │
│                                  │
│ 你的名称："今日跑步路线"          │
│ 建议选择一个更规范的名称：        │
│                                  │
│ ○ 西湖湖滨5公里环线               │
│   起点：西湖湖滨，5km环形路线     │
│                                  │
│ ○ 断桥-苏堤5公里晨跑线           │
│   途经断桥苏堤两大地标            │
│                                  │
│ ○ 西湖北线5公里轻跑              │
│   北线平坦适合轻松跑              │
│                                  │
│ [使用选中的]  [保留原名称]        │
└──────────────────────────────────┘
```

#### 后端 API

```
// 快速去重检查
POST /api/v1/ai/route/duplicate-check
Body: { "route_id": "xxx", "name": "...", "distance": 5200, "city": "杭州" }
Response:
{
  "code": 0,
  "data": {
    "has_similar": true,
    "similar_routes": [
      { "id": "yyy", "name": "西湖环线", "distance": 5.1, "similarity": 85 }
    ]
  }
}

// AI命名建议
POST /api/v1/ai/route/suggest-names
Body: { "route_id": "xxx" }
Response:
{
  "code": 0,
  "data": {
    "suggestions": [
      { "name": "西湖湖滨5公里环线", "reason": "起点西湖湖滨，5km环形" },
      { "name": "断桥-苏堤5公里晨跑线", "reason": "途经断桥苏堤" },
      { "name": "西湖北线5公里轻跑", "reason": "北线平坦" }
    ]
  }
}

// AI描述生成
POST /api/v1/ai/route/generate-description
Body: { "route_id": "xxx" }
Response:
{
  "code": 0,
  "data": {
    "description": "沿西湖湖北岸而行，途经断桥、白堤、苏堤，平路为主，"
  }
}
```

---

### 3.8 AI功能开关 — 改 `settings_page.dart`

#### 前端位置

```
设置
├── 账号与安全
├── 通知设置
├── ✨ AI 智能功能          ← 新增分组
│   ├── AI跑步教练  [开关]
│   ├── AI跑后总结  [开关]
│   ├── AI路线推荐  [开关]
│   ├── AI帮写评论  [开关]
│   ├── AI每日金句  [开关]
│   └── 数据使用说明  ⓘ     ← 点击查看AI数据使用隐私说明
├── 隐私设置
└── 关于
```

**开关状态同步**：设置变更后，同步到后端用户配置表，AI请求前先检查开关状态。

---

## 4. 管理端 AI 配置详细设计

### 4.1 功能配置页 `ai/feature-config.vue`

全局管控每个AI功能的启用/禁用和模型选择：

```
┌─────────────────────────────────────────────────────────┐
│ AI 功能配置                                              │
├──────────┬──────────┬──────────────┬─────────┬──────────┤
│ 功能      │ 启用状态  │ 使用模型      │ 调用密钥 │ 日限额   │
├──────────┼──────────┼──────────────┼─────────┼──────────┤
│ AI跑步教练│ [开关✓]  │ deepseek-chat│ sk-..3X │ 1000次/日│
│ AI跑后总结│ [开关✓]  │ moonshot-v1  │ sk-..7Y │ 500次/日 │
│ AI路线推荐│ [开关✓]  │ qwen-turbo   │ sk-..2Z │ 800次/日 │
│ AI帮写评论│ [开关✓]  │ deepseek-chat│ sk-..3X │ 2000次/日│
│ AI找搭档  │ [开关✓]  │ deepseek-chat│ sk-..3X │ 500次/日 │
│ AI每日金句│ [开关✓]  │ qwen-turbo   │ sk-..2Z │ 100次/日 │
│ AI路线审核│ [开关✓]  │ deepseek-chat│ sk-..3X │ 无限     │
└──────────┴──────────┴──────────────┴─────────┴──────────┘
```

### 4.2 教练模板页 `ai/coach-template.vue`

编辑各跑步模式的 Prompt 模板：

```
跑步模式：[单独跑 ▾]   语音风格：[江湖风 ▾]

Prompt模板：
┌──────────────────────────────────────────────┐
│ 你是一位专业的跑步教练，正在指导一位跑者...    │  ← 可编辑的文本区域
│                                              │
│ 变量插入：{distance} {pace} {heart_rate}...   │  ← 点击插入变量
└──────────────────────────────────────────────┘

[预览效果]  [保存]
```

### 4.3 总结模板页 `ai/summary-template.vue`

管理4种风格的 Prompt + 默认总结模板：

```
风格：[励志 ▾]

励志风格 Prompt：
┌──────────────────────────────────────────────┐
│ 充满正能量，鼓励继续坚持...                     │
└──────────────────────────────────────────────┘

降级模板（AI不可用时使用）：
┌──────────────────────────────────────────────┐
│ 恭喜完成{distance}公里跑步！平均配速{pace}     │
└──────────────────────────────────────────────┘
```

### 4.4 审核规则配置页 `ai/moderation-config.vue`

```
路线命名规则：
┌──────────────────────────────────────────────┐
│ ✅ 必须包含地名          [开启]               │
│ ✅ 必须包含距离          [开启]               │
│ ✅ 名称长度4-30字        [开启]               │
│ ❌ 允许纯英文命名        [关闭]               │
│                                              │
│ 地名识别词典：                                │
│ [西湖] [钱塘江] [断桥] [苏堤] ...  [+添加]   │
│                                              │
│ AI命名建议：[开启]                            │
│ AI描述生成：[开启]                            │
└──────────────────────────────────────────────┘

去重规则：
┌──────────────────────────────────────────────┐
│ 快速去重距离容差：[20]%                       │
│ 深度去重相似度阈值：[70]%                     │
│ AI辅助去重：[开启]                            │
│ 同一用户同一轨迹：[禁止重复上传]               │
└──────────────────────────────────────────────┘

动态审核规则：
┌──────────────────────────────────────────────┐
│ 敏感词库：[导入] [编辑]                       │
│ 广告检测：[开启]                              │
│ 自动通过阈值：AI评分 ≥ [80] 分                │
│ 自动拒绝阈值：AI评分 ≤ [30] 分                │
└──────────────────────────────────────────────┘
```

### 4.5 管理端新增表

> **⚠️ 待定**：此表尚未创建。当前用 `ai_api_keys.is_active` + `usage_scope` 控制功能启禁即可满足需求。待管理端配置页开发时再决定是否建此表。需求文档见 `docs/admin_ai_feature_config_requirements.md`。

```sql
-- AI功能配置表（管理端专用，待定）
CREATE TABLE IF NOT EXISTS `ai_feature_configs` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `feature_key`     VARCHAR(50) NOT NULL UNIQUE COMMENT '功能键: run_coach/post_summary/route_recommend/social_comment/partner_match/daily_quote/route_review',
    `feature_name`    VARCHAR(100) NOT NULL COMMENT '功能名称',
    `enabled`         TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    `api_key_id`      BIGINT COMMENT '关联ai_api_keys.id',
    `model_override`  VARCHAR(100) COMMENT '模型覆盖（空则用密钥默认）',
    `daily_limit`     INT DEFAULT 0 COMMENT '日限额（0=不限）',
    `fallback_mode`   VARCHAR(20) DEFAULT 'rule' COMMENT '降级模式: rule/template/off',
    `prompt_template` TEXT COMMENT '默认Prompt模板',
    `config_json`     JSON COMMENT '功能特有配置（如命名规则、去重阈值）',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_key` (`feature_key`),
    CONSTRAINT `fk_feature_apikey` FOREIGN KEY (`api_key_id`) REFERENCES `ai_api_keys`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI功能配置';

-- 初始化数据
INSERT INTO ai_feature_configs
(feature_key, feature_name, enabled, model_override, daily_limit, fallback_mode, config_json)
VALUES
('run_coach',      'AI跑步教练', 1, 'deepseek-chat', 1000, 'rule', '{}'),
('post_summary',   'AI跑后总结', 1, 'moonshot-v1',   500,  'template', '{"styles":["motivational","humorous","data","literary"]}'),
('route_recommend','AI路线推荐', 1, 'qwen-turbo',    800,  'rule', '{"weights":{"distance":0.3,"difficulty":0.2,"preference":0.3,"time":0.2}}'),
('social_comment', 'AI帮写评论', 1, 'deepseek-chat', 2000, 'off', '{"max_length":30}'),
('partner_match',  'AI找搭档',   1, 'deepseek-chat', 500,  'rule', '{}'),
('daily_quote',    'AI每日金句', 1, 'qwen-turbo',    100,  'template', '{}'),
('route_review',   'AI路线审核', 1, 'deepseek-chat', 0,    'rule', '{"naming":{"require_place":true,"require_distance":true,"min_length":4,"max_length":30},"dedup":{"distance_tolerance":0.2,"similarity_threshold":0.7}}');
```

---

## 5. 降级策略

**核心原则：AI挂了/关了，现有功能完全不受影响。**

| 功能 | AI不可用时的降级方案 | 用户感知 |
|------|-------------------|---------|
| AI跑步教练 | 使用现有规则播报（`_buildSoloText`等） | 无感知，正常播报 |
| AI跑后总结 | 使用模板文案（"恭喜完成X公里！"） | 看到简单模板文案 |
| AI路线推荐 | 不显示"AI推荐"Tab，或Tab内显示"暂不可用" | 少一个Tab |
| AI帮写评论 | 不显示"AI帮写"按钮 | 少一个按钮 |
| AI找搭档 | 不显示AI推荐卡片 | 正常选择对手 |
| AI每日金句 | 使用语料库随机金句 | 无感知 |
| AI路线审核 | 只走规则审核，跳过AI命名建议和深度去重 | 可能有重复路线，人工补审 |

---

## 6. 数据流与缓存

### 6.1 AI请求优先级

```
1. App端检查AI功能开关（本地缓存）
   → 关闭 → 不请求
   → 开启 → 继续

2. Go后端检查 VIP 权限（users.is_vip > 0）
   → 非VIP → 返回"需要开通VIP"提示
   → VIP → 继续

3. Go后端检查 ai_api_keys.is_active
   → 禁用 → 返回降级数据
   → 启用 → 继续

4. Go后端检查日限额（ai_api_keys.daily_limit）
   → 超限 → 返回降级数据 + 记录超限日志
   → 未超 → 调用AI

> **注**：`ai_feature_configs` 表待定，当前用 `ai_api_keys` 的 `is_active` + `usage_scope` 控制功能启禁。

4. 调用AI
   → 成功 → 返回AI数据 + 写ai_call_logs
   → 超时(3s) → 返回降级数据
   → 失败 → 返回降级数据 + 记录错误日志
```

### 6.2 缓存策略

| 功能 | 缓存方式 | 缓存时间 | 命中条件 |
|------|---------|---------|---------|
| AI跑步教练 | Redis，按run_id+split_index | 10分钟 | 同一次跑步同一公里段 |
| AI跑后总结 | Redis，按run_id | 1小时 | 同一次跑步 |
| AI路线推荐 | Redis，按user_id+位置网格 | 1小时 | 1km内位置变化 |
| AI帮写评论 | 不缓存 | - | 每次重新生成 |
| AI找搭档 | Redis，按user_id | 24小时 | - |
| AI每日金句 | Redis，按user_id+date | 24小时 | 同一天同一用户 |
| AI命名建议 | Redis，按route_id | 30分钟 | - |

---

## 7. 实施优先级与详细排期

### 7.1 优先级判定依据

| 维度 | 权重 | 说明 |
|------|------|------|
| 用户感知度 | 40% | 跑完就能看到 vs 跑步中才触发 |
| 传播价值 | 25% | 能否引发分享和传播 |
| 技术复杂度 | 20% | 独立性、依赖少优先 |
| 运营价值 | 15% | 内容质量、社区健康 |

### 7.2 功能优先级排序

| 优先级 | 功能 | 理由 |
|--------|------|------|
| **P0-A** | AI跑情分析 | 翻历史记录时自然查看；结合历史数据有参照价值；值得截图分享；技术最简单（无实时性要求） |
| **P0-B** | AI功能开关 + 基础设施 | 所有AI功能的前置依赖；AIService框架、配置加载、降级机制 |
| **P1-A** | AI路线审核（规则部分） | 跑迹广场内容质量的保障，规则审核可独立运行不依赖AI |
| **P1-B** | AI跑步教练 | 核心差异化功能，但依赖播报系统稳定，需更多Prompt调优 |
| **P1-C** | AI路线审核（AI部分） | 在规则审核基础上叠加AI命名建议和深度去重 |
| **P2-A** | AI每日金句 | 实现简单，但感知较弱；可与P1阶段并行 |
| **P2-B** | AI路线推荐 | 需要足够路线数据支撑，推荐才有意义 |
| **P3-A** | AI帮写评论 | 社交增强，非核心 |
| **P3-B** | AI找搭档 | 依赖伴跑功能用户量，优先级最低 |

### 7.3 分阶段详细排期

---

#### 🏗️ 第0阶段：基础设施（3天）

> **目标**：搭好AI服务的骨架，后续功能往里填就行

| 天 | 任务 | 产出 | 依赖 |
|----|------|------|------|
| D1 | 数据库：`ai_api_keys.usage_scope` 扩展7个值（`ai_feature_configs` 表待定） | SQL脚本 | 无 |
| D1 | 后端：`AIService` 统一入口（配置加载 + 密钥获取 + 调用 + 降级 + 日志） | `ai_service.go` | 无 |
| D2 | 后端：Go端配置缓存（Redis 10分钟）+ ai_call_logs 写入回调 | 缓存+日志机制 | D1 |
| D2 | 前端：`ai_service.dart` 统一调用服务（开关检查 + 超时3s + 错误静默） | `ai_service.dart` | 无 |
| D3 | 前端：`settings_page.dart` 新增"AI智能功能"开关分组 | 设置页改完 | D2 |
| D3 | 注册DeepSeek API Key，端到端验证调用链 | 验证通过 | D2 |

**验收标准**：设置页能开关AI功能，App调用AIService能成功拿到AI响应，AI关闭时降级数据正常返回

---

#### ⭐ 第1阶段：AI跑情分析（3天）

> **目标**：用户在跑步详情页看到有历史参照的跑情分析报告，有洞察有建议，值得截图分享

> **前置说明**：从「跑完弹出」改为「运动记录 → 跑步详情页查看」。用户跑完累了不会马上看，但翻历史记录时会很自然地点开。分析结合个人历史成绩+跑境（天气/地形/时段/跑步等级），给出有参照的洞察。

| 天 | 任务 | 产出 | 依赖 |
|----|------|------|------|
| D1 | 后端：`ai_run_analysis.go` 实现 + `/api/v1/ai/run-analysis` API | API完成 | 第0阶段 |
| D1 | 后端：历史数据拉取（近30天均速、个人最佳、去年同期）+ 跑境归因数据接口 | 数据接口 | 无 |
| D1 | Prompt编写：5块内容（本次点评+历史对比+跑境解读+亮点捕捉+训练建议） | Prompt v1 | 无 |
| D2 | 前端：跑步详情页底部新增「AI跑情分析」卡片（展开/收起+刷新+分享） | 卡片UI | D1 |
| D2 | 前端：详情页操作栏三个按钮：「发跑友动态」「收藏我的跑迹」「AI跑情分析」 | 操作栏 | D1 |
| D3 | 联调测试 + Prompt调优（拿10组不同跑步数据实测输出质量） | 可发布 | D2 |

**AI跑情分析卡片内容**：
1. 本次表现点评 — 配速/心率在个人历史中的位置（"这次排进历史前20%"）；道祖级→配速与全球顶尖选手对照；天君级→配速趋势分析；元婴级→半马/全马配速综合评价；筑基/炼气/凡人→距离成就为主（"你的5km比上次快X秒，继续！"）
2. 与历史对比 — vs 个人最佳 / vs 近30天平均（数据不足时对比区间自动收缩，比如只有10条记录就对比最近5条）
3. 跑境解读 — 结合天气（高温/低温/下雨）、地形（爬升）、时段（晨跑/夜跑）、跑步等级（道祖/天君/元婴等）综合分析对成绩的影响；建议内容因等级而异：道祖级→极简专业无废话，天君级→技术分析为主，元婴级→平衡鼓励与技术，筑基/炼气/凡人级→鼓励为主（每句话都有正面反馈）
4. 亮点捕捉 — 自动找出突破点（配速新低/距离新长/心率新稳）
5. 训练建议 — 基于历史数据给出下一阶段建议；道祖级仅给数据对比不加建议（世界顶流不需指导）；天君级→极简技术对比；元婴级→技术分析+一句可操作提示；筑基/炼气/凡人→鼓励为主（每句话都有正面反馈）

> **注**：数据不足时自动降级对比范围（无去年数据→对比全部历史；历史不足10条→对比最近5条；不足3条→仅展示本次数据不做对比）。

**验收标准**：在跑步详情页看到AI跑情分析，与历史数据对比有参照意义，能分享

**v2.3 实现状态**：
- ✅ 后端 API 已完成（`/api/v1/ai/run-analysis`）
- ✅ 前端卡片UI已完成
- ✅ VIP判断逻辑已完成（isVip > 0）
- ✅ 路面类型增强已完成（5种路面：大马路/绿道/坡道/跑道/河边）
- ✅ 爬升下降增强已完成（elevationTip）
- ✅ Prompt v1 已完成（5块内容）
- ✅ 历史数据接口已完成（近30天均速、个人最佳）

---

#### 🛡️ 第2阶段：AI路线审核 — 规则部分（3天）

> **目标**：先上规则审核，不含AI，保障广场内容质量

| 天 | 任务 | 产出 | 依赖 |
|----|------|------|------|
| D1 | 后端：路线命名规则校验（必含地名+距离+长度4-30字+禁止纯符号） | 校验API | 无 |
| D1 | 后端：快速去重检查（同城市+距离差<20%查询候选） | 去重API | 无 |
| D2 | 前端：`route_upload_page.dart` 提交时规则校验 + 不通过提示 | 校验交互 | D1 |
| D2 | 前端：疑似重复弹确认（"发现相似路线，是否继续？"） | 去重交互 | D1 |
| D3 | 本地地名词典（常用城市地标初始词库100+）+ 测试 | 词典+测试 | D2 |

**验收标准**：命名不规范的路线被拦截，重复路线弹确认，规范路线正常发布

---

#### 🏃 第3阶段：AI跑步教练（5天）

> **目标**：跑步中AI实时指导，这是最核心的差异化功能

| 天 | 任务 | 产出 | 依赖 |
|----|------|------|------|
| D1 | 后端：`ai_coach.go` 实现 + `/api/v1/ai/coach/advice` API | API完成 | 第0阶段 |
| D1 | Prompt编写：3种模式 × 4种风格 = 12套Prompt模板 | Prompt v1 | 无 |
| D2 | 前端：修改 `voice_broadcast_service.dart`，加AI增强层 | 增强层完成 | D1 |
| D2 | 前端：单独跑AI教练对接 + 降级测试 | 单独跑OK | D1 |
| D3 | 前端：伴跑AI教练对接（三段式数据+对手对比） | 伴跑OK | D2 |
| D3 | 前端：挑战跑AI教练对接（赛况解读+策略建议） | 挑战跑OK | D2 |
| D4 | AI文案缓存机制（同一公里段不重复请求）+ 异步预加载 | 缓存+预加载 | D3 |
| D5 | 全模式联调 + Prompt调优（每种模式至少跑5次验证） | 可发布 | D4 |

**验收标准**：三种模式下AI教练正常播报，4种风格输出语气正确，AI超时/失败时无缝回退规则播报

---

#### ✨ 第4阶段：AI路线审核 — AI部分 + AI每日金句（3天）

> **目标**：规则审核基础上叠加AI能力；顺手把每日金句也做了（简单）

| 天 | 任务 | 产出 | 依赖 |
|----|------|------|------|
| D1 | 后端：AI命名建议 `/api/v1/ai/route/suggest-names` | API完成 | 第0阶段 |
| D1 | 后端：AI描述生成 `/api/v1/ai/route/generate-description` | API完成 | 第0阶段 |
| D1 | 后端：AI深度去重（语义相似度判断） | API完成 | 第2阶段 |
| D2 | 前端：`route_upload_page.dart` AI命名建议BottomSheet + AI描述辅助 | UI完成 | D1 |
| D2 | 后端：AI每日金句 `/api/v1/ai/daily-quote` + 24h缓存 | API完成 | 第0阶段 |
| D3 | 前端：`discover_page.dart` 金句AI增强 + AI标识 | UI完成 | D2 |
| D3 | 联调测试 | 可发布 | D3 |

**验收标准**：上传路线时AI建议名称规范，金句每日更新且AI来源有标识

---

#### 🗺️ 第5阶段：AI路线推荐（4天）

> **目标**：路线广场AI推荐Tab

| 天 | 任务 | 产出 | 依赖 |
|----|------|------|------|
| D1 | 后端：`ai_route.go` 推荐算法（距离匹配+难度适配+偏好匹配+时段适配） | 推荐算法 | 第0阶段 |
| D2 | 后端：`/api/v1/ai/routes/recommend` API + 位置缓存 | API完成 | D1 |
| D2 | Prompt编写：路线推荐理由生成 | Prompt v1 | 无 |
| D3 | 前端：`route_square_page.dart` 新增"AI推荐"Tab + 推荐卡片UI | Tab完成 | D2 |
| D4 | 联调 + 推荐质量验证（至少验证10个不同用户画像的推荐结果） | 可发布 | D3 |

**验收标准**：AI推荐Tab显示个性化路线，推荐理由合理，位置变化后推荐更新

---

#### 💬 第6阶段：AI社交功能（4天）

> **目标**：AI帮写评论 + AI找搭档

| 天 | 任务 | 产出 | 依赖 |
|----|------|------|------|
| D1 | 后端：AI帮写评论 `/api/v1/ai/social/generate-comment` | API完成 | 第0阶段 |
| D1 | 后端：AI找搭档 `/api/v1/ai/social/match-partner` | API完成 | 第0阶段 |
| D2 | 前端：`post_detail_page.dart` "AI帮写"按钮 + BottomSheet 3条候选 | UI完成 | D1 |
| D3 | 前端：`companion_select_page.dart` 顶部AI推荐搭档卡片 | UI完成 | D1 |
| D4 | 联调 + 评论质量验证 + 搭档匹配合理性验证 | 可发布 | D3 |

**验收标准**：AI评论走心不尴尬，搭档匹配配速相近

---

#### ⚙️ 第7阶段：管理端AI配置 + 上线（5天）

> **目标**：管理端AI配置页面全部完成，全功能上线

| 天 | 任务 | 产出 | 依赖 |
|----|------|------|------|
| D1 | 管理端：`ai/feature-config.vue` 功能配置页（全局开关+模型选择+日限额） | 配置页 | 第0阶段 |
| D2 | 管理端：`ai/coach-template.vue` 教练模板页 + `ai/summary-template.vue` 总结模板页 | 模板页 | D1 |
| D2 | 管理端：`ai/moderation-config.vue` 审核规则配置页 | 配置页 | D1 |
| D3 | 管理端：`ai/comment-config.vue` + `ai/recommend-config.vue` + `ai/daily-quote-template.vue` | 配置页 | D1 |
| D4 | 全功能集成测试（每个功能的开启/关闭/降级/缓存/日志链路验证） | 测试通过 | D3 |
| D5 | 线上部署 + 灰度发布（先对10%用户开放AI功能） | 上线 | D4 |

**验收标准**：管理端可控制所有AI功能开关，修改Prompt即时生效，调用日志准确

---

### 7.4 总排期概览

#### VIP 分级设计（v2.3 新增）

**VIP 与 AI 功能的关系**：AI功能为VIP专属，非VIP用户（`is_vip = 0`）无法使用。VIP等级1-5为预留等级，当前所有VIP等级享受相同的AI功能权限。

| is_vip | 身份 | AI功能权限 |
|--------|------|----------|
| 0 | 普通用户 | ❌ 不可用，显示"开通VIP解锁" |
| 1-5 | VIP用户 | ✅ 全部可用 |

**判断逻辑**：`is_vip > 0` 即为VIP，不需要判断具体等级。

```
第0阶段  基础设施        ███░░░░░░░░░░░░░░░░░░  3天
第1阶段  AI跑后总结      ░░░███░░░░░░░░░░░░░░░  3天
第2阶段  路线审核(规则)   ░░░░░░███░░░░░░░░░░░░  3天
第3阶段  AI跑步教练      ░░░░░░░░░█████░░░░░░░  5天
第4阶段  审核AI+金句     ░░░░░░░░░░░░░░███░░░░  3天
第5阶段  AI路线推荐      ░░░░░░░░░░░░░░░░░████  4天
第6阶段  AI社交功能      ░░░░░░░░░░░░░░░░░░░░░  4天（可与5并行）
第7阶段  管理端+上线     ░░░░░░░░░░░░░░░░░░░░░  5天
                                              ──
                                    总计约 30天（6周）
```

> **注**：第5、6阶段可并行开发（不同人/不同分支），并行后可压缩到约5周

### 7.5 里程碑与交付物

| 里程碑 | 时间 | 交付物 | 用户可感知 |
|--------|------|--------|-----------|
| M1 基础可用 | 第1周 | AI跑情分析上线 | ✅ 翻历史记录看到有参照的跑情分析，可分享 |
| M2 内容保障 | 第2周 | 路线规则审核上线 | ✅ 广场路线质量提升 |
| M3 核心差异化 | 第3-4周 | AI跑步教练上线 | ✅ 跑步中AI语音指导 |
| M4 体验增强 | 第4-5周 | AI审核+金句+推荐上线 | ✅ 多处AI增强体验 |
| M5 社交增强 | 第5-6周 | AI评论+搭档上线 | ✅ 社交互动AI辅助 |
| M6 正式上线 | 第6周 | 管理端完善+灰度→全量 | ✅ 全功能可用 |

### 7.6 风险与应对

| 风险 | 概率 | 影响 | 应对 |
|------|------|------|------|
| DeepSeek API不稳定 | 中 | AI功能不可用 | 降级机制兜底；备用Kimi/Qwen密钥 |
| Prompt质量不达标 | 高 | AI输出不理想 | 每个功能预留调优时间；管理端可改Prompt |
| 跑步教练延迟高 | 中 | 播报不及时 | 先播规则文案，AI返回后缓存下段使用 |
| 路线数据不足 | 低 | 推荐无内容 | P2阶段再上推荐，等数据积累 |
| 管理端开发延后 | 低 | 配置只能改数据库 | M6前完成即可，不影响App端功能 |

---

## 8. 成本预估

以 DeepSeek-Chat 为例（¥0.001/1K tokens），日活1万用户：

| 功能 | 单次tokens | 日调用量 | 月成本 |
|------|-----------|---------|--------|
| AI跑步教练 | ~300 | 5万 | ¥15 |
| AI跑后总结 | ~500 | 1万 | ¥5 |
| AI路线推荐 | ~800 | 2万 | ¥16 |
| AI帮写评论 | ~400 | 1万 | ¥4 |
| AI找搭档 | ~500 | 3000 | ¥1.5 |
| AI每日金句 | ~200 | 1万 | ¥2 |
| AI路线审核 | ~600 | 2000 | ¥1.2 |
| **合计** | - | - | **¥45/月** |

> 实际更低：大量请求可缓存命中，降级场景不调AI

---

## 9. 与现有系统的融合清单

### 9.1 复用管理端已有设计

| 已有设计 | 复用方式 |
|---------|---------|
| `ai_api_keys` 表 | AI密钥管理，`usage_scope` 扩展 |
| `ai_call_logs` 表 | AI调用日志 |
| `AiKeyController` | 密钥CRUD + 轮换 + 启禁 |
| 菜单权限树 | AI服务管理目录下扩展子菜单 |
| Go后端对接接口 | 配置拉取 + 日志回调 |

### 9.2 复用语音播报系统

| 已有设计 | AI融合方式 |
|---------|-----------|
| `_buildBroadcastText(state)` | AI作为增强层，保留规则降级 |
| 4种语音风格 | AI Prompt按风格生成 |
| 三种跑步模式分流 | 各模式独立AI Prompt |
| TTS播报 | AI文案直接走现有TTS |

### 9.3 复用路线去重算法

| 已有设计 | AI融合方式 |
|---------|-----------|
| `RouteMatcherService`（Hausdorff距离） | 上传时轻量去重用此算法 |
| `duplicate_groups` 表 | AI深度去重结果也写此表 |
| 管理端重复路线页面 | 统一展示和管理 |

---

*文档编写：大衍神君*  
*版本：v2.3 — VIP分级设计、VIP+AI联动、Phase 1实现状态*  
*最后更新：2026-05-12*
