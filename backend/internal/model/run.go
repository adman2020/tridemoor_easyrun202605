package model

import (
	"time"
)

// Run 跑步记录模型
type Run struct {
	ID              string    `gorm:"type:char(36);primaryKey" json:"id"`
	UserID          string    `gorm:"type:char(36);not null;index:idx_user" json:"user_id"`
	RouteID         *string   `gorm:"type:char(36);index:idx_route" json:"route_id,omitempty"`
	Mode            string    `gorm:"type:varchar(20);not null;default:'solo';index:idx_mode" json:"mode"`
	OpponentRunID   *string   `gorm:"type:char(36)" json:"opponent_run_id,omitempty"`
	StartTime       time.Time `gorm:"type:datetime(3);not null;index:idx_start_time" json:"start_time"`
	EndTime         *time.Time `gorm:"type:datetime(3)" json:"end_time,omitempty"`
	TotalTime       *int64    `gorm:"type:int" json:"total_time,omitempty"`
	TotalDistance   *float64  `gorm:"type:decimal(10,2)" json:"total_distance,omitempty"`
	AvgPace         *int  `gorm:"type:int" json:"avg_pace,omitempty"`
	BestPace        *int  `gorm:"type:int" json:"best_pace,omitempty"`
	AvgHeartRate    *int16    `gorm:"type:smallint" json:"avg_heart_rate,omitempty"`
	MaxHeartRate    *int16    `gorm:"type:smallint" json:"max_heart_rate,omitempty"`
	AvgCadence      *int16    `gorm:"type:smallint" json:"avg_cadence,omitempty"`
	MaxCadence      *int16    `gorm:"type:smallint" json:"max_cadence,omitempty"`
	AvgStrideLength *float64  `gorm:"type:decimal(5,2)" json:"avg_stride_length,omitempty"`
	ElevationGain   float64   `gorm:"type:decimal(10,2);default:0" json:"elevation_gain"`
	ElevationLoss   float64   `gorm:"type:decimal(10,2);default:0" json:"elevation_loss"`
	Calories        *int      `gorm:"type:int" json:"calories,omitempty"`
	Weather         *string   `gorm:"type:varchar(20)" json:"weather,omitempty"`
	Temperature     *int16    `gorm:"type:smallint" json:"temperature,omitempty"`
	DeviceType      *string   `gorm:"type:varchar(50)" json:"device_type,omitempty"`
	GpxFileURL      *string   `gorm:"type:varchar(500)" json:"gpx_file_url,omitempty"`
	IsShared        bool      `gorm:"type:tinyint(1);default:0" json:"is_shared"`
	ShareCount      int       `gorm:"type:int;default:0" json:"share_count"`
	LikeCount       int       `gorm:"type:int;default:0" json:"like_count"`
	HeatCount       int        `gorm:"type:int;default:0" json:"heat_count"`
	DeletedAt       *time.Time `gorm:"type:datetime(3);index:idx_run_deleted" json:"deleted_at,omitempty"`
	CreatedAt       time.Time  `gorm:"type:datetime(3)" json:"created_at"`
	UpdatedAt       time.Time  `gorm:"type:datetime(3)" json:"updated_at"`

	// 关联
	User    User        `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Route   *Route      `gorm:"foreignKey:RouteID" json:"route,omitempty"`
	Splits  []RunSplit  `gorm:"foreignKey:RunID" json:"splits,omitempty"`
	Samples []RunSample `gorm:"-" json:"samples,omitempty"`
	Bounds  *RunBounds  `gorm:"-" json:"bounds,omitempty"`
}

// RunBounds 跑迹GPS范围（用于伴跑/挑战前距离校验）
type RunBounds struct {
	MinLat float64 `json:"min_lat"`
	MaxLat float64 `json:"max_lat"`
	MinLng float64 `json:"min_lng"`
	MaxLng float64 `json:"max_lng"`
}

func (Run) TableName() string {
	return "runs"
}

// RunSplit 跑步分段数据
type RunSplit struct {
	ID              string    `gorm:"type:char(36);primaryKey" json:"id"`
	RunID           string    `gorm:"type:char(36);not null;uniqueIndex:uk_run_split;index:idx_run" json:"run_id"`
	SplitIndex      int64     `gorm:"type:int;not null;uniqueIndex:uk_run_split" json:"split_index"`
	Distance        float64   `gorm:"type:decimal(10,2);not null" json:"distance"`
	Time            int64     `gorm:"type:int;not null" json:"time"`
	Pace            *float64  `gorm:"type:decimal(6,2)" json:"pace,omitempty"`
	AvgHeartRate    *int16    `gorm:"type:smallint" json:"avg_heart_rate,omitempty"`
	AvgCadence      *int16    `gorm:"type:smallint" json:"avg_cadence,omitempty"`
	AvgStrideLength *float64  `gorm:"type:decimal(5,2)" json:"avg_stride_length,omitempty"`
	ElevationGain   float64   `gorm:"type:decimal(10,2);default:0" json:"elevation_gain"`
	ElevationLoss   float64   `gorm:"type:decimal(10,2);default:0" json:"elevation_loss"`
	CreatedAt       time.Time `gorm:"type:datetime(3)" json:"created_at"`

	Run Run `gorm:"foreignKey:RunID" json:"run,omitempty"`
}

func (RunSplit) TableName() string {
	return "run_splits"
}

// RunSample 跑步秒级采样数据（时序数据）
type RunSample struct {
	RunID             string    `gorm:"type:char(36);primaryKey" json:"run_id"`
	SampleTime        time.Time `gorm:"type:datetime(3);primaryKey" json:"sample_time"`
	Latitude          float64   `gorm:"type:decimal(10,7);not null" json:"latitude"`
	Longitude         float64   `gorm:"type:decimal(10,7);not null" json:"longitude"`
	Altitude          *float64  `gorm:"type:decimal(10,2)" json:"altitude,omitempty"`
	Pace              *float64  `gorm:"type:decimal(6,2)" json:"pace,omitempty"`
	HeartRate         *int16    `gorm:"type:smallint" json:"heart_rate,omitempty"`
	Cadence           *int16    `gorm:"type:smallint" json:"cadence,omitempty"`
	StrideLength      *float64  `gorm:"type:decimal(5,2)" json:"stride_length,omitempty"`
	DistanceFromStart float64   `gorm:"type:decimal(10,2);default:0" json:"distance_from_start"`
}

func (RunSample) TableName() string {
	return "run_samples"
}

// RunAverages 跑步历史平均值（用于语音播报中对比自己的历史水平）
type RunAverages struct {
	AvgPace      int     `json:"avg_pace"`
	AvgHeartRate int16   `json:"avg_heart_rate"`
	AvgCadence   int16   `json:"avg_cadence"`
	AvgStride    float64 `json:"avg_stride_length"`
	RunCount     int64   `json:"run_count"`
}

// RunBookmark 跑友跑迹收藏 — 收藏跑友某次具体跑步记录，而非路线
type RunBookmark struct {
	ID        string    `gorm:"type:char(36);primaryKey" json:"id"`
	UserID    string    `gorm:"type:char(36);not null;index:idx_bm_user" json:"user_id"`
	RunID     string    `gorm:"type:char(36);not null;uniqueIndex:uk_user_run" json:"run_id"`
	CreatedAt time.Time `gorm:"type:datetime(3)" json:"created_at"`

	Run  Run  `gorm:"foreignKey:RunID" json:"run,omitempty"`
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

func (RunBookmark) TableName() string {
	return "run_bookmarks"
}
