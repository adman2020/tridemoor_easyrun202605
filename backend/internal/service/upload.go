package service

import (
	"context"
	"errors"
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"stridemoor-api/internal/repository"
	"stridemoor-api/pkg/database"
)

type UploadService struct {
	storage  *database.MinIOClient
	userRepo *repository.UserRepository
}

func NewUploadService(storage *database.MinIOClient, userRepo *repository.UserRepository) *UploadService {
	return &UploadService{
		storage:  storage,
		userRepo: userRepo,
	}
}

const (
	maxAvatarSize = 5 * 1024 * 1024  // 5MB
	maxGPXSize    = 10 * 1024 * 1024 // 10MB
)

// UploadAvatar 上传头像
func (s *UploadService) UploadAvatar(ctx context.Context, userID string, file multipart.File, header *multipart.FileHeader) (string, error) {
	if header.Size > maxAvatarSize {
		return "", errors.New("头像过大，最大支持 5MB")
	}

	ext := strings.ToLower(filepath.Ext(header.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
		return "", errors.New("仅支持 jpg/png/webp 格式")
	}

	objectName := fmt.Sprintf("avatars/%s/%d%s", userID, time.Now().Unix(), ext)
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "image/jpeg"
	}

	url, err := s.storage.Upload(ctx, objectName, file, header.Size, contentType)
	if err != nil {
		return "", err
	}

	// 更新用户头像 URL
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return "", err
	}
	if user == nil {
		return "", errors.New("user not found")
	}
	user.Avatar = &url
	if err := s.userRepo.Update(ctx, user); err != nil {
		return "", err
	}

	return url, nil
}

// UploadGPX 上传 GPX 轨迹文件
func (s *UploadService) UploadGPX(ctx context.Context, userID string, file multipart.File, header *multipart.FileHeader) (string, error) {
	if header.Size > maxGPXSize {
		return "", errors.New("GPX 文件过大，最大支持 10MB")
	}

	ext := strings.ToLower(filepath.Ext(header.Filename))
	if ext != ".gpx" {
		return "", errors.New("仅支持 .gpx 格式")
	}

	objectName := fmt.Sprintf("gpx/%s/%d%s", userID, time.Now().Unix(), ext)
	url, err := s.storage.Upload(ctx, objectName, file, header.Size, "application/gpx+xml")
	if err != nil {
		return "", err
	}

	return url, nil
}
