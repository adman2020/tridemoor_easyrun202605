#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io, requests, json, math, random, time
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

def query_osm(query, timeout=15):
    h = {"User-Agent": "StrideMoor/1.0"}
    try:
        r = requests.post('https://overpass-api.de/api/interpreter', data={'data': query}, headers=h, timeout=timeout)
        if r.text.startswith('{'):
            return r.json()
        print(f"  Bad response: {r.text[:100]}")
    except Exception as e:
        print(f"  Error: {e}")
    return None

# Park queries - multiple name attempts
PARK_QUERIES = [
    # (name, query_label, query_string)
    ("莲花山公园", "莲花山公园", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"=\"莲花山公园\"];relation[\"leisure\"=\"park\"][\"name\"=\"莲花山公园\"];);out geom;"),
    ("深圳湾公园", "深圳湾公园", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"=\"深圳湾公园\"];relation[\"leisure\"=\"park\"][\"name\"=\"深圳湾公园\"];);out geom;"),
    ("深圳湾公园", "Shenzhen Bay Park", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name:en\"=\"Shenzhen Bay Park\"];relation[\"leisure\"=\"park\"][\"name:en\"=\"Shenzhen Bay Park\"];);out geom;"),
    ("人才公园", "人才公园", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"=\"人才公园\"];relation[\"leisure\"=\"park\"][\"name\"=\"人才公园\"];);out geom;"),
    ("笔架山公园", "笔架山公园", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"=\"笔架山公园\"];relation[\"leisure\"=\"park\"][\"name\"=\"笔架山公园\"];);out geom;"),
    ("中心公园", "中心公园", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"=\"中心公园\"];relation[\"leisure\"=\"park\"][\"name\"=\"中心公园\"];);out geom;"),
    ("东湖公园", "东湖公园", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"=\"东湖公园\"];relation[\"leisure\"=\"park\"][\"name\"=\"东湖公园\"];);out geom;"),
    ("洪湖公园", "洪湖公园", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"=\"洪湖公园\"];relation[\"leisure\"=\"park\"][\"name\"=\"洪湖公园\"];);out geom;"),
    ("香蜜公园", "香蜜公园", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"=\"香蜜公园\"];relation[\"leisure\"=\"park\"][\"name\"=\"香蜜公园\"];);out geom;"),
    ("塘朗山公园", "塘朗山", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"=\"塘朗山公园\"];relation[\"leisure\"=\"park\"][\"name\"=\"塘朗山公园\"];way[\"leisure\"=\"park\"][\"name\"~\"塘朗山\"];);out geom;"),
    ("梅林水库", "梅林水库", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"~\"梅林\"];relation[\"leisure\"=\"park\"][\"name\"~\"梅林\"];);out geom;"),
    ("银湖山公园", "银湖山", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"~\"银湖\"];relation[\"leisure\"=\"park\"][\"name\"~\"银湖\"];);out geom;"),
    ("南山公园", "南山公园", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"~\"南山\"];relation[\"leisure\"=\"park\"][\"name\"~\"南山\"];);out geom;"),
    ("欢乐港湾", "欢乐港湾", f"[out:json][timeout:15];(way[\"leisure\"=\"park\"][\"name\"~\"欢乐港湾\"];relation[\"leisure\"=\"park\"][\"name\"~\"欢乐港湾\"];);out geom;"),
]

print("Querying OSM park boundaries...")
results = {}
for pname, qlabel, q in PARK_QUERIES:
    time.sleep(0.5)  # rate limit
    data = query_osm(q)
    if data:
        best = None
        best_n = 0
        for e in data.get('elements', []):
            n = len(e.get('geometry', []))
            if n > best_n:
                best_n = n
                best = e
        
        if best:
            gcj_pts = osm_to_gcj(best)
            total = 0
            for i in range(1, len(gcj_pts)):
                total += haversine(gcj_pts[i-1][0], gcj_pts[i-1][1], gcj_pts[i][0], gcj_pts[i][1])
            print(f"[OK] {pname} (from '{qlabel}'): {len(gcj_pts)} pts, {total/1000:.2f}km loop")
            results[pname] = gcj_pts
        else:
            print(f"[--] {pname} ('{qlabel}'): no boundary found")
    else:
        print(f"[--] {pname} ('{qlabel}'): query failed")

print(f"\n=== SUMMARY ===")
print(f"Found {len(results)} park boundaries out of {len(PARK_QUERIES)} queries")
for name, pts in results.items():
    total = sum(haversine(pts[i-1][0], pts[i-1][1], pts[i][0], pts[i][1]) for i in range(1, len(pts)))
    print(f"  {name}: {len(pts)} pts, {total/1000:.2f}km")
