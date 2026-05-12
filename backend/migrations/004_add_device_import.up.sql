-- 004_add_device_import.up.sql
-- 设备管理 & 第三方跑步记录导入

-- 用户绑定设备表
CREATE TABLE IF NOT EXISTS devices (
    id           CHAR(36)     PRIMARY KEY,
    user_id      CHAR(36)     NOT NULL,
    name         VARCHAR(100) NOT NULL COMMENT '显示名称',
    device_type  VARCHAR(50)  NOT NULL COMMENT 'smartwatch/fitness_band/hr_monitor/smart_ring',
    brand        VARCHAR(50)  NOT NULL COMMENT 'Apple/Huawei/Garmin/Xiaomi/Polar',
    model        VARCHAR(100) DEFAULT '' COMMENT '具体型号',
    conn_type    VARCHAR(50)  NOT NULL COMMENT 'ble/apple_health/huawei_health/garmin/health_connect',
    mac_addr     VARCHAR(100) DEFAULT '' COMMENT '设备唯一标识',
    is_connected BOOLEAN      DEFAULT FALSE COMMENT '当前连接状态',
    battery      TINYINT      DEFAULT NULL COMMENT '电量 0~100',
    last_sync_at DATETIME(3)  DEFAULT NULL COMMENT '最后同步时间',
    created_at   DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3),
    updated_at   DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    INDEX idx_device_user (user_id),
    INDEX idx_device_conn (conn_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户绑定的可穿戴设备';

-- 第三方导入记录表（防重复导入）
CREATE TABLE IF NOT EXISTS import_records (
    id           CHAR(36)     PRIMARY KEY,
    user_id      CHAR(36)     NOT NULL,
    run_id       CHAR(36)     NOT NULL,
    source       VARCHAR(50)  NOT NULL COMMENT '数据来源: apple_health/huawei_health/health_connect/garmin',
    source_id    VARCHAR(255) NOT NULL COMMENT '健康平台侧跑步记录唯一 ID',
    device_id    CHAR(36)     DEFAULT NULL COMMENT '关联的设备 ID',
    imported_at  DATETIME(3)  DEFAULT CURRENT_TIMESTAMP(3),
    INDEX idx_import_user (user_id),
    INDEX idx_import_source (source),
    UNIQUE KEY uk_source_srcid (source, source_id(100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='跑步记录导入历史';
