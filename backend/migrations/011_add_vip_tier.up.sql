-- 添加 VIP 子等级字段
ALTER TABLE users ADD COLUMN vip_tier TINYINT NOT NULL DEFAULT 5 COMMENT 'VIP子等级：1=白银 2=黄金 3=钻石 4=星耀 5=王者' AFTER is_vip;

-- 所有现有 VIP 用户默认子等级为最高级（王者=5）
UPDATE users SET vip_tier = 5 WHERE is_vip > 0;
