#!/usr/bin/env python3
"""Generate SQL to update route_points and route metadata from OSM data."""
import requests, json, math, time, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ====== GCJ-02 conversion ======
def gcj02_offset(lat, lon):
    a, ee = 6378245.0, 0.00669342162296594323
    dLat = _tl(lon - 105.0, lat - 35.0)
    dLon = _tlon(lon - 105.0, lat - 35.0)
    radLat = lat / 180.0 * math.pi
    magic = 1 - ee * math.sin(radLat) ** 2
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
    ret += (150*math.sin(x/12*math.pi) + 300*math.sin(x/30*math.pi))*2/3
    return ret

def hm(lat1, lon1, lat2, lon2):
    dy = (lat2 - lat1) * 111320
    dx = (lon2 - lon1) * 111320 * math.cos(math.radians((lat1+lat2)/2))
    return math.sqrt(dx*dx + dy*dy)

def get_geom(osm_type, osm_id):
    url = f"https://api.openstreetmap.org/api/0.6/{osm_type}/{osm_id}/full.json"
    r = requests.get(url, headers={"User-Agent": "StrideMoor/1.0"}, timeout=15)
    data = r.json()
    elems = data.get("elements", [])
    nodes = {}
    for e in elems:
        if e.get("type") == "node":
            nodes[e["id"]] = (e["lat"], e["lon"])
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

# ====== Route definitions ======
# (route_name, osm_type, osm_id, out_and_back, target_m, db_id)
routes = [
    ("大沙河生态长廊(19km)", "relation", 15626532, True, 19000,
     "d590c5e5-f1e3-4e72-a8cf-c8ade4b83907"),
    ("大沙河生态长廊(7.4km)", "relation", 15626532, True, 7400,
     "ee9ab030-977c-463f-93f0-2e2d823b0d60"),
    ("人才公园环湖", "relation", 18459537, False, 3200,
     "995aa063-40f0-4c8b-985f-823d708d46eb"),
    ("人才公园海滨线", "relation", 18459537, True, 6300,
     "4bf307ae-f4d4-4485-a433-b53ec6bb74bd"),
    ("香蜜公园环湖", "way", 540340500, False, 2300,
     "b875099a-6606-4a00-af6a-f174dcafc331"),
    ("香蜜公园夜跑", "way", 540340500, True, 3500,
     "843ebc2a-d6c2-4be9-8a75-8bbbd8935a11"),
]

sql_statements = []
sql_lines = ["-- Generated OSM route_points injection", f"-- Generated: 2026-05-07", ""]

for name, otype, oid, out_back, target_m, rid in routes:
    print(f"Processing {name} ({rid[:8]}...)")
    coords = get_geom(otype, oid)
    time.sleep(1.2)
    
    if len(coords) < 3:
        print(f"  Skipped: only {len(coords)} points")
        continue
    
    # Convert to GCJ-02
    gcj = [gcj02_offset(lat, lon) for lat, lon in coords]
    
    # For loop routes, close the ring
    if not out_back:
        # For a proper loop, keep the circuit
        pass
    
    # Calculate current length
    cur_m = sum(hm(gcj[i][0], gcj[i][1], gcj[i+1][0], gcj[i+1][1])
                for i in range(len(gcj)-1))
    
    print(f"  Raw curve: {cur_m:.0f}m, {len(gcj)} pts")
    
    # Generate route to hit target distance
    final = []
    if out_back:
        half = target_m / 2
        accum = 0
        split_i = 0
        # Find where to turn around
        for i in range(len(gcj)-1):
            seg = hm(gcj[i][0], gcj[i][1], gcj[i+1][0], gcj[i+1][1])
            if accum + seg >= half:
                ratio = (half - accum) / seg if seg > 0 else 0
                mlat = gcj[i][0] + (gcj[i+1][0] - gcj[i][0]) * ratio
                mlon = gcj[i][1] + (gcj[i+1][1] - gcj[i][1]) * ratio
                # Forward to midpoint
                for j in range(i+1):
                    final.append(gcj[j])
                final.append((mlat, mlon))
                # Back
                for j in range(i, -1, -1):
                    final.append(gcj[j])
                break
            accum += seg
    else:
        # Loop: repeat to hit target
        perim = cur_m
        repeats = max(1, round(target_m / perim))
        for r in range(repeats):
            final.extend(gcj)
    
    if len(final) < 3:
        print(f"  Skipped: only {len(final)} points after generation")
        continue
    
    # Calculate final distance
    dist_m = sum(hm(final[i][0], final[i][1], final[i+1][0], final[i+1][1])
                 for i in range(len(final)-1))
    
    # Simplify to ~12m per point
    target_pts = max(30, int(dist_m / 12))
    if len(final) > target_pts * 2:
        step = len(final) // target_pts
        final = final[::step]
    
    # Recalculate
    dist_m = sum(hm(final[i][0], final[i][1], final[i+1][0], final[i+1][1])
                 for i in range(len(final)-1))
    
    # Center point
    center_lat = sum(p[0] for p in final) / len(final)
    center_lon = sum(p[1] for p in final) / len(final)
    
    print(f"  Final: {dist_m:.0f}m, {len(final)} pts, center=({center_lat:.4f},{center_lon:.4f})")
    
    # Generate SQL
    sql_lines.append(f"-- {name}: {rid}")
    sql_lines.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
    sql_lines.append(f"UPDATE routes SET distance = ROUND({dist_m}, 2),")
    sql_lines.append(f"  start_lat = ROUND({final[0][0]}, 6), start_lng = ROUND({final[0][1]}, 6),")
    sql_lines.append(f"  center_lat = ROUND({center_lat}, 6), center_lng = ROUND({center_lon}, 6)")
    sql_lines.append(f"WHERE id = '{rid}';")
    sql_lines.append("")
    
    # Insert route_points in batches of 50
    for i in range(0, len(final), 50):
        batch = final[i:i+50]
        vals = []
        for j, (lat, lon) in enumerate(batch):
            vals.append(f"('{rid}', {i+j}, ROUND({lat}, 6), ROUND({lon}, 6), NULL)")
        sql_lines.append(f"INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
        sql_lines.append(",\n".join(vals) + ";")
    sql_lines.append("")

# Write SQL file
sql_path = r"D:\AI\StrideMoor\osm_update_routes.sql"
with open(sql_path, "w", encoding="utf-8") as f:
    f.write("\n".join(sql_lines))
print(f"\n✅ SQL written to {sql_path}")
print(f"   Total lines: {len(sql_lines)}")
