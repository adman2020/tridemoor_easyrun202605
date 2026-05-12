package repository

import (
	"stridemoor-api/internal/model"
	"stridemoor-api/pkg/database"
)

type AIKeyRepository struct{}

func NewAIKeyRepository() *AIKeyRepository {
	return &AIKeyRepository{}
}

// GetEnabledConfig 获取某功能(usage_scope)的可用配置（按优先级选最高）
func (r *AIKeyRepository) GetEnabledConfig(usageScope string) (*model.AIAPIKey, error) {
	var key model.AIAPIKey
	err := database.DB.Where("usage_scope = ? AND is_active = 1", usageScope).
		Order("priority DESC").
		First(&key).Error
	if err != nil {
		return nil, err
	}
	return &key, nil
}

// Create 创建配置
func (r *AIKeyRepository) Create(key *model.AIAPIKey) error {
	return database.DB.Create(key).Error
}

// Update 更新配置
func (r *AIKeyRepository) Update(key *model.AIAPIKey) error {
	return database.DB.Save(key).Error
}

// ListByScope 列出某功能所有配置
func (r *AIKeyRepository) ListByScope(usageScope string) ([]model.AIAPIKey, error) {
	var keys []model.AIAPIKey
	err := database.DB.Where("usage_scope = ?", usageScope).Order("priority DESC").Find(&keys).Error
	return keys, err
}

type AICallLogRepository struct{}

func NewAICallLogRepository() *AICallLogRepository {
	return &AICallLogRepository{}
}

// Create 写入调用日志
func (r *AICallLogRepository) Create(log *model.AICallLog) error {
	return database.DB.Create(log).Error
}

// RecentByScope 获取某功能最近的调用记录
func (r *AICallLogRepository) RecentByScope(usageScope string, limit int) ([]model.AICallLog, error) {
	var logs []model.AICallLog
	err := database.DB.Where("usage_scope = ?", usageScope).
		Order("create_time DESC").
		Limit(limit).
		Find(&logs).Error
	return logs, err
}

type AIAnalysisRepository struct{}

func NewAIAnalysisRepository() *AIAnalysisRepository {
	return &AIAnalysisRepository{}
}

// GetByRunID 根据 run_id 查询缓存的分析结果
func (r *AIAnalysisRepository) GetByRunID(runID string) (*model.AIAnalysis, error) {
	var analysis model.AIAnalysis
	err := database.DB.Where("run_id = ?", runID).First(&analysis).Error
	if err != nil {
		return nil, err
	}
	return &analysis, nil
}

// CreateOrUpdate 创建或更新（run_id 唯一约束）
func (r *AIAnalysisRepository) CreateOrUpdate(analysis *model.AIAnalysis) error {
	return database.DB.Save(analysis).Error
}

// GetByID 根据ID获取密钥配置
func (r *AIKeyRepository) GetByID(id int64) (*model.AIAPIKey, error) {
	var key model.AIAPIKey
	err := database.DB.Where("id = ? AND is_active = 1", id).First(&key).Error
	if err != nil {
		return nil, err
	}
	return &key, nil
}
