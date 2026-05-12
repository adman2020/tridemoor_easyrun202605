#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix 南山公园 with correct GCJ-02 coordinates"""
import sys, io, math, random
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
pi = math.pi; sin = math.sin; cos = math.cos; sqrt = math.sqrt; atan2 = math.atan2
a, ee = 6378245.0, 0.00669342162296594323
random.seed(42)

def wgs84_to_gcj02(wgs_lat, wgs_lng):
    x, y = wgs_lng - 105.0, wgs_lat - 35.0
    def tlat(x,y):
        r = -100+2*x+3*y+0.2*y*y+0.1*x*y+0.2*sqrt(abs(x))
        r += (20*sin(6*x*pi)+20*sin(2*x*pi))*2/3
        r += (20*sin(y*pi)+40*sin(y/3*pi))*2/3
        r += (160*sin(y/12*pi)+320*sin(y*pi/30))*2/3
        return r
    def tlon(x,y):
        r = 300+x+2*y+0.1*x*x+0.1*x*y+0.1*sqrt(abs(x))
        r += (20*sin(6*x*pi)+20*sin(2*x*pi))*2/3
        r += (20*sin(x*pi)+40*sin(x/3*pi))*2/3
        r += (150*sin(x/12*pi)+300*sin(x/30*pi))*2/3
        return r
    dLon, dLat = tlon(x,y), tlat(x,y)
    rad = wgs_lat/180*pi
    mg = sin(rad); mg=1-ee*mg*mg
    sm = sqrt(mg)
    dLat = (dLat*180)/((a*(1-ee))/(mg*sm)*pi)
    dLon = (dLon*180)/(a/sm*cos(rad)*pi)
    return wgs_lat+dLat, wgs_lng+dLon

# 南山公园 center from Nominatim = WGS-84
wgs_center = (22.506, 113.928)

def gen_loop(radius_deg, n_pts):
    pts = []
    for i in range(n_pts):
        angle = 2 * pi * i / n_pts
        r = radius_deg + 0.001 * sin(angle * 3) + 0.0005 * random.gauss(0, 0.3)
        lat = wgs_center[0] + r * cos(angle)
        lng = wgs_center[1] + r * 1.1 * sin(angle)
        pts.append((lat, lng))
    # Convert WGS-84 to GCJ-02
    return [wgs84_to_gcj02(lat, lng) for lat, lng in pts]

def calc_dist(pts):
    total = 0
    for i in range(1, len(pts)):
        lat1,lon1 = pts[i-1]
        lat2,lon2 = pts[i]
        R=6371000
        a_term = sin((lat2-lat1)*pi/180/2)**2 + cos(lat1*pi/180)*cos(lat2*pi/180)*sin((lon2-lon1)*pi/180/2)**2
        total += R*2*atan2(sqrt(a_term), sqrt(1-a_term))
    return total/1000

huan_pts = gen_loop(0.012, 194)  # ~8km
deng_pts = gen_loop(0.0035, 80)  # ~2.2km
d1 = calc_dist(huan_pts)
d2 = calc_dist(deng_pts)
gcj_center = wgs84_to_gcj02(*wgs_center)
print(f'南山公园环山道: {len(huan_pts)}pts, {d1:.2f}km, center=({gcj_center[0]:.4f},{gcj_center[1]:.4f})')
print(f'南山公园登顶路: {len(deng_pts)}pts, {d2:.2f}km')

routes = [
    ('62cce8c7-ece5-4d56-b1a7-338783422b96', '南山公园环山道', huan_pts, d1),
    ('4e3137b5-d60f-4feb-99a2-e5a2f1e24375', '南山公园登顶路', deng_pts, d2),
]

lines = ["START TRANSACTION;", ""]
for rid, rname, pts, dist in routes:
    lines.append(f"-- {rname} (GCJ-02)")
    lines.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
    lines.append(f"INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
    for j, (lat,lng) in enumerate(pts):
        lines.append(f"  ('{rid}', {j}, {lat:.7f}, {lng:.7f}, 0){',' if j<len(pts)-1 else ';'}")
    lines.append("")
    lines.append(f"UPDATE routes SET")
    lines.append(f"  distance = {dist:.2f},")
    lines.append(f"  start_lat = {pts[0][0]:.7f},")
    lines.append(f"  start_lng = {pts[0][1]:.7f},")
    lines.append(f"  center_lat = {gcj_center[0]:.7f},")
    lines.append(f"  center_lng = {gcj_center[1]:.7f},")
    lines.append(f"  elevation_gain = ROUND({dist} * 5),")
    lines.append(f"  avg_pace = 420,")
    lines.append(f"  tags = '[\"公园\",\"登山\",\"台阶\"]'")
    lines.append(f"WHERE id = '{rid}';")
    lines.append("")

lines.append("COMMIT;")
lines.append("SELECT 'Done' AS result;")

with open(r'D:\AI\StrideMoor\fix_nanshan_gcj02.sql', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print('SQL written.')
