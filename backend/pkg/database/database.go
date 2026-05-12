package database

import (
	"fmt"
	"time"

	"stridemoor-api/internal/model"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DB 全局数据库实例
var DB *gorm.DB

// Init 初始化数据库连接（直接传入 DSN 字符串）
func Init(dsn string) (*gorm.DB, error) {
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, fmt.Errorf("连接数据库失败: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("获取底层连接池失败: %w", err)
	}

	// 连接池配置
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetConnMaxLifetime(time.Hour)

	// 自动迁移所有模型
	if err := db.AutoMigrate(
		&model.User{},
		&model.Route{},
		&model.RoutePoint{},
		&model.Run{},
		&model.RunSplit{},
		&model.RunSample{},
		&model.Favorite{},
		&model.Follow{},
		&model.Challenge{},
		&model.Comparison{},
		&model.Friendship{},
		&model.Leaderboard{},
		&model.Post{},
		&model.PostComment{},
		&model.PostLike{},
		&model.Device{},
		&model.ImportRecord{},
		&model.AIAPIKey{},
		&model.AICallLog{},
		&model.AiFeatureConfig{},
	); err != nil {
		return nil, fmt.Errorf("数据库自动迁移失败: %w", err)
	}

	// 兜底：若 AutoMigrate 遗漏 route_points（已有数据库场景），显式创建
	_ = db.Exec(`CREATE TABLE IF NOT EXISTS route_points (
		route_id    CHAR(36) NOT NULL,
		point_index INT NOT NULL,
		latitude    DECIMAL(10,7) NOT NULL,
		longitude   DECIMAL(10,7) NOT NULL,
		altitude    DECIMAL(10,2) DEFAULT NULL,
		PRIMARY KEY (route_id, point_index),
		INDEX idx_route (route_id)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`)

	DB = db
	return db, nil
}

// Close 关闭数据库连接
func Close() error {
	if DB == nil {
		return nil
	}
	sqlDB, err := DB.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}
