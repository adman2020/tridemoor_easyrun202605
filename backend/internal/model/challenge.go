package model

import (
	"time"
)

// Challenge 挑战模型
type Challenge struct {
	ID              string     `gorm:"type:char(36);primaryKey" json:"id"`
	RouteID         string     `gorm:"type:char(36);not null;index:idx_route" json:"route_id"`
	ChallengerID    string     `gorm:"type:char(36);not null;index:idx_challenger" json:"challenger_id"`
	ChallengerRunID *string    `gorm:"type:char(36)" json:"challenger_run_id,omitempty"`
	InviteeID       *string    `gorm:"type:char(36);index:idx_invitee" json:"invitee_id,omitempty"`
	// TargetRunID 被挑战的目标跑步记录ID（异步挑战：B挑战A的历史记录）
	TargetRunID     *string    `gorm:"type:char(36);index:idx_target_run" json:"target_run_id,omitempty"`
	GhostMode       string     `gorm:"type:varchar(20);default:'real_replay'" json:"ghost_mode"`
	GoalMetric      *string    `gorm:"type:varchar(20)" json:"goal_metric,omitempty"`
	Status          string     `gorm:"type:varchar(20);default:'pending';index:idx_status" json:"status"`
	ChallengerResult *string   `gorm:"type:json" json:"challenger_result,omitempty"`
	InviteeResult   *string    `gorm:"type:json" json:"invitee_result,omitempty"`
	WinnerID        *string    `gorm:"type:char(36)" json:"winner_id,omitempty"`
	CreatedAt       time.Time  `gorm:"type:datetime(3)" json:"created_at"`
	AcceptedAt      *time.Time `gorm:"type:datetime(3)" json:"accepted_at,omitempty"`
	StartedAt       *time.Time `gorm:"type:datetime(3)" json:"started_at,omitempty"`
	CompletedAt     *time.Time `gorm:"type:datetime(3)" json:"completed_at,omitempty"`
	ExpiresAt       *time.Time `gorm:"type:datetime(3);index:idx_expires" json:"expires_at,omitempty"`

	// 关联
	Route       Route        `gorm:"foreignKey:RouteID" json:"route,omitempty"`
	Challenger  User         `gorm:"foreignKey:ChallengerID" json:"challenger,omitempty"`
	Invitee     *User        `gorm:"foreignKey:InviteeID" json:"invitee,omitempty"`
	Winner      *User        `gorm:"foreignKey:WinnerID" json:"winner,omitempty"`
	TargetRun   *Run         `gorm:"foreignKey:TargetRunID" json:"target_run,omitempty"`
	Comparison  *Comparison  `gorm:"foreignKey:ChallengeID" json:"comparison,omitempty"`
}

func (Challenge) TableName() string {
	return "challenges"
}

// Comparison 对比报告模型
type Comparison struct {
	ID           string    `gorm:"type:char(36);primaryKey" json:"id"`
	ChallengeID  *string   `gorm:"type:char(36);uniqueIndex:idx_challenge" json:"challenge_id,omitempty"`
	RunAID       string    `gorm:"type:char(36);not null;index:idx_run_a" json:"run_a_id"`
	RunBID       string    `gorm:"type:char(36);not null;index:idx_run_b" json:"run_b_id"`
	OverallDiff  string    `gorm:"type:json;not null" json:"overall_diff"`
	SplitsJSON   *string   `gorm:"type:json" json:"splits_json,omitempty"`
	DiagnosisJSON *string  `gorm:"type:json" json:"diagnosis_json,omitempty"`
	CreatedAt    time.Time `gorm:"type:datetime(3)" json:"created_at"`

	Challenge *Challenge `gorm:"foreignKey:ChallengeID" json:"challenge,omitempty"`
	RunA      Run        `gorm:"foreignKey:RunAID" json:"run_a,omitempty"`
	RunB      Run        `gorm:"foreignKey:RunBID" json:"run_b,omitempty"`
}

func (Comparison) TableName() string {
	return "comparisons"
}

// Friendship 好友关系模型
type Friendship struct {
	ID        string    `gorm:"type:char(36);primaryKey" json:"id"`
	UserIDA   string    `gorm:"type:char(36);not null;uniqueIndex:uk_friends;index:idx_user_a" json:"user_id_a"`
	UserIDB   string    `gorm:"type:char(36);not null;uniqueIndex:uk_friends;index:idx_user_b" json:"user_id_b"`
	Status    string    `gorm:"type:varchar(20);default:'pending'" json:"status"`
	CreatedAt time.Time `gorm:"type:datetime(3)" json:"created_at"`
	UpdatedAt time.Time `gorm:"type:datetime(3)" json:"updated_at"`

	UserA User `gorm:"foreignKey:UserIDA" json:"user_a,omitempty"`
	UserB User `gorm:"foreignKey:UserIDB" json:"user_b,omitempty"`
}

func (Friendship) TableName() string {
	return "friendships"
}

// Leaderboard 排行榜快照模型
type Leaderboard struct {
	ID         string    `gorm:"type:char(36);primaryKey" json:"id"`
	RouteID    string    `gorm:"type:char(36);not null;uniqueIndex:uk_route_user;index:idx_route_time" json:"route_id"`
	UserID     string    `gorm:"type:char(36);not null;uniqueIndex:uk_route_user;index:idx_user" json:"user_id"`
	RunID      string    `gorm:"type:char(36);not null" json:"run_id"`
	TotalTime  int64     `gorm:"type:int;not null" json:"total_time"`
	AvgPace    *int      `gorm:"type:int" json:"avg_pace"`
	RunCount   int       `gorm:"type:int;default:0" json:"run_count"`
	RecordedAt time.Time `gorm:"type:datetime(3);not null" json:"recorded_at"`
	CreatedAt  time.Time `gorm:"type:datetime(3)" json:"created_at"`
	UpdatedAt  time.Time `gorm:"type:datetime(3)" json:"updated_at"`

	Route Route `gorm:"foreignKey:RouteID" json:"route,omitempty"`
	User  User  `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Run   Run   `gorm:"foreignKey:RunID" json:"run,omitempty"`
}

func (Leaderboard) TableName() string {
	return "route_leaderboards"
}
