#!/usr/bin/env python3
"""Get linear trail geometries from OSM for remaining 11 routes using Overpass.
One-way (单向) is fine per user instruction."""
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
    ret += (150*math.sin(x/12*math.pi) + 320*math.sin(x*math.pi/30))*2/3
    return ret

# Known route info - use Nominatim to find them
# For each trail, search by name in Shenzhen area
trails = [
    # (route_name_in_db, search_keyword, target_meters)
    ("大沙河生态长廊(19km)", "深圳大沙河生态长廊", 19000),  # already done
    ("大沙河生态长廊(7.4km)", "深圳大沙河生态长廊", 7400),    # already done
    ("深圳湾公园晨跑线", "深圳湾公园", 3800),
    ("深圳湾公园沿海跑道", "深圳湾公园滨海栈道", 5800),
    ("盐田海滨栈道", "深圳盐田海滨栈道", 15000),
    ("福田河绿道", "深圳福田河绿道", 9800),
    ("欢乐港湾-前海绿道", "深圳欢乐港湾前海", 8600),
    ("塘朗山越野跑", "深圳塘朗山", 10400),
    ("塘朗山郊野径", "深圳塘朗山郊野径", 12700),
    ("梅林水库绿道", "深圳梅林水库", 10600),
    ("梧桐山绿道", "深圳梧桐山", 19300),
    ("银湖山郊野径", "深圳银湖山", 14300),
    ("奥体中心绕圈", "深圳奥林匹克体育中心", 4700),
]

print("=== 搜索深圳线性绿道/公园 ===")
all_found = {}

for name, keyword, target_m in trails:
    if name in ("大沙河生态长廊(19km)", "大沙河生态长廊(7.4km)"):
        continue  # already done
    try:
        url = "https://nominatim.openstreetmap.org/search"
        params = {"q": keyword, "format": "json", "limit": 5,
                  "bounded": 1, "viewbox": "113.8,22.7,114.3,22.4",
                  "polygon_geojson": 1}
        r = requests.get(url, params=params,
                         headers={"User-Agent": "StrideMoor/1.0"},
                         timeout=10)
        data = r.json()
        matches = []
        for item in data:
            osm_type = item.get("osm_type", "")
            osm_id = item.get("osm_id", 0)
            clss = item.get("class", "")
            typ = item.get("type", "")
            lat, lon = float(item.get("lat", 0)), float(item.get("lon", 0))
            geo = item.get("geojson", {})
            geo_type = geo.get("type", "")
            disp = item.get("display_name", "")[:80]
            matches.append((osm_type, osm_id, clss, typ, lat, lon, geo_type, len(geo.get("coordinates", [])), disp))
        all_found[name] = matches
        print(f"  {name:20s}: {len(matches)} results")
        for m in matches[:3]:
            print(f"    {m[0]:10s} ID={m[1]:>12d} class={m[2]:10s} type={m[3]:10s} geo={m[6]:10s} ({m[4]:.4f},{m[5]:.4f})")
        time.sleep(1.2)
    except Exception as e:
        print(f"  ❌ {name}: {e}")
        time.sleep(1)

print("\n=== 选取最佳候选并拉取几何数据 ===")
# Now pick the best candidate for each trail and get full geometry
# Priority: relation > way with geojson > node
sql_parts = []
sql_path = r"D:\AI\StrideMoor\linear_trails_sql.sql"
sql_lines = ["-- Linear trails OSM-based route_points injection",
             "-- Generated: 2026-05-07", "SET NAMES utf8mb4;", ""]

# DB route IDs for remaining routes
route_ids = {
    "深圳湾公园晨跑线": "86992120-3eec-4ce4-b44d-8da0c6691632",
    "深圳湾公园沿海跑道": "c3d5a64b-503e-401f-a068-c154aede5755",
    "盐田海滨栈道": "b3d17360-21b5-4366-bf80-8b77be911762",
    "福田河绿道": "b5901b3c-5704-495d-a6da-b472f86001d3",
    "欢乐港湾-前海绿道": "3da7213f-475a-4f15-b14a-93f0121dc2c4",
    "塘朗山越野跑": "f712c0ec-6af0-43b6-a056-3018c6bdb2c1",
    "塘朗山郊野径": "95c1e112-511c-4048-8856-9369360afebd",
    "梅林水库绿道": "4a440fed-0ceb-4a4f-a0e1-324f48509148",
    "梧桐山绿道": "c2832561-5363-4849-bff2-4b5b79576a2c",
    "银湖山郊野径": "fa4f2f71-e158-49ba-8a0e-5c12828cdcf6",
    "奥体中心绕圈": "9437791a-95cf-4b40-a291-f34a352a4f87",
}

target_dists = {
    "深圳湾公园晨跑线": 3800, "深圳湾公园沿海跑道": 5800,
    "盐田海滨栈道": 15000, "福田河绿道": 9800,
    "欢乐港湾-前海绿道": 8600, "塘朗山越野跑": 10400,
    "塘朗山郊野径": 12700, "梅林水库绿道": 10600,
    "梧桐山绿道": 19300, "银湖山郊野径": 14300,
    "奥体中心绕圈": 4700,
}

for name in route_ids:
    matches = all_found.get(name, [])
    if not matches:
        print(f"  ⚠️ {name}: no matches found")
        continue
    
    # Pick best: prefer leisure=park with polygon, or way with highway
    # Try to find a way or relation with polygon geometry
    best = None
    for m in matches:
        osm_type, osm_id, clss, typ, lat, lon, geo_type, coord_count, disp = m
        if geo_type in ("Polygon", "MultiPolygon") and coord_count > 10:
            best = m
            break
    if not best:
        # Pick the first way or relation
        for m in matches:
            if m[0] in ("way", "relation"):
                best = m
                break
    if not best:
        best = matches[0]
    
    osm_type, osm_id, clss, typ, lat, lon, geo_type, coord_count, disp = best
    print(f"\n  {name:20s}: using {osm_type}/{osm_id} ({clss}/{typ}) at ({lat:.4f},{lon:.4f})")
    print(f"    display: {disp}")
    
    try:
        # Get full geometry
        if osm_type == "relation":
            url = f"https://api.openstreetmap.org/api/0.6/relation/{osm_id}/full.json"
        else:
            url = f"https://api.openstreetmap.org/api/0.6/way/{osm_id}/full.json"
        
        r = requests.get(url, headers={"User-Agent": "StrideMoor/1.0"}, timeout=15)
        if r.status_code != 200:
            print(f"    ❌ HTTP {r.status_code}")
            time.sleep(1.2)
            continue
        
        data = r.json()
        elems = data.get("elements", [])
        nodes = {}
        for e in elems:
            if e.get("type") == "node":
                nodes[e["id"]] = (e["lat"], e["lon"])
        
        coords = []
        if osm_type == "relation":
            outer_ids = []
            for e in elems:
                if e.get("type") == "relation" and e.get("id") == osm_id:
                    for mbr in e.get("members", []):
                        if mbr.get("role") in ("outer", "") and mbr.get("type") == "way":
                            outer_ids.append(mbr["ref"])
            for wid in outer_ids:
                for e in elems:
                    if e.get("type") == "way" and e.get("id") == wid:
                        coords.extend([nodes[n] for n in e.get("nodes", []) if n in nodes])
                        break
        else:
            for e in elems:
                if e.get("type") == "way" and e.get("id") == osm_id:
                    coords = [nodes[n] for n in e.get("nodes", []) if n in nodes]
                    break
                elif e.get("type") == "node":
                    pass  # already in nodes
        
        if len(coords) < 3:
            print(f"    ⚠️ Only {len(coords)} coords")
            time.sleep(1.2)
            continue
        
        # Calculate perimeter
        perim = sum(hm(coords[i][0], coords[i][1],
                        coords[(i+1)%len(coords)][0], coords[(i+1)%len(coords)][1])
                    for i in range(len(coords)))
        
        # Convert to GCJ-02
        gcj = [gcj02_offset(lat, lon) for lat, lon in coords]
        
        rid = route_ids[name]
        target_m = target_dists[name]
        
        # For loop parks (奥体中心), close the ring
        # For linear trails, do one-way or out-and-back based on perimeter vs target
        if perim >= target_m * 0.8:
            # Park boundary is big enough, use it directly (for loop routes)
            # Close the polygon
            loop_coords = gcj + [gcj[0]]
            final = loop_coords[:]
            print(f"    Loop route: {perim:.0f}m perimeter")
        else:
            # Need to repeat or do out-and-back
            repeats = max(1, round(target_m / perim))
            final = []
            for rpt in range(repeats):
                if rpt % 2 == 0:
                    final.extend(gcj)
                else:
                    final.extend(reversed(gcj))
            print(f"    Repeated {repeats}x: target={target_m}m, raw_perim={perim:.0f}m")
        
        if len(final) < 3:
            print(f"    ⚠️ Only {len(final)} after generation")
            time.sleep(1.2)
            continue
        
        # Calculate final distance
        dist_m = sum(hm(final[i][0], final[i][1], final[i+1][0], final[i+1][1])
                     for i in range(len(final)-1))
        
        # Simplify to ~15m per point
        target_pts = max(30, int(dist_m / 15))
        if len(final) > target_pts * 1.5:
            step = len(final) // target_pts
            final = final[::step]
        
        dist_m = sum(hm(final[i][0], final[i][1], final[i+1][0], final[i+1][1])
                     for i in range(len(final)-1))
        
        center_lat = sum(p[0] for p in final) / len(final)
        center_lon = sum(p[1] for p in final) / len(final)
        
        print(f"    Final: {dist_m:.0f}m, {len(final)}pts, center=({center_lat:.4f},{center_lon:.4f})")
        
        # Generate SQL
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
        
        time.sleep(1.2)
    except Exception as e:
        print(f"    ❌ Error: {e}")
        time.sleep(1.2)

with open(sql_path, "w", encoding="utf-8") as f:
    f.write("\n".join(sql_lines))
print(f"\n✅ SQL written ({len(sql_lines)} lines)")
