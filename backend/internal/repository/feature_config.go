package repository

import (
	"encoding/json"
	"sync"
	"time"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

// FeatureConfigRepository AI功能配置仓库（带本地缓存）
// 每10分钟从 stridemoor.ai_feature_configs JOIN ai_api_keys 拉取一次配置
type FeatureConfigRepository struct {
	mu       sync.RWMutex
	cache    map[string]*model.AiFeatureConfigWithKey
	lastSync time.Time
	db       *gorm.DB
}

func NewFeatureConfigRepository(db *gorm.DB) *FeatureConfigRepository {
	r := &FeatureConfigRepository{
		cache: make(map[string]*model.AiFeatureConfigWithKey),
		db:    db,
	}
	r.refresh() // 启动时加载
	return r
}

// GetByFeatureKey 获取某功能的最新配置（从缓存读取）
func (r *FeatureConfigRepository) GetByFeatureKey(featureKey string) (*model.AiFeatureConfigWithKey, error) {
	r.mu.RLock()
	cfg, ok := r.cache[featureKey]
	r.mu.RUnlock()
	if ok {
		return cfg, nil
	}
	return nil, gorm.ErrRecordNotFound
}

// Refresh 外部调用触发刷新（可做定时任务或REST回调）
func (r *FeatureConfigRepository) Refresh() {
	r.refresh()
}

// StartAutoRefresh 启动自动刷新（每10分钟）
func (r *FeatureConfigRepository) StartAutoRefresh() {
	go func() {
		ticker := time.NewTicker(10 * time.Minute)
		for range ticker.C {
			r.refresh()
		}
	}()
}

// refresh 从数据库查询所有已启用的功能配置（JOIN ai_api_keys）
func (r *FeatureConfigRepository) refresh() {
	var rows []struct {
		model.AiFeatureConfig
		Provider string `gorm:"column:provider"`
		APIKey   string `gorm:"column:api_key"`
		BaseURL  string `gorm:"column:base_url"`
		KeyModel string `gorm:"column:key_model"` // ai_api_keys.model
	}

	err := r.db.Table("ai_feature_configs fc").
		Select(`fc.*, ak.provider, ak.api_key, ak.base_url, ak.model as key_model`).
		Joins("LEFT JOIN ai_api_keys ak ON fc.api_key_id = ak.id AND ak.is_active = 1").
		Find(&rows).Error

	if err != nil {
		// 读失败不更新缓存，保留旧缓存
		return
	}

	newCache := make(map[string]*model.AiFeatureConfigWithKey)
	for _, row := range rows {
		// 确定实际使用的模型
		effectiveModel := row.KeyModel
		if row.ModelOverride != "" {
			effectiveModel = row.ModelOverride
		}

		newCache[row.FeatureKey] = &model.AiFeatureConfigWithKey{
			AiFeatureConfig: row.AiFeatureConfig,
			Provider:        row.Provider,
			APIKey:          row.APIKey,
			BaseURL:         row.BaseURL,
			Model:           effectiveModel,
		}
	}

	r.mu.Lock()
	r.cache = newCache
	r.lastSync = time.Now()
	r.mu.Unlock()
}

// GetCacheJSON 返回缓存快照（调试/管理用）
func (r *FeatureConfigRepository) GetCacheJSON() string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	b, _ := json.MarshalIndent(r.cache, "", "  ")
	return string(b)
}

// IncrementTodayCalls 递增指定功能的今日调用量
func (r *FeatureConfigRepository) IncrementTodayCalls(featureKey string) {
	r.db.Exec("UPDATE ai_feature_configs SET today_calls = today_calls + 1 WHERE feature_key = ? AND (last_reset = CURDATE() OR last_reset IS NULL)", featureKey)
	// 更新本地缓存中的 todayCalls
	r.mu.Lock()
	if cfg, ok := r.cache[featureKey]; ok {
		cfg.TodayCalls++
	}
	r.mu.Unlock()
}

