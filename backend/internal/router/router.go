package router

import (
	"stridemoor-api/internal/handler"
	"stridemoor-api/internal/middleware"
	"stridemoor-api/pkg/jwt"

	"github.com/gin-gonic/gin"
)

func SetupRouter(
	userHandler *handler.UserHandler,
	runHandler *handler.RunHandler,
	routeHandler *handler.RouteHandler,
	friendshipHandler *handler.FriendshipHandler,
	challengeHandler *handler.ChallengeHandler,
	uploadHandler *handler.UploadHandler,
	postHandler *handler.PostHandler,
	followHandler *handler.FollowHandler,
	paojingHandler *handler.PaojingHandler,
	deviceHandler *handler.DeviceHandler,
	aiHandler *handler.AIHandler,
	jwtGen *jwt.Generator,
) *gin.Engine {
	r := gin.Default()

	// 静态文件服务（头像/GPX 等上传文件）
	r.Static("/static", "./uploads")

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"code":    0,
			"message": "ok",
			"data": gin.H{
				"service": "stridemoor-api",
				"version": "v1.0.0",
			},
		})
	})

	// 公开路由
	api := r.Group("/api/v1")
	{
		api.POST("/auth/register", userHandler.Register)
		api.POST("/auth/login", userHandler.Login)
		api.POST("/auth/refresh", userHandler.RefreshToken)
	}

	// 需要认证的路由
	auth := api.Group("")
	auth.Use(middleware.JWTAuth(jwtGen))
	{
		auth.GET("/user/profile", userHandler.GetProfile)
		auth.PUT("/user/profile", userHandler.UpdateProfile)
		auth.PUT("/user/password", userHandler.UpdatePassword)
		auth.GET("/users/:id/stats", userHandler.GetUserStats)
		auth.GET("/user/stats/heats", userHandler.GetHeatStats)

		// 跑步模块
		auth.POST("/runs/start", runHandler.StartRun)
		auth.POST("/runs/:id/samples", runHandler.UploadSamples)
		auth.POST("/runs/:id/finish", runHandler.FinishRun)
		auth.GET("/runs", runHandler.GetRunList)
		auth.GET("/runs/averages", runHandler.GetRunAverages)
		auth.GET("/runs/:id", runHandler.GetRunDetail)
		auth.POST("/runs/:id/bookmark", runHandler.BookmarkRun)
		auth.DELETE("/runs/:id/bookmark", runHandler.UnbookmarkRun)
		auth.GET("/runs/bookmarks/list", runHandler.ListBookmarks)
		auth.POST("/runs/:id/companion", runHandler.CompanionComplete)
		auth.DELETE("/runs/:id", runHandler.DeleteRun)

		// 路线模块
		auth.POST("/routes", routeHandler.CreateRoute)
		auth.POST("/routes/validate", routeHandler.ValidateRoute)
		auth.GET("/routes", routeHandler.ListRoutes)
		auth.GET("/routes/favorites", routeHandler.ListFavorites)
		auth.GET("/routes/:id", routeHandler.GetRouteDetail)
		auth.POST("/routes/:id/favorite", routeHandler.FavoriteRoute)
		auth.DELETE("/routes/:id/favorite", routeHandler.UnfavoriteRoute)
		auth.DELETE("/routes/:id", routeHandler.DeleteRoute)
		auth.GET("/routes/:id/leaderboard", routeHandler.GetLeaderboard)
		auth.POST("/routes/:id/rate", routeHandler.RateRoute)
		auth.PUT("/routes/:id", routeHandler.UpdateRoute)
		auth.GET("/routes/nearby", routeHandler.NearbyRoutes)

		// 好友模块
		auth.POST("/friends/requests", friendshipHandler.SendFriendRequest)
		auth.GET("/friends/requests/pending", friendshipHandler.ListPendingRequests)
		auth.POST("/friends/requests/:id/accept", friendshipHandler.AcceptFriendRequest)
		auth.POST("/friends/requests/:id/reject", friendshipHandler.RejectFriendRequest)
		auth.GET("/friends", friendshipHandler.ListFriends)
		auth.DELETE("/friends/:id", friendshipHandler.RemoveFriend)

		// 挑战模块
		auth.POST("/challenges", challengeHandler.CreateChallenge)
		auth.GET("/challenges", challengeHandler.ListChallenges)
		auth.GET("/challenges/:id", challengeHandler.GetChallengeDetail)
		auth.POST("/challenges/:id/accept", challengeHandler.AcceptChallenge)
		auth.POST("/challenges/:id/start", challengeHandler.StartChallenge)
		auth.POST("/challenges/:id/complete", challengeHandler.CompleteChallenge)
		auth.POST("/challenges/:id/cancel", challengeHandler.CancelChallenge)
		auth.GET("/challenges/:id/comparison", challengeHandler.GetComparison)

		// 文件上传模块
		auth.POST("/upload/avatar", uploadHandler.UploadAvatar)
		auth.POST("/upload/gpx", uploadHandler.UploadGPX)

		// 关注模块
		auth.POST("/users/:id/follow", followHandler.FollowUser)
		auth.DELETE("/users/:id/follow", followHandler.UnfollowUser)
		auth.GET("/users/followings", followHandler.ListFollowings)
		auth.GET("/users/followers", followHandler.ListFollowers)

		// 跑友动态模块
		auth.GET("/posts", postHandler.ListPosts)
		auth.POST("/posts", postHandler.CreatePost)
		auth.GET("/posts/:id", postHandler.GetPostDetail)
		auth.POST("/posts/:id/comments", postHandler.CreateComment)
		auth.GET("/posts/:id/comments", postHandler.ListComments)
		auth.POST("/posts/:id/like", postHandler.LikePost)
		auth.DELETE("/posts/:id/like", postHandler.UnlikePost)

		// 跑境模块
		auth.GET("/user/paojing", paojingHandler.GetPaojing)
		auth.POST("/user/paojing/check", paojingHandler.CheckUpgrade)

		// 设备管理模块
		auth.GET("/devices", deviceHandler.ListDevices)
		auth.POST("/devices", deviceHandler.BindDevice)
		auth.PATCH("/devices/:id", deviceHandler.UpdateDevice)
		auth.DELETE("/devices/:id", deviceHandler.UnbindDevice)

		// 第三方跑步记录导入模块
		auth.POST("/runs/import", deviceHandler.ImportRun)
		auth.GET("/runs/import/history", deviceHandler.ListImportHistory)
		auth.DELETE("/runs/import/:id", deviceHandler.DeleteImported)

		// 调试接口：强制设境界（开发环境使用）
		auth.POST("/admin/realm/debug-set", paojingHandler.DebugSetRealm)

		// AI 功能模块
		auth.POST("/ai/run-analysis", aiHandler.RunAnalysis)
		auth.GET("/ai/analyses/:run_id", aiHandler.GetAnalysis)
		auth.GET("/ai/features", aiHandler.ListFeatures)
	}

	return r
}
