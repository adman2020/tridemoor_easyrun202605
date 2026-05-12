package model

import "time"

// Follow 关注关系模型（单向关注）
type Follow struct {
	ID          uint      `gorm:"primaryKey;autoIncrement" json:"-"`
	FollowerID  string    `gorm:"type:char(36);not null;index:idx_follower" json:"follower_id"`
	FollowingID string    `gorm:"type:char(36);not null;index:idx_following" json:"following_id"`
	CreatedAt   time.Time `gorm:"type:datetime(3)" json:"created_at"`
}

func (Follow) TableName() string {
	return "follows"
}
