-- 添加 is_vip 字段到 users 表
ALTER TABLE users ADD COLUMN is_vip TINYINT(1) NOT NULL DEFAULT 0;