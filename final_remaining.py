#!/usr/bin/env python3
"""Get OSM way/relation geometry and generate SQL for remaining routes."""
import requests, json, math, time, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

def hm(lat1, lon1, lat2, lon2):
    dy = (lat2 - lat1) * 111320
    dx = (lon2 - lon1) * 111320 * math.cos(math.radians((lat1+lat2)/2))
    return math.sqrt(dx*dx + dy*dy)

def gcj02_offset(lat, lon):
    a, ee = 6378245.0, 0.00669342162296594323
    dLat = _tl(lon - 105.0, lat - 35.0)
    dLon = _tlon(lon - 105.0, lat - 35.0)
    radLat = lat / 180.0 * math.pi
    magic = math.sin(radLat)
    magic = 1 - ee * magic * magic
    sq = math.sqrt(magic)
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sq) * math.pi)
    dLon = (dLon * 180.0) / (a / sq * math.cos(radLat) * math.pi)
    return lat + dLat, lon + dLon

def _tl(x, y):
    ret = -100.0 + 2*x + 3*y + 0.2*y*y + 0.1*x*y + 0.2*math.sqrt(abs(x))
    ret += (20*math.sin(6*x*math.pi) + 20*math.sin(2*x*math.pi))*2/3
    ret += (20*math.sin(y*math.pi) + 40*math.sin(y/3*math.pi))*2/3
    ret += (160*math.sin(y/12*math.pi) + 320*math.sin(y*math.pi/30))*2/3
    return ret

def _tlon(x, y):
    ret = 300.0 + x + 2*y + 0.1*x*x + 0.1*x*y + 0.1*math.sqrt(abs(x))
    ret += (20*math.sin(6*x*math.pi) + 20*math.sin(2*x*math.pi))*2/3
    ret += (20*math.sin(x*math.pi) + 40*math.sin(x/3*math.pi))*2/3
    ret += (150*math.sin(x/12*math.pi) + 320*math.sin(x/30*math.pi))*2/3
    return ret

def get_geom(osm_type, osm_id):
    url = f"https://api.openstreetmap.org/api/0.6/{osm_type}/{osm_id}/full.json"
    r = requests.get(url, headers={"User-Agent": "StrideMoor/1.0"}, timeout=15)
    data = r.json()
    elems = data.get("elements", [])
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in elems if e.get("type") == "node"}
    if osm_type == "relation":
        outer_ids = []
        for e in elems:
            if e.get("type") == "relation" and e.get("id") == osm_id:
                for m in e.get("members", []):
                    if m.get("role") in ("outer", "") and m.get("type") == "way":
                        outer_ids.append(m["ref"])
        coords = []
        for wid in outer_ids:
            for e in elems:
                if e.get("type") == "way" and e.get("id") == wid:
                    coords.extend([nodes[n] for n in e.get("nodes", []) if n in nodes])
                    break
        return coords
    else:
        for e in elems:
            if e.get("type") == "way" and e.get("id") == osm_id:
                return [nodes[n] for n in e.get("nodes", []) if n in nodes]
    return []

# Get 欢乐港湾 (way 771513760, tourism=attraction)
print("=== Getting known OSM geometries ===")

targets = [
    ("欢乐港湾-前海绿道", "way", 771513760, 8600, 
     "3da7213f-475a-4f15-b14a-93f0121dc2c4"),
]

# Also try Overpass for 深圳湾公园 as a leisure=park
print("\nTrying Overpass for 深圳湾公园 (leisure=park by name)...")
q = "[out:json][timeout:25];way[\"leisure\"=\"park\"][\"name\"=\"深圳湾公园\"];out geom tags 30;"
r = requests.post("https://overpass-api.de/api/interpreter",
                  data={"data": q},
                  headers={"User-Agent": "StrideMoor/1.0"},
                  timeout=30)
if r.status_code == 200:
    data = r.json()
    for e in data.get("elements", []):
        geom = e.get("geometry", [])
        coords = [(g["lat"], g["lon"]) for g in geom]
        print(f"  深圳湾公园: {len(coords)} pts")
        if len(coords) >= 3:
            targets.append(("深圳湾公园沿海跑道", "way", e["id"], 5800,
                           "c3d5a64b-503e-401f-a068-c154aede5755"))
            targets.append(("深圳湾公园晨跑线", "way", e["id"], 3800,
                           "86992120-3eec-4ce4-b44d-8da0c6691632"))

# Try getting a larger area - 深圳湾公园 coastline
q2 = "[out:json][timeout:25];area[\"name\"=\"深圳\"]->.sz;way[\"name\"~\"深圳湾\"];out geom tags 30;"
r2 = requests.post("https://overpass-api.de/api/interpreter",
                   data={"data": q2},
                   headers={"User-Agent": "StrideMoor/1.0"},
                   timeout=30)
if r2.status_code == 200:
    data = r2.json()
    for e in data.get("elements", []):
        tags = e.get("tags", {})
        name = tags.get("name", "")
        geom = e.get("geometry", [])
        print(f"  深圳湾 area: {name:30s} {len(geom)} pts")

# Try 盐田海滨栈道 longer segments via Overpass with relaxed name matching
q3 = "[out:json][timeout:25];way[\"name\"~\"栈道\"][\"highway\"~\"path|footway|steps\"];out geom tags 30;"
r3 = requests.post("https://overpass-api.de/api/interpreter",
                   data={"data": q3},
                   headers={"User-Agent": "StrideMoor/1.0"},
                   timeout=30)
if r3.status_code == 200:
    data = r3.json()
    n_sz = 0
    for e in data.get("elements", []):
        tags = e.get("tags", {})
        name = tags.get("name", "")
        if "深圳" in name or "盐田" in name:
            geom = e.get("geometry", [])
            print(f"  way {e['id']}: {name:40s} {len(geom)} pts")
            n_sz += 1
    print(f"  Total in Shenzhen: {n_sz}")

time.sleep(3)

# Generate SQL for confirmed geometries
sql_lines = ["-- Remaining routes from OSM API/Overpass",
             f"-- Generated: 2026-05-07", "SET NAMES utf8mb4;", ""]

for name, osm_type, osm_id, target_m, rid in targets:
    print(f"\n  Processing {name} ({rid[:8]}...)")
    coords = get_geom(osm_type, osm_id)
    time.sleep(1.2)
    
    if len(coords) < 3:
        print(f"    Skipped: only {len(coords)} pts")
        continue
    
    # Convert to GCJ-02
    gcj = [gcj02_offset(lat, lon) for lat, lon in coords]
    
    perim = sum(hm(gcj[i][0], gcj[i][1],
                    gcj[(i+1)%len(gcj)][0], gcj[(i+1)%len(gcj)][1])
                for i in range(len(gcj)))
    
    print(f"    Raw perim: {perim:.0f}m ({len(gcj)} pts)")
    
    if perim >= target_m * 0.7:
        # Close the polygon as loop
        final = gcj + [gcj[0]]
        print(f"    Loop (perim {perim:.0f}m >= target)")
    else:
        # Out-and-back / repeat
        repeats = max(1, round(target_m / perim))
        final = []
        for rpt in range(repeats):
            final.extend(gcj if rpt % 2 == 0 else list(reversed(gcj)))
        print(f"    Out-back {repeats}x to reach {target_m}m")
    
    dist_m = sum(hm(final[i][0], final[i][1], final[i+1][0], final[i+1][1])
                 for i in range(len(final)-1))
    
    # Simplify
    target_pts = max(30, int(dist_m / 15))
    if len(final) > target_pts * 1.5:
        step = len(final) // target_pts
        final = final[::step]
    
    dist_m = sum(hm(final[i][0], final[i][1], final[i+1][0], final[i+1][1])
                 for i in range(len(final)-1))
    center_lat = sum(p[0] for p in final) / len(final)
    center_lon = sum(p[1] for p in final) / len(final)
    
    print(f"    Final: {dist_m:.0f}m, {len(final)} pts, ({center_lat:.4f},{center_lon:.4f})")
    
    sql_lines.append(f"-- {name}: {rid}")
    sql_lines.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
    sql_lines.append(f"UPDATE routes SET distance = ROUND({dist_m}, 2),")
    sql_lines.append(f"  start_lat = ROUND({final[0][0]}, 6), start_lng = ROUND({final[0][1]}, 6),")
    sql_lines.append(f"  center_lat = ROUND({center_lat}, 6), center_lng = ROUND({center_lon}, 6)")
    sql_lines.append(f"WHERE id = '{rid}';")
    sql_lines.append("")
    
    for i in range(0, len(final), 50):
        batch = final[i:i+50]
        vals = []
        for j, (blat, blon) in enumerate(batch):
            vals.append(f"('{rid}', {i+j}, ROUND({blat}, 6), ROUND({blon}, 6), NULL)")
        sql_lines.append("INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
        sql_lines.append(",\n".join(vals) + ";")
    sql_lines.append("")

with open(r"D:\AI\StrideMoor\final_remaining.sql", "w", encoding="utf-8") as f:
    f.write("\n".join(sql_lines))
print(f"\n✅ SQL written ({len(sql_lines)} lines)")
