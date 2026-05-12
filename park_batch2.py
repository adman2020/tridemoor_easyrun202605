#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Batch 2: remaining parks"""
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

h = {'User-Agent': 'StrideMoor/1.0', 'Accept': 'application/json'}

parks = [
    '东湖公园',
    '洪湖公园',
    '香蜜公园',
    '塘朗山公园',
    '梅林公园',
    '银湖山郊野公园',
    '南山公园',
    '梧桐山',
    '深圳人才公园',
    '深圳中心公园',
    '笔架山公园',
    '莲花山公园',
    '欢乐港湾',
    '西湾红树林公园',
]

for name in parks:
    time.sleep(1.0)
    q = f'[out:json][timeout:10];(way["leisure"="park"][~"name"~"^{name}$|{name[:2]}"];relation["leisure"="park"][~"name"~"^{name}$|{name[:2]}"];);out geom;'
    try:
        r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q}, headers=h, timeout=10)
        data = r.json()
        elems = data.get('elements', [])
        best = max(elems, key=lambda e: len(e.get('geometry', [])), default=None) if elems else None
        
        if best and best.get('geometry'):
            gcj = [(wgs84_to_gcj02(n['lat'], n['lon'])) for n in best['geometry']]
            d = sum(math.sqrt((gcj[i][0]-gcj[i-1][0])**2+(gcj[i][1]-gcj[i-1][1])**2)*111000 for i in range(1, len(gcj)))
            found_name = best.get('tags', {}).get('name', '?')
            print(f'OK {name} -> "{found_name}": {len(gcj)}pts {d/1000:.2f}km')
        else:
            print(f'.. {name}: no boundary ({len(elems)} elems)')
    except Exception as e:
        print(f'XX {name}: {str(e)[:60]}')
