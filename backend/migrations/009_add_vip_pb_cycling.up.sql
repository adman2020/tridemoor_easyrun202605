-- ============================================================
-- 驰陌 StrideMoor 用户表升级 v9
-- 安全增量（纯新增列，无重复）:
--   - email + weight 改 NOT NULL + UNIQUE
--   - VIP tier/expiry/features
--   - PB 记录: 5k / 10k / 半马
--   - 骑境预留: 13 column
--
-- 前提: 002_add_realm_fields / 003_add_total_calories / 008_add_is_vip 已执行
--       且 GORM AutoMigrate 已创建 email 列
-- ============================================================

-- 1. email 改为 NOT NULL + UNIQUE（列由 GORM AutoMigrate 创建）
UPDATE users SET email = CONCAT('user_', phone, '@stridemoor.app') WHERE email IS NULL OR email = '';
ALTER TABLE users MODIFY COLUMN `email` VARCHAR(100) NOT NULL COMMENT '邮箱';

-- 清理重复邮箱后建 UNIQUE 索引
DELETE t1 FROM users t1 INNER JOIN users t2 WHERE t1.id > t2.id AND t1.email = t2.email;
ALTER TABLE users ADD UNIQUE INDEX `idx_email` (`email`);

-- 2. weight 改为 NOT NULL（001_init 定义为 SMALLINT，GORM 已改为 DECIMAL）
UPDATE users SET weight = 60 WHERE weight IS NULL OR weight = 0;
ALTER TABLE users MODIFY COLUMN `weight` DECIMAL(5,2) NOT NULL DEFAULT 60.0 COMMENT '体重(kg)';

-- 3. 跑步 PB 记录（纯新增）
ALTER TABLE users ADD COLUMN `best_5k_time` INT DEFAULT NULL COMMENT '5km PB(秒)' AFTER `post_count`;
ALTER TABLE users ADD COLUMN `best_10k_time` INT DEFAULT NULL COMMENT '10km PB(秒)' AFTER `best_5k_time`;
ALTER TABLE users ADD COLUMN `best_half_marathon_time` INT DEFAULT NULL COMMENT '半马 PB(秒)' AFTER `best_10k_time`;

-- 4. VIP 体系扩展（is_vip 已由 008_add_is_vip 添加）
ALTER TABLE users ADD COLUMN `vip_tier` TINYINT NOT NULL DEFAULT 0 COMMENT '0=非会员 1=标准 2=Pro 3=Ultra' AFTER `is_vip`;
ALTER TABLE users ADD COLUMN `vip_expires_at` DATETIME(3) DEFAULT NULL COMMENT 'VIP到期时间' AFTER `vip_tier`;
ALTER TABLE users ADD COLUMN `vip_features` JSON COMMENT '已解锁功能列表' AFTER `vip_expires_at`;

-- 5. 骑境系统预留（13列，纯新增）
ALTER TABLE users ADD COLUMN `cycling_realm` TINYINT NOT NULL DEFAULT 0 COMMENT '骑境索引 0~12' AFTER `vip_features`;
ALTER TABLE users ADD COLUMN `cycling_realm_badges` JSON COMMENT '骑行已获勋章列表' AFTER `cycling_realm`;
ALTER TABLE users ADD COLUMN `cycling_best_20k_time` INT DEFAULT NULL COMMENT '20km PB(秒)' AFTER `cycling_realm_badges`;
ALTER TABLE users ADD COLUMN `cycling_best_40k_time` INT DEFAULT NULL COMMENT '40km PB(秒)' AFTER `cycling_best_20k_time`;
ALTER TABLE users ADD COLUMN `cycling_best_80k_time` INT DEFAULT NULL COMMENT '80km PB(秒)' AFTER `cycling_best_40k_time`;
ALTER TABLE users ADD COLUMN `cycling_best_100k_time` INT DEFAULT NULL COMMENT '百公里计时(秒)' AFTER `cycling_best_80k_time`;
ALTER TABLE users ADD COLUMN `cycling_best_160k_time` INT DEFAULT NULL COMMENT '160km PB(秒)' AFTER `cycling_best_100k_time`;
ALTER TABLE users ADD COLUMN `cycling_best_speed` DECIMAL(6,2) DEFAULT NULL COMMENT '最佳均速(km/h)' AFTER `cycling_best_160k_time`;
ALTER TABLE users ADD COLUMN `cycling_best_distance` DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '最佳单次骑行距离(km)' AFTER `cycling_best_speed`;
ALTER TABLE users ADD COLUMN `cycling_companions` INT NOT NULL DEFAULT 0 COMMENT '伴骑次数' AFTER `cycling_best_distance`;
ALTER TABLE users ADD COLUMN `cycling_challenges_won` INT NOT NULL DEFAULT 0 COMMENT '挑战骑胜利次数' AFTER `cycling_companions`;
ALTER TABLE users ADD COLUMN `cycling_dual_badges` JSON COMMENT '双修成就列表' AFTER `cycling_challenges_won`;
ALTER TABLE users ADD COLUMN `cycling_total_distance` DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '累计骑行距离(km)' AFTER `cycling_dual_badges`;
