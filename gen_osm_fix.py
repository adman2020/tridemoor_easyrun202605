#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate corrected SQL for 东湖公园 and 中心公园"""
import sys, io, requests, json, math, time
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
h = {'User-Agent': 'StrideMoor/1.0'}

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
    magic = math.sin(rad_lat); magic = 1 - 0.00669342162296594323*magic*magic
    sqrt_magic = math.sqrt(magic)
    dLat = (dLat*180.0)/((6378245.0*(1-0.00669342162296594323))/(magic*sqrt_magic)*math.pi)
    dLon = (dLon*180.0)/(6378245.0/sqrt_magic*math.cos(rad_lat)*math.pi)
    return wgs_lat+dLat, wgs_lng+dLon

ROUTE_MAP = {
    '东湖公园': {
        'ids': ['5c473ba3-e055-4d7d-aa26-a6515f2aaab9'],
        'names': ['东湖公园绿道'],
        'q': 'way["leisure"="park"]["name"="东湖公园"](22.54,114.11,22.60,114.18)'
    },
    '中心公园': {
        'ids': ['519ffc17-cf9b-434c-b496-b5b4f0e779bc', 'c365a069-404f-44ea-b808-2f9e749b1e24'],
        'names': ['深圳中心公园绿道', '中心公园花径'],
        'q': 'way["leisure"="park"]["name"="深圳中心公园"](22.50,114.04,22.58,114.10)'
    },
}

all_sql = []
total_pts = 0

for pname, info in ROUTE_MAP.items():
    time.sleep(2.0)
    q = f'[out:json][timeout:10];({info["q"]};);out geom;'
    r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q}, headers=h, timeout=10)
    data = r.json()
    best = max(data.get('elements', []), key=lambda e: len(e.get('geometry', [])), default=None)
    if not best or not best.get('geometry'):
        print(f'FAIL {pname}')
        continue
    
    gcj_pts = [wgs84_to_gcj02(n['lat'], n['lon']) for n in best['geometry']]
    total = sum(math.sqrt((gcj_pts[i][0]-gcj_pts[i-1][0])**2+(gcj_pts[i][1]-gcj_pts[i-1][1])**2)*111000 for i in range(1, len(gcj_pts)))
    center_lat = sum(p[0] for p in gcj_pts) / len(gcj_pts)
    center_lng = sum(p[1] for p in gcj_pts) / len(gcj_pts)
    
    print(f'OK {pname}: {len(gcj_pts)}pts, {total/1000:.2f}km')
    
    for i, rid in enumerate(info['ids']):
        rname = info['names'][i]
        values = [f"  ('{rid}', {j}, {lat:.7f}, {lng:.7f}, 0)" for j, (lat, lng) in enumerate(gcj_pts)]
        
        all_sql.append(f"-- {rname} ({pname})")
        all_sql.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
        all_sql.append(f"INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
        for j, v in enumerate(values):
            all_sql.append(f"{v}{',' if j < len(values)-1 else ';'}")
        all_sql.append(f"")
        all_sql.append(f"UPDATE routes SET")
        all_sql.append(f"  distance = {total/1000:.2f},")
        all_sql.append(f"  start_lat = {gcj_pts[0][0]:.7f},")
        all_sql.append(f"  start_lng = {gcj_pts[0][1]:.7f},")
        all_sql.append(f"  center_lat = {center_lat:.7f},")
        all_sql.append(f"  center_lng = {center_lng:.7f},")
        all_sql.append(f"  elevation_gain = ROUND({total/1000} * 5),")
        all_sql.append(f"  avg_pace = 420,")
        all_sql.append(f"  tags = '[\"公园\",\"环线\",\"平路\"]'")
        all_sql.append(f"WHERE id = '{rid}';")
        all_sql.append(f"")
        total_pts += len(gcj_pts)

sql = "START TRANSACTION;\n\n" + '\n'.join(all_sql) + "\nCOMMIT;\nSELECT 'Done' AS result;"
with open(r'D:\AI\StrideMoor\osm_park_fix.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print(f'SQL: {total_pts} pts')
