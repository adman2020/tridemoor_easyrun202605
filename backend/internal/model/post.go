package model

import "time"

// Post 跑友动态
type Post struct {
	ID        string    `gorm:"type:char(36);primaryKey" json:"id"`
	UserID    string    `gorm:"type:char(36);not null;index:idx_post_user" json:"user_id"`
	RunID     *string   `gorm:"type:char(36);index:idx_post_run" json:"run_id,omitempty"`
	RouteID   *string   `gorm:"type:char(36);index:idx_post_route" json:"route_id,omitempty"`
	Content   string    `gorm:"type:text" json:"content"`
	CreatedAt time.Time `gorm:"type:datetime(3)" json:"created_at"`

	// 审核和可见性字段（由管理后台控制）
	ReviewStatus int8       `gorm:"type:tinyint;not null;default:0;index:idx_post_review" json:"review_status"`
	IsHidden     int8       `gorm:"type:tinyint;not null;default:0;index:idx_post_hidden" json:"is_hidden"`
	DeletedAt    *time.Time `gorm:"type:datetime(3);index:idx_post_deleted" json:"deleted_at,omitempty"`

	User  User   `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Run   *Run   `gorm:"foreignKey:RunID" json:"run,omitempty"`
	Route *Route `gorm:"foreignKey:RouteID" json:"route,omitempty"`

	// 计算字段（不在数据库中存储）
	LikeCount    int64 `gorm:"-" json:"like_count"`
	CommentCount int64 `gorm:"-" json:"comment_count"`
}

func (Post) TableName() string { return "posts" }

// PostComment 动态评论
type PostComment struct {
	ID        string    `gorm:"type:char(36);primaryKey" json:"id"`
	PostID    string    `gorm:"type:char(36);not null;index:idx_comment_post" json:"post_id"`
	UserID    string    `gorm:"type:char(36);not null;index:idx_comment_user" json:"user_id"`
	Content   string    `gorm:"type:text;not null" json:"content"`
	CreatedAt time.Time `gorm:"type:datetime(3)" json:"created_at"`

	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

func (PostComment) TableName() string { return "post_comments" }

// PostLike 动态点赞
type PostLike struct {
	PostID    string    `gorm:"type:char(36);primaryKey" json:"post_id"`
	UserID    string    `gorm:"type:char(36);primaryKey" json:"user_id"`
	CreatedAt time.Time `gorm:"type:datetime(3)" json:"created_at"`
}

func (PostLike) TableName() string { return "post_likes" }
