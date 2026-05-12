-- 跑境系统：为用户表添加境界相关字段
ALTER TABLE `users`
    ADD COLUMN `realm`             TINYINT  NOT NULL DEFAULT 0  COMMENT '当前境界索引 0=炼气 1=筑基 2=结丹 3=元婴 4=化神 5=练虚 6=合体 7=大乘 8=真仙 9=金仙 10=太乙 11=大罗 12=道祖' AFTER `settings`,
    ADD COLUMN `realm_badges`      JSON     NOT NULL DEFAULT ('[]') COMMENT '已获取勋章列表 JSON: ["气","筑",...]' AFTER `realm`,
    ADD COLUMN `companion_runs`    INT      NOT NULL DEFAULT 0  COMMENT '已完成伴跑次数' AFTER `realm_badges`,
    ADD COLUMN `challenges_won`    INT      NOT NULL DEFAULT 0  COMMENT '挑战成功次数' AFTER `companion_runs`,
    ADD COLUMN `best_marathon_time` INT     NOT NULL DEFAULT 0  COMMENT '最佳全马成绩(秒)' AFTER `challenges_won`,
    ADD COLUMN `post_count`        INT      NOT NULL DEFAULT 0  COMMENT '已发动态数' AFTER `best_marathon_time`;
