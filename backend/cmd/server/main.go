package main

import (
	"log"
	"os"
	"time"

	"gopkg.in/yaml.v3"

	"stridemoor-api/internal/handler"
	"stridemoor-api/internal/repository"
	"stridemoor-api/internal/router"
	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/database"
	"stridemoor-api/pkg/jwt"
)

type Config struct {
	Server struct {
		Port string `yaml:"port"`
	} `yaml:"server"`
	Database struct {
		DSN string `yaml:"dsn"`
	} `yaml:"database"`
	JWT struct {
		Secret      string `yaml:"secret"`
		ExpireHours int    `yaml:"expire_hours"`
		RefreshDays int    `yaml:"refresh_days"`
	} `yaml:"jwt"`
	MinIO struct {
		Endpoint  string `yaml:"endpoint"`
		AccessKey string `yaml:"access_key"`
		SecretKey string `yaml:"secret_key"`
		Bucket    string `yaml:"bucket"`
		UseSSL    bool   `yaml:"use_ssl"`
	} `yaml:"minio"`
}

func main() {
	// 加载配置
	data, err := os.ReadFile("configs/config.yaml")
	if err != nil {
		log.Fatalf("读取配置失败: %v", err)
	}
	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		log.Fatalf("解析配置失败: %v", err)
	}

	// 支持环境变量覆盖数据库 DSN（Docker 环境下使用）
	dsn := cfg.Database.DSN
	if envDSN := os.Getenv("DB_DSN"); envDSN != "" {
		dsn = envDSN
		log.Printf("使用环境变量 DB_DSN 覆盖数据库连接")
	}

	// 初始化数据库
	db, err := database.Init(dsn)
	if err != nil {
		log.Fatalf("初始化数据库失败: %v", err)
	}

	// 初始化 MinIO
	minioCfg := &database.MinIOConfig{
		Endpoint:  cfg.MinIO.Endpoint,
		AccessKey: cfg.MinIO.AccessKey,
		SecretKey: cfg.MinIO.SecretKey,
		Bucket:    cfg.MinIO.Bucket,
		UseSSL:    cfg.MinIO.UseSSL,
		ServerURL: "",
	}
	minioClient, err := database.NewMinIOClient(minioCfg)
	if err != nil {
		log.Fatalf("初始化 MinIO 失败: %v", err)
	}

	// 初始化 JWT
	jwtConfig := &jwt.Config{
		Secret:     cfg.JWT.Secret,
		AccessTTL:  time.Duration(cfg.JWT.ExpireHours) * time.Hour,
		RefreshTTL: time.Duration(cfg.JWT.RefreshDays) * 24 * time.Hour,
	}
	jwtGen := jwt.NewGenerator(jwtConfig)

	// 初始化依赖
	userRepo := repository.NewUserRepository(db)
	runRepo := repository.NewRunRepository(db)
	sampleRepo := repository.NewRunSampleRepository(db)
	lbRepo := repository.NewLeaderboardRepository(db)
	challengeRepo := repository.NewChallengeRepository(db)
	bmRepo := repository.NewRunBookmarkRepository(db)
	routeRepo := repository.NewRouteRepository(db)
	followRepo := repository.NewFollowRepository(db)
	favRepo := repository.NewFavoriteRepository(db)
	friendRepo := repository.NewFriendshipRepository(db)
	postRepo := repository.NewPostRepository(db)
	deviceRepo := repository.NewDeviceRepository(db)

	userService := service.NewUserService(userRepo, followRepo, bmRepo, challengeRepo, jwtGen)
	userHandler := handler.NewUserHandler(userService)

	runService := service.NewRunService(runRepo, sampleRepo, userRepo, lbRepo, challengeRepo, bmRepo, routeRepo)
	runHandler := handler.NewRunHandler(runService)

	routeService := service.NewRouteService(routeRepo, favRepo, lbRepo)
	routeHandler := handler.NewRouteHandler(routeService)

	friendshipService := service.NewFriendshipService(friendRepo, userRepo)
	friendshipHandler := handler.NewFriendshipHandler(friendshipService)

	challengeService := service.NewChallengeService(challengeRepo, runRepo, userRepo, routeRepo)
	challengeHandler := handler.NewChallengeHandler(challengeService)

	uploadService := service.NewUploadService(minioClient, userRepo)
	uploadHandler := handler.NewUploadHandler(uploadService)

	postService := service.NewPostService(postRepo)
	postHandler := handler.NewPostHandler(postService)

	followService := service.NewFollowService(followRepo, userRepo)
	followHandler := handler.NewFollowHandler(followService)

	deviceService := service.NewDeviceService(deviceRepo, runRepo, sampleRepo)
	deviceHandler := handler.NewDeviceHandler(deviceService)

	// 跑境模块（在 postService/runService 之后创建以避免循环依赖）
	paojingService := service.NewPaojingService(db, userRepo, postService)
	paojingHandler := handler.NewPaojingHandler(paojingService)

	// AI 功能模块
	aiKeyRepo := repository.NewAIKeyRepository()
	aiLogRepo := repository.NewAICallLogRepository()
	aiFeatureRepo := repository.NewFeatureConfigRepository(db)
	aiFeatureRepo.StartAutoRefresh() // 每10分钟刷新缓存
	aiSvc := service.NewAIService(aiKeyRepo, aiLogRepo, aiFeatureRepo)
	aiAnalysisRepo := repository.NewAIAnalysisRepository()
	aiHandler := handler.NewAIHandler(aiSvc, runRepo, userRepo, aiAnalysisRepo)

	// 跑境与跑步/动态/挑战模块联动
	runService.SetPaojingService(paojingService)
	postService.SetPaojingService(paojingService)
	challengeService.SetPaojingService(paojingService)

	// 设置路由
	r := router.SetupRouter(userHandler, runHandler, routeHandler, friendshipHandler, challengeHandler, uploadHandler, postHandler, followHandler, paojingHandler, deviceHandler, aiHandler, jwtGen)

	log.Printf("🚀 StrideMoor API 启动成功，监听 :%s", cfg.Server.Port)
	if err := r.Run(":" + cfg.Server.Port); err != nil {
		log.Fatalf("启动服务失败: %v", err)
	}
}
