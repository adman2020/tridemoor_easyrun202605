package model

import (
	"time"
)

// Route 路线模型
type Route struct {
	ID             string    `gorm:"type:char(36);primaryKey" json:"id"`
	CreatorID      string    `gorm:"type:char(36);not null;index:idx_creator" json:"creator_id"`
	Name           string    `gorm:"type:varchar(100);not null;fulltext:idx_name" json:"name"`
	Description    *string   `gorm:"type:text" json:"description,omitempty"`
	Distance       float64   `gorm:"type:decimal(10,2);not null" json:"distance"`
	ElevationGain  float64   `gorm:"type:decimal(10,2);default:0" json:"elevation_gain"`
	ElevationLoss  float64   `gorm:"type:decimal(10,2);default:0" json:"elevation_loss"`
	Difficulty     int8      `gorm:"type:tinyint;default:1" json:"difficulty"`
	RoadType       int8      `gorm:"type:tinyint;default:0" json:"road_type"`
	Popularity     int       `gorm:"type:int;default:0" json:"popularity"`
	Rating         float64   `gorm:"type:decimal(2,1);default:5.0" json:"rating"`
	RatingCount    int       `gorm:"type:int;default:0" json:"rating_count"`
	AvgPace        int       `gorm:"type:int;default:0" json:"avg_pace"`
	AvgCadence     int       `gorm:"type:int;default:0" json:"avg_cadence"`
	AvgStride      float64   `gorm:"type:decimal(5,2);default:0" json:"avg_stride"`
	Calories       int       `gorm:"type:int;default:0" json:"calories"`
	AvgHeartRate   int       `gorm:"type:int;default:0" json:"avg_heart_rate"`
	GpxFileURL     *string   `gorm:"type:varchar(500)" json:"gpx_file_url,omitempty"`
	ThumbnailURL   *string   `gorm:"type:varchar(500)" json:"thumbnail_url,omitempty"`
	Tags           string    `gorm:"type:json" json:"tags"`
	City           *string   `gorm:"type:varchar(50);index:idx_city" json:"city,omitempty"`
	TotalTime      *int64    `gorm:"type:int" json:"total_time,omitempty"`
	MaxHeartRate   *int16    `gorm:"type:smallint" json:"max_heart_rate,omitempty"`
	MaxCadence     *int16    `gorm:"type:smallint" json:"max_cadence,omitempty"`
	StartLat       *float64  `gorm:"type:decimal(10,7)" json:"start_lat,omitempty"`
	StartLng       *float64  `gorm:"type:decimal(10,7)" json:"start_lng,omitempty"`
	CenterLat      *float64  `gorm:"type:decimal(10,7)" json:"center_lat,omitempty"`
	CenterLng      *float64  `gorm:"type:decimal(10,7)" json:"center_lng,omitempty"`
	IsPublic       bool       `gorm:"type:tinyint(1);default:1" json:"is_public"`
	Status         int8       `gorm:"type:tinyint;default:1" json:"status"`
	ReviewStatus   int8       `gorm:"type:tinyint;not null;default:1;index:idx_route_review" json:"review_status"`
	DeletedAt      *time.Time `gorm:"type:datetime(3);index:idx_route_deleted" json:"deleted_at,omitempty"`
	CreatedAt      time.Time  `gorm:"type:datetime(3)" json:"created_at"`
	UpdatedAt      time.Time  `gorm:"type:datetime(3)" json:"updated_at"`

	// 关联
	Creator   User        `gorm:"foreignKey:CreatorID;references:ID" json:"creator,omitempty"`
	Runs      []Run       `gorm:"foreignKey:RouteID" json:"runs,omitempty"`
	Favorites []Favorite  `gorm:"foreignKey:RouteID" json:"favorites,omitempty"`
	Leaderboards []Leaderboard `gorm:"foreignKey:RouteID" json:"leaderboards,omitempty"`
	Points    []RoutePoint `gorm:"foreignKey:RouteID;references:ID" json:"points,omitempty"`
}

// RoutePoint 路线坐标点
type RoutePoint struct {
	RouteID    string  `gorm:"type:char(36);primaryKey" json:"route_id"`
	PointIndex int     `gorm:"type:int;primaryKey" json:"point_index"`
	Latitude   float64 `gorm:"type:decimal(10,7);not null" json:"latitude"`
	Longitude  float64 `gorm:"type:decimal(10,7);not null" json:"longitude"`
	Altitude   *float64 `gorm:"type:decimal(10,2)" json:"altitude,omitempty"`
}

func (RoutePoint) TableName() string {
	return "route_points"
}

func (Route) TableName() string {
	return "routes"
}

// Favorite 路线收藏
type Favorite struct {
	ID        string    `gorm:"type:char(36);primaryKey" json:"id"`
	UserID    string    `gorm:"type:char(36);not null;uniqueIndex:uk_user_route;index:idx_user" json:"user_id"`
	RouteID   string    `gorm:"type:char(36);not null;uniqueIndex:uk_user_route;index:idx_route" json:"route_id"`
	Tag       string    `gorm:"type:varchar(20);default:'收藏'" json:"tag"`
	CreatedAt time.Time `gorm:"type:datetime(3)" json:"created_at"`

	User  User  `gorm:"foreignKey:UserID" json:"-"`
	Route Route `gorm:"foreignKey:RouteID" json:"route,omitempty"`
}

func (Favorite) TableName() string {
	return "route_favorites"
}
