#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Re-inject 洪湖公园 with raw WGS-84 (no GCJ conversion), inject new GPX files"""
import sys, io, re, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def parse_gpx(fp):
    with open(fp, 'r', encoding='utf-8') as f:
        raw = f.read()
    names = re.findall(r'<name>(.*?)</name>', raw)
    pts = re.findall(r'lat="([\d.-]+)" lon="([\d.-]+)"', raw)
    pts_float = [(float(lat), float(lon)) for lat, lon in pts]
    
    total = 0
    for i in range(1, len(pts_float)):
        lat1, lon1 = pts_float[i-1]
        lat2, lon2 = pts_float[i]
        R = 6371000
        dlat = (lat2-lat1)*math.pi/180
        dlon = (lon2-lon1)*math.pi/180
        a = math.sin(dlat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dlon/2)**2
        total += R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    center_lat = sum(p[0] for p in pts_float) / len(pts_float)
    center_lng = sum(p[1] for p in pts_float) / len(pts_float)
    
    return {
        'names': names,
        'pts': pts_float,
        'dist_km': total/1000,
        'center': (center_lat, center_lng),
    }

# Process all GPX files
gpx_files = [
    {
        'path': r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\1ef6ad46-d84f-4525-9210-16069f00367a.gpx',
        'route_id': '68b1bd0b-5e85-4a02-a8b2-957453c5e46f',
        'route_name': '洪湖公园晨跑',
        'tags': '["洪湖公园","湖边","平路"]'
    },
    {
        'path': r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\f1cdfce5-0955-48b7-96e2-2b60d7893b9a.gpx',
        'route_id': '22ce365a-5659-4192-884a-cd6e5b4f24c9',
        'route_name': '福田CBD夜跑',
        'tags': '["福田","CBD","城市"]'
    },
]

all_sql = []
for g in gpx_files:
    rid = g['route_id']
    info = parse_gpx(g['path'])
    pts = info['pts']
    print(f'{g["route_name"]}: {len(pts)}pts, {info["dist_km"]:.2f}km (WGS-84 raw)')
    
    values = []
    for j, (lat, lng) in enumerate(pts):
        end = ',' if j < len(pts) - 1 else ';'
        values.append(f"  ('{rid}', {j}, {lat:.7f}, {lng:.7f}, 0){end}")
    
    all_sql.append(f"-- {g['route_name']} (WGS-84 raw)")
    all_sql.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
    all_sql.append(f"INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
    all_sql.extend(values)
    all_sql.append("")
    all_sql.append(f"UPDATE routes SET")
    all_sql.append(f"  distance = {info['dist_km']:.2f},")
    all_sql.append(f"  start_lat = {pts[0][0]:.7f},")
    all_sql.append(f"  start_lng = {pts[0][1]:.7f},")
    all_sql.append(f"  center_lat = {info['center'][0]:.7f},")
    all_sql.append(f"  center_lng = {info['center'][1]:.7f},")
    all_sql.append(f"  elevation_gain = ROUND({info['dist_km']} * 5),")
    all_sql.append(f"  avg_pace = 420,")
    all_sql.append(f"  tags = '{g['tags']}'")
    all_sql.append(f"WHERE id = '{rid}';")
    all_sql.append("")

sql = "START TRANSACTION;\n\n" + '\n'.join(all_sql) + "\nCOMMIT;\nSELECT 'Done' AS result;"
with open(r'D:\AI\StrideMoor\reimport_wgs84.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print(f'SQL written ({len(all_sql)} lines)')
