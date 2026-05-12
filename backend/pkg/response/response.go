package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

const (
	CodeSuccess          = 0
	CodeError            = 1
	CodeBadRequest       = 1001
	CodeUnauthorized     = 1002
	CodeTokenExpired     = 1003
	CodeNotFound         = 1004
	CodeUserExists       = 2001
	CodePasswordError    = 2002
	CodeRouteNotFound    = 3001
	CodeChallengeExpired = 4001
)

func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{Code: CodeSuccess, Message: "success", Data: data})
}

func Error(c *gin.Context, code int, message string) {
	if message == "" {
		switch code {
		case CodeBadRequest:
			message = "参数错误"
		case CodeUnauthorized:
			message = "未授权"
		case CodeTokenExpired:
			message = "Token 已过期"
		case CodeNotFound:
			message = "资源不存在"
		case CodeUserExists:
			message = "用户已存在"
		case CodePasswordError:
			message = "密码错误"
		default:
			message = "unknown error"
		}
	}
	c.JSON(http.StatusOK, Response{Code: code, Message: message})
}

func BadRequest(c *gin.Context, message string) {
	c.JSON(http.StatusBadRequest, Response{Code: CodeBadRequest, Message: message})
}

func Unauthorized(c *gin.Context, message string) {
	c.JSON(http.StatusUnauthorized, Response{Code: CodeUnauthorized, Message: message})
}
