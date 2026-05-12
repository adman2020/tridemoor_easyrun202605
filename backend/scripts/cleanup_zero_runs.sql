-- ================================================================================
-- 清理 0.0km 废记录
--
-- 闪退导致 startRun() 创建了记录但 GPS 还没跑起来就断了，
-- 这些记录 total_distance = 0.00 或 NULL，没有任何 GPS 采样点。
-- 关联表因 DELETE CASCADE 自动清理（run_splits / run_bookmarks / 排行榜等）。
--
-- 使用方式：
--   mysql -u root -p stridemoor < scripts/cleanup_zero_runs.sql
--   或手动执行：
--   source scripts/cleanup_zero_runs.sql;
-- ================================================================================

SET @deleted_count = 0;

-- 找出所有 0.0km 废记录
SELECT COUNT(*) AS '待清理记录数'
FROM runs
WHERE (total_distance IS NULL OR total_distance = 0)
  AND total_time IS NULL;

-- 开始清理
DELETE FROM runs
WHERE (total_distance IS NULL OR total_distance = 0)
  AND total_time IS NULL;

SELECT ROW_COUNT() AS '已清理记录数';
