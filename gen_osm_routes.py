#!/usr/bin/env python3
"""Generate running routes from OSM park/linear trail boundaries.
For loop parks → loop route. For linear parks → out-and-back."""
import requests, json, math, time, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

def gcj02_offset(lat, lon):
    a, ee = 6378245.0, 0.00669342162296594323
    dLat = transform_lat(lon - 105.0, lat - 35.0)
    dLon = transform_lon(lon - 105.0, lat - 35.0)
    radLat = lat / 180.0 * math.pi
    magic = 1 - ee * math.sin(radLat) ** 2
    sqrtMagic = math.sqrt(magic)
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * math.pi)
    dLon = (dLon * 180.0) / (a / sqrtMagic * math.cos(radLat) * math.pi)
    return lat + dLat, lon + dLon

def transform_lat(x, y):
    ret = -100.0 + 2.0*x + 3.0*y + 0.2*y*y + 0.1*x*y + 0.2*math.sqrt(abs(x))
    ret += (20.0*math.sin(6.0*x*math.pi) + 20.0*math.sin(2.0*x*math.pi)) * 2.0/3.0
    ret += (20.0*math.sin(y*math.pi) + 40.0*math.sin(y/3.0*math.pi)) * 2.0/3.0
    ret += (160.0*math.sin(y/12.0*math.pi) + 320.0*math.sin(y*math.pi/30.0)) * 2.0/3.0
    return ret

def transform_lon(x, y):
    ret = 300.0 + x + 2.0*y + 0.1*x*x + 0.1*x*y + 0.1*math.sqrt(abs(x))
    ret += (20.0*math.sin(6.0*x*math.pi) + 20.0*math.sin(2.0*x*math.pi)) * 2.0/3.0
    ret += (20.0*math.sin(x*math.pi) + 40.0*math.sin(x/3.0*math.pi)) * 2.0/3.0
    ret += (150.0*math.sin(x/12.0*math.pi) + 300.0*math.sin(x/30.0*math.pi)) * 2.0/3.0
    return ret

def haversine_m(lat1, lon1, lat2, lon2):
    dy = (lat2 - lat1) * 111320
    dx = (lon2 - lon1) * 111320 * math.cos(math.radians((lat1+lat2)/2))
    return math.sqrt(dx*dx + dy*dy)

def get_osm_geom(osm_type, osm_id):
    url = f"https://api.openstreetmap.org/api/0.6/{osm_type}/{osm_id}/full.json"
    r = requests.get(url, headers={"User-Agent": "StrideMoor/1.0"}, timeout=15)
    data = r.json()
    elements = data.get("elements", [])
    
    # Build node map
    nodes = {}
    for e in elements:
        if e.get("type") == "node":
            nodes[e["id"]] = (e["lat"], e["lon"])
    
    # Get way geometries
    if osm_type == "relation":
        # Find outer members
        outer_ids = []
        for e in elements:
            if e.get("type") == "relation" and e.get("id") == osm_id:
                for m in e.get("members", []):
                    if m.get("role") in ("outer", "") and m.get("type") == "way":
                        outer_ids.append(m["ref"])
        all_coords = []
        for wid in outer_ids:
            for e in elements:
                if e.get("type") == "way" and e.get("id") == wid:
                    all_coords.extend([nodes[n] for n in e.get("nodes", []) if n in nodes])
                    break
        return all_coords
    else:  # way
        for e in elements:
            if e.get("type") == "way" and e.get("id") == osm_id:
                return [nodes[n] for n in e.get("nodes", []) if n in nodes]
    return []

# OSM data we already found
sources = [
    ("大沙河生态长廊(19km)", "relation", 15626532, True, 19000),  # out-and-back, 19km
    ("大沙河生态长廊(7.4km)", "relation", 15626532, True, 7400),  # out-and-back, 7.4km
    ("深圳人才公园环湖", "relation", 18459537, False, 3200),       # loop, 3.2km
    ("深圳人才公园海滨线", "relation", 18459537, True, 6300),       # out-and-back along coast side
    ("香蜜公园环湖", "way", 540340500, False, 2300),                # loop
    ("香蜜公园夜跑", "way", 540340500, True, 3500),                 # loop+extend
    ("欢乐港湾-前海绿道", "way", 771513760, True, 8600),            # out-and-back
]

print("Fetching OSM geometries...\n")
all_sql = []

for name, otype, oid, is_out_and_back, target_m in sources:
    try:
        coords = get_osm_geom(otype, oid)
        time.sleep(1)
        
        if len(coords) < 3:
            print(f"  ⚠️ {name}: 仅{len(coords)}点")
            continue
        
        # Calculate actual perimeter
        perim = sum(haversine_m(coords[i][0], coords[i][1],
                                coords[(i+1)%len(coords)][0], coords[(i+1)%len(coords)][1])
                    for i in range(len(coords)))
        
        # For loop routes, close ring
        if not is_out_and_back:
            loop_coords = coords + [coords[0]]
        else:
            loop_coords = coords
        
        # Convert to GCJ-02
        gcj = [gcj02_offset(lat, lon) for lat, lon in loop_coords]
        
        # Now we need to hit target_m meters
        # Calculate current length
        cur_m = sum(haversine_m(gcj[i][0], gcj[i][1], gcj[i+1][0], gcj[i+1][1])
                    for i in range(len(gcj)-1))
        
        if cur_m < 100:
            print(f"  ⚠️ {name}: 仅{cur_m:.0f}m，跳过")
            continue
        
        # Loop to hit target: repeat route until close to target
        final_coords = []
        if is_out_and_back:
            # For out-and-back: go to far end, return
            half = target_m / 2
            # Find the segment that gets closest to half
            accum = 0
            split_idx = 0
            for i in range(len(gcj)-1):
                seg = haversine_m(gcj[i][0], gcj[i][1], gcj[i+1][0], gcj[i+1][1])
                if accum + seg >= half:
                    # Split at this segment
                    ratio = (half - accum) / seg
                    mid_lat = gcj[i][0] + (gcj[i+1][0] - gcj[i][0]) * ratio
                    mid_lon = gcj[i][1] + (gcj[i+1][1] - gcj[i][1]) * ratio
                    # Forward
                    for j in range(i+1):
                        final_coords.append(gcj[j])
                    final_coords.append((mid_lat, mid_lon))
                    # Back
                    final_coords.append((mid_lat, mid_lon))
                    for j in range(i, -1, -1):
                        final_coords.append(gcj[j])
                    break
                accum += seg
        else:
            # Loop: repeat until close to target
            repeats = max(1, round(target_m / cur_m))
            for _ in range(repeats):
                final_coords.extend(gcj)
                if _ < repeats - 1:
                    final_coords.extend(gcj)
        
        if len(final_coords) < 3:
            print(f"  ⚠️ {name}: 生成后仍不足3点")
            continue
        
        # Recalculate distance
        dist_m = sum(haversine_m(final_coords[i][0], final_coords[i][1],
                                  final_coords[i+1][0], final_coords[i+1][1])
                     for i in range(len(final_coords)-1))
        
        # Interpolate to ~12m per point like existing routes
        total_len = dist_m
        num_points = max(20, int(total_len / 12))
        step = max(1, len(final_coords) // num_points)
        final_coords = final_coords[::step]
        
        print(f"  ✅ {name:25s} {dist_m/1000:.1f}km ({len(final_coords)}pts, out-back={is_out_and_back})")
        
    except Exception as e:
        print(f"  ❌ {name}: {e}")
        time.sleep(1)

print("\n✅ 完成")
