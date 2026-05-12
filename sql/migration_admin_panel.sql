-- StrideMoor 管理端数据迁移脚本
-- 为现有业务表添加审核和软删除字段
-- 所有新字段都有默认值，保证向后兼容

-- ==================== posts 表 ====================
ALTER TABLE posts
  ADD COLUMN review_status TINYINT NOT NULL DEFAULT 0 COMMENT '审核状态 0=待审核 1=已通过 2=已拒绝',
  ADD COLUMN is_hidden     TINYINT NOT NULL DEFAULT 0 COMMENT '是否隐藏 0=显示 1=隐藏',
  ADD COLUMN deleted_at    DATETIME(3) DEFAULT NULL COMMENT '软删除时间',
  ADD COLUMN reviewed_by   CHAR(36) DEFAULT NULL COMMENT '审核人(管理员ID)',
  ADD COLUMN reviewed_at   DATETIME(3) DEFAULT NULL COMMENT '审核时间';
CREATE INDEX idx_post_review ON posts(review_status);
CREATE INDEX idx_post_hidden ON posts(is_hidden);
CREATE INDEX idx_post_deleted ON posts(deleted_at);

-- ==================== routes 表 ====================
ALTER TABLE routes
  ADD COLUMN review_status TINYINT NOT NULL DEFAULT 1 COMMENT '审核状态 1=已通过(默认) 0=待审核 2=已拒绝',
  ADD COLUMN deleted_at    DATETIME(3) DEFAULT NULL COMMENT '软删除时间',
  ADD COLUMN reviewed_by   CHAR(36) DEFAULT NULL COMMENT '审核人',
  ADD COLUMN reviewed_at   DATETIME(3) DEFAULT NULL COMMENT '审核时间';
CREATE INDEX idx_route_review ON routes(review_status);
CREATE INDEX idx_route_deleted ON routes(deleted_at);

-- ==================== runs 表 ====================
ALTER TABLE runs
  ADD COLUMN deleted_at  DATETIME(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX idx_run_deleted ON runs(deleted_at);

-- ==================== 更新现有数据 ====================
-- 确保存量数据全部标记为已通过
UPDATE posts  SET review_status = 1 WHERE review_status = 0;
UPDATE routes SET review_status = 1 WHERE review_status = 0;
