package middleware

import (
	"strings"

	"stridemoor-api/pkg/jwt"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

func JWTAuth(jwtGen *jwt.Generator) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.Unauthorized(c, "缺少 Authorization 头")
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			response.Unauthorized(c, "Authorization 格式错误")
			c.Abort()
			return
		}

		claims, err := jwtGen.ParseToken(parts[1])
		if err != nil {
			response.Unauthorized(c, "Token 无效或已过期")
			c.Abort()
			return
		}

		c.Set("userID", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Next()
	}
}
