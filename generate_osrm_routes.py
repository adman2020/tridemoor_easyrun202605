#!/usr/bin/env python3
"""
OSRM 路网路线生成脚本
从已知坐标点生成沿真实道路的跑步路线，WGS-84 → GCJ-02 转换后输出 SQL
"""
import json, time, requests, math

# ============ WGS-84 ↔ GCJ-02 转换 ============
def transform_coords(wgs_lat, wgs_lng):
    """WGS-84 转 GCJ-02"""
    a = 6378245.0
    ee = 0.00669342162296594323
    x = wgs_lng - 105.0
    y = wgs_lat - 35.0
    dLon = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(abs(x))
    dLon += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    dLon += (20.0 * math.sin(x * math.pi) + 40.0 * math.sin(x / 3.0 * math.pi)) * 2.0 / 3.0
    dLon += (150.0 * math.sin(x / 12.0 * math.pi) + 300.0 * math.sin(x / 30.0 * math.pi)) * 2.0 / 3.0
    dLat = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * math.sqrt(abs(x))
    dLat += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    dLat += (20.0 * math.sin(y * math.pi) + 40.0 * math.sin(y / 3.0 * math.pi)) * 2.0 / 3.0
    dLon += (160.0 * math.sin(y / 12.0 * math.pi) + 320.0 * math.sin(y * math.pi / 30.0)) * 2.0 / 3.0
    rad_lat = wgs_lat / 180.0 * math.pi
    magic = math.sin(rad_lat)
    magic = 1 - ee * magic * magic
    sqrt_magic = math.sqrt(magic)
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrt_magic) * math.pi)
    dLon = (dLon * 180.0) / (a / sqrt_magic * math.cos(rad_lat) * math.pi)
    gcj_lat = wgs_lat + dLat
    gcj_lng = wgs_lng + dLon
    return gcj_lat, gcj_lng

def gcj02_to_wgs84(gcj_lat, gcj_lng):
    """GCJ-02 转回 WGS-84（递推法）"""
    wgs_lat, wgs_lng = gcj_lat, gcj_lng
    for _ in range(5):
        glat, glng = transform_coords(wgs_lat, wgs_lng)
        wgs_lat += gcj_lat - glat
        wgs_lng += gcj_lng - glng
    return wgs_lat, wgs_lng

def haversine(lat1, lng1, lat2, lng2):
    """计算两点间距离(米)"""
    R = 6371000
    dlat = (lat2 - lat1) * math.pi / 180
    dlng = (lng2 - lng1) * math.pi / 180
    a = math.sin(dlat/2)*math.sin(dlat/2) + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dlng/2)*math.sin(dlng/2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

# ============ 路线定义（GCJ-02 坐标，即高德坐标）============
# 这些是用高德地图查到的深圳各跑点关键坐标
ROUTES = [
    {
        "name": "梅林水库绿道",
        "city": "深圳",
        "difficulty": 1,
        "waypoints_gcj": [
            (22.5693, 114.0225),  # 梅林水库大坝
            (22.5695, 114.0240),
            (22.5700, 114.0255),
            (22.5720, 114.0270),  # 沿水库
            (22.5740, 114.0275),
            (22.5760, 114.0270),
            (22.5780, 114.0265),
            (22.5800, 114.0255),  # 水库尾端折返
            (22.5780, 114.0265),
            (22.5760, 114.0270),
            (22.5740, 114.0275),
            (22.5720, 114.0270),
            (22.5700, 114.0255),
            (22.5695, 114.0240),
            (22.5693, 114.0225),  # 回大坝
            (22.5690, 114.0210),
            (22.5685, 114.0195),
            (22.5680, 114.0180),
            (22.5675, 114.0165),
            (22.5670, 114.0155),  # 绿道延伸段
        ]
    },
]

# ============ 执行生成 ============
all_sql_parts = []

for route in ROUTES:
    name = route["name"]
    waypoints_gcj = route["waypoints_gcj"]
    
    # GCJ-02 → WGS-84 才能喂 OSRM
    waypoints_wgs = [gcj02_to_wgs84(lat, lng) for lat, lng in waypoints_gcj]
    coords_str = ";".join([f"{lng},{lat}" for lat, lng in waypoints_wgs])
    
    url = f"https://router.project-osrm.org/route/v1/foot/{coords_str}"
    params = {"overview": "full", "geometries": "geojson", "steps": "false", "continue_straight": "false"}
    
    print(f"\n=== {name} ===")
    print(f"  OSRM 请求中...")
    
    try:
        resp = requests.get(url, params=params, timeout=20)
        data = resp.json()
        
        if data["code"] != "Ok":
            print(f"  失败: {data.get('message', data['code'])}")
            continue
        
        route_data = data["routes"][0]
        wgs_coords = route_data["geometry"]["coordinates"]  # [lng, lat] 格式
        dist_m = route_data["distance"]
        
        print(f"  原始: {dist_m/1000:.2f}km, {len(wgs_coords)} points")
        
        # 简化点（每4个取1个，保留关键点）
        simplified = []
        for i, pt in enumerate(wgs_coords):
            if i % 4 == 0 or i == len(wgs_coords) - 1:
                simplified.append(pt)
        print(f"  简化: {len(simplified)} points")
        
        # WGS-84 → GCJ-02 并转换为SQL
        gcj_points = []
        for lng, lat in simplified:
            glat, glng = transform_coords(lat, lng)
            gcj_points.append((glat, glng))
        
        # 计算起点终点和中心
        start_lat, start_lng = gcj_points[0]
        end_lat, end_lng = gcj_points[-1]
        center_lat = sum(p[0] for p in gcj_points) / len(gcj_points)
        center_lng = sum(p[1] for p in gcj_points) / len(gcj_points)
        
        # 准备 SQL
        full_name = route.get("full_name", name)
        tags_str = json.dumps(route.get("tags", ["跑步", "绿道", "深圳"]), ensure_ascii=False)
        
        sql_parts = []
        sql_parts.append(f"-- {name}: {dist_m/1000:.2f}km, {len(simplified)} GPS points")
        
        # route_points INSERT
        point_values = []
        for i, (glat, glng) in enumerate(gcj_points):
            point_values.append(
                f"(UUID(), '{name}', {i}, {glat:.7f}, {glng:.7f})"
            )
        
        if point_values:
            sql_parts.append(
                f"INSERT INTO route_points (id, route_name, seq, lat, lng) VALUES\n"
                + ",\n".join(point_values) + ";"
            )
        
        print(f"  SQL 已生成: {len(gcj_points)} 点")
        all_sql_parts.extend(sql_parts)
        
    except Exception as e:
        print(f"  错误: {e}")
    
    # 控制 OSRM 请求频率
    time.sleep(1)

# 输出
output = "\n\n".join(all_sql_parts)
filepath = r"D:\AI\StrideMoor\osrm_routes_test.sql"
with open(filepath, "w", encoding="utf-8") as f:
    f.write(output)
print(f"\n\nSQL 已写入: {filepath}")
print(f"总大小: {len(output)} 字符")
