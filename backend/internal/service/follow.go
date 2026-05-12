package service

import (
	"context"
	"errors"

	"stridemoor-api/internal/repository"
)

type FollowService struct {
	followRepo *repository.FollowRepository
	userRepo   *repository.UserRepository
}

func NewFollowService(followRepo *repository.FollowRepository, userRepo *repository.UserRepository) *FollowService {
	return &FollowService{
		followRepo: followRepo,
		userRepo:   userRepo,
	}
}

// FollowUser 关注用户
func (s *FollowService) FollowUser(ctx context.Context, followerID, followingID string) error {
	// 不能关注自己
	if followerID == followingID {
		return errors.New("cannot follow yourself")
	}
	// 检查被关注用户是否存在
	user, err := s.userRepo.FindByID(ctx, followingID)
	if err != nil {
		return err
	}
	if user == nil {
		return errors.New("user not found")
	}
	return s.followRepo.Follow(ctx, followerID, followingID)
}

// UnfollowUser 取消关注
func (s *FollowService) UnfollowUser(ctx context.Context, followerID, followingID string) error {
	return s.followRepo.Unfollow(ctx, followerID, followingID)
}

// IsFollowing 判断是否已关注
func (s *FollowService) IsFollowing(ctx context.Context, followerID, followingID string) (bool, error) {
	return s.followRepo.IsFollowing(ctx, followerID, followingID)
}

type FollowUserInfo struct {
	FollowerID  string  `json:"follower_id"`
	FollowingID string  `json:"following_id"`
	Nickname    string  `json:"nickname"`
	Avatar      *string `json:"avatar,omitempty"`
	Phone       string  `json:"phone"`
	CreatedAt   string  `json:"created_at"`
}

// ListFollowings 获取关注列表（含用户信息）
func (s *FollowService) ListFollowings(ctx context.Context, followerID string, page, pageSize int) ([]FollowUserInfo, int64, error) {
	follows, total, err := s.followRepo.ListFollowings(ctx, followerID, page, pageSize)
	if err != nil {
		return nil, 0, err
	}
	infoList := make([]FollowUserInfo, 0, len(follows))
	for _, f := range follows {
		user, _ := s.userRepo.FindByID(ctx, f.FollowingID)
		nickname := "未知跑友"
		if user != nil {
			nickname = user.Nickname
		}
		infoList = append(infoList, FollowUserInfo{
			FollowerID:  f.FollowerID,
			FollowingID: f.FollowingID,
			Nickname:    nickname,
			Avatar:      user.Avatar,
			Phone:       user.Phone,
			CreatedAt:   f.CreatedAt.Format("2006-01-02 15:04:05"),
		})
	}
	return infoList, total, nil
}

// ListFollowers 获取粉丝列表（含用户信息）
func (s *FollowService) ListFollowers(ctx context.Context, followingID string, page, pageSize int) ([]FollowUserInfo, int64, error) {
	follows, total, err := s.followRepo.ListFollowers(ctx, followingID, page, pageSize)
	if err != nil {
		return nil, 0, err
	}
	infoList := make([]FollowUserInfo, 0, len(follows))
	for _, f := range follows {
		user, _ := s.userRepo.FindByID(ctx, f.FollowerID)
		nickname := "未知跑友"
		if user != nil {
			nickname = user.Nickname
		}
		infoList = append(infoList, FollowUserInfo{
			FollowerID:  f.FollowerID,
			FollowingID: f.FollowingID,
			Nickname:    nickname,
			Avatar:      user.Avatar,
			Phone:       user.Phone,
			CreatedAt:   f.CreatedAt.Format("2006-01-02 15:04:05"),
		})
	}
	return infoList, total, nil
}
