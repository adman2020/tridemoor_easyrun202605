package model

import "time"

// AIAPIKey AI模型配置（管理端 RuoYi 维护）
// 对应数据库已有表 ai_api_keys（bigint 自增主键）
type AIAPIKey struct {
	ID         int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	Provider   string    `gorm:"type:varchar(50);not null" json:"provider"`
	Name       string    `gorm:"type:varchar(100);not null" json:"name"`
	APIKey     string    `gorm:"column:api_key;type:varchar(500);not null" json:"-"`
	BaseURL    string    `gorm:"column:base_url;type:varchar(255)" json:"base_url,omitempty"`
	Model      string    `gorm:"type:varchar(100)" json:"model"`
	UsageScope string    `gorm:"column:usage_scope;type:varchar(100);default:all" json:"usage_scope"`
	Priority   int       `gorm:"default:0" json:"priority"`
	IsActive   bool      `gorm:"column:is_active;type:tinyint(1);default:1" json:"is_active"`
	DailyLimit int       `gorm:"default:0" json:"daily_limit"`
	TodayCalls int       `gorm:"default:0" json:"today_calls"`
	Remarks    string    `gorm:"type:varchar(500)" json:"remarks,omitempty"`
	CreateTime time.Time `gorm:"column:create_time;autoCreateTime" json:"create_time"`
	UpdateTime time.Time `gorm:"column:update_time;autoUpdateTime" json:"update_time"`
}

func (AIAPIKey) TableName() string {
	return "ai_api_keys"
}

// AICallLog AI调用日志
// 对应数据库已有表 ai_call_logs（bigint 自增主键）
type AICallLog struct {
	ID              int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	APIKeyID        *int64    `gorm:"column:api_key_id" json:"api_key_id,omitempty"`
	Provider        string    `gorm:"type:varchar(50);not null" json:"provider"`
	Model           string    `gorm:"type:varchar(100)" json:"model"`
	UsageScope      string    `gorm:"column:usage_scope;type:varchar(50);not null" json:"usage_scope"`
	RequestTokens   int       `gorm:"default:0" json:"request_tokens"`
	ResponseTokens  int       `gorm:"default:0" json:"response_tokens"`
	CostCount       float64   `gorm:"type:decimal(10,6);default:0" json:"cost_count"`
	DurationMs      int       `gorm:"default:0" json:"duration_ms"`
	Status          string    `gorm:"type:varchar(20);not null;default:success" json:"status"`
	ErrorMsg        string    `gorm:"type:varchar(500)" json:"error_msg,omitempty"`
	CreateTime      time.Time `gorm:"column:create_time;autoCreateTime;index" json:"create_time"`
}

func (AICallLog) TableName() string {
	return "ai_call_logs"
}

// AIAnalysis AI 跑情分析缓存（跑完即生成，查看即读取）
type AIAnalysis struct {
	ID            int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	RunID         string     `gorm:"type:char(36);not null;uniqueIndex" json:"run_id"`
	UserID        string     `gorm:"type:char(36);not null;index" json:"user_id"`
	AnalysisText  string     `gorm:"column:analysis_text;type:text;not null" json:"analysis_text"`
	Tokens        int        `gorm:"default:0" json:"tokens"`
	DurationMs    int        `gorm:"column:duration_ms;default:0" json:"duration_ms"`
	Model         string     `gorm:"type:varchar(64);default:''" json:"model"`
	Weather       string     `gorm:"type:varchar(32);default:''" json:"weather"`
	Temperature   *int8      `json:"temperature"`
	CreatedAt     time.Time  `gorm:"column:created_at;autoCreateTime" json:"created_at"`
	UpdatedAt     time.Time  `gorm:"column:updated_at;autoUpdateTime" json:"updated_at"`
}

func (AIAnalysis) TableName() string {
	return "ai_analyses"
}

// AiFeatureConfig AI功能配置（管理端 RuoYi 维护，Go 端只读）
type AiFeatureConfig struct {
	ID           int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	FeatureKey   string    `gorm:"column:feature_key;type:varchar(50);not null;uniqueIndex" json:"feature_key"`
	FeatureName  string    `gorm:"column:feature_name;type:varchar(100);not null" json:"feature_name"`
	Enabled      bool      `gorm:"type:tinyint(1);default:1" json:"enabled"`
	APIKeyID     *int64    `gorm:"column:api_key_id" json:"api_key_id,omitempty"`
	ModelOverride string   `gorm:"column:model_override;type:varchar(100)" json:"model_override,omitempty"`
	DailyLimit   int       `gorm:"default:0" json:"daily_limit"`
	TodayCalls   int       `gorm:"default:0" json:"today_calls"`
	LastReset    string    `gorm:"column:last_reset;type:date" json:"last_reset"`
	CreateTime   time.Time `gorm:"column:create_time;autoCreateTime" json:"create_time"`
	UpdateTime   time.Time `gorm:"column:update_time;autoUpdateTime" json:"update_time"`
}

func (AiFeatureConfig) TableName() string {
	return "ai_feature_configs"
}

// AiFeatureConfigWithKey AI功能配置 + 关联的密钥信息
type AiFeatureConfigWithKey struct {
	AiFeatureConfig
	Provider   string `gorm:"-" json:"provider"`
	APIKey     string `gorm:"-" json:"-"`
	BaseURL    string `gorm:"-" json:"base_url,omitempty"`
	Model      string `gorm:"-" json:"model"`
}
