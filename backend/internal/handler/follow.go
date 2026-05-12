package handler

import (
	"strconv"

	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

type FollowHandler struct {
	followService *service.FollowService
}

func NewFollowHandler(followService *service.FollowService) *FollowHandler {
	return &FollowHandler{followService: followService}
}

// FollowUser 关注用户
func (h *FollowHandler) FollowUser(c *gin.Context) {
	followerID, _ := c.Get("userID")
	followingID := c.Param("id")
	if followingID == "" {
		response.BadRequest(c, "缺少用户ID")
		return
	}

	if err := h.followService.FollowUser(c.Request.Context(), followerID.(string), followingID); err != nil {
		switch err.Error() {
		case "cannot follow yourself":
			response.Error(c, response.CodeBadRequest, "不能关注自己")
		case "user not found":
			response.Error(c, response.CodeNotFound, "用户不存在")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// UnfollowUser 取消关注
func (h *FollowHandler) UnfollowUser(c *gin.Context) {
	followerID, _ := c.Get("userID")
	followingID := c.Param("id")
	if followingID == "" {
		response.BadRequest(c, "缺少用户ID")
		return
	}

	if err := h.followService.UnfollowUser(c.Request.Context(), followerID.(string), followingID); err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, nil)
}

// IsFollowing 判断是否已关注
func (h *FollowHandler) IsFollowing(c *gin.Context) {
	followerID, _ := c.Get("userID")
	followingID := c.Query("user_id")
	if followingID == "" {
		response.BadRequest(c, "缺少用户ID")
		return
	}

	isFollowing, err := h.followService.IsFollowing(c.Request.Context(), followerID.(string), followingID)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{"is_following": isFollowing})
}

// ListFollowings 获取关注列表
func (h *FollowHandler) ListFollowings(c *gin.Context) {
	followerID, _ := c.Get("userID")

	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "20")
	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	follows, total, err := h.followService.ListFollowings(c.Request.Context(), followerID.(string), page, pageSize)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{
		"list":  follows,
		"total": total,
		"page":  page,
		"size":  pageSize,
	})
}

// ListFollowers 获取粉丝列表
func (h *FollowHandler) ListFollowers(c *gin.Context) {
	followingID, _ := c.Get("userID")

	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "20")
	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	follows, total, err := h.followService.ListFollowers(c.Request.Context(), followingID.(string), page, pageSize)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{
		"list":  follows,
		"total": total,
		"page":  page,
		"size":  pageSize,
	})
}
