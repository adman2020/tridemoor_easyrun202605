package handler

import (
	"strconv"

	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

type ChallengeHandler struct {
	challengeService *service.ChallengeService
}

func NewChallengeHandler(challengeService *service.ChallengeService) *ChallengeHandler {
	return &ChallengeHandler{challengeService: challengeService}
}

// CreateChallenge 发起挑战
func (h *ChallengeHandler) CreateChallenge(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.CreateChallengeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	challenge, err := h.challengeService.CreateChallenge(c.Request.Context(), userID.(string), &req)
	if err != nil {
		switch err.Error() {
		case "route not found":
			response.Error(c, response.CodeNotFound, "路线不存在")
		case "invitee not found":
			response.Error(c, response.CodeNotFound, "被挑战者不存在")
		case "cannot challenge yourself":
			response.Error(c, response.CodeBadRequest, "不能挑战自己")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, challenge)
}

// AcceptChallenge 接受挑战
func (h *ChallengeHandler) AcceptChallenge(c *gin.Context) {
	userID, _ := c.Get("userID")
	challengeID := c.Param("id")
	if challengeID == "" {
		response.BadRequest(c, "缺少挑战ID")
		return
	}

	if err := h.challengeService.AcceptChallenge(c.Request.Context(), challengeID, userID.(string)); err != nil {
		switch err.Error() {
		case "challenge not found":
			response.Error(c, response.CodeNotFound, "挑战不存在")
		case "challenge not pending":
			response.Error(c, response.CodeError, "挑战状态不可接受")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权操作")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// StartChallenge 开始挑战
func (h *ChallengeHandler) StartChallenge(c *gin.Context) {
	userID, _ := c.Get("userID")
	challengeID := c.Param("id")
	if challengeID == "" {
		response.BadRequest(c, "缺少挑战ID")
		return
	}

	resp, err := h.challengeService.StartChallenge(c.Request.Context(), challengeID, userID.(string))
	if err != nil {
		switch err.Error() {
		case "challenge not found":
			response.Error(c, response.CodeNotFound, "挑战不存在")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权参与")
		case "challenge cannot be started":
			response.Error(c, response.CodeError, "挑战状态不可开始")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, resp)
}

// CompleteChallenge 完成挑战
func (h *ChallengeHandler) CompleteChallenge(c *gin.Context) {
	userID, _ := c.Get("userID")
	challengeID := c.Param("id")
	if challengeID == "" {
		response.BadRequest(c, "缺少挑战ID")
		return
	}

	var req service.CompleteChallengeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	if err := h.challengeService.CompleteChallenge(c.Request.Context(), challengeID, userID.(string), &req); err != nil {
		switch err.Error() {
		case "challenge not found":
			response.Error(c, response.CodeNotFound, "挑战不存在")
		case "challenge not in progress":
			response.Error(c, response.CodeError, "挑战未在进行中")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权操作")
		case "run not found":
			response.Error(c, response.CodeNotFound, "跑步记录不存在")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// CancelChallenge 取消挑战
func (h *ChallengeHandler) CancelChallenge(c *gin.Context) {
	userID, _ := c.Get("userID")
	challengeID := c.Param("id")
	if challengeID == "" {
		response.BadRequest(c, "缺少挑战ID")
		return
	}

	if err := h.challengeService.CancelChallenge(c.Request.Context(), challengeID, userID.(string)); err != nil {
		switch err.Error() {
		case "challenge not found":
			response.Error(c, response.CodeNotFound, "挑战不存在")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权操作")
		case "challenge already finished":
			response.Error(c, response.CodeError, "挑战已结束")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// ListChallenges 挑战列表
func (h *ChallengeHandler) ListChallenges(c *gin.Context) {
	userID, _ := c.Get("userID")

	status := c.Query("status")
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

	items, total, err := h.challengeService.ListChallenges(c.Request.Context(), userID.(string), status, page, pageSize)
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

// GetChallengeDetail 挑战详情
func (h *ChallengeHandler) GetChallengeDetail(c *gin.Context) {
	challengeID := c.Param("id")
	if challengeID == "" {
		response.BadRequest(c, "缺少挑战ID")
		return
	}

	challenge, err := h.challengeService.GetChallengeDetail(c.Request.Context(), challengeID)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}
	if challenge == nil {
		response.Error(c, response.CodeNotFound, "挑战不存在")
		return
	}

	response.Success(c, challenge)
}

// GetComparison 对比报告
func (h *ChallengeHandler) GetComparison(c *gin.Context) {
	challengeID := c.Param("id")
	if challengeID == "" {
		response.BadRequest(c, "缺少挑战ID")
		return
	}

	comparison, err := h.challengeService.GetComparison(c.Request.Context(), challengeID)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}
	if comparison == nil {
		response.Error(c, response.CodeNotFound, "对比报告不存在")
		return
	}

	response.Success(c, comparison)
}
