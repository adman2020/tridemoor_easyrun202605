package handler

import (
	"strconv"

	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

type PostHandler struct {
	postService *service.PostService
}

func NewPostHandler(postService *service.PostService) *PostHandler {
	return &PostHandler{postService: postService}
}

// CreatePost 创建动态
func (h *PostHandler) CreatePost(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	post, err := h.postService.CreatePost(c.Request.Context(), userID.(string), &req)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, post)
}

// ListPosts 动态列表
func (h *PostHandler) ListPosts(c *gin.Context) {
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

	posts, total, err := h.postService.ListPosts(c.Request.Context(), page, pageSize)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{
		"list":  posts,
		"total": total,
		"page":  page,
		"size":  pageSize,
	})
}

// GetPostDetail 动态详情
func (h *PostHandler) GetPostDetail(c *gin.Context) {
	postID := c.Param("id")
	if postID == "" {
		response.BadRequest(c, "缺少动态ID")
		return
	}

	post, err := h.postService.GetPostDetail(c.Request.Context(), postID)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}
	if post == nil {
		response.Error(c, response.CodeNotFound, "动态不存在")
		return
	}

	response.Success(c, post)
}

// CreateComment 发表评论
func (h *PostHandler) CreateComment(c *gin.Context) {
	userID, _ := c.Get("userID")
	postID := c.Param("id")
	if postID == "" {
		response.BadRequest(c, "缺少动态ID")
		return
	}

	var req service.CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}

	if err := h.postService.CreateComment(c.Request.Context(), postID, userID.(string), &req); err != nil {
		switch err.Error() {
		case "post not found":
			response.Error(c, response.CodeNotFound, "动态不存在")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// ListComments 评论列表
func (h *PostHandler) ListComments(c *gin.Context) {
	postID := c.Param("id")
	if postID == "" {
		response.BadRequest(c, "缺少动态ID")
		return
	}

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

	comments, total, err := h.postService.ListComments(c.Request.Context(), postID, page, pageSize)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, gin.H{
		"list":  comments,
		"total": total,
		"page":  page,
		"size":  pageSize,
	})
}

// LikePost 点赞
func (h *PostHandler) LikePost(c *gin.Context) {
	userID, _ := c.Get("userID")
	postID := c.Param("id")
	if postID == "" {
		response.BadRequest(c, "缺少动态ID")
		return
	}

	if err := h.postService.LikePost(c.Request.Context(), postID, userID.(string)); err != nil {
		switch err.Error() {
		case "post not found":
			response.Error(c, response.CodeNotFound, "动态不存在")
		case "already liked":
			response.Error(c, response.CodeBadRequest, "已经点过赞了")
		default:
			response.Error(c, response.CodeError, err.Error())
		}
		return
	}

	response.Success(c, nil)
}

// UnlikePost 取消点赞
func (h *PostHandler) UnlikePost(c *gin.Context) {
	userID, _ := c.Get("userID")
	postID := c.Param("id")
	if postID == "" {
		response.BadRequest(c, "缺少动态ID")
		return
	}

	if err := h.postService.UnlikePost(c.Request.Context(), postID, userID.(string)); err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, nil)
}
