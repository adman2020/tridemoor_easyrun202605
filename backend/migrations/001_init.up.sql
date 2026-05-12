-- ============================================================
-- 驰陌 StrideMoor 数据库初始化脚本 (MySQL 8.0)
-- 字符集：utf8mb4
-- 时区：Asia/Shanghai
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1. 用户表 (users)
-- ============================================================
CREATE TABLE IF NOT EXISTS `users` (
    `id`              CHAR(36) PRIMARY KEY COMMENT 'UUID',
    `phone`           VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号',
    `password_hash`   VARCHAR(255) NOT NULL COMMENT 'bcrypt哈希',
    `nickname`        VARCHAR(50) NOT NULL DEFAULT '跑者' COMMENT '昵称',
    `avatar`          VARCHAR(500) COMMENT '头像OSS URL',
    `gender`          TINYINT COMMENT '0:未知 1:男 2:女',
    `birthday`        DATE COMMENT '生日',
    `height`          SMALLINT COMMENT '身高(cm)',
    `weight`          SMALLINT COMMENT '体重(kg)',
    `total_distance`  DECIMAL(10,2) DEFAULT 0 COMMENT '累计距离(m)',
    `total_runs`      BIGINT DEFAULT 0 COMMENT '累计次数',
    `total_time`      BIGINT DEFAULT 0 COMMENT '累计时长(秒)',
    `device_info`     JSON COMMENT '设备信息',
    `settings`        JSON COMMENT '用户设置',
    `created_at`      DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at`      DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    INDEX `idx_phone` (`phone`),
    INDEX `idx_nickname` (`nickname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ============================================================
-- 2. 路线表 (routes)
-- ============================================================
CREATE TABLE IF NOT EXISTS `routes` (
    `id`              CHAR(36) PRIMARY KEY COMMENT 'UUID',
    `creator_id`      CHAR(36) NOT NULL COMMENT '创建者',
    `name`            VARCHAR(100) NOT NULL COMMENT '路线名称',
    `description`     TEXT COMMENT '路线描述',
    `distance`        DECIMAL(10,2) NOT NULL COMMENT '距离(m)',
    `elevation_gain`  DECIMAL(10,2) DEFAULT 0 COMMENT '爬升(m)',
    `elevation_loss`  DECIMAL(10,2) DEFAULT 0 COMMENT '下降(m)',
    `difficulty`      TINYINT DEFAULT 1 COMMENT '1:轻松 2:中等 3:挑战',
    `popularity`      INT DEFAULT 0 COMMENT '被陪跑次数',
    `rating`          DECIMAL(2,1) DEFAULT 5.0 COMMENT '评分0-5',
    `rating_count`    INT DEFAULT 0 COMMENT '评分人数',
    `gpx_file_url`    VARCHAR(500) COMMENT 'GPX文件OSS URL',
    `thumbnail_url`   VARCHAR(500) COMMENT '缩略图OSS URL',
    `tags`            JSON COMMENT '标签数组',
    `city`            VARCHAR(50) COMMENT '城市',
    `start_lat`       DECIMAL(10,7) COMMENT '起点纬度',
    `start_lng`       DECIMAL(10,7) COMMENT '起点经度',
    `center_lat`      DECIMAL(10,7) COMMENT '中心点纬度',
    `center_lng`      DECIMAL(10,7) COMMENT '中心点经度',
    `is_public`       TINYINT(1) DEFAULT 1 COMMENT '是否公开',
    `status`          TINYINT DEFAULT 1 COMMENT '1:正常 2:下架',
    `created_at`      DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at`      DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    INDEX `idx_creator` (`creator_id`),
    INDEX `idx_city` (`city`),
    INDEX `idx_difficulty` (`difficulty`),
    INDEX `idx_distance` (`distance`),
    INDEX `idx_popularity` (`popularity` DESC),
    INDEX `idx_location` (`center_lat`, `center_lng`),
    INDEX `idx_status` (`status`, `is_public`),
    FULLTEXT INDEX `idx_name` (`name`) WITH PARSER ngram,
    CONSTRAINT `fk_routes_creator` FOREIGN KEY (`creator_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='路线表';

-- ============================================================
-- 2.1 路线坐标点表 (route_points)
-- ============================================================
CREATE TABLE IF NOT EXISTS `route_points` (
    `route_id`    CHAR(36) NOT NULL COMMENT '路线ID',
    `point_index` INT NOT NULL COMMENT '点序号',
    `latitude`    DECIMAL(10,7) NOT NULL COMMENT '纬度',
    `longitude`   DECIMAL(10,7) NOT NULL COMMENT '经度',
    `altitude`    DECIMAL(10,2) COMMENT '海拔(m)',
    PRIMARY KEY (`route_id`, `point_index`),
    INDEX `idx_route` (`route_id`),
    CONSTRAINT `fk_points_route` FOREIGN KEY (`route_id`) REFERENCES `routes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='路线坐标点表';

-- ============================================================
-- 3. 跑步记录表 (runs)
-- ============================================================
CREATE TABLE IF NOT EXISTS `runs` (
    `id`              CHAR(36) PRIMARY KEY COMMENT 'UUID',
    `user_id`         CHAR(36) NOT NULL COMMENT '用户ID',
    `route_id`        CHAR(36) COMMENT '路线ID（自由跑为NULL）',
    `start_time`      DATETIME(3) NOT NULL COMMENT '开始时间',
    `end_time`        DATETIME(3) COMMENT '结束时间',
    `total_time`      INT COMMENT '总用时(秒)',
    `total_distance`  DECIMAL(10,2) COMMENT '总距离(m)',
    `avg_pace`        DECIMAL(6,2) COMMENT '平均配速(秒/km)',
    `best_pace`       DECIMAL(6,2) COMMENT '最佳配速',
    `avg_heart_rate`  SMALLINT COMMENT '平均心率',
    `max_heart_rate`  SMALLINT COMMENT '最大心率',
    `avg_cadence`     SMALLINT COMMENT '平均步频',
    `max_cadence`     SMALLINT COMMENT '最大步频',
    `avg_stride_length` DECIMAL(5,2) COMMENT '平均步幅(m)',
    `elevation_gain`  DECIMAL(10,2) DEFAULT 0 COMMENT '累计爬升(m)',
    `elevation_loss`  DECIMAL(10,2) DEFAULT 0 COMMENT '累计下降(m)',
    `calories`        INT COMMENT '卡路里',
    `weather`         VARCHAR(20) COMMENT '天气',
    `temperature`     SMALLINT COMMENT '气温(℃)',
    `device_type`     VARCHAR(50) COMMENT '设备型号',
    `gpx_file_url`    VARCHAR(500) COMMENT 'GPX文件OSS URL',
    `is_shared`       TINYINT(1) DEFAULT 0 COMMENT '是否分享',
    `share_count`     INT DEFAULT 0 COMMENT '分享次数',
    `like_count`      INT DEFAULT 0 COMMENT '点赞数',
    `created_at`      DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at`      DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_route` (`route_id`),
    INDEX `idx_start_time` (`start_time` DESC),
    INDEX `idx_user_time` (`user_id`, `start_time` DESC),
    CONSTRAINT `fk_runs_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_runs_route` FOREIGN KEY (`route_id`) REFERENCES `routes`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='跑步记录表';

-- ============================================================
-- 4. 跑步分段数据表 (run_splits)
-- ============================================================
CREATE TABLE IF NOT EXISTS `run_splits` (
    `id`              CHAR(36) PRIMARY KEY COMMENT 'UUID',
    `run_id`          CHAR(36) NOT NULL COMMENT '跑步记录ID',
    `split_index`     INT NOT NULL COMMENT '分段序号',
    `distance`        DECIMAL(10,2) NOT NULL COMMENT '本段距离(m)',
    `time`            INT NOT NULL COMMENT '本段用时(秒)',
    `pace`            DECIMAL(6,2) COMMENT '本段配速',
    `avg_heart_rate`  SMALLINT COMMENT '平均心率',
    `avg_cadence`     SMALLINT COMMENT '平均步频',
    `avg_stride_length` DECIMAL(5,2) COMMENT '平均步幅',
    `elevation_gain`  DECIMAL(10,2) DEFAULT 0,
    `elevation_loss`  DECIMAL(10,2) DEFAULT 0,
    `created_at`      DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE KEY `uk_run_split` (`run_id`, `split_index`),
    INDEX `idx_run` (`run_id`),
    CONSTRAINT `fk_splits_run` FOREIGN KEY (`run_id`) REFERENCES `runs`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='跑步分段数据表';

-- ============================================================
-- 5. 跑步秒级采样数据表 (run_samples) — RANGE 按月分区
-- ============================================================
CREATE TABLE IF NOT EXISTS `run_samples` (
    `run_id`            CHAR(36) NOT NULL COMMENT '跑步记录ID',
    `sample_time`       DATETIME(3) NOT NULL COMMENT '采样时间',
    `latitude`          DECIMAL(10,7) NOT NULL COMMENT '纬度',
    `longitude`         DECIMAL(10,7) NOT NULL COMMENT '经度',
    `altitude`          DECIMAL(10,2) COMMENT '海拔(m)',
    `pace`              DECIMAL(6,2) COMMENT '当前配速(秒/km)',
    `heart_rate`        SMALLINT COMMENT '心率',
    `cadence`           SMALLINT COMMENT '步频(spm)',
    `stride_length`     DECIMAL(5,2) COMMENT '步幅(m)',
    `distance_from_start` DECIMAL(10,2) DEFAULT 0 COMMENT '距起点距离(m)',
    PRIMARY KEY (`run_id`, `sample_time`),
    INDEX `idx_run_time` (`run_id`, `sample_time` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='跑步秒级采样数据表'
PARTITION BY RANGE COLUMNS(`sample_time`) (
    PARTITION `p202604` VALUES LESS THAN ('2026-05-01'),
    PARTITION `p202605` VALUES LESS THAN ('2026-06-01'),
    PARTITION `p202606` VALUES LESS THAN ('2026-07-01'),
    PARTITION `p202607` VALUES LESS THAN ('2026-08-01'),
    PARTITION `p202608` VALUES LESS THAN ('2026-09-01'),
    PARTITION `p202609` VALUES LESS THAN ('2026-10-01'),
    PARTITION `p202610` VALUES LESS THAN ('2026-11-01'),
    PARTITION `p202611` VALUES LESS THAN ('2026-12-01'),
    PARTITION `p202612` VALUES LESS THAN ('2027-01-01'),
    PARTITION `pmax` VALUES LESS THAN (MAXVALUE)
);

-- 自动创建新分区的 EVENT（每月1号凌晨执行）
DELIMITER //

CREATE EVENT IF NOT EXISTS `evt_add_monthly_partition`
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-05-01 02:00:00'
DO
BEGIN
    DECLARE next_month DATE;
    DECLARE partition_name VARCHAR(20);
    DECLARE less_than DATE;

    SET next_month = DATE_ADD(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 2 MONTH);
    SET partition_name = CONCAT('p', DATE_FORMAT(next_month, '%Y%m'));
    SET less_than = DATE_ADD(DATE_FORMAT(next_month, '%Y-%m-01'), INTERVAL 1 MONTH);

    SET @sql = CONCAT(
        'ALTER TABLE run_samples ADD PARTITION (',
        'PARTITION ', partition_name, ' VALUES LESS THAN (\'', less_than, '\')',
        ')'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END//

DELIMITER ;

-- SET GLOBAL event_scheduler = ON;
-- 注意：Event Scheduler 需要在 MySQL 启动参数中设置
-- 已在 docker-compose.yml 中通过 --event-scheduler=ON 启用

-- ============================================================
-- 6. 路线收藏表 (route_favorites)
-- ============================================================
CREATE TABLE IF NOT EXISTS `route_favorites` (
    `id`          CHAR(36) PRIMARY KEY COMMENT 'UUID',
    `user_id`     CHAR(36) NOT NULL COMMENT '用户ID',
    `route_id`    CHAR(36) NOT NULL COMMENT '路线ID',
    `tag`         VARCHAR(20) DEFAULT '收藏' COMMENT '想去跑/已跑过/收藏',
    `created_at`  DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE KEY `uk_user_route` (`user_id`, `route_id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_route` (`route_id`),
    CONSTRAINT `fk_fav_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fav_route` FOREIGN KEY (`route_id`) REFERENCES `routes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='路线收藏表';

-- ============================================================
-- 7. 挑战表 (challenges)
-- ============================================================
CREATE TABLE IF NOT EXISTS `challenges` (
    `id`                CHAR(36) PRIMARY KEY COMMENT 'UUID',
    `route_id`          CHAR(36) NOT NULL COMMENT '路线ID',
    `challenger_id`     CHAR(36) NOT NULL COMMENT '挑战者ID',
    `challenger_run_id` CHAR(36) COMMENT '挑战者跑步记录ID',
    `invitee_id`        CHAR(36) COMMENT '被挑战者ID（NULL表示自发陪跑）',
    `target_run_id`     CHAR(36) COMMENT '被挑战目标跑步记录ID（异步挑战）',
    `ghost_mode`        VARCHAR(20) DEFAULT 'real_replay' COMMENT 'real_replay/constant/rabbit/tortoise_hare/goal',
    `goal_metric`       VARCHAR(20) COMMENT 'pace/heart_rate/cadence/stride_length',
    `status`            VARCHAR(20) DEFAULT 'pending' COMMENT 'pending/accepted/running/completed/cancelled',
    `challenger_result` JSON COMMENT '挑战者结果',
    `invitee_result`    JSON COMMENT '被挑战者结果',
    `winner_id`         CHAR(36) COMMENT '获胜者ID',
    `created_at`        DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    `accepted_at`       DATETIME(3) COMMENT '接受时间',
    `started_at`        DATETIME(3) COMMENT '开始时间',
    `completed_at`      DATETIME(3) COMMENT '完成时间',
    `expires_at`        DATETIME(3) COMMENT '过期时间',
    INDEX `idx_challenger` (`challenger_id`),
    INDEX `idx_invitee` (`invitee_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_route` (`route_id`),
    INDEX `idx_expires` (`expires_at`),
    CONSTRAINT `fk_ch_route` FOREIGN KEY (`route_id`) REFERENCES `routes`(`id`),
    CONSTRAINT `fk_ch_challenger` FOREIGN KEY (`challenger_id`) REFERENCES `users`(`id`),
    CONSTRAINT `fk_ch_invitee` FOREIGN KEY (`invitee_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ch_winner` FOREIGN KEY (`winner_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='挑战表';

-- ============================================================
-- 8. 对比报告表 (comparisons)
-- ============================================================
CREATE TABLE IF NOT EXISTS `comparisons` (
    `id`            CHAR(36) PRIMARY KEY COMMENT 'UUID',
    `challenge_id`  CHAR(36) UNIQUE COMMENT '挑战ID',
    `run_a_id`      CHAR(36) NOT NULL COMMENT '跑步A',
    `run_b_id`      CHAR(36) NOT NULL COMMENT '跑步B',
    `overall_diff`  JSON NOT NULL COMMENT '综合差异',
    `splits_json`   JSON COMMENT '分段对比',
    `diagnosis_json` JSON COMMENT 'AI诊断建议',
    `created_at`    DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    INDEX `idx_challenge` (`challenge_id`),
    INDEX `idx_run_a` (`run_a_id`),
    INDEX `idx_run_b` (`run_b_id`),
    CONSTRAINT `fk_comp_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `challenges`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_comp_run_a` FOREIGN KEY (`run_a_id`) REFERENCES `runs`(`id`),
    CONSTRAINT `fk_comp_run_b` FOREIGN KEY (`run_b_id`) REFERENCES `runs`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='对比报告表';

-- ============================================================
-- 9. 好友关系表 (friendships)
-- ============================================================
CREATE TABLE IF NOT EXISTS `friendships` (
    `id`          CHAR(36) PRIMARY KEY COMMENT 'UUID',
    `user_id_a`   CHAR(36) NOT NULL COMMENT '用户A（较小UUID）',
    `user_id_b`   CHAR(36) NOT NULL COMMENT '用户B（较大UUID）',
    `status`      VARCHAR(20) DEFAULT 'pending' COMMENT 'pending/accepted/rejected',
    `created_at`  DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at`  DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    UNIQUE KEY `uk_friends` (`user_id_a`, `user_id_b`),
    INDEX `idx_user_a` (`user_id_a`),
    INDEX `idx_user_b` (`user_id_b`),
    CONSTRAINT `chk_user_order` CHECK (`user_id_a` < `user_id_b`),
    CONSTRAINT `fk_friend_a` FOREIGN KEY (`user_id_a`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_friend_b` FOREIGN KEY (`user_id_b`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='好友关系表';

-- ============================================================
-- 10. 排行榜快照表 (route_leaderboards)
-- ============================================================
CREATE TABLE IF NOT EXISTS `route_leaderboards` (
    `id`          CHAR(36) PRIMARY KEY COMMENT 'UUID',
    `route_id`    CHAR(36) NOT NULL COMMENT '路线ID',
    `user_id`     CHAR(36) NOT NULL COMMENT '用户ID',
    `run_id`      CHAR(36) NOT NULL COMMENT '最新跑步记录ID',
    `total_time`  INT NOT NULL COMMENT '总用时(秒)',
    `avg_pace`    DECIMAL(6,2) COMMENT '平均配速',
    `run_count`   INT NOT NULL DEFAULT 0 COMMENT '在此路线打卡次数',
    `recorded_at` DATETIME(3) NOT NULL COMMENT '记录时间',
    `created_at`  DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at`  DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    UNIQUE KEY `uk_route_user` (`route_id`, `user_id`),
    INDEX `idx_route_time` (`route_id`, `total_time`),
    INDEX `idx_user` (`user_id`),
    CONSTRAINT `fk_lb_route` FOREIGN KEY (`route_id`) REFERENCES `routes`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lb_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lb_run` FOREIGN KEY (`run_id`) REFERENCES `runs`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='路线排行榜快照';

SET FOREIGN_KEY_CHECKS = 1;
