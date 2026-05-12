package handler

import (
	"strconv"

	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

type FriendshipHandler struct {
	friendshipService *service.FriendshipService
}

func NewFriendshipHandler(friendshipService *service.FriendshipService) *FriendshipHandler {
	return &FriendshipHandler{friendshipService: friendshipService}
}

// SendFriendRequest 发送好友申请
func (h *FriendshipHandler) SendFriendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req struct {
		ToUserID string `json:"to_user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	if err := h.friendshipService.SendFriendRequest(c.Request.Context(), userID.(string), req.ToUserID); err != nil {
		switch err.Error() {
		case "cannot add yourself":
			response.Error(c, response.CodeBadRequest, "不能添加自己")
		case "user not found":
			response.Error(c, response.CodeNotFound, "用户不存在")
		case "already friends":
			response.Error(c, response.CodeError, "已经是好友")
		case "request already pending":
			response.Error(c, response.CodeError, "申请已存在")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// AcceptFriendRequest 接受好友申请
func (h *FriendshipHandler) AcceptFriendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")
	requestID := c.Param("id")
	if requestID == "" {
		response.BadRequest(c, "缺少申请ID")
		return
	}

	if err := h.friendshipService.AcceptFriendRequest(c.Request.Context(), requestID, userID.(string)); err != nil {
		switch err.Error() {
		case "request not found":
			response.Error(c, response.CodeNotFound, "申请不存在")
		case "request already processed":
			response.Error(c, response.CodeError, "申请已处理")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权操作")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// RejectFriendRequest 拒绝好友申请
func (h *FriendshipHandler) RejectFriendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")
	requestID := c.Param("id")
	if requestID == "" {
		response.BadRequest(c, "缺少申请ID")
		return
	}

	if err := h.friendshipService.RejectFriendRequest(c.Request.Context(), requestID, userID.(string)); err != nil {
		switch err.Error() {
		case "request not found":
			response.Error(c, response.CodeNotFound, "申请不存在")
		case "request already processed":
			response.Error(c, response.CodeError, "申请已处理")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权操作")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// ListFriends 好友列表
func (h *FriendshipHandler) ListFriends(c *gin.Context) {
	userID, _ := c.Get("userID")

	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "20")
	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}

	items, total, err := h.friendshipService.ListFriends(c.Request.Context(), userID.(string), page, pageSize)
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

// ListPendingRequests 待处理申请列表
func (h *FriendshipHandler) ListPendingRequests(c *gin.Context) {
	userID, _ := c.Get("userID")

	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "20")
	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}

	items, total, err := h.friendshipService.ListPendingRequests(c.Request.Context(), userID.(string), page, pageSize)
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

// RemoveFriend 删除好友
func (h *FriendshipHandler) RemoveFriend(c *gin.Context) {
	userID, _ := c.Get("userID")
	friendID := c.Param("id")
	if friendID == "" {
		response.BadRequest(c, "缺少好友关系ID")
		return
	}

	if err := h.friendshipService.RemoveFriend(c.Request.Context(), friendID, userID.(string)); err != nil {
		switch err.Error() {
		case "friendship not found":
			response.Error(c, response.CodeNotFound, "好友关系不存在")
		case "not friends":
			response.Error(c, response.CodeError, "不是好友")
		case "permission denied":
			response.Error(c, response.CodeUnauthorized, "无权操作")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}
