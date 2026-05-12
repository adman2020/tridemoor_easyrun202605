-- ============================================================
-- 驰陌 StrideMoor is_vip 字段升级
-- 改 is_vip 从 TINYINT(1) 为 TINYINT，允许存储 0-5
-- ============================================================

-- 1. 修改字段类型
ALTER TABLE users MODIFY COLUMN is_vip TINYINT NOT NULL DEFAULT 0 COMMENT '0=非VIP 1-5=VIP等级';

-- 2. 全量设为最高VIP（测试用）
UPDATE users SET is_vip = 5;
