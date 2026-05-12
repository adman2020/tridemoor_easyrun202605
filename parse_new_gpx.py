#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io, re, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

fp = r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\1ef6ad46-d84f-4525-9210-16069f00367a.gpx'

with open(fp, 'r', encoding='utf-8') as f:
    raw = f.read()

print('Size:', len(raw), 'bytes')

# Find names
names = re.findall(r'<name>(.*?)</name>', raw)
print('Names:', names)

# Parse GPX coordinates
pts = re.findall(r'lat="([\d.-]+)" lon="([\d.-]+)"', raw)
print('Points:', len(pts))

if len(pts) > 1:
    total = 0
    for i in range(1, len(pts)):
        lat1, lon1 = float(pts[i-1][0]), float(pts[i-1][1])
        lat2, lon2 = float(pts[i][0]), float(pts[i][1])
        R = 6371000
        dlat = (lat2-lat1)*math.pi/180
        dlon = (lon2-lon1)*math.pi/180
        a = math.sin(dlat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dlon/2)**2
        total += R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    print('Distance:', round(total/1000, 3), 'km')
    print('First:', pts[0][0], pts[0][1])
    print('Last:', pts[-1][0], pts[-1][1])
