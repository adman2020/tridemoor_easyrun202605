-- AI 跑情分析结果缓存表
-- 跑完即生成，查看时直接读取
CREATE TABLE IF NOT EXISTS ai_analyses (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    run_id      CHAR(36) NOT NULL UNIQUE COMMENT '关联的跑步记录ID',
    user_id     CHAR(36) NOT NULL COMMENT '用户ID',
    analysis_text TEXT NOT NULL COMMENT 'AI 分析原文',
    tokens      INT UNSIGNED DEFAULT 0 COMMENT 'AI 消耗 token 数',
    duration_ms INT UNSIGNED DEFAULT 0 COMMENT 'AI 生成耗时(毫秒)',
    model       VARCHAR(64) DEFAULT '' COMMENT '使用的 AI 模型名称',
    weather     VARCHAR(32) DEFAULT '' COMMENT '分析时注入的天气',
    temperature TINYINT DEFAULT NULL COMMENT '分析时注入的温度(°C)',
    created_at  DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    updated_at  DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    INDEX idx_ai_analyses_user_id (user_id),
    INDEX idx_ai_analyses_run_id (run_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI 跑情分析缓存';
