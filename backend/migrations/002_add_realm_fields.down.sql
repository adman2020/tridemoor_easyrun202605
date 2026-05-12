-- 回滚：移除跑境字段
ALTER TABLE `users`
    DROP COLUMN `post_count`,
    DROP COLUMN `best_marathon_time`,
    DROP COLUMN `challenges_won`,
    DROP COLUMN `companion_runs`,
    DROP COLUMN `realm_badges`,
    DROP COLUMN `realm`;
