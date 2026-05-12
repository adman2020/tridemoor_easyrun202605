package repository

import (
	"context"
	"errors"
	"time"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

type ChallengeRepository struct {
	db *gorm.DB
}

func NewChallengeRepository(db *gorm.DB) *ChallengeRepository {
	return &ChallengeRepository{db: db}
}

// ==================== Challenge CRUD ====================

func (r *ChallengeRepository) Create(ctx context.Context, challenge *model.Challenge) error {
	return r.db.WithContext(ctx).Create(challenge).Error
}

func (r *ChallengeRepository) FindByID(ctx context.Context, id string) (*model.Challenge, error) {
	var challenge model.Challenge
	err := r.db.WithContext(ctx).
		Preload("Route").
		Preload("Challenger").
		Preload("Invitee").
		Preload("Winner").
		Preload("Comparison").
		First(&challenge, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &challenge, nil
}

func (r *ChallengeRepository) Update(ctx context.Context, challenge *model.Challenge) error {
	return r.db.WithContext(ctx).Save(challenge).Error
}

func (r *ChallengeRepository) ListByUser(ctx context.Context, userID string, status string, page, pageSize int) ([]model.Challenge, int64, error) {
	var challenges []model.Challenge
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Challenge{}).
		Where("(challenger_id = ? OR invitee_id = ?)", userID, userID)

	if status != "" {
		db = db.Where("status = ?", status)
	}

	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err := db.Preload("Route").Preload("Challenger").Preload("Invitee").
		Order("created_at DESC").Offset(offset).Limit(pageSize).
		Find(&challenges).Error
	return challenges, total, err
}

// ==================== Status & Result ====================

func (r *ChallengeRepository) UpdateStatus(ctx context.Context, id string, status string, acceptedAt, startedAt, completedAt *time.Time) error {
	updates := map[string]interface{}{"status": status}
	if acceptedAt != nil {
		updates["accepted_at"] = *acceptedAt
	}
	if startedAt != nil {
		updates["started_at"] = *startedAt
	}
	if completedAt != nil {
		updates["completed_at"] = *completedAt
	}
	return r.db.WithContext(ctx).Model(&model.Challenge{}).Where("id = ?", id).Updates(updates).Error
}

func (r *ChallengeRepository) UpdateChallengerResult(ctx context.Context, id string, runID string, result string) error {
	return r.db.WithContext(ctx).Model(&model.Challenge{}).Where("id = ?", id).
		Updates(map[string]interface{}{
			"challenger_run_id": runID,
			"challenger_result": result,
		}).Error
}

func (r *ChallengeRepository) UpdateInviteeResult(ctx context.Context, id string, result string) error {
	return r.db.WithContext(ctx).Model(&model.Challenge{}).Where("id = ?", id).
		Update("invitee_result", result).Error
}

func (r *ChallengeRepository) UpdateWinner(ctx context.Context, id string, winnerID *string) error {
	return r.db.WithContext(ctx).Model(&model.Challenge{}).Where("id = ?", id).
		Update("winner_id", winnerID).Error
}

// ==================== Comparison ====================

func (r *ChallengeRepository) CreateComparison(ctx context.Context, comparison *model.Comparison) error {
	return r.db.WithContext(ctx).Create(comparison).Error
}

func (r *ChallengeRepository) FindComparisonByChallengeID(ctx context.Context, challengeID string) (*model.Comparison, error) {
	var comparison model.Comparison
	err := r.db.WithContext(ctx).
		Preload("RunA").Preload("RunB").
		Where("challenge_id = ?", challengeID).
		First(&comparison).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &comparison, nil
}

// FindComparisonByRunID 根据跑步记录ID查找对比报告（该Run作为RunA或RunB）
// CountChallengeReceived 统计用户被异步挑战次数（别人挑战用户的跑步记录，不含伴跑/结对跑邀请）
func (r *ChallengeRepository) CountChallengeReceived(ctx context.Context, userID string) (int64, error) {
	var count int64
	// 只有异步挑战：invitee_id IS NULL，目标跑记录属于该用户，且发起者不是用户自己
	err := r.db.WithContext(ctx).Model(&model.Challenge{}).
		Where("target_run_id IN (SELECT id FROM runs WHERE user_id = ?) AND challenger_id != ? AND invitee_id IS NULL", userID, userID).
		Count(&count).Error
	return count, err
}

// CountChallengeOutcomes 统计用户被异步挑战的胜负情况（仅别人异步挑战用户，不含伴跑/结对跑）
func (r *ChallengeRepository) CountChallengeOutcomes(ctx context.Context, userID string) (wins int64, losses int64, pending int64, noResult int64, err error) {
	sqlBase := "(target_run_id IN (SELECT id FROM runs WHERE user_id = ?) AND challenger_id != ? AND invitee_id IS NULL)"

	// 胜：winner_id 为该用户
	if e := r.db.WithContext(ctx).Model(&model.Challenge{}).
		Where(sqlBase+" AND winner_id = ?", userID, userID, userID).
		Count(&wins).Error; e != nil {
		return 0, 0, 0, 0, e
	}

	// 负：completed 且 winner 明确但非该用户
	if e := r.db.WithContext(ctx).Model(&model.Challenge{}).
		Where(sqlBase+" AND status = 'completed' AND winner_id IS NOT NULL AND winner_id != ?", userID, userID, userID).
		Count(&losses).Error; e != nil {
		return 0, 0, 0, 0, e
	}

	// 进行中：未完成、未取消
	if e := r.db.WithContext(ctx).Model(&model.Challenge{}).
		Where(sqlBase+" AND status NOT IN ('completed','cancelled','expired')", userID, userID).
		Count(&pending).Error; e != nil {
		return 0, 0, 0, 0, e
	}

	// 无胜负：completed 但 winner 为空
	if e := r.db.WithContext(ctx).Model(&model.Challenge{}).
		Where(sqlBase+" AND status = 'completed' AND winner_id IS NULL", userID, userID).
		Count(&noResult).Error; e != nil {
		return 0, 0, 0, 0, e
	}

	return
}

// CountChallengeInitiated 统计用户发起的异步挑战次数（不含伴跑/结对跑）
func (r *ChallengeRepository) CountChallengeInitiated(ctx context.Context, userID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.Challenge{}).
		Where("challenger_id = ? AND invitee_id IS NULL", userID).
		Count(&count).Error
	return count, err
}

// CountChallengeInitiatedOutcomes 统计用户发起的异步挑战胜负（不含进行中）
func (r *ChallengeRepository) CountChallengeInitiatedOutcomes(ctx context.Context, userID string) (wins int64, losses int64, err error) {
	sqlBase := "challenger_id = ? AND invitee_id IS NULL"

	// 胜
	if e := r.db.WithContext(ctx).Model(&model.Challenge{}).
		Where(sqlBase+" AND status = 'completed' AND winner_id = ?", userID, userID).
		Count(&wins).Error; e != nil {
		return 0, 0, e
	}

	// 负：completed 且 winner 明确但非该用户
	if e := r.db.WithContext(ctx).Model(&model.Challenge{}).
		Where(sqlBase+" AND status = 'completed' AND winner_id IS NOT NULL AND winner_id != ?", userID, userID).
		Count(&losses).Error; e != nil {
		return 0, 0, e
	}

	return
}

func (r *ChallengeRepository) FindComparisonByRunID(ctx context.Context, runID string) (*model.Comparison, error) {
	var comparison model.Comparison
	err := r.db.WithContext(ctx).
		Preload("RunA.Splits").Preload("RunB.Splits").
		Preload("Challenge").
		Where("run_a_id = ? OR run_b_id = ?", runID, runID).
		First(&comparison).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &comparison, nil
}
