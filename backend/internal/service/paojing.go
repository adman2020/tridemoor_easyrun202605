package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"

	"gorm.io/gorm"
)

// ==================== 境界常量 ====================

var RealmOrder = []string{"气", "筑", "丹", "婴", "化", "虚", "合", "乘", "真", "金", "太", "罗", "道"}

var RealmNames = map[string]string{
	"气": "气引勋章", "筑": "筑仙勋章", "丹": "丹凝勋章", "婴": "婴生勋章",
	"化": "化神勋章", "虚": "炼虚勋章", "合": "合元勋章", "乘": "大乘勋章",
	"真": "真仙勋章", "金": "金仙勋章", "太": "太乙勋章", "罗": "大罗勋章",
	"道": "道祖勋章",
}

// 境界晋升条件
type RealmRule struct {
	RequireDistance     float64 // 需要完成的单次距离(km)，0表示不检查距离
	RequireMarathonMax  int64   // 全马最大时间(秒)，0表示不检查
	RequireCompanionRun int64   // 需要的伴跑次数
	RequireChallengeWin int64   // 需要的挑战成功次数
	RequirePost         int64   // 需要发的动态数
	RequireDistanceType string  // "single" 单次 / "" 无
}

var realmRules = []RealmRule{
	// 0 炼气: 无门槛，注册即入
	{},
	// 1 筑基: 5km + 1次伴跑
	{RequireDistance: 5, RequireDistanceType: "single", RequireCompanionRun: 1},
	// 2 结丹: 10km + 2次挑战
	{RequireDistance: 10, RequireDistanceType: "single", RequireChallengeWin: 2},
	// 3 元婴: 半马 + 5次挑战
	{RequireDistance: 21.0975, RequireDistanceType: "single", RequireChallengeWin: 5},
	// 4 化神: 全马 + 发1次动态
	{RequireDistance: 42.195, RequireDistanceType: "single", RequirePost: 1},
	// 5 练虚: 全马 + 全马<=3h + 发1次动态
	{RequireDistance: 42.195, RequireDistanceType: "single", RequireMarathonMax: 10800, RequirePost: 1},
	// 6 合体: 全马 + 全马<=2:45 + 发1次动态
	{RequireDistance: 42.195, RequireDistanceType: "single", RequireMarathonMax: 9900, RequirePost: 1},
	// 7 大乘: 全马 + 全马<=2:30 + 发1次动态
	{RequireDistance: 42.195, RequireDistanceType: "single", RequireMarathonMax: 9000, RequirePost: 1},
	// 8 真仙: 全马 + 全马<=2:20 + 发1次动态
	{RequireDistance: 42.195, RequireDistanceType: "single", RequireMarathonMax: 8400, RequirePost: 1},
	// 9 金仙: 全马 + 全马<=2:15 + 发1次动态
	{RequireDistance: 42.195, RequireDistanceType: "single", RequireMarathonMax: 8100, RequirePost: 1},
	// 10 太乙: 全马 + 全马<=2:10 + 发1次动态
	{RequireDistance: 42.195, RequireDistanceType: "single", RequireMarathonMax: 7800, RequirePost: 1},
	// 11 大罗: 全马 + 全马<=2:05 + 发1次动态
	{RequireDistance: 42.195, RequireDistanceType: "single", RequireMarathonMax: 7500, RequirePost: 1},
	// 12 道祖: 全马 + 全马<2:00
	{RequireDistance: 42.195, RequireDistanceType: "single", RequireMarathonMax: 7199, RequirePost: 1},
}

// ==================== 数据模型 ====================

type RealmBadgeInfo struct {
	Char   string `json:"char"`
	Name   string `json:"name"`
	Earned bool   `json:"earned"`
}

type PaojingResponse struct {
	CurrentRealm int             `json:"current_realm"` // 当前境界索引 0-12
	CurrentChar  string          `json:"current_char"`
	CurrentName  string          `json:"current_name"`
	Progress     float64         `json:"progress"` // 当前境界晋升进度 0.0-1.0
	Badges       []RealmBadgeInfo `json:"badges"`
	NextRule     *RealmRuleInfo  `json:"next_rule,omitempty"` // 下一境条件（仅未满时有）
}

type RealmRuleInfo struct {
	RequireDistance     float64 `json:"require_distance,omitempty"`
	RequireMarathonMax  int64   `json:"require_marathon_max,omitempty"`
	RequireCompanionRun int64   `json:"require_companion_run,omitempty"`
	RequireChallengeWin int64   `json:"require_challenge_win,omitempty"`
	RequirePost         int64   `json:"require_post,omitempty"`
	DistanceType        string  `json:"distance_type,omitempty"`
}

type RealmUpgradeResult struct {
	Upgraded   bool   `json:"upgraded"`
	OldRealm   int8   `json:"old_realm"`
	NewRealm   int8   `json:"new_realm"`
	NewChar    string `json:"new_char"`
	NewName    string `json:"new_name"`
	AutoPosted bool   `json:"auto_posted"` // 是否自动发布了升级动态
}

// ==================== Service ====================

type PaojingService struct {
	db           *gorm.DB
	userRepo     *repository.UserRepository
	postService  *PostService
}

func NewPaojingService(db *gorm.DB, userRepo *repository.UserRepository, postService *PostService) *PaojingService {
	return &PaojingService{
		db:          db,
		userRepo:    userRepo,
		postService: postService,
	}
}

// GetPaojing 获取用户的跑境完整数据
func (s *PaojingService) GetPaojing(ctx context.Context, userID string) (*PaojingResponse, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("user not found")
	}

	realm := int(user.Realm)
	badges := make([]RealmBadgeInfo, 0, len(RealmOrder))
	earnedList := s.parseBadges(user.RealmBadges)

	for i, ch := range RealmOrder {
		// 当前境界及以下默认已点亮（即使 realm_badges 为空也保证至少有第一境）
		earned := i <= realm
		// 但如果 realm_badges 非空，以实际记录为准（也覆盖上级境界）
		for _, b := range earnedList {
			if b == ch {
				earned = true
				break
			}
		}
		badges = append(badges, RealmBadgeInfo{
			Char:   ch,
			Name:   RealmNames[ch],
			Earned: earned,
		})
	}

	resp := &PaojingResponse{
		CurrentRealm: realm,
		CurrentChar:  RealmOrder[realm],
		CurrentName:  RealmNames[RealmOrder[realm]],
		Badges:       badges,
	}

	// 计算晋升进度
	if realm < 12 {
		rule := realmRules[realm+1]
		progress := s.calcProgress(user, rule)
		resp.Progress = progress
		resp.NextRule = &RealmRuleInfo{
			RequireDistance:     rule.RequireDistance,
			RequireMarathonMax:  rule.RequireMarathonMax,
			RequireCompanionRun: rule.RequireCompanionRun,
			RequireChallengeWin: rule.RequireChallengeWin,
			RequirePost:         rule.RequirePost,
			DistanceType:        rule.RequireDistanceType,
		}
	} else {
		resp.Progress = 1.0
	}

	return resp, nil
}

// CheckRealmUpgrade 检查并执行境界晋升（跑后/发动态后调用）
func (s *PaojingService) CheckRealmUpgrade(ctx context.Context, userID string) (*RealmUpgradeResult, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("user not found")
	}

	result := &RealmUpgradeResult{
		OldRealm: user.Realm,
	}

	// 从当前境界开始检查是否满足下一境条件
	upgraded := false
	// 最多允许一次升多级（比如新手直接完成全马）
	maxIterations := 13 - int(user.Realm)

	for i := 0; i < maxIterations; i++ {
		nextIndex := int(user.Realm) + 1
		if nextIndex >= len(realmRules) {
			break
		}
		rule := realmRules[nextIndex]
		if !s.meetsRequirements(user, rule) {
			break
		}
		// 符合条件，晋升
		user.Realm = int8(nextIndex)
		// 添加勋章
		earnedList := s.parseBadges(user.RealmBadges)
		char := RealmOrder[nextIndex]
		hasBadge := false
		for _, b := range earnedList {
			if b == char {
				hasBadge = true
				break
			}
		}
		if !hasBadge {
			earnedList = append(earnedList, char)
		}
		badgesBytes, _ := json.Marshal(earnedList)
		user.RealmBadges = string(badgesBytes)
		upgraded = true
	}

	if !upgraded {
		return result, nil
	}

	// 保存到数据库
	if err := s.db.WithContext(ctx).Model(user).Updates(map[string]interface{}{
		"realm":        user.Realm,
		"realm_badges": user.RealmBadges,
	}).Error; err != nil {
		return nil, err
	}

	result.Upgraded = true
	result.NewRealm = user.Realm
	result.NewChar = RealmOrder[user.Realm]
	result.NewName = RealmNames[RealmOrder[user.Realm]]

	// 自动发动态恭喜突破
	autoPostContent := fmt.Sprintf("🎉 恭喜突破至【%s】！%s，万里挑一！",
		result.NewName,
		getRealmBreakthroughSaying(int(user.Realm)))

	_, err = s.postService.CreatePost(ctx, userID, &CreatePostRequest{
		Content: autoPostContent,
	})
	if err == nil {
		result.AutoPosted = true
		// 自动发的动态也算一次发动态
		s.db.WithContext(ctx).Model(user).UpdateColumn("post_count", gorm.Expr("post_count + ?", 1))
	}

	return result, nil
}

// IncrementCompanionRun 伴跑完成 +1
func (s *PaojingService) IncrementCompanionRun(ctx context.Context, userID string) error {
	return s.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", userID).
		UpdateColumn("companion_runs", gorm.Expr("companion_runs + ?", 1)).Error
}

// IncrementChallengeWin 挑战成功 +1
func (s *PaojingService) IncrementChallengeWin(ctx context.Context, userID string) error {
	return s.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", userID).
		UpdateColumn("challenges_won", gorm.Expr("challenges_won + ?", 1)).Error
}

// IncrementPostCount 发动态 +1
func (s *PaojingService) IncrementPostCount(ctx context.Context, userID string) error {
	return s.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", userID).
		UpdateColumn("post_count", gorm.Expr("post_count + ?", 1)).Error
}

// CheckAndUpgradeAfterPost 发动态后检查晋升
func (s *PaojingService) CheckAndUpgradeAfterPost(ctx context.Context, userID string) (*RealmUpgradeResult, error) {
	// 先增加发动态计数
	if err := s.IncrementPostCount(ctx, userID); err != nil {
		return nil, err
	}
	return s.CheckRealmUpgrade(ctx, userID)
}

// UpdateBestMarathon 更新最佳全马成绩并检查晋升
func (s *PaojingService) UpdateBestMarathon(ctx context.Context, userID string, marathonTime int64) (*RealmUpgradeResult, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("user not found")
	}

	if marathonTime > 0 && (user.BestMarathonTime == 0 || marathonTime < user.BestMarathonTime) {
		user.BestMarathonTime = marathonTime
		if err := s.db.WithContext(ctx).Model(user).UpdateColumn("best_marathon_time", marathonTime).Error; err != nil {
			return nil, err
		}
	}

	return s.CheckRealmUpgrade(ctx, userID)
}

// ==================== 内部方法 ====================

func (s *PaojingService) parseBadges(badgesJSON string) []string {
	if badgesJSON == "" || badgesJSON == "[]" {
		return []string{}
	}
	var list []string
	if err := json.Unmarshal([]byte(badgesJSON), &list); err != nil {
		return []string{}
	}
	return list
}

// calcProgress 计算当前境界晋升下一境的进度
func (s *PaojingService) calcProgress(user *model.User, rule RealmRule) float64 {
	if rule.RequireDistance == 0 && rule.RequireMarathonMax == 0 &&
		rule.RequireCompanionRun == 0 && rule.RequireChallengeWin == 0 &&
		rule.RequirePost == 0 {
		return 1.0
	}

	var totalWeight float64
	var completedWeight float64

	// 距离条件（单次最大距离）
	if rule.RequireDistance > 0 {
		totalWeight += 1
		var maxDistance *float64
		s.db.Model(&model.Run{}).Select("MAX(total_distance)").
			Where("user_id = ? AND total_distance IS NOT NULL", user.ID).
			Scan(&maxDistance)
		if maxDistance != nil && *maxDistance >= rule.RequireDistance {
			completedWeight += 1
		}
	}

	// 全马条件
	if rule.RequireMarathonMax > 0 {
		totalWeight += 1
		if user.BestMarathonTime > 0 && user.BestMarathonTime <= rule.RequireMarathonMax {
			completedWeight += 1
		}
	}

	// 伴跑次数
	if rule.RequireCompanionRun > 0 {
		totalWeight += 1
		if user.CompanionRuns >= rule.RequireCompanionRun {
			completedWeight += 1
		} else {
			completedWeight += float64(user.CompanionRuns) / float64(rule.RequireCompanionRun)
		}
	}

	// 挑战次数
	if rule.RequireChallengeWin > 0 {
		totalWeight += 1
		if user.ChallengesWon >= rule.RequireChallengeWin {
			completedWeight += 1
		} else {
			completedWeight += float64(user.ChallengesWon) / float64(rule.RequireChallengeWin)
		}
	}

	// 发动态
	if rule.RequirePost > 0 {
		totalWeight += 1
		if user.PostCount >= rule.RequirePost {
			completedWeight += 1
		} else {
			completedWeight += float64(user.PostCount) / float64(rule.RequirePost)
		}
	}

	if totalWeight == 0 {
		return 1.0
	}
	progress := completedWeight / totalWeight
	if progress > 1.0 {
		progress = 1.0
	}
	return progress
}

// meetsRequirements 检查用户是否满足某一境界的全部条件
func (s *PaojingService) meetsRequirements(user *model.User, rule RealmRule) bool {
	if rule.RequireDistance > 0 && rule.RequireDistanceType == "single" {
		// 检查用户是否有单次达到该距离的记录
		var maxDistance *float64
		s.db.Model(&model.Run{}).Select("MAX(total_distance)").
			Where("user_id = ? AND total_distance IS NOT NULL", user.ID).
			Scan(&maxDistance)
		if maxDistance == nil || *maxDistance < rule.RequireDistance {
			return false
		}
	}
	if rule.RequireMarathonMax > 0 {
		if user.BestMarathonTime == 0 || user.BestMarathonTime > rule.RequireMarathonMax {
			return false
		}
	}
	if rule.RequireCompanionRun > 0 && user.CompanionRuns < rule.RequireCompanionRun {
		return false
	}
	if rule.RequireChallengeWin > 0 && user.ChallengesWon < rule.RequireChallengeWin {
		return false
	}
	if rule.RequirePost > 0 && user.PostCount < rule.RequirePost {
		return false
	}
	return true
}

func getRealmBreakthroughSaying(realm int) string {
	sayings := []string{
		"引气入体，凡人起步",       // 炼气
		"脱胎换骨，踏上仙途",       // 筑基
		"凝结金丹，一方高手",       // 结丹
		"丹破化婴，寿元千载",       // 元婴
		"元神出窍，跨界遨游",       // 化神
		"熔炼虚空，感悟法则",       // 练虚
		"肉身元神合一，雄霸灵界",   // 合体
		"灵界顶端，渡劫飞升",       // 大乘
		"飞升仙界，重塑仙体",       // 真仙
		"法则凝丝，自成领域",       // 金仙
		"太乙道果，不朽仙躯",       // 太乙
		"大罗永恒，豁免岁月",       // 大罗
		"执掌本源，万界巅峰",       // 道祖
	}
	if realm >= 0 && realm < len(sayings) {
		return sayings[realm]
	}
	return ""
}

// ==================== 调试方法 ====================

// DebugSetRealm 强制设置用户境界（开发调试用）
func (s *PaojingService) DebugSetRealm(ctx context.Context, userID string, realm int8) (*RealmUpgradeResult, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("user not found")
	}

	oldRealm := user.Realm
	user.Realm = realm

	// 根据境界自动生成徽章列表
	allBadges := make([]string, 0, realm+1)
	for i := 0; i <= int(realm); i++ {
		allBadges = append(allBadges, RealmOrder[i])
	}
	badgesBytes, _ := json.Marshal(allBadges)
	user.RealmBadges = string(badgesBytes)

	if err := s.db.WithContext(ctx).Model(user).Updates(map[string]interface{}{
		"realm":        user.Realm,
		"realm_badges": user.RealmBadges,
	}).Error; err != nil {
		return nil, err
	}

	result := &RealmUpgradeResult{
		Upgraded: realm != oldRealm,
		OldRealm: oldRealm,
		NewRealm: realm,
		NewChar:  RealmOrder[realm],
		NewName:  RealmNames[RealmOrder[realm]],
	}

	return result, nil
}

// DebugSetExtraFields 额外设置跑量/社交数据（开发调试用）
func (s *PaojingService) DebugSetExtraFields(ctx context.Context, userID string, updates map[string]interface{}) {
	if len(updates) > 0 {
		s.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", userID).Updates(updates)
	}
}

// For backward compatibility: export CheckAndUpgradeAfterFinishRun
func (s *PaojingService) CheckAndUpgradeAfterFinishRun(ctx context.Context, userID string, run *model.Run) (*RealmUpgradeResult, error) {
	// 如果这次是全马距离，更新最佳全马成绩
	if run.TotalDistance != nil && *run.TotalDistance >= 42.0 && run.TotalTime != nil {
		marathonTime := *run.TotalTime
		// 按比例换算成全马42.195km时间
		standardTime := int64(float64(marathonTime) * 42.195 / *run.TotalDistance)
		return s.UpdateBestMarathon(ctx, userID, standardTime)
	}
	return s.CheckRealmUpgrade(ctx, userID)
}


