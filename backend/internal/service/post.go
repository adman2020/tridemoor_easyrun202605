package service

import (
	"context"
	"errors"
	"time"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"

	"github.com/google/uuid"
)

type PostService struct {
	postRepo     *repository.PostRepository
	paojingSvc   *PaojingService
}

func NewPostService(postRepo *repository.PostRepository) *PostService {
	return &PostService{postRepo: postRepo}
}

// SetPaojingService 设置跑境服务引用（避免循环依赖）
func (s *PostService) SetPaojingService(ps *PaojingService) {
	s.paojingSvc = ps
}

// ==================== Post ====================

type CreatePostRequest struct {
	Content string  `json:"content" binding:"required"`
	RunID   *string `json:"run_id"`
	RouteID *string `json:"route_id"`
}

func (s *PostService) CreatePost(ctx context.Context, userID string, req *CreatePostRequest) (*model.Post, error) {
	// 每日限流：跑友每人每天最多发 2 条动态，防止刷屏
	const dailyLimit = 2
	var todayCount int64
	if err := s.postRepo.CountTodayByUser(ctx, userID, &todayCount); err != nil {
		return nil, err
	}
	if todayCount >= dailyLimit {
		return nil, errors.New("每日最多发布 2 条动态，请明天再试试")
	}

	post := &model.Post{
		ID:      uuid.New().String(),
		UserID:  userID,
		RunID:   req.RunID,
		RouteID: req.RouteID,
		Content: req.Content,
	}

	if err := s.postRepo.Create(ctx, post); err != nil {
		return nil, err
	}

	// 发动态后检查跑境晋升
	if s.paojingSvc != nil {
		s.paojingSvc.CheckAndUpgradeAfterPost(ctx, userID)
	}

	return post, nil
}

func (s *PostService) ListPosts(ctx context.Context, page, pageSize int) ([]model.Post, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 10
	}
	return s.postRepo.List(ctx, page, pageSize)
}

func (s *PostService) GetPostDetail(ctx context.Context, postID string) (*model.Post, error) {
	return s.postRepo.FindByID(ctx, postID)
}

// ==================== Comment ====================

type CreateCommentRequest struct {
	Content string `json:"content" binding:"required"`
}

func (s *PostService) CreateComment(ctx context.Context, postID string, userID string, req *CreateCommentRequest) error {
	post, err := s.postRepo.FindByID(ctx, postID)
	if err != nil {
		return err
	}
	if post == nil {
		return errors.New("post not found")
	}

	comment := &model.PostComment{
		ID:      uuid.New().String(),
		PostID:  postID,
		UserID:  userID,
		Content: req.Content,
	}

	return s.postRepo.CreateComment(ctx, comment)
}

func (s *PostService) ListComments(ctx context.Context, postID string, page, pageSize int) ([]model.PostComment, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 10
	}
	return s.postRepo.ListCommentsByPostID(ctx, postID, page, pageSize)
}

// ==================== Like ====================

func (s *PostService) LikePost(ctx context.Context, postID string, userID string) error {
	post, err := s.postRepo.FindByID(ctx, postID)
	if err != nil {
		return err
	}
	if post == nil {
		return errors.New("post not found")
	}

	liked, err := s.postRepo.IsLiked(ctx, postID, userID)
	if err != nil {
		return err
	}
	if liked {
		return errors.New("already liked")
	}

	like := &model.PostLike{
		PostID:    postID,
		UserID:    userID,
		CreatedAt: time.Now(),
	}

	return s.postRepo.CreateLike(ctx, like)
}

func (s *PostService) UnlikePost(ctx context.Context, postID string, userID string) error {
	return s.postRepo.DeleteLike(ctx, postID, userID)
}
