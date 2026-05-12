package handler

import (
	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

type UserHandler struct {
	userService *service.UserService
}

func NewUserHandler(userService *service.UserService) *UserHandler {
	return &UserHandler{userService: userService}
}

func (h *UserHandler) Register(c *gin.Context) {
	var req service.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	tokens, err := h.userService.Register(c.Request.Context(), &req)
	if err != nil {
		if err.Error() == "phone already registered" {
			response.Error(c, response.CodeUserExists, "手机号已注册")
			return
		}
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, tokens)
}

func (h *UserHandler) Login(c *gin.Context) {
	var req service.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	tokens, userInfo, err := h.userService.Login(c.Request.Context(), &req)
	if err != nil {
		switch err.Error() {
		case "user not found":
			response.Error(c, response.CodeNotFound, "用户不存在")
		case "invalid password":
			response.Error(c, response.CodePasswordError, "密码错误")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, gin.H{
		"tokens":    tokens,
		"user_info": userInfo,
	})
}

func (h *UserHandler) GetProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "未登录")
		return
	}

	info, err := h.userService.GetUserInfo(c.Request.Context(), userID.(string))
	if err != nil {
		response.Error(c, response.CodeNotFound, "用户不存在")
		return
	}

	response.Success(c, info)
}

func (h *UserHandler) UpdatePassword(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "未登录")
		return
	}

	var req service.UpdatePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	if err := h.userService.UpdatePassword(c.Request.Context(), userID.(string), &req); err != nil {
		switch err.Error() {
		case "user not found":
			response.Error(c, response.CodeNotFound, "用户不存在")
		case "invalid password":
			response.Error(c, response.CodePasswordError, "旧密码错误")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "未登录")
		return
	}

	var req service.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	if err := h.userService.UpdateProfile(c.Request.Context(), userID.(string), &req); err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, nil)
}

// GetUserStats 获取指定用户的跑步统计数据（跑友详情用）
func (h *UserHandler) GetUserStats(c *gin.Context) {
	userID := c.Param("id")
	if userID == "" {
		response.BadRequest(c, "缺少用户ID")
		return
	}

	info, err := h.userService.GetUserStats(c.Request.Context(), userID)
	if err != nil {
		response.Error(c, response.CodeNotFound, "用户不存在")
		return
	}

	response.Success(c, info)
}

func (h *UserHandler) GetHeatStats(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "未登录")
		return
	}

	stats, err := h.userService.GetHeatStats(c.Request.Context(), userID.(string))
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, stats)
}

func (h *UserHandler) RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	tokens, err := h.userService.RefreshToken(c.Request.Context(), req.RefreshToken)
	if err != nil {
		switch err.Error() {
		case "invalid refresh token":
			response.Error(c, response.CodeTokenExpired, "Refresh Token 无效")
		case "user not found":
			response.Error(c, response.CodeNotFound, "用户不存在")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, tokens)
}
