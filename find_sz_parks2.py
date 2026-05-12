#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Try alternate names for Shenzhen parks"""
import sys, io, requests, json, math, time
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
h = {'User-Agent': 'StrideMoor/1.0'}

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

# Search around Shenzhen for parks by type not name
queries = [
    ('南山 all parks sz', 'way["leisure"="park"](22.48,113.91,22.53,113.95);'),
    ('中心 all parks sz', 'way["leisure"="park"](22.52,114.05,22.56,114.10);'),
    ('大南山 trail', 'way["highway"="footway"](22.48,113.91,22.53,113.95);'),
    ('东湖 all parks sz', 'way["leisure"="park"](22.56,114.13,22.58,114.16);'),
]

for name, raw_q in queries:
    time.sleep(1.0)
    q = f'[out:json][timeout:10];({raw_q});out geom;'
    try:
        r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q}, headers=h, timeout=10)
        data = r.json()
        elems = data.get('elements', [])
        # Show names
        names = set()
        for e in elems:
            n = e.get('tags', {}).get('name', '')
            if n:
                names.add(n)
        if names:
            print(f'{name}: {len(elems)} ways, names: {list(sorted(names))}')
        else:
            print(f'{name}: {len(elems)} ways, unnamed')
    except Exception as e:
        print(f'XX {name}: {str(e)[:50]}')
