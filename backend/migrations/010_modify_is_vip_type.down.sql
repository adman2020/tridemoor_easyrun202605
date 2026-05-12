-- ============================================================
-- 回滚：is_vip 改回 TINYINT(1)
-- ============================================================
ALTER TABLE users MODIFY COLUMN is_vip TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0=非VIP 1-5=VIP等级';
UPDATE users SET is_vip = LEAST(is_vip, 1);
