package repository

import (
	"context"
	"errors"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

type FollowRepository struct {
	db *gorm.DB
}

func NewFollowRepository(db *gorm.DB) *FollowRepository {
	return &FollowRepository{db: db}
}

// Follow 关注用户
func (r *FollowRepository) Follow(ctx context.Context, followerID, followingID string) error {
	// 幂等：先检查是否已关注
	var existing model.Follow
	err := r.db.WithContext(ctx).
		Where("follower_id = ? AND following_id = ?", followerID, followingID).
		First(&existing).Error
	if err == nil {
		return nil // 已关注，直接返回
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	follow := &model.Follow{
		FollowerID:  followerID,
		FollowingID: followingID,
	}
	return r.db.WithContext(ctx).Create(follow).Error
}

// Unfollow 取消关注
func (r *FollowRepository) Unfollow(ctx context.Context, followerID, followingID string) error {
	return r.db.WithContext(ctx).
		Where("follower_id = ? AND following_id = ?", followerID, followingID).
		Delete(&model.Follow{}).Error
}

// IsFollowing 判断是否已关注
func (r *FollowRepository) IsFollowing(ctx context.Context, followerID, followingID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Follow{}).
		Where("follower_id = ? AND following_id = ?", followerID, followingID).
		Count(&count).Error
	return count > 0, err
}

// ListFollowings 获取关注列表（我关注了谁）
func (r *FollowRepository) ListFollowings(ctx context.Context, followerID string, page, pageSize int) ([]model.Follow, int64, error) {
	var follows []model.Follow
	var total int64
	db := r.db.WithContext(ctx).Model(&model.Follow{}).Where("follower_id = ?", followerID)
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * pageSize
	err := db.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&follows).Error
	return follows, total, err
}

// ListFollowers 获取粉丝列表（谁关注了我）
func (r *FollowRepository) ListFollowers(ctx context.Context, followingID string, page, pageSize int) ([]model.Follow, int64, error) {
	var follows []model.Follow
	var total int64
	db := r.db.WithContext(ctx).Model(&model.Follow{}).Where("following_id = ?", followingID)
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * pageSize
	err := db.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&follows).Error
	return follows, total, err
}

// CountFollowers 统计被关注数（粉丝数）
func (r *FollowRepository) CountFollowers(ctx context.Context, followingID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.Follow{}).Where("following_id = ?", followingID).Count(&count).Error
	return count, err
}
