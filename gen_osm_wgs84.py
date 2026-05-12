#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Re-inject ALL OSM routes with raw WGS-84 coordinates (no GCJ conversion)"""
import sys, io, requests, json, math, time
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
h = {'User-Agent': 'StrideMoor/1.0'}

ROUTE_MAP = {
    '莲花山公园': {
        'ids': ['d5c45106-da86-450c-ac37-169086dbf41b', '5aa84db1-c4f7-4d71-8876-49a9ca444ba8'],
        'names': ['莲花山公园绕湖', '莲花山环湖跑'],
        'q': 'way["leisure"="park"]["name"="莲花山公园"](22.53,114.03,22.58,114.08)'
    },
    '笔架山公园': {
        'ids': ['e3ba6405-0e30-4d1c-a801-b6e7f130f9a9', '6bd63195-4f54-4108-8cab-71db9589d679'],
        'names': ['笔架山公园环山', '笔架山环山径'],
        'q': 'way["leisure"="park"]["name"="笔架山公园"](22.55,114.06,22.58,114.09)'
    },
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
    try:
        r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q}, headers=h, timeout=10)
        data = r.json()
        best = max(data.get('elements', []), key=lambda e: len(e.get('geometry', [])), default=None)
        if not best or not best.get('geometry'):
            print(f'FAIL {pname}')
            continue
        
        # RAW WGS-84 - NO conversion
        pts = [(n['lat'], n['lon']) for n in best['geometry']]
        
        total = 0
        for i in range(1, len(pts)):
            lat1, lon1 = pts[i-1]
            lat2, lon2 = pts[i]
            R = 6371000
            a = math.sin((lat2-lat1)*math.pi/180/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin((lon2-lon1)*math.pi/180/2)**2
            total += R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        
        center_lat = sum(p[0] for p in pts) / len(pts)
        center_lng = sum(p[1] for p in pts) / len(pts)
        
        print(f'OK {pname}: {len(pts)}pts, {total/1000:.2f}km (WGS-84 raw)')
        
        for i, rid in enumerate(info['ids']):
            rname = info['names'][i]
            values = []
            for j, (lat, lng) in enumerate(pts):
                end = ',' if j < len(pts) - 1 else ';'
                values.append(f"  ('{rid}', {j}, {lat:.7f}, {lng:.7f}, 0){end}")
            
            all_sql.append(f"-- {rname} (WGS-84 raw)")
            all_sql.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
            all_sql.append(f"INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
            all_sql.extend(values)
            all_sql.append(f"UPDATE routes SET")
            all_sql.append(f"  distance = {total/1000:.2f},")
            all_sql.append(f"  start_lat = {pts[0][0]:.7f},")
            all_sql.append(f"  start_lng = {pts[0][1]:.7f},")
            all_sql.append(f"  center_lat = {center_lat:.7f},")
            all_sql.append(f"  center_lng = {center_lng:.7f},")
            all_sql.append(f"  elevation_gain = ROUND({total/1000} * 5),")
            all_sql.append(f"  avg_pace = 420,")
            all_sql.append(f"  tags = '[\"公园\",\"环线\",\"平路\"]'")
            all_sql.append(f"WHERE id = '{rid}';")
            all_sql.append(f"")
            total_pts += len(pts)
            
    except Exception as e:
        print(f'XX {pname}: {str(e)[:60]}')

sql = "START TRANSACTION;\n\n" + '\n'.join(all_sql) + "\nCOMMIT;\nSELECT 'Done' AS result;"
with open(r'D:\AI\StrideMoor\osm_wgs84.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print(f'\nSQL written: {total_pts} pts')
