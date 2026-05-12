package handler

import (
	"log"
	"strconv"

	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

type RouteHandler struct {
	routeService *service.RouteService
}

func NewRouteHandler(routeService *service.RouteService) *RouteHandler {
	return &RouteHandler{routeService: routeService}
}

// CreateRoute 创建路线
func (h *RouteHandler) CreateRoute(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.CreateRouteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	route, err := h.routeService.CreateRoute(c.Request.Context(), userID.(string), &req)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, route)
}

// ValidateRoute 路线规则校验
// POST /api/v1/routes/validate
func (h *RouteHandler) ValidateRoute(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.ValidateRouteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	result, err := h.routeService.ValidateRoute(c.Request.Context(), userID.(string), &req)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, result)
}

// ListRoutes 路线列表
func (h *RouteHandler) ListRoutes(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.RouteListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	items, total, err := h.routeService.ListRoutes(c.Request.Context(), req, userID.(string))
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{
		"list":  items,
		"total": total,
		"page":  req.Page,
		"size":  req.PageSize,
	})
}

// GetRouteDetail 路线详情
func (h *RouteHandler) GetRouteDetail(c *gin.Context) {
	userID, _ := c.Get("userID")
	routeID := c.Param("id")
	if routeID == "" {
		response.BadRequest(c, "缺少路线ID")
		return
	}

	detail, err := h.routeService.GetRouteDetail(c.Request.Context(), routeID, userID.(string))
	if err != nil {
		if err.Error() == "route not found" {
			response.Error(c, response.CodeNotFound, "路线不存在")
			return
		}
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, detail)
}

// FavoriteRoute 收藏路线
func (h *RouteHandler) FavoriteRoute(c *gin.Context) {
	userID, _ := c.Get("userID")
	routeID := c.Param("id")
	if routeID == "" {
		response.BadRequest(c, "缺少路线ID")
		return
	}

	if err := h.routeService.FavoriteRoute(c.Request.Context(), userID.(string), routeID); err != nil {
		switch err.Error() {
		case "route not found":
			response.Error(c, response.CodeNotFound, "路线不存在")
		case "already favorited":
			response.Error(c, response.CodeError, "已收藏")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// UnfavoriteRoute 取消收藏
func (h *RouteHandler) UnfavoriteRoute(c *gin.Context) {
	userID, _ := c.Get("userID")
	routeID := c.Param("id")
	if routeID == "" {
		response.BadRequest(c, "缺少路线ID")
		return
	}

	if err := h.routeService.UnfavoriteRoute(c.Request.Context(), userID.(string), routeID); err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, nil)
}

// ListFavorites 我的收藏列表
func (h *RouteHandler) ListFavorites(c *gin.Context) {
	userID, _ := c.Get("userID")

	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "10")
	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 10
	}

	items, total, err := h.routeService.ListFavorites(c.Request.Context(), userID.(string), page, pageSize)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{
		"list":  items,
		"total": total,
		"page":  page,
		"size":  pageSize,
	})
}

// DeleteRoute 删除路线
func (h *RouteHandler) DeleteRoute(c *gin.Context) {
	userID, _ := c.Get("userID")
	routeID := c.Param("id")
	if routeID == "" {
		response.BadRequest(c, "缺少路线ID")
		return
	}

	if err := h.routeService.DeleteRoute(c.Request.Context(), routeID, userID.(string)); err != nil {
		switch err.Error() {
		case "route not found":
			response.Error(c, response.CodeNotFound, "路线不存在")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权删除")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// RateRoute 评分路线
func (h *RouteHandler) RateRoute(c *gin.Context) {
	userID, _ := c.Get("userID")
	routeID := c.Param("id")
	if routeID == "" {
		response.BadRequest(c, "缺少路线ID")
		return
	}

	var req struct {
		Rating float64 `json:"rating" binding:"required,min=0,max=5"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	if err := h.routeService.RateRoute(c.Request.Context(), routeID, userID.(string), req.Rating); err != nil {
		if err.Error() == "route not found" {
			response.Error(c, response.CodeNotFound, "路线不存在")
			return
		}
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, nil)
}

// UpdateRoute 更新路线
func (h *RouteHandler) UpdateRoute(c *gin.Context) {
	userID, _ := c.Get("userID")
	routeID := c.Param("id")
	if routeID == "" {
		response.BadRequest(c, "缺少路线ID")
		return
	}

	var req service.UpdateRouteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	if err := h.routeService.UpdateRoute(c.Request.Context(), routeID, userID.(string), &req); err != nil {
		switch err.Error() {
		case "route not found":
			response.Error(c, response.CodeNotFound, "路线不存在")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权修改")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// NearbyRoutes 附近路线
func (h *RouteHandler) NearbyRoutes(c *gin.Context) {
	latStr := c.Query("lat")
	lngStr := c.Query("lng")
	radiusStr := c.DefaultQuery("radius", "5000")
	limitStr := c.DefaultQuery("limit", "20")

	lat, err1 := strconv.ParseFloat(latStr, 64)
	lng, err2 := strconv.ParseFloat(lngStr, 64)
	radius, _ := strconv.ParseFloat(radiusStr, 64)
	limit, _ := strconv.Atoi(limitStr)

	if err1 != nil || err2 != nil {
		response.BadRequest(c, "lat/lng 参数错误")
		return
	}

	routes, err := h.routeService.NearbyRoutes(c.Request.Context(), lat, lng, radius, limit)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{"routes": routes})
}

// GetLeaderboard 路线排行榜
func (h *RouteHandler) GetLeaderboard(c *gin.Context) {
	routeID := c.Param("id")
	if routeID == "" {
		response.BadRequest(c, "缺少路线ID")
		return
	}

	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "20")
	sortBy := c.DefaultQuery("sort_by", "")
	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}

	// 调试日志
	log.Printf("[route] GetLeaderboard routeID=%s sortBy=%q page=%d pageSize=%d", routeID, sortBy, page, pageSize)

	items, total, err := h.routeService.GetLeaderboard(c.Request.Context(), routeID, page, pageSize, sortBy)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{
		"list":  items,
		"total": total,
		"page":  page,
		"size":  pageSize,
	})
}
