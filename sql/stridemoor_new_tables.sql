-- ==============================
-- New Management Tables for stridemoor database
-- These are the RuoYi code-gen compatible tables
-- ==============================

-- 1. post_reviews 跑迹审核记录表
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

-- 2. admin_roles 管理员角色表
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

-- 3. duplicate_groups 重复路线分组表
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

-- 4. cleanup_logs 数据清理日志表
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

-- 5. ai_api_keys AI API 密钥配置表
CREATE TABLE IF NOT EXISTS `ai_api_keys` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `provider`        VARCHAR(50) NOT NULL COMMENT '供应商: openai / claude / kiro / minimax / custom',
    `name`            VARCHAR(100) NOT NULL COMMENT '配置名称',
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

-- 6. ai_call_logs AI 服务调用日志表
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

-- 7. device_types 设备类型定义表
CREATE TABLE IF NOT EXISTS `device_types` (
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `device_kind`     VARCHAR(50) NOT NULL COMMENT '设备种类: smart_band / smart_ring / watch / chest_strap',
    `brand`           VARCHAR(100) NOT NULL COMMENT '品牌',
    `model`           VARCHAR(100) NOT NULL COMMENT '型号',
    `protocol`        VARCHAR(50) NOT NULL DEFAULT 'ble' COMMENT '连接协议: ble / wifi / http',
    `interface_spec`  JSON COMMENT '接口规范',
    `supported_data`  VARCHAR(255) COMMENT '支持的数据类型: hr / pace / steps / sleep / spo2',
    `data_format`     VARCHAR(50) NOT NULL DEFAULT 'json' COMMENT '数据格式: json / protobuf / csv',
    `sample_rate`     VARCHAR(50) COMMENT '采样率',
    `battery_type`    VARCHAR(50) DEFAULT 'rechargeable' COMMENT '供电方式',
    `waterproof`      VARCHAR(20) COMMENT '防水等级',
    `firmware_version` VARCHAR(50) COMMENT '当前固件版本',
    `setup_guide`     TEXT COMMENT '配对接入指南',
    `is_active`       TINYINT(1) DEFAULT 1 COMMENT '是否支持',
    `remarks`         VARCHAR(500) COMMENT '备注',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_kind` (`device_kind`),
    INDEX `idx_brand` (`brand`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备类型定义';

-- 8. device_bind_stats 设备绑定统计表
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

-- 9. backup_config 备份配置表
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
    `cron_expression` VARCHAR(100) NOT NULL DEFAULT '0 0 3 * * ?' COMMENT 'Quartz cron 表达式',
    `compress`        TINYINT(1) DEFAULT 1 COMMENT '是否压缩(.gz)',
    `is_active`       TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    `last_backup_time` DATETIME COMMENT '最近一次备份时间',
    `last_backup_size` BIGINT DEFAULT 0 COMMENT '最近备份大小(字节)',
    `last_backup_status` VARCHAR(20) DEFAULT 'none' COMMENT 'none/success/failed',
    `remarks`         VARCHAR(500) COMMENT '备注',
    `create_time`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='备份配置';

-- 10. backup_records 备份记录表
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
