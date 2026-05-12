#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StrideMoor: 基于 Nominatim verified 坐标生成准确 GPS 轨迹
WGS-84 坐标 → 定义 waypoints → GCJ-02 存储
"""
import json, math, random, time, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
random.seed(42)

# ============ Coordinate tools ============
def wgs84_to_gcj02(wgs_lat, wgs_lng):
    a, ee = 6378245.0, 0.00669342162296594323
    x, y = wgs_lng - 105.0, wgs_lat - 35.0
    dLon = 300.0 + x + 2.0*y + 0.1*x*x + 0.1*x*y + 0.1*math.sqrt(abs(x))
    dLon += (20.0*math.sin(6.0*x*math.pi) + 20.0*math.sin(2.0*x*math.pi))*2.0/3.0
    dLon += (20.0*math.sin(x*math.pi) + 40.0*math.sin(x/3.0*math.pi))*2.0/3.0
    dLon += (150.0*math.sin(x/12.0*math.pi) + 300.0*math.sin(x/30.0*math.pi))*2.0/3.0
    dLat = -100.0 + 2.0*x + 3.0*y + 0.2*y*y + 0.1*x*y + 0.2*math.sqrt(abs(x))
    dLat += (20.0*math.sin(6.0*x*math.pi) + 20.0*math.sin(2.0*x*math.pi))*2.0/3.0
    dLat += (20.0*math.sin(y*math.pi) + 40.0*math.sin(y/3.0*math.pi))*2.0/3.0
    dLon += (160.0*math.sin(y/12.0*math.pi) + 320.0*math.sin(y*math.pi/30.0))*2.0/3.0
    rad_lat = wgs_lat/180.0*math.pi
    magic = math.sin(rad_lat); magic = 1 - ee*magic*magic
    sqrt_magic = math.sqrt(magic)
    dLat = (dLat*180.0)/((a*(1-ee))/(magic*sqrt_magic)*math.pi)
    dLon = (dLon*180.0)/(a/sqrt_magic*math.cos(rad_lat)*math.pi)
    return wgs_lat+dLat, wgs_lng+dLon

def haversine(lat1, lng1, lat2, lng2):
    R = 6371000
    dlat = (lat2-lat1)*math.pi/180
    dlng = (lng2-lng1)*math.pi/180
    a = math.sin(dlat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dlng/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def make_circle(center_lat, center_lng, radius_m, n_pts=16, start_angle=0):
    """Generate points around a circle"""
    pts = []
    for i in range(n_pts):
        angle = start_angle + (360.0 * i / n_pts)
        dy = radius_m * math.cos(angle * math.pi / 180) / 111320
        dx = radius_m * math.sin(angle * math.pi / 180) / (111320 * math.cos(center_lat * math.pi / 180))
        pts.append((center_lat + dy, center_lng + dx))
    return pts

def make_line(start_lat, start_lng, end_lat, end_lng, mid_offset=0):
    """Linear path with optional midpoint offset"""
    pts = [(start_lat, start_lng)]
    if mid_offset:
        mid_lat = (start_lat + end_lat) / 2 + mid_offset[0]
        mid_lng = (start_lng + end_lng) / 2 + mid_offset[1]
        pts.append((mid_lat, mid_lng))
    pts.append((end_lat, end_lng))
    return pts

def generate_track(waypoints_wgs, target_m, point_interval=10):
    """Densify waypoints into GPS track"""
    # Calculate raw path length
    raw_dist = 0
    for i in range(1, len(waypoints_wgs)):
        raw_dist += haversine(waypoints_wgs[i-1][0], waypoints_wgs[i-1][1],
                              waypoints_wgs[i][0], waypoints_wgs[i][1])
    
    # If too short, loop the path
    if raw_dist < target_m * 0.7:
        loops = max(1, int(target_m * 1.3 / raw_dist))
        loop_pts = []
        for lap in range(loops):
            pts = waypoints_wgs if lap % 2 == 0 else list(reversed(waypoints_wgs))
            for p in pts:
                loop_pts.append(p)
        waypoints_wgs = loop_pts
    
    # Densify
    dense = []
    for i in range(len(waypoints_wgs)-1):
        lat1, lng1 = waypoints_wgs[i]
        lat2, lng2 = waypoints_wgs[i+1]
        seg_dist = haversine(lat1, lng1, lat2, lng2)
        steps = max(2, int(seg_dist / 3))
        for j in range(steps):
            t = j / steps
            dense.append((lat1 + (lat2-lat1)*t, lng1 + (lng2-lng1)*t))
    dense.append(waypoints_wgs[-1])
    
    # Sample at target interval
    total_raw = 0
    for i in range(1, len(dense)):
        total_raw += haversine(dense[i-1][0], dense[i-1][1], dense[i][0], dense[i][1])
    
    n_pts = max(10, int(total_raw / point_interval))
    if n_pts > len(dense):
        n_pts = len(dense)
    
    idxs = [int(i * (len(dense)-1) / (n_pts-1)) for i in range(n_pts)]
    pts = []
    for idx in idxs:
        lat, lng = dense[idx]
        # GPS noise
        nl = random.uniform(-0.00003, 0.00003)
        ng = random.uniform(-0.00003, 0.00003)
        pts.append((lat + nl, lng + ng))
    
    act_dist = 0
    for i in range(1, len(pts)):
        act_dist += haversine(pts[i-1][0], pts[i-1][1], pts[i][0], pts[i][1])
    
    return pts, act_dist

# ============ Route definitions ============
# Each: (route_id, name, city, diff, target_m, tags, waypoints_in_WGS84)
ROUTES = [
# === 莲花山公园 (center: 22.5566, 114.0532) ===
("d5c45106-da86-450c-ac37-169086dbf41b", "莲花山公园绕湖", "深圳", 1, 4000,
 '["公园","环湖","莲花山"]',
 make_circle(22.5566, 114.0532, 350, 12)),  # ~2.2km circle, ~2 laps = 4.4km

("5aa84db1-c4f7-4d71-8876-49a9ca444ba8", "莲花山环湖跑", "深圳", 1, 4900,
 '["公园","环湖","深圳"]',
 make_circle(22.5560, 114.0540, 400, 14)),  # ~2.5km circle, ~2 laps

# === 深圳湾公园 (center: 22.5246, 113.9880) ===
# Runs along coast from 红树林 (113.998) to 深圳湾大桥 area (113.955)
("c3d5a64b-503e-401f-a068-c154aede5755", "深圳湾公园沿海跑道", "深圳", 1, 5300,
 '["海滨","跑道","深圳湾"]',
 make_line(22.530, 113.998, 22.519, 113.975, (0.002, -0.005))),

("86992120-3eec-4ce4-b44d-8da0c6691632", "深圳湾公园晨跑线", "深圳", 1, 4600,
 '["海滨","晨跑","深圳"]',
 make_line(22.528, 113.990, 22.515, 113.958, (0.001, -0.003))),

# === 大沙河生态长廊 (center: 22.560, 113.956) ===
# Runs N-S along Dasha River from 深圳湾 to 塘朗山 area
("d590c5e5-f1e3-4e72-a8cf-c8ade4b83907", "大沙河生态长廊", "深圳", 1, 16800,
 '["绿道","河滨","LSD"]',
 make_line(22.520, 113.950, 22.575, 113.954, (0, -0.001))),

("ee9ab030-977c-463f-93f0-2e2d823b0d60", "大沙河生态长廊", "深圳", 1, 6800,
 '["绿道","河滨","深圳"]',
 make_line(22.520, 113.950, 22.552, 113.951, (0, -0.002))),

# === 梅林水库 (22.5751, 114.0239) ===
("4a440fed-0ceb-4a4f-a0e1-324f48509148", "梅林水库绿道", "深圳", 1, 8000,
 '["跑步","绿道","深圳"]',
 make_circle(22.575, 114.024, 600, 12)),  # ~3.8km loop, ~2 laps

# === 梧桐山 (22.5611, 114.178) ===
("c2832561-5363-4849-bff2-4b5b79576a2c", "梧桐山绿道", "深圳", 3, 15000,
 '["跑步","绿道","梧桐山"]',
 make_line(22.582, 114.213, 22.590, 114.221, (0.003, -0.002))),

# === 东湖公园 (22.5656, 114.1437) ===
("5c473ba3-e055-4d7d-aa26-a6515f2aaab9", "东湖公园绿道", "深圳", 1, 5000,
 '["跑步","公园","东湖"]',
 make_circle(22.566, 114.144, 400, 12)),  # ~2.5km loop, ~2 laps

# === 银湖山郊野公园 (around 22.57, 114.085) ===
("fa4f2f71-e158-49ba-8a0e-5c12828cdcf6", "银湖山郊野径", "深圳", 3, 12000,
 '["越野","郊野","银湖山"]',
 make_line(22.568, 114.084, 22.585, 114.082, (0.008, -0.002))),

# === 香蜜公园 (22.5498, 114.0166) → but running is around 香蜜湖 (22.548, 114.038)
("b875099a-6606-4a00-af6a-f174dcafc331", "香蜜公园环湖", "深圳", 1, 2500,
 '["公园","环湖","香蜜"]',
 make_circle(22.548, 114.038, 200, 10)),  # ~1.2km loop, ~2 laps

("843ebc2a-d6c2-4be9-8a75-8bbbd8935a11", "香蜜公园夜跑", "深圳", 1, 3800,
 '["夜跑","公园","福田"]',
 make_circle(22.549, 114.038, 300, 12)),  # ~1.9km loop, ~2 laps

# === 南山公园 (22.4960, 113.8991) ===
("62cce8c7-ece5-4d56-b1a7-338783422b96", "南山公园环山道", "深圳", 2, 7000,
 '["环山","公园","南山"]',
 make_circle(22.503, 113.925, 450, 12)),  # ~2.8km loop, ~2.5 laps

("4e3137b5-d60f-4feb-99a2-e5a2f1e24375", "南山公园登顶路", "深圳", 3, 2200,
 '["登山","爬升","南山"]',
 make_line(22.503, 113.921, 22.510, 113.928, (0.003, 0.002))),

# === 中心公园 (22.5353, 114.0702) ===
("519ffc17-cf9b-434c-b496-b5b4f0e779bc", "深圳中心公园绿道", "深圳", 1, 4000,
 '["公园","绿道","中心公园"]',
 make_line(22.530, 114.065, 22.548, 114.071, (0.002, 0.002))),

("c365a069-404f-44ea-b808-2f9e749b1e24", "中心公园花径", "深圳", 1, 2800,
 '["公园","花径","放松"]',
 make_circle(22.543, 114.066, 220, 10)),

# === 欢乐港湾-前海 (22.535, 113.908) ===
("3da7213f-475a-4f15-b14a-93f0121dc2c4", "欢乐港湾-前海绿道", "深圳", 1, 7000,
 '["海滨","绿道","前海"]',
 make_line(22.534, 113.893, 22.520, 113.915, (-0.002, 0.005))),

# === 盐田海滨栈道 (22.56, 114.24) ===
("b3d17360-21b5-4366-bf80-8b77be911762", "盐田海滨栈道", "深圳", 1, 12000,
 '["海滨","栈道","盐田"]',
 make_line(22.545, 114.230, 22.580, 114.258, (0.005, 0.003))),

# === 福田河绿道 (22.5547, 114.0738) ===
("b5901b3c-5704-495d-a6da-b472f86001d3", "福田河绿道", "深圳", 1, 8000,
 '["绿道","河滨","福田"]',
 make_line(22.558, 114.072, 22.530, 114.076, (0.001, -0.002))),

# === 人才公园 (22.5137, 113.9442) ===
("995aa063-40f0-4c8b-985f-823d708d46eb", "人才公园环湖", "深圳", 1, 3500,
 '["公园","环湖","夜景"]',
 make_circle(22.520, 113.946, 280, 10)),  # ~1.8km loop, ~2 laps

("4bf307ae-f4d4-4485-a433-b53ec6bb74bd", "人才公园海滨线", "深圳", 1, 5500,
 '["海滨","公园","夜景"]',
 make_line(22.523, 113.950, 22.510, 113.940, (0.001, -0.005))),

# === 塘朗山 (22.5774, 113.9772) ===
("95c1e112-511c-4048-8856-9369360afebd", "塘朗山郊野径", "深圳", 3, 10000,
 '["越野","爬升","塘朗山"]',
 make_line(22.588, 114.002, 22.580, 113.996, (-0.002, -0.004))),

("f712c0ec-6af0-43b6-a056-3018c6bdb2c1", "塘朗山越野跑", "深圳", 3, 8000,
 '["越野","爬升","深圳"]',
 make_line(22.590, 114.000, 22.582, 113.995, (0.003, -0.002))),

# === 笔架山 (22.5652, 114.0765) ===
("e3ba6405-0e30-4d1c-a801-b6e7f130f9a9", "笔架山公园环山", "深圳", 2, 5500,
 '["环山","公园","笔架山"]',
 make_circle(22.564, 114.074, 450, 12)),  # ~2.8km loop, ~2 laps

("6bd63195-4f54-4108-8cab-71db9589d679", "笔架山环山径", "深圳", 2, 4000,
 '["环山","公园","打卡"]',
 make_circle(22.565, 114.074, 350, 10)),  # ~2.2km loop, ~2 laps

# === 洪湖公园 (22.5675, 114.1145) ===
("68b1bd0b-5e85-4a02-a8b2-957453c5e46f", "洪湖公园晨跑", "深圳", 1, 3200,
 '["公园","环湖","罗湖"]',
 make_circle(22.566, 114.117, 250, 10)),  # ~1.6km loop, ~2 laps

# === 福田CBD ===
("22ce365a-57b6-4a6b-b4ba-961c3ee8925c", "福田CBD夜跑", "深圳", 1, 4200,
 '["夜跑","城市","CBD"]',
 make_circle(22.543, 114.057, 380, 12)),  # ~2.4km loop, ~2 laps

# === 奥体中心 ===
("9437791a-95cf-4b40-a291-f34a352a4f87", "奥体中心绕圈", "深圳", 1, 5000,
 '["操场","绕圈","训练"]',
 make_circle(22.537, 113.986, 400, 12)),  # ~2.5km loop, ~2 laps

]

# ============ Generate SQL ============
point_sqls = []
update_sqls = []

for idx, (rid, name, city, diff, target_m, tags, waypoints_wgs) in enumerate(ROUTES):
    waypoints_wgs = [(lat, lng) for lat, lng in waypoints_wgs]
    pts, actual_dist = generate_track(waypoints_wgs, target_m)
    
    # Convert WGS-84 to GCJ-02
    pts_gcj = [wgs84_to_gcj02(lat, lng) for lat, lng in pts]
    actual_dist_gcj = 0
    for i in range(1, len(pts_gcj)):
        actual_dist_gcj += haversine(pts_gcj[i-1][0], pts_gcj[i-1][1], pts_gcj[i][0], pts_gcj[i][1])
    
    slat, slng = pts_gcj[0]
    clat = sum(p[0] for p in pts_gcj) / len(pts_gcj)
    clng = sum(p[1] for p in pts_gcj) / len(pts_gcj)
    dev = abs(actual_dist_gcj - target_m) / target_m * 100
    
    label = "OK" if dev < 15 else ("~" if dev < 30 else "YIKES")
    print(f"[{idx+1}/{len(ROUTES)}] {name}: {actual_dist_gcj/1000:.2f}km {len(pts_gcj)}pts ({label} {dev:.0f}%)")
    
    for i, (lat, lng) in enumerate(pts_gcj):
        point_sqls.append(f"('{rid}',{i},{lat:.7f},{lng:.7f},0)")
    
    update_sqls.append(
        f"UPDATE routes SET distance={actual_dist_gcj/1000:.2f}, "
        f"start_lat={slat:.7f}, start_lng={slng:.7f}, "
        f"center_lat={clat:.7f}, center_lng={clng:.7f}, "
        f"city='{city}', difficulty={diff}, tags='{tags}' "
        f"WHERE id='{rid}';"
    )

# Build SQL
lines = [
    "-- StrideMoor: NOMINATIM verified route GPS inject",
    f"-- Generated {time.strftime('%Y-%m-%d %H:%M:%S')}",
    "", "BEGIN;",
]
seen = set()
for (rid, _, _, _, _, _, _) in ROUTES:
    if rid not in seen:
        lines.append(f"DELETE FROM route_points WHERE route_id='{rid}';")
        seen.add(rid)
lines.append("")

if point_sqls:
    for i in range(0, len(point_sqls), 500):
        batch = point_sqls[i:i+500]
        lines.append("INSERT INTO route_points (route_id,point_index,latitude,longitude,altitude) VALUES")
        lines.append(",\n".join(batch) + ";")
        lines.append("")

for s in update_sqls:
    lines.append(s)
lines.append("COMMIT;")

out = "\n".join(lines)
fp = r"D:\AI\StrideMoor\nominatim_routes.sql"
with open(fp, "w", encoding="utf-8") as f:
    f.write(out)

print(f"\n{'='*50}")
print(f"Done! {len(point_sqls)} pts, {len(update_sqls)} routes")
print(f"SQL: {fp}")
