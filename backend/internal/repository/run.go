package repository

import (
	"context"
	"errors"
	"time"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

type RunRepository struct {
	db *gorm.DB
}

func NewRunRepository(db *gorm.DB) *RunRepository {
	return &RunRepository{db: db}
}

func (r *RunRepository) Create(ctx context.Context, run *model.Run) error {
	return r.db.WithContext(ctx).Create(run).Error
}

func (r *RunRepository) FindByID(ctx context.Context, id string) (*model.Run, error) {
	var run model.Run
	err := r.db.WithContext(ctx).
		Where("deleted_at IS NULL").
		Preload("Splits").
		Preload("Route").
		First(&run, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &run, nil
}

func (r *RunRepository) ListByUserID(ctx context.Context, userID string, page, pageSize int) ([]model.Run, int64, error) {
	var runs []model.Run
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Run{}).
		Where("user_id = ? AND deleted_at IS NULL", userID)
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err := db.Order("start_time DESC").Offset(offset).Limit(pageSize).Find(&runs).Error
	if err != nil {
		return nil, 0, err
	}

	return runs, total, nil
}

func (r *RunRepository) Update(ctx context.Context, run *model.Run) error {
	return r.db.WithContext(ctx).Save(run).Error
}

func (r *RunRepository) UpdateRouteID(ctx context.Context, runID, routeID string) error {
	return r.db.WithContext(ctx).Model(&model.Run{}).
		Where("id = ?", runID).
		UpdateColumn("route_id", routeID).Error
}

func (r *RunRepository) IncrementHeatCount(ctx context.Context, runID string) error {
	return r.db.WithContext(ctx).Model(&model.Run{}).Where("id = ?", runID).
		UpdateColumn("heat_count", gorm.Expr("heat_count + 1")).Error
}

func (r *RunRepository) Delete(ctx context.Context, id string) error {
	// 级联删除关联的采样点和分段
	_ = r.db.WithContext(ctx).Where("run_id = ?", id).Delete(&model.RunSample{}).Error
	_ = r.db.WithContext(ctx).Where("run_id = ?", id).Delete(&model.RunSplit{}).Error
	_ = r.db.WithContext(ctx).Where("run_id = ?", id).Delete(&model.RunBookmark{}).Error
	return r.db.WithContext(ctx).Delete(&model.Run{}, "id = ?", id).Error
}

// GetRecentByUser 获取用户最近的跑步记录（用于AI分析的历史数据）
func (r *RunRepository) GetRecentByUser(ctx context.Context, userID string, limit int) ([]model.Run, error) {
	var runs []model.Run
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND deleted_at IS NULL", userID).
		Order("start_time DESC").
		Limit(limit).
		Find(&runs).Error
	if err != nil {
		return nil, err
	}
	return runs, nil
}

// GetRunsInDays 获取用户近N天的跑步记录（时间范围过滤）
func (r *RunRepository) GetRunsInDays(ctx context.Context, userID string, days int) ([]model.Run, error) {
	var runs []model.Run
	since := time.Now().AddDate(0, 0, -days)
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND start_time >= ? AND deleted_at IS NULL", userID, since).
		Order("start_time DESC").
		Find(&runs).Error
	if err != nil {
		return nil, err
	}
	return runs, nil
}

// PersonalBest 用户个人最佳记录（历史全量）
type PersonalBest struct {
	BestPace     int     // 最佳配速（秒/公里），越小越好
	BestDistance float64 // 最长距离（公里）
}

// GetPersonalBests 获取用户历史个人最佳记录（全量统计）
func (r *RunRepository) GetPersonalBests(ctx context.Context, userID string) (*PersonalBest, error) {
	pb := &PersonalBest{}

	// 最佳配速（MIN）
	r.db.WithContext(ctx).
		Model(&model.Run{}).
		Where("user_id = ? AND avg_pace > 0 AND deleted_at IS NULL", userID).
		Select("MIN(avg_pace) as best_pace").
		Scan(pb)

	// 最长距离（MAX）
	r.db.WithContext(ctx).
		Model(&model.Run{}).
		Where("user_id = ? AND total_distance > 0 AND deleted_at IS NULL", userID).
		Select("MAX(total_distance) as best_distance").
		Scan(pb)

	return pb, nil
}

func (r *RunRepository) CreateSplits(ctx context.Context, splits []model.RunSplit) error {
	if len(splits) == 0 {
		return nil
	}
	return r.db.WithContext(ctx).CreateInBatches(splits, 50).Error
}

// ==================== 导入记录相关 ====================

func (r *RunRepository) FindBySource(ctx context.Context, source, sourceID string) (*model.Run, error) {
	var rec model.ImportRecord
	err := r.db.WithContext(ctx).Where("source = ? AND source_id = ?", source, sourceID).First(&rec).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return r.FindByID(ctx, rec.RunID)
}

func (r *RunRepository) CreateImportRecord(ctx context.Context, rec *model.ImportRecord) error {
	return r.db.WithContext(ctx).Create(rec).Error
}

func (r *RunRepository) ListImportRecords(ctx context.Context, userID string) ([]model.ImportRecord, error) {
	var recs []model.ImportRecord
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).Order("imported_at DESC").Find(&recs).Error
	return recs, err
}

func (r *RunRepository) DeleteImportRecord(ctx context.Context, id, userID string) error {
	// 先查出来获取 run_id
	var rec model.ImportRecord
	if err := r.db.WithContext(ctx).Where("id = ? AND user_id = ?", id, userID).First(&rec).Error; err != nil {
		return err
	}
	// 删除导入记录
	if err := r.db.WithContext(ctx).Delete(&rec).Error; err != nil {
		return err
	}
	// 级联删除关联的跑步记录（及采样和分段）
	return r.Delete(ctx, rec.RunID)
}

func (r *RunRepository) UpdateUserStats(ctx context.Context, userID string, totalDistance float64, totalTime int64, calories *float64) error {
	updates := map[string]interface{}{
		"total_distance": gorm.Expr("COALESCE(total_distance,0) + ?", totalDistance),
		"total_runs":     gorm.Expr("total_runs + 1"),
		"total_time":     gorm.Expr("COALESCE(total_time,0) + ?", totalTime),
	}
	if calories != nil {
		updates["total_calories"] = gorm.Expr("COALESCE(total_calories,0) + ?", int64(*calories))
	}
	return r.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", userID).Updates(updates).Error
}

// ---------------------------------------------------------------------------
// RunBookmarkRepository 跑友跑迹收藏
// ---------------------------------------------------------------------------

type RunBookmarkRepository struct{ db *gorm.DB }

func NewRunBookmarkRepository(db *gorm.DB) *RunBookmarkRepository {
	return &RunBookmarkRepository{db: db}
}

// Create 添加收藏
func (r *RunBookmarkRepository) Create(ctx context.Context, bm *model.RunBookmark) error {
	return r.db.WithContext(ctx).Create(bm).Error
}

// Delete 取消收藏
func (r *RunBookmarkRepository) Delete(ctx context.Context, userID, runID string) error {
	return r.db.WithContext(ctx).Where("user_id = ? AND run_id = ?", userID, runID).Delete(&model.RunBookmark{}).Error
}

// FindByUserAndRun 查询是否已收藏
func (r *RunBookmarkRepository) FindByUserAndRun(ctx context.Context, userID, runID string) (*model.RunBookmark, error) {
	var bm model.RunBookmark
	err := r.db.WithContext(ctx).Where("user_id = ? AND run_id = ?", userID, runID).First(&bm).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &bm, nil
}

// CountByRunOwner 统计某用户的所有跑步记录被收藏了多少次
func (r *RunBookmarkRepository) CountByRunOwner(ctx context.Context, userID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.RunBookmark{}).
		Joins("JOIN runs ON runs.id = run_bookmarks.run_id").
		Where("runs.user_id = ?", userID).
		Count(&count).Error
	return count, err
}

// ListByUser 获取用户的所有收藏（含跑友信息和跑步数据）
func (r *RunBookmarkRepository) ListByUser(ctx context.Context, userID string) ([]model.RunBookmark, error) {
	var bms []model.RunBookmark
	err := r.db.WithContext(ctx).
		Preload("Run").
		Preload("Run.User").
		Preload("Run.Route").
		Preload("Run.Route.Points").
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Find(&bms).Error
	if err != nil {
		return nil, err
	}
	// 批量查询每个收藏跑迹的GPS范围（用于前端距离校验）
	for i := range bms {
		if bms[i].Run.ID != "" {
			bounds, err := r.GetRunBounds(ctx, bms[i].Run.ID)
			if err == nil && bounds != nil {
				bms[i].Run.Bounds = bounds
			}
		}
	}
	return bms, nil
}

// GetRunAverages 用户跑步历史平均值
func (r *RunRepository) GetRunAverages(ctx context.Context, userID string) (*model.RunAverages, error) {
	type rawAverages struct {
		AvgPace       float64 `json:"avg_pace"`
		AvgHeartRate  float64 `json:"avg_heart_rate"`
		AvgCadence    float64 `json:"avg_cadence"`
		AvgStride     float64 `json:"avg_stride_length"`
		RunCount      int64   `json:"run_count"`
	}
	var avg rawAverages
	err := r.db.WithContext(ctx).
		Table("runs").
		Select(`
			COALESCE(AVG(avg_pace), 0) AS avg_pace,
			COALESCE(AVG(avg_heart_rate), 0) AS avg_heart_rate,
			COALESCE(AVG(avg_cadence), 0) AS avg_cadence,
			COALESCE(AVG(avg_stride_length), 0) AS avg_stride_length,
			COUNT(*) AS run_count
		`).
		Where("user_id = ? AND total_time > 0", userID).
		Row().Scan(&avg.AvgPace, &avg.AvgHeartRate, &avg.AvgCadence, &avg.AvgStride, &avg.RunCount)
	if err != nil {
		return nil, err
	}
	return &model.RunAverages{
		AvgPace:       int(avg.AvgPace),
		AvgHeartRate:  int16(avg.AvgHeartRate),
		AvgCadence:    int16(avg.AvgCadence),
		AvgStride:     avg.AvgStride,
		RunCount:      avg.RunCount,
	}, nil
}

// GetRunBounds 查询某条跑步记录的GPS采样点范围
func (r *RunBookmarkRepository) GetRunBounds(ctx context.Context, runID string) (*model.RunBounds, error) {
	type boundsRow struct {
		MinLat float64 `json:"min_lat"`
		MaxLat float64 `json:"max_lat"`
		MinLng float64 `json:"min_lng"`
		MaxLng float64 `json:"max_lng"`
	}
	var row boundsRow
	err := r.db.WithContext(ctx).
		Table("run_samples").
		Select("MIN(latitude) AS min_lat, MAX(latitude) AS max_lat, MIN(longitude) AS min_lng, MAX(longitude) AS max_lng").
		Where("run_id = ?", runID).
		Row().Scan(&row.MinLat, &row.MaxLat, &row.MinLng, &row.MaxLng)
	if err != nil {
		if row.MinLat == 0 && row.MaxLat == 0 && row.MinLng == 0 && row.MaxLng == 0 {
			return nil, nil
		}
		return nil, err
	}
	return &model.RunBounds{
		MinLat: row.MinLat,
		MaxLat: row.MaxLat,
		MinLng: row.MinLng,
		MaxLng: row.MaxLng,
	}, nil
}
