-- 003_add_total_calories.up.sql
-- 1. 新增 total_calories 字段
ALTER TABLE users ADD COLUMN total_calories INT NOT NULL DEFAULT 0 COMMENT '累计消耗卡路里(千卡)' AFTER total_time;

-- 2. 回填所有用户的累积统计数据（从 runs 表计算）
UPDATE users u
SET
    total_distance = COALESCE((
        SELECT ROUND(SUM(COALESCE(total_distance, 0)), 2)
        FROM runs
        WHERE user_id = u.id AND total_distance IS NOT NULL AND total_distance > 0
    ), 0),
    total_runs = COALESCE((
        SELECT COUNT(*)
        FROM runs
        WHERE user_id = u.id AND total_distance IS NOT NULL AND total_distance > 0
    ), 0),
    total_time = COALESCE((
        SELECT SUM(COALESCE(total_time, 0))
        FROM runs
        WHERE user_id = u.id AND total_time IS NOT NULL AND total_time > 0
    ), 0),
    total_calories = COALESCE((
        SELECT SUM(COALESCE(calories, 0))
        FROM runs
        WHERE user_id = u.id
    ), 0);
