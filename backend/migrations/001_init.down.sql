-- ============================================================
-- 驰陌 StrideMoor 数据库回滚脚本
-- 删除所有表（按依赖顺序逆序删除）
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `route_leaderboards`;
DROP TABLE IF EXISTS `friendships`;
DROP TABLE IF EXISTS `comparisons`;
DROP TABLE IF EXISTS `challenges`;
DROP TABLE IF EXISTS `route_favorites`;
DROP TABLE IF EXISTS `run_samples`;
DROP TABLE IF EXISTS `run_splits`;
DROP TABLE IF EXISTS `runs`;
DROP TABLE IF EXISTS `routes`;
DROP TABLE IF EXISTS `users`;

DROP EVENT IF EXISTS `evt_add_monthly_partition`;

SET FOREIGN_KEY_CHECKS = 1;
