package repository

import (
	"context"
	"errors"
	"sort"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

type FriendshipRepository struct {
	db *gorm.DB
}

func NewFriendshipRepository(db *gorm.DB) *FriendshipRepository {
	return &FriendshipRepository{db: db}
}

func (r *FriendshipRepository) Create(ctx context.Context, friendship *model.Friendship) error {
	return r.db.WithContext(ctx).Create(friendship).Error
}

func (r *FriendshipRepository) FindByUsers(ctx context.Context, userA, userB string) (*model.Friendship, error) {
	ids := []string{userA, userB}
	sort.Strings(ids)

	var friendship model.Friendship
	err := r.db.WithContext(ctx).Where("user_id_a = ? AND user_id_b = ?", ids[0], ids[1]).First(&friendship).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &friendship, nil
}

func (r *FriendshipRepository) FindByID(ctx context.Context, id string) (*model.Friendship, error) {
	var friendship model.Friendship
	err := r.db.WithContext(ctx).Preload("UserA").Preload("UserB").First(&friendship, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &friendship, nil
}

func (r *FriendshipRepository) UpdateStatus(ctx context.Context, id, status string) error {
	return r.db.WithContext(ctx).Model(&model.Friendship{}).Where("id = ?", id).Update("status", status).Error
}

func (r *FriendshipRepository) Delete(ctx context.Context, id string) error {
	return r.db.WithContext(ctx).Delete(&model.Friendship{}, "id = ?", id).Error
}

func (r *FriendshipRepository) ListByUserID(ctx context.Context, userID string, page, pageSize int) ([]model.Friendship, int64, error) {
	var friendships []model.Friendship
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Friendship{}).
		Where("(user_id_a = ? OR user_id_b = ?) AND status = ?", userID, userID, "accepted")

	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err := db.Preload("UserA").Preload("UserB").
		Order("updated_at DESC").Offset(offset).Limit(pageSize).
		Find(&friendships).Error
	return friendships, total, err
}

func (r *FriendshipRepository) ListPendingByUser(ctx context.Context, userID string, page, pageSize int) ([]model.Friendship, int64, error) {
	var friendships []model.Friendship
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Friendship{}).
		Where("(user_id_a = ? OR user_id_b = ?) AND status = ?", userID, userID, "pending")

	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err := db.Preload("UserA").Preload("UserB").
		Order("created_at DESC").Offset(offset).Limit(pageSize).
		Find(&friendships).Error
	return friendships, total, err
}
