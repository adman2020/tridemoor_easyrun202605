#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io, re, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

fp = r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\1ef6ad46-d84f-4525-9210-16069f00367a.gpx'

with open(fp, 'r', encoding='utf-8') as f:
    raw = f.read()

# Parse WGS-84 points
wgs_pts = re.findall(r'lat="([\d.-]+)" lon="([\d.-]+)"', raw)
print(f'WGS-84 points: {len(wgs_pts)}')
print(f'  First: {wgs_pts[0]}')
print(f'  Last: {wgs_pts[-1]}')

# WGS-84 to GCJ-02
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

gcj_pts = []
for lat_str, lon_str in wgs_pts:
    gcj = wgs84_to_gcj02(float(lat_str), float(lon_str))
    gcj_pts.append(gcj)

# Calculate GCJ distance
total = 0
for i in range(1, len(gcj_pts)):
    lat1, lon1 = gcj_pts[i-1]
    lat2, lon2 = gcj_pts[i]
    R = 6371000
    dlat = (lat2-lat1)*math.pi/180
    dlon = (lon2-lon1)*math.pi/180
    a = math.sin(dlat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dlon/2)**2
    total += R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

print(f'\nGCJ-02 distance: {total/1000:.2f} km')
print(f'  First GCJ: ({gcj_pts[0][0]:.6f}, {gcj_pts[0][1]:.6f})')
print(f'  Last GCJ: ({gcj_pts[-1][0]:.6f}, {gcj_pts[-1][1]:.6f})')

# Center
clat = sum(p[0] for p in gcj_pts) / len(gcj_pts)
clng = sum(p[1] for p in gcj_pts) / len(gcj_pts)
print(f'  Center: ({clat:.6f}, {clng:.6f})')

# Generate INSERT SQL (first 10 as sample)
print(f'\nSQL sample (first 5 points):')
route_id = '68b1bd0b-5e85-4a02-a8b2-957453c5e46f'
for i in range(min(5, len(gcj_pts))):
    print(f"  ({route_id}, {i}, {gcj_pts[i][0]:.7f}, {gcj_pts[i][1]:.7f}, 0),")
print(f'  ... total {len(gcj_pts)} points')
