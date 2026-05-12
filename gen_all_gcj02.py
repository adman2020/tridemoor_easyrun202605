#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Re-generate ALL routes with CORRECT GCJ-02 conversion"""
import sys, io, math, re, uuid, requests, time
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
pi = math.pi; sin = math.sin; cos = math.cos; sqrt = math.sqrt; atan2 = math.atan2
a, ee = 6378245.0, 0.00669342162296594323

# ===== CORRECT WGS-84 -> GCJ-02 conversion =====
def transform_lat(x, y):
    ret = -100.0 + 2.0*x + 3.0*y + 0.2*y*y + 0.1*x*y + 0.2*sqrt(abs(x))
    ret += (20.0*sin(6.0*x*pi) + 20.0*sin(2.0*x*pi))*2.0/3.0
    ret += (20.0*sin(y*pi) + 40.0*sin(y/3.0*pi))*2.0/3.0
    ret += (160.0*sin(y/12.0*pi) + 320.0*sin(y*pi/30.0))*2.0/3.0
    return ret

def transform_lon(x, y):
    ret = 300.0 + x + 2.0*y + 0.1*x*x + 0.1*x*y + 0.1*sqrt(abs(x))
    ret += (20.0*sin(6.0*x*pi) + 20.0*sin(2.0*x*pi))*2.0/3.0
    ret += (20.0*sin(x*pi) + 40.0*sin(x/3.0*pi))*2.0/3.0
    ret += (150.0*sin(x/12.0*pi) + 300.0*sin(x/30.0*pi))*2.0/3.0
    return ret

def wgs84_to_gcj02(wgs_lat, wgs_lng):
    x, y = wgs_lng - 105.0, wgs_lat - 35.0
    dLat = transform_lat(x, y)
    dLon = transform_lon(x, y)
    rad_lat = wgs_lat/180.0*pi
    magic = sin(rad_lat); magic = 1 - ee*magic*magic
    sqrt_magic = sqrt(magic)
    dLat = (dLat*180.0)/((a*(1-ee))/(magic*sqrt_magic)*pi)
    dLon = (dLon*180.0)/(a/sqrt_magic*cos(rad_lat)*pi)
    return wgs_lat+dLat, wgs_lng+dLon

def calc_distance(pts):
    total = 0
    for i in range(1, len(pts)):
        lat1, lon1 = pts[i-1]
        lat2, lon2 = pts[i]
        R = 6371000
        dlat = (lat2-lat1)*pi/180
        dlon = (lon2-lon1)*pi/180
        a_term = sin(dlat/2)**2 + cos(lat1*pi/180)*cos(lat2*pi/180)*sin(dlon/2)**2
        total += R * 2 * atan2(sqrt(a_term), sqrt(1-a_term))
    return total/1000

def gen_values(rid, pts):
    """Generate INSERT values for route_points"""
    values = []
    for j, (lat, lng) in enumerate(pts):
        end = ',' if j < len(pts) - 1 else ';'
        values.append(f"  ('{rid}', {j}, {lat:.7f}, {lng:.7f}, 0){end}")
    return values

all_sql = []

# ===== OSM Park Boundaries =====
h = {'User-Agent': 'StrideMoor/1.0'}
ROUTE_MAP = {
    '莲花山公园': {
        'ids': ['d5c45106-da86-450c-ac37-169086dbf41b', '5aa84db1-c4f7-4d71-8876-49a9ca444ba8'],
        'names': ['莲花山公园绕湖', '莲花山环湖跑'],
        'q': 'way["leisure"="park"]["name"="莲花山公园"](22.53,114.03,22.58,114.08)',
        'tags': '["公园","环线","平路"]'
    },
    '笔架山公园': {
        'ids': ['e3ba6405-0e30-4d1c-a801-b6e7f130f9a9', '6bd63195-4f54-4108-8cab-71db9589d679'],
        'names': ['笔架山公园环山', '笔架山环山径'],
        'q': 'way["leisure"="park"]["name"="笔架山公园"](22.55,114.06,22.58,114.09)',
        'tags': '["公园","环线","平路"]'
    },
    '东湖公园': {
        'ids': ['5c473ba3-e055-4d7d-aa26-a6515f2aaab9'],
        'names': ['东湖公园绿道'],
        'q': 'way["leisure"="park"]["name"="东湖公园"](22.54,114.11,22.60,114.18)',
        'tags': '["公园","环线","平路"]'
    },
    '中心公园': {
        'ids': ['519ffc17-cf9b-434c-b496-b5b4f0e779bc', 'c365a069-404f-44ea-b808-2f9e749b1e24'],
        'names': ['深圳中心公园绿道', '中心公园花径'],
        'q': 'way["leisure"="park"]["name"="深圳中心公园"](22.50,114.04,22.58,114.10)',
        'tags': '["公园","环线","平路"]'
    },
}

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
        
        # Convert WGS-84 -> GCJ-02 with CORRECT formula
        gcj_pts = [wgs84_to_gcj02(n['lat'], n['lon']) for n in best['geometry']]
        dist = calc_distance(gcj_pts)
        center_lat = sum(p[0] for p in gcj_pts)/len(gcj_pts)
        center_lng = sum(p[1] for p in gcj_pts)/len(gcj_pts)
        
        print(f'OK {pname}: {len(gcj_pts)}pts, {dist:.2f}km (GCJ-02 correct)')
        
        for i, rid in enumerate(info['ids']):
            rname = info['names'][i]
            vals = gen_values(rid, gcj_pts)
            all_sql.append(f"-- {rname} (GCJ-02)")
            all_sql.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
            all_sql.append(f"INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
            all_sql.extend(vals)
            all_sql.append(f"UPDATE routes SET")
            all_sql.append(f"  distance = {dist:.2f},")
            all_sql.append(f"  start_lat = {gcj_pts[0][0]:.7f},")
            all_sql.append(f"  start_lng = {gcj_pts[0][1]:.7f},")
            all_sql.append(f"  center_lat = {center_lat:.7f},")
            all_sql.append(f"  center_lng = {center_lng:.7f},")
            all_sql.append(f"  elevation_gain = ROUND({dist} * 5),")
            all_sql.append(f"  avg_pace = 420,")
            all_sql.append(f"  tags = '{info['tags']}'")
            all_sql.append(f"WHERE id = '{rid}';")
            all_sql.append("")
    except Exception as e:
        print(f'XX {pname}: {str(e)[:80]}')

# ===== Wikiloc GPX files =====
gpx_files = [
    {
        'path': r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\1ef6ad46-d84f-4525-9210-16069f00367a.gpx',
        'rid': '68b1bd0b-5e85-4a02-a8b2-957453c5e46f',
        'name': '洪湖公园晨跑',
        'tags': '["洪湖公园","湖边","平路"]'
    },
    {
        'path': r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\f1cdfce5-0955-48b7-96e2-2b60d7893b9a.gpx',
        'rid': '22ce365a-57b6-4a6b-b4ba-961c3ee8925c',
        'name': '福田CBD夜跑',
        'tags': '["福田","CBD","城市"]'
    },
    {
        'path': r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\68637744-0133-4fdb-b695-139146008d9c.gpx',
        'rid': 'ef056e1d-41a1-465e-afe4-ec48519b2a77',
        'name': '荔枝公园环线',
        'tags': '["公园","环线","平路"]'
    },
]

for g in gpx_files:
    with open(g['path'], 'r', encoding='utf-8') as f:
        raw = f.read()
    wgs_pts = re.findall(r'lat="([\d.-]+)" lon="([\d.-]+)"', raw)
    wgs_pts = [(float(lat), float(lon)) for lat, lon in wgs_pts]
    gcj_pts = [wgs84_to_gcj02(lat, lng) for lat, lng in wgs_pts]
    dist = calc_distance(gcj_pts)
    center_lat = sum(p[0] for p in gcj_pts)/len(gcj_pts)
    center_lng = sum(p[1] for p in gcj_pts)/len(gcj_pts)
    print(f'OK {g["name"]}: {len(gcj_pts)}pts, {dist:.2f}km (GCJ-02 correct)')
    
    vals = gen_values(g['rid'], gcj_pts)
    all_sql.append(f"-- {g['name']} (GCJ-02)")
    all_sql.append(f"DELETE FROM route_points WHERE route_id = '{g['rid']}';")
    all_sql.append(f"INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
    all_sql.extend(vals)
    all_sql.append(f"UPDATE routes SET")
    all_sql.append(f"  distance = {dist:.2f},")
    all_sql.append(f"  start_lat = {gcj_pts[0][0]:.7f},")
    all_sql.append(f"  start_lng = {gcj_pts[0][1]:.7f},")
    all_sql.append(f"  center_lat = {center_lat:.7f},")
    all_sql.append(f"  center_lng = {center_lng:.7f},")
    all_sql.append(f"  elevation_gain = ROUND({dist} * 5),")
    all_sql.append(f"  avg_pace = 420,")
    all_sql.append(f"  tags = '{g['tags']}'")
    all_sql.append(f"WHERE id = '{g['rid']}';")
    all_sql.append("")

sql = "START TRANSACTION;\n\n" + '\n'.join(all_sql) + "\nCOMMIT;\nSELECT 'Done' AS result;"
with open(r'D:\AI\StrideMoor\all_routes_gcj02.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print(f'\nSQL written: all 7 routes with CORRECT GCJ-02')
