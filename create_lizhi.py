#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Create new route: 荔枝公园环线 from Nanhu GPX - fixed schema"""
import sys, io, re, math, uuid
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

gpx_path = r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\68637744-0133-4fdb-b695-139146008d9c.gpx'

with open(gpx_path, 'r', encoding='utf-8') as f:
    raw = f.read()

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

print(f'荔枝公园环线: {len(pts_float)}pts, {total/1000:.2f}km')

new_id = str(uuid.uuid4())
# Same creator_id as 福田CBD夜跑 etc.
creator_id = 'c023fb36-98cc-4f6d-afaa-ac0cdd8b6c5e'

# Build SQL
values = []
for j, (lat, lng) in enumerate(pts_float):
    end = ',' if j < len(pts_float) - 1 else ';'
    values.append(f"  ('{new_id}', {j}, {lat:.7f}, {lng:.7f}, 0){end}")

sql = f"""START TRANSACTION;

-- 荔枝公园环线 (from Nanhu GPX)
INSERT INTO routes (id, creator_id, name, city, distance, difficulty, tags, status, is_public, start_lat, start_lng, center_lat, center_lng, elevation_gain, avg_pace, created_at, updated_at)
VALUES ('{new_id}', '{creator_id}', '荔枝公园环线', '深圳', {total/1000:.2f}, 1, '[\"公园\",\"环线\",\"平路\"]', 1, 1, {pts_float[0][0]:.7f}, {pts_float[0][1]:.7f}, {center_lat:.7f}, {center_lng:.7f}, ROUND({total/1000} * 5), 420, NOW(), NOW());

INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES
""" + '\n'.join(values) + """

COMMIT;
SELECT 'Done' AS result;"""

with open(r'D:\AI\StrideMoor\create_lizhi.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print(f'SQL written')
