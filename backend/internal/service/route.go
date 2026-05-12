package service

import (
	"context"
	"errors"
	"regexp"
	"strings"
	"unicode"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"

	"github.com/google/uuid"
)

type RouteService struct {
	routeRepo   *repository.RouteRepository
	favRepo     *repository.FavoriteRepository
	lbRepo      *repository.LeaderboardRepository
}

func NewRouteService(
	routeRepo *repository.RouteRepository,
	favRepo *repository.FavoriteRepository,
	lbRepo *repository.LeaderboardRepository,
) *RouteService {
	return &RouteService{
		routeRepo:   routeRepo,
		favRepo:     favRepo,
		lbRepo:      lbRepo,
	}
}

// ==================== Create Route ====================

type CreateRouteRequest struct {
	Name            string          `json:"name" binding:"required,min=1,max=100"`
	Description     *string         `json:"description"`
	Distance        float64         `json:"distance" binding:"required,min=0"`
	ElevationGain   float64         `json:"elevation_gain"`
	ElevationLoss   float64         `json:"elevation_loss"`
	AvgPace         *int            `json:"avg_pace"`
	AvgCadence      *int            `json:"avg_cadence"`
	AvgStride       *float64        `json:"avg_stride"`
	Calories        *int            `json:"calories"`
	AvgHeartRate    *int            `json:"avg_heart_rate"`
	TotalTime       *int64          `json:"total_time"`
	MaxHeartRate    *int16          `json:"max_heart_rate"`
	MaxCadence      *int16          `json:"max_cadence"`
	Difficulty      *int8           `json:"difficulty"`
	Tags            []string        `json:"tags"`
	City            *string         `json:"city"`
	StartLat        *float64        `json:"start_lat"`
	StartLng        *float64        `json:"start_lng"`
	CenterLat       *float64        `json:"center_lat"`
	CenterLng       *float64        `json:"center_lng"`
	Points          []RoutePointReq `json:"points" binding:"required,min=2,max=10000"`
}

type RoutePointReq struct {
	Latitude  float64  `json:"latitude" binding:"required"`
	Longitude float64  `json:"longitude" binding:"required"`
	Altitude  *float64 `json:"altitude"`
}

func (s *RouteService) CreateRoute(ctx context.Context, creatorID string, req *CreateRouteRequest) (*model.Route, error) {
	route := &model.Route{
		ID:            uuid.New().String(),
		CreatorID:     creatorID,
		Name:          req.Name,
		Description:   req.Description,
		Distance:      req.Distance,
		ElevationGain: req.ElevationGain,
		ElevationLoss: req.ElevationLoss,
		AvgPace:        func() int { if req.AvgPace != nil { return *req.AvgPace }; return 0 }(),
		AvgCadence:     func() int { if req.AvgCadence != nil { return *req.AvgCadence }; return 0 }(),
		AvgStride:      func() float64 { if req.AvgStride != nil { return *req.AvgStride }; return 0 }(),
		Calories:       func() int { if req.Calories != nil { return *req.Calories }; return 0 }(),
		AvgHeartRate:   func() int { if req.AvgHeartRate != nil { return *req.AvgHeartRate }; return 0 }(),
		TotalTime:      req.TotalTime,
		MaxHeartRate:   req.MaxHeartRate,
		MaxCadence:     req.MaxCadence,
		Difficulty:     func() int8 { if req.Difficulty != nil { return *req.Difficulty }; return 1 }(),
		Tags:          marshalTags(req.Tags),
		City:          req.City,
		StartLat:      req.StartLat,
		StartLng:      req.StartLng,
		CenterLat:     req.CenterLat,
		CenterLng:     req.CenterLng,
		IsPublic:      true,
		Status:        1,
	}

	if err := s.routeRepo.Create(ctx, route); err != nil {
		return nil, err
	}

	// 保存坐标点
	if len(req.Points) > 0 {
		points := make([]model.RoutePoint, len(req.Points))
		for i, p := range req.Points {
			points[i] = model.RoutePoint{
				RouteID:    route.ID,
				PointIndex: i,
				Latitude:   p.Latitude,
				Longitude:  p.Longitude,
				Altitude:   p.Altitude,
			}
		}
		if err := s.routeRepo.BatchCreatePoints(ctx, points); err != nil {
			return nil, err
		}
	}

	return route, nil
}

// ==================== Validate Route ====================

type ValidateRouteRequest struct {
	Name     string  `json:"name" binding:"required"`
	City     string  `json:"city"`
	Distance float64 `json:"distance" binding:"required"`
	Points   []struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	} `json:"points"`
}

type ValidateRouteResponse struct {
	Passed     bool              `json:"passed"`
	Flags      []string          `json:"flags"`           // "invalid_name", "no_gps", "duplicate", "distance_zero"
	Reason     string            `json:"reason"`          // Human readable
	Duplicates []DuplicateInfo   `json:"duplicates"`      // 疑似重复路线列表
}

type DuplicateInfo struct {
	ID       string  `json:"id"`
	Name     string  `json:"name"`
	Distance float64 `json:"distance"`
	Diff     float64 `json:"diff"`  // 距离差百分比
}

func (s *RouteService) ValidateRoute(ctx context.Context, creatorID string, req *ValidateRouteRequest) (*ValidateRouteResponse, error) {
	resp := &ValidateRouteResponse{Passed: true, Flags: []string{}, Duplicates: []DuplicateInfo{}}

	// 1. 校验名称格式
	nameFlags, nameReason := validateRouteName(req.Name)
	if len(nameFlags) > 0 {
		resp.Passed = false
		resp.Flags = append(resp.Flags, nameFlags...)
		resp.Reason = nameReason
	}

	// 2. 校验距离
	if req.Distance <= 0 {
		resp.Passed = false
		resp.Flags = append(resp.Flags, "distance_zero")
		resp.Reason = "距离必须大于0"
	} else if req.Distance > 500000 { // 500km
		resp.Passed = false
		resp.Flags = append(resp.Flags, "distance_too_large")
		resp.Reason = "距离超出合理范围（最大500km）"
	}

	// 3. 校验GPS点数量
	if len(req.Points) < 2 {
		resp.Passed = false
		resp.Flags = append(resp.Flags, "no_gps")
		if resp.Reason == "" {
			resp.Reason = "GPS轨迹点不足，需要至少2个点"
		}
	}

	// 4. 重复路线检测（即使名称不通过也检测，帮助提示用户）
	if req.City != "" && req.Distance > 0 {
		if dupes, err := s.routeRepo.FindDuplicates(ctx, req.City, req.Distance, creatorID, 3); err == nil && len(dupes) > 0 {
			for _, d := range dupes {
				diff := 0.0
				if req.Distance > 0 {
					diff = (d.Distance - req.Distance) / req.Distance * 100
					if diff < 0 {
						diff = -diff
					}
				}
				resp.Duplicates = append(resp.Duplicates, DuplicateInfo{
					ID:       d.ID,
					Name:     d.Name,
					Distance: d.Distance,
					Diff:     diff,
				})
			}
			// 重复是警告，不是阻止
			if !containsFlag(resp.Flags, "duplicate") {
				resp.Flags = append(resp.Flags, "duplicate")
			}
		}
	}

	if resp.Reason == "" && !resp.Passed {
		resp.Reason = "路线信息不符合规范，请检查后重试"
	}

	return resp, nil
}

// validateRouteName 检查路线名称规范
// 返回 flags 列表和原因
func validateRouteName(name string) ([]string, string) {
	var flags []string
	runes := []rune(name)

	// 1. 长度检查
	if len(runes) < 4 {
		flags = append(flags, "name_too_short")
		return flags, "路线名称太短，至少需要4个字符"
	}
	if len(runes) > 30 {
		flags = append(flags, "name_too_long")
		return flags, "路线名称太长，最多30个字符"
	}

	// 2. 不能是纯数字
	if isPureNumber(name) {
		flags = append(flags, "name_pure_number")
		return flags, "路线名称不能是纯数字，请包含地名或描述"
	}

	// 3. 必须包含中文或英文字符（不能是纯符号/emoji）
	hasChineseOrAlpha := false
	for _, r := range runes {
		if unicode.Is(unicode.Han, r) || unicode.IsLetter(r) {
			hasChineseOrAlpha = true
			break
		}
	}
	if !hasChineseOrAlpha {
		flags = append(flags, "invalid_name")
		return flags, "路线名称必须包含中文或英文字符，不能使用纯符号或表情"
	}

	// 4. 必须包含数字（距离提示）
	hasDigit := regexp.MustCompile(`\d`).MatchString(name)
	if !hasDigit {
		flags = append(flags, "name_no_distance")
		return flags, "路线名称应包含距离，如「5公里」或「5km」"
	}

	return nil, ""
}

func isPureNumber(name string) bool {
	// 匹配纯数字（可含小数点）
	return regexp.MustCompile(`^\d+(\.\d+)?$`).MatchString(strings.TrimSpace(name))
}

func containsFlag(flags []string, flag string) bool {
	for _, f := range flags {
		if f == flag {
			return true
		}
	}
	return false
}

// ==================== List Routes ====================

type RouteListRequest struct {
	Page        int     `json:"page" form:"page"`
	PageSize    int     `json:"page_size" form:"page_size"`
	City        string  `json:"city" form:"city"`
	Difficulty  int8    `json:"difficulty" form:"difficulty"`
	DistanceMin float64 `json:"distance_min" form:"distance_min"`
	DistanceMax float64 `json:"distance_max" form:"distance_max"`
	Keyword     string  `json:"keyword" form:"keyword"`
	SortBy      string  `json:"sort_by" form:"sort_by"`
}

type RouteListItem struct {
	model.Route
	IsFavorited bool `json:"is_favorited"`
}

func (s *RouteService) ListRoutes(ctx context.Context, req RouteListRequest, userID string) ([]RouteListItem, int64, error) {
	if req.Page < 1 {
		req.Page = 1
	}
	if req.PageSize < 1 || req.PageSize > 50 {
		req.PageSize = 10
	}

	filter := repository.RouteFilter{
		Page:        req.Page,
		PageSize:    req.PageSize,
		City:        req.City,
		Difficulty:  req.Difficulty,
		DistanceMin: req.DistanceMin,
		DistanceMax: req.DistanceMax,
		Keyword:     req.Keyword,
		SortBy:      req.SortBy,
	}

	routes, total, err := s.routeRepo.List(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	items := make([]RouteListItem, len(routes))
	for i, r := range routes {
		items[i] = RouteListItem{Route: r}
		if userID != "" {
			fav, _ := s.favRepo.FindByUserAndRoute(ctx, userID, r.ID)
			items[i].IsFavorited = fav != nil
		}
	}

	return items, total, nil
}

// ==================== Route Detail ====================

type RouteDetail struct {
	Route       model.Route       `json:"route"`
	Points      []model.RoutePoint `json:"points"`
	IsFavorited bool              `json:"is_favorited"`
	FavCount    int64             `json:"fav_count"`
}

func (s *RouteService) GetRouteDetail(ctx context.Context, routeID string, userID string) (*RouteDetail, error) {
	route, err := s.routeRepo.FindByID(ctx, routeID)
	if err != nil {
		return nil, err
	}
	if route == nil {
		return nil, errors.New("route not found")
	}

	points, err := s.routeRepo.FindPointsByRouteID(ctx, routeID)
	if err != nil {
		return nil, err
	}

	detail := &RouteDetail{
		Route:  *route,
		Points: points,
	}

	if userID != "" {
		fav, _ := s.favRepo.FindByUserAndRoute(ctx, userID, routeID)
		detail.IsFavorited = fav != nil
	}

	return detail, nil
}

// ==================== Favorite ====================

func (s *RouteService) FavoriteRoute(ctx context.Context, userID, routeID string) error {
	// 检查路线是否存在
	route, err := s.routeRepo.FindByID(ctx, routeID)
	if err != nil {
		return err
	}
	if route == nil {
		return errors.New("route not found")
	}

	// 检查是否已收藏
	existing, err := s.favRepo.FindByUserAndRoute(ctx, userID, routeID)
	if err != nil {
		return err
	}
	if existing != nil {
		return errors.New("already favorited")
	}

	fav := &model.Favorite{
		ID:      uuid.New().String(),
		UserID:  userID,
		RouteID: routeID,
	}
	if err := s.favRepo.Create(ctx, fav); err != nil {
		return err
	}

	// 增加路线热度
	_ = s.routeRepo.IncrementPopularity(ctx, routeID)
	return nil
}

func (s *RouteService) UnfavoriteRoute(ctx context.Context, userID, routeID string) error {
	return s.favRepo.DeleteByUserAndRoute(ctx, userID, routeID)
}

func (s *RouteService) ListFavorites(ctx context.Context, userID string, page, pageSize int) ([]model.Favorite, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 10
	}
	return s.favRepo.ListByUserID(ctx, userID, page, pageSize)
}

// ==================== Delete Route ====================

func (s *RouteService) DeleteRoute(ctx context.Context, routeID, userID string) error {
	route, err := s.routeRepo.FindByID(ctx, routeID)
	if err != nil {
		return err
	}
	if route == nil {
		return errors.New("route not found")
	}
	if route.CreatorID != userID {
		return errors.New("permission denied")
	}
	return s.routeRepo.Delete(ctx, routeID)
}

// ==================== Leaderboard ====================

func (s *RouteService) GetLeaderboard(ctx context.Context, routeID string, page, pageSize int, sortBy string) ([]model.Leaderboard, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}
	return s.lbRepo.ListByRouteID(ctx, routeID, page, pageSize, sortBy)
}

// ==================== Rate Route ====================

func (s *RouteService) RateRoute(ctx context.Context, routeID string, userID string, rating float64) error {
	if rating < 0 || rating > 5 {
		return errors.New("rating must be between 0 and 5")
	}
	route, err := s.routeRepo.FindByID(ctx, routeID)
	if err != nil {
		return err
	}
	if route == nil {
		return errors.New("route not found")
	}
	return s.routeRepo.RateRoute(ctx, routeID, rating)
}

// ==================== Update Route ====================

type UpdateRouteRequest struct {
	Name          *string          `json:"name"`
	Description   *string          `json:"description"`
	Distance      *float64         `json:"distance"`
	ElevationGain *float64         `json:"elevation_gain"`
	ElevationLoss *float64         `json:"elevation_loss"`
	Difficulty    *int8            `json:"difficulty"`
	Tags          []string         `json:"tags"`
	City          *string          `json:"city"`
	StartLat      *float64         `json:"start_lat"`
	StartLng      *float64         `json:"start_lng"`
	CenterLat     *float64         `json:"center_lat"`
	CenterLng     *float64         `json:"center_lng"`
	Points        []RoutePointReq  `json:"points"`
}

func (s *RouteService) UpdateRoute(ctx context.Context, routeID, userID string, req *UpdateRouteRequest) error {
	route, err := s.routeRepo.FindByID(ctx, routeID)
	if err != nil {
		return err
	}
	if route == nil {
		return errors.New("route not found")
	}
	if route.CreatorID != userID {
		return errors.New("permission denied")
	}

	if req.Name != nil {
		route.Name = *req.Name
	}
	if req.Description != nil {
		route.Description = req.Description
	}
	if req.Distance != nil {
		route.Distance = *req.Distance
	}
	if req.ElevationGain != nil {
		route.ElevationGain = *req.ElevationGain
	}
	if req.ElevationLoss != nil {
		route.ElevationLoss = *req.ElevationLoss
	}
	if req.Difficulty != nil {
		route.Difficulty = *req.Difficulty
	}
	if len(req.Tags) > 0 {
		route.Tags = marshalTags(req.Tags)
	}
	if req.City != nil {
		route.City = req.City
	}
	if req.StartLat != nil {
		route.StartLat = req.StartLat
	}
	if req.StartLng != nil {
		route.StartLng = req.StartLng
	}
	if req.CenterLat != nil {
		route.CenterLat = req.CenterLat
	}
	if req.CenterLng != nil {
		route.CenterLng = req.CenterLng
	}

	if err := s.routeRepo.Update(ctx, route); err != nil {
		return err
	}

	// 如果传了新坐标点，先删旧点再插入新点
	if len(req.Points) > 0 {
		if err := s.routeRepo.DeletePointsByRouteID(ctx, routeID); err != nil {
			return err
		}
		points := make([]model.RoutePoint, len(req.Points))
		for i, p := range req.Points {
			points[i] = model.RoutePoint{
				RouteID:    routeID,
				PointIndex: i,
				Latitude:   p.Latitude,
				Longitude:  p.Longitude,
				Altitude:   p.Altitude,
			}
		}
		if err := s.routeRepo.BatchCreatePoints(ctx, points); err != nil {
			return err
		}
	}

	return nil
}

// ==================== Nearby Routes ====================

func (s *RouteService) NearbyRoutes(ctx context.Context, lat, lng, radius float64, limit int) ([]model.Route, error) {
	if limit < 1 || limit > 50 {
		limit = 20
	}
	return s.routeRepo.NearbyRoutes(ctx, lat, lng, radius, limit)
}

// ==================== Helper ====================

func marshalTags(tags []string) string {
	if len(tags) == 0 {
		return "[]"
	}
	result := "["
	for i, t := range tags {
		if i > 0 {
			result += ","
		}
		result += "\"" + t + "\""
	}
	result += "]"
	return result
}
