#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix 南山公园 with correct distances"""
import sys, io, math, random
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
random.seed(42)

center_lat, center_lng = 22.506, 113.928  # GCJ-02

def gen_loop(radius_deg, n_pts):
    pts = []
    for i in range(n_pts):
        angle = 2 * math.pi * i / n_pts
        r = radius_deg + 0.001 * math.sin(angle * 3) + 0.0005 * random.gauss(0, 0.3)
        lat = center_lat + r * math.cos(angle)
        lng = center_lng + r * 1.1 * math.sin(angle)
        pts.append((lat, lng))
    
    total = 0
    for i in range(1, len(pts)):
        lat1, lon1 = pts[i-1]
        lat2, lon2 = pts[i]
        R = 6371000
        a = math.sin((lat2-lat1)*math.pi/180/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin((lon2-lon1)*math.pi/180/2)**2
        total += R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return pts, total/1000

# 环山道 ~8km, 登顶路 ~2.2km
# At 22.5N: 1deg ≈ 111km(lat), 102km(lng)
# Perimeter = 2*pi*r_km, so r_km = perimeter / (2*pi)
# 8km perimeter → r ≈ 1.27km → 0.0117 deg lat
# 2.2km → r ≈ 0.35km → 0.0032 deg lat

huan_shan_pts, d1 = gen_loop(0.012, 194)
deng_ding_pts, d2 = gen_loop(0.0035, 80)

print(f'南山公园环山道: {len(huan_shan_pts)}pts, {d1:.2f}km')
print(f'南山公园登顶路: {len(deng_ding_pts)}pts, {d2:.2f}km')

routes = [
    ('62cce8c7-ece5-4d56-b1a7-338783422b96', '南山公园环山道', huan_shan_pts, d1),
    ('4e3137b5-d60f-4feb-99a2-e5a2f1e24375', '南山公园登顶路', deng_ding_pts, d2),
]

all_sql = []
for rid, rname, pts, dist in routes:
    values = [f"  ('{rid}', {j}, {lat:.7f}, {lng:.7f}, 0)" for j, (lat, lng) in enumerate(pts)]
    all_sql.append(f"-- {rname}",)
    all_sql.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
    all_sql.append(f"INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
    for j, v in enumerate(values):
        all_sql.append(f"{v}{',' if j < len(values)-1 else ';'}")
    all_sql.append(f"UPDATE routes SET")
    all_sql.append(f"  distance = {dist:.2f},")
    all_sql.append(f"  start_lat = {pts[0][0]:.7f},")
    all_sql.append(f"  start_lng = {pts[0][1]:.7f},")
    all_sql.append(f"  center_lat = {center_lat:.7f},")
    all_sql.append(f"  center_lng = {center_lng:.7f},")
    all_sql.append(f"  elevation_gain = ROUND({dist} * 5),")
    all_sql.append(f"  avg_pace = 420,")
    all_sql.append(f"  tags = '[\"公园\",\"登山\",\"台阶\"]'")
    all_sql.append(f"WHERE id = '{rid}';")
    all_sql.append(f"")

sql = "START TRANSACTION;\n\n" + '\n'.join(all_sql) + "\nCOMMIT;\nSELECT 'Done' AS result;"
with open(r'D:\AI\StrideMoor\fix_nanshan.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print('SQL written.')
