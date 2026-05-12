#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io, requests, json, math, random
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
random.seed(42)

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

def haversine(lat1, lng1, lat2, lng2):
    R = 6371000
    dlat = (lat2-lat1)*math.pi/180
    dlng = (lng2-lng1)*math.pi/180
    a = math.sin(dlat/2)**2 + math.cos(lat1*math.pi/180)*math.cos(lat2*math.pi/180)*math.sin(dlng/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def osm_to_gcj(elem):
    pts = []
    for node in elem.get('geometry', []):
        gcj = wgs84_to_gcj02(node['lat'], node['lon'])
        pts.append(gcj)
    return pts

def get_park_boundary(name, lat, lng, radius=0.025):
    q = f"""
    [out:json][timeout:15];
    (
      way["leisure"="park"]["name"~"{name}"]({lat-radius},{lng-radius},{lat+radius},{lng+radius});
      relation["leisure"="park"]["name"~"{name}"]({lat-radius},{lng-radius},{lat+radius},{lng+radius});
    );
    out geom;
    """
    h = {"User-Agent": "StrideMoor/1.0"}
    r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q}, headers=h, timeout=15)
    data = r.json()
    
    # Find the way/relation with most geometry points
    best = None
    best_pts = 0
    for e in data.get('elements', []):
        n = len(e.get('geometry', []))
        if n > best_pts:
            best_pts = n
            best = e
    
    if best:
        gcj_pts = osm_to_gcj(best)
        # Calculate distance
        total = 0
        for i in range(1, len(gcj_pts)):
            total += haversine(gcj_pts[i-1][0], gcj_pts[i-1][1], gcj_pts[i][0], gcj_pts[i][1])
        return gcj_pts, total/1000
    return [], 0

# Parks to query
PARKS = {
    "莲花山公园": (22.555, 114.055, 0.025),
    "深圳湾公园": (22.525, 113.988, 0.025),
    "人才公园": (22.518, 113.945, 0.018),
    "笔架山公园": (22.564, 114.075, 0.020),
    "中心公园": (22.540, 114.068, 0.020),
    "东湖公园": (22.565, 114.144, 0.020),
    "洪湖公园": (22.567, 114.117, 0.018),
    "香蜜湖": (22.548, 114.038, 0.020),
    "南山公园": (22.500, 113.925, 0.025),
    "塘朗山": (22.575, 113.975, 0.030),
    "梅林水库": (22.573, 114.024, 0.020),
    "银湖山": (22.570, 114.082, 0.025),
}

for pname, (plat, plng, pr) in PARKS.items():
    pts, dist_km = get_park_boundary(pname, plat, plng, pr)
    if pts:
        print(f"{pname}: {len(pts)} pts, {dist_km:.2f}km loop")
    else:
        print(f"{pname}: NOT FOUND")
