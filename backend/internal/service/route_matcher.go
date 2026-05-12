package service

import (
	"context"
	"math"
	"sort"
	"time"

	"stridemoor-api/internal/model"

	"github.com/google/uuid"
)

const (
	// 匹配算法参数
	matchOverlapThreshold = 0.80     // 80% 重合即认定为匹配
	matchDistanceMeters   = 50.0     // 采样点与路点的最大距离（米）
	candidateRadiusMeters = 5000.0   // 候选路线搜索半径（米）
	downsampleTarget      = 200      // 跑者 GPS 降采样目标点数
)

// GPSPoint 简化的 GPS 坐标点
type GPSPoint struct {
	Lat float64
	Lng float64
}

// MatchResult 路线匹配结果
type MatchResult struct {
	RouteID string
	Route   *model.Route
	Overlap float64 // 重合率 0.0~1.0
	Matched int     // 匹配上的点数
	Total   int     // 比对的总点数
}

// haversine 计算两点间距离（米）
func haversine(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371000.0
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLng := (lng2 - lng1) * math.Pi / 180.0
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180.0)*math.Cos(lat2*math.Pi/180.0)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}

// downsamplePoints 降采样 GPS 点到目标数量
func downsamplePoints(samples []model.RunSample, target int) []GPSPoint {
	if len(samples) <= target {
		pts := make([]GPSPoint, len(samples))
		for i, s := range samples {
			pts[i] = GPSPoint{Lat: s.Latitude, Lng: s.Longitude}
		}
		return pts
	}
	step := float64(len(samples)-1) / float64(target-1)
	pts := make([]GPSPoint, target)
	for i := 0; i < target; i++ {
		idx := int(float64(i) * step)
		if idx >= len(samples) {
			idx = len(samples) - 1
		}
		pts[i] = GPSPoint{Lat: samples[idx].Latitude, Lng: samples[idx].Longitude}
	}
	return pts
}

// gridKey 为 GPS 点生成网格坐标（用于空间索引）
func gridKey(lat, lng float64, cellSize float64) (int, int) {
	return int(math.Floor(lat / cellSize)), int(math.Floor(lng / cellSize))
}

// buildGridIndex 构建路线点的空间网格索引
func buildGridIndex(points []model.RoutePoint, cellSize float64) map[[2]int][]model.RoutePoint {
	grid := make(map[[2]int][]model.RoutePoint)
	for _, p := range points {
		cellX, cellY := gridKey(p.Latitude, p.Longitude, cellSize)
		key := [2]int{cellX, cellY}
		grid[key] = append(grid[key], p)
	}
	return grid
}

// findMatchingRate 计算跑者 GPS 与路线 GPS 的重合比例
//
// 算法：
//  1. 将路线点按 0.0003°×0.0003°（≈30m）网格建立空间索引
//  2. 对每个跑者采样点，查找其所在网格及相邻 8 个网格中的路线点
//  3. 计算最近距离，≤30m 视为"匹配"
//  4. 匹配比例 = 匹配点数 / 总采样点数
func findMatchingRate(runPts []GPSPoint, routePts []model.RoutePoint) (matched, total int, overlap float64) {
	if len(runPts) == 0 || len(routePts) == 0 {
		return 0, 0, 0
	}

	cellSize := matchDistanceMeters / 111000.0 // 30m 对应的经纬度约 0.00027°
	grid := buildGridIndex(routePts, cellSize)

	matchedCount := 0
	for _, rp := range runPts {
		cellX, cellY := gridKey(rp.Lat, rp.Lng, cellSize)
		found := false

		// 检查 3×3 = 9 个相邻网格
		for dx := -1; dx <= 1 && !found; dx++ {
			for dy := -1; dy <= 1 && !found; dy++ {
				key := [2]int{cellX + dx, cellY + dy}
				if pts, ok := grid[key]; ok {
					for _, rp2 := range pts {
						d := haversine(rp.Lat, rp.Lng, rp2.Latitude, rp2.Longitude)
						if d <= matchDistanceMeters {
							matchedCount++
							found = true
							break
						}
					}
				}
			}
		}
	}

	return matchedCount, len(runPts), float64(matchedCount) / float64(len(runPts))
}

// AutoMatchRoute 自动匹配跑者的 GPS 轨迹与附近路线
//
// 流程：
//  1. 从 run_samples 加载 GPS 采样点
//  2. 计算跑者的外包框，查找候选路线（中心点在框外扩 5km 内）
//  3. 对每条候选路线，计算重合率
//  4. 取重合率最高的路线，若 ≥80% 则自动关联
//
// 调用时机：FinishRun 完成后异步执行
func (s *RunService) AutoMatchRoute(ctx context.Context, runID string) (*MatchResult, error) {
	// 1. 加载 GPS 采样
	samples, err := s.sampleRepo.ListByRunID(ctx, runID)
	if err != nil {
		return nil, err
	}
	if len(samples) < 5 {
		return nil, nil // 采样太少无法匹配
	}

	// 2. 计算跑者的外包框和中心点
	minLat, maxLat := samples[0].Latitude, samples[0].Latitude
	minLng, maxLng := samples[0].Longitude, samples[0].Longitude
	var sumLat, sumLng float64
	for _, s := range samples {
		if s.Latitude < minLat {
			minLat = s.Latitude
		}
		if s.Latitude > maxLat {
			maxLat = s.Latitude
		}
		if s.Longitude < minLng {
			minLng = s.Longitude
		}
		if s.Longitude > maxLng {
			maxLng = s.Longitude
		}
		sumLat += s.Latitude
		sumLng += s.Longitude
	}
	centerLat := sumLat / float64(len(samples))
	centerLng := sumLng / float64(len(samples))

	// 3. 外扩搜索半径（取跑者跨越半径 + 候选半径）
	spanLat := maxLat - minLat
	spanLng := maxLng - minLng
	spanMeters := math.Max(
		spanLat*111000.0,
		spanLng*111000.0*math.Cos(centerLat*math.Pi/180.0),
	)
	searchRadius := math.Max(spanMeters/2+candidateRadiusMeters, candidateRadiusMeters)

	// 4. 查找候选路线
	candidateRoutes, err := s.routeRepo.NearbyRoutes(ctx, centerLat, centerLng, searchRadius, 50)
	if err != nil {
		return nil, err
	}
	if len(candidateRoutes) == 0 {
		return nil, nil
	}

	// 5. 降采样跑者点
	runPts := downsamplePoints(samples, downsampleTarget)

	// 6. 逐条路线计算重合率
	type scored struct {
		route   model.Route
		matched int
		total   int
		overlap float64
	}
	var results []scored

	for _, route := range candidateRoutes {
		routePts, err := s.routeRepo.FindPointsByRouteID(ctx, route.ID)
		if err != nil || len(routePts) < 2 {
			continue
		}

		matched, total, overlap := findMatchingRate(runPts, routePts)
		if matched > 0 {
			results = append(results, scored{
				route:   route,
				matched: matched,
				total:   total,
				overlap: overlap,
			})
		}
	}

	if len(results) == 0 {
		return nil, nil
	}

	// 7. 按重合率降序排列
	sort.Slice(results, func(i, j int) bool {
		return results[i].overlap > results[j].overlap
	})

	best := results[0]

	// 8. 只有 ≥80% 才认为匹配成功
	if best.overlap < matchOverlapThreshold {
		return nil, nil
	}

	return &MatchResult{
		RouteID: best.route.ID,
		Route:   &best.route,
		Overlap: best.overlap,
		Matched: best.matched,
		Total:   best.total,
	}, nil
}

// ApplyMatch 将匹配结果应用到跑步记录和排行榜
func (s *RunService) ApplyMatch(ctx context.Context, runID, userID string, match *MatchResult, totalTime int64, avgPace *int) error {
	if match == nil || match.RouteID == "" {
		return nil
	}

	// 更新跑步记录关联的路线
	if err := s.runRepo.UpdateRouteID(ctx, runID, match.RouteID); err != nil {
		return err
	}

	// 更新排行榜
	board := &model.Leaderboard{
		ID:         uuid.New().String(),
		RouteID:    match.RouteID,
		UserID:     userID,
		RunID:      runID,
		TotalTime:  totalTime,
		AvgPace:    avgPace,
		RunCount:   1,
		RecordedAt: time.Now(),
	}
	return s.lbRepo.Upsert(ctx, board)
}
