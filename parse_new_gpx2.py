#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io, re, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

files = [
    r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\68637744-0133-4fdb-b695-139146008d9c.gpx',
    r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\f1cdfce5-0955-48b7-96e2-2b60d7893b9a.gpx',
]

for fp in files:
    with open(fp, 'r', encoding='utf-8') as f:
        raw = f.read()
    
    names = re.findall(r'<name>(.*?)</name>', raw)
    pts = re.findall(r'lat="([\d.-]+)" lon="([\d.-]+)"', raw)
    
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
        
        print(f'=== {names} ===')
        print(f'  Points: {len(pts)}')
        print(f'  WGS-84 distance: {total/1000:.2f}km')
        print(f'  First: {pts[0]}')
        print(f'  Last: {pts[-1]}')
    print()
