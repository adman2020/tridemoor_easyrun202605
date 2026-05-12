-- 灌数据到深圳湾公园晨跑线 (5km) 测试打卡榜和成绩榜
-- route_id = 86992120-3eec-4ce4-b44d-8da0c6691632

-- 韩立 - 打卡 10 次 (榜首)
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
SELECT UUID(), 'b8b387d9-4bfe-4de3-a441-e56a0e760224', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL n DAY), DATE_SUB(NOW(), INTERVAL n DAY) + INTERVAL (1500 + FLOOR(RAND()*200)) SECOND,
  5000.00, 1500 + FLOOR(RAND()*200), 300 + FLOOR(RAND()*40), 172 + FLOOR(RAND()*8), 15 + FLOOR(RAND()*10), NOW(), NOW()
FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) nums;

-- 南宫婉 - 打卡 8 次
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
SELECT UUID(), '664cf4cc-ee65-44ff-8403-7c82c82e471b', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL n DAY), DATE_SUB(NOW(), INTERVAL n DAY) + INTERVAL (1600 + FLOOR(RAND()*150)) SECOND,
  5000.00, 1600 + FLOOR(RAND()*150), 320 + FLOOR(RAND()*30), 170 + FLOOR(RAND()*6), 10 + FLOOR(RAND()*8), NOW(), NOW()
FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8) nums;

-- 元瑶 - 打卡 7 次
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
SELECT UUID(), '7862e67b-1e0f-428d-90b2-22df7c006d5e', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL n DAY), DATE_SUB(NOW(), INTERVAL n DAY) + INTERVAL (1550 + FLOOR(RAND()*180)) SECOND,
  5000.00, 1550 + FLOOR(RAND()*180), 310 + FLOOR(RAND()*36), 168 + FLOOR(RAND()*8), 12 + FLOOR(RAND()*6), NOW(), NOW()
FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7) nums;

-- 紫灵 - 打卡 6 次
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
SELECT UUID(), '2d575e7d-5bd0-4abf-ad8f-17b09fba9b3f', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL n DAY), DATE_SUB(NOW(), INTERVAL n DAY) + INTERVAL (1750 + FLOOR(RAND()*200)) SECOND,
  5000.00, 1750 + FLOOR(RAND()*200), 350 + FLOOR(RAND()*40), 165 + FLOOR(RAND()*6), 8 + FLOOR(RAND()*8), NOW(), NOW()
FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6) nums;

-- 银月 - 打卡 5 次 (最快选手)
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
SELECT UUID(), 'acf32306-192a-4dfb-9416-3f32d60dd60e', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL n DAY), DATE_SUB(NOW(), INTERVAL n DAY) + INTERVAL (1480 + FLOOR(RAND()*120)) SECOND,
  5000.00, 1480 + FLOOR(RAND()*120), 296 + FLOOR(RAND()*24), 175 + FLOOR(RAND()*4), 20 + FLOOR(RAND()*5), NOW(), NOW()
FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) nums;

-- 向之礼 - 打卡 4 次
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
SELECT UUID(), 'eb577996-0b55-4bba-b9d4-82d5a20f3ccb', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL n DAY), DATE_SUB(NOW(), INTERVAL n DAY) + INTERVAL (2000 + FLOOR(RAND()*300)) SECOND,
  5000.00, 2000 + FLOOR(RAND()*300), 400 + FLOOR(RAND()*60), 160 + FLOOR(RAND()*8), 5 + FLOOR(RAND()*8), NOW(), NOW()
FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) nums;

-- 东君(主) - 打卡 3 次
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
SELECT UUID(), '76702697-d684-4567-9207-a25a5bad0d10', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL n DAY), DATE_SUB(NOW(), INTERVAL n DAY) + INTERVAL (1700 + FLOOR(RAND()*180)) SECOND,
  5000.00, 1700 + FLOOR(RAND()*180), 340 + FLOOR(RAND()*36), 166 + FLOOR(RAND()*6), 8 + FLOOR(RAND()*6), NOW(), NOW()
FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3) nums;

-- 李化元 - 打卡 2 次
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
SELECT UUID(), '260e08a3-71a2-4c0e-8460-a76036cad4aa', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL n DAY), DATE_SUB(NOW(), INTERVAL n DAY) + INTERVAL (1900 + FLOOR(RAND()*250)) SECOND,
  5000.00, 1900 + FLOOR(RAND()*250), 380 + FLOOR(RAND()*50), 162 + FLOOR(RAND()*6), 6 + FLOOR(RAND()*5), NOW(), NOW()
FROM (SELECT 1 n UNION ALL SELECT 2) nums;

-- 厉飞雨 - 打卡 2 次 (次快)
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
SELECT UUID(), '4019e9a3-2056-410e-8249-85b88d245062', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL n DAY), DATE_SUB(NOW(), INTERVAL n DAY) + INTERVAL (1420 + FLOOR(RAND()*100)) SECOND,
  5000.00, 1420 + FLOOR(RAND()*100), 284 + FLOOR(RAND()*20), 178 + FLOOR(RAND()*5), 22 + FLOOR(RAND()*5), NOW(), NOW()
FROM (SELECT 1 n UNION ALL SELECT 2) nums;

-- 冰凤 - 打卡 1 次
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
VALUES (UUID(), '7565d507-ce60-430f-9fdf-bd72ced9115c', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY) + INTERVAL 1650 SECOND,
  5000.00, 1650, 330, 170, 10, NOW(), NOW());

-- 金童 - 打卡 1 次
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
VALUES (UUID(), '11cef625-dd60-4659-ad0f-fa439eec909c', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1580 SECOND,
  5000.00, 1580, 316, 172, 14, NOW(), NOW());

-- 墨彩环 - 打卡 1 次
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
VALUES (UUID(), 'a7ba8ceb-7190-4ed2-936d-73f1a5b059c4', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY) + INTERVAL 1850 SECOND,
  5000.00, 1850, 370, 168, 6, NOW(), NOW());

-- 温天仁 - 打卡 1 次 (很慢)
INSERT IGNORE INTO runs (id, user_id, route_id, start_time, end_time, total_distance, total_time, avg_pace, avg_cadence, elevation_gain, created_at, updated_at)
VALUES (UUID(), 'e12300e3-01c9-496b-902b-df5c86ffa37f', '86992120-3eec-4ce4-b44d-8da0c6691632',
  DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY) + INTERVAL 2500 SECOND,
  5000.00, 2500, 500, 155, 3, NOW(), NOW());

-- ================= 验证数据 =================
SELECT '===== 打卡榜 =====' AS label;
SELECT u.nickname, COUNT(r.id) AS checkin_count, ROUND(MIN(r.total_time)/60, 1) AS best_min
FROM runs r JOIN users u ON r.user_id = u.id
WHERE r.route_id = '86992120-3eec-4ce4-b44d-8da0c6691632'
GROUP BY u.nickname ORDER BY checkin_count DESC, best_min ASC;

SELECT '===== 成绩榜 =====' AS label;
SELECT u.nickname, MIN(r.total_time) AS best_sec, ROUND(MIN(r.total_time)/60, 2) AS best_min,
  ROUND(MIN(r.avg_pace)/100.0, 2) AS best_pace_min_km
FROM runs r JOIN users u ON r.user_id = u.id
WHERE r.route_id = '86992120-3eec-4ce4-b44d-8da0c6691632'
GROUP BY u.nickname ORDER BY best_sec ASC;

SELECT CONCAT('共计 ', COUNT(*), ' 条跑步记录') AS summary FROM runs WHERE route_id = '86992120-3eec-4ce4-b44d-8da0c6691632';
