-- Fix missing route_points table (Error 1146)
-- Execute this SQL in the stridemoor MySQL database if AutoMigrate failed to create the table

CREATE TABLE IF NOT EXISTS `route_points` (
  `route_id` char(36) NOT NULL,
  `point_index` int NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `altitude` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`route_id`,`point_index`),
  KEY `idx_route_points_route_id` (`route_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
