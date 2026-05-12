# 设备管理 & 健康数据导入 —— 设计方案

## 一、背景

驰陌目前只支持手机端 GPS 记录跑步。用户实际场景中常佩戴手表/手环（Apple Watch、华为手表、Garmin等），跑完自动同步到各自健康平台（华为健康、Apple Health、Health Connect），需要打通从手表→健康平台→驰陌的导入链路。

## 二、核心思路

**手表负责完整记录（GPS+心率+步频），驰陌作为数据消费方从健康平台导入。**

```
手表跑完记录
  ↓ 自动同步
华为健康 / Apple Health / Health Connect 等
  ↓ 手动/自动导入
驰陌 App 解析并创建跑步记录
  ↓
自动路线匹配 → 更新排行榜
```

## 三、数据模型

### 3.1 Device 表（数据库新建）

```sql
CREATE TABLE devices (
    id           CHAR(36)     PRIMARY KEY,
    user_id      CHAR(36)     NOT NULL,
    name         VARCHAR(100) NOT NULL,               -- 显示名 "东君的 Watch Ultra"
    device_type  VARCHAR(50)  NOT NULL,               -- smartwatch / fitness_band / hr_monitor
    brand        VARCHAR(50)  NOT NULL,               -- Apple / Huawei / Garmin / Xiaomi / Polar
    model        VARCHAR(100) DEFAULT '',              -- 具体型号 "Watch Ultra 2"
    conn_type    VARCHAR(50)  NOT NULL,                -- 连接方式: ble / apple_health / huawei_health / garmin / health_connect
    mac_addr     VARCHAR(100) DEFAULT '',              -- 设备唯一标识
    is_connected BOOLEAN      DEFAULT FALSE,           -- 当前连接状态
    battery      TINYINT      DEFAULT NULL,            -- 电量 0~100
    last_sync_at DATETIME(3)  DEFAULT NULL,            -- 最后同步时间
    created_at   DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3),
    updated_at   DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    INDEX idx_user_id (user_id)
);
```

### 3.2 ImportRecord 表（记录导入历史，防重复）

```sql
CREATE TABLE import_records (
    id              CHAR(36)     PRIMARY KEY,
    user_id         CHAR(36)     NOT NULL,
    run_id          CHAR(36)     NOT NULL,             -- 关联的跑步记录 ID
    source          VARCHAR(50)  NOT NULL,             -- 来源: apple_health / huawei_health / health_connect / garmin
    source_id       VARCHAR(255) NOT NULL,             -- 健康平台侧的记录唯一 ID（防重复导入）
    device_id       CHAR(36)     DEFAULT NULL,         -- 关联的设备 ID
    imported_at     DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3),
    INDEX idx_user_source (user_id, source),
    UNIQUE KEY uk_source_source_id (source, source_id(100))
);
```

### 3.3 User.DeviceInfo 字段使用

User 表的 `DeviceInfo (JSON)` 字段存储用户设备偏好：
```json
{
  "default_source": "huawei_health",
  "auto_import": true,
  "last_import_ids": ["xxx", "yyy"]
}
```

## 四、后端 API

### 4.1 设备管理

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET`    | `/api/v1/devices`            | 获取用户设备列表 |
| `POST`   | `/api/v1/devices`            | 绑定/注册设备 |
| `PATCH`  | `/api/v1/devices/:id`        | 更新设备信息（名称、电量、连接状态） |
| `DELETE` | `/api/v1/devices/:id`        | 解绑设备 |
| `PATCH`  | `/api/v1/devices/:id/sync`   | 更新 last_sync_at 时间 |

### 4.2 数据导入

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET`    | `/api/v1/runs/importable`          | 获取可导入的健康记录列表（前端调用健康平台后回传元数据） |
| `POST`   | `/api/v1/runs/import`              | 提交一条导入数据（含 GPS 采样 + 元数据），创建 Run 记录 |
| `GET`    | `/api/v1/runs/import/history`      | 查看历史导入记录 |
| `DELETE` | `/api/v1/runs/import/:importId`    | 删除某条导入记录（同时删关联的 Run） |

### 4.3 导入 API 请求体示例

```json
POST /api/v1/runs/import
{
  "source": "huawei_health",
  "source_id": "hh_20260503_001",
  "device_id": "uuid-of-device",
  "start_time": "2026-05-03T07:00:00+08:00",
  "end_time": "2026-05-03T07:50:00+08:00",
  "total_distance": 10050,
  "total_time": 3000,
  "avg_pace": 298,
  "avg_heart_rate": 152,
  "max_heart_rate": 178,
  "avg_cadence": 170,
  "elevation_gain": 45.2,
  "elevation_loss": 44.8,
  "calories": 520,
  "samples": [
    { "latitude": 22.543, "longitude": 114.057, "sample_time": "...", "heart_rate": 145, "cadence": 168 },
    ...
  ]
}
```

## 五、前端分层架构

```
┌──────────────────────────────────────────────────┐
│              设备管理页面 (已有骨架)                │
│  ├ 设备列表（从 API 加载）                        │
│  ├ 绑定新设备                             │
│  ├ 同步入口 "从华为健康导入" / "从 Apple Health"    │
│  └ 设备详情（电量、最后同步时间）                  │
├──────────────────────────────────────────────────┤
│             健康平台读取层                          │
│  ├ Apple HealthKit       → health 包              │
│  ├ Health Connect        → health 包              │
│  ├ 华为运动健康          → HMS Health Kit SDK      │
│  └ Garmin Connect        → OAuth API              │
├──────────────────────────────────────────────────┤
│             导入流程 (UI)                          │
│  ├ 选择平台 → 读取最近运动记录                      │
│  ├ 勾选要导入的记录                                │
│  ├ 确认导入 → POST /api/v1/runs/import            │
│  └ 结果页显示新创建的跑步记录                       │
└──────────────────────────────────────────────────┘
```

### 同步流程（用户视角）

```
手动同步：
  打开设备管理 → 点"同步" → 读取健康平台记录
    → 展示可导入列表 → 用户勾选 → 确认导入
    → 创建跑步记录 → 自动路线匹配 → 完成 ✅

自动提示：
  后台检测到新记录 → 通知："检测到 1 条新运动记录，是否导入？"
    → 用户点"查看" → 跳转导入页面
    → 同手动流程
```

## 六、跑步记录的 DeviceType 字段关联

FinishRun 时如果用户连接了蓝牙设备，前端传入 `device_type` 和 `device_id`：

```json
{
  "device_type": "huawei_watch_gt4",  // 已连接设备类型
  "device_id": "uuid-of-device",      // 后端 Device 表 ID
}
```

后端存储到 Run 表，用于统计每台设备的运动数据。

## 七、分阶段实施

| 阶段 | 内容 | 预估工时 |
|------|------|---------|
| **Phase 1** 🎯 | 后端 Device 模型 + 迁移 + 设备 CRUD API + ImportRecord 模型 | 半天 |
| **Phase 2** 🎯 | 后端导入 API + 自动路线匹配联动 | 半天 |
| **Phase 3** 🎯 | Flutter `health` 插件集成 + Apple Health / Health Connect 读取 | 1天 |
| **Phase 4** 🎯 | 前端导入流程 UI + 同步页面 | 1天 |
| **Phase 5** 🏁 | 华为 Health Kit 集成 | 待评估 |
| **Phase 6** 🏁 | Garmin 等其他平台 | 待评估 |

## 八、未解决的问题 / 待决策

- [ ] 华为 Health Kit 需要 HMS 环境，Flutter 是否有成熟的插件？是否需要原生桥接？
- [ ] 自动导入的触发方式：定时后台任务 vs 推送通知唤醒？
- [ ] 导入的记录是否允许手动删除？删除是否同步到健康平台？
