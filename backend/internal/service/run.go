package service

import (
	"context"
	"errors"
	"log"
	"time"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"

	"github.com/google/uuid"
)

type RunService struct {
	runRepo       *repository.RunRepository
	sampleRepo    *repository.RunSampleRepository
	userRepo      *repository.UserRepository
	lbRepo        *repository.LeaderboardRepository
	challengeRepo *repository.ChallengeRepository
	bmRepo        *repository.RunBookmarkRepository
	routeRepo     *repository.RouteRepository
	paojingSvc    *PaojingService
}

func NewRunService(
	runRepo *repository.RunRepository,
	sampleRepo *repository.RunSampleRepository,
	userRepo *repository.UserRepository,
	lbRepo *repository.LeaderboardRepository,
	challengeRepo *repository.ChallengeRepository,
	bmRepo *repository.RunBookmarkRepository,
	routeRepo *repository.RouteRepository,
) *RunService {
	return &RunService{
		runRepo:       runRepo,
		sampleRepo:    sampleRepo,
		userRepo:      userRepo,
		lbRepo:        lbRepo,
		challengeRepo: challengeRepo,
		bmRepo:        bmRepo,
		routeRepo:     routeRepo,
	}
}

// SetPaojingService 设置跑境服务引用
func (s *RunService) SetPaojingService(ps *PaojingService) {
	s.paojingSvc = ps
}

type StartRunRequest struct {
	RouteID *string `json:"route_id"`
}

type StartRunResponse struct {
	RunID     string    `json:"run_id"`
	StartTime time.Time `json:"start_time"`
}

type SamplePoint struct {
	SampleTime        time.Time `json:"sample_time" binding:"required"`
	Latitude          float64   `json:"latitude" binding:"required"`
	Longitude         float64   `json:"longitude" binding:"required"`
	Altitude          *float64  `json:"altitude"`
	Pace              *float64  `json:"pace"`
	HeartRate         *int16    `json:"heart_rate"`
	Cadence           *int16    `json:"cadence"`
	StrideLength      *float64  `json:"stride_length"`
	DistanceFromStart float64   `json:"distance_from_start"`
}

type UploadSamplesRequest struct {
	Samples []SamplePoint `json:"samples" binding:"required,min=1,max=500"`
}

type FinishRunRequest struct {
	EndTime         time.Time        `json:"end_time" binding:"required"`
	TotalDistance   float64          `json:"total_distance" binding:"required,min=0"`
	TotalTime       int64            `json:"total_time" binding:"required,min=0"`
	Mode            string           `json:"mode"`
	OpponentRunID   *string          `json:"opponent_run_id,omitempty"`
	AvgPace         *int         `json:"avg_pace"`
	BestPace        *int         `json:"best_pace"`
	AvgHeartRate    *int16           `json:"avg_heart_rate"`
	MaxHeartRate    *int16           `json:"max_heart_rate"`
	AvgCadence      *int16           `json:"avg_cadence"`
	MaxCadence      *int16           `json:"max_cadence"`
	AvgStrideLength *float64         `json:"avg_stride_length"`
	ElevationGain   float64          `json:"elevation_gain"`
	ElevationLoss   float64          `json:"elevation_loss"`
	Calories        *int             `json:"calories"`
	Weather         *string          `json:"weather"`
	Temperature     *int16           `json:"temperature"`
	Splits          []FinishRunSplit `json:"splits"`
}

type FinishRunSplit struct {
	SplitIndex      int64    `json:"split_index" binding:"required"`
	Distance        float64  `json:"distance" binding:"required"`
	Time            int64    `json:"time" binding:"required"`
	Pace            *float64 `json:"pace"`
	AvgHeartRate    *int16   `json:"avg_heart_rate"`
	AvgCadence      *int16   `json:"avg_cadence"`
	AvgStrideLength *float64 `json:"avg_stride_length"`
	ElevationGain   float64  `json:"elevation_gain"`
	ElevationLoss   float64  `json:"elevation_loss"`
}

type RunListItem struct {
	ID            string     `json:"id"`
	Mode          string     `json:"mode"`
	StartTime     time.Time  `json:"start_time"`
	EndTime       *time.Time `json:"end_time,omitempty"`
	TotalTime     *int64     `json:"total_time,omitempty"`
	TotalDistance *float64   `json:"total_distance,omitempty"`
	AvgPace       *int   `json:"avg_pace,omitempty"`
	Calories      *int       `json:"calories,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
}

type RunDetail struct {
	Run             model.Run         `json:"run"`
	Samples         []model.RunSample `json:"samples"`
	OpponentRun     *model.Run        `json:"opponent_run,omitempty"`
	OpponentSamples []model.RunSample `json:"opponent_samples,omitempty"`
	GoalMetric      *string           `json:"goal_metric,omitempty"`
}

func (s *RunService) StartRun(ctx context.Context, userID string, req *StartRunRequest) (*StartRunResponse, error) {
	run := &model.Run{
		ID:        uuid.New().String(),
		UserID:    userID,
		RouteID:   req.RouteID,
		StartTime: time.Now(),
	}

	if err := s.runRepo.Create(ctx, run); err != nil {
		return nil, err
	}

	return &StartRunResponse{
		RunID:     run.ID,
		StartTime: run.StartTime,
	}, nil
}

func (s *RunService) UploadSamples(ctx context.Context, runID string, req *UploadSamplesRequest) error {
	run, err := s.runRepo.FindByID(ctx, runID)
	if err != nil {
		return err
	}
	if run == nil {
		return errors.New("run not found")
	}

	samples := make([]model.RunSample, len(req.Samples))
	for i, p := range req.Samples {
		samples[i] = model.RunSample{
			RunID:             runID,
			SampleTime:        p.SampleTime,
			Latitude:          p.Latitude,
			Longitude:         p.Longitude,
			Altitude:          p.Altitude,
			Pace:              p.Pace,
			HeartRate:         p.HeartRate,
			Cadence:           p.Cadence,
			StrideLength:      p.StrideLength,
			DistanceFromStart: p.DistanceFromStart,
		}
	}

	return s.sampleRepo.BatchCreate(ctx, samples)
}

func (s *RunService) FinishRun(ctx context.Context, runID string, userID string, req *FinishRunRequest) (*MatchResult, error) {
	run, err := s.runRepo.FindByID(ctx, runID)
	if err != nil {
		return nil, err
	}
	if run == nil {
		return nil, errors.New("run not found")
	}
	if run.UserID != userID {
		return nil, errors.New("permission denied")
	}

	run.EndTime = &req.EndTime
	run.TotalTime = &req.TotalTime
	run.TotalDistance = &req.TotalDistance
	run.AvgPace = req.AvgPace
	run.BestPace = req.BestPace
	run.AvgHeartRate = req.AvgHeartRate
	run.MaxHeartRate = req.MaxHeartRate
	run.AvgCadence = req.AvgCadence
	run.MaxCadence = req.MaxCadence
	run.AvgStrideLength = req.AvgStrideLength
	run.ElevationGain = req.ElevationGain
	run.ElevationLoss = req.ElevationLoss
	run.Calories = req.Calories
	run.Weather = req.Weather
	run.Temperature = req.Temperature
	run.Mode = req.Mode
	run.OpponentRunID = req.OpponentRunID

	// 伴跑/挑战跑：创建 comparisons 比对记录（方便回看时展示对手数据）
	if (req.Mode == "companion" || req.Mode == "challenge") && req.OpponentRunID != nil {
		opponent, err := s.runRepo.FindByID(ctx, *req.OpponentRunID)
		if err == nil && opponent != nil {
			_ = s.challengeRepo.CreateComparison(ctx, &model.Comparison{
				ID:       uuid.New().String(),
				RunAID:   runID,
				RunBID:   *req.OpponentRunID,
			})
		}
	}

	if err := s.runRepo.Update(ctx, run); err != nil {
		return nil, err
	}

	// 路线人气 +1（有路线才算）
	if run.RouteID != nil {
		_ = s.routeRepo.IncrementPopularity(ctx, *run.RouteID)
	}

	if len(req.Splits) > 0 {
		splits := make([]model.RunSplit, len(req.Splits))
		for i, sp := range req.Splits {
			splits[i] = model.RunSplit{
				ID:              uuid.New().String(),
				RunID:           runID,
				SplitIndex:     int64(sp.SplitIndex),
				Distance:        sp.Distance,
				Time:            sp.Time,
				Pace:            sp.Pace,
				AvgHeartRate:    sp.AvgHeartRate,
				AvgCadence:      sp.AvgCadence,
				AvgStrideLength: sp.AvgStrideLength,
				ElevationGain:   sp.ElevationGain,
				ElevationLoss:   sp.ElevationLoss,
			}
		}
		if err := s.runRepo.CreateSplits(ctx, splits); err != nil {
			return nil, err
		}
	}

	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user != nil {
		user.TotalDistance += req.TotalDistance
		user.TotalRuns++
		user.TotalTime += req.TotalTime
		if req.Calories != nil {
			user.TotalCalories += int64(*req.Calories)
		}
		if err := s.userRepo.Update(ctx, user); err != nil {
			return nil, err
		}
	}

	// 跑完步后检查跑境晋升
	if s.paojingSvc != nil {
		// 使用 goroutine 避免阻塞主流程
		go func() {
			ctx := context.Background()
			if run.TotalDistance != nil && *run.TotalDistance >= 42.195 && run.TotalTime != nil {
				s.paojingSvc.UpdateBestMarathon(ctx, userID, int64(*run.TotalTime))
			} else {
				s.paojingSvc.CheckRealmUpgrade(ctx, userID)
			}
		}()
	}

	// 如果关联了路线，更新排行榜（打卡次数+1）
	if run.RouteID != nil && *run.RouteID != "" {
		board := &model.Leaderboard{
			ID:         uuid.New().String(),
			RouteID:    *run.RouteID,
			UserID:     userID,
			RunID:      runID,
			TotalTime:  req.TotalTime,
			AvgPace:    req.AvgPace,
			RunCount:   1,
			RecordedAt: time.Now(),
		}
		_ = s.lbRepo.Upsert(ctx, board)
	}

	// 🆕 自动路线匹配：如果跑步未关联路线，尝试自动匹配附近的路线
	var match *MatchResult
	if run.RouteID == nil || *run.RouteID == "" {
		m, err := s.AutoMatchRoute(ctx, runID)
		if err != nil {
			log.Printf("[match] run=%s auto-match failed: %v", runID[:8], err)
		} else if m != nil {
			log.Printf("[match] run=%s auto-matched route=%s overlap=%.1f%%",
				runID[:8], m.RouteID[:8], m.Overlap*100)
			if err := s.ApplyMatch(ctx, runID, userID, m,
				req.TotalTime, req.AvgPace); err != nil {
				log.Printf("[match] run=%s apply-match failed: %v", runID[:8], err)
			} else {
				match = m
			}
		}
	}

	return match, nil
}


func (s *RunService) GetRunList(ctx context.Context, userID string, page, pageSize int) ([]RunListItem, int64, error) {
	runs, total, err := s.runRepo.ListByUserID(ctx, userID, page, pageSize)
	if err != nil {
		return nil, 0, err
	}

	items := make([]RunListItem, len(runs))
	for i, r := range runs {
		items[i] = RunListItem{
			ID:            r.ID,
			Mode:          r.Mode,
			StartTime:     r.StartTime,
			EndTime:       r.EndTime,
			TotalTime:     r.TotalTime,
			TotalDistance: r.TotalDistance,
			AvgPace:       r.AvgPace,
			Calories:      r.Calories,
			CreatedAt:     r.CreatedAt,
		}
	}

	return items, total, nil
}

// GetRunAverages 获取用户历史跑步平均值
func (s *RunService) GetRunAverages(ctx context.Context, userID string) (*model.RunAverages, error) {
	return s.runRepo.GetRunAverages(ctx, userID)
}

func (s *RunService) GetRunDetail(ctx context.Context, runID string, userID string) (*RunDetail, error) {
	run, err := s.runRepo.FindByID(ctx, runID)
	if err != nil {
		return nil, err
	}
	if run == nil {
		return nil, errors.New("run not found")
	}
	if run.UserID != userID {
		return nil, errors.New("permission denied")
	}

	samples, err := s.sampleRepo.ListByRunID(ctx, runID)
	if err != nil {
		return nil, err
	}

	detail := &RunDetail{
		Run:     *run,
		Samples: samples,
	}

	// 查询是否有关联的伴跑/挑战对比报告
	comparison, err := s.challengeRepo.FindComparisonByRunID(ctx, runID)
	if err != nil {
		// 查询失败不影响主流程
		return detail, nil
	}
	if comparison != nil {
		// 传递挑战指标（goal_metric），用于前端突出显示
		if comparison.Challenge != nil && comparison.Challenge.GoalMetric != nil {
			detail.GoalMetric = comparison.Challenge.GoalMetric
		}

		var opponentID string
		if comparison.RunAID == runID && comparison.RunBID != "" {
			opponentID = comparison.RunBID
		} else if comparison.RunBID == runID && comparison.RunAID != "" {
			opponentID = comparison.RunAID
		}
		if opponentID != "" {
			opponent, err := s.runRepo.FindByID(ctx, opponentID)
			if err == nil && opponent != nil {
				detail.OpponentRun = opponent
				// 同时加载对手的GPS采样点（用于地图上显示轨迹）
				oppSamples, err := s.sampleRepo.ListByRunID(ctx, opponentID)
				if err == nil {
					detail.OpponentSamples = oppSamples
				}
			}
		}
	}

	return detail, nil
}

// ---------------------------------------------------------------------------
// 跑友跑迹收藏
// ---------------------------------------------------------------------------

func (s *RunService) BookmarkRun(ctx context.Context, userID, runID string) error {
	// Check run exists
	run, err := s.runRepo.FindByID(ctx, runID)
	if err != nil {
		return err
	}
	if run == nil {
		return errors.New("run not found")
	}

	// Check not already bookmarked
	existing, err := s.bmRepo.FindByUserAndRun(ctx, userID, runID)
	if err != nil {
		return err
	}
	if existing != nil {
		return errors.New("already bookmarked")
	}

	bm := &model.RunBookmark{
		ID:        uuid.New().String(),
		UserID:    userID,
		RunID:     runID,
		CreatedAt: time.Now(),
	}
	return s.bmRepo.Create(ctx, bm)
}

func (s *RunService) UnbookmarkRun(ctx context.Context, userID, runID string) error {
	return s.bmRepo.Delete(ctx, userID, runID)
}

func (s *RunService) ListBookmarks(ctx context.Context, userID string) ([]model.RunBookmark, error) {
	return s.bmRepo.ListByUser(ctx, userID)
}

// ---------------------------------------------------------------------------
// 伴跑完成（轻量，不保存跑步记录，仅更新热度）
// ---------------------------------------------------------------------------

func (s *RunService) DeleteRun(ctx context.Context, runID string, userID string) error {
	run, err := s.runRepo.FindByID(ctx, runID)
	if err != nil {
		return err
	}
	if run == nil {
		return errors.New("run not found")
	}
	if run.UserID != userID {
		return errors.New("permission denied")
	}
	// 只允许删除未完成的空跑记录
	if run.EndTime != nil {
		return errors.New("cannot delete finished run")
	}
	return s.runRepo.Delete(ctx, runID)
}

func (s *RunService) CompanionRunComplete(ctx context.Context, userID string, targetRunID string) error {
	// 验证目标跑步记录存在
	run, err := s.runRepo.FindByID(ctx, targetRunID)
	if err != nil {
		return err
	}
	if run == nil {
		return errors.New("target run not found")
	}

	// 不能伴跑自己的跑迹
	if run.UserID == userID {
		return errors.New("cannot companion your own run")
	}

	// 目标跑迹热度 +1
	if err := s.runRepo.IncrementHeatCount(ctx, targetRunID); err != nil {
		return err
	}

	// 跑境：伴跑次数 +1 并检查晋级
	if s.paojingSvc != nil {
		go func() {
			bgCtx := context.Background()
			s.paojingSvc.IncrementCompanionRun(bgCtx, userID)
			s.paojingSvc.CheckRealmUpgrade(bgCtx, userID)
		}()
	}

	return nil
}
