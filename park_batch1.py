#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Check OSM park boundaries - batch 1"""
import sys, io, requests, json, math, time
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

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

h = {'User-Agent': 'StrideMoor/1.0'}
parks = [
    ('人才公园', 'way["leisure"="park"]["name"="人才公园"]'),
    ('笔架山公园', 'way["leisure"="park"]["name"="笔架山公园"]'),
    ('中心公园', 'way["leisure"="park"]["name"="中心公园"]'),
    ('东湖公园', 'way["leisure"="park"]["name"="东湖公园"]'),
    ('洪湖公园', 'way["leisure"="park"]["name"="洪湖公园"]'),
]

for name, f in parks:
    time.sleep(0.5)
    q = '[out:json][timeout:10];(' + f + ';);out geom;'
    try:
        r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q}, headers=h, timeout=10)
        data = r.json()
        best = None
        best_n = 0
        for e in data.get('elements', []):
            n = len(e.get('geometry', []))
            if n > best_n:
                best_n = n
                best = e
        if best:
            pts = [(wgs84_to_gcj02(n['lat'], n['lon'])) for n in best['geometry']]
            total = sum(math.sqrt((pts[i][0]-pts[i-1][0])**2+(pts[i][1]-pts[i-1][1])**2)*111000 for i in range(1, len(pts)))
            print(f'OK {name}: {len(pts)}pts, {total/1000:.2f}km')
        else:
            print(f'.. {name}: no boundary')
    except Exception as e:
        print(f'XX {name}: {str(e)[:50]}')
