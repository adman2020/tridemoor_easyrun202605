#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io, re, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

fp = r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\1ef6ad46-d84f-4525-9210-16069f00367a.gpx'

with open(fp, 'r', encoding='utf-8') as f:
    raw = f.read()

wgs_pts = re.findall(r'lat="([\d.-]+)" lon="([\d.-]+)"', raw)

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

gcj_pts = [wgs84_to_gcj02(float(lat), float(lon)) for lat, lon in wgs_pts]

total = 0
for i in range(1, len(gcj_pts)):
    lat1, lon1 = gcj_pts[i-1]
    lat2, lon2 = gcj_pts[i]
    R = 6371000
    dlat = (lat2-lat1)*math.pi/180
    dlon = (lon2-lon1)*math.pi/180
    a = math.sin(dlat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dlon/2)**2
    total += R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

center_lat = sum(p[0] for p in gcj_pts) / len(gcj_pts)
center_lng = sum(p[1] for p in gcj_pts) / len(gcj_pts)

route_id = '68b1bd0b-5e85-4a02-a8b2-957453c5e46f'

# Create a single large INSERT
values = []
for i, (lat, lng) in enumerate(gcj_pts):
    comma = ',' if i < len(gcj_pts) - 1 else ';'
    values.append(f"  ('{route_id}', {i}, {lat:.7f}, {lng:.7f}, 0){comma}")

sql = f"""-- Inject real 洪湖公园跑步 GPX from Wikiloc
-- {len(gcj_pts)} points, {total/1000:.2f}km

DELETE FROM route_points WHERE route_id = '{route_id}';

INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES
""" + '\n'.join(values) + f"""

UPDATE routes SET
  distance = {total/1000:.2f},
  start_lat = {gcj_pts[0][0]:.7f},
  start_lng = {gcj_pts[0][1]:.7f},
  center_lat = {center_lat:.7f},
  center_lng = {center_lng:.7f},
  elevation_gain = ROUND({total/1000} * 5),
  avg_pace = 420,
  tags = '洪湖公园,湖边,平路'
WHERE id = '{route_id}';

SELECT ROW_COUNT() AS updated;
"""

with open(r'D:\AI\StrideMoor\wikiloc_honghu.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print(f"SQL written: {len(gcj_pts)} points, {total/1000:.2f}km")
