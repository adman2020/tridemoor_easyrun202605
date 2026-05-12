# 驰陌 StrideMoor 管理端方案（RuoYi 原生版）

> 版本：v3.1 | 日期：2026-05-10
> 框架：RuoYi-Vue3（Spring Boot 3.x + Vue 3 + Element Plus）
> 目标：依托若依框架，为驰陌构建完整 Web 管理后台

---

## 一、项目定位

### 1.1 一句话定义

> 驰陌管理端 = 一个**若依模块**（`ruoyi-stridemoor`），插在标准 RuoYi 项目里，读取/写入 `stridemoor` 数据库，完成运营管理操作。

### 1.2 架构关系

```
┌─ RuoYi 标准层 ──────────────────────────────────────────────┐
│  ruoyi-admin     ← 启动入口                                  │
│  ruoyi-system    ← 管理员管理/角色/菜单/字典/日志（不动）     │
│  ruoyi-common    ← 工具类/数据源/权限（不动）                 │
│  ruoyi-generator ← 代码生成器（开发阶段用）                    │
│  ruoyi-quartz    ← 定时任务管理                              │
├─ 驰陌业务模块 ──────────────────────────────────────────────┤
│  ruoyi-stridemoor ← 本方案所有功能都在这里（新增模块）        │
└──────────────────────────────────────────────────────────────┘
     │ 多数据源
     ├──────────────┬───────────────────────────────────────┐
     ▼              ▼                                       │
  ry_stridemoor   stridemoor                                │
  (RuoYi原生表)    (驰陌业务表,与Go后端共用)                    │
                                            Go 后端也连这个库  │
```

### 1.3 数据流向原则

```
RuoYi → stridemoor 库：只写运营相关字段
  ├── posts.review_status / is_hidden       ← 审核状态
  ├── routes.name / description / status    ← 改名/上下架
  ├── routes.deleted_at                     ← 软删除
  ├── runs.deleted_at                       ← 清理零距离
  └── post_reviews / admin_roles 表         ← 新表（RuoYi 全权管理）

RuoYi → ry_stridemoor 库：管理员自身数据
  ├── sys_user           ← 管理员账号
  ├── sys_role           ← 角色（超管/运营/审核员）
  ├── sys_menu           ← 管理端菜单权限
  ├── sys_oper_log       ← 操作审计日志
  └── sys_dict_data      ← 数据字典（审核状态、距离档位等）
```

---

## 二、项目初始化（RuoYi 标准流程）

### 2.1 从模板创建

```bash
# 方案：基于 RuoYi-Vue3 官方模板二次开发
git clone https://github.com/yangzongzhuan/RuoYi-Vue3.git
# 或下载 zip 包
# 项目名改为 ruoyi-stridemoor-admin

# 项目结构（关键部分）
ruoyi-stridemoor-admin/
├── ruoyi-admin/                # Spring Boot 启动类（不动）
├── ruoyi-system/               # 系统管理（不动）
├── ruoyi-generator/            # 代码生成（开发期用，部署可删）
├── ruoyi-common/               # 公共模块（不动）
├── ruoyi-framework/            # 框架配置（不动）
├── ruoyi-quartz/               # 定时任务（不动）
│
├── ruoyi-stridemoor/           # ← 本方案的新模块（全部代码在这里）
│   ├── pom.xml
│   └── src/main/java/com/ruoyi/stridemoor/
│       ├── controller/         # 控制器
│       ├── domain/             # 实体（映射 stridemoor 库表）
│       ├── mapper/             # MyBatis Mapper
│       ├── service/            # 业务逻辑
│       └── dto/                # 自定义 DTO
│
└── ruoyi-ui/                   # 前端（Vue 3）
    └── src/views/stridemoor/   # ← 驰陌管理页面
```

### 2.2 模块集成

在 `ruoyi-admin/pom.xml` 添加依赖：
```xml
<dependency>
    <groupId>com.ruoyi</groupId>
    <artifactId>ruoyi-stridemoor</artifactId>
</dependency>
```

在 `ruoyi-admin` 启动类的 `@SpringBootApplication` 加扫描包：
```java
// 默认已有 scanBasePackages = "com.ruoyi"
// 框架会自动扫描 ruoyi-stridemoor 下的 @Component @Service @Controller
// 只要模块包名是 com.ruoyi.stridemoor 即可，无需额外配置
```

### 2.3 多数据源配置

RuoYi 内置多数据源支持（`com.ruoyi.common.annotation.DataSource`），配置如下：

```yaml
# application-druid.yml（RuoYi 标准配置）
spring:
  datasource:
    druid:
      # 主库：RuoYi 自身（管理员体系）
      master:
        url: jdbc:mysql://127.0.0.1:3308/ry_stridemoor?useUnicode=true&characterEncoding=utf8mb4&serverTimezone=Asia/Shanghai
        username: root
        password: xxxxx
        
      # 从库：驰陌业务库（仅此一个从库）
      slave:
        enabled: true
        url: jdbc:mysql://127.0.0.1:3308/stridemoor?useUnicode=true&characterEncoding=utf8mb4&serverTimezone=Asia/Shanghai
        username: stridemoor
        password: stridemoor_pass_2026
```

在代码中使用：
```java
@DataSource("slave")           // 查 stridemoor 库
public List<Post> list(Post post) { ... }

@DataSource(DataSourceType.MASTER)  // 查 ry_stridemoor 库（默认）
public List<SysUser> list(SysUser user) { ... }
```

---

## 三、数据库变更清单

### 3.1 驰陌库（stridemoor）新增表和字段

```sql
-- ==============================
-- 1. posts 表加审核相关字段
-- ==============================
ALTER TABLE `posts` 
  ADD COLUMN `review_status` TINYINT DEFAULT 0 COMMENT '审核状态: 0待审 1通过 2拒绝' AFTER `content`,
  ADD COLUMN `is_hidden` TINYINT(1) DEFAULT 0 COMMENT '管理员隐藏: 0正常 1隐藏' AFTER `review_status`,
  ADD INDEX `idx_review_status` (`review_status`);

-- ==============================
-- 2. 跑迹审核记录表（若依代码生成）
-- ==============================
CREATE TABLE IF NOT EXISTS `post_reviews` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `post_id`         CHAR(36) NOT NULL COMMENT '被审核的posts.id',
    `reviewer_id`     BIGINT COMMENT '审核人ID（ry_stridemoor.sys_user.id）',
    `status`          TINYINT DEFAULT 0 COMMENT '状态: 0待审 1通过 2拒绝',
    `reject_reason`   VARCHAR(500) COMMENT '拒绝原因',
    `review_note`     VARCHAR(500) COMMENT '审核备注',
    `auto_reviewed`   TINYINT(1) DEFAULT 0 COMMENT '是否自动审核',
    `auto_score`      TINYINT COMMENT '自动审核评分',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_post_id` (`post_id`),
    INDEX `idx_status` (`status`),
    CONSTRAINT `fk_review_post` FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='跑迹审核记录';

-- ==============================
-- 3. 管理员角色表（若依代码生成）
-- ==============================
CREATE TABLE IF NOT EXISTS `admin_roles` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `user_id`         BIGINT NOT NULL COMMENT '管理员ID（ry_stridemoor.sys_user.id）',
    `role_type`       VARCHAR(20) NOT NULL DEFAULT 'operator' COMMENT 'super_admin/admin/operator',
    `is_active`       TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_user` (`user_id`),
    INDEX `idx_role` (`role_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员角色表';

-- ==============================
-- 4. 重复路线分组表（若依代码生成）
-- ==============================
CREATE TABLE IF NOT EXISTS `duplicate_groups` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `route_a_id`      CHAR(36) NOT NULL COMMENT '路线A ID',
    `route_b_id`      CHAR(36) NOT NULL COMMENT '路线B ID',
    `similarity`      DECIMAL(5,2) NOT NULL COMMENT '相似度(%)',
    `distance_diff`   DECIMAL(10,2) COMMENT '距离差值(m)',
    `status`          TINYINT DEFAULT 0 COMMENT '0待处理 1已忽略 2已合并',
    `merged_to_id`    CHAR(36) COMMENT '合并到的路线ID',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_pair` (`route_a_id`, `route_b_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='重复路线分组';

-- ==============================
-- 5. 数据清理日志表（若依代码生成）
-- ==============================
CREATE TABLE IF NOT EXISTS `cleanup_logs` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `cleanup_type`    VARCHAR(50) NOT NULL COMMENT '清理类型: zero_distance / short_run / abnormal',
    `total_count`     INT NOT NULL DEFAULT 0 COMMENT '清理总数',
    `details`         JSON COMMENT '清理明细JSON（被清理的ID列表）',
    `operator_id`     BIGINT COMMENT '操作人ID',
    `is_auto`         TINYINT(1) DEFAULT 0 COMMENT '是否自动清理',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_type` (`cleanup_type`),
    INDEX `idx_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据清理日志';

-- ==============================
-- 6. AI API 密钥配置表（若依代码生成）
-- ==============================
CREATE TABLE IF NOT EXISTS `ai_api_keys` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `provider`        VARCHAR(50) NOT NULL COMMENT '供应商: openai / claude / kiro / minimax / custom',
    `name`            VARCHAR(100) NOT NULL COMMENT '配置名称（如：GPT-4助手、Claude分析引擎）',
    `api_key`         VARCHAR(500) NOT NULL COMMENT 'API密钥（加密存储）',
    `base_url`        VARCHAR(255) DEFAULT '' COMMENT '自定义API地址',
    `model`           VARCHAR(100) DEFAULT '' COMMENT '默认模型',
    `usage_scope`     VARCHAR(100) DEFAULT 'all' COMMENT '使用范围: run_analysis / content_review / smart_reply / all',
    `priority`        INT DEFAULT 0 COMMENT '优先级（数字越小越优先）',
    `is_active`       TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    `daily_limit`     INT DEFAULT 0 COMMENT '每日调用上限（0=不限）',
    `today_calls`     INT DEFAULT 0 COMMENT '今日已调用次数',
    `remarks`         VARCHAR(500) COMMENT '备注',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_provider` (`provider`),
    INDEX `idx_scope` (`usage_scope`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI API密钥配置';

-- ==============================
-- 7. AI 服务调用日志表（若依代码生成）
-- ==============================
CREATE TABLE IF NOT EXISTS `ai_call_logs` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `api_key_id`      BIGINT COMMENT '使用的API密钥ID',
    `provider`        VARCHAR(50) NOT NULL COMMENT '供应商',
    `model`           VARCHAR(100) COMMENT '使用的模型',
    `usage_scope`     VARCHAR(50) NOT NULL COMMENT '调用场景',
    `request_tokens`  INT DEFAULT 0 COMMENT '请求tokens',
    `response_tokens` INT DEFAULT 0 COMMENT '响应tokens',
    `cost_count`      DECIMAL(10,6) DEFAULT 0 COMMENT '估算费用($)',
    `duration_ms`     INT DEFAULT 0 COMMENT '响应时长(ms)',
    `status`          VARCHAR(20) NOT NULL DEFAULT 'success' COMMENT 'success / error',
    `error_msg`       VARCHAR(500) COMMENT '错误信息',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_provider` (`provider`),
    INDEX `idx_scope` (`usage_scope`),
    INDEX `idx_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI服务调用日志';

-- ==============================
-- 8. 设备类型定义表（若依代码生成）
-- ==============================
CREATE TABLE IF NOT EXISTS `device_types` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `device_kind`     VARCHAR(50) NOT NULL COMMENT '设备种类: smart_band / smart_ring / watch / chest_strap',
    `brand`           VARCHAR(100) NOT NULL COMMENT '品牌',
    `model`           VARCHAR(100) NOT NULL COMMENT '型号',
    `protocol`        VARCHAR(50) NOT NULL DEFAULT 'ble' COMMENT '连接协议: ble / wifi / http',
    `interface_spec`  JSON COMMENT '接口规范（详细字段定义见文档）',
    `supported_data`  VARCHAR(255) COMMENT '支持的数据类型: hr / pace / steps / sleep / spo2',
    `data_format`     VARCHAR(50) NOT NULL DEFAULT 'json' COMMENT '数据格式: json / protobuf / csv',
    `sample_rate`     VARCHAR(50) COMMENT '采样率（如: 1s / 5s / 10s）',
    `battery_type`    VARCHAR(50) DEFAULT 'rechargeable' COMMENT '供电方式',
    `waterproof`      VARCHAR(20) COMMENT '防水等级',
    `firmware_version` VARCHAR(50) COMMENT '当前固件版本',
    `setup_guide`     TEXT COMMENT '配对接入指南（Markdown）',
    `is_active`       TINYINT(1) DEFAULT 1 COMMENT '是否支持',
    `remarks`         VARCHAR(500) COMMENT '备注',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_kind` (`device_kind`),
    INDEX `idx_brand` (`brand`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备类型定义';

-- ==============================
-- 9. 用户绑定设备表（可直接查strindmoor库的user_devices表，也可新建管理端统计表）
-- ==============================
CREATE TABLE IF NOT EXISTS `device_bind_stats` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `device_type_id`  BIGINT NOT NULL COMMENT '设备类型ID',
    `user_id`         CHAR(36) COMMENT '绑定用户ID',
    `device_mac`      VARCHAR(50) COMMENT '设备MAC/SN',
    `bind_time`       DATETIME COMMENT '绑定时间',
    `last_sync_time`  DATETIME COMMENT '最后同步时间',
    `status`          VARCHAR(20) DEFAULT 'connected' COMMENT 'connected / disconnected / offline',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_device_type` (`device_type_id`),
    INDEX `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备绑定统计';

-- ==============================
-- 10. 核心表加软删除字段
-- ==============================
ALTER TABLE `runs`    ADD COLUMN `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除时间' AFTER `updated_at`;
ALTER TABLE `routes`  ADD COLUMN `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除时间' AFTER `updated_at`;
ALTER TABLE `posts`   ADD COLUMN `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除时间' AFTER `is_hidden`;
ALTER TABLE `users`   ADD COLUMN `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除时间' AFTER `updated_at`;
ALTER TABLE `users`   ADD COLUMN `is_banned` TINYINT(1) DEFAULT 0 COMMENT '是否禁用' AFTER `deleted_at`;
```

### 3.2 若依库（ry_stridemoor）新增数据字典

在 RuoYi 管理端 → 系统管理 → 数据字典，新增：

| 字典名称 | 字典类型 | 字典数据 |
|---------|---------|---------|
| 审核状态 | stridemoor_review_status | 0=待审核 1=已通过 2=已拒绝 |
| 路线状态 | stridemoor_route_status | 1=上架 2=下架 |
| 难度等级 | stridemoor_difficulty | 1=轻松 2=中等 3=挑战 |
| 距离档位 | stridemoor_distance_bracket | 2km 3km 5km 8km 10km 半马 全马 |
| 管理员角色 | stridemoor_admin_role | super_admin / admin / operator |
| 清理类型 | stridemoor_cleanup_type | zero_distance / short_run / abnormal / duplicate |

**若依的数据字典优势**：前端直接 `{{ dict.type.stridemoor_review_status }}` 渲染下拉框和标签，后端直接用 `DictUtils` 获取，改数据不用改代码。

### 3.3 数据库备份策略

```
当前状态（待迁移）：
  - Windows Task Scheduler 任务 `\StrideMoor-DBBackup`（每天凌晨 3:00 触发）
  - 脚本: E:\bakeup\stridemoor_backup.ps1（mysqldump, 端口3308, 保留30天）
  - 日志: E:\bakeup\backup.log

迁移目标：将备份管理迁移到 RuoYi 管理端，统一通过若依 Quartz 定时任务管理
  迁移后，管理端可以：
  - Web 界面配置备份策略（库/端口/保留天数/执行频率）
  - 手动一键备份
  - 查看备份历史记录（时间/大小/状态）
  - 恢复备份文件下载
  - 操作日志全程审计
```

#### 3.3.1 迁移方案对比

| 项目 | 当前（Task Scheduler） | 迁移后（RuoYi Quartz） |
|------|----------------------|----------------------|
| 调度 | Windows Task Scheduler | RuoYi 系统工具→定时任务管理页面 |
| 执行 | `stridemoor_backup.ps1` PS脚本 | RuoYi Quartz Job Bean 调用 `Process.exec(mysqldump)` |
| 配置 | 手动改脚本 | Web 页面配置页（库/端口/保留天数/cron） |
| 日志 | 读 backup.log 文件 | `backup_records` 表 + 操作日志 |
| 手动触发 | 右键 Task → Run | 管理端一键执行按钮 |
| 策略调整 | 改脚本代码 | 管理端下拉选项 |

#### 3.3.2 新增表：backup_config / backup_records

```sql
-- ==============================
-- 11. 备份配置表（若依代码生成）
-- ==============================
CREATE TABLE IF NOT EXISTS `backup_config` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `config_name`     VARCHAR(100) NOT NULL DEFAULT 'default' COMMENT '配置名称',
    `db_host`         VARCHAR(50) NOT NULL DEFAULT '127.0.0.1' COMMENT '数据库地址',
    `db_port`         INT NOT NULL DEFAULT 3308 COMMENT '数据库端口',
    `db_user`         VARCHAR(50) NOT NULL DEFAULT 'stridemoor' COMMENT '数据库用户',
    `db_password`     VARCHAR(200) COMMENT '数据库密码（AES加密存储）',
    `databases`       VARCHAR(200) NOT NULL DEFAULT 'stridemoor' COMMENT '备份的库名（逗号分隔）',
    `backup_dir`      VARCHAR(255) NOT NULL DEFAULT 'E:\\bakeup' COMMENT '备份文件存放目录',
    `retention_days`  INT NOT NULL DEFAULT 30 COMMENT '保留天数',
    `cron_expression` VARCHAR(100) NOT NULL DEFAULT '0 0 3 * * ?' COMMENT 'Quartz cron 表达式（默认凌晨3点）',
    `compress`        TINYINT(1) DEFAULT 1 COMMENT '是否压缩(.gz)',
    `is_active`       TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    `last_backup_time` DATETIME COMMENT '最近一次备份时间',
    `last_backup_size` BIGINT DEFAULT 0 COMMENT '最近备份大小(字节)',
    `last_backup_status` VARCHAR(20) DEFAULT 'none' COMMENT 'none/success/failed',
    `remarks`         VARCHAR(500) COMMENT '备注',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='备份配置';

-- ==============================
-- 12. 备份记录表（若依代码生成）
-- ==============================
CREATE TABLE IF NOT EXISTS `backup_records` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `config_id`       BIGINT NOT NULL COMMENT '备份配置ID',
    `file_name`       VARCHAR(255) NOT NULL COMMENT '备份文件名',
    `file_path`       VARCHAR(500) NOT NULL COMMENT '备份文件完整路径',
    `file_size`       BIGINT DEFAULT 0 COMMENT '文件大小(字节)',
    `database_list`   VARCHAR(200) COMMENT '备份的数据库列表',
    `status`          VARCHAR(20) NOT NULL DEFAULT 'running' COMMENT 'running/success/failed',
    `error_msg`       VARCHAR(500) COMMENT '错误信息',
    `duration_sec`    INT DEFAULT 0 COMMENT '耗时(秒)',
    `operator_id`     BIGINT COMMENT '操作人（手动触发时记录）',
    `trigger_type`    VARCHAR(20) DEFAULT 'auto' COMMENT 'auto/scheduled/manual',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_config` (`config_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='备份记录';
```

**数据字典新增：**

| 字典名称 | 字典类型 | 字典数据 |
|---------|---------|---------|
| 备份状态 | stridemoor_backup_status | none / running / success / failed |
| 触发方式 | stridemoor_backup_trigger | auto / scheduled / manual |

#### 3.3.3 迁移步骤

```
1. 管理端新增备份配置表、备份记录表（代码生成器）
2. 实现 BackupController（CRUD + 手动触发 + 历史记录）
3. 实现 BackupJob（Quartz Job Bean 调用 mysqldump 命令）
4. 在 RuoYi 系统工具→定时任务 中注册 BackupJob（cron: 0 0 3 * * ?）
5. 管理端前端页面：备份配置页 + 备份历史页 + 执行记录页
6. 迁移完成后，关闭 Windows Task Scheduler 的 `\StrideMoor-DBBackup` 任务
7. 手动执行一次验证备份结果
```

---

## 四、若依代码生成流程（具体操作步骤）

### 4.1 哪些表用生成器

| 表名 | 建表时机 | 生成全量CRUD? | 后续手工修改量 |
|------|---------|-------------|-------------|
| `post_reviews` | 新建 | ✅ 是 | 小（加审核通过/拒绝方法） |
| `admin_roles` | 新建 | ✅ 是 | 小 |
| `duplicate_groups` | 新建 | ✅ 是 | 小（加手动触发检测方法） |
| `cleanup_logs` | 新建 | ✅ 是 | 极小（只读） |
| `ai_api_keys` | 新建 | ✅ 是 | 中（加密/脱敏/轮换/启禁自定义） |
| `ai_call_logs` | 新建 | ✅ 是 | 极小（只读+图表） |
| `device_types` | 新建 | ✅ 是 | 中（JSON规范编辑器/卡片布局） |
| `device_bind_stats` | 新建 | ✅ 是 | 极小（只读+统计卡片） |
| `backup_config` | 新建 | ✅ 是 | 中（手动触发/加密存储/Quartz集成） |
| `backup_records` | 新建 | ✅ 是 | 极小（只读） |

**已存在的表（routes/runs/posts/users）** 不走生成器，手动建 Domain/Mapper/Service。

### 4.2 生成器操作步骤

```
▶ 第1步：在 stridemoor 库执行上述 CREATE TABLE SQL
▶ 第2步：登录 RuoYi 管理端 → 系统工具 → 代码生成
▶ 第3步：点击"导入"→ 选择 stridemoor 库（从库）
         → 勾选 post_reviews / admin_roles / duplicate_groups / cleanup_logs
▶ 第4步：编辑配置：
   生成包路径：com.ruoyi.stridemoor
   生成模块名：stridemoor
   上级菜单：驰陌管理
   表前缀：空（默认即可）
▶ 第5步：生成代码 → 下载 zip 包
▶ 第6步：解压后把 controller/service/domain/mapper 文件放入 ruoyi-stridemoor 模块
          把 Vue 页面放入 ruoyi-ui/src/views/stridemoor/review/
```

### 4.3 生成器产出物说明

以 `post_reviews` 为例，生成器产出：

```
后端：
  controller/PostReviewsController.java   ← CRUD + @PreAuthorize
  domain/PostReviews.java                 ← 实体类，含 @Excel 注解
  mapper/PostReviewsMapper.java           ← 基础 CRUD SQL
  service/IPostReviewsService.java        ← 接口
  service/impl/PostReviewsServiceImpl.java ← 实现

前端：
  views/stridemoor/review/index.vue       ← 基础列表页（搜索表单+表格+新增/编辑/删除）
  views/stridemoor/review/form.vue        ← 新增/编辑表单
```

---

## 五、模块划分与 RuoYi 规范实现

### 5.1 模块结构（ruoyi-stridemoor）

```
ruoyi-stridemoor/src/main/java/com/ruoyi/stridemoor/
├── controller/
│   ├── ReviewController.java         ← 审核管理
│   ├── RouteManageController.java    ← 路线管理
│   ├── CleanupController.java        ← 数据清理
│   ├── UserManageController.java     ← 用户管理
│   ├── PostManageController.java     ← 动态管理
│   ├── RealmController.java          ← 跑境管理
│   ├── DashboardController.java      ← 数据看板（6个Tab）
│   ├── StatsController.java          ← 统计查询API（补充明细）
│   ├── AiKeyController.java          ← AI API密钥管理
│   ├── AiLogController.java          ← AI调用日志查询
│   ├── DeviceTypeController.java     ← 设备类型定义管理
│   ├── DeviceStatController.java     ← 设备绑定统计
│   ├── BackupConfigController.java   ← 备份配置管理
│   └── BackupRecordController.java   ← 备份记录查询
│
├── domain/
│   ├── StridePost.java               ← posts 表映射（手动写）
│   ├── StrideRoute.java              ← routes 表映射（手动写）
│   ├── StrideRun.java                ← runs 表映射（手动写）
│   ├── StrideUser.java               ← users 表映射（手动写）
│   ├── PostReviews.java              ← 生成器生成
│   ├── AdminRoles.java               ← 生成器生成
│   ├── DuplicateGroups.java          ← 生成器生成
│   ├── CleanupLogs.java              ← 生成器生成
│   ├── AiApiKeys.java                ← 生成器生成（AI密钥）
│   ├── AiCallLogs.java               ← 生成器生成（AI调用日志）
│   ├── DeviceTypes.java              ← 生成器生成（设备类型）
│   ├── DeviceBindStats.java          ← 生成器生成（绑定统计）
│   ├── BackupConfig.java             ← 生成器生成（备份配置）
│   └── BackupRecords.java            ← 生成器生成（备份记录）
│
├── mapper/
│   ├── StridePostMapper.java         ← 手动
│   ├── StrideRouteMapper.java        ← 手动
│   ├── StrideRunMapper.java          ← 手动
│   ├── StrideUserMapper.java         ← 手动
│   ├── PostReviewsMapper.java        ← 生成
│   ├── AdminRolesMapper.java         ← 生成
│   ├── DuplicateGroupsMapper.java    ← 生成
│   ├── CleanupLogsMapper.java        ← 生成
│   ├── AiApiKeysMapper.java          ← 生成
│   ├── AiCallLogsMapper.java         ← 生成
│   ├── DeviceTypesMapper.java        ← 生成
│   ├── DeviceBindStatsMapper.java    ← 生成
│   ├── BackupConfigMapper.java       ← 生成
│   └── BackupRecordsMapper.java      ← 生成
│
├── service/
│   ├── IReviewService.java
│   ├── ReviewServiceImpl.java
│   ├── IRouteManageService.java
│   ├── RouteManageServiceImpl.java
│   ├── CleanupService.java           ← 数据清理业务逻辑
│   ├── RouteMatcherService.java      ← 重复路线检测算法
│   ├── DashboardService.java         ← 看板统计（概览/用户/跑步/挑战/排行/跑境）
│   ├── StatsExportService.java       ← 统计报表导出（Excel）
│   ├── AiKeyService.java             ← AI密钥管理（加密存储+轮换）
│   ├── AiLogService.java             ← AI调用日志查询
│   ├── DeviceTypeService.java        ← 设备类型定义管理
│   ├── DeviceStatService.java        ← 设备绑定统计
│   ├── BackupConfigService.java      ← 备份配置+手动触发备份
│   └── BackupRecordService.java      ← 备份记录查询
│
├── job/
│   └── BackupJob.java                ← Quartz Job Bean（调用 mysqldump 执行备份）
│
└── dto/
    ├── ReviewQueryDTO.java           ← 审核列表查询参数
    ├── BatchReviewDTO.java           ← 批量审核参数
    ├── RouteUpdateDTO.java           ← 路线更新参数
    ├── MergeRouteDTO.java            ← 合并路线参数
    ├── CleanupPreviewDTO.java        ← 清理预览结果
    ├── DashboardSummaryVO.java       ← 看板概览指标
    ├── CityRouteStatsVO.java         ← 地区路线统计
    ├── HeatPointVO.java              ← 热力图数据点
    ├── UserActivityVO.java           ← 用户活跃度分布
    ├── RunTrendVO.java               ← 跑步趋势
    ├── RunAggregateVO.java           ← 跑步汇总
    ├── ChallengeStatsVO.java         ← 挑战统计
    ├── RunnerRankingVO.java          ← 跑者排行
    ├── DistanceBracketVO.java        ← 跑距分段
    ├── PopularRouteVO.java           ← 路线排行
    ├── NameValueVO.java              ← 通用名称/值对
    └── TrendPointVO.java             ← 通用趋势点
```

### 5.2 手动 Domain 示例（映射 stridemoor 已存在表）

```java
/**
 * 映射 stridemoor 库的 posts 表
 * 注意：@DataSource("slave") 用在 Service 层
 */
public class StridePost {
    
    @Excel(name = "动态ID")
    private String id;
    
    @Excel(name = "用户ID")
    private String userId;
    
    @Excel(name = "内容")
    private String content;
    
    @Excel(name = "审核状态", dictType = "stridemoor_review_status")
    private Integer reviewStatus;
    
    @Excel(name = "是否隐藏")
    private Integer isHidden;
    
    private String createTime;
    
    // getter/setter...
}
```

### 5.3 Controller 规范（RuoYi 标准风格）

```java
@RestController
@RequestMapping("/stridemoor/review")
public class ReviewController extends BaseController {
    
    @Autowired
    private IReviewService reviewService;
    
    /**
     * 分页查询待审核列表
     * RuoYi 标准：BaseController.startPage() 自动从请求参数读取 pageNum/pageSize
     * 返回 TableDataInfo（带分页信息的标准响应）
     */
    @PreAuthorize("@ss.hasPermi('stridemoor:review:list')")
    @GetMapping("/list")
    public TableDataInfo list(StridePost post) {
        startPage();
        List<StridePost> list = reviewService.selectPendingList(post);
        return getDataTable(list);
    }
    
    /**
     * 审核通过
     * @Log 自动记录操作日志到 sys_oper_log
     * @RepeatSubmit 防止重复提交
     */
    @PreAuthorize("@ss.hasPermi('stridemoor:review:approve')")
    @Log(title = "跑迹审核", businessType = BusinessType.UPDATE)
    @RepeatSubmit
    @PostMapping("/approve/{postId}")
    public AjaxResult approve(@PathVariable String postId, String note) {
        reviewService.approve(postId, getUserId(), note);
        return success("审核通过");
    }
    
    /**
     * 批量审核通过
     */
    @PreAuthorize("@ss.hasPermi('stridemoor:review:batch')")
    @Log(title = "跑迹审核", businessType = BusinessType.UPDATE)
    @RepeatSubmit
    @PostMapping("/batchApprove")
    public AjaxResult batchApprove(@RequestBody BatchReviewDTO dto) {
        reviewService.batchApprove(dto.getPostIds(), getUserId());
        return success("批量审核通过 " + dto.getPostIds().length + " 条");
    }
    
    /**
     * 审核拒绝
     */
    @PreAuthorize("@ss.hasPermi('stridemoor:review:reject')")
    @Log(title = "跑迹审核", businessType = BusinessType.UPDATE)
    @RepeatSubmit
    @PostMapping("/reject/{postId}")
    public AjaxResult reject(@PathVariable String postId, @RequestBody ReviewRejectDTO dto) {
        reviewService.reject(postId, getUserId(), dto.getReason());
        return success("已拒绝");
    }
    
    /**
     * 审核统计（给前端角标用）
     */
    @PreAuthorize("@ss.hasPermi('stridemoor:review:list')")
    @GetMapping("/stats")
    public AjaxResult stats() {
        return success(reviewService.getReviewStats());
    }
}
```

### 5.4 Vue 页面标准（index.vue 规范）

```vue
<template>
  <div class="app-container">
    <!-- 搜索表单 -->
    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="动态内容" prop="content">
        <el-input v-model="queryParams.content" placeholder="搜索动态内容" clearable />
      </el-form-item>
      <el-form-item label="上传者" prop="userId">
        <el-input v-model="queryParams.userId" placeholder="用户ID或昵称" clearable />
      </el-form-item>
      <el-form-item label="审核状态" prop="reviewStatus">
        <el-select v-model="queryParams.reviewStatus" placeholder="审核状态" clearable>
          <el-option
            v-for="dict in stridemoor_review_status"
            :key="dict.value"
            :label="dict.label"
            :value="dict.value"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="上传时间" prop="createTime">
        <el-date-picker v-model="dateRange" type="daterange" format="yyyy-MM-dd" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- 操作按钮 -->
    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="success" plain icon="Check" :disabled="selected.length===0" @click="batchApprove">
          批量通过
        </el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="danger" plain icon="Close" :disabled="selected.length===0" @click="batchReject">
          批量拒绝
        </el-button>
      </el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
    </el-row>

    <!-- 表格 -->
    <el-table v-loading="loading" :data="postList" @selection-change="handleSelection">
      <el-table-column type="selection" width="50" />
      <el-table-column label="动态内容" prop="content" min-width="200" :show-overflow-tooltip="true" />
      <el-table-column label="上传者" prop="nickname" width="120" />
      <el-table-column label="关联路线" prop="routeName" width="180" />
      <el-table-column label="审核状态" prop="reviewStatus" width="100">
        <template #default="{ row }">
          <dict-tag :options="stridemoor_review_status" :value="row.reviewStatus" />
        </template>
      </el-table-column>
      <el-table-column label="上传时间" prop="createTime" width="160" />
      <el-table-column label="操作" width="220" fixed="right">
        <template #default="{ row }">
          <el-button type="success" link icon="Check" @click="handleApprove(row)">通过</el-button>
          <el-button type="warning" link icon="Close" @click="handleReject(row)">拒绝</el-button>
          <el-button type="primary" link icon="View" @click="handleDetail(row)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <pagination
      v-show="total > 0"
      :total="total"
      v-model:page="queryParams.pageNum"
      v-model:limit="queryParams.pageSize"
      @pagination="getList"
    />

    <!-- 详情抽屉 -->
    <detail-drawer ref="detailDrawerRef" @refresh="getList" />
  </div>
</template>
```

### 5.5 菜单与权限配置

在 RuoYi 管理端 → 系统管理 → 菜单管理，新增以下菜单树：

```
驰陌管理（目录）
├── 跑迹审核（菜单）
│   ├── 审核列表（按钮）        permi: stridemoor:review:list
│   ├── 审核通过（按钮）        permi: stridemoor:review:approve
│   ├── 审核拒绝（按钮）        permi: stridemoor:review:reject
│   └── 批量审核（按钮）        permi: stridemoor:review:batch
├── 路线管理（菜单）
│   ├── 路线列表（按钮）        permi: stridemoor:route:list
│   ├── 路线编辑（按钮）        permi: stridemoor:route:edit
│   ├── 路线删除（按钮）        permi: stridemoor:route:delete
│   ├── 上下架（按钮）          permi: stridemoor:route:toggle
│   └── 重复检测（按钮）        permi: stridemoor:route:dedup
├── 数据清理（菜单）
│   ├── 清理预览（按钮）        permi: stridemoor:cleanup:preview
│   ├── 执行清理（按钮）        permi: stridemoor:cleanup:execute
│   └── 清理历史（按钮）        permi: stridemoor:cleanup:history
├── 用户管理（菜单）
│   └── ...                    permi: stridemoor:user:*
├── 动态管理（菜单）
│   └── ...                    permi: stridemoor:post:*
├── 跑境管理（菜单）
│   └── ...                    permi: stridemoor:realm:*
├── AI 服务管理（目录）
│   ├── API密钥管理（菜单）    permi: stridemoor:ai:key
│   │   ├── 查看列表（按钮）   permi: stridemoor:ai:key:list
│   │   ├── 新增密钥（按钮）   permi: stridemoor:ai:key:add
│   │   ├── 编辑密钥（按钮）   permi: stridemoor:ai:key:edit
│   │   ├── 删除密钥（按钮）   permi: stridemoor:ai:key:delete
│   │   ├── 启用/禁用（按钮）  permi: stridemoor:ai:key:toggle
│   │   └── 密钥轮换（按钮）  permi: stridemoor:ai:key:rotate
│   └── 调用日志（菜单）     permi: stridemoor:ai:log
│       ├── 查询日志（按钮）   permi: stridemoor:ai:log:list
│       └── 导出（按钮）     permi: stridemoor:ai:log:export
├── 设备管理（目录）
│   ├── 设备类型定义（菜单）   permi: stridemoor:device:type
│   │   ├── 查看列表（按钮）   permi: stridemoor:device:type:list
│   │   ├── 新增设备（按钮）  permi: stridemoor:device:type:add
│   │   ├── 编辑设备（按钮）  permi: stridemoor:device:type:edit
│   │   ├── 删除设备（按钮）  permi: stridemoor:device:type:delete
│   │   └── 接口预览（按钮）  permi: stridemoor:device:type:preview
│   └── 绑定统计（菜单）     permi: stridemoor:device:stat
├── 系统工具 - 备份管理（目录）
│   ├── 备份策略配置（菜单）   permi: stridemoor:backup:config
│   │   ├── 查看配置（按钮）   permi: stridemoor:backup:config:list
│   │   ├── 编辑配置（按钮）   permi: stridemoor:backup:config:edit
│   │   └── 立即备份（按钮）  permi: stridemoor:backup:execute
│   ├── 备份记录（菜单）     permi: stridemoor:backup:record
│   │   ├── 查询记录（按钮）   permi: stridemoor:backup:record:list
│   │   └── 下载文件（按钮）  permi: stridemoor:backup:download
│   └── Quartz 定时任务（复用 RuoYi 原生）→ 系统工具→定时任务
└── 数据看板（目录）
    ├── 运营概览（菜单）       permi: stridemoor:dashboard:overview
    ├── 地区分布（菜单）       permi: stridemoor:dashboard:region
    ├── 用户分析（菜单）       permi: stridemoor:dashboard:users
    ├── 跑步分析（菜单）       permi: stridemoor:dashboard:running
    ├── 挑战分析（菜单）       permi: stridemoor:dashboard:challenge
    └── 排行榜（菜单）        permi: stridemoor:dashboard:ranking
```

这样哪位管理员有什么权限，在 RuoYi 的角色管理页面直接勾选即可，**不需要改代码**。

---

## 六、驰陌品牌主题定制

### 6.1 UI 设计定位

```
品牌调性：活力、动感、专业、自然
关键词：驰骋、奔跑、轨迹、山水、热血
配色灵感：运动装备 + 自然山川
```

**Slogan**：驰于阡陌，自在奔跑 — *Stride in Moor, Run at Ease*

### 6.2 品牌色体系

```
🎯 主色系：运动活力
  主色 #FF6B35     → 驰陌橙（活力、热血、动感）
  辅色 #2EC4B6     → 跑道绿（自然、健康、生长）
  强调 #FF3366     → 竞速红（冲刺、目标、高亮）
  背景 #F7F8FC     → 轻量灰（干净、留白）

🎯 文字色系
  主要文字 #1A1A2E  → 深黑蓝（标题/正文）
  次要文字 #6B7280  → 中灰（辅助信息）
  占位文字 #9CA3AF  → 浅灰（placeholder）

🎯 数据色板（ECharts 图表）
  ['#FF6B35', '#2EC4B6', '#FF3366', '#F5A623', '#7B68EE', '#20B2AA', '#FF8C42', '#4A90D9']
```

### 6.3 RuoYi 前端主题替换位置

```
ruoyi-ui/
├── src/
│   ├── assets/styles/
│   │   ├── index.scss          ← 全局样式入口（改背景色、字体）
│   │   ├── variables.scss      ← Element Plus 变量覆盖（改品牌色）
│   │   └── stride-theme.scss   ← ★ 新增：驰陌主题覆盖
│   ├── layout/
│   │   ├── components/Sidebar/  ← 侧边栏组件（改Logo、背景色）
│   │   ├── components/Navbar/   ← 顶部导航（改样式）
│   │   └── index.vue           ← 布局容器
│   ├── views/stridemoor/
│   │   └── dashboard/
│   │       └── stat-card.css ← ★ 新增：指标卡片样式
│   └── login.vue             ← 登录页
│
├── public/
│   └── logo-stridemoor.png   ← ★ 驰陌 Logo
│   └── favicon-stridemoor.ico ← ★ 驰陌图标
```

### 6.4 Element Plus 主题变量覆盖

```scss
// ruoyi-ui/src/assets/styles/variables.scss — 覆盖主题变量

// 品牌色（覆盖 Element Plus 的 $primary color）
$--color-primary: #FF6B35;
$--color-primary-light-1: #FF8C5A;
$--color-primary-light-2: #FFAD80;
$--color-primary-light-3: #FFCDA6;
$--color-primary-dark-1: #E55A2B;

$--color-success: #2EC4B6;
$--color-warning: #F5A623;
$--color-danger: #FF3366;
$--color-info: #6B7280;

// 侧边栏
$--sidebar-bg-color: #1A1A2E;        // 深色侧边栏
$--sidebar-text-color: #A0AEC0;
$--sidebar-active-text: #FFFFFF;
$--sidebar-active-bg: linear-gradient(135deg, #FF6B35, #FF3366);

// 卡片
$--card-border-radius: 12px;
$--card-padding: 20px;
$--card-box-shadow: 0 2px 12px rgba(0,0,0,0.06);
```

### 6.5 登录页设计

```vue
<!-- 登录页改造：驰陌主题 -->
<template>
  <div class="stride-login">
    <!-- 左侧：品牌展示区 -->
    <div class="login-brand">
      <div class="brand-bg">
        <!-- 动态背景：奔跑的人物剪影动画（CSS animation） -->
        <div class="runner-animation"></div>
      </div>
      <div class="brand-content">
        <img src="logo-stridemoor.png" class="brand-logo" />
        <h1 class="brand-title">驰陌</h1>
        <p class="brand-slogan">驰于阡陌，自在奔跑</p>
        <p class="brand-sub">Stride in Moor, Run at Ease</p>
        <div class="brand-stats">
          <div class="stat-item">
            <span class="num">12,345</span>
            <span class="label">跑者</span>
          </div>
          <div class="stat-item">
            <span class="num">89,752</span>
            <span class="label">条跑迹</span>
          </div>
          <div class="stat-item">
            <span class="num">528,000</span>
            <span class="label">公里</span>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 右侧：登录表单（沿用 RuoYi 原逻辑） -->
    <div class="login-form">
      <!-- ... RuoYi 标准登录表单，改按钮色为主色 -->
    </div>
  </div>
</template>

<style lang="scss">
.stride-login {
  display: flex;
  height: 100vh;
  
  .login-brand {
    flex: 1;
    background: linear-gradient(135deg, #1A1A2E 0%, #16213E 50%, #0F3460 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
    
    .brand-logo {
      height: 64px;
      margin-bottom: 16px;
    }
    .brand-title {
      color: #FFFFFF;
      font-size: 42px;
      font-weight: 700;
      letter-spacing: 4px;
    }
    .brand-slogan {
      color: #FF6B35;
      font-size: 20px;
      margin-top: 8px;
      font-weight: 500;
    }
    .brand-stats {
      display: flex;
      gap: 40px;
      margin-top: 48px;
      .stat-item {
        text-align: center;
        .num { color: #FF6B35; font-size: 28px; font-weight: bold; display: block; }
        .label { color: #A0AEC0; font-size: 14px; }
      }
    }
    
    // 奔跑动画（纯 CSS）
    .runner-animation {
      position: absolute;
      bottom: 10%;
      width: 100%;
      height: 200px;
      background: url('runner-silhouette.svg') repeat-x;
      animation: run 8s linear infinite;
    }
    @keyframes run {
      from { background-position: 0 0; }
      to { background-position: -1000px 0; }
    }
  }
  
  .login-form {
    width: 480px;
    padding: 64px;
    display: flex;
    flex-direction: column;
    justify-content: center;
    
    // 覆盖登录按钮为主色
    .el-button--primary {
      background: #FF6B35;
      border-color: #FF6B35;
      &:hover { background: #FF8C5A; border-color: #FF8C5A; }
    }
  }
}
</style>
```

### 6.6 侧边栏设计

```
┌──────────────────────────────────────┐
│  🏃 驰陌管理台（Logo）               │ ← 深蓝黑色背景 #1A1A2E
├──────────────────────────────────────┤    Logo = 奔跑剪影 + 驰陌文字
│                                      │
│  📊 数据看板                         │
│    ├── 🏠 运营概览                    │ ← 活跃态：渐变色左边界
│    ├── 📍 地区分布                    │    #FF6B35 → #FF3366
│    ├── 👥 用户分析                    │
│    ├── 🏃 跑步分析                    │
│    ├── ⚔️ 挑战分析                    │
│    └── 🏆 排行榜                     │
│                                      │
│  📝 跑迹审核                         │
│  🗺️ 路线管理                         │
│  🧹 数据清理                         │
│  👤 用户管理                         │
│  💬 动态管理                         │
│  🏯 跑境管理                         │
│  ⚙️ 系统管理（RuoYi自带）             │
│    ├── 用户管理                       │
│    ├── 角色管理                       │
│    ├── 菜单管理                       │
│    ├── 数据字典                       │
│    ├── 操作日志                       │
│    ├── 代码生成                       │
│    └── 定时任务                       │
└──────────────────────────────────────┘
```

侧边栏实现要点：
```scss
// 覆盖 RuoYi 侧边栏样式
.el-menu {
  background-color: #1A1A2E !important;
  
  .el-menu-item {
    color: #A0AEC0;
    border-left: 3px solid transparent;
    transition: all 0.2s;
    
    &:hover { background: rgba(255,107,53,0.1); color: #FFFFFF; }
    
    &.is-active {
      color: #FFFFFF;
      background: linear-gradient(135deg, rgba(255,107,53,0.2), rgba(255,51,102,0.1));
      border-left-color: #FF6B35;
    }
  }
}
```

### 6.7 数据看板卡片样式

```scss
/* views/stridemoor/dashboard/stat-card.css */
.stat-card {
  border-radius: 12px;
  padding: 20px;
  background: #FFFFFF;
  transition: transform 0.2s, box-shadow 0.2s;
  cursor: default;
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 24px rgba(0,0,0,0.1);
  }
  
  // 不同主题色的卡片左边框
  &.primary  { border-left: 4px solid #FF6B35; }
  &.success  { border-left: 4px solid #2EC4B6; }
  &.warning  { border-left: 4px solid #F5A623; }
  &.danger   { border-left: 4px solid #FF3366; }
  &.purple   { border-left: 4px solid #7B68EE; }
  &.info     { border-left: 4px solid #4A90D9; }
  
  .stat-value {
    font-size: 32px;
    font-weight: 700;
    line-height: 1.2;
    margin-bottom: 4px;
  }
  
  .stat-label {
    font-size: 14px;
    color: #6B7280;
  }
  
  .stat-icon {
    float: right;
    opacity: 0.15;
    font-size: 48px;
  }
}
```

### 6.8 表格和页面样式

```scss
/* stride-theme.scss — 全局主题覆盖 */

// 内容区域背景
.app-container {
  background: #F7F8FC;
  border-radius: 12px;
  padding: 20px;
}

// 搜索表单
.el-form--inline {
  background: #FFFFFF;
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 16px;
}

// 操作按钮区
.mb8 {
  margin-bottom: 12px;
  .el-button--primary { background: #FF6B35; border-color: #FF6B35; }
  .el-button--success { background: #2EC4B6; border-color: #2EC4B6; }
}

// 表格
.el-table {
  border-radius: 12px;
  overflow: hidden;
  
  th.el-table__cell { background: #F7F8FC; color: #1A1A2E; font-weight: 600; }
  
  .el-table__row {
    &:hover { background: rgba(255,107,53,0.04); }
  }
}

// 标签
.el-tag--success { background: rgba(46,196,182,0.1); border-color: rgba(46,196,182,0.3); color: #2EC4B6; }
.el-tag--danger  { background: rgba(255,51,102,0.1); border-color: rgba(255,51,102,0.3); color: #FF3366; }
.el-tag--warning { background: rgba(245,166,35,0.1); border-color: rgba(245,166,35,0.3); color: #F5A623; }

// 卡片
.el-card {
  border-radius: 12px;
  border: none;
  box-shadow: 0 2px 12px rgba(0,0,0,0.04);
  
  .el-card__header {
    font-weight: 600;
    color: #1A1A2E;
    border-bottom: 1px solid #F3F4F6;
    padding: 16px 20px;
  }
}

// 分页
.el-pagination {
  margin-top: 16px;
  justify-content: flex-end;
}

// 按钮
.el-button {
  border-radius: 8px;
}
```

### 6.9 Logo 和 Favicon

需要准备以下素材放在 `ruoyi-ui/public/`：

| 文件 | 用途 | 推荐规格 |
|------|------|---------|
| `logo-stridemoor.png` | 登录页 + 侧边栏顶部的 Logo | 200x64px 透明PNG |
| `favicon-stridemoor.ico` | 浏览器标签图标 | 32x32px ICO |
| `runner-silhouette.svg` | 登录页奔跑动画的人物剪影 | SVG 矢量 |
| `logo-stridemoor.svg` | 各种场景复用的矢量 Logo | SVG 矢量 |

Logo 设计建议：
```
🏃 驰陌
└── 图形：一个简洁的奔跑人物剪影 + 三条流动线条（象征跑道/轨迹）
└── 配色：驰陌橙 #FF6B35 + 深蓝黑 #1A1A2E
└── 字体：无衬线，锐利有力（如 Montserrat、思源黑体 Bold）
```

### 6.10 主题切换文件清单

```
实施时需修改/新增的文件：

RuoYi 标注文件（修改）：
  ruoyi-ui/src/assets/styles/index.scss      ← 引入 stride-theme.scss
  ruoyi-ui/src/assets/styles/variables.scss  ← 覆盖 Element Plus 变量
  ruoyi-ui/src/views/login.vue               ← 换登录页布局和品牌色
  ruoyi-ui/src/layout/components/Sidebar/    ← 换侧边栏Logo和样式
  ruoyi-ui/src/layout/components/Navbar/     ← 顶部栏样式
  ruoyi-ui/public/index.html                 ← 换 favicon

驰陌新增文件：
  ruoyi-ui/src/assets/styles/stride-theme.scss ← 全局主题覆盖
  ruoyi-ui/src/views/stridemoor/dashboard/stat-card.css ← 指标卡片样式
  ruoyi-ui/public/logo-stridemoor.png         ← Logo
  ruoyi-ui/public/favicon-stridemoor.ico      ← 图标
  ruoyi-ui/public/runner-silhouette.svg       ← 登录页动画
```

---

## 七、核心功能 RuoYi 实现详解

### 7.1 跑迹审核

**审核流程的完整链路：**

```
用户 App 发布动态 (POST /api/v1/posts)
  → Go 后端创建 posts 记录（review_status=0 待审核）
  → post_reviews 表写入一条待审核记录

管理员登录 RuoYi 管理端
  → 菜单"跑迹审核" → 看到待审核列表
  → 点击动态详情 → 抽屉展示内容 + 轨迹地图 + 跑步数据
  
管理员操作：
  ├── 通过 → POST /stridemoor/review/approve/{postId}
  │         → Service：更新 post_reviews.status=1, posts.review_status=1
  │         → @Log 自动记日志
  │
  ├── 拒绝 → POST /stridemoor/review/reject/{postId}
  │         → Service：更新 post_reviews.status=2, posts.review_status=2
  │         → 填入拒绝原因
  │
  └── 详情 → GET /stridemoor/review/detail/{postId}
            → Service：联表查询 post + user + route + run 数据
            → 前端渲染轨迹地图
```

**后台审核后 App 端的同步**：
- Go 后端的跑迹广场 API 查询时加上 `WHERE review_status = 1 AND is_hidden = 0`
- 共用同一个数据库，RuoYi 更新后 Go 端实时读到新数据，**无需额外通知机制**

### 7.2 路线去重（算法+合并）

**RouteMatcherService.java（纯后端逻辑，不走生成器）：**

```java
@Service
public class RouteMatcherService {
    
    @Autowired
    private StrideRouteMapper routeMapper;
    
    @Autowired
    private DuplicateGroupsMapper dupMapper;
    
    /**
     * 触发全量重复检测（手动点击 + 定时任务共用）
     * 结果写入 duplicate_groups 表
     */
    @Transactional
    public List<DuplicateGroupVO> detectDuplicates() {
        // 1. 查询所有正常路线（state=1, deleted_at IS NULL）
        List<StrideRoute> allRoutes = routeMapper.selectNormalRoutes();
        
        // 2. 按 city 分组（只比同城市的）
        Map<String, List<StrideRoute>> byCity = allRoutes.stream()
            .collect(Collectors.groupingBy(r -> r.getCity() != null ? r.getCity() : "未知"));
        
        List<DuplicateGroupVO> results = new ArrayList<>();
        
        // 3. 每组内两两比较
        for (List<StrideRoute> cityRoutes : byCity.values()) {
            for (int i = 0; i < cityRoutes.size(); i++) {
                for (int j = i + 1; j < cityRoutes.size(); j++) {
                    StrideRoute a = cityRoutes.get(i);
                    StrideRoute b = cityRoutes.get(j);
                    
                    // 3.1 距离过滤：相差 > 30% 的直接跳过
                    if (Math.abs(a.getDistance() - b.getDistance()) / Math.max(a.getDistance(), b.getDistance()) > 0.3) {
                        continue;
                    }
                    
                    // 3.2 计算轨迹相似度
                    double similarity = calculateSimilarity(a.getId(), b.getId());
                    
                    // 3.3 相似度 > 70% 记录到结果
                    if (similarity > 70) {
                        DuplicateGroupVO vo = new DuplicateGroupVO(a, b, similarity);
                        results.add(vo);
                        
                        // 写入 duplicate_groups 表
                        DuplicateGroups record = new DuplicateGroups();
                        record.setRouteAId(a.getId());
                        record.setRouteBId(b.getId());
                        record.setSimilarity(new BigDecimal(similarity));
                        record.setDistanceDiff(new BigDecimal(Math.abs(a.getDistance() - b.getDistance())));
                        record.setStatus(0); // 待处理
                        dupMapper.insert(record);
                    }
                }
            }
        }
        
        return results;
    }
    
    /**
     * 计算两条路线的轨迹相似度（Hausdorff 距离）
     */
    private double calculateSimilarity(String routeAId, String routeBId) {
        // 从 route_points 表读取轨迹点
        List<RoutePoint> pointsA = routeMapper.selectPointsByRouteId(routeAId);
        List<RoutePoint> pointsB = routeMapper.selectPointsByRouteId(routeBId);
        
        // 重采样到 100 个等距点
        List<Point> resampledA = resample(pointsA, 100);
        List<Point> resampledB = resample(pointsB, 100);
        
        // 计算 Hausdorff 距离（有向距离的最大值）
        double maxDistAB = directedHausdorff(resampledA, resampledB);
        double maxDistBA = directedHausdorff(resampledB, resampledA);
        double hausdorffDist = Math.max(maxDistAB, maxDistBA);
        
        // 转相似度（0~100%）
        // 50米以内 = 高度相似，200米以上 = 不相似
        double similarity = Math.max(0, 100 * (1 - hausdorffDist / 200.0));
        return Math.min(100, similarity);
    }
    
    /**
     * 合并路线（事务保证一致性）
     */
    @Transactional
    public void mergeRoutes(String keepId, String removeId) {
        // 1. runs 表：将 removeId 的引用改为 keepId
        routeMapper.updateRunRouteId(keepId, removeId);
        // 2. route_favorites：合并收藏
        routeMapper.mergeFavorites(keepId, removeId);
        // 3. post_reviews：合并关联
        routeMapper.mergePosts(keepId, removeId);
        // 4. duplicate_groups：标记已合并
        dupMapper.updateMerged(removeId, keepId);
        // 5. 软删除 removeId 的 route_points
        routeMapper.deletePointsByRouteId(removeId);
        // 6. 软删除 removeId
        routeMapper.softDeleteRoute(removeId);
        // 7. 更新 keepId 的统计值
        routeMapper.recalcRouteStats(keepId);
    }
}
```

### 7.3 数据清理（RuoYi Quartz 定时任务）

```java
@Component("strideCleanupTask")
public class StrideCleanupTask {
    
    @Autowired
    private CleanupService cleanupService;
    
    /**
     * 每日凌晨3:00自动清理零距离记录
     * 在 RuoYi 定时任务页面配置：
     *   任务名称：跑迹自动清理
     *   调用方法：strideCleanupTask.autoCleanZeroDistance()
     *   Cron：0 0 3 * * ?
     */
    public void autoCleanZeroDistance() {
        CleanupResult result = cleanupService.cleanZeroDistance();
        if (result.getCount() > 0) {
            // 写入清理日志
            cleanupService.logCleanup("zero_distance", result);
        }
    }
    
    /**
     * 每周一凌晨4:00自动检测重复路线
     *   Cron：0 0 4 * * 1
     */
    public void autoDetectDuplicates() {
        // 只检测本周新增的路线（增量检测）
        cleanupService.detectDuplicatesIncremental();
    }
}
```

在 RuoYi 定时任务管理页面操作：
```
系统工具 → 定时任务 → 新增
  任务名称：跑迹数据每日清理
  调用目标：strideCleanupTask.autoCleanZeroDistance
  执行表达式：0 0 3 * * ?
  状态：正常
```

**两步操作完成定时任务配置，无需写调度代码**，这是若依的一大便利。

### 7.4 数据看板（完整统计体系）

RuoYi UI 已内置 ECharts，直接在 Vue 页面使用。

#### 7.4.1 DashboardService 完整统计接口

```java
@Service
@DataSource("slave")  // 所有统计查询走 stridemoor 库
public class DashboardService {

    @Autowired
    private StrideUserMapper userMapper;
    @Autowired
    private StrideRunMapper runMapper;
    @Autowired
    private StrideRouteMapper routeMapper;
    @Autowired
    private StridePostMapper postMapper;
    @Autowired
    private ChallengeMapper challengeMapper;  // 手动映射 challenges 表

    // ==================== 概览统计（顶部8个卡片） ====================
    public DashboardSummaryVO getSummary() {
        DashboardSummaryVO vo = new DashboardSummaryVO();
        vo.setTotalUsers(userMapper.countTotal());                      // 累计注册用户
        vo.setTotalDistance(runMapper.sumTotalDistance());               // 跑步总里程(m)
        vo.setTotalRuns(runMapper.countTotal());                        // 跑步总次数
        vo.setTotalRoutes(routeMapper.countTotal());                    // 路线总数
        vo.setTodayActiveUsers(runMapper.countTodayActiveUsers());       // 今日活跃
        vo.setTodayRuns(runMapper.countTodayRuns());                    // 今日跑步数
        vo.setPendingReviews(postMapper.countPendingReviews());          // 待审核
        vo.setNewUsersThisWeek(userMapper.countNewThisWeek());           // 本周新增
        return vo;
    }

    // ==================== 地区路线统计 ====================
    // 按城市统计路线分布：城市名、路线数、总陪跑次数、平均评分
    public List<CityRouteStatsVO> getRouteStatsByCity() {
        return routeMapper.selectRouteStatsGroupByCity();
    }
    // 某城市的详细路线列表（下钻）
    public List<StrideRoute> getRoutesByCity(String city) {
        return routeMapper.selectByCity(city);
    }
    // 路线地理热力数据（给高德热力图用）
    public List<HeatPointVO> getRouteHeatMapData() {
        return routeMapper.selectRouteHeatData();
    }

    // ==================== 用户统计 ====================
    public List<TrendPointVO> getUserGrowthTrend() {                    // 用户增长趋势（近30天）
        return userMapper.selectUserGrowthTrend();
    }
    public UserActivityVO getUserActivityDistribution() {               // 活跃度分布
        UserActivityVO vo = new UserActivityVO();
        vo.setHighFreq(userMapper.countHighFreqUsers());   // 周跑3+次
        vo.setMidFreq(userMapper.countMidFreqUsers());     // 周1-2次
        vo.setLowFreq(userMapper.countLowFreqUsers());     // 月1-3次
        vo.setChurned(userMapper.countChurnedUsers());     // 30天未跑
        return vo;
    }
    public List<NameValueVO> getDeviceDistribution() {                  // 设备分布
        return userMapper.selectDeviceDistribution();
    }

    // ==================== 跑步统计 ====================
    public RunTrendVO getRunTrend(int days) {                           // 跑步趋势（7/30天）
        return runMapper.selectRunTrend(days);
    }
    public List<DistanceBracketVO> getRunDistanceDistribution() {        // 跑距分段分布
        return runMapper.selectDistanceDistribution();
    }
    public List<NameValueVO> getAvgPaceDistribution() {                  // 配速分布
        return runMapper.selectPaceDistribution();
    }
    public List<TrendPointVO> getMonthlyDistanceTrend() {                // 月里程趋势
        return runMapper.selectMonthlyDistanceTrend();
    }
    public RunAggregateVO getRunAggregate() {                           // 跑步汇总
        return runMapper.selectRunAggregate();
    }

    // ==================== 挑战跑统计 ====================
    public ChallengeStatsVO getChallengeStats() {
        ChallengeStatsVO vo = new ChallengeStatsVO();
        vo.setTotalChallenges(challengeMapper.countTotal());
        vo.setCompletedChallenges(challengeMapper.countByStatus("completed"));
        vo.setActiveChallenges(challengeMapper.countActive());
        vo.setCancelledChallenges(challengeMapper.countByStatus("cancelled"));
        vo.setCompletionRate(calcRate(vo.getCompletedChallenges(), vo.getTotalChallenges()));
        return vo;
    }
    public List<TrendPointVO> getChallengeTrend() {                     // 挑战趋势
        return challengeMapper.selectChallengeTrend();
    }
    public List<NameValueVO> getGhostModeDistribution() {                // 陪跑模式分布
        return challengeMapper.selectGhostModeDistribution();
    }
    public List<PopularRouteVO> getPopularChallengeRoutes() {            // 热门陪跑路线 TOP10
        return challengeMapper.selectPopularChallengeRoutes();
    }

    // ==================== 排行榜 ====================
    public List<PopularRouteVO> getRoutePopularityRanking() {            // 路线热度排行
        return routeMapper.selectPopularityRanking();
    }
    public List<RunnerRankingVO> getRunnerMonthlyRanking() {             // 跑者月跑量排行
        return runMapper.selectRunnerMonthlyRanking();
    }

    // ==================== 跑境分布 ====================
    public List<NameValueVO> getRealmDistribution() {
        return userMapper.selectRealmDistribution();
    }
}
```

#### 7.4.2 关键统计 SQL

```xml
<!-- StrideRouteMapper.xml — 按城市统计路线 -->
<select id="selectRouteStatsGroupByCity" resultType="com.ruoyi.stridemoor.dto.CityRouteStatsVO">
    SELECT 
        COALESCE(city, '未知') AS city,
        COUNT(*) AS routeCount,
        COALESCE(SUM(popularity), 0) AS totalPopularity,
        ROUND(AVG(rating), 1) AS avgRating
    FROM routes WHERE deleted_at IS NULL AND status = 1
    GROUP BY city ORDER BY routeCount DESC
</select>

<!-- 路线热力数据（给高德热力图） -->
<select id="selectRouteHeatData" resultType="com.ruoyi.stridemoor.dto.HeatPointVO">
    SELECT center_lat AS lat, center_lng AS lng,
           popularity AS intensity, name AS label
    FROM routes WHERE deleted_at IS NULL AND status = 1
      AND center_lat IS NOT NULL AND center_lng IS NOT NULL
</select>

<!-- 路线热度排行（陪跑次数*3 + 评分*评分人数） -->
<select id="selectPopularityRanking" resultType="com.ruoyi.stridemoor.dto.PopularRouteVO">
    SELECT r.id, r.name, r.city, r.distance, r.difficulty,
           r.popularity, r.rating, r.rating_count,
           u.nickname AS creatorName
    FROM routes r LEFT JOIN users u ON r.creator_id = u.id
    WHERE r.deleted_at IS NULL AND r.status = 1
    ORDER BY (r.popularity * 3 + r.rating * r.rating_count) DESC
    LIMIT 50
</select>

<!-- StrideRunMapper.xml — 跑步统计 -->
<select id="sumTotalDistance" resultType="double">
    SELECT COALESCE(SUM(total_distance), 0) FROM runs WHERE deleted_at IS NULL
</select>
<select id="selectRunTrend" resultType="com.ruoyi.stridemoor.dto.RunTrendVO">
    SELECT DATE(start_time) AS date,
           COUNT(*) AS runCount,
           COALESCE(SUM(total_distance), 0) AS totalDistance
    FROM runs WHERE start_time >= DATE_SUB(NOW(), INTERVAL #{days} DAY)
      AND deleted_at IS NULL
    GROUP BY DATE(start_time) ORDER BY date ASC
</select>
<select id="selectRunAggregate" resultType="com.ruoyi.stridemoor.dto.RunAggregateVO">
    SELECT COUNT(*) AS totalRuns,
           COALESCE(SUM(total_distance), 0) AS totalDistance,
           COALESCE(SUM(total_time), 0) AS totalDuration,
           COALESCE(SUM(calories), 0) AS totalCalories,
           ROUND(COALESCE(SUM(total_distance), 0) / COUNT(DISTINCT user_id)) AS avgDistancePerUser
    FROM runs WHERE deleted_at IS NULL
</select>

<!-- ChallengeMapper.xml — 挑战/伴跑统计 -->
<select id="countByStatus" resultType="long">
    SELECT COUNT(*) FROM challenges WHERE status = #{status}
</select>
<select id="countActive" resultType="long">
    SELECT COUNT(*) FROM challenges 
    WHERE status IN ('pending', 'accepted', 'running')
</select>
<select id="selectGhostModeDistribution">
    SELECT ghost_mode AS name, COUNT(*) AS value
    FROM challenges WHERE ghost_mode IS NOT NULL
    GROUP BY ghost_mode ORDER BY value DESC
</select>
<select id="selectPopularChallengeRoutes">
    SELECT r.id, r.name, r.city, r.distance,
           COUNT(c.id) AS challengeCount
    FROM challenges c JOIN routes r ON c.route_id = r.id
    GROUP BY r.id ORDER BY challengeCount DESC LIMIT 10
</select>

<!-- 跑者月跑量排行 -->
<select id="selectRunnerMonthlyRanking" resultType="com.ruoyi.stridemoor.dto.RunnerRankingVO">
    SELECT u.nickname, u.avatar,
           COUNT(*) AS runCount,
           SUM(r.total_distance) AS monthlyDistance,
           ROUND(AVG(r.avg_pace)) AS avgPace
    FROM runs r JOIN users u ON r.user_id = u.id
    WHERE DATE_FORMAT(r.start_time, '%Y-%m') = DATE_FORMAT(NOW(), '%Y-%m')
      AND r.deleted_at IS NULL AND u.deleted_at IS NULL
    GROUP BY r.user_id
    ORDER BY monthlyDistance DESC
    LIMIT 20
</select>
```

#### 7.4.3 Vue 看板页面（6 Tab 完整版）

看板页面按 Tab 组织，每 Tab 一个独立的数据视图：

```
📊 运营数据看板
├── 🏠 概览      ← 8个核心指标卡片 + 跑步趋势图 + 跑距分布 + 地区分布 + 跑境分布
├── 📍 地区分布   ← 高德热力图 + 城市排名表格 + 点击下钻路线列表
├── 👥 用户分析   ← 增长趋势折线图 + 活跃度饼图 + 设备分布 + 用户详情描述列表
├── 🏃 跑步分析   ← 月里程趋势 + 跑距分段 + 配速分布 + 跑步汇总（总次数/总里程/总时长）
├── ⚔️ 挑战分析   ← 挑战概览卡片 + 陪跑模式饼图 + 挑战趋势 + 热门陪跑路线 TOP10
└── 🏆 排行榜    ← 路线热度综合排行 + 跑者月跑量排行
```

**Tab 1 - 概览（展示关键指标 + 趋势图）**

```vue
<template>
  <div class="app-container">
    <!-- 8个核心指标卡片 -->
    <el-row :gutter="12">
      <el-col :span="3" v-for="card in topCards" :key="card.key">
        <el-card shadow="hover" :body-style="{ padding: '12px' }">
          <div class="stat-value" :style="{ color: card.color }">{{ card.value }}</div>
          <div class="stat-label">{{ card.label }}</div>
          <div class="stat-sub" v-if="card.sub">{{ card.sub }}</div>
        </el-card>
      </el-col>
    </el-row>
    
    <!-- 跑步趋势 + 跑距分布 -->
    <el-row :gutter="12" class="mt12">
      <el-col :span="16">
        <el-card>
          <template #header>
            <span>跑步趋势</span>
            <el-radio-group v-model="trendDays" size="small" style="float:right">
              <el-radio-button :value="7">7天</el-radio-button>
              <el-radio-button :value="30">30天</el-radio-button>
            </el-radio-group>
          </template>
          <div ref="trendChart" style="height: 280px"></div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card>
          <template #header>跑距分布</template>
          <div ref="distChart" style="height: 280px"></div>
        </el-card>
      </el-col>
    </el-row>
    
    <!-- 地区分布 + 跑境分布 -->
    <el-row :gutter="12" class="mt12">
      <el-col :span="12">
        <el-card>
          <template #header>🚩 地区路线 TOP10</template>
          <div ref="cityChart" style="height: 260px"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>🏯 跑境分布</template>
          <div ref="realmChart" style="height: 260px"></div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>
```

**Tab 2 - 地区分布（热力图 + 城市表格 + 下钻详情）**

```vue
<template>
  <el-row :gutter="12">
    <el-col :span="16">
      <el-card>
        <template #header>🌏 全国路线热力图</template>
        <div ref="heatMapContainer" style="height: 520px">
          <!-- 嵌入高德地图 JS API + AMap.HeatmapLayer -->
          <!-- 从 getRouteHeatMapData() 获取坐标点数据 -->
        </div>
      </el-card>
    </el-col>
    <el-col :span="8">
      <el-card>
        <template #header>📋 城市路线排名</template>
        <el-table :data="cityStats" size="small" max-height="520" @row-click="drillCity">
          <el-table-column label="#" width="45">
            <template #default="{ $index }">
              <el-tag v-if="$index<3" :type="['danger','warning',''][$index]" size="small">{{ $index+1 }}</el-tag>
              <span v-else>{{ $index+1 }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="city" label="城市" />
          <el-table-column prop="routeCount" label="路线" width="55" align="center" />
          <el-table-column prop="totalPopularity" label="陪跑" width="65" align="center" sortable />
          <el-table-column prop="avgRating" label="均分" width="55" align="center" />
        </el-table>
      </el-card>
    </el-col>
  </el-row>
  
  <!-- 下钻抽屉 -->
  <el-drawer v-model="cityDrawer" :title="selectedCity + '路线列表'" size="40%">
    <el-table :data="cityRoutes" size="small">
      <el-table-column prop="name" label="路线名" min-width="140" />
      <el-table-column label="距离" width="70">
        <template #default="{row}">{{ (row.distance/1000).toFixed(1) }}km</template>
      </el-table-column>
      <el-table-column prop="difficulty" label="难度" width="55" />
      <el-table-column prop="popularity" label="陪跑" width="55" />
      <el-table-column prop="rating" label="评分" width="55" />
      <el-table-column label="状态" width="55">
        <template #default="{row}">
          <dict-tag :options="stridemoor_route_status" :value="row.status" />
        </template>
      </el-table-column>
    </el-table>
  </el-drawer>
</template>
```

**Tab 5 - 挑战分析（包含挑战跑 + 伴跑的完整统计）**

```vue
<template>
  <!-- 挑战概览卡片 -->
  <el-row :gutter="12">
    <el-col :span="4" v-for="c in challengeCards" :key="c.key">
      <el-card shadow="hover">
        <div class="stat-value" :style="{ color: c.color }">{{ c.value }}</div>
        <div class="stat-label">{{ c.label }}</div>
      </el-card>
    </el-col>
  </el-row>
  
  <el-row :gutter="12" class="mt12">
    <el-col :span="12">
      <el-card>
        <template #header>🎭 陪跑模式分布</template>
        <div ref="modeChart" style="height: 300px"></div>
        <!-- 五种模式：真实回放/匀速目标/兔子模式/龟兔模式/目标挑战 -->
      </el-card>
    </el-col>
    <el-col :span="12">
      <el-card>
        <template #header>📈 挑战趋势（近30天）</template>
        <div ref="challengeTrendChart" style="height: 300px"></div>
      </el-card>
    </el-col>
  </el-row>
  
  <el-row :gutter="12" class="mt12">
    <el-col :span="24">
      <el-card>
        <template #header>🔥 热门陪跑路线 TOP10</template>
        <el-table :data="popularChallengeRoutes" size="small">
          <el-table-column label="#" width="50">
            <template #default="{ $index }">{{ $index+1 }}</template>
          </el-table-column>
          <el-table-column prop="name" label="路线名" min-width="160" />
          <el-table-column prop="city" label="城市" width="80" />
          <el-table-column label="距离" width="80">
            <template #default="{row}">{{ (row.distance/1000).toFixed(1) }}km</template>
          </el-table-column>
          <el-table-column prop="challengeCount" label="陪跑次数" width="90" sortable align="center" />
        </el-table>
      </el-card>
    </el-col>
  </el-row>
</template>
```

**Tab 6 - 排行榜**

```vue
<template>
  <el-row :gutter="12">
    <el-col :span="12">
      <el-card>
        <template #header>🔥 路线热度排行 TOP50</template>
        <el-table :data="routeRanking" size="small" max-height="540" @row-click="goRouteDetail">
          <el-table-column label="#" width="50">
            <template #default="{ $index }">
              <el-tag v-if="$index<3" :type="['danger','warning',''][$index]" size="small">{{ $index+1 }}</el-tag>
              <span v-else>{{ $index+1 }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="name" label="路线名" min-width="140" />
          <el-table-column prop="city" label="城市" width="70" />
          <el-table-column label="距离" width="65">
            <template #default="{row}">{{ (row.distance/1000).toFixed(1) }}km</template>
          </el-table-column>
          <el-table-column prop="popularity" label="陪跑" width="55" sortable align="center" />
          <el-table-column prop="rating" label="⭐" width="50" sortable align="center" />
        </el-table>
      </el-card>
    </el-col>
    <el-col :span="12">
      <el-card>
        <template #header>🏃 本月跑量排行 TOP20</template>
        <el-table :data="runnerRanking" size="small" max-height="540">
          <el-table-column label="#" width="50">
            <template #default="{ $index }">
              <el-tag v-if="$index<3" :type="['danger','warning',''][$index]" size="small">{{ $index+1 }}</el-tag>
              <span v-else>{{ $index+1 }}</span>
            </template>
          </el-table-column>
          <el-table-column label="昵称" width="100">
            <template #default="{row}">
              <el-avatar :src="row.avatar" size="small" /> {{ row.nickname }}
            </template>
          </el-table-column>
          <el-table-column label="本月跑量" width="90" sortable>
            <template #default="{row}">{{ (row.monthlyDistance/1000).toFixed(1) }}km</template>
          </el-table-column>
          <el-table-column prop="runCount" label="次数" width="55" sortable align="center" />
          <el-table-column label="均配速" width="75">
            <template #default="{row}">
              {{ Math.floor(row.avgPace/60) }}:{{ String(row.avgPace%60).padStart(2,'0') }}
            </template>
          </el-table-column>
        </el-table>
      </el-card>
    </el-col>
  </el-row>
</template>
```

#### 7.4.4 DTO 一览

```java
// DashboardSummaryVO — 8个核心指标
public class DashboardSummaryVO {
    private long totalUsers;             // 累计注册用户数
    private double totalDistance;        // 跑步总里程(m)
    private long totalRuns;              // 跑步总次数
    private long totalRoutes;            // 路线总数
    private long todayActiveUsers;       // 今日活跃用户数
    private long todayRuns;              // 今日跑步记录数
    private long pendingReviews;         // 待审核动态数
    private long newUsersThisWeek;       // 本周新增用户
}

// CityRouteStatsVO — 按城市路线统计
public class CityRouteStatsVO {
    private String city;                // 城市名
    private long routeCount;            // 路线数
    private long totalPopularity;       // 陪跑总次数
    private double avgRating;           // 平均评分
}

// HeatPointVO — 热力图数据点
public class HeatPointVO {
    private double lat;                 // 纬度
    private double lng;                 // 经度
    private int intensity;              // 热度值（陪跑次数）
    private String label;               // 路线名
}

// UserActivityVO — 用户活跃度分布
public class UserActivityVO {
    private long highFreq;    // 高频（周跑3+次）
    private long midFreq;     // 中频（周1-2次）
    private long lowFreq;     // 低频（月1-3次）
    private long churned;     // 流失（30天未跑）
}

// RunTrendVO — 跑步趋势
public class RunTrendVO {
    private List<String> dates;          // 日期列表
    private List<Long> runCounts;        // 每日跑步数
    private List<Double> totalDistances; // 每日总距离
}

// RunAggregateVO — 跑步汇总
public class RunAggregateVO {
    private long totalRuns;              // 总跑步次数
    private double totalDistance;        // 总里程(m)
    private long totalDuration;          // 总时长(秒)
    private long totalCalories;         // 总消耗(kcal)
    private double avgDistancePerUser;   // 人均跑量(m)
    private double avgDistancePerRun;    // 平均每次(m)
}

// ChallengeStatsVO — 挑战统计
public class ChallengeStatsVO {
    private long totalChallenges;        // 总挑战数
    private long completedChallenges;    // 已完成
    private long activeChallenges;       // 进行中
    private long cancelledChallenges;    // 已取消
    private double completionRate;       // 完成率(%)
}

// RunnerRankingVO — 跑者排行
public class RunnerRankingVO {
    private String nickname;             // 昵称
    private String avatar;              // 头像
    private long runCount;               // 跑步次数
    private double monthlyDistance;      // 月跑量(m)
    private int avgPace;                // 均配速(s/km)
}

// NameValueVO — 名称/值对（通用）
public class NameValueVO {
    private String name;
    private long value;
}

// TrendPointVO — 趋势点（通用）
public class TrendPointVO {
    private String date;
    private double value;
}

// DistanceBracketVO — 跑距分段
public class DistanceBracketVO {
    private String bracket;  // "0-2km", "2-5km"...
    private long count;
}

// PopularRouteVO — 路线排行
public class PopularRouteVO {
    private String id, name, city, creatorName;
    private double distance;
    private int difficulty, popularity, ratingCount, challengeCount;
    private double rating;
}
```
```

### 7.5 AI API 密钥管理

#### 7.5.1 设计要点

```
核心需求：管理员在界面上维护所有AI服务的API密钥，App端通过Go后端统一调用AI服务时，
从后台获取密钥配置，无需在App端硬编码。

流程：
  管理端配置密钥 → 存库（加密）→ Go后端缓存 → App调用AI时透传

安全策略：
  - API_KEY 入库前 AES-256 加密（ruoyi-common 加密工具类）
  - 前端展示时只显示末4位（如：sk-...xYz3）
  - 支持密钥轮换（新密钥立即生效，旧密钥保留30天过渡）
  - 支持每日调用上限控制（达到上限自动熔断）
  - 操作日志记录所有密钥变更（@Log）
```

#### 7.5.2 AiKeyController 接口

```java
@RestController
@RequestMapping("/stridemoor/ai/keys")
public class AiKeyController extends BaseController {

    @Autowired
    private AiKeyService aiKeyService;

    @PreAuthorize("@ss.hasPermi('stridemoor:ai:key:list')")
    @GetMapping("/list")
    @Log(title = "AI密钥管理", businessType = BusinessType.QUERY)
    public TableDataInfo list(AiApiKeys aiApiKeys) {
        startPage();
        List<AiApiKeys> list = aiKeyService.selectAiApiKeysList(aiApiKeys);
        // 脱敏：只显示密钥末4位
        list.forEach(k -> {
            if (k.getApiKey() != null && k.getApiKey().length() > 8) {
                k.setApiKey("..." + k.getApiKey().substring(k.getApiKey().length() - 4));
            }
        });
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('stridemoor:ai:key:add')")
    @PostMapping
    @Log(title = "AI密钥管理", businessType = BusinessType.INSERT)
    @RepeatSubmit
    public AjaxResult add(@Validated @RequestBody AiApiKeys aiApiKeys) {
        // 入库前加密
        aiApiKeys.setApiKey(encryptAES(aiApiKeys.getApiKey()));
        return toAjax(aiApiKeys.insertAiApiKeys(aiApiKeys));
    }

    @PreAuthorize("@ss.hasPermi('stridemoor:ai:key:edit')")
    @PutMapping
    @Log(title = "AI密钥管理", businessType = BusinessType.UPDATE)
    public AjaxResult edit(@Validated @RequestBody AiApiKeys aiApiKeys) {
        if (StringUtils.isNotEmpty(aiApiKeys.getApiKey())) {
            aiApiKeys.setApiKey(encryptAES(aiApiKeys.getApiKey()));
        }
        return toAjax(aiKeyService.updateAiApiKeys(aiApiKeys));
    }

    @PreAuthorize("@ss.hasPermi('stridemoor:ai:key:rotate')")
    @PostMapping("/rotate/{id}")
    @Log(title = "AI密钥管理", businessType = BusinessType.UPDATE)
    public AjaxResult rotate(@PathVariable Long id, @RequestBody Map<String, String> body) {
        // 密钥轮换：新密钥立即生效，旧密钥保留7天过渡期
        String newKey = encryptAES(body.get("newKey"));
        aiKeyService.rotateKey(id, newKey);
        return success();
    }

    @PreAuthorize("@ss.hasPermi('stridemoor:ai:key:toggle')")
    @PutMapping("/toggle/{id}")
    @Log(title = "AI密钥管理", businessType = BusinessType.UPDATE)
    public AjaxResult toggle(@PathVariable Long id) {
        AiApiKeys key = aiKeyService.selectAiApiKeysById(id);
        key.setIsActive(key.getIsActive() == 1 ? 0 : 1);
        return toAjax(aiKeyService.updateAiApiKeys(key));
    }

    @PreAuthorize("@ss.hasPermi('stridemoor:ai:key:delete')")
    @DeleteMapping("/{ids}")
    @Log(title = "AI密钥管理", businessType = BusinessType.DELETE)
    public AjaxResult remove(@PathVariable Long[] ids) {
        return toAjax(aiKeyService.deleteAiApiKeysByIds(ids));
    }
}
```

#### 7.5.3 前端密钥管理页面

```vue
<template>
  <div class="app-container">
    <!-- 搜索栏 -->
    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="供应商" prop="provider">
        <el-select v-model="queryParams.provider" placeholder="全部" clearable style="width:140px">
          <el-option v-for="d in dict.type.stridemoor_ai_provider" :key="d.value" :label="d.label" :value="d.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="使用范围" prop="usageScope">
        <el-select v-model="queryParams.usageScope" placeholder="全部" clearable style="width:140px">
          <el-option v-for="d in dict.type.stridemoor_ai_scope" :key="d.value" :label="d.label" :value="d.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="状态">
        <el-select v-model="queryParams.isActive" placeholder="全部" clearable style="width:100px">
          <el-option label="启用" :value="1" />
          <el-option label="禁用" :value="0" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- 操作按钮区 -->
    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="Plus" @click="handleAdd"
          v-hasPermi="['stridemoor:ai:key:add']">新增密钥</el-button>
      </el-col>
    </el-row>

    <!-- 表格 -->
    <el-table :data="keyList" stripe>
      <el-table-column label="配置名称" prop="name" min-width="140" />
      <el-table-column label="供应商" prop="provider" width="100">
        <template #default="{row}">
          <dict-tag :options="dict.type.stridemoor_ai_provider" :value="row.provider" />
        </template>
      </el-table-column>
      <el-table-column label="API密钥" prop="apiKey" width="160">
        <template #default="{row}">
          <el-input :model-value="row.apiKey" readonly type="password" show-password />
        </template>
      </el-table-column>
      <el-table-column label="默认模型" prop="model" width="120" />
      <el-table-column label="使用范围" prop="usageScope" width="130">
        <template #default="{row}">
          <dict-tag :options="dict.type.stridemoor_ai_scope" :value="row.usageScope" />
        </template>
      </el-table-column>
      <el-table-column label="日限额/已用" width="130" align="center">
        <template #default="{row}">
          <el-progress :percentage="Math.round(row.todayCalls/(row.dailyLimit||1)*100)"
            :stroke-width="12" :text-inside="true" :status="row.todayCalls >= row.dailyLimit ? 'exception' : ''" />
        </template>
      </el-table-column>
      <el-table-column label="状态" width="80" align="center">
        <template #default="{row}">
          <el-switch :model-value="row.isActive==1" @change="handleToggle(row)" />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="220" fixed="right">
        <template #default="{row}">
          <el-button link type="primary" icon="Edit" @click="handleEdit(row)"
            v-hasPermi="['stridemoor:ai:key:edit']">编辑</el-button>
          <el-button link type="warning" icon="Refresh" @click="handleRotate(row)"
            v-hasPermi="['stridemoor:ai:key:rotate']">轮换</el-button>
          <el-button link type="danger" icon="Delete" @click="handleDelete(row)"
            v-hasPermi="['stridemoor:ai:key:delete']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />
  </div>
</template>
```

#### 7.5.4 AiCallLogs 查询页

```
功能：查看所有AI服务调用记录
- 搜索条件：供应商 / 使用范围 / 时间范围 / 状态（成功/失败）
- 列表字段：时间 / 供应商 / 模型 / 场景 / token数 / 耗时(ms) / 费用($) / 状态
- 操作列：点击查看调用详情（请求参数/返回结果）
- 支持按日/周/月汇总图表（调用量趋势 + 费用趋势）
- 导出 Excel
```

#### 7.5.5 Go 后端对接接口约定

```
Go 端新增一个配置加载接口（仅内网调用，不需外部暴露）：

GET /api/v1/admin/ai/config
→ 从 ruoyi-stridemoor 拉取 active=1 的 AI 密钥配置
→ 缓存在 Redis（10分钟过期）
→ Go 端调用 AI 服务时从缓存获取密钥

Go 端调用 AI 后会调用回调接口写入调用日志：
POST /api/v1/admin/ai/log
Body: {
  provider: "openai",
  model: "gpt-4",
  usageScope: "run_analysis",
  requestTokens: 1234,
  responseTokens: 567,
  durationMs: 3200,
  status: "success"
}
→ 写入 ai_call_logs 表
```

---

### 7.6 设备类型定义管理

#### 7.6.1 设计要点

```
目标：在管理端定义驰陌支持的所有第三方设备（手环、指环、手表、心率带），
包括接口协议、数据格式、接入指南，作为 App 端设备接入的「规范文档」。

数据模型（device_types 表）：
  设备种类（kind） → 品牌（brand） → 型号（model） → 接口规范（JSON/Protocol Buffers）

支持的设备种类：
  👋 smart_band  → 智能手环
  💍 smart_ring  → 智能指环  
  ⌚ watch       → 运动手表
  💓 chest_strap → 心率带

每类设备需定义的接口规范（interface_spec 字段 JSON）：
  - 协议类型: BLE / WiFi / HTTP
  - 服务UUID（BLE）
  - 特征UUID（BLE）- 心率/步频/步数 各特征
  - 数据格式: JSON字段定义 / Protobuf schema
  - 采样率（如1s / 5s）
  - 配对接入步骤
```

#### 7.6.2 DeviceTypeController 接口

```java
@RestController
@RequestMapping("/stridemoor/device/types")
public class DeviceTypeController extends BaseController {

    @Autowired
    private DeviceTypeService deviceTypeService;

    // 标准 CRUD（代码生成器自动生成）
    @PreAuthorize("@ss.hasPermi('stridemoor:device:type:list')")
    @GetMapping("/list")
    public TableDataInfo list(DeviceTypes deviceTypes) { ... }

    @PreAuthorize("@ss.hasPermi('stridemoor:device:type:add')")
    @PostMapping
    @Log(title = "设备类型", businessType = BusinessType.INSERT)
    public AjaxResult add(@Validated @RequestBody DeviceTypes deviceTypes) { ... }

    @PreAuthorize("@ss.hasPermi('stridemoor:device:type:edit')")
    @PutMapping
    @Log(title = "设备类型", businessType = BusinessType.UPDATE)
    public AjaxResult edit(@Validated @RequestBody DeviceTypes deviceTypes) { ... }

    @PreAuthorize("@ss.hasPermi('stridemoor:device:type:delete')")
    @DeleteMapping("/{ids}")
    @Log(title = "设备类型", businessType = BusinessType.DELETE)
    public AjaxResult remove(@PathVariable Long[] ids) { ... }
}
```

#### 7.6.3 前端设备定义页

```vue
<template>
  <div class="app-container">
    <!-- 分类筛选标签 -->
    <el-tabs v-model="activeKind" @tab-change="handleKindChange">
      <el-tab-pane label="全部" name="" />
      <el-tab-pane label="智能手环" name="smart_band" />
      <el-tab-pane label="智能指环" name="smart_ring" />
      <el-tab-pane label="运动手表" name="watch" />
      <el-tab-pane label="心率带" name="chest_strap" />
    </el-tabs>

    <el-button type="primary" plain icon="Plus" @click="handleAdd" class="mb8"
      v-hasPermi="['stridemoor:device:type:add']">新增设备</el-button>

    <!-- 设备卡片展示（不是表格，是卡片布局，突出设备品牌感） -->
    <el-row :gutter="16">
      <el-col :span="6" v-for="item in typeList" :key="item.id">
        <el-card shadow="hover" :body-style="{ padding: '16px' }">
          <div class="device-card">
            <div class="device-icon">
              <img :src="getDeviceIcon(item.deviceKind)" style="width:48px;height:48px" />
            </div>
            <div class="device-info">
              <h4>{{ item.brand }} {{ item.model }}</h4>
              <p class="device-meta">
                <dict-tag :options="dict.type.stridemoor_device_kind" :value="item.deviceKind" />
                <el-tag size="small" :type="item.isActive ? 'success' : 'info'">
                  {{ item.isActive ? '已支持' : '未启用' }}
                </el-tag>
              </p>
              <p class="device-specs">
                <span>🔗 {{ item.protocol.toUpperCase() }}</span>
                <span>📊 {{ item.dataFormat }}</span>
                <span>⏱ {{ item.sampleRate }}</span>
              </p>
              <p class="device-data">📊 {{ item.supportedData }}</p>
            </div>
            <div class="device-actions">
              <el-button link type="primary" icon="Document" @click="handleViewSpec(item)">接口规范</el-button>
              <el-button link type="primary" icon="Edit" @click="handleEdit(item)"
                v-hasPermi="['stridemoor:device:type:edit']">编辑</el-button>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 接口规范预览抽屉 -->
    <el-drawer v-model="specDrawer" :title="currentDevice?.brand + ' ' + currentDevice?.model + ' - 接口规范'" size="50%">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="协议">{{ currentDevice?.protocol }}</el-descriptions-item>
        <el-descriptions-item label="数据格式">{{ currentDevice?.dataFormat }}</el-descriptions-item>
        <el-descriptions-item label="采样率">{{ currentDevice?.sampleRate }}</el-descriptions-item>
        <el-descriptions-item label="供电方式">{{ currentDevice?.batteryType }}</el-descriptions-item>
        <el-descriptions-item label="防水等级">{{ currentDevice?.waterproof }}</el-descriptions-item>
        <el-descriptions-item label="固件版本">{{ currentDevice?.firmwareVersion }}</el-descriptions-item>
      </el-descriptions>
      <h4 style="margin-top:16px">📋 接口规范 JSON</h4>
      <el-input type="textarea" :rows="16" :model-value="formatJson(currentDevice?.interfaceSpec)" readonly />
      <h4 style="margin-top:16px">📖 配对接入指南</h4>
      <div v-html="marked(currentDevice?.setupGuide)"></div>
    </el-drawer>
  </div>
</template>
```

#### 7.6.4 interface_spec JSON 规范格式

```json
// 手环示例：小米手环 9
{
  "protocol": "ble",
  "services": [
    {
      "uuid": "0000180D-0000-1000-8000-00805F9B34FB",
      "name": "Heart Rate Service",
      "characteristics": [
        {
          "uuid": "00002A37-0000-1000-8000-00805F9B34FB",
          "name": "Heart Rate Measurement",
          "format": "uint8",
          "unit": "bpm",
          "notify": true
        },
        {
          "uuid": "00002A38-0000-1000-8000-00805F9B34FB",
          "name": "Body Sensor Location",
          "format": "uint8",
          "read": true
        }
      ]
    },
    {
      "uuid": "0000181B-0000-1000-8000-00805F9B34FB",
      "name": "Battery Service",
      "characteristics": [{
        "uuid": "00002A1A-0000-1000-8000-00805F9B34FB",
        "name": "Battery Level",
        "format": "uint8",
        "unit": "%"
      }]
    }
  ],
  "data_mapping": {
    "heart_rate": {
      "service": "0000180D-0000-1000-8000-00805F9B34FB",
      "characteristic": "00002A37-0000-1000-8000-00805F9B34FB",
      "transform": "first_byte & 0x01 == 0 ? value[1] : value[1] | (value[2] << 8)"
    }
  }
}
```

#### 7.6.5 智能指环接口示例

```json
// 指环示例：Oura Ring Gen 4 (模拟)
{
  "protocol": "ble",
  "services": [{
    "uuid": "custom-UUID",
    "name": "Ring Data Service",
    "characteristics": [
      {
        "uuid": "characteristic-UUID-1",
        "name": "Heart Rate",
        "format": "uint16",
        "unit": "bpm"
      },
      {
        "uuid": "characteristic-UUID-2",
        "name": "SpO2",
        "format": "uint8",
        "unit": "%"
      },
      {
        "uuid": "characteristic-UUID-3",
        "name": "Body Temperature",
        "format": "float32",
        "unit": "℃"
      }
    ]
  }]
}
```

#### 7.6.6 接口规范页面组件

配合前端，在管理端提供一个**接口规范预览器**组件：

```
┌─ 接口规范预览 ─────────────────────────────────────────────┐
│ 📋 设备信息                              🔗 BLE  📊 JSON   │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ Service: Heart Rate Service (0x180D)                    │ │
│ │ ├── HR Measurement (0x2A37) ← notify = uint8 bpm       │ │
│ │ └── Body Sensor Location (0x2A38) → read = uint8       │ │
│ │ Service: Battery Service (0x181B)                       │ │
│ │ └── Battery Level (0x2A1A) → read = uint8 %            │ │
│ └────────────────────────────────────────────────────────┘ │
│ 📝 数据映射                                                 │
│ heart_rate → [0x180D/0x2A37] transform: raw_value >> 1    │
│                                                             │
│ 📖 配对接入指南                                             │
│ 1. 确保设备处于配对模式（长按按键3秒）                      │
│ 2. 打开驰陌 App → 设备管理 → 添加设备                      │
│ 3. 扫描附近设备，选择 "Mi Band 9"                          │
│ 4. 点击配对，确认配对码一致                                  │
│ 5. 配对成功 ✓                                               │
└─────────────────────────────────────────────────────────────┘
```

#### 7.6.7 设备绑定统计

```
功能：查看各类设备的实际用户绑定情况和活跃度
- 统计卡片：总绑定设备数 / 今日活跃设备 / 各类型占比
- 设备类型分布饼图（ECharts）
- 各品牌绑定数排行
- 设备表格：用户昵称 / 设备类型 / 品牌型号 / 绑定时间 / 最后同步 / 状态
- 支持按设备类型/品牌/状态筛选
```

---

### 7.7 数据库备份管理

#### 7.7.1 设计要点

```
核心：将备份管理从 Windows Task Scheduler 迁移到 RuoYi 管理端，统一由 RuoYi Quartz 调度。

架构：
  管理端配置备份策略（库/端口/保留天数/cron）
  → BackupJob（Quartz Job Bean）定时调用 mysqldump
  → 备份文件写磁盘 + 记录写入 backup_records 表
  → 旧的备份文件自动清理（按保留天数）

安全：
  - 数据库密码 AES-256 加密存储
  - 操作日志记录每次备份触发（@Log）
  - 仅 admin 角色可配置备份策略
  - 备份文件通过 Nginx 代理下载（不直接暴露目录）

Quartz 集成：
  RuoYi 系统工具 → 定时任务 管理界面中注册 BackupJob，
  cron 表达式从 backup_config 表读取，无需写死在代码里。
  支持在管理界面手动触发（立即执行）、暂停、恢复。
```

#### 7.7.2 BackupJob — Quartz Job 实现

```java
/**
 * 数据库备份定时任务
 * 在 RuoYi 系统工具→定时任务 中注册，cron 从 backup_config 表读取
 */
@Component("backupJob")
public class BackupJob implements IJob {

    @Autowired
    private BackupConfigService backupConfigService;

    @Override
    public void execute(String params) throws Exception {
        // 1. 读取活动的备份配置（is_active = 1）
        BackupConfig config = backupConfigService.getActiveConfig();
        if (config == null) return;

        // 2. 生成备份文件名：stridemoor_yyyy-MM-dd_HHmmss.sql
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HHmmss"));
        String fileName = "stridemoor_" + timestamp + ".sql";
        String filePath = config.getBackupDir() + File.separator + fileName;

        // 3. 执行 mysqldump
        String cmd = String.format(
            "mysqldump -h %s -P %d -u %s -p%s --default-character-set=utf8mb4 --no-tablespaces --result-file=%s %s",
            config.getDbHost(), config.getDbPort(), config.getDbUser(),
            decryptAES(config.getDbPassword()), filePath, config.getDatabases()
        );
        Process process = Runtime.getRuntime().exec(cmd);
        int exitCode = process.waitFor();

        // 4. 写入备份记录
        BackupRecords record = new BackupRecords();
        record.setConfigId(config.getId());
        record.setFileName(fileName);
        record.setFilePath(filePath);
        record.setDatabaseList(config.getDatabases());
        record.setStatus(exitCode == 0 ? "success" : "failed");
        if (exitCode == 0) {
            File backupFile = new File(filePath);
            record.setFileSize(backupFile.length());
            // 压缩 .gz
            if (config.getCompress() == 1) {
                compressGzip(backupFile);
                record.setFilePath(filePath + ".gz");
            }
        }
        backupConfigService.saveRecord(record);

        // 5. 清理过期备份
        cleanupOldBackups(config);
    }

    private void cleanupOldBackups(BackupConfig config) {
        File dir = new File(config.getBackupDir());
        File[] oldFiles = dir.listFiles((d, name) -> name.startsWith("stridemoor_"));
        LocalDateTime cutoff = LocalDateTime.now().minusDays(config.getRetentionDays());
        for (File f : oldFiles) {
            if (f.lastModified() < cutoff.toInstant(ZoneOffset.ofHours(8)).toEpochMilli()) {
                f.delete();
            }
        }
    }
}
```

#### 7.7.3 BackupConfigController 接口

```java
@RestController
@RequestMapping("/stridemoor/backup")
public class BackupConfigController extends BaseController {

    // 标准 CRUD（代码生成器自动生成）
    @PreAuthorize("@ss.hasPermi('stridemoor:backup:config:list')")
    @GetMapping("/config/list")
    public TableDataInfo list(BackupConfig config) { ... }

    @PreAuthorize("@ss.hasPermi('stridemoor:backup:config:add')")
    @PostMapping("/config")
    @Log(title = "备份配置", businessType = BusinessType.INSERT)
    public AjaxResult add(@Validated @RequestBody BackupConfig config) { ... }

    @PreAuthorize("@ss.hasPermi('stridemoor:backup:config:edit')")
    @PutMapping("/config")
    @Log(title = "备份配置", businessType = BusinessType.UPDATE)
    public AjaxResult edit(@Validated @RequestBody BackupConfig config) { ... }

    @PreAuthorize("@ss.hasPermi('stridemoor:backup:delete')")
    @DeleteMapping("/config/{ids}")
    @Log(title = "备份配置", businessType = BusinessType.DELETE)
    public AjaxResult remove(@PathVariable Long[] ids) { ... }

    // 手动触发备份
    @PreAuthorize("@ss.hasPermi('stridemoor:backup:execute')")
    @PostMapping("/run/{configId}")
    @Log(title = "备份管理", businessType = BusinessType.OTHER, desc = "手动触发数据库备份")
    public AjaxResult runBackup(@PathVariable Long configId) {
        backupConfigService.runBackup(configId);
        return success("备份任务已触发，请稍后查看记录");
    }

    // 备份记录列表
    @PreAuthorize("@ss.hasPermi('stridemoor:backup:record:list')")
    @GetMapping("/records")
    public TableDataInfo records(BackupRecords query) { ... }

    // 下载备份文件
    @PreAuthorize("@ss.hasPermi('stridemoor:backup:download')")
    @GetMapping("/download/{recordId}")
    public void download(@PathVariable Long recordId, HttpServletResponse response) {
        BackupRecords record = backupConfigService.selectRecordById(recordId);
        File file = new File(record.getFilePath());
        // 文件流输出
        try (InputStream is = new FileInputStream(file)) {
            response.setContentType("application/octet-stream");
            response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode(record.getFileName(), "UTF-8"));
            IOUtils.copy(is, response.getOutputStream());
        }
    }
}
```

#### 7.7.4 前端备份管理页面

```vue
<!-- 备份配置页：src/views/stridemoor/backup/config.vue -->
<template>
  <div class="app-container">
    <!-- 备份策略配置表单（仅一条活动配置） -->
    <el-card shadow="never" class="mb16">
      <template #header>
        <span>📋 备份策略配置</span>
      </template>
      <el-form :model="configForm" label-width="120px" v-if="configForm">
        <el-row :gutter="24">
          <el-col :span="8">
            <el-form-item label="数据库地址">
              <el-input v-model="configForm.dbHost" placeholder="127.0.0.1" />
            </el-form-item>
          </el-col>
          <el-col :span="4">
            <el-form-item label="端口">
              <el-input-number v-model="configForm.dbPort" :min="1" :max="65535" />
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="数据库用户">
              <el-input v-model="configForm.dbUser" />
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="密码">
              <el-input v-model="configForm.dbPassword" type="password" show-password />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="备份库名">
              <el-input v-model="configForm.databases" placeholder="stridemoor" />
              <span class="el-form-item__tips">多个库用逗号分隔：stridemoor,ry_stridemoor</span>
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="保留天数">
              <el-input-number v-model="configForm.retentionDays" :min="1" :max="365" />
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="压缩">
              <el-switch v-model="configForm.compress" :active-value="1" :inactive-value="0" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="备份目录">
              <el-input v-model="configForm.backupDir" placeholder="E:\\bakeup" />
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="Cron表达式">
              <el-input v-model="configForm.cronExpression" placeholder="0 0 3 * * ?" />
            </el-form-item>
          </el-col>
          <el-col :span="6" style="display:flex;align-items:center;gap:8px">
            <el-button type="primary" @click="handleSave">💾 保存配置</el-button>
            <el-button type="success" @click="handleRunNow" :loading="running">▶ 立即备份</el-button>
          </el-col>
        </el-row>
        <!-- 最近备份状态 -->
        <el-alert v-if="configForm.lastBackupTime"
          :title="'上次备份: ' + configForm.lastBackupTime + ' | 大小: ' + formatSize(configForm.lastBackupSize) + ' | 状态: ' + (configForm.lastBackupStatus === 'success' ? '✅ 成功' : '❌ 失败')"
          :type="configForm.lastBackupStatus === 'success' ? 'success' : 'warning'" show-icon />
      </el-form>
    </el-card>

    <!-- 备份历史记录表格 -->
    <el-card shadow="never">
      <template #header>
        <span>📂 备份历史记录</span>
      </template>
      <el-table :data="recordList" stripe>
        <el-table-column label="文件名" prop="fileName" min-width="200" />
        <el-table-column label="大小" prop="fileSize" width="100" align="right">
          <template #default="{row}">{{ formatSize(row.fileSize) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template #default="{row}">
            <dict-tag :options="dict.type.stridemoor_backup_status" :value="row.status" />
          </template>
        </el-table-column>
        <el-table-column label="触发方式" prop="triggerType" width="100">
          <template #default="{row}">
            <dict-tag :options="dict.type.stridemoor_backup_trigger" :value="row.triggerType" />
          </template>
        </el-table-column>
        <el-table-column label="备份时间" prop="createTime" width="170" />
        <el-table-column label="耗时" prop="durationSec" width="80">
          <template #default="{row}">{{ row.durationSec }}s</template>
        </el-table-column>
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{row}">
            <el-button link type="primary" icon="Download" @click="handleDownload(row)"
              v-if="row.status === 'success'" v-hasPermi="['stridemoor:backup:download']">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="recordTotal>0" :total="recordTotal" v-model:page="queryParams.pageNum"
        v-model:limit="queryParams.pageSize" @pagination="getRecords" />
    </el-card>
  </div>
</template>
```

---

## 八、前端页面完整列表（Ruoyi-ui/views/stridemoor/）

```
src/views/stridemoor/
├── review/
│   ├── index.vue          ← 审核列表（含搜索、批量操作）
│   └── detail.vue         ← 审核详情（跑迹地图预览）
├── route/
│   ├── index.vue          ← 路线列表（含编辑、上下架）
│   ├── edit.vue           ← 路线编辑表单
│   └── duplicate.vue      ← 疑似重复列表（并排轨迹对比）
├── cleanup/
│   ├── index.vue          ← 清理概览（统计卡片+预览列表）
│   ├── preview.vue        ← 清理预览详情
│   └── history.vue        ← 清理历史记录
├── user/
│   └── index.vue          ← 用户列表（封禁/解禁/导出）
├── post/
│   └── index.vue          ← 动态管理（隐藏/显示/删除）
├── realm/
│   └── index.vue          ← 跑境配置（各境界条件编辑）
├── ai/
│   ├── key.vue            ← AI API密钥管理（列表/新增/编辑/轮换/启禁）
│   ├── key-detail.vue     ← 密钥表单弹窗
│   └── log.vue            ← AI调用日志（搜索+表格+日周月汇总图表+导出）
├── device/
│   ├── type.vue           ← 设备类型定义（卡片布局，按种类Tab筛选）
│   ├── type-form.vue      ← 设备新增/编辑表单（含JSON编辑器）
│   └── bind-stat.vue      ← 设备绑定统计（统计卡片+饼图+排行+表格）
├── backup/
│   ├── index.vue          ← 备份管理主页面（配置 + 记录列表）
│   └── config.vue         ← 备份配置弹窗
└── dashboard/
    ├── index.vue          ← 运营数据看板（Tab 容器页，内嵌6个子Tab）
    ├── overview.vue       ← 🏠 概览（8个核心指标卡片 + 跑步趋势折线图 + 跑距分布饼图 + 地区TOP10柱状图 + 跑境饼图）
    ├── region.vue         ← 📍 地区分布（高德热力图 + 城市排名表格 + 点击下钻城市路线列表抽屉）
    ├── users.vue          ← 👥 用户分析（增长趋势图 + 活跃度分布饼图 + 设备分布图 + 用户总量描述列表）
    ├── running.vue        ← 🏃 跑步分析（月度里程趋势柱状图 + 跑距分段柱状图 + 配速分布 + 跑步汇总6项）
    ├── challenge.vue      ← ⚔️ 挑战分析（挑战概览4卡片 + 伴跑模式饼图 + 挑战趋势折线图 + 热门陪跑路线表格）
    └── ranking.vue        ← 🏆 排行榜（路线热度排行TOP50表格 + 跑者月跑量排行TOP20表格）
```

---

## 九、完整权限控制

### 9.1 RuoYi 标准 @PreAuthorize

```java
// 按钮级权限控制
@PreAuthorize("@ss.hasPermi('stridemoor:review:approve')")
@PostMapping("/approve/{postId}")
public AjaxResult approve(...) { ... }
```

### 9.2 数据权限（@DataScope）

如果需要某个管理员只能看到自己负责区域的路线：
```java
// 需要在 domain 加字段，然后在 mapper XML 配合
@DataSource("slave")
@DataScope(deptAlias = "r")
public List<StrideRoute> selectRouteList(StrideRoute route) {
    return routeMapper.selectRouteList(route);
}
```

### 9.3 操作审计（@Log）

```java
@Log(title = "路线管理", businessType = BusinessType.DELETE)
@DeleteMapping("/{id}")
public AjaxResult remove(@PathVariable String id) {
    // 业务代码...
}
```

操作完成后，在 RuoYi → 系统管理 → 操作日志 中可查看：
```
操作用户: admin
操作模块: 路线管理
操作类型: 删除
操作时间: 2026-05-10 10:32:15
请求URL: /stridemoor/route/xxx
请求参数: {"id": "xxx"}
操作结果: 成功
```

**这些全部是若依框架自带能力，我们只需要在 Controller 上加注解即可。**

---

## 十、实施步骤（按 RuoYi 开发顺序）

### Phase 1：环境搭建（1天）

```
□ 1.1 下载 RuoYi-Vue3 源码
□ 1.2 创建 ry_stridemoor 数据库（RuoYi 自动建表）
□ 1.3 配置 application-druid.yml 双数据源
□ 1.4 创建 ruoyi-stridemoor 模块（pom.xml + 目录结构）
□ 1.5 启动验证：管理员登录 RuoYi 界面正常
□ 1.6 扫码连接 stridemoor 库验证成功
```

### Phase 2：数据映射 + 代码生成（1天）

```
□ 2.1 执行新增表/字段 SQL
□ 2.2 post_reviews / admin_roles / duplicate_groups / cleanup_logs → 代码生成
□ 2.3 生成物导入 ruoyi-stridemoor 模块
□ 2.4 手动创建 stridemoor 库已存在表的 Domain/Mapper
□ 2.5 创建数据字典（审核状态/距离档位等）
□ 2.6 创建菜单树 + 分配权限标识
```

### Phase 3：跑迹审核（2天）

```
□ 3.1 ReviewController（含 approve/reject/batch）
□ 3.2 ReviewServiceImpl（联表查 post+user+route）
□ 3.3 前端列表页（搜索/筛选/批量/分页）
□ 3.4 前端详情抽屉（轨迹地图组件）
□ 3.5 审核统计角标
```

### Phase 4：路线管理（2天）

```
□ 4.1 RouteManageController + Service（编辑/删除/上下架）
□ 4.2 RouteMatcherService（Hausdorff 距离算法）
□ 4.3 DuplicateGroupsController（手动检测/列表/合并）
□ 4.4 前端路线列表页
□ 4.5 前端疑似重复页（并排轨迹对比）
```

### Phase 5：数据清理（1天）

```
□ 5.1 CleanupService（零距离/异常记录查询）
□ 5.2 CleanupController（预览/执行/历史/恢复）
□ 5.3 Quartz 定时任务配置
□ 5.4 前端清理页
```

### Phase 6：驰陌主题定制（1天）

```
□ 6.1 品牌色体系配置（variables.scss 覆盖 Element Plus 变量）
□ 6.2 登录页改造（驰陌品牌展示 + 奔跑动画 + 实时统计）
□ 6.3 侧边栏样式（深色 #1A1A2E + 渐变色焦点标识）
□ 6.4 数据看板卡片样式（圆角/上浮阴影/主题色左边框）
□ 6.5 全局表格/按钮/标签样式统一
□ 6.6 Logo + Favicon 素材准备
```

### Phase 7：数据看板（3天）

```
□ 7.1 DashboardService（8个概览指标 + 城市统计 + 热力图数据 + 用户分析 + 跑步趋势 + 挑战统计 + 排行）
□ 7.2 DashboardController（6个Tab的API接口 + 数据导出接口）
□ 7.3 Mapper SQL（12个统计查询 + 排行查询 + 报表查询）
□ 7.4 DTO 类（DashboardSummaryVO / CityRouteStatsVO / HeatPointVO / UserActivityVO / RunTrendVO / ChallengeStatsVO 等15个DTO）
□ 7.5 Vue 概览 Tab（8个核心指标卡片 + ECharts 折线图/饼图/柱状图）
□ 7.6 Vue 地区分布 Tab（高德地图 + 热力图图层 + 城市排名表格 + 下钻抽屉）
□ 7.7 Vue 用户分析 Tab（增长趋势 + 活跃度分布 + 设备分布 + 用户描述列表）
□ 7.8 Vue 跑步分析 Tab（月里程趋势 + 跑距分段 + 配速分布 + 跑步汇总6项）
□ 7.9 Vue 挑战分析 Tab（挑战概览4卡片 + 伴跑模式饼图 + 挑战趋势 + 热门陪跑路线）
□ 7.10 Vue 排行榜 Tab（路线热度TOP50 + 跑者月跑量TOP20）
□ 7.11 StatsExportService（Excel 报表导出）
```

### Phase 8：AI API密钥 + 设备管理（2天）

```
□ 8.1 代码生成：ai_api_keys / ai_call_logs / device_types / device_bind_stats 四张表
□ 8.2 AiKeyController（CRUD + 密钥脱敏 + 加密存储 + 轮换）
□ 8.3 AiKeyService（AES-256 加解密）
□ 8.4 AiLogController（日志查询 + 汇总统计 + 导出）
□ 8.5 Go 端对接接口约定（配置拉取 + 日志回调）
□ 8.6 Vue AI密钥管理页（表格 + 进度条日限额 + 启禁开关）
□ 8.7 Vue AI日志页（搜索 + 折线图趋势 + Excel导出）
□ 8.8 DeviceTypeController（CRUD + 分类Tab筛选）
□ 8.9 Vue 设备类型定义页（卡片布局 + JSON编辑器 + 接口规范预览抽屉）
□ 8.10 Vue 设备绑定统计页（统计卡片 + 饼图 + 排行 + 表格）
```

### Phase 9：其余功能 + 备份管理迁移（2天）

```
□ 9.1 用户管理（列表/封禁/解禁/导出）
□ 9.2 动态管理（列表/删除/隐藏）
□ 9.3 跑境管理（配置查看/手动调境）
□ 9.4 数据库备份迁移（RuoYi Quartz 接管）
    - 代码生成：backup_config / backup_records 两张表
    - BackupConfigController（配置 CRUD + 手动触发 + 文件下载）
    - BackupJob Quartz Job Bean（调用 mysqldump 命令）
    - BackupConfigService（密码加解密 + 脚本参数组装）
    - 在 RuoYi 系统工具→定时任务 注册 BackupJob（cron: 0 0 3 * * ?）
    - Vue 备份管理页（策略配置表单 + 历史记录表格 + 一键备份按钮）
□ 9.5 关闭 Windows Task Scheduler 的 `\StrideMoor-DBBackup` 任务
□ 9.6 手动验证备份：触发一次 → 检查备份文件 → 确认记录写入
```

### Phase 10：集成测试 + 部署（1天）

```
□ 10.1 App 端适配：Go 后端查询过滤 review_status/is_hidden/deleted_at
□ 10.2 全流程联调：用户端发布 → 管理端审核 → 用户端可见性变化
□ 10.3 AI密钥从管理端配置 → Go端缓存 → App调用链验证
□ 10.4 设备接口规范录入 → App端按规范对接验证
□ 10.5 看板数据与数据库一致性验证
□ 10.6 Docker 打包 RuoYi 项目
□ 10.7 域名配置 + HTTPS + Nginx
□ 10.8 备份全链路验证：Quartz触发 → mysqldump执行 → 文件落盘 → 记录入库
```



---

## 十一、与现有 Go 后端配合要点

### 11.1 Go 端需要改的查询

```go
// 跑迹广场列表 — 追加过滤条件
db.Where("review_status = ?", 1)     // 只显示已通过
db.Where("is_hidden = ?", 0)         // 不显示隐藏
db.Where("deleted_at IS NULL")       // 不显示已删除
```

### 11.2 Go 端创建动态时

```go
// Go 后端创建 Post 时初始化为待审核
post.ReviewStatus = 0 // 待审核
```

### 11.3 不影响现有 API 兼容性

RuoYi 管理端新增的字段全部有默认值，现有 API 不传这些字段时：
- `review_status` 默认 0（待审核）
- `is_hidden` 默认 0（不隐藏）
- `deleted_at` 默认 NULL（未删除）

**所有改动向后兼容，现有 App 端无需修改。**

**总计：约 16 天**（含主题定制1天、看板3天、AI+设备2天、备份管理迁移1天）

---

## 十二、文档总结

这份方案完全按照 RuoYi 原生规范设计：

| 维度 | 标准 |
|------|------|
| 模块 | 一个 `ruoyi-stridemoor` 模块，插在标准 RuoYi 项目 |
| 架构 | 多数据源，读 stridemoor 库，写 ry 库 |
| 生成器 | 12 张新表用代码生成，已有表手动映射 |
| 权限 | `@PreAuthorize` + 菜单管理 + 数据字典 |
| 日志 | `@Log` 自动记录操作日志 |
| 任务 | Quartz 定时任务管理界面配置 |
| 备份 | RuoYi Quartz 定时任务接管，Web 页面配置备份策略 |
| 前端 | 标准 Vue3 + Element Plus 组件 |
| 部署 | Docker Compose + Nginx |

方案文档已更新：`D:\AI\StrideMoor\docs\admin-panel-plan.md`
