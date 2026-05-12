#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Retry failed parks with kumi mirror + simpler queries"""
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

# Use kumi mirror which might have different limits
url = 'https://overpass.kumi.systems/api/interpreter'

queries = [
    ('洪湖公园', '[out:json][timeout:10];(way["leisure"="park"]["name"="洪湖公园"];);out geom;'),
    ('香蜜公园', '[out:json][timeout:10];(way["leisure"="park"]["name"="香蜜公园"];);out geom;'),
    ('深圳湾公园', '[out:json][timeout:10];(way["leisure"="park"]["name"="深圳湾公园"];relation["leisure"="park"]["name"="深圳湾公园"];);out geom;'),
    ('塘朗山', '[out:json][timeout:10];(way["leisure"="nature_reserve"]["name"~"塘朗山"];way["boundary"="protected_area"]["name"~"塘朗山"];);out geom;'),
    ('银湖山', '[out:json][timeout:10];(way["leisure"="park"]["name"="银湖山郊野公园"];way["leisure"="nature_reserve"]["name"~"银湖山"];);out geom;'),
    ('大沙河', '[out:json][timeout:10];(way["waterway"="river"]["name"="大沙河"];);out geom;'),
    ('福田河', '[out:json][timeout:10];(way["waterway"="river"]["name"="福田河"];);out geom;'),
    ('梧桐山', '[out:json][timeout:10];(way["leisure"="nature_reserve"]["name"~"梧桐山"];way["boundary"="national_park"]["name"~"梧桐山"];);out geom;'),
]

results = {}
for qname, q in queries:
    time.sleep(3.0)
    try:
        r = requests.post(url, data={'data': q}, headers=h, timeout=15)
        data = r.json()
        elems = data.get('elements', [])
        if not elems:
            print(f'.. {qname}: no results')
            continue
        best = max(elems, key=lambda e: len(e.get('geometry', [])))
        if best and best.get('geometry'):
            gcj = [(wgs84_to_gcj02(n['lat'], n['lon'])) for n in best['geometry']]
            d = sum(math.sqrt((gcj[i][0]-gcj[i-1][0])**2+(gcj[i][1]-gcj[i-1][1])**2)*111000 for i in range(1, len(gcj)))
            fn = best.get('tags', {}).get('name', '?')
            print(f'OK {qname} -> {fn}: {len(gcj)}pts {d/1000:.2f}km')
            results[qname] = gcj
        else:
            print(f'.. {qname}: no geom')
    except Exception as e:
        print(f'XX {qname}: {str(e)[:50]}')

print(f'\nGot {len(results)} more parks')
for k, pts in results.items():
    d = sum(math.sqrt((pts[i][0]-pts[i-1][0])**2+(pts[i][1]-pts[i-1][1])**2)*111000 for i in range(1, len(pts)))
    print(f'  {k}: {len(pts)}pts {d/1000:.2f}km')
