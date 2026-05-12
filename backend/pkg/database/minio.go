package database

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

// MinIOConfig 存储配置
// ServerURL 是服务端公网/内网地址，仅本地模式用于拼接完整 URL
type MinIOConfig struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	Bucket    string
	UseSSL    bool
	ServerURL string
}

// MinIOClient 本地文件存储客户端（MinIO 占位实现）
type MinIOClient struct {
	basePath  string
	baseURL   string
	serverURL string
}

// NewMinIOClient 创建存储客户端（本地模式）
func NewMinIOClient(cfg *MinIOConfig) (*MinIOClient, error) {
	basePath := "./uploads"
	for _, dir := range []string{"avatars", "gpx"} {
		path := filepath.Join(basePath, dir)
		if err := os.MkdirAll(path, 0755); err != nil {
			return nil, fmt.Errorf("创建目录失败 %s: %w", path, err)
		}
	}
	return &MinIOClient{
		basePath:  basePath,
		baseURL:   "/static",
		serverURL: cfg.ServerURL,
	}, nil
}

// Upload 上传文件到本地，返回访问 URL
func (c *MinIOClient) Upload(ctx context.Context, objectName string, reader io.Reader, size int64, contentType string) (string, error) {
	fullPath := filepath.Join(c.basePath, objectName)

	// 确保子目录存在
	dir := filepath.Dir(fullPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return "", fmt.Errorf("创建目录失败: %w", err)
	}

	file, err := os.Create(fullPath)
	if err != nil {
		return "", fmt.Errorf("创建文件失败: %w", err)
	}
	defer file.Close()

	if _, err := io.Copy(file, reader); err != nil {
		return "", fmt.Errorf("写入文件失败: %w", err)
	}

	url := fmt.Sprintf("%s/%s", c.baseURL, objectName)
	if c.serverURL != "" {
		url = fmt.Sprintf("%s%s", c.serverURL, url)
	}
	return url, nil
}

// Delete 删除本地文件
func (c *MinIOClient) Delete(ctx context.Context, objectName string) error {
	fullPath := filepath.Join(c.basePath, objectName)
	return os.Remove(fullPath)
}

// BasePath 返回本地存储根路径（用于静态文件服务）
func (c *MinIOClient) BasePath() string {
	return c.basePath
}
