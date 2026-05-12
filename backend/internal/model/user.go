package model

import (
	"time"
)

// User 用户模型
type User struct {
	ID             string    `gorm:"type:char(36);primaryKey" json:"id"`
	Phone          string    `gorm:"type:varchar(20);not null;uniqueIndex:idx_phone" json:"phone"`
	PasswordHash   string    `gorm:"type:varchar(255);not null" json:"-"`
	Nickname       string    `gorm:"type:varchar(50);not null;default:'跑者'" json:"nickname"`
	Avatar         *string   `gorm:"type:varchar(500)" json:"avatar,omitempty"`
	Bio            *string   `gorm:"type:text" json:"bio,omitempty"`
	Gender         *int8     `gorm:"type:tinyint" json:"gender,omitempty"`
	Birthday       *string   `gorm:"type:date" json:"birthday,omitempty"`
	Height         *int16    `gorm:"type:smallint" json:"height,omitempty"`
	Weight         *float64  `gorm:"type:decimal(5,2)" json:"weight,omitempty"`
	Email          *string   `gorm:"type:varchar(100)" json:"email,omitempty"`
	TotalDistance  float64   `gorm:"type:decimal(10,2);default:0" json:"total_distance"`
	TotalRuns      int64     `gorm:"type:bigint;default:0" json:"total_runs"`
	TotalTime      int64     `gorm:"type:bigint;default:0" json:"total_time"`
	TotalCalories  int64     `gorm:"type:int;default:0" json:"total_calories"`
	DeviceInfo     *string   `gorm:"type:json" json:"device_info,omitempty"`
	Settings       string    `gorm:"type:json" json:"settings"`

	// ========== VIP 增值服务 ==========
	IsVip          int8      `gorm:"type:tinyint;default:0" json:"is_vip"`
	VipTier        int8       `gorm:"type:tinyint;default:0" json:"vip_tier"`
	VipExpiresAt   *time.Time `gorm:"type:datetime(3)" json:"vip_expires_at,omitempty"`
	VipFeatures    string     `gorm:"type:json" json:"vip_features"`

	// ========== 跑境系统 ==========
	Realm            int8   `gorm:"type:tinyint;default:0" json:"realm"`                         // 当前境界索引 0=炼气…12=道祖
	RealmBadges      string `gorm:"type:json" json:"realm_badges"`                   // 已获得勋章列表 JSON: ["气","筑",...]
	CompanionRuns    int64  `gorm:"type:int;default:0" json:"companion_runs"`                     // 已完成伴跑次数
	ChallengesWon    int64  `gorm:"type:int;default:0" json:"challenges_won"`                     // 挑战成功次数
	BestMarathonTime int64  `gorm:"type:int;default:0" json:"best_marathon_time"`
	Best5kTime       *int64 `gorm:"type:int" json:"best_5k_time,omitempty"`
	Best10kTime      *int64 `gorm:"type:int" json:"best_10k_time,omitempty"`
	BestHalfMarathonTime *int64 `gorm:"type:int" json:"best_half_marathon_time,omitempty"`                 // 半马 PB(秒)
	PostCount        int64  `gorm:"type:int;default:0" json:"post_count"`                         // 已发动态数

	// ========== 骑境系统 ==========
	CyclingRealm        int8    `gorm:"type:tinyint;default:0" json:"cycling_realm"`
	CyclingRealmBadges  string  `gorm:"type:json" json:"cycling_realm_badges"`
	CyclingBest20kTime  *int64  `gorm:"type:int" json:"cycling_best_20k_time,omitempty"`
	CyclingBest40kTime  *int64  `gorm:"type:int" json:"cycling_best_40k_time,omitempty"`
	CyclingBest80kTime  *int64  `gorm:"type:int" json:"cycling_best_80k_time,omitempty"`
	CyclingBest100kTime *int64  `gorm:"type:int" json:"cycling_best_100k_time,omitempty"`
	CyclingBest160kTime *int64  `gorm:"type:int" json:"cycling_best_160k_time,omitempty"`
	CyclingBestSpeed    *float64 `gorm:"type:decimal(6,2)" json:"cycling_best_speed,omitempty"`
	CyclingBestDistance float64 `gorm:"type:decimal(10,2);default:0" json:"cycling_best_distance"`
	CyclingCompanions   int64   `gorm:"type:int;default:0" json:"cycling_companions"`
	CyclingChallengesWon int64  `gorm:"type:int;default:0" json:"cycling_challenges_won"`
	CyclingDualBadges   string  `gorm:"type:json" json:"cycling_dual_badges"`
	CyclingTotalDistance float64 `gorm:"type:decimal(10,2);default:0" json:"cycling_total_distance"`                         // 累计骑行距离(km)

	CreatedAt      time.Time `gorm:"type:datetime(3);default:CURRENT_TIMESTAMP(3)" json:"created_at"`
	UpdatedAt      time.Time `gorm:"type:datetime(3);default:CURRENT_TIMESTAMP(3)" json:"updated_at"`

	// 关联
	Routes    []Route    `gorm:"foreignKey:CreatorID" json:"routes,omitempty"`
	Runs      []Run      `gorm:"foreignKey:UserID" json:"runs,omitempty"`
	Favorites []Favorite `gorm:"foreignKey:UserID" json:"favorites,omitempty"`
}

// TableName 指定表名
func (User) TableName() string {
	return "users"
}
