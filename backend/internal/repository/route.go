package repository

import (
	"context"
	"errors"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

// ==================== Route Repository ====================

type RouteRepository struct {
	db *gorm.DB
}

func NewRouteRepository(db *gorm.DB) *RouteRepository {
	return &RouteRepository{db: db}
}

func (r *RouteRepository) Create(ctx context.Context, route *model.Route) error {
	return r.db.WithContext(ctx).Create(route).Error
}

func (r *RouteRepository) FindByID(ctx context.Context, id string) (*model.Route, error) {
	var route model.Route
	err := r.db.WithContext(ctx).
		Where("deleted_at IS NULL").
		Preload("Creator").
		First(&route, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &route, nil
}

func (r *RouteRepository) List(ctx context.Context, filter RouteFilter) ([]model.Route, int64, error) {
	var routes []model.Route
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Route{}).
		Where("status = ? AND is_public = ?", 1, true).
		Where("deleted_at IS NULL")

	if filter.City != "" {
		db = db.Where("city = ?", filter.City)
	}
	if filter.Difficulty > 0 {
		db = db.Where("difficulty = ?", filter.Difficulty)
	}
	if filter.DistanceMin > 0 {
		db = db.Where("distance >= ?", filter.DistanceMin)
	}
	if filter.DistanceMax > 0 {
		db = db.Where("distance <= ?", filter.DistanceMax)
	}
	if filter.Keyword != "" {
		db = db.Where("name LIKE ? OR description LIKE ?", "%"+filter.Keyword+"%", "%"+filter.Keyword+"%")
	}

	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (filter.Page - 1) * filter.PageSize
	db = db.Offset(offset).Limit(filter.PageSize)

	switch filter.SortBy {
	case "popularity":
		db = db.Order("popularity DESC")
	case "rating":
		db = db.Order("rating DESC")
	case "distance":
		db = db.Order("distance ASC")
	default:
		db = db.Order("created_at DESC")
	}

	err := db.Preload("Points", func(db *gorm.DB) *gorm.DB {
		return db.Order("point_index ASC")
	}).Find(&routes).Error
	return routes, total, err
}

func (r *RouteRepository) Update(ctx context.Context, route *model.Route) error {
	return r.db.WithContext(ctx).Save(route).Error
}

func (r *RouteRepository) Delete(ctx context.Context, id string) error {
	return r.db.WithContext(ctx).Delete(&model.Route{}, "id = ?", id).Error
}

func (r *RouteRepository) IncrementPopularity(ctx context.Context, routeID string) error {
	return r.db.WithContext(ctx).Model(&model.Route{}).
		Where("id = ?", routeID).
		UpdateColumn("popularity", gorm.Expr("popularity + 1")).Error
}

func (r *RouteRepository) RateRoute(ctx context.Context, routeID string, newRating float64) error {
	var route model.Route
	if err := r.db.WithContext(ctx).First(&route, "id = ?", routeID).Error; err != nil {
		return err
	}
	newAvg := (route.Rating*float64(route.RatingCount) + newRating) / float64(route.RatingCount+1)
	return r.db.WithContext(ctx).Model(&model.Route{}).Where("id = ?", routeID).
		Updates(map[string]interface{}{
			"rating":       newAvg,
			"rating_count": route.RatingCount + 1,
		}).Error
}

func (r *RouteRepository) NearbyRoutes(ctx context.Context, lat, lng, radius float64, limit int) ([]model.Route, error) {
	latDelta := radius / 111000.0
	lngDelta := radius / 78000.0

	var routes []model.Route
	err := r.db.WithContext(ctx).
		Where("status = ? AND is_public = ?", 1, true).
		Where("deleted_at IS NULL").
		Where("center_lat BETWEEN ? AND ?", lat-latDelta, lat+latDelta).
		Where("center_lng BETWEEN ? AND ?", lng-lngDelta, lng+lngDelta).
		Order("popularity DESC").
		Limit(limit).
		Find(&routes).Error
	return routes, err
}

// ==================== RoutePoint Repository ====================

func (r *RouteRepository) BatchCreatePoints(ctx context.Context, points []model.RoutePoint) error {
	if len(points) == 0 {
		return nil
	}
	return r.db.WithContext(ctx).CreateInBatches(points, 200).Error
}

func (r *RouteRepository) FindPointsByRouteID(ctx context.Context, routeID string) ([]model.RoutePoint, error) {
	var points []model.RoutePoint
	err := r.db.WithContext(ctx).
		Where("route_id = ?", routeID).
		Order("point_index ASC").
		Find(&points).Error
	return points, err
}

// FindDuplicates 查找疑似重复路线：同城市 + 距离差 < 20%
// 返回 id, name, distance
func (r *RouteRepository) FindDuplicates(ctx context.Context, city string, distance float64, excludeCreatorID string, limit int) ([]DuplicateRoute, error) {
	if city == "" || distance <= 0 {
		return nil, nil
	}
	minDist := distance * 0.8
	maxDist := distance * 1.2
	var results []DuplicateRoute
	// 优先按相似度排序（距离差最小的在前）
	err := r.db.WithContext(ctx).
		Model(&model.Route{}).
		Select("id, name, distance, ABS(distance - ?) as dist_diff", distance).
		Where("city = ? AND status = 1 AND deleted_at IS NULL", city).
		Where("distance BETWEEN ? AND ?", minDist, maxDist).
		Where("creator_id != ?", excludeCreatorID).
		Order("dist_diff ASC").
		Limit(limit).
		Find(&results).Error
	if err != nil {
		return nil, err
	}
	return results, nil
}

type DuplicateRoute struct {
	ID       string  `gorm:"column:id"`
	Name     string  `gorm:"column:name"`
	Distance float64 `gorm:"column:distance"`
}

func (r *RouteRepository) DeletePointsByRouteID(ctx context.Context, routeID string) error {
	return r.db.WithContext(ctx).Where("route_id = ?", routeID).Delete(&model.RoutePoint{}).Error
}

// ==================== Favorite Repository ====================

type FavoriteRepository struct {
	db *gorm.DB
}

func NewFavoriteRepository(db *gorm.DB) *FavoriteRepository {
	return &FavoriteRepository{db: db}
}

func (r *FavoriteRepository) Create(ctx context.Context, fav *model.Favorite) error {
	return r.db.WithContext(ctx).Create(fav).Error
}

func (r *FavoriteRepository) FindByUserAndRoute(ctx context.Context, userID, routeID string) (*model.Favorite, error) {
	var fav model.Favorite
	err := r.db.WithContext(ctx).Where("user_id = ? AND route_id = ?", userID, routeID).First(&fav).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &fav, nil
}

func (r *FavoriteRepository) DeleteByUserAndRoute(ctx context.Context, userID, routeID string) error {
	return r.db.WithContext(ctx).Where("user_id = ? AND route_id = ?", userID, routeID).Delete(&model.Favorite{}).Error
}

func (r *FavoriteRepository) ListByUserID(ctx context.Context, userID string, page, pageSize int) ([]model.Favorite, int64, error) {
	var favorites []model.Favorite
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Favorite{}).Where("user_id = ?", userID)
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err := db.Preload("Route.Creator").Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&favorites).Error
	return favorites, total, err
}

// ==================== Leaderboard Repository ====================

type LeaderboardRepository struct {
	db *gorm.DB
}

func NewLeaderboardRepository(db *gorm.DB) *LeaderboardRepository {
	return &LeaderboardRepository{db: db}
}

func (r *LeaderboardRepository) ListByRouteID(ctx context.Context, routeID string, page, pageSize int, sortBy string) ([]model.Leaderboard, int64, error) {
	var boards []model.Leaderboard
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Leaderboard{}).Where("route_id = ?", routeID)
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize

	// 支持排序：time_asc = 成绩榜（用时最短排第一），默认 = 打卡榜（次数最多排第一）
	orderClause := "run_count DESC, created_at ASC"
	if sortBy == "time_asc" {
		orderClause = "total_time ASC, run_count DESC"
	}

	err := db.Preload("User").Order(orderClause).Offset(offset).Limit(pageSize).Find(&boards).Error
	return boards, total, err
}

func (r *LeaderboardRepository) Upsert(ctx context.Context, board *model.Leaderboard) error {
	var existing model.Leaderboard
	err := r.db.WithContext(ctx).Where("route_id = ? AND user_id = ?", board.RouteID, board.UserID).First(&existing).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return r.db.WithContext(ctx).Create(board).Error
		}
		return err
	}
	// 保留最好成绩（最小用时）
	bestTime := existing.TotalTime
	if board.TotalTime < bestTime {
		bestTime = board.TotalTime
	}
	return r.db.WithContext(ctx).Model(&existing).Updates(map[string]interface{}{
		"run_id":      board.RunID,
		"total_time":  bestTime,
		"avg_pace":    board.AvgPace,
		"run_count":   gorm.Expr("run_count + 1"),
		"recorded_at": board.RecordedAt,
	}).Error
}

// ==================== Filter ====================

type RouteFilter struct {
	Page        int
	PageSize    int
	City        string
	Difficulty  int8
	DistanceMin float64
	DistanceMax float64
	Keyword     string
	SortBy      string
}
