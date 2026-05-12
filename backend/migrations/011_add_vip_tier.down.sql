-- 回滚：移除 vip_tier 字段
ALTER TABLE users DROP COLUMN vip_tier;
