#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate fixed center park SQL with transaction wrapper"""
import sys, io, math, requests
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
pi = math.pi; sin = math.sin; cos = math.cos; sqrt = math.sqrt; atan2 = math.atan2
a, ee = 6378245.0, 0.00669342162296594323

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

h = {'User-Agent': 'StrideMoor/1.0'}
q = '[out:json][timeout:10];(way["leisure"="park"]["name"="深圳中心公园"](22.50,114.04,22.58,114.10););out geom;'
r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q}, headers=h, timeout=10)
data = r.json()
best = max(data['elements'], key=lambda e: len(e.get('geometry', [])))
wgs_pts = [(n['lat'], n['lon']) for n in best['geometry']]
gcj = [wgs84_to_gcj02(lat,lng) for lat,lng in wgs_pts]
total = 0
for i in range(1, len(gcj)):
    lat1,lon1 = gcj[i-1]
    lat2,lon2 = gcj[i]
    R=6371000
    a_term = sin((lat2-lat1)*pi/180/2)**2 + cos(lat1*pi/180)*cos(lat2*pi/180)*sin((lon2-lon1)*pi/180/2)**2
    total += R*2*atan2(sqrt(a_term), sqrt(1-a_term))
total /= 1000
clat = sum(p[0] for p in gcj)/len(gcj)
clng = sum(p[1] for p in gcj)/len(gcj)

lines = ["START TRANSACTION;", ""]
for rid, rname in [
    ('519ffc17-cf9b-434c-b496-b5b4f0e779bc', '深圳中心公园绿道'),
    ('c365a069-404f-44ea-b808-2f9e749b1e24', '中心公园花径')
]:
    lines.append(f"-- {rname}")
    lines.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
    lines.append(f"INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
    for j, (lat,lng) in enumerate(gcj):
        lines.append(f"  ('{rid}', {j}, {lat:.7f}, {lng:.7f}, 0){',' if j<len(gcj)-1 else ';'}")
    lines.append(f"UPDATE routes SET distance={total:.2f}, start_lat={gcj[0][0]:.7f}, start_lng={gcj[0][1]:.7f}, center_lat={clat:.7f}, center_lng={clng:.7f}, elevation_gain=ROUND({total}*5), avg_pace=420, tags='[\"公园\",\"环线\",\"平路\"]' WHERE id='{rid}';")
    lines.append("")

lines.append("COMMIT;")
lines.append("SELECT 'Done' AS result;")

with open(r'D:\AI\StrideMoor\fix_center.sql', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f'SQL written: center park, {total:.2f}km')
