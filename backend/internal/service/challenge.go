package service

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"

	"github.com/google/uuid"
)

type ChallengeService struct {
	challengeRepo *repository.ChallengeRepository
	runRepo       *repository.RunRepository
	userRepo      *repository.UserRepository
	routeRepo     *repository.RouteRepository
	paojingSvc    *PaojingService
}

func (s *ChallengeService) SetPaojingService(ps *PaojingService) {
	s.paojingSvc = ps
}

func NewChallengeService(
	challengeRepo *repository.ChallengeRepository,
	runRepo *repository.RunRepository,
	userRepo *repository.UserRepository,
	routeRepo *repository.RouteRepository,
) *ChallengeService {
	return &ChallengeService{
		challengeRepo: challengeRepo,
		runRepo:       runRepo,
		userRepo:      userRepo,
		routeRepo:     routeRepo,
	}
}

// ==================== Create Challenge ====================

type CreateChallengeRequest struct {
	RouteID     string  `json:"route_id" binding:"required"`
	InviteeID   *string `json:"invitee_id"`
	TargetRunID *string `json:"target_run_id"`
	GhostMode   string  `json:"ghost_mode" binding:"required,oneof=real_replay constant rabbit tortoise_hare goal"`
	GoalMetric  *string `json:"goal_metric"`
}

func (s *ChallengeService) CreateChallenge(ctx context.Context, challengerID string, req *CreateChallengeRequest) (*model.Challenge, error) {
	// 验证路线
	route, err := s.routeRepo.FindByID(ctx, req.RouteID)
	if err != nil {
		return nil, err
	}
	if route == nil {
		return nil, errors.New("route not found")
	}

	// 验证被挑战者
	if req.InviteeID != nil {
		invitee, err := s.userRepo.FindByID(ctx, *req.InviteeID)
		if err != nil {
			return nil, err
		}
		if invitee == nil {
			return nil, errors.New("invitee not found")
		}
		if *req.InviteeID == challengerID {
			return nil, errors.New("cannot challenge yourself")
		}
	}

	// 验证目标跑步记录（异步挑战）
	if req.TargetRunID != nil {
		targetRun, err := s.runRepo.FindByID(ctx, *req.TargetRunID)
		if err != nil {
			return nil, err
		}
		if targetRun == nil {
			return nil, errors.New("target run not found")
		}
	}

	challenge := &model.Challenge{
		ID:           uuid.New().String(),
		RouteID:      req.RouteID,
		ChallengerID: challengerID,
		InviteeID:    req.InviteeID,
		TargetRunID:  req.TargetRunID,
		GhostMode:    req.GhostMode,
		GoalMetric:   req.GoalMetric,
		Status:       "pending",
	}

	// 自发陪跑（无对手），直接 accepted
	if req.InviteeID == nil {
		challenge.Status = "accepted"
		now := time.Now()
		challenge.AcceptedAt = &now
	}

	// 异步挑战（有TargetRunID，不需要对方同意），直接 accepted
	if req.TargetRunID != nil {
		challenge.Status = "accepted"
		now := time.Now()
		challenge.AcceptedAt = &now
	}

	if err := s.challengeRepo.Create(ctx, challenge); err != nil {
		return nil, err
	}

	return challenge, nil
}

// ==================== Accept Challenge ====================

func (s *ChallengeService) AcceptChallenge(ctx context.Context, challengeID, userID string) error {
	challenge, err := s.challengeRepo.FindByID(ctx, challengeID)
	if err != nil {
		return err
	}
	if challenge == nil {
		return errors.New("challenge not found")
	}
	if challenge.Status != "pending" {
		return errors.New("challenge not pending")
	}
	if challenge.InviteeID == nil || *challenge.InviteeID != userID {
		return errors.New("permission denied")
	}

	now := time.Now()
	return s.challengeRepo.UpdateStatus(ctx, challengeID, "accepted", &now, nil, nil)
}

// ==================== Start Challenge ====================

type StartChallengeResponse struct {
	ChallengeID string    `json:"challenge_id"`
	RunID       string    `json:"run_id"`
	StartTime   time.Time `json:"start_time"`
}

func (s *ChallengeService) StartChallenge(ctx context.Context, challengeID, userID string) (*StartChallengeResponse, error) {
	challenge, err := s.challengeRepo.FindByID(ctx, challengeID)
	if err != nil {
		return nil, err
	}
	if challenge == nil {
		return nil, errors.New("challenge not found")
	}

	// 验证参与权
	isChallenger := challenge.ChallengerID == userID
	isInvitee := challenge.InviteeID != nil && *challenge.InviteeID == userID
	if !isChallenger && !isInvitee {
		return nil, errors.New("permission denied")
	}

	// 状态检查
	if challenge.Status != "pending" && challenge.Status != "accepted" {
		return nil, errors.New("challenge cannot be started")
	}

	// 创建跑步记录
	run := &model.Run{
		ID:        uuid.New().String(),
		UserID:    userID,
		RouteID:   &challenge.RouteID,
		StartTime: time.Now(),
	}
	if err := s.runRepo.Create(ctx, run); err != nil {
		return nil, err
	}

	// 更新挑战状态
	now := time.Now()
	status := "running"
	if challenge.Status == "pending" && isChallenger {
		// 挑战者自发开始，无需等待被挑战者接受
		status = "running"
	}
	_ = s.challengeRepo.UpdateStatus(ctx, challengeID, status, nil, &now, nil)

	return &StartChallengeResponse{
		ChallengeID: challengeID,
		RunID:       run.ID,
		StartTime:   run.StartTime,
	}, nil
}

// ==================== Complete Challenge ====================

type CompleteChallengeRequest struct {
	RunID  string          `json:"run_id" binding:"required"`
	Result json.RawMessage `json:"result" binding:"required"`
}

func (s *ChallengeService) CompleteChallenge(ctx context.Context, challengeID, userID string, req *CompleteChallengeRequest) error {
	challenge, err := s.challengeRepo.FindByID(ctx, challengeID)
	if err != nil {
		return err
	}
	if challenge == nil {
		return errors.New("challenge not found")
	}
	if challenge.Status != "running" && challenge.Status != "accepted" {
		return errors.New("challenge not in progress")
	}

	isChallenger := challenge.ChallengerID == userID
	isInvitee := challenge.InviteeID != nil && *challenge.InviteeID == userID
	if !isChallenger && !isInvitee {
		return errors.New("permission denied")
	}

	// 验证 run 属于当前用户
	run, err := s.runRepo.FindByID(ctx, req.RunID)
	if err != nil {
		return err
	}
	if run == nil {
		return errors.New("run not found")
	}
	if run.UserID != userID {
		return errors.New("run does not belong to user")
	}

	resultStr := string(req.Result)

	// 更新结果
	if isChallenger {
		if err := s.challengeRepo.UpdateChallengerResult(ctx, challengeID, req.RunID, resultStr); err != nil {
			return err
		}
	} else {
		if err := s.challengeRepo.UpdateInviteeResult(ctx, challengeID, resultStr); err != nil {
			return err
		}
	}

	// 重新加载，检查是否双方都已完成
	challenge, err = s.challengeRepo.FindByID(ctx, challengeID)
	if err != nil {
		return err
	}

	// 判断挑战是否完成
	bothCompleted := false
	if challenge.TargetRunID != nil {
		// 异步挑战：B挑战A的历史记录，只需要挑战者（B）完成即可
		bothCompleted = challenge.ChallengerResult != nil
	} else if challenge.InviteeID == nil {
		// 自发陪跑，只需要挑战者完成
		bothCompleted = challenge.ChallengerResult != nil
	} else {
		// 同步PK：需要双方都完成
		bothCompleted = challenge.ChallengerResult != nil && challenge.InviteeResult != nil
	}

	if bothCompleted {
		now := time.Now()
		_ = s.challengeRepo.UpdateStatus(ctx, challengeID, "completed", nil, nil, &now)

		// 生成对比报告
		if err := s.generateComparison(ctx, challenge); err != nil {
			// 对比报告生成失败不影响主流程
			_ = err
		}

		// 热度更新：被挑战的跑迹 +1
		if challenge.TargetRunID != nil {
			_ = s.runRepo.IncrementHeatCount(ctx, *challenge.TargetRunID)
		}

		// 跑境晋级：挑战双方各 +1，双方都检查晋级
		if s.paojingSvc != nil {
			s.paojingSvc.IncrementChallengeWin(ctx, challenge.ChallengerID)
			go s.paojingSvc.CheckRealmUpgrade(ctx, challenge.ChallengerID)
			if challenge.InviteeID != nil {
				s.paojingSvc.IncrementChallengeWin(ctx, *challenge.InviteeID)
				go s.paojingSvc.CheckRealmUpgrade(ctx, *challenge.InviteeID)
			}
		}
	} else {
		// 单方先完成，也检查晋级
		if s.paojingSvc != nil {
			go s.paojingSvc.CheckRealmUpgrade(ctx, userID)
		}
	}

	return nil
}

// ==================== Cancel Challenge ====================

func (s *ChallengeService) CancelChallenge(ctx context.Context, challengeID, userID string) error {
	challenge, err := s.challengeRepo.FindByID(ctx, challengeID)
	if err != nil {
		return err
	}
	if challenge == nil {
		return errors.New("challenge not found")
	}
	if challenge.ChallengerID != userID {
		return errors.New("permission denied")
	}
	if challenge.Status == "completed" || challenge.Status == "cancelled" {
		return errors.New("challenge already finished")
	}
	return s.challengeRepo.UpdateStatus(ctx, challengeID, "cancelled", nil, nil, nil)
}

// ==================== List & Detail ====================

func (s *ChallengeService) ListChallenges(ctx context.Context, userID string, status string, page, pageSize int) ([]model.Challenge, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 10
	}
	return s.challengeRepo.ListByUser(ctx, userID, status, page, pageSize)
}

func (s *ChallengeService) GetChallengeDetail(ctx context.Context, challengeID string) (*model.Challenge, error) {
	return s.challengeRepo.FindByID(ctx, challengeID)
}

func (s *ChallengeService) GetComparison(ctx context.Context, challengeID string) (*model.Comparison, error) {
	return s.challengeRepo.FindComparisonByChallengeID(ctx, challengeID)
}

// ==================== Comparison Generator ====================

func (s *ChallengeService) generateComparison(ctx context.Context, challenge *model.Challenge) error {
	if challenge.ChallengerResult == nil {
		return errors.New("challenger result missing")
	}

	var challengerResult ChallengeResult
	if err := json.Unmarshal([]byte(*challenge.ChallengerResult), &challengerResult); err != nil {
		return err
	}

	// 确定对手数据
	var opponentResult ChallengeResult
	var runBID string

	if challenge.TargetRunID != nil {
		// 异步挑战：对手是目标跑步记录的历史数据
		targetRun, err := s.runRepo.FindByID(ctx, *challenge.TargetRunID)
		if err != nil || targetRun == nil {
			return errors.New("target run not found")
		}
		runBID = targetRun.ID
		opponentResult = ChallengeResult{
			RunID:         targetRun.ID,
			TotalTime:     0,
			TotalDistance: 0,
			AvgPace:       0,
		}
		if targetRun.TotalTime != nil {
			opponentResult.TotalTime = *targetRun.TotalTime
		}
		if targetRun.TotalDistance != nil {
			opponentResult.TotalDistance = *targetRun.TotalDistance
		}
		if targetRun.AvgPace != nil {
			opponentResult.AvgPace = float64(*targetRun.AvgPace)
		}
		// 构建分段数据
		if len(targetRun.Splits) > 0 {
			opponentResult.Splits = make([]SplitResult, len(targetRun.Splits))
			for i, sp := range targetRun.Splits {
				var pace float64
				if sp.Pace != nil {
					pace = *sp.Pace
				}
				opponentResult.Splits[i] = SplitResult{
					SplitIndex: sp.SplitIndex,
					Distance:   sp.Distance,
					Time:       int(sp.Time),
					Pace:       pace,
				}
			}
		}
	} else if challenge.InviteeResult != nil {
		// 同步PK：对手是被挑战者的结果
		if err := json.Unmarshal([]byte(*challenge.InviteeResult), &opponentResult); err != nil {
			return err
		}
		runBID = opponentResult.RunID
	}

	if challenge.ChallengerRunID == nil || *challenge.ChallengerRunID == "" {
		return errors.New("challenger run id missing")
	}

	// 计算差异
	timeDiff := float64(challengerResult.TotalTime - opponentResult.TotalTime)
	paceDiff := challengerResult.AvgPace - opponentResult.AvgPace

	var winnerID *string
	if challenge.TargetRunID != nil {
		// 异步挑战：比较挑战者（B）和目标（A）
		if timeDiff < 0 {
			winnerID = &challenge.ChallengerID
		} else if timeDiff > 0 {
			// 目标获胜，winner 是被挑战者（invitee_id）
			winnerID = challenge.InviteeID
		}
	} else if challenge.InviteeID != nil {
		if timeDiff < 0 {
			winnerID = &challenge.ChallengerID
		} else if timeDiff > 0 {
			winnerID = challenge.InviteeID
		}
	} else {
		// 自发陪跑，无 winner
		winnerID = nil
	}

	// 更新 winner
	_ = s.challengeRepo.UpdateWinner(ctx, challenge.ID, winnerID)

	overallDiff := map[string]interface{}{
		"challenger": map[string]interface{}{
			"total_time":     challengerResult.TotalTime,
			"avg_pace":       challengerResult.AvgPace,
			"total_distance": challengerResult.TotalDistance,
		},
		"opponent": map[string]interface{}{
			"total_time":     opponentResult.TotalTime,
			"avg_pace":       opponentResult.AvgPace,
			"total_distance": opponentResult.TotalDistance,
		},
		"time_diff": timeDiff,
		"pace_diff": paceDiff,
		"winner_id": winnerID,
	}
	overallDiffJSON, _ := json.Marshal(overallDiff)

	diagnosis := map[string]interface{}{
		"summary": "挑战完成，数据对比已生成",
		"tips":    []string{},
	}
	diagnosisJSON, _ := json.Marshal(diagnosis)
	diagnosisStr := string(diagnosisJSON)

	comparison := &model.Comparison{
		ID:            uuid.New().String(),
		ChallengeID:   &challenge.ID,
		RunAID:        *challenge.ChallengerRunID,
		RunBID:        runBID,
		OverallDiff:   string(overallDiffJSON),
		DiagnosisJSON: &diagnosisStr,
	}

	return s.challengeRepo.CreateComparison(ctx, comparison)
}

// ChallengeResult 挑战参与者结果
type ChallengeResult struct {
	RunID         string        `json:"run_id"`
	TotalTime     int64         `json:"total_time"`
	TotalDistance float64       `json:"total_distance"`
	AvgPace       float64       `json:"avg_pace"`
	Splits        []SplitResult `json:"splits"`
}

type SplitResult struct {
	SplitIndex int64   `json:"split_index"`
	Distance   float64 `json:"distance"`
	Time       int     `json:"time"`
	Pace       float64 `json:"pace"`
}
