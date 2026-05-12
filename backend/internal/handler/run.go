package handler

import (
	"strconv"

	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

type RunHandler struct {
	runService *service.RunService
}

func NewRunHandler(runService *service.RunService) *RunHandler {
	return &RunHandler{runService: runService}
}

func (h *RunHandler) StartRun(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.StartRunRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	resp, err := h.runService.StartRun(c.Request.Context(), userID.(string), &req)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, resp)
}

func (h *RunHandler) UploadSamples(c *gin.Context) {
	runID := c.Param("id")
	if runID == "" {
		response.BadRequest(c, "缺少跑步ID")
		return
	}

	var req service.UploadSamplesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	if err := h.runService.UploadSamples(c.Request.Context(), runID, &req); err != nil {
		if err.Error() == "run not found" {
			response.Error(c, response.CodeNotFound, "跑步记录不存在")
			return
		}
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{"uploaded": len(req.Samples)})
}

func (h *RunHandler) FinishRun(c *gin.Context) {
	userID, _ := c.Get("userID")
	runID := c.Param("id")
	if runID == "" {
		response.BadRequest(c, "缺少跑步ID")
		return
	}

	var req service.FinishRunRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	match, err := h.runService.FinishRun(c.Request.Context(), runID, userID.(string), &req)
	if err != nil {
		switch err.Error() {
		case "run not found":
			response.Error(c, response.CodeNotFound, "跑步记录不存在")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权操作")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	resp := gin.H{}
	if match != nil {
		resp["match"] = gin.H{
			"route_id": match.RouteID,
			"overlap":  match.Overlap,
			"matched":  match.Matched,
			"total":    match.Total,
		}
		if match.Route != nil {
			resp["route"] = gin.H{
				"id":   match.Route.ID,
				"name": match.Route.Name,
			}
		}
	}
	response.Success(c, resp)
}

func (h *RunHandler) GetRunList(c *gin.Context) {
	userID, _ := c.Get("userID")

	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "10")

	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}

	items, total, err := h.runService.GetRunList(c.Request.Context(), userID.(string), page, pageSize)
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

func (h *RunHandler) GetRunDetail(c *gin.Context) {
	userID, _ := c.Get("userID")
	runID := c.Param("id")
	if runID == "" {
		response.BadRequest(c, "缺少跑步ID")
		return
	}

	detail, err := h.runService.GetRunDetail(c.Request.Context(), runID, userID.(string))
	if err != nil {
		switch err.Error() {
		case "run not found":
			response.Error(c, response.CodeNotFound, "跑步记录不存在")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权操作")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, detail)
}

// ---------------------------------------------------------------------------
// 跑友跑迹收藏
// ---------------------------------------------------------------------------

func (h *RunHandler) BookmarkRun(c *gin.Context) {
	userID, _ := c.Get("userID")
	runID := c.Param("id")
	if runID == "" {
		response.BadRequest(c, "缺少跑步ID")
		return
	}
	if err := h.runService.BookmarkRun(c.Request.Context(), userID.(string), runID); err != nil {
		switch err.Error() {
		case "run not found":
			response.Error(c, response.CodeNotFound, "跑步记录不存在")
		case "already bookmarked":
			response.Error(c, response.CodeError, "已收藏")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}
	response.Success(c, nil)
}

func (h *RunHandler) UnbookmarkRun(c *gin.Context) {
	userID, _ := c.Get("userID")
	runID := c.Param("id")
	if runID == "" {
		response.BadRequest(c, "缺少跑步ID")
		return
	}
	if err := h.runService.UnbookmarkRun(c.Request.Context(), userID.(string), runID); err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}
	response.Success(c, nil)
}

// DeleteRun 删除未完成的空跑记录
func (h *RunHandler) DeleteRun(c *gin.Context) {
	userID, _ := c.Get("userID")
	runID := c.Param("id")
	if runID == "" {
		response.BadRequest(c, "缺少跑步ID")
		return
	}

	if err := h.runService.DeleteRun(c.Request.Context(), runID, userID.(string)); err != nil {
		switch err.Error() {
		case "run not found":
			response.Error(c, response.CodeNotFound, "跑步记录不存在")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权操作")
		case "cannot delete finished run":
			response.Error(c, response.CodeError, "已完成跑步不能删除")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

func (h *RunHandler) ListBookmarks(c *gin.Context) {
	userID, _ := c.Get("userID")
	bms, err := h.runService.ListBookmarks(c.Request.Context(), userID.(string))
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}
	response.Success(c, gin.H{"list": bms})
}

// CompanionComplete 伴跑完成（轻量：不存记录，仅加热度）
// GetRunAverages 获取当前用户的跑步历史平均值（用于语音播报对比）
func (h *RunHandler) GetRunAverages(c *gin.Context) {
	userID, _ := c.Get("user_id")
	avg, err := h.runService.GetRunAverages(c.Request.Context(), userID.(string))
	if err != nil {
		response.Error(c, response.CodeNotFound, "获取平均值失败")
		return
	}
	response.Success(c, avg)
}

func (h *RunHandler) CompanionComplete(c *gin.Context) {
	userID, _ := c.Get("userID")
	targetRunID := c.Param("id")
	if targetRunID == "" {
		response.BadRequest(c, "缺少跑步ID")
		return
	}

	if err := h.runService.CompanionRunComplete(c.Request.Context(), userID.(string), targetRunID); err != nil {
		switch err.Error() {
		case "target run not found":
			response.Error(c, response.CodeNotFound, "跑步记录不存在")
		case "cannot companion your own run":
			response.Error(c, response.CodeBadRequest, "不能伴跑自己的跑迹")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}
