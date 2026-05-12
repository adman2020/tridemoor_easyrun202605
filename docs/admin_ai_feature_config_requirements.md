# 管理端 AI 功能配置页 — 需求文档

> **版本**: v2.5
> **日期**: 2026-05-12
> **作者**: 大衍神君
> **状态**: ✅ 已实现（feature_key 与 Go handler 对齐）

---

## 1. 页面位置

**AI服务管理 → 功能配置**（管理端）

---

## 2. 页面结构

```
┌───────────────────────────────────────────────────────────────────┐
│ AI 功能配置                                                       │
├──────────┬────────┬──────────────┬──────────┬──────────┬─────────┤
│ 功能      │ 启用    │ 使用模型      │ 调用密钥   │ 日限额     │ 今日调用 │
├──────────┼────────┼──────────────┼──────────┼──────────┼─────────┤
│ AI跑情分析 │ [开关✓]│ deepseek…    │ StrideMoo│ 1000次/日 │ 0次     │
│ AI跑步教练 │ [开关✓]│ 自动          │ 自动      │ 1000次/日 │ 0次     │
│ AI跑后总结 │ [开关✓]│ 自动          │ 自动      │ 1000次/日 │ 0次     │
│ AI路线推荐 │ [开关✓]│ 自动          │ 自动      │ 800次/日  │ 0次     │
│ AI帮写评论 │ [开关✓]│ 自动          │ 自动      │ 2000次/日 │ 0次     │
│ AI找搭档   │ [开关✓]│ 自动          │ 自动      │ 500次/日  │ 0次     │
│ AI每日金句 │ [开关✓]│ 自动          │ 自动      │ 100次/日  │ 0次     │
│ AI路线审核 │ [开关✓]│ 自动          │ 自动      │ 无限      │ 0次     │
└──────────┴────────┴──────────────┴──────────┴──────────┴─────────┘
```

---

## 3. 字段说明

| 字段 | 类型 | 是否必填 | 说明 |
|------|------|---------|------|
| 功能名称 | 文本 | - | 固定8个功能，不可增删 |
| 启用状态 | 开关 | 是 | 启用/禁用，禁用后该功能不可用 |
| 使用模型 | 下拉选择 | 否 | 从 `ai_api_keys` 表读取可用模型，可覆盖密钥默认模型 |
| 调用密钥 | 下拉选择 | 否 | 从 `ai_api_keys` 表读取，关联 `api_key_id` |
| 日限额 | 数字输入 | 是 | 0 = 不限，超过限额返回降级数据 |
| 今日调用 | 只读 | - | 实时显示 `today_calls`，每日午夜自动重置 |

---

## 4. 交互逻辑

### 4.1 启用开关
- **关闭** → 该功能在 App 端不可用，返回"功能已关闭"提示
- **开启** → 正常调用 AI

### 4.2 模型选择
- 默认使用关联密钥的 `model` 字段
- 可下拉选择其他模型覆盖（存 `model_override` 字段）
- 下拉数据源：`SELECT DISTINCT model FROM ai_api_keys WHERE is_active = 1`

### 4.3 调用密钥
- 下拉数据源：`SELECT id, name, model FROM ai_api_keys WHERE is_active = 1`
- 选择后关联 `api_key_id`
- 当前已配置密钥：**StrideMoor**（DeepSeek）

### 4.4 日限额
- 超过限额 → 返回降级数据 + 记录超限日志
- 0 = 不限

### 4.5 今日调用
- 只读，显示 `today_calls` 字段值
- 每日午夜自动重置为 0（通过 `last_reset` 日期判断）

---

## 5. 数据表

### 5.1 `ai_feature_configs` 表（✅ 已创建）

```sql
CREATE TABLE IF NOT EXISTS `ai_feature_configs` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `feature_key`     VARCHAR(50) NOT NULL UNIQUE COMMENT '功能键（与Go handler对齐）',
    `feature_name`    VARCHAR(100) NOT NULL COMMENT '功能名称',
    `enabled`         TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    `api_key_id`      BIGINT COMMENT '关联ai_api_keys.id',
    `model_override`  VARCHAR(100) COMMENT '模型覆盖（空则用密钥默认）',
    `daily_limit`     INT DEFAULT 0 COMMENT '日限额（0=不限）',
    `today_calls`     INT DEFAULT 0 COMMENT '今日调用次数',
    `last_reset`      DATE COMMENT '今日调用重置日期',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_key` (`feature_key`),
    CONSTRAINT `fk_feature_apikey` FOREIGN KEY (`api_key_id`) REFERENCES `ai_api_keys`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI功能配置';
```

### 5.2 初始数据（✅ 已插入，feature_key 已与 Go handler 对齐）

| feature_key | feature_name | enabled | daily_limit |
|-------------|-------------|---------|------------|
| run_analysis | AI跑情分析 | 1 | 1000 |
| coach | AI跑步教练 | 1 | 1000 |
| route_recommend | AI路线推荐 | 1 | 800 |
| comment | AI帮写评论 | 1 | 2000 |
| match | AI找搭档 | 1 | 500 |
| daily | AI每日金句 | 1 | 100 |
| moderation | AI路线审核 | 1 | 0（无限） |
| **summary** | **AI跑后总结** | **1** | **1000** |

> ⚠️ **注意**：以上 8 个 feature_key 与 Go 后端 AIService handler 硬编码的 key 完全对齐。管理端更改配置后，需 Go 端读取 `ai_feature_configs` 表才能生效。

### 5.3 `ai_api_keys` 表（现有，未改动）

```sql
CREATE TABLE `ai_api_keys` (
    `id`            BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `provider`      VARCHAR(50)  NOT NULL COMMENT '供应商',
    `name`          VARCHAR(100) NOT NULL COMMENT '配置名称',
    `api_key`       VARCHAR(500) NOT NULL COMMENT 'API密钥（加密存储）',
    `base_url`      VARCHAR(255) DEFAULT NULL COMMENT '自定义API地址',
    `model`         VARCHAR(100) DEFAULT NULL COMMENT '默认模型',
    `usage_scope`   VARCHAR(100) DEFAULT 'all' COMMENT '使用范围',
    `priority`      BIGINT DEFAULT 0 COMMENT '优先级',
    `is_active`     TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    `daily_limit`   BIGINT DEFAULT 0 COMMENT '每日调用上限（0=不限）',
    `today_calls`   BIGINT DEFAULT 0 COMMENT '今日已调用次数',
    `remarks`       VARCHAR(500) DEFAULT NULL COMMENT '备注',
    `create_time`   DATETIME(3) DEFAULT NULL,
    `update_time`   DATETIME(3) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI API密钥配置';
```

---

## 6. 后端 API（✅ 已实现）

### 6.1 获取全量功能配置

```
GET /stridemoor/ai/feature/config/all
Headers: Authorization: Bearer {token}

Response:
{
  "code": 200,
  "data": [
    {
      "id": 1,
      "featureKey": "run_analysis",
      "featureName": "AI跑情分析",
      "enabled": true,
      "apiKeyId": 1,
      "apiKeyName": "StrideMoor",
      "modelOverride": "",
      "model": "deepseek-chat",
      "dailyLimit": 1000,
      "todayCalls": 0,
      "lastReset": "2026-05-12"
    }
  ]
}
```

### 6.2 更新单个功能配置

```
PUT /stridemoor/ai/feature/config
Body:
{
  "id": 1,
  "enabled": true,
  "apiKeyId": 1,
  "modelOverride": "",
  "dailyLimit": 1000
}

Response:
{ "code": 200, "data": 1 }
```

### 6.3 切换启用状态

```
PUT /stridemoor/ai/feature/config/toggle/{id}
Response: { "code": 200, "msg": "操作成功" }
```

### 6.4 重置今日调用

```
PUT /stridemoor/ai/feature/config/reset-daily/{id}
Response: { "code": 200, "msg": "重置成功" }
```

### 6.5 获取可用模型列表

```
GET /stridemoor/ai/feature/config/available-models
Response:
{ "code": 200, "data": ["deepseek-chat", "gpt-4", "claude-3"] }
```

### 6.6 获取可用密钥列表

```
GET /stridemoor/ai/feature/config/available-keys
Response:
{ "code": 200, "data": [{ "id": 1, "name": "StrideMoor", "model": "deepseek-chat" }] }
```

### 6.7 全部 API 端点

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | `/stridemoor/ai/feature/config/all` | `stridemoor:ai:feature:list` | 全量查询（前端主用） |
| GET | `/stridemoor/ai/feature/config/list` | `stridemoor:ai:feature:list` | 分页查询 |
| GET | `/stridemoor/ai/feature/config/{id}` | `stridemoor:ai:feature:list` | 详情 |
| POST | `/stridemoor/ai/feature/config` | `stridemoor:ai:feature:add` | 新增 |
| PUT | `/stridemoor/ai/feature/config` | `stridemoor:ai:feature:edit` | 编辑 |
| PUT | `/stridemoor/ai/feature/config/toggle/{id}` | `stridemoor:ai:feature:edit` | 切换启用 |
| PUT | `/stridemoor/ai/feature/config/reset-daily/{id}` | `stridemoor:ai:feature:edit` | 重置今日调用 |
| GET | `/stridemoor/ai/feature/config/available-models` | `stridemoor:ai:feature:list` | 可用模型列表 |
| GET | `/stridemoor/ai/feature/config/available-keys` | `stridemoor:ai:feature:list` | 可用密钥列表 |
| DELETE | `/stridemoor/ai/feature/config/{ids}` | `stridemoor:ai:feature:remove` | 删除 |

---

## 7. 前后端文件清单（✅ 已创建）

### 后端
| 文件 | 路径 |
|------|------|
| Domain | `ruoyi-stridemoor/.../domain/AiFeatureConfig.java` |
| Mapper | `ruoyi-stridemoor/.../mapper/AiFeatureConfigMapper.java` |
| Mapper XML | `ruoyi-stridemoor/src/main/resources/mapper/stridemoor/AiFeatureConfigsMapper.xml` |
| Service | `ruoyi-stridemoor/.../service/AiFeatureConfigService.java` |
| ServiceImpl | `ruoyi-stridemoor/.../service/impl/AiFeatureConfigServiceImpl.java` |
| Controller | `ruoyi-stridemoor/.../controller/AiFeatureConfigController.java` |

### 前端
| 文件 | 路径 |
|------|------|
| API | `ruoyi-ui/src/api/stridemoor/featureConfig.js` |
| Vue页面 | `ruoyi-ui/src/views/stridemoor/ai/feature-config.vue` |
| 路由 | `ruoyi-ui/src/router/index.js`（`ai/feature-config`） |

### 菜单 & 权限
| 菜单ID | 菜单名 | 父级 | 路径 | 权限码 |
|--------|--------|------|------|--------|
| 2008 | AI功能配置 | AI服务管理(2000) | `/stridemoor/ai/feature-config` | `stridemoor:ai:feature:list` |
| - | 查询 | AI功能配置 | - | `stridemoor:ai:feature:list` |
| - | 新增 | AI功能配置 | - | `stridemoor:ai:feature:add` |
| - | 修改 | AI功能配置 | - | `stridemoor:ai:feature:edit` |
| - | 删除 | AI功能配置 | - | `stridemoor:ai:feature:remove` |
| - | 启用 | AI功能配置 | - | `stridemoor:ai:feature:enable` |
| - | 重置 | AI功能配置 | - | `stridemoor:ai:feature:reset` |

---

## 8. 注意事项

1. **日限额重置**：后端在每次查询时检查 `last_reset` 是否为今天，若不是则自动将 `today_calls` 重置为 0 并更新 `last_reset`（Service 层实现）
2. **密钥联动**：若关联的 `ai_api_keys` 记录被禁用（`is_active=0`），配置页应提示"关联密钥已禁用"
3. **模型覆盖**：`model_override` 为空时使用密钥默认模型；有值时优先使用覆盖模型
4. **路面类型 + 爬升增强**（Phase 1 已完成）：AI跑情分析已集成 5 种路面类型识别及爬升分析
5. **VIP + AI 功能联动**（v2.3 设计）：`enabled=1` AND `users.is_vip>0` AND `api_keys.is_active=1` 三者同时满足方可使用

---

## 9. Go 后端集成（待实现 — 需 AI 同事接入）

### 9.1 feature_key 对照表（已对齐 ✅）

| 管理端 | Go handler | 功能 |
|--------|-----------|------|
| `run_analysis` | `run_analysis` | AI跑情分析 |
| `coach` | `coach` | AI跑步教练 |
| `summary` | `summary` | AI跑后总结 |
| `route_recommend` | `route_recommend` | AI路线推荐 |
| `comment` | `comment` | AI帮写评论 |
| `match` | `match` | AI找搭档 |
| `daily` | `daily` | AI每日金句 |
| `moderation` | `moderation` | AI路线审核 |

> ⚠️ 以上 8 个 key 已完全对齐。Go 端须从 `ai_feature_configs` 表读取配置，勿再硬编码这些 key。

### 9.2 Go 后端配置加载流程

1. 启动时 / 定时（10min 间隔）从 `stridemoor.ai_feature_configs` 读取 `enabled=1` 的配置
   - `JOIN ai_api_keys ON ai_feature_configs.api_key_id = ai_api_keys.id`
2. 缓存到 Redis（10 分钟过期）
3. App 请求 AI 功能时，Go 从缓存取对应 `feature_key` 的配置
4. 判断流程：
   a. `config.enabled == false` → 返回"功能已关闭"
   b. `user.is_vip <= 0` → 返回"需要 VIP"
   c. `config.daily_limit > 0 AND config.today_calls >= config.daily_limit` → 返回"已达到日限额"
   d. `api_key` 不可用 → 返回"服务配置异常"
5. 调用 AI 后 `today_calls + 1`，写 `ai_call_logs` 表

### 9.3 Go 后端查询 SQL

```sql
SELECT
    f.id, f.feature_key, f.feature_name, f.enabled,
    f.api_key_id, f.model_override, f.daily_limit, f.today_calls,
    k.provider, k.api_key, k.base_url,
    COALESCE(f.model_override, k.model) AS effective_model
FROM ai_feature_configs f
LEFT JOIN ai_api_keys k ON f.api_key_id = k.id AND k.is_active = 1
WHERE f.feature_key = ?;
```

### 9.4 Go 后端改动清单

| 文件 | 改动 |
|------|------|
| `AIService.go` | `CallAI()` 方法：新增从 `ai_feature_configs` 读取配置逻辑 |
| `handler/*.go` | 确认 8 个 handler 的 `feature_key` 已对齐 |
| 新增 `config_loader.go` | 定时加载 + Redis 缓存 `ai_feature_configs` 配置 |
| 新增 `config/model.go` | 定义 `FeatureConfig` 结构体 |

---

*需求编写：大衍神君*
*最后更新：2026-05-12 | v2.5*
