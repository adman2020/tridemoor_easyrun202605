package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"
	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

// RealmNames 境界索引 → 名称映射
var RealmNames = []string{
	"炼气", "筑基", "金丹", "元婴", "化神",
	"合体", "大乘", "渡劫", "真仙", "金仙",
	"太乙", "大罗", "道祖",
}

// RoadTypeNames 路面类型映射
var RoadTypeNames = map[int8]string{
	0: "普通路面",
	1: "大马路（城市主干道，有红绿灯和车流，需注意安全）",
	2: "绿道（专用跑道/自行车道，路面平整，人少）",
	3: "坡道（山路/起伏路面，有爬升）",
	4: "跑道/操场（标准400m一圈，平整弹性）",
	5: "河边/湖边（风景好，路面一般较平）",
	6: "土路/越野（自然路面，有碎石和不平坦）",
}

// 高德天气 API Key（与地图 SDK 同一控制台）
const amapWeatherKey = "f50e31d4bd4b6cb53cbf2a019d9be9ba"

type AIHandler struct {
	aiSvc       *service.AIService
	runRepo     *repository.RunRepository
	userRepo    *repository.UserRepository
	analysisRepo *repository.AIAnalysisRepository
}

func NewAIHandler(aiSvc *service.AIService, runRepo *repository.RunRepository, userRepo *repository.UserRepository, analysisRepo *repository.AIAnalysisRepository) *AIHandler {
	return &AIHandler{aiSvc: aiSvc, runRepo: runRepo, userRepo: userRepo, analysisRepo: analysisRepo}
}

// RunAnalysisRequest 跑情分析请求
type RunAnalysisRequest struct {
	RunID string `json:"run_id" binding:"required"`
}

// RunAnalysis 生成跑情分析（AI跑情分析）
// POST /api/v1/ai/run-analysis
func (h *AIHandler) RunAnalysis(c *gin.Context) {
	var req RunAnalysisRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "参数错误")
		return
	}

	userID := c.GetString("userID")
	ctx := c.Request.Context()

	// 1. 获取跑步记录（含路线信息）
	run, err := h.runRepo.FindByID(ctx, req.RunID)
	if err != nil || run == nil {
		response.Error(c, http.StatusNotFound, "跑步记录不存在")
		return
	}
	if run.UserID != userID {
		response.Error(c, http.StatusForbidden, "无权访问")
		return
	}

	// 2. 检查是否有缓存
	cached, _ := h.analysisRepo.GetByRunID(req.RunID)
	if cached != nil {
		response.Success(c, gin.H{
			"content":   cached.AnalysisText,
			"model":     cached.Model,
			"tokens":    cached.Tokens,
			"latency":   cached.DurationMs,
			"run_id":    req.RunID,
			"cached_at": cached.CreatedAt.Format(time.RFC3339),
		})
		return
	}

	// 3. 获取用户信息（含跑境境界）
	user, _ := h.userRepo.FindByID(ctx, userID)

	// 4. 获取历史跑步数据
	runsIn30Days, _ := h.runRepo.GetRunsInDays(ctx, userID, 30) // 近30天
	personalBests, _ := h.runRepo.GetPersonalBests(ctx, userID)  // 个人最佳

	// 5. 查询真实天气（高德天气 API）
	weatherStr, tempInt := h.fetchRunWeather(run)

	// 6. 构建Prompt，发给AI
	realmName := getRealmName(user.Realm)
	prompt := buildRunAnalysisPrompt(run, user, runsIn30Days, personalBests, weatherStr, tempInt)
	systemPrompt := getRunAnalysisSystemPrompt(realmName)

	result, err := h.aiSvc.Call(ctx, "run_analysis", systemPrompt, prompt)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "分析生成失败，请稍后重试")
		return
	}

	// 7. 存入缓存
	analysis := &model.AIAnalysis{
		RunID:        req.RunID,
		UserID:       userID,
		AnalysisText: result.Content,
		Tokens:       result.Tokens,
		DurationMs:   int(result.Latency),
		Model:        result.Model,
		Weather:      weatherStr,
		Temperature:  &tempInt,
	}
	h.analysisRepo.CreateOrUpdate(analysis)

	response.Success(c, gin.H{
		"content": result.Content,
		"model":   result.Model,
		"tokens":  result.Tokens,
		"latency": result.Latency,
		"run_id":  req.RunID,
	})
}

// GetAnalysis 获取缓存的 AI 分析结果
// GET /api/v1/ai/analyses/:run_id
func (h *AIHandler) GetAnalysis(c *gin.Context) {
	runID := c.Param("run_id")
	if runID == "" {
		response.Error(c, http.StatusBadRequest, "缺少 run_id")
		return
	}

	userID := c.GetString("userID")

	cached, err := h.analysisRepo.GetByRunID(runID)
	if err != nil || cached == nil {
		response.Error(c, http.StatusNotFound, "暂无分析结果")
		return
	}
	if cached.UserID != userID {
		response.Error(c, http.StatusForbidden, "无权访问")
		return
	}

	response.Success(c, gin.H{
		"content":   cached.AnalysisText,
		"model":     cached.Model,
		"tokens":    cached.Tokens,
		"latency":   cached.DurationMs,
		"run_id":    runID,
		"cached_at": cached.CreatedAt.Format(time.RFC3339),
	})
}

// ===== AI 功能列表（VIP权益展示）=====

// AIFeatureDef 功能定义
type AIFeatureDef struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	MinVipTier  int    `json:"min_vip_tier"`
	Icon        string `json:"icon"`
}

// AIFeatureAccess 用户功能权益
type AIFeatureAccess struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	MinVipTier  int    `json:"min_vip_tier"`
	Icon        string `json:"icon"`
	Unlocked    bool   `json:"unlocked"`
}

// featuresList AI功能定义列表（硬编码，MVP阶段使用）
var featuresList = []AIFeatureDef{
	{ID: "run_analysis", Name: "AI跑情分析", Description: "跑步结束后获取智能分析报告，洞察跑步表现与训练建议", MinVipTier: 1, Icon: "🧠"},
	{ID: "coach", Name: "AI跑步教练", Description: "跑步过程中实时语音指导，根据跑步等级定制化建议", MinVipTier: 3, Icon: "🏃"},
	{ID: "summary", Name: "AI跑后总结", Description: "一键生成跑后分享文案，自动提炼精彩瞬间", MinVipTier: 1, Icon: "📝"},
	{ID: "route_recommend", Name: "AI路线推荐", Description: "基于你的跑步习惯和目标，智能推荐适合的跑步路线", MinVipTier: 3, Icon: "🗺️"},
	{ID: "comment", Name: "AI帮写评论", Description: "帮写跑友动态评论，轻松互动无压力", MinVipTier: 2, Icon: "💬"},
	{ID: "match", Name: "AI找搭档", Description: "根据跑步偏好和实力匹配志同道合的跑友", MinVipTier: 2, Icon: "👥"},
	{ID: "daily", Name: "AI每日金句", Description: "每日推送跑步激励语录，陪你坚持每一公里", MinVipTier: 1, Icon: "✨"},
	{ID: "moderation", Name: "AI路线审核", Description: "上传路线时自动审核命名规范与内容合规性", MinVipTier: 1, Icon: "🔍"},
}

// ListFeatures 获取当前用户可访问的AI功能列表
func (h *AIHandler) ListFeatures(c *gin.Context) {
	userID := c.GetString("userID")
	user, err := h.userRepo.FindByID(context.Background(), userID)
	if err != nil || user == nil {
		response.Error(c, http.StatusUnauthorized, "用户未登录")
		return
	}

	// 取 max(is_vip, vip_tier) 作为用户VIP等级
	userVipTier := int(user.IsVip)
	if int(user.VipTier) > userVipTier {
		userVipTier = int(user.VipTier)
	}

	// 组装功能访问列表
	var features []AIFeatureAccess
	for _, f := range featuresList {
		features = append(features, AIFeatureAccess{
			ID:          f.ID,
			Name:        f.Name,
			Description: f.Description,
			MinVipTier:  f.MinVipTier,
			Icon:        f.Icon,
			Unlocked:    userVipTier >= f.MinVipTier,
		})
	}

	response.Success(c, gin.H{
		"vip_tier":  userVipTier,
		"is_vip":    user.IsVip > 0,
		"features":  features,
	})
}

// ===== 天气查询 =====

// AmapWeatherResponse 高德天气 API 响应
type AmapWeatherResponse struct {
	Status   string                 `json:"status"`
	Count    string                 `json:"count"`
	Info     string                 `json:"info"`
	Infocode string                 `json:"infocode"`
	Forecasts []AmapForecast        `json:"forecasts"`
	Casts     []AmapCast             `json:"casts"` // 实时天气
}

type AmapForecast struct {
	City   string       `json:"city"`
	Casts  []AmapCast   `json:"casts"`
}

type AmapCast struct {
	Date         string `json:"date"`
	Dayweather   string `json:"dayweather"`
	Nightweather string `json:"nightweather"`
	Daytemp      string `json:"daytemp"`
	Nighttemp    string `json:"nighttemp"`
	Daypower     string `json:"daypower"`
}

// fetchRunWeather 根据跑步记录查询真实天气
// 返回 (天气描述, 温度°C)
func (h *AIHandler) fetchRunWeather(run *model.Run) (string, int8) {
	// 尝试从路线获取坐标
	var lat, lon float64
	if run.Route != nil && run.Route.CenterLat != nil && *run.Route.CenterLat != 0 &&
		run.Route.CenterLng != nil && *run.Route.CenterLng != 0 {
		lat = *run.Route.CenterLat
		lon = *run.Route.CenterLng
	}

	// 如果没有坐标，返回未知
	if lat == 0 && lon == 0 {
		return "", 0
	}

	// 调用高德天气 API（气象预报接口，支持历史日期查询有限制，
	// 这里用实时接口获取当前天气作为参考；后续可改用订阅版历史天气）
	url := fmt.Sprintf(
		"https://restapi.amap.com/v3/weather/weatherInfo?key=%s&city=%.4f,%.4f&extensions=base&output=JSON",
		amapWeatherKey, lon, lat, // 高德用经度,纬度顺序
	)

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return "", 0
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", 0
	}

	var wResp AmapWeatherResponse
	if json.Unmarshal(body, &wResp) != nil {
		return "", 0
	}
	if wResp.Status != "1" || len(wResp.Casts) == 0 {
		return "", 0
	}

	cast := wResp.Casts[0]
	weather := cast.Dayweather // 白天天气
	temp, _ := strconv.ParseInt(cast.Daytemp, 10, 8)

	return weather, int8(temp)
}

// ===== 辅助函数 =====

func getRealmName(realm int8) string {
	if realm >= 0 && int(realm) < len(RealmNames) {
		return RealmNames[realm]
	}
	return RealmNames[0] // 默认返回"炼气"
}

func getRoadTypeName(roadType int8) string {
	if name, ok := RoadTypeNames[roadType]; ok {
		return name
	}
	return RoadTypeNames[0]
}

func getElevationTip(gain, loss float64) string {
	if gain > 50 {
		return "（含较大爬升，考验心肺功能）"
	} else if gain > 20 {
		return "（有中等起伏）"
	} else if gain > 0 {
		return "（有轻微起伏）"
	} else if loss > 20 {
		return "（含较大下坡，注意膝关节缓冲）"
	}
	return ""
}

func getRunAnalysisSystemPrompt(realm string) string {
	switch realm {
	case "道祖":
		return `你是驰陌App的AI跑情分析师。用户为道祖级跑者（世界顶流职业水准，全马配速<2:50/km）。
分析要求：
- 极简专业，无废话，每句话都有数据支撑
- 直接对比全球顶尖水平，不用鼓励语言
- 配速分析精确到秒，步频/步幅与世界纪录对照
- 结合路面类型和天气，给出专业级训练调整建议（如：坡道分段配速策略、绿道冲刺节奏等）
- 训练建议：只给数据对比，不给方向性建议（他们比任何AI都懂训练）
- 重要：如果天气数据缺失或为"未知"，不要编造温度和天气状况，直接跳过天气相关分析
输出格式：简短，不超过250字，纯数据+对比，少用形容词。`
	case "大罗", "太乙", "金仙", "真仙":
		return `你是驰陌App的AI跑情分析师。用户为天君/金仙级跑者（全马2:00~3:20区间，业余顶尖）。
分析要求：
- 技术分析为主（配速趋势、步频效率、完赛策略）
- 结合路面类型：马路安全提醒、绿道节奏建议、坡道心率控制、跑道速度优化
- 结合天气：高温/低温/雨天/大风给出针对性叮嘱
- 训练建议一句，包含具体数值（如"本周维持这个配速，下周尝试+5秒/km"）
- 重要：如果天气数据缺失或为"未知"，不要编造温度和天气状况，直接跳过天气相关分析
输出格式：350字以内，分点清晰。`
	case "渡劫", "大乘", "合体":
		return `你是驰陌App的AI跑情分析师。用户为元婴级跑者（能跑半马/全马，配速3:20~4:15）。
分析要求：
- 技术分析与鼓励各半
- 指出一个具体技术亮点（配速/心率/步频之一）
- 结合路面类型和天气做归因分析，给出具体建议
- 训练建议一句，包含具体数值
- 大马路跑步要提醒安全注意事项
- 重要：如果天气数据缺失或为"未知"，不要编造温度和天气状况，直接跳过天气相关分析
输出格式：350字以内，温暖但专业。`
	default: // 炼气、筑基、金丹、元婴、化神
		return `你是驰陌App的AI跑情分析师。用户为筑基期及以下跑者（入门~10km级别）。
分析要求：
- 鼓励为主，每句话都有正面反馈
- 重点突出本次亮点（距离突破、步数进步、时长增加）
- 历史对比用绝对数字，不用百分比（"你上次跑了2km，这次跑了3km，进步了！"）
- 跑境解读：正面归因（"今天有点热，你还是坚持跑完了，厉害！"）
- 结合路面类型：路面软硬/平整度/安全性给出贴心叮嘱（大马路提醒安全、绿道夸环境好、坡道提醒上坡发力）
- 结合天气给出正面鼓励
- 训练建议：简单一句，充满期待感
- 重要：如果天气数据缺失或为"未知"，不要编造温度和天气状况，直接跳过天气相关分析
输出格式：300字以内，语气温暖，像一个懂跑步的朋友在鼓励你。`
	}
}

func buildRunAnalysisPrompt(run *model.Run, user *model.User, runsIn30Days []model.Run, personalBests *repository.PersonalBest, weatherOverride string, tempOverride int8) string {
	// 本次数据
	totalDistance := 0.0
	if run.TotalDistance != nil {
		totalDistance = *run.TotalDistance
	}
	totalTime := int64(0)
	if run.TotalTime != nil {
		totalTime = *run.TotalTime
	}
	avgPace := 0
	if run.AvgPace != nil {
		avgPace = *run.AvgPace
	}
	avgHeartRate := int16(0)
	if run.AvgHeartRate != nil {
		avgHeartRate = *run.AvgHeartRate
	}
	avgCadence := int16(0)
	if run.AvgCadence != nil {
		avgCadence = *run.AvgCadence
	}

	// 天气：优先使用高德查询的真实天气，其次用记录中的值
	weather := ""
	temperature := int16(0)
	hasRealWeather := false

	if weatherOverride != "" {
		weather = weatherOverride
		temperature = int16(tempOverride)
		hasRealWeather = true
	} else if run.Weather != nil && *run.Weather != "" && *run.Weather != "?" {
		weather = *run.Weather
		if run.Temperature != nil && *run.Temperature > 0 {
			temperature = *run.Temperature
			hasRealWeather = true
		}
	}

	// 路面信息
	roadTypeName := getRoadTypeName(int8(0))
	if run.Route != nil {
		roadTypeName = getRoadTypeName(run.Route.RoadType)
	}
	elevationGain := run.ElevationGain
	elevationLoss := run.ElevationLoss
	elevationTip := getElevationTip(elevationGain, elevationLoss)

	// 历史统计（近30天）
	historyCount := len(runsIn30Days)
	var avgPaceSum int
	paceCount := 0
	for _, hist := range runsIn30Days {
		if hist.AvgPace != nil && *hist.AvgPace > 0 {
			avgPaceSum += *hist.AvgPace
			paceCount++
		}
	}
	avgPaceHist := 0
	if paceCount > 0 {
		avgPaceHist = avgPaceSum / paceCount
	}

	// 个人最佳（全量历史）
	bestPace := 0
	bestDistance := 0.0
	if personalBests != nil {
		bestPace = personalBests.BestPace
		bestDistance = personalBests.BestDistance
	}

	realmName := getRealmName(user.Realm)

	// 构建 prompt，天气部分根据是否有真实数据动态调整
	prompt := `用户跑步数据：
- 本次距离：` + formatDist(totalDistance) + `
- 本次时长：` + formatDuration(totalTime) + `
- 本次配速：` + formatPace(avgPace) + `/km
- 平均心率：` + itoa(int(avgHeartRate)) + ` bpm（若有）
- 平均步频：` + itoa(int(avgCadence)) + ` spm（若有）
- 路面类型：` + roadTypeName + `
- 爬升：` + ftoa(elevationGain) + ` m（下降 ` + ftoa(elevationLoss) + ` m）` + elevationTip + `
`

	if hasRealWeather && weather != "" {
		prompt += `- 天气：` + weather + `，约 ` + itoa(int(temperature)) + `°C
`
	} else {
		prompt += `- 天气：未知（本次跑步未记录天气数据）
`
	}

	prompt += `- 跑步时间：` + run.StartTime.Format("2006-01-02 15:04") + `
- 用户跑境：` + realmName + `
- 历史跑步记录：` + itoa(historyCount) + `条
- 历史最佳距离：` + formatDist(bestDistance) + `
- 历史平均配速：` + formatPace(avgPaceHist) + `/km
- 历史最佳配速：` + formatPace(bestPace) + `/km

请生成跑情分析，重点结合路面类型和天气条件给出针对性建议。`

	return prompt
}

func formatPace(paceSec int) string {
	if paceSec <= 0 {
		return "—"
	}
	m := paceSec / 60
	s := paceSec % 60
	return itoa(m) + ":" + pad2(s)
}

func formatDist(km float64) string {
	if km < 1 {
		return ftoa(km*1000) + "m"
	}
	return ftoa(km) + "km"
}

func formatDuration(seconds int64) string {
	h := seconds / 3600
	m := (seconds % 3600) / 60
	s := seconds % 60
	if h > 0 {
		return itoa(int(h)) + "h" + pad2(int(m)) + "m"
	}
	return itoa(int(m)) + "m" + pad2(int(s))
}

func pad2(n int) string {
	if n < 10 {
		return "0" + itoa(n)
	}
	return itoa(n)
}

func ftoa(f float64) string {
	return strconv.FormatFloat(f, 'f', 1, 64)
}

func itoa(i int) string {
	return strconv.Itoa(i)
}
