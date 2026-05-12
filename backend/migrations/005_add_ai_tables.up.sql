-- AI能力层迁移脚本
-- 新增 ai_api_keys（API密钥配置）和 ai_call_logs（调用日志）两张表

-- ai_api_keys: 管理AI模型配置（由管理端维护）
CREATE TABLE IF NOT EXISTS `ai_api_keys` (
    `id`          CHAR(36) PRIMARY KEY,
    `feature`     VARCHAR(50)  NOT NULL COMMENT '功能标识: coach|summary|route|comment|match|daily',
    `provider`    VARCHAR(30)  NOT NULL COMMENT '服务商: deepseek|openai|kimi|qianwen|huawei',
    `model`       VARCHAR(100) NOT NULL COMMENT '模型标识',
    `api_key`     VARCHAR(500) NOT NULL COMMENT 'API密钥（加密存储）',
    `base_url`    VARCHAR(300) DEFAULT NULL COMMENT '自定义endpoint（如需代理）',
    `max_tokens`  INT          DEFAULT 2048 COMMENT '单次最大输出token',
    `temperature` DECIMAL(3,2) DEFAULT 0.70 COMMENT '温度参数',
    `enabled`     TINYINT(1)   DEFAULT 1 COMMENT '是否启用',
    `priority`    INT          DEFAULT 0 COMMENT '优先级（高>低）',
    `remark`      VARCHAR(200) DEFAULT NULL COMMENT '备注',
    `created_at`  DATETIME(3)  NOT NULL,
    `updated_at`  DATETIME(3)  NOT NULL,
    UNIQUE KEY `uk_feature_provider` (`feature`, `provider`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI模型配置表';

-- ai_call_logs: 记录每次AI调用（用于计费/审计/排障）
CREATE TABLE IF NOT EXISTS `ai_call_logs` (
    `id`          CHAR(36) PRIMARY KEY,
    `user_id`     CHAR(36) DEFAULT NULL COMMENT '触发用户（可为NULL，如管理端触发）',
    `feature`     VARCHAR(50)  NOT NULL COMMENT '功能标识（同ai_api_keys.feature）',
    `model`       VARCHAR(100) NOT NULL COMMENT '实际调用的模型',
    `input_tokens`  INT DEFAULT NULL COMMENT '输入token数',
    `output_tokens` INT DEFAULT NULL COMMENT '输出token数',
    `total_tokens`  INT GENERATED ALWAYS AS (COALESCE(input_tokens,0) + COALESCE(output_tokens,0)) STORED COMMENT '总token',
    `latency_ms`    INT DEFAULT NULL COMMENT '耗时（毫秒）',
    `status`      VARCHAR(20)  NOT NULL COMMENT '状态: success|error|timeout|fallback',
    `error_msg`   VARCHAR(500) DEFAULT NULL COMMENT '错误信息（失败时）',
    `request`     MEDIUMTEXT DEFAULT NULL COMMENT '请求体摘要（脱敏）',
    `response`    MEDIUMTEXT DEFAULT NULL COMMENT '响应摘要（截断）',
    `ip_address`  VARCHAR(45) DEFAULT NULL COMMENT '调用来源IP',
    `created_at`  DATETIME(3)  NOT NULL,
    INDEX `idx_user` (`user_id`),
    INDEX `idx_feature` (`feature`),
    INDEX `idx_created_at` (`created_at`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI调用日志表';

-- 初始化：给跑情分析（ai_run_analysis）插入一条默认配置占位
INSERT INTO `ai_api_keys` (`id`, `feature`, `provider`, `model`, `api_key`, `max_tokens`, `temperature`, `enabled`, `priority`, `created_at`, `updated_at`)
SELECT UUID(), 'run_analysis', 'deepseek', 'deepseek-chat', 'YOUR_API_KEY_HERE', 2048, 0.70, 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `ai_api_keys` WHERE `feature` = 'run_analysis' AND `provider` = 'deepseek');