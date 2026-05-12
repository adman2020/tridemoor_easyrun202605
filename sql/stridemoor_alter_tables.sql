-- ALTER existing tables in stridemoor database
ALTER TABLE `posts` 
  ADD COLUMN `review_status` TINYINT DEFAULT 0 COMMENT '审核状态: 0待审 1通过 2拒绝' AFTER `content`,
  ADD COLUMN `is_hidden` TINYINT(1) DEFAULT 0 COMMENT '管理员隐藏: 0正常 1隐藏' AFTER `review_status`,
  ADD INDEX `idx_review_status` (`review_status`);

ALTER TABLE `runs`    ADD COLUMN `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除时间' AFTER `updated_at`;
ALTER TABLE `routes`  ADD COLUMN `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除时间' AFTER `updated_at`;
ALTER TABLE `posts`   ADD COLUMN `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除时间' AFTER `is_hidden`;
ALTER TABLE `users`   ADD COLUMN `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除时间' AFTER `updated_at`;
ALTER TABLE `users`   ADD COLUMN `is_banned` TINYINT(1) DEFAULT 0 COMMENT '是否禁用' AFTER `deleted_at`;
