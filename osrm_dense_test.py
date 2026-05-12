#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test: OSRM with dense waypoints along actual park perimeter
Trace the park perimeter at ~200m intervals so OSRM stays on roads
"""
import requests, json, math, sys, io, time
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

# Test 1: 莲花山公园绕湖 - use perimeter waypoints
# The park lake is ~400m x 300m, paths around it
# In WGS-84, park center is approximately:
# Let me define waypoints around the actual lake perimeter
# These are WGS-84 → OSRM gets WGS-84 input
lianhuashan_waypoints = [
    (22.5562, 114.0521),  # 西侧起点（公园西门）
    (22.5580, 114.0505),  # 西北
    (22.5600, 114.0500),  # 北
    (22.5610, 114.0520),  # 东北
    (22.5610, 114.0540),  # 东北-东
    (22.5600, 114.0560),  # 东-东南
    (22.5580, 114.0570),  # 东南（山顶广场附近）
    (22.5560, 114.0560),  # 南
    (22.5550, 114.0540),  # 南偏西
    (22.5555, 114.0520),  # 西南
    (22.5562, 114.0521),  # 回到起点
]

print("=== 莲花山公园 OSRM test ===")
coords = ";".join([f"{lng},{lat}" for lat,lng in lianhuashan_waypoints])
url = f"https://router.project-osrm.org/route/v1/foot/{coords}"
params = {"overview": "full", "geometries": "geojson", "steps": "false", "continue_straight": "false"}
try:
    r = requests.get(url, params=params, timeout=30)
    data = r.json()
    if data["code"] == "Ok":
        rd = data["routes"][0]
        wgs_coords = rd["geometry"]["coordinates"]
        dist_km = rd["distance"] / 1000
        n = len(wgs_coords)
        # Convert first/last to GCJ
        first_gcj = wgs84_to_gcj02(wgs_coords[0][1], wgs_coords[0][0])
        print(f"  Dist: {dist_km:.2f}km, {n} pts")
        print(f"  Start (GCJ): {first_gcj[0]:.6f}, {first_gcj[1]:.6f}")
        # sample a few points
        for i in range(0, n, n//5):
            gcj = wgs84_to_gcj02(wgs_coords[i][1], wgs_coords[i][0])
            print(f"  Pt {i}: ({gcj[0]:.6f}, {gcj[1]:.6f})")
    else:
        print(f"  FAIL: {data}")
except Exception as e:
    print(f"  ERROR: {e}")

# Test 2: 深圳湾公园晨跑线 - follow the coastal road
# Along 望海路 from 红树林(113.998) to 海风运动公园(113.953)
print("\n=== 深圳湾公园 OSRM test ===")
sz_bay_wp = [
    (22.528, 113.997),  # 红树林/福田入口
    (22.527, 113.993),  # 沿海
    (22.526, 113.989),  # 深圳湾公园地铁站
    (22.525, 113.985),  # 白鹭坡
    (22.524, 113.981),  # 小沙山
    (22.522, 113.977),  # 大运火炬塔
    (22.520, 113.973),  # 弯月山谷
    (22.518, 113.969),  # 流花山
    (22.516, 113.965),  # 海韵公园
    (22.514, 113.961),  # 深圳湾大桥
    (22.512, 113.957),  # 海风运动公园
]
coords2 = ";".join([f"{lng},{lat}" for lat,lng in sz_bay_wp])
url2 = f"https://router.project-osrm.org/route/v1/foot/{coords2}"
try:
    r = requests.get(url2, params=params, timeout=30)
    data = r.json()
    if data["code"] == "Ok":
        rd = data["routes"][0]
        wgs_coords = rd["geometry"]["coordinates"]
        dist_km = rd["distance"] / 1000
        n = len(wgs_coords)
        first_gcj = wgs84_to_gcj02(wgs_coords[0][1], wgs_coords[0][0])
        print(f"  Dist: {dist_km:.2f}km, {n} pts")
        print(f"  Start (GCJ): {first_gcj[0]:.6f}, {first_gcj[1]:.6f}")
        for i in range(0, n, n//5):
            gcj = wgs84_to_gcj02(wgs_coords[i][1], wgs_coords[i][0])
            print(f"  Pt {i}: ({gcj[0]:.6f}, {gcj[1]:.6f})")
    else:
        print(f"  FAIL: {data}")
except Exception as e:
    print(f"  ERROR: {e}")
