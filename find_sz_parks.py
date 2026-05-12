#!/usr/bin/env python3
# -*- coding: utf-8 -*-
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

queries = [
    ('南山公园 wide', ['way["leisure"="park"]["name"="南山公园"](22.45,113.90,22.55,113.96)']),
    ('南山公园 no bound', ['way["leisure"="park"]["name"="南山公园"]']),
    ('大南山', ['way["leisure"="park"]["name"~"大南山"]']),
    ('中心公园 sz bound', ['way["leisure"="park"]["name"="中心公园"](22.50,114.04,22.56,114.10)']),
    ('深圳中心公园', ['way["leisure"="park"]["name"="深圳中心公园"]']),
    ('中心公园 no bound', ['way["leisure"="park"]["name"="中心公园"]']),
]

for name, filters in queries:
    time.sleep(1.0)
    q = f'[out:json][timeout:10];({"".join(f + ";" for f in filters)});out geom;'
    try:
        r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q}, headers=h, timeout=10)
        data = r.json()
        elems = data.get('elements', [])
        if not elems:
            print(f'.. {name}: 0 elements')
            continue
        best = max(elems, key=lambda e: len(e.get('geometry', [])))
        geom = best.get('geometry', [])
        fn = best.get('tags', {}).get('name', '?')
        if geom:
            gcj = [wgs84_to_gcj02(n['lat'], n['lon']) for n in geom]
            d = sum(math.sqrt((gcj[i][0]-gcj[i-1][0])**2+(gcj[i][1]-gcj[i-1][1])**2)*111000 for i in range(1, len(gcj)))
            print(f'OK {name}: tag="{fn}" {len(geom)}pts {d/1000:.2f}km GCJ=({gcj[0][0]:.4f},{gcj[0][1]:.4f})')
    except Exception as e:
        print(f'XX {name}: {str(e)[:50]}')
