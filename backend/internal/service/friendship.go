package service

import (
	"context"
	"errors"
	"sort"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"

	"github.com/google/uuid"
)

type FriendshipService struct {
	friendRepo *repository.FriendshipRepository
	userRepo   *repository.UserRepository
}

func NewFriendshipService(friendRepo *repository.FriendshipRepository, userRepo *repository.UserRepository) *FriendshipService {
	return &FriendshipService{
		friendRepo: friendRepo,
		userRepo:   userRepo,
	}
}

// SendFriendRequest 发送好友申请
func (s *FriendshipService) SendFriendRequest(ctx context.Context, fromUserID, toUserID string) error {
	if fromUserID == toUserID {
		return errors.New("cannot add yourself")
	}

	// 检查目标用户是否存在
	target, err := s.userRepo.FindByID(ctx, toUserID)
	if err != nil {
		return err
	}
	if target == nil {
		return errors.New("user not found")
	}

	// 检查是否已有关系
	existing, err := s.friendRepo.FindByUsers(ctx, fromUserID, toUserID)
	if err != nil {
		return err
	}
	if existing != nil {
		if existing.Status == "accepted" {
			return errors.New("already friends")
		}
		return errors.New("request already pending")
	}

	ids := []string{fromUserID, toUserID}
	sort.Strings(ids)

	friendship := &model.Friendship{
		ID:      uuid.New().String(),
		UserIDA: ids[0],
		UserIDB: ids[1],
		Status:  "pending",
	}
	return s.friendRepo.Create(ctx, friendship)
}

// AcceptFriendRequest 接受好友申请
func (s *FriendshipService) AcceptFriendRequest(ctx context.Context, requestID, userID string) error {
	friendship, err := s.friendRepo.FindByID(ctx, requestID)
	if err != nil {
		return err
	}
	if friendship == nil {
		return errors.New("request not found")
	}
	if friendship.Status != "pending" {
		return errors.New("request already processed")
	}
	// 验证操作人是否为被申请者
	if friendship.UserIDA != userID && friendship.UserIDB != userID {
		return errors.New("permission denied")
	}
	return s.friendRepo.UpdateStatus(ctx, requestID, "accepted")
}

// RejectFriendRequest 拒绝好友申请
func (s *FriendshipService) RejectFriendRequest(ctx context.Context, requestID, userID string) error {
	friendship, err := s.friendRepo.FindByID(ctx, requestID)
	if err != nil {
		return err
	}
	if friendship == nil {
		return errors.New("request not found")
	}
	if friendship.Status != "pending" {
		return errors.New("request already processed")
	}
	if friendship.UserIDA != userID && friendship.UserIDB != userID {
		return errors.New("permission denied")
	}
	return s.friendRepo.Delete(ctx, requestID)
}

// ListFriends 好友列表
func (s *FriendshipService) ListFriends(ctx context.Context, userID string, page, pageSize int) ([]model.Friendship, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}
	return s.friendRepo.ListByUserID(ctx, userID, page, pageSize)
}

// ListPendingRequests 待处理的好友申请列表
func (s *FriendshipService) ListPendingRequests(ctx context.Context, userID string, page, pageSize int) ([]model.Friendship, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}
	return s.friendRepo.ListPendingByUser(ctx, userID, page, pageSize)
}

// RemoveFriend 删除好友
func (s *FriendshipService) RemoveFriend(ctx context.Context, friendID, userID string) error {
	friendship, err := s.friendRepo.FindByID(ctx, friendID)
	if err != nil {
		return err
	}
	if friendship == nil {
		return errors.New("friendship not found")
	}
	if friendship.Status != "accepted" {
		return errors.New("not friends")
	}
	if friendship.UserIDA != userID && friendship.UserIDB != userID {
		return errors.New("permission denied")
	}
	return s.friendRepo.Delete(ctx, friendID)
}
