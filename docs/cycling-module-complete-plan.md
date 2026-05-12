# 驰陌 / StrideMoor — 骑行模块完整方案

> **文档版本**: v1.3  
> **更新日期**: 2026-05-12  
> **状态**: 全案已定稿，待用户确认后开始编码
> 🔴 骑行勋章系统的具体设计待定（双轨独立已确定，形式/名称/级数待定）
> **关联文档**: `requirements.md`（主产品需求）, `design.md`（系统设计）, `伴跑-挑战跑-完整方案.md`, `ai_features_integration_plan.md`, `device-management-design.md`

---

## 一、产品概述

### 1.1 为什么要做骑行

骑行与跑步天然互补：

| 维度 | 跑步 | 骑行 |
|------|------|------|
| 用户群 | 跑步爱好者（初级~中级） | 骑行爱好者（通勤/休闲/运动） |
| 运动频次 | 3~5 次/周 | 高频（通勤+周末骑行） |
| 数据维度 | 配速/步频/步幅/心率 | 均速/踏频/功率/心率/爬升 |
| 社交需求 | 路线分享伴跑 | 路线分享伴骑 |
| 场地依赖 | 公园/绿道/路跑 | 公路/绿道/山地/城市 |
| 设备门槛 | 手机即可 | 自行车+手机/车把支架 |

**核心判断：** 驰陌的「路线为锚点」社交模型天然适用于骑行——路线更长、数据更丰富、社交属性更强。骑行不是跑步的附属功能，而是同等级的第二运动品类。

### 1.2 产品定位

```
驰陌 = 社交跑步教练 + 社交骑行教练
      以路线为纽带的运动社交平台
```

**Slogan 更新：** *"Stride in Moor, Run at Ease — Ride the Same Trail"*

### 1.3 用户场景

| 场景 | 描述 |
|------|------|
| **通勤骑** | 用户绑定自行车后，每天通勤自动记录 GPS 轨迹+心率+踏频，系统生成骑行报告 |
| **路线挑战** | 看到跑友/骑友分享的经典骑行路线（如深圳湾→大沙河），收藏后发起挑战骑 |
| **伴骑训练** | 和跑友数据一起骑，影子伴骑对照配速/心率/踏频 |
| **周末休闲骑** | 骑友组团出行，所有绑定驰陌的车自动记录并同步路线数据 |
| **品牌活动** | 合作车厂发起骑行挑战赛，用户完成路线获取品牌积分/勋章 |

---

## 二、硬件合作模式

### 2.1 自行车厂合作方案

**基本模式：** 驰陌与自行车厂商（OEM/ODM）深度合作，预装驰陌智能模组到出厂自行车。

| 合作层级 | 模式 | 功能 | 分润方式 |
|----------|------|------|----------|
| **L1 基础版** | 车厂预装驰陌芯片模组 | GPS 轨迹记录 + 基础心率感应 | 每车激活费用 |
| **L2 标准版** | 车厂定制驰陌 SDK | L1 + 踏频传感器 + 蓝牙连接手机 | 激活费 + App订阅分成 |
| **L3 旗舰版** | 联合品牌 | L2 + 功率计 + 智能变速 + 彩屏仪表盘 | 定制费用 + 持续分成 |

### 2.2 每车唯一识别码系统

```
┌──────────────────────────────────────────┐
│          Bike Identity System            │
├──────────────────────────────────────────┤
│  硬件ID: STM-XXXX-YYYY-ZZZZ             │
│   ├─ STM: 驰陌前缀                        │
│   ├─ XXXX: 品牌型号编码                   │
│   ├─ YYYY: 生产批次编码                   │
│   └─ ZZZZ: 序列号（8位hex）               │
│                                          │
│  存储位置：                               │
│   1. 芯片模组出厂烧录                       │
│   2. 车架激光刻印二维码                     │
│   3. 包装盒内 NFC 标签                     │
│   4. 品牌方数据库备案                       │
└──────────────────────────────────────────┘
```

### 2.3 绑定流程

```
用户购车
  ↓
扫描车架二维码 / 靠近 NFC 标签
  ↓
App 弹出绑定确认页
  ├ 展示: 品牌、型号、车架号末4位、保修期
  ├ 点击 [绑定我的车] → POST /api/v1/bikes/bind
  ↓
绑定成功
  ├ 自动激活硬件 GPS 模块
  ├ 车辆信息存入用户设备列表
  ├ 写入 BikeUser 关联表
  └ 提示: "恭喜绑定成功！骑行即可自动记录轨迹+心率"
```

### 2.4 硬件模组规格

| 组件 | 规格 | 供电 | 备注 |
|------|------|------|------|
| GPS 模组 | u-blox M10 (GNSS 多模) | 自行车自带电池 / 发电花鼓 | 低功耗，待机30天 |
| 心率传感器 | 车把触摸式光学心率 | 车把内置纽扣电池 CR2032 | IP67 防水 |
| 踏频传感器 | 磁感应/陀螺仪 | 曲柄臂内置，免电池 | 通过蓝牙/BLE 连接手机 |
| 蓝牙模块 | BLE 5.2 | 集成至主控模块 | 范围约 10m |
| 主控 MCU | ESP32-S3 (低功耗) | 自行车电池系统 | 负责数据采集+传输 |
| 加速度计 | 六轴 IMU (BMI270) | 集成模组 | 自动唤醒（检测到车辆移动） |
| 状态 LED | 三色指示 (绿/蓝/红) | — | 蓝牙连接/电量/异常状态 |

**数据流：**

```
车把心率传感器 ─┐
GPS 模组 ───────┼──→ MCU 模组 ──BLE 5.2──→ 驰陌 App ──HTTPS──→ 后端
踏频传感器 ─────┘
加速度计(自动唤醒)
```

---

## 三、数据模型

### 3.1 新增表：`bikes`（自行车注册表）

```sql
CREATE TABLE bikes (
    id              CHAR(36)     PRIMARY KEY,
    hardware_id     VARCHAR(50)  NOT NULL UNIQUE,      -- STM-XXXX-YYYY-ZZZZ
    brand           VARCHAR(50)  NOT NULL,              -- GIANT / MERIDA / TREK / 定制
    model           VARCHAR(100) NOT NULL,              -- 具体车型
    tier            ENUM('L1','L2','L3') DEFAULT 'L1', -- 合作层级
    chip_version    VARCHAR(50)  DEFAULT '',             -- 模组固件版本
    manufacture_at  DATE         DEFAULT NULL,           -- 出厂日期
    activated_at    DATETIME(3)  DEFAULT NULL,           -- 首绑激活时间
    status          ENUM('inactive','active','revoked') DEFAULT 'inactive',
    created_at      DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3),
    updated_at      DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    INDEX idx_hardware_id (hardware_id),
    INDEX idx_tier (tier)
);
```

### 3.2 新增表：`bike_users`（人车绑定关系）

```sql
CREATE TABLE bike_users (
    id              CHAR(36)     PRIMARY KEY,
    bike_id         CHAR(36)     NOT NULL,
    user_id         CHAR(36)     NOT NULL,
    is_primary      BOOLEAN      DEFAULT TRUE,          -- 主车主（可选：家庭共享）
    nickname        VARCHAR(100) DEFAULT '',             -- "我的战车"
    color           VARCHAR(10)  DEFAULT '',             -- 车颜色（用户设置）
    service_mileage FLOAT        DEFAULT 0,              -- 累计服务里程 km
    bind_at         DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3),
    unbound_at      DATETIME(3)  DEFAULT NULL,
    UNIQUE KEY uk_bike_user (bike_id, user_id),
    INDEX idx_user_id (user_id)
);
```

### 3.3 新增表：`cycling_records`（骑行记录）

```sql
CREATE TABLE cycling_records (
    id              CHAR(36)     PRIMARY KEY,
    user_id         CHAR(36)     NOT NULL,
    bike_id         CHAR(36)     NOT NULL,
    route_id        CHAR(36)     DEFAULT NULL,           -- 关联路线（可选）
    start_time      DATETIME(3)  NOT NULL,
    end_time        DATETIME(3)  NOT NULL,
    total_distance  FLOAT        NOT NULL,              -- 米
    total_time      INT          NOT NULL,              -- 秒
    avg_speed       FLOAT        NOT NULL,              -- km/h
    max_speed       FLOAT        DEFAULT 0,             -- km/h
    avg_heart_rate  INT          DEFAULT 0,             -- bpm
    max_heart_rate  INT          DEFAULT 0,
    avg_cadence     INT          DEFAULT 0,             -- rpm
    avg_power       FLOAT        DEFAULT 0,             -- 瓦 (L3设备)
    elevation_gain  FLOAT        DEFAULT 0,             -- 米
    elevation_loss  FLOAT        DEFAULT 0,
    calories        INT          DEFAULT 0,
    fatigue_score   INT          DEFAULT NULL,           -- 疲劳指数（基于心率/功率估算）
    device_type     VARCHAR(50)  DEFAULT 'stridemoor_bike',
    mode            VARCHAR(20)  DEFAULT 'solo',         -- solo / companion / challenge
    opponent_run_id CHAR(36)     DEFAULT NULL,           -- 对手跑步记录ID（伴骑/挑战骑）
    opponent_user_id CHAR(36)    DEFAULT NULL,
    challenge_id    CHAR(36)     DEFAULT NULL,           -- 挑战ID
    gps_track       JSON         DEFAULT NULL,           -- GPS采样点
    created_at      DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3),
    INDEX idx_user_id (user_id),
    INDEX idx_bike_id (bike_id),
    INDEX idx_route_id (route_id),
    INDEX idx_start_time (start_time),
    INDEX idx_challenge_id (challenge_id)
);
```

### 3.4 新增表：`cycling_splits`（分段数据）

```sql
CREATE TABLE cycling_splits (
    id              CHAR(36)     PRIMARY KEY,
    cycling_id      CHAR(36)     NOT NULL,
    split_index     TINYINT      NOT NULL,              -- 第几公里
    distance        FLOAT        NOT NULL,              -- 本段距离 米
    time            INT          NOT NULL,              -- 本段用时 ms
    avg_speed       FLOAT        NOT NULL,              -- km/h
    avg_heart_rate  INT          DEFAULT 0,
    avg_cadence     INT          DEFAULT 0,
    avg_power       FLOAT        DEFAULT 0,
    elevation_gain  FLOAT        DEFAULT 0,
    UNIQUE KEY uk_cycling_split (cycling_id, split_index)
);
```

### 3.5 新增表：`cycling_samples`（秒级采样 — 时序分区）

```sql
CREATE TABLE cycling_samples (
    id              BIGINT       AUTO_INCREMENT,
    cycling_id      CHAR(36)     NOT NULL,
    record_time     DATETIME(3)  NOT NULL,              -- 采样时间
    latitude        DOUBLE       NOT NULL,
    longitude       DOUBLE       NOT NULL,
    altitude        DOUBLE       DEFAULT 0,
    speed           FLOAT        DEFAULT 0,             -- 实时速度 km/h
    heart_rate      INT          DEFAULT 0,
    cadence         INT          DEFAULT 0,
    power           FLOAT        DEFAULT 0,
    PRIMARY KEY (id, record_time)
) PARTITION BY RANGE COLUMNS(record_time) (
    PARTITION p2026q2 VALUES LESS THAN ('2026-10-01'),
    PARTITION p2026q3 VALUES LESS THAN ('2027-01-01'),
    PARTITION p2027q1 VALUES LESS THAN ('2027-04-01'),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- 自动创建新分区的事件（与 run_samples 相同逻辑）
```

### 3.6 扩展表：`routes`（路线表增加骑行字段）

```sql
-- 在现有 routes 表新增字段
ALTER TABLE routes ADD COLUMN sport_type ENUM('run','cycle','both') DEFAULT 'run' AFTER id;
ALTER TABLE routes ADD COLUMN surface_type VARCHAR(50) DEFAULT '' AFTER sport_type;  -- road / gravel / trail / mixed
ALTER TABLE routes ADD COLUMN traffic_level ENUM('low','medium','high') DEFAULT 'low' AFTER surface_type;
ALTER TABLE routes ADD COLUMN cycling_difficulty TINYINT DEFAULT NULL AFTER difficulty;  -- 骑行难度（1~10）
```

### 3.7 扩展表：`devices`（增加 BikeDevice 类型）

```sql
-- device_type 新增枚举值
-- 'bike_gps': 自行车载GPS模块
-- 'bike_hr': 车把心率传感器
-- 'bike_cadence': 踏频传感器
-- 'bike_power': 功率计
```

### 3.8 扩展表：`challenges`（挑战表增加骑行）

```sql
-- 现有 challenges 表增加字段
ALTER TABLE challenges ADD COLUMN sport_type ENUM('run','cycle') DEFAULT 'run';
ALTER TABLE challenges ADD COLUMN cycling_metrics JSON DEFAULT NULL;
-- cycling_metrics 示例:
-- {
--   "metrics": ["avg_speed", "avg_heart_rate", "avg_cadence", "elevation_gain"],
--   "opponent_bike_id": "...",
--   "weight_factor": 1.0  -- 体重校正系数
-- }
```

### 3.9 扩展表：`跑境成就`（境界表）

```
-- 现有跑境成就系统增加骑行聚合字段
-- 骑行段位与跑步段位独立，共用"十三境"命名体系
-- 骑行版命名微调（保持意境一致）：
--   练气 → 骑行版：轻骑
--   筑基 → 骑行版：游骑
--   筑丹 → 骑行版：劲骑
--   ... 待产品确认
```

### 3.10 Redis 缓存新增

| Key 模式 | 类型 | TTL | 说明 |
|----------|------|-----|------|
| `bike:info:{hardware_id}` | String | 30d | 自行车出厂信息缓存 |
| `bike:user:{bike_id}` | String | 1h | 当前绑定用户缓存 |
| `cycling:leaderboard:route:{route_id}` | Sorted Set | 5m | 骑行路线排行榜 |
| `cycling:challenge:{id}:progress` | Hash | 1h | 骑行挑战实时进度 |
| `cycling:online:{route_id}` | Set | 5m | 当前正在该路线的骑友 |

---

## 四、后端 API 设计

### 4.1 设备管理（自行车绑定）

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST`   | `/api/v1/bikes/bind`          | 扫码绑定自行车 |
| `GET`    | `/api/v1/bikes`                | 获取用户自行车列表 |
| `PATCH`  | `/api/v1/bikes/:id`            | 更新车辆昵称/颜色 |
| `DELETE` | `/api/v1/bikes/:id/unbind`     | 解绑车辆 |
| `GET`    | `/api/v1/bikes/:id/info`       | 车辆详细信息（硬件版本/固件升级状态） |
| `GET`    | `/api/v1/bikes/:id/stats`      | 车辆累计骑行统计 |

### 4.2 骑行记录

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST`   | `/api/v1/cycling/start`       | 开始骑行（创建记录，伴骑/挑战骑模式） |
| `PATCH`  | `/api/v1/cycling/:id/update`  | 实时更新骑行数据（GPS采样+心率+踏频） |
| `POST`   | `/api/v1/cycling/:id/finish`  | 结束骑行，生成记录 |
| `GET`    | `/api/v1/cycling/:id`          | 获取骑行记录详情 |
| `GET`    | `/api/v1/cycling`              | 获取用户骑行记录列表（分页，按时间倒序） |
| `DELETE` | `/api/v1/cycling/:id`          | 删除骑行记录 |

### 4.3 伴骑 API（新生而复用伴跑逻辑）

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET`    | `/api/v1/companion/friends/cycling` | 获取可伴骑的骑友骑车记录（已收藏的骑行跑迹） |
| `GET`    | `/api/v1/companion/:runId/ghost/cycling` | 获取对手骑行幽灵数据（GPS采样 + 分段数据 + 核心指标） |

### 4.4 挑战 API（扩展现有挑战系统）

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST`   | `/api/v1/challenges/create/cycling` | 创建骑行挑战 |
| `GET`    | `/api/v1/challenges/cycling`        | 获取骑行挑战记录 |
| `POST`   | `/api/v1/challenges/:id/start`     | 开始骑行挑战 |
| `POST`   | `/api/v1/challenges/:id/complete`  | 完成骑行挑战，生成对比报告 |
| `GET`    | `/api/v1/challenges/:id/comparison` | 获取骑行挑战对比数据 |

### 4.5 排行榜

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET`    | `/api/v1/leaderboard/route/:id/cycling` | 同路线骑行成绩排行 |
| `GET`    | `/api/v1/leaderboard/global/cycling`    | 骑行总榜（周/月/全部） |

### 4.6 骑行 BLE 通信

```
驰陌 App ← BLE 5.2 → 自行车模组
```

**通信协议（基于 BLE GATT）：**

| Service UUID | Characteristic UUID | 方向 | 数据 | 频率 |
|-------------|-------------------|------|------|------|
| `STM-BIKE-1000` | `STM-BIKE-1001` | Notify | GPS 坐标 (JSON压缩) | 1Hz |
| `STM-BIKE-1000` | `STM-BIKE-1002` | Notify | 心率 (uint8 bpm) | 1Hz |
| `STM-BIKE-1000` | `STM-BIKE-1003` | Notify | 踏频 (uint8 rpm) | 1Hz |
| `STM-BIKE-1000` | `STM-BIKE-1004` | Write | 控制指令 (开始记录/结束/固件升级) | 按需 |
| `STM-BIKE-1000` | `STM-BIKE-1005` | Read | 设备状态 (电量/信号强度/存储余量) | 按需 |

**数据压缩：** GPS 坐标使用增量编码 + ZigZag 压缩，心率/踏频直接传原始值。

---

## 五、前端设计

### 5.1 设计原则

- **最小改动**：底部导航保持 4 Tab 不变，不增加第5个 Tab
- **统一入口**："运动" Tab 作为跑步和骑行的统一入口
- **解耦独立**：跑步和骑行的准备页代码各自独立，通过公共组件库共享
- **可扩展**：未来新增运动类型(游泳/徒步等)只需在 SportModeSelectPage 加一个卡片

### 5.2 导航流程（核心改动）

```
底部导航（4 Tab 不变）
┌────────┬────────┬────────┬────────┐
│  发现   │  运动   │  跑迹   │  我的   │
│        │ (tabRun)│        │        │
└────────┴───┬────┴────────┴────────┘
             │ 点击「运动」Tab
             ▼
┌──────────────────────────────────┐
│                                  │
│        选择运动模式               │
│                                  │
│  ┌────────────────────────┐      │
│  │  🏃  跑步              │      │
│  │  配速·步频·心率·爬升   │      │
│  │  跑步勋章·跑境成就      │      │
│  └────────────┬───────────┘      │
│  ┌────────────┴───────────┐      │
│  │  🚴  骑行              │      │
│  │  均速·踏频·功率·爬升   │      │
│  │  骑行勋章·骑境成就      │      │
│  └────────────────────────┘      │
│                                  │
│  未来可扩展：🏊 游泳 / 🥾 徒步   │
└──────────────────────────────────┘
             │
      ┌──────┴──────┐
      ▼              ▼
┌────────────┐  ┌────────────┐
│ 跑步准备页  │  │ 骑行准备页  │
│ (现有不变)  │  │ (新建)      │
│            │  │            │
│ RunMode:   │  │ CycleMode: │
│ · 独自跑   │  │ · 独自骑   │
│ · 伴跑     │  │ · 伴骑     │
│ · 挑战跑   │  │ · 挑战骑   │
│            │  │            │
│ 选路线     │  │ 选路线     │
│ 设定目标   │  │ 绑定车辆   │
│ 语音播报   │  │ BLE设备连接│
│            │  │ 设定目标   │
│ [开始跑]   │  │ 语音播报   │
└────────────┘  │ [开始骑]   │
                 └────────────┘
```

### 5.3 页面清单（更新）

| 页面 | 改动 | 类型 |
|------|------|------|
| **SportModeSelectPage**（新建） | 两个大卡片选择「跑步」或「骑行」，路由 `/activity` | **新建** |
| **跑步准备页** RunPreparationPage | **不做任何改动**，保持现有 `/run/preparation` | 已有→保持 |
| **骑行准备页** CyclingPreparationPage | 新建：选择骑行模式（独自骑/伴骑/挑战骑）+ 选路线 + 连接BLE | **新建** |
| **骑行中页面** | 新建：实时数据展示（均速/心率/踏频/海拔/GPS轨迹） | **新建** |
| **骑行完成页** | 新建：骑行报告 + 对比图表（伴骑/挑战骑） | **新建** |
| **自行车管理页** | 新建：管理已绑定自行车，查看硬件信息/固件升级 | **新建** |
| **骑行统计页** | 新建：月度/年度骑行数据统计 | **新建** |
| **首页（发现页）** | **不做任何改动**—首页不需要运动模式 Tab | 已有→保持 |

### 5.4 路由配置改动

```dart
// 当前 routes.dart（仅运动相关）
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/run',           // ← 改为 /activity
      builder: (context, state) => const RunPreparationPage(),  // ← 改为 SportModeSelectPage
      routes: [
        GoRoute(path: 'gps', ...),          // 跑步专用
        GoRoute(path: 'ongoing', ...),       // 跑步专用
        GoRoute(path: 'finish', ...),        // 跑步专用
        // ↓ 新增骑行子路由
        GoRoute(path: 'cycling/preparation', ...),    // 骑行准备
        GoRoute(path: 'cycling/ongoing', ...),        // 骑行中
        GoRoute(path: 'cycling/finish', ...),         // 骑行完成
      ],
    ),
  ],
),
```

**改动要点**：
- `/run` 路径 → `/activity`（语义更通用），指向新建 `SportModeSelectPage`
- 原有跑步子路由保持不变：`gps` / `ongoing` / `finish`
- 新增骑行子路由放在同一 Branch 下：`cycling/preparation` / `cycling/ongoing` / `cycling/finish`
- 骑行准备页推入时保留底部导航，用户可随时切回其它 Tab
- ShellScaffold 中 `_onTap` 的 index==1 特殊处理不变，依旧 push 到 `/activity`

### 5.5 SportModeSelectPage 设计

```
┌──────────────────────────────────┐
│          ← 返回                  │
│                                  │
│        选择运动方式               │
│                                  │
│  ┌────────────────────────────┐  │
│  │   🏃                       │  │
│  │   跑步                     │  │
│  │   配速 · 步频 · 心率 · 爬升  │  │
│  │   跑境 13 重 · 挑战跑 · 伴跑 │  │
│  │                            │  │
│  │   [上次: 5.2km · 32min]    │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │   🚴                       │  │
│  │   骑行                     │  │
│  │   均速 · 踏频 · 心率 · 功率  │  │
│  │   骑境 13 重 · 挑战骑 · 伴骑 │  │
│  │                            │  │
│  │   [无最近骑行记录]           │  │
│  └────────────────────────────┘  │
│                                  │
│  底部：未来扩展：🏊 游泳 | 🥾 徒步 │
└──────────────────────────────────┘
```

**交互细节**：
- 两个大卡片全屏居中，点击后 push 到对应准备页
- 每张卡片底部显示当前用户的最近运动记录摘要
- 跑步卡片带跑境段位徽章装饰，骑行卡片待首次完成后显示
- 骑行卡片可选择性地显示已绑定的自行车名称（如"我的战车 GIANT"）
- 左滑/右滑可快速切换（类似 iOS 运动模式），但初期只做点按

### 5.6 骑行准备页

```
┌──────────────────────────────────┐
│  ← 运动选择                      │
│                                  │
│  🚴 骑行                         │
│                                  │
│  模式：○ 独自骑                    │
│        ○ 伴骑                     │
│        ○ 挑战骑                   │
│                                  │
│  [选择跑迹]  ← 选中伴骑/挑战骑时出现   │
│  已选：跑友「张三」深圳湾→后海 13.7km │
│                                  │
│  ┌─ 连接设备 ───────────────────┐ │
│  │ ✅ 已连接: 我的战车 (GIANT)   │ │
│  │     GPS ✅ 心率 ✅ 踏频 ✅    │ │
│  │   电池: ████████ 80%          │ │
│  │  [刷新设备]                    │ │
│  └────────────────────────────┘ │
│                                  │
│  [开始骑行 🚴]                    │
└──────────────────────────────────┘
```

### 5.7 技术要点（代码层面）

**公共组件（widgets/）**：
- `SportModeCard` — 模式选择卡片（用于 SportModeSelectPage）
- `RouteSelector` — 路线选择组件（跑步/骑行复用）
- `GoalSettingCard` — 运动目标设定组件
- `VoiceBroadcastConfig` — 语音播报配置（骑行版增加骑行播报项）
- `GhostModeSelector` — 影子模式选择（伴跑/伴骑共用 6 种 GhostMode）

**以上组件当前都在 RunPreparationPage 内联实现**，改造时按需提取到 `widgets/` 下即可。

**独立代码（不做公共的）**：
- 实时运动页面（RunningPage vs CyclingPage）— 数据展示差异大，各自独立
- 完成页（RunFinishPage vs CyclingFinishPage）— 指标不同，各自独立

### 5.8 运动记录页改造（run_history_page）

#### 5.8.1 设计决策

- 跑步和骑行的**历史记录合并在同一页面**展示
- 通过**图标**（`directions_run` / `directions_bike`）和**颜色**区分运动类型
- 不新建独立骑行记录页，复用现有 `RunHistoryPage`
- 列表数据由后端返回统一结构，每条附带 `sport_type` 字段

#### 5.8.2 筛选器位置与形态

**吸铁石式下拉框**（PopMenuButton），放在 AppBar 标题行内右侧：

```
┌──────────────────────────────────┐
│  ←  运动记录                     │
│      筛选: 全部 ▾      [清理]    │
│            ┌──────┐              │
│            │ 全部  │              │
│            │ 跑步  │              │
│            │ 骑行  │              │
│            │──────│              │
│            │ 选择日期│            │
│            └──────┘              │
├──────────────────────────────────┤
│                                  │
│  🏃 5/10  5.2km  5'30"  伴跑     │
│  🚴 5/9  15.3km  22km/h  独自骑   │
│  🏃 5/8  10km  4'50"  挑战       │
│  ...                             │
└──────────────────────────────────┘
```

**筛选选项**（可扩展）：
| 选项 | 说明 |
|------|------|
| 全部 | 跑步+骑行混合展示，无过滤（默认） |
| 跑步 | 仅显示 `sport_type='run'` 的记录 |
| 骑行 | 仅显示 `sport_type='cycle'` 的记录 |
| ——分隔线—— | |
| 选择日期 | 弹出日期选择器，按日/周/月筛选 |

#### 5.8.3 卡片图标区分

`_RunHistoryCard` 的图标区域逻辑扩展：

| 条件 | 图标 | 颜色 |
|------|------|------|
| `sport_type=run` + `mode=solo` | `directions_run` | 橙色渐变 |
| `sport_type=run` + `mode=companion` | 双 `directions_run` | 绿色渐变 |
| `sport_type=run` + `mode=challenge` | `directions_run` + 奖杯 | 红橙渐变 |
| `sport_type=cycle` + `mode=solo` | `directions_bike` | 橙色渐变 |
| `sport_type=cycle` + `mode=companion` | 双 `directions_bike` | 绿色渐变 |
| `sport_type=cycle` + `mode=challenge` | `directions_bike` + 奖杯 | 红橙渐变 |

#### 5.8.4 卡片数据行

跑步显示：`{距离km} · {配速} · {用时}`
骑行显示：`{距离km} · {均速 km/h} · {用时}`

两种记录共用 `total_distance`、`total_time` 字段，差异字段（pace vs speed）由后端在 `display_text` 中返回，或前端根据 `sport_type` 取值。

#### 5.8.5 后端数据接口

统一列表接口：`GET /api/v1/records?sport_type=all|run|cycle&date_from=...&page=1&page_size=20`

- 后端聚合 `runs` 表 + `cycling_records` 表，返回统一结构
- 每条记录携带 `sport_type`、`mode`、`total_distance`、`total_time`、`start_time`
- 差异字段（`avg_pace` / `avg_speed`）由前端按 `sport_type` 选择渲染
- `display_metric` 字段：跑步返回 `{value: 330, unit: "s", label: "配速"}`，骑行返回 `{value: 22.5, unit: "km/h", label: "均速"}`

```dart
class RecordListItem {
  final String id;
  final String sportType; // 'run' | 'cycle'
  final String mode;      // 'solo' | 'companion' | 'challenge'
  final DateTime startTime;
  final int totalTime;    // 秒
  final double totalDistance; // 公里
  final String? label;    // 跑步用avg_pace格式化，骑行用avg_speed
  final String? sublabel; // 跑步步频/骑行踏频等选填
}
```

### 5.9 骑行中页面

```
┌──────────────────────────────────┐
│  12:32   13.7km   ← 返回           │
│                                  │
│  ┌──────── 高德地图 ──────────┐  │
│  │  (实时 GPS 轨迹 + 对手幽灵)   │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌─ 实时数据 ─────────────────┐ │
│  │  均速 22.3 km/h  心率 146   │ │
│  │  踏频 79 rpm    爬升 12m    │ │
│  │  距离 5.2/10km  用时 14:32  │ │
│  └────────────────────────────┘ │
│                                  │
│  ┌─ 对手对比 ─────────────────┐ │
│  │  我：🚴 22.3 km/h  超你 0:12!│ │
│  │  对手：📊 21.8 km/h  🟢领先   │ │
│  │  分段: 🟢前 🔴落后 ⚪持平     │ │
│  └────────────────────────────┘ │
│                                  │
│  □ 语音播报 | □ 暂停 | □ 结束   │
└──────────────────────────────────┘
```

### 5.10 骑行完成页（对比报告）

```
┌──────────────────────────────────┐
│  🚴 骑行完成！                    │
│                                  │
│  总里程: 13.7 km                  │
│  用时:   38:22                    │
│  均速:   21.5 km/h               │
│  心率:   148/178 (avg/max)       │
│  踏频:   76 rpm                   │
│  爬升:   45 m                     │
│                                  │
│  ┌─ 分段对比 ─────────────────┐ │
│  │  km  你    对手   差       │ │
│  │  1   23.2  22.1  +1.1 🟢  │ │
│  │  2   22.8  22.5  +0.3 🟢  │ │
│  │  3   21.1  22.8  -1.7 🔴  │ │
│  │  4   20.5  21.5  -1.0 🔴  │ │
│  │  5   22.0  21.8  +0.2 🟢  │ │
│  └────────────────────────────┘ │
│                                  │
│  [发骑友动态] [AI 骑行诊断]        │
│  [收藏路线] [分享到微信]          │
└──────────────────────────────────┘
```

---

### 5.11 跑迹广场与路线生态系统

#### 5.11.1 当前路线体系现状

路线是整个 APP 的**核心社交资产**——创建、收藏、伴跑/伴骑、挑战、排行榜，全都基于路线。

现有路线页面：

| 页面 | 路径 | 当前特点 |
|------|------|---------|
| 跑迹广场 | `/square` | 城市下拉 + 热门/最新/评分 Tab |
| 路线详情 | `/route/:id` | 轨迹地图 + 排行榜 |
| 我的跑迹 | `/routes` (子Tab) | 个人上传路线列表 |
| 附近路线 | `/routes/nearby` | LBS 地图展示 |
| 上传跑迹 | `/routes/upload` | 从运动记录生成路线 |
| 跑迹选择 | `/routes/friends/select` | 选跑友记录做伴跑/挑战 |
| 跑迹排行榜 | `/route/:id/leaderboard` | 路线最快成绩排行 |

当前所有路线都是**跑步专有**，Route 模型无 `sport_type`。

#### 5.11.2 骑行对路线体系的影响面

**核心变化**：路线不再只是"跑步路线"，而是通用"运动路线"，每条路线标注 `sport_type`（`run` / `cycle` / `both`）。

#### 5.11.3 各页面详细改动

**① 跑迹广场（route_square_page.dart）**

```
当前布局：
┌──────────────────────────────────┐
│  跑迹广场              [搜索]    │
│  城市: 全部 ▾  热门│最新│评分    │
├──────────────────────────────────┤
│  🗺️ 深圳湾公园  13.7km  · 难度易 │
│     爬升45m · 500人跑过 · 4.8分  │
└──────────────────────────────────┘

改为：
┌──────────────────────────────────┐
│  跑迹广场              [搜索]    │
│  运动: 全部 ▾  城市: 全部 ▾     │  ← 新增运动类型下拉
│  热门│最新│评分                   │
├──────────────────────────────────┤
│  🏃 深圳湾公园  13.7km  · 难度易  │ ← 跑步 badge
│     爬升45m · 500人跑过 · 4.8分  │
│                                  │
│  🚴 大沙河骑道  15.3km  · 难度中  │ ← 骑行 badge
│     爬升20m · 适合公路车         │
└──────────────────────────────────┘
```

- 跑迹广场 AppBar 下方新增「运动类型」下拉框，与城市下拉平级
- 选项：全部（默认）/ 跑步 / 骑行
- 路线卡片增加运动类型 `Chip`/`Badge`：🏃跑步 / 🚴骑行
- 后端 `GET /api/v1/routes` 新增 `sport_type` 查询参数

**② 路线详情（route_detail_page.dart）**

- 标题下方新增运动类型标签（跑步绿色 / 骑行橙色）
- 数据面板根据 `sport_type` 动态展示：
  - 跑步路线：距离开头 + 配速 + 步频 + 爬升
  - 骑行路线：距离开头 + 均速 + 踏频 + 爬升 + 路面类型
- 排行榜成绩排序逻辑不变（按用时排），但展示指标切换：
  - 跑步榜显示 avg_pace
  - 骑行榜显示 avg_speed
- 底部操作按钮："去伴骑" / "去挑战骑" 根据路线类型动态显示

**③ 我的跑迹（my_routes_page.dart）**

- 页面标题改为"我的路线"（不再限定"跑迹"）
- 列表增加运动类型 badge
- 来源：既能从跑步记录生成路线，也能从骑行记录生成

**④ 上传跑迹（upload_route_page.dart）**

- 当前逻辑：从 `recentRunsProvider` 选一条跑步记录生成路线
- 改为：从 `recentRecordsProvider`（跑步+骑行统一列表）选择
- 上传时自动标记 `sport_type` 跟随原运动记录的类型
- 上传表单增加：路线名称、难度、运动类型（可手工修改）

**⑤ 附近路线（nearby_routes_page.dart）**

- 搜索参数增加 `sport_type` 过滤
- 地图上的路线标记点区分跑步/骑行图标

**⑥ 跑迹选择页（run_trace_select_page.dart）**

- 当前用于伴跑/挑战跑时从收藏的跑友跑迹中选一条
- 改为在 SportModeSelectPage 选择跑步→选跑步记录，选骑行→选骑行记录
- 骑行版新建 `cycle_trace_select_page.dart`，逻辑复用但数据源切换

**⑦ 路线后端改动**

```sql
-- Route 模型扩展
ALTER TABLE routes ADD COLUMN sport_type ENUM('run','cycle','both') 
  DEFAULT 'run' COMMENT '运动类型' AFTER id;
ALTER TABLE routes ADD COLUMN surface_type VARCHAR(50) DEFAULT '' 
  COMMENT '路面类型: road/gravel/trail/mixed' AFTER sport_type;
ALTER TABLE routes ADD COLUMN traffic_level ENUM('low','medium','high') 
  DEFAULT 'low' COMMENT '交通流量' AFTER surface_type;
ALTER TABLE routes ADD COLUMN cycling_difficulty TINYINT DEFAULT NULL 
  COMMENT '骑行难度 1~10' AFTER difficulty;

-- 路线列表接口增加参数
-- GET /api/v1/routes?sport_type=run|cycle|all&city=&sort_by=&page=&page_size=
-- GET /api/v1/routes/nearby?lat=&lng=&radius=&sport_type=run|cycle|all
```

**后端 RouteListRequest 改动**：
```go
type RouteListRequest struct {
    Page        int      `json:"page" form:"page"`
    PageSize    int      `json:"page_size" form:"page_size"`
    SportType   string   `json:"sport_type" form:"sport_type"`  // ← 新增
    City        string   `json:"city" form:"city"`
    Difficulty  int8     `json:"difficulty" form:"difficulty"`
    DistanceMin float64  `json:"distance_min" form:"distance_min"`
    DistanceMax float64  `json:"distance_max" form:"distance_max"`
    Keyword     string   `json:"keyword" form:"keyword"`
    SortBy      string   `json:"sort_by" form:"sort_by"`
}
```

#### 5.11.4 其他受影响页面

**⑧ 个人中心统计（profile_page.dart）**

当前：
```
🏃 528km  45次  42h
总距离  次数  总时长
```

**决策：方案 B — 分两行展示**

```
🏃 528km    45次    42h
🚴 72km     12次    3.5h
总距离     次数    总时长
```

改动：
- 后端 `User` 模型新增 `cycling_total_rides`（骑行次数）、`cycling_total_duration`（骑行总时长秒）字段
- Flutter `User` 模型同步增加 `cyclingTotalRides`、`cyclingTotalDuration`，以及对已有的 `cyclingTotalDistance`、`cyclingCompanions`、`cyclingChallengesWon` 等字段完成同步
- `_buildStatsCard` 改为两行布局：第一行跑步（跑步图标+橙色），第二行骑行（骑行图标+蓝色/青色）
- 底部标签行保持不变

**⑨ 发现页快捷入口（discover_page.dart）**

当前三个卡片：
- `Icons.history` → `/history`（运动记录）
- `Icons.map` → `/square`（跑迹广场）
- `Icons.emoji_events` → `/ranking`（排行榜）

改动量最小——入口不变，跳转目标不变，**数据源自然扩展**即可。

但有两个选项供选择：
- **方案 A**：保留三个卡片不变，/history 和 /square 内部已做运动类型筛选
- **方案 B**：把第一个卡片改为「运动记录」动态入口——点击弹 SportModeRecordPicker（选择 跑步记录/骑行记录），但会增加复杂度
- **推荐：方案 A**，简化为佳

**⑩ 路线主页（routes_home_page.dart）**

当前四个子Tab：我的跑迹 / 跑友跑迹 / 上传管理 / 我的热度

**决策： Tab 1「我的跑迹」→「骑友轨迹」**

| 调整 | Tab 1 | Tab 2 | Tab 3 | Tab 4 |
|------|-------|-------|-------|-------|
| 改名 | 🚴 ~~我的跑迹~~ → **骑友轨迹** | 🏃 跑友跑迹 (不变) | 上传管理 (不变) | 我的热度 (不变) |
| 用途 | 收藏骑友的骑行路线 → 伴骑/挑战骑 | 收藏跑友的跑步路线 → 伴跑/挑战跑 | — | — |
| 卡片指标 | 骑行专属：均速/爬升/距离/踏频 | 跑步专属：配速/步频/步幅/距离 | — | — |

**具体改动：**

1. `routes_home_page.dart`：Tab 1 文字从 `l10n.routesTabMy` 改为 `l10n.routesTabCyclists`（新增 L10n 键）
2. `_MyRoutesTab` 组件内容改为骑行路线列表，调用 `friendCyclingRoutesProvider` 或类似 Provider
3. `RouteCard` 组件需要根据运动类型（骑行 vs 跑步）动态切换数据行：
   - 跑步：距离/配速/用时，步频/步幅/心率
   - 骑行：距离/均速/用时，踏频/爬升/功率
4. `_FriendsRoutesTab` 保持原样（跑步），命名上可能需同步调整为 `_FriendsRunningRoutesTab` 以示区分
5. 后端需新增接口 `GET /api/v1/routes/cycling/friends` 返回骑行好友路线数据
6. L10n 新增 `routesTabCyclists` = "骑友轨迹"

**其他子Tab：**

- "上传管理" Tab 的数据源从 `recentRunsProvider` 改为 `recentRecordsProvider`（跑步+骑行混排）
- 上传时自动继承原运动记录的 `sport_type`，用户可在表单页修改
- "我的热度" Tab 暂不涉及骑行统计（骑行热度功能暂缓）

**⑪ 跑友动态 / 帖子（feed_page.dart, post_detail_page.dart）**

- 动态发布：骑行完成后的分享帖添加 🚴 标签
- Feed 流：帖子卡片区分 🏃/🚴（现有实现已按 run 数据渲染，运动类型靠 icon 区分）
- 目前 feed 帖子的 run 引用是 `Run` 模型，骑行完成后需改为通用 `Record` 模型
- 改动较大，**建议此部分列入第二阶段**，初期骑行记录不出现在 Feed 流

**⑫ 发现页本周数据概览（discover_page.dart）**

当前布局：
```
本周数据概览
12.5km    3次    2.5h    1560cal
总距离    次数    总时长   卡路里
```

数据源为 `user.totalDistanceKm/totalRuns/totalDurationSeconds/totalCalories`，仅跑步。

**决策：方案 A — 合并展示，标题改为「本周运动概览」**

- 4列数据改为跑步+骑行的合计值（后端统一返回）
- 标题从「本周数据概览」改为「本周运动概览」
- 不区分运动类型，以简化为先

**⑬ 运动统计页 redesign（running_stats_page.dart → sports_stats_page.dart）**

> 此页即"我的"→ "跑步统计" 入口，现半成品（数据硬编码、图表占位符）。
> 完全对标华为运动健康统计页重建。

**布局（华为模式，根据三张截图还原）：**
```
┌──────────────────────────────────────┐
│  ← 运动统计           所有运动 ▾   │  ← AppBar：运动类型下拉筛选
│  ┌────┬────┬────┬────┐               │
│  │ 周 │ 月 │ 年 │ 总 │               │  ← 4个Tab（比原计划多一个「总」）
│  └────┴────┴────┴────┘               │
│                                      │
│         495.65 km                    │  ← 大号加粗总里程数字
│          2026年 5月                  │  ← 当前周期
│                                      │
│  ┌─ 柱状图 ───────────────────────┐ │
│  │   ██     ████                   │ │
│  │ ██████ ████████  ██ ██          │ │
│  │ ████████████████  ██ ██ ██      │ │
│  │ 1  2  3  4  5  6  7  8  9...    │ │  ← 周期自适应粒度
│  │ 周频/日频展示                    │ │
│  └──────────────────────────────────┘ │
│                                      │
│  运动时长           运动次数         │  ← 两项核心统计
│  91.8 小时          100 次           │
│                                      │
│  ─ 运动时长占比 ──────────────────  │
│                                      │
│  🏃 跑步  89.3 小时     97.4%       │  ← 运动类型拆分占比
│  🚴 骑行   2.4 小时      2.6%       │
└──────────────────────────────────────┘
```

**周期 Tab 对比：**

| Tab | 日期范围 | 图表粒度 | 适用场景 |
|-----|---------|---------|---------|
| 周 | 最近7天 | 每日柱 | 本周运动概览 |
| 月 | 当前月 | 每日柱 | 月度趋势 |
| 年 | 当前年 | 月度柱 | 年度趋势 |
| 总 | 全部历史 | 年度柱 | 总累计数据 |

**决策细节：**

| 维度 | 设计 |
|------|------|
| 运动类型筛选 | AppBar标题行右侧PopMenuButton：「所有运动 ▾」/ 🏃跑步 / 🚴骑行 |
| 日期Tab | 周/月/年/总（4Tab，华为模式） |
| 筛选联动 | 选「所有运动」→ 跑步+骑行合并；选「跑步/骑行」→ 对应类型专项数据 |
| 大数字 | 页面核心展示：总里程（km）加粗大号，下方附当前周期文字 |
| 柱状图 | fl_chart / 自实现，按周期粒度自动切换（日/月/年） |
| 摘要行 | 运动时长(小时) + 运动次数 两项，与华为一致 |
| 占比拆分 | 底部展示跑步vs骑行的时长与百分比，选单项时隐藏此项 |
| 图表库 | 现有占位符 → 引入 fl_chart |
| 文件命名 | `running_stats_page.dart` → `sports_stats_page.dart` |

**数据接口：**
```
GET /api/v1/stats
  ?sport_type=all|run|cycle
  &period=week|month|year|total
  &date=2026-05-12

返回：
{
  "title": "2026年 5月",
  "total_distance": 495.65,        // km（大数字）
  "total_duration": 330480,        // 秒（对应 91.8小时）
  "total_count": 100,              // 次数
  "breakdown": [                    // 运动类型拆分
    {"sport_type": "run",  "duration": 321480, "duration_hours": 89.3, "percentage": 97.4},
    {"sport_type": "cycle", "duration": 8640,  "duration_hours": 2.4,  "percentage": 2.6}
  ],
  "chart_data": [                   // 柱状图数据（周期粒度的分段数据）
    {"label": "1", "value": 12.5},
    {"label": "2", "value": 8.3},
    {"label": "3", "value": 15.7},
    ...
  ]
}
```

**注意：** 此页重构涉及前后端，**建议第四阶段实施**（先跑通骑行核心流程）。

**⑭ 骑行记录详情（cycle_detail_page.dart）**

- 新建 `cycle_detail_page.dart`，对标 `run_detail_page.dart`
- 展示骑行独有指标：均速/踏频/功率/爬升
- 轨迹地图复用路线轨迹展示组件

**⑮ 播报设置 + 播报服务改造**

当前骑行语音播报内容已在 §6.5 定义。本节聚焦前端改造：

**涉及文件：**
| 文件 | 改动 |
|------|------|
| `voice_broadcast_service.dart` | 支持运动类型分支，区分跑步/骑行播报逻辑 |
| `broadcast_settings_page.dart` | 增加运动类型Toggle，跑步/骑行各自独立配置 |
| `storage_service.dart` | 增加骑行播报设置独立存储键 |
| `constants.dart` | 新增骑行播报项枚举、骑行专用频率选项 |

**⑮-a `broadcast_settings_page.dart` — 设置页UI改造**

当前结构：
```
┌─ 播报设置 ─────────────────┐
│ 播放频率                     │
│ ◎ 每1公里  ○ 每5分钟 ...    │
│ 播报内容                     │
│ ☑ 配速 ☑ 距离 ☑ 时长 ☑ 心率 │
│ ☑ 步频 ☑ 步幅 ☑ 爬升 ...    │
│ 语音风格                     │
│ ◎ 标准  ○ 江湖  ○ 教练  ○ 毒舌 │
└──────────────────────────────┘
```

**改造后：**
```
┌─ 播报设置 ──────────────────────┐
│ ┌──────────┬──────────┐          │
│ │ 🏃跑步   │ 🚴骑行   │          │  ← 新增运动类型Toggle
│ └──────────┴──────────┘          │
│                                   │
│ 播放频率（两模式共享）            │
│ ◎ 每1公里  ○ 每5分钟  ...        │
│                                   │
│ 播报内容（根据当前Tab变化）        │
│ ─── 跑步Tab ───                   │
│ ☑ 配速  ☑ 距离  ☑ 时长  ☑ 心率  │
│ ☑ 步频  ☑ 步幅  ☑ 爬升           │
│ ─── 骑行Tab ───                   │
│ ☑ 均速  ☑ 距离  ☑ 时长  ☑ 心率  │
│ ☑ 踏频  ☑ 爬升  ☑ 卡路里         │
│ ☐ 功率（外设支持时可用）           │
│                                   │
│ 语音风格（按模式切换列表）         │
│ 🏃跑步: ◎ 标准  ○ 江湖  ○ 教练  ○ 毒舌 │
│ 🚴骑行: ◎ 标准  ○ 教练             │
│         ○ 环法解说  ○ 休闲骑游    │  ← 替换江湖/毒舌
│ [保存]                             │
└───────────────────────────────────┘
```

**规则：**
- 频率：跑步/骑行共享同一设置
- 播报内容独立存储（两套 `_selectedItems`，分别保存到 Hive）：
  - 存储key: `broadcast_items_run` / `broadcast_items_cycle`
- **语音风格拆分**：总数为4种不增加，按模式切换列表
  - 🏃跑步Tab显示：标准 / 江湖 / 教练 / 毒舌（原4种不变）
  - 🚴骑行Tab显示：**标准 / 教练 / 环法解说 / 休闲骑游**（替换江湖/毒舌）
  - `voice_styles` 常量表新增 `'tour_de_france'`（环法解说）、`'leisure_ride'`（休闲骑游）
  - 跑步风格选了「江湖」或「毒舌」时，切到骑行Tab时自动切换为默认「标准」
- `voice_styles` 常量表扩展加入骑行特有风格

**⑮-b `voice_broadcast_service.dart` — 服务层改造**

当前 `RunSessionState` 包含跑步专有字段（avgPace, cadence as 步频等）。

改造方案：
1. `RunSessionState` 增加 `sportType` 字段（run/cycle）
2. 广播文本构建函数 `_buildBroadcastText` 根据 `sportType` 路由：
   - run → 现有逻辑（配速/步频/步幅）
   - cycle → 新分支（均速/踏频/功率）
3. 骑行版播报文本模板：
   - "均速 XX.X 公里/小时"（替代 "配速 XX'XX\"/公里"）
   - "踏频 XX 转/分钟"（替代 "步频 XX 步/分钟"）
   - "爬升 XX 米，坡度 X%"
4. 异常检测适配骑行：心率阈值、速度骤降检测
5. 伴骑/挑战骑文本：
   - "领先对手 XX 米" / "落后对手 XX 秒"
   - "对手均速 XX km/h，你比他快 XX"
6. `reset()` 触发时机改为骑行开始时调用

**⑮-c 存储层改造 `storage_service.dart`**

```dart
// 新增存储方法：
Future<void> setBroadcastItemsForSport(String sportType, List<String> items)
List<String> getBroadcastItemsForSport(String sportType)
```

内部使用 key: `broadcast_items_run`, `broadcast_items_cycle`

**⑮-d 骑行中页调用（CyclingPage）**

骑行过程中每公里/定时调用 `VoiceBroadcastService.onStateUpdate()`，传入
带 `sportType: "cycle"` 的 `RunSessionState`。

```dart
// 伪代码
final broadcast = VoiceBroadcastService();
broadcast.onStateUpdate(RunSessionState(
  sportType: 'cycle',
  currentRun: cycleRecord,
  broadcastFrequency: frequency,
  broadcastItems: items,
  voiceStyle: style,
  runMode: mode,  // solo/companion/challenge
));
```

---

### 6.1 数据维度映射表

| 跑步数据 | 单位 | 骑行数据 | 单位 | 说明 |
|----------|------|----------|------|------|
| 配速 | min/km | **均速** | km/h | 速度表现 |
| 心率 | bpm | **心率** | bpm | 体力负荷指标，车把传感 |
| 步频 | spm（步/分钟） | **踏频** | rpm（转/分钟） | 踩踏频率 |
| 步幅 | m（米） | **功率** | W（瓦特） | 踩踏效率（L3设备） |
| 爬升 | m | **爬升** | m | 海拔增益 |
| 距离 | km | **距离** | km | 里程 |
| — | — | **时速** | km/h | 瞬时速度（骑行特有） |

### 6.2 独自骑（Solo Ride）

- 对标：独自跑
- 功能：GPS 轨迹记录 + 实时心率采集 + 踏频记录
- 语音播报：每公里/每5分钟播报均速、心率、踏频、里程
- 跑后：骑行记录存入 `cycling_records`，自动匹配路线

### 6.3 伴骑（Companion Cycling）

- 对标：伴跑（Companion Run）
- 核心逻辑：选一条已收藏的跑友/骑友运动记录，跟着对方的幽灵数据骑
- 跑友的跑步记录 → 骑行时自动转换成骑行对应数据（配速→均速映射）

**伴骑 GhostMode（与伴跑一致，追加骑行版）：**

| 模式 | 跑步版 | 骑行版 | 说明 |
|:----|:-------|:-------|:------|
| **真实复刻** | 还原对方配速变化 | 还原对方均速变化 | 按对方原始速度曲线骑行 |
| **匀速目标** | 对方平均配速匀速 | 对方平均均速匀速 | 适合新手跟骑训练 |
| **兔式超前** | 快5%前跑 | 快5%前骑 | 初期冲劲，体验领先 |
| **龟兔模式** | 前快后慢 | 前快后慢 | 挑战后段耐力 |
| **目标挑战** | 选维度挑战极限 | 选维度挑战极限 | 均速/心率/踏频/功率 |

**骑行版新增 GhostMode 场景：**

| 模式 | 说明 |
|:----|:------|
| **爬坡模式** | 上坡段自动减速匹配坡度，下坡段自由冲刺 | 
| **编队模式** | 尾流模拟（虚拟降低风阻，显示预期节省时间） |

**伴骑规则：**
- 对手数据可以是跑步记录或骑行记录
- 跑步记录 → 骑行自动换算：配速→均速 (`60/pace_in_min_per_km`)
- 不保存骑行记录到挑战数据（同伴跑规则）
- 仅更新路线热度

### 6.4 挑战骑（Challenge Cycling）

- 对标：挑战跑（Challenge Run）
- 核心逻辑：选一条已收藏的运动记录发起挑战，跑后系统对比数据判胜负

**挑战指标：**

| 指标 | 单位 | 说明 | 对应跑步指标 |
|:----|:----|:------|:-----------|
| 均速 | km/h | 整段路线平均速度 | 配速 |
| 心率 | bpm | 同均速下心率更低者优 | 心率 |
| 踏频 | rpm | 同均速下更优者胜 | 步频 |
| 功率（L3） | W | 同均速下功率更优者胜 | 步幅 |
| 爬升 | m | 累计爬升 | 爬升 |
| 总用时 | s | 路线完成时间 | 总用时 |

**挑战骑规则：**
- GhostMode **固定为「真实复刻」**（同挑战跑）
- 跑友的跑步记录可以作为挑战骑的对手（配速→均速映射）
- 骑友的骑行记录可以作为挑战跑的对手（均速→配速映射）
- 支持「跨运动挑战」：跑友张三跑步 10km 配速 5:00，骑友李四挑战骑 10km 均速需 ≥12km/h 即胜

**挑战跨运动换算参考：**

```
跑步配速 5:00/km → 对应骑行均速 ≈ 12 km/h
跑步配速 6:00/km → 对应骑行均速 ≈ 10 km/h
跑步配速 4:30/km → 对应骑行均速 ≈ 13.3 km/h
骑行均速 20 km/h → 对应跑步配速 ≈ 3:00/km（明显不同努力程度）

※ 跨运动挑战仅供参考娱乐，不纳入正式段位积分
```

### 6.5 语音播报（骑行版）

**播报频次：** 每公里 / 每10分钟 / 爬坡预警 / 心率超阈值

**播报项：**

| 播报项 | 触发 | 语音内容（示例） |
|--------|------|-----------------|
| 均速 | 每公里 | "当前均速 22.3 公里每小时，比上一公里快了 1.2" |
| 心率 | 每公里 | "当前心率 148" |
| 踏频 | 每公里 | "踏频 79 转" |
| 爬升提醒 | 检测到上坡 | "前方连续上坡约 800 米，建议保持踏频" |
| 差距（骑行版） | 伴骑/挑战骑每公里 | "落后对手 12 秒，差距在缩小" |
| 冲刺提醒 | 最后 1km | "最后一公里，冲一把！" |
| 打鸡血 | 随机触发 | "今天的均速已经超越 80% 的骑友！" |

**骑行版特有语音风格：**
- **环法解说风**："来自驰陌的选手正在加速，前方还有 500 米坡顶！"
- **休闲骑游风**："慢慢骑，风景在路上 🌅"（非竞技场景）
- **教练风**："踏频过低了，建议降档提升踏频到 80 以上"

### 6.6 AI 骑行诊断（AI Ride Analysis）

基于 `ai_features_integration_plan.md` 扩展：

| AI 功能 | 跑步版 | 骑行版 |
|----------|--------|--------|
| AI 跑情分析 | 跑步详情页底部 | 骑行详情页底部 |
| AI 骑行教练 | 跑步中实时播报 | 骑行中实时播报（关注踏频/均速/心率） |
| AI 路线推荐 | 跑步路线 | 骑行路线（筛选适合骑行的路面/交通评级） |
| AI 帮写评论 | 跑步动态 | 骑行动态 |
| AI 找搭档 | 跑步伴跑 | 骑行伴骑 |
| AI 每日金句 | 跑步金句 | **骑行金句混合**（"骑 100 公里比跑马拉松更需要勇气"） |
| AI 路线审核 | 跑步路线 | 骑行路线（增加路面类型/交通流量评估） |

---

## 七、成就体系扩展——双轨独立勋章

> ⚠️ **骑行勋章系统 - 待定**
>
> **已确定：** 跑境与骑境双轨独立晋升。
> **待定：** 骑行勋章的具体形式、名称、级数。下方§7.1~§7.6内容为基于境界-配速体系.md的占位方案（借用跑步13境命名体系+骑行判境条件），待后续确定后替换。
> — 2026-05-12

### 7.1 核心理念：两套勋章墙，双倍成就感

> 用户声音："很多人既喜欢跑步又喜欢骑行怎么办？"
> 答案：**两套独立勋章墙，你的境界取最高值，但勋章各亮各的。**

**关键原则：**
1. **十三境命名体系不变** — 炼气到道祖，跑步和骑行共用同一套境界名
2. **各自独立晋升** — 跑步的进展不影响骑行，反之亦然
3. **用户主页展示最高境界** — 只显示一个主境界（取跑步/骑行中更高的那个）
4. **两扇勋章墙** — 跑步十三境一页，骑行十三境一页，双修用户两面都点亮
5. **双修成就作为额外彩蛋** — 不是替代，而是叠加

---

### 7.2 骑行十三境判境标准

沿用跑步版十三境命名体系（炼气到道祖），但条件适配骑行特性：

**下五境（距离）：**

| 境界 | 跑步判境（原标准） | **骑行判境（新）** | 说明 |
|------|-----------------|-------------------|------|
| **炼气** | 首次跑步 | **首次骑行** | 任何骑行即入 |
| **筑基** | 单次跑完 5km | **单次骑完 20km** | 4x跑步距离大约相等消耗 |
| **结丹** | 单次跑完 10km | **单次骑完 40km** | 城市通勤一趟 |
| **元婴** | 单次跑完 半马 | **单次骑完 80km** | 周末休闲骑 |
| **化神** | 单次跑完 全马 | **单次骑完 160km** | 百英里骑行 |

**上八境（速度/均速）：**

| 境界 | 跑步（全马配速） | **骑行（100km均速）** | 均速对应 |
|------|----------------|---------------------|---------|
| **练虚** | 全马 <= 3:00:00 | **100km均速 >= 33.3 km/h** | 100km 3h内 |
| **合体** | 全马 <= 2:45:00 | **100km均速 >= 36.4 km/h** | 100km 2h45m内 |
| **大乘** | 全马 <= 2:30:00 | **100km均速 >= 40.0 km/h** | 100km 2h30m内 |
| **真仙** | 全马 <= 2:20:00 | **100km均速 >= 42.9 km/h** | 100km 2h20m内 |
| **金仙** | 全马 <= 2:15:00 | **100km均速 >= 44.4 km/h** | 100km 2h15m内 |
| **太乙** | 全马 <= 2:10:00 | **100km均速 >= 46.2 km/h** | 100km 2h10m内 |
| **大罗** | 全马 <= 2:05:00 | **100km均速 >= 48.0 km/h** | 100km 2h05m内 |
| **道祖** | 全马 < 2:00:00 | **100km均速 > 50.0 km/h** | 100km 2h内 |

---

### 7.3 用户身份显示方案

```
用户主页
  头像区域
  [头像]  化神
          全马真人
          🏃🚴 双修

  勋章墙（左右滑动翻页）

  [第1页 🏃 跑步十三境]
  气✨ 筑✨ 丹✨ 婴✨ 化✨ 🌫虚 🌫合 ...
  底标签: 🏃 跑步              < >

  [第2页 🚴 骑行十三境]
  气✨ 筑✨ 丹✨ 🌫婴 🌫化 🌫虚 ...
  底标签: 🚴 骑行              < >

  [第3页 🎖️ 双修成就]
  🔄 初入双修 ✨  ⚔️ 双剑合璧 🌫 ...
  底标签: 🎖️ 成就             < >

  境界状态：
  🏃 跑步境界：化神（全马 4:30:00）
  🚴 骑行境界：结丹（单次 52km）
  主境界取最高：🏃 化神
```

**显示规则：**
- **头像右下角徽章** — 显示主境界（取更高者），不区分运动
- **头像圈色边** — 蓝=仅跑步 / 橙=仅骑行 / 绿=双修
- **主页段位标题** — 根据主境界来源自动切换："化神 · 全马真人" 或 "结丹 · 骑行百公里"
- **勋章墙** — 左右滑动切换三页

---

### 7.4 骑行成就徽章

骑行专属徽章，显示在骑行十三境勋章墙周围作为补充：

| 徽章 | 触发条件 | 稀有度 |
|------|----------|--------|
| 🚴 首骑 | 完成第一次骑行 | 🥉 |
| ⚡ 追风 | 瞬时速度 >=50km/h | 🥈 |
| 🏔 爬坡王 | 单次爬升 >=500m | 🥈 |
| 🌙 夜骑侠 | 夜间骑行累计 10 次 | 🥉 |
| 🗺 百路通 | 累计完成 100 条不同骑行路线 | 🥇 |
| 🏆 挑战王 | 赢得 10 次挑战骑 | 🥇 |
| 🚴 千公里 | 累计骑行 1,000 km | 🥉 |
| 🚴 万公里 | 累计骑行 10,000 km | 💎 |

---

### 7.5 双修专属成就

双修用户额外解锁第三页成就墙（叠加，非替代）：

| 徽章 | 触发条件 | 稀有度 |
|------|----------|--------|
| 🔄 初入双修 | 跑步+骑行均达到筑基 | 🥉 |
| ⚔️ 双剑合璧 | 跑步+骑行均达到元婴 | 🥈 |
| 🐉 龙骑虎步 | 跑步+骑行均达到化神 | 🥇 |
| ☯️ 道法自然 | 跑步+骑行均达到练虚 | 💎 |
| ⭐ 破界飞升 | 跑步+骑行均达到真仙 | 👑 |
| 🌈 无极之境 | 跑步+骑行均达到道祖 | 🏆 |

---

### 7.6 判境数据字段扩展（User 模型新增）

```dart
// 骑行独立（跑步境界字段不变）
cyclingRealm: String?              // 骑行境界
cyclingRealmBadges: List<String>?  // 骑行已获勋章列表
cyclingRealmProgress: double?      // 骑行晋升进度 0.0~1.0
cyclingBestDistance: double?       // 单次最佳骑行距离
cyclingBestSpeed: double?          // 最佳均速 km/h
cyclingBestTimed_100km: int?       // 100km计时赛最优(秒)
cyclingTotalDistance: double?      // 累计骑行里程
cyclingCompanions: int?            // 伴骑完成次数
cyclingChallengesWon: int?         // 挑战骑胜利次数

// 主境界计算（后端自动）
// mainRealmIndex = max(runningRealmIndex, cyclingRealmIndex)
// mainRealmLabel = names[mainRealmIndex]
// mainRealmSource = running >= cycling ? 'run' : 'cycle'
```

> **SQL 扩展：** users 表新增以上 cycling_* 字段，采用与 realm_* 字段相同的判境逻辑，由后端自动计算。## 八、设备生态与多平台支持

### 8.1 骑行设备兼容性

| 设备类型 | 连接方式 | 可获取数据 | 支持阶段 |
|----------|---------|-----------|---------|
| 🚴 **驰陌智能模组** | BLE 5.2 | GPS + 心率 + 踏频 + 加速度 | Phase 1 |
| ⌚ Apple Watch | HealthKit | 心率（骑手佩戴手表时） | Phase 1 |
| ⌚ 华为手表/手环 | HMS Health Kit | 心率 + GPS（备用） | Phase 2 |
| ⌚ Garmin Edge/Forerunner | Garmin API | 全量骑行数据导入 | Phase 2 |
| 💓 心率带 (BLE HRM) | BLE 标准 HRM 协议 | 高精度心率 | Phase 1 |
| 🔄 Wahoo 码表 | BLE/Wahoo API | 全量骑行数据 | Phase 3 |
| 🔄 佳明 Edge 码表 | Garmin API | 全量骑行数据 | Phase 3 |
| 📱 手机 GPS（无硬件） | 手机内置 GPS | 仅 GPS 轨迹（无心率/踏频） | Phase 0（最简模式） |

### 8.2 最简模式（Phase 0 — 无需硬件）

用户即使没有绑定自行车硬件，也可以记录骑行：
- 选择「骑行模式」→ 手机 GPS 记录轨迹
- 无心率/踏频数据
- 仍可参与路线社交、路线收藏、排行榜
- 鼓励用户后续绑定硬件获取更多功能

### 8.3 多车支持

```
用户可绑定多辆自行车：

我的车库
├── 🚴 我的战车（GIANT TCR Adv）← 活跃中
│    累计 1,247 km · 上次骑行 2天前
├── 🚴 通勤车（MERIDA 探索者）← 今天骑过
│    累计 342 km · 电池 60%
└── 🚴 共享单车（临时绑定）
     累计 12 km · 无心率数据

App 自动按「蓝牙连接检测」识别当前骑的是哪辆车
→ BLE 连接时读取硬件 ID
→ 自动切换到对应车辆的统计
```

---



## 八、设备生态与多平台支持

### 8.1 骑行设备兼容性

| 设备类型 | 连接方式 | 可获取数据 | 支持阶段 |
|----------|---------|-----------|---------|
| 驰陌智能模组 | BLE 5.2 | GPS + 心率 + 踏频 + 加速度 | Phase 1 |
| Apple Watch | HealthKit | 心率（骑手佩戴手表时） | Phase 1 |
| 华为手表/手环 | HMS Health Kit | 心率 + GPS（备用） | Phase 2 |
| Garmin Edge/Forerunner | Garmin API | 全量骑行数据导入 | Phase 2 |
| 心率带 (BLE HRM) | BLE 标准 HRM 协议 | 高精度心率 | Phase 1 |
| Wahoo 码表 | BLE/Wahoo API | 全量骑行数据 | Phase 3 |
| 佳明 Edge 码表 | Garmin API | 全量骑行数据 | Phase 3 |
| 手机 GPS（无硬件） | 手机内置 GPS | 仅 GPS 轨迹（无心率/踏频） | Phase 0 |

### 8.2 最简模式（Phase 0 — 无需硬件）

用户即使没有绑定自行车硬件，也可以记录骑行：
- 选择「骑行模式」-> 手机 GPS 记录轨迹
- 无心率/踏频数据
- 仍可参与路线社交、路线收藏、排行榜
- 鼓励用户后续绑定硬件获取更多功能

### 8.3 多车支持

用户可绑定多辆自行车：

`
我的车库
- 我的战车（GIANT TCR Adv） 活跃中
  累计 1,247 km . 上次骑行 2 天前
- 通勤车（MERIDA 探索者） 今天骑过
  累计 342 km . 电池 60%
- 共享单车（临时绑定）
  累计 12 km . 无心率数据
`

App 自动按蓝牙连接检测识别当前骑的是哪辆车：
BLE 连接时读取硬件 ID -> 自动切换到对应车辆的统计

## 九、商业模式

### 9.1 收入来源

| 收入项 | 目标客户 | 收费模式 | 预估单价 |
|--------|---------|---------|---------|
| **自行车厂 B2B** | 自行车 OEM/ODM 厂商 | 每车激活授权费 | ¥5~15/车 |
| **驰陌骑行订阅** | 骑行用户 | ¥9.9/月 或 ¥99/年 | ¥99/年 |
| **骑行数据分析** | 自行车品牌/赛事方 | 批量用户骑行数据报告 | ¥10,000+/份 |
| **品牌挑战赛** | 品牌赞助商 | 每场赛事品牌冠名 | ¥20,000~50,000/场 |
| **硬件升级** | 已绑定用户 | 踏频传感器/功率计配件 | ¥199~999 |

### 9.2 B2B 自行车厂合作定价

| 合作层级 | 模式 | 售价影响 | 驰陌收入 | 用户收益 |
|----------|------|---------|---------|---------|
| **L1 基础** | 预装驰陌芯片模组 | +¥30~50/车 | ¥5~15/车激活 | 免费基础骑行记录 |
| **L2 标准** | L1 + 手机配对 SDK | +¥80~120/车 | ¥8~20/车 | 高级骑行分析+AI |
| **L3 旗舰** | 联合品牌仪表盘 | +¥200~500/车 | 项目制 | 全部功能+品牌联名 |

### 9.3 免费 vs 付费功能

| 功能 | 免费用户 | 订阅用户 |
|------|---------|---------|
| 骑行 GPS 记录 | ✅ | ✅ |
| 伴骑 | ✅ | ✅ |
| 挑战骑 | ✅ | ✅ |
| 路线收藏/分享 | ✅ | ✅ |
| AI 骑行诊断 | ❌ | ✅（每月 30 次） |
| 高级骑行分析（功率曲线/疲劳分析） | ❌ | ✅ |
| BLE 外接设备（踏频/功率计） | ❌ | ✅ |
| 历史数据导出（GPX/CSV） | ❌ | ✅ |
| AI 骑行教练（实时语音） | ❌ | ✅ |
| 无广告 | ❌ | ✅ |

---

## 十、分阶段实施路线图

| 阶段 | 内容 | 工时估算 | 优先级 |
|------|------|---------|--------|
| **Phase 0: 手机骑行基本版** | 骑行模式+手机GPS记录+路线关联+骑行记录表 | 1 周 | 🔴 |
| **Phase 1: 伴骑+挑战骑** | 伴骑系统+挑战骑+对比报告+排行榜 | 2 周 | 🔴 |
| **Phase 2: 硬件绑定** | BLE 通信协议+自行车管理+扫码绑定+心率/踏频接入 | 2 周 | 🔴 |
| **Phase 3: 语音播报+AI** | 骑行语音播报+AI骑行诊断+AI骑行教练 | 2 周 | 🟡 |
| **Phase 4: 跑境成就** | 骑行段位+成就徽章+面板统计 | 1 周 | 🟡 |
| **Phase 5: B2B 合作** | 车厂管理后台+激活码体系+数据分析报告 | 2 周 | 🟢 |
| **Phase 6: 跨运动** | 跑步⇄骑行数据映射+跨运动挑战+统一段位积分 | 1 周 | 🟢 |
| **Phase 7: 社区生态** | 骑行路线推荐+骑行活动+品牌挑战赛 | 2 周 | 🟢 |

**总估算：** ~13 周（3.25 个月），其中核心功能（Phase 0~2）约 5 周。

---

## 十一、跨运动数据融合（超前规划）

### 11.1 统一运动数据模型

长远目标：驰陌成为一个**多运动社交平台**，跑步和骑行只是前两个品类。

```
统一运动模型（SportActivity）
├── 🏃 跑步（Running）
│   ├── 数据: 配速/心率/步频/步幅
│   └── 模式: 独自跑/伴跑/挑战跑
├── 🚴 骑行（Cycling）
│   ├── 数据: 均速/心率/踏频/功率
│   └── 模式: 独自骑/伴骑/挑战骑
├── 🏊 游泳（Swimming）← 未来
├── 🥾 徒步（Hiking）← 未来
└── 🎿 滑雪（Ski）← 未来
```

### 11.2 统一路线模型

路线不再限定运动品类，同一条路线可被跑步和骑行共用：

```
route.sport_type = "both"
→ 跑者完成标记为 run 记录
→ 骑者完成标记为 cycling 记录
→ 排行榜分运动品类各自排名
→ 跨运动对比仅作为趣味参考
```

### 11.3 统一健康积分（待定）

```
跑步 1km = 10 积分
骑行 1km = 3 积分   （骑行距离通常更长）
跑步/骑行都计入总"运动积分"
积分决定用户等级/地位/解锁功能
```

---

## 十二、风险管理 & 技术难点

| 风险 | 影响 | 缓解方案 |
|------|------|---------|
| BLE 连接不稳定 | 骑行中数据断流 | 本地缓存+断点续传+离线模式 |
| GPS 信号差（隧道/林荫道） | 轨迹偏移/断开 | GPS+IMU 融合定位 |
| 心率传感器精度（车把触摸式） | 心率数据不准 | 鼓励佩戴心率带+数据平滑过滤 |
| 自行车厂合作谈判周期长 | B2B 收入延迟 | Phase 0 先做手机版验证需求 |
| 电池续航（GPS+BLE） | 用户骑行中途没电 | 低功耗算法+电量预警提醒 |
| 跑步/骑行混合路线归属 | 一条路线既有跑步数据又有骑行数据 | 按 sport_type 分区排行 |

---

## 十三、与现有系统的关系

| 现有模块 | 关系 | 改动程度 |
|----------|------|---------|
| `routes` 路线 | 骑车路线共用，新增骑行字段 | 小改 |
| `runs` 跑步记录 | 新增 `cycling_records` 表，模式平行 | 新增 |
| `challenges` 挑战 | 扩展 sport_type 字段，重写查询逻辑 | 中改 |
| `comparisons` 对比 | 扩展 sport_type 字段 | 小改 |
| `devices` 设备 | 新增自行车设备类型 | 小改 |
| 排行榜 | 新增骑行路线排行 | 新增路由 |
| 社交动态 | 新增骑行动态类型 | 小改 |
| 好友关系 | 不变（跨运动通用） | 不改 |
| 推送通知 | 新增骑行相关推送模板 | 小改 |
| 后台管理 | 新增自行车管理/骑行数据统计面板 | 新增页面 |

---

## 十四、附录

### A. 骑行关键指标计算公式

| 指标 | 公式 | 说明 |
|------|------|------|
| 均速 | `距离(km) / 总用时(h)` | |
| 踏频 | `每分钟曲柄完整旋转次数` | 通过加速度计检测 |
| 功率 | `扭矩 × 角速度` | 需要专用功率计（L3） |
| 疲劳指数 | `∫(心率-基础心率)/阈值心率 dt` | 基于心率的累积负荷估算 |
| 爬升 | `∑max(0, 海拔差)` | 逐点计算正海拔增益 |
| 最大均速 | `连续5秒最高速度` | 防止 GPS 跳点干扰 |

### B. 与华为/Apple 等健康平台的关系

骑行数据同样遵循 `device-management-design.md` 的同步流程：

```
自行车模组记录 → BLE → 驰陌 App → 可选写入 Health Connect / Apple Health
                                                                      ↓
                                              健康平台骑行记录 → 可被其他 App 读取
```

驰陌负责记录，同时可选择性写入健康平台（用户授权），不做强绑定。

### C. FAQ

**Q: 没有绑定的自行车可以用骑行功能吗？**
A: 可以。手机 GPS 记录轨迹，无心率/踏频数据，功能不受限。

**Q: 跑步和骑行的路线可以互相挑战吗？**
A: 可以，但仅限趣味参考（跨运动换算公式），不计入正式段位积分。

**Q: 已经绑定的自行车可以换用户吗？**
A: 可以。用户解绑后，车辆恢复未绑定状态，新用户扫码重绑。

**Q: 共享单车能用吗？**
A: 共享单车缺少硬件 ID，不支持心率/踏频，但可以用手机 GPS 记录骑行轨迹。未来可推出"临时绑定"功能，扫码共享单车后自动匹配车型。

**Q: 骑行是否保存到 Apple Health/华为健康？**
A: 是。用户可选择写入健康平台，让其他 App 也能获取骑行数据。
