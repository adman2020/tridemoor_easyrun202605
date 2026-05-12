-- 009 回滚: 移除 v9 新增列
ALTER TABLE users DROP COLUMN `cycling_total_distance`;
ALTER TABLE users DROP COLUMN `cycling_dual_badges`;
ALTER TABLE users DROP COLUMN `cycling_challenges_won`;
ALTER TABLE users DROP COLUMN `cycling_companions`;
ALTER TABLE users DROP COLUMN `cycling_best_distance`;
ALTER TABLE users DROP COLUMN `cycling_best_speed`;
ALTER TABLE users DROP COLUMN `cycling_best_160k_time`;
ALTER TABLE users DROP COLUMN `cycling_best_100k_time`;
ALTER TABLE users DROP COLUMN `cycling_best_80k_time`;
ALTER TABLE users DROP COLUMN `cycling_best_40k_time`;
ALTER TABLE users DROP COLUMN `cycling_best_20k_time`;
ALTER TABLE users DROP COLUMN `cycling_realm_badges`;
ALTER TABLE users DROP COLUMN `cycling_realm`;
ALTER TABLE users DROP COLUMN `vip_features`;
ALTER TABLE users DROP COLUMN `vip_expires_at`;
ALTER TABLE users DROP COLUMN `vip_tier`;
ALTER TABLE users DROP COLUMN `best_half_marathon_time`;
ALTER TABLE users DROP COLUMN `best_10k_time`;
ALTER TABLE users DROP COLUMN `best_5k_time`;
-- weight 和 email 改回原状
ALTER TABLE users MODIFY COLUMN `weight` SMALLINT COMMENT '体重(kg)';
ALTER TABLE users DROP INDEX `idx_email`;
ALTER TABLE users MODIFY COLUMN `email` VARCHAR(100) DEFAULT NULL COMMENT '邮箱';
