#!/usr/bin/env python3
"""Get geometries for Shenzhen Bay Park sub-parks and generate route SQL."""
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

def get_way_geom(way_id):
    url = f"https://api.openstreetmap.org/api/0.6/way/{way_id}/full.json"
    r = requests.get(url, headers={"User-Agent": "StrideMoor/1.0"}, timeout=15)
    data = r.json()
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in data.get("elements", []) if e.get("type") == "node"}
    for e in data.get("elements", []):
        if e.get("type") == "way" and e.get("id") == way_id:
            return [nodes[n] for n in e.get("nodes", []) if n in nodes], e.get("tags", {})
    return [], {}

# Park ways from Overpass query
park_ways = [
    (238150214, "红树林海滨生态公园"),   # part of 深圳湾公园 south section
    (259033259, "弯月山谷"),             # part of 深圳湾公园
    (259033261, "海风运动广场"),         # part of 深圳湾公园
]

print("=== Fetching 深圳湾公园 sub-park geometries ===\n")
all_coords = []

for wid, pname in park_ways:
    print(f"Getting {pname} (way {wid})...")
    coords, tags = get_way_geom(wid)
    time.sleep(1.2)
    if len(coords) >= 3:
        perim = sum(hm(coords[i][0], coords[i][1], coords[(i+1)%len(coords)][0], coords[(i+1)%len(coords)][1])
                    for i in range(len(coords)))
        print(f"  {perim:.0f}m ({len(coords)} pts)")
        # Convert to GCJ
        gcj = [gcj02_offset(lat, lon) for lat, lon in coords]
        all_coords.extend(gcj)
    else:
        print(f"  too few: {len(coords)}")

# Also try to get the coastline footway/cycleway
print("\nTrying to get 深圳湾公园 coastal path from Nominatim...")
try:
    r = requests.get(
        "https://nominatim.openstreetmap.org/search"
        "?q=深圳湾公园滨海步道&format=json&limit=3"
        "&viewbox=113.90,22.53,114.05,22.48&bounded=1"
        "&polygon_geojson=1",
        headers={"User-Agent": "StrideMoor/1.0"}, timeout=10
    )
    if r.status_code == 200:
        for item in r.json():
            osm_type = item.get("osm_type", "")
            osm_id = item.get("osm_id", 0)
            geo = item.get("geojson", {})
            print(f"  {osm_type}/{osm_id} type={geo.get('type','')} name={item.get('display_name','')[:60]}")
except Exception as e:
    print(f"  Error: {e}")

# Now generate SQL from the combined park coordinates
# Use the combined coordinates as a coastal path
sql_lines = []
route_ids = {
    "深圳湾公园晨跑线": "86992120-3eec-4ce4-b44d-8da0c6691632",
    "深圳湾公园沿海跑道": "c3d5a64b-503e-401f-a068-c154aede5755",
}
targets = {"深圳湾公园晨跑线": 3800, "深圳湾公园沿海跑道": 5800}

if len(all_coords) >= 10:
    # Simplify combined coords
    perim = sum(hm(all_coords[i][0], all_coords[i][1], all_coords[(i+1)%len(all_coords)][0], all_coords[(i+1)%len(all_coords)][1])
                for i in range(len(all_coords)))
    print(f"\nCombined park perimeter: {perim:.0f}m ({len(all_coords)} pts)")
    
    for name in route_ids:
        rid = route_ids[name]
        target = targets[name]
        repeats = max(1, round(target / perim))
        final = []
        for rpt in range(repeats):
            if rpt % 2 == 0:
                final.extend(all_coords)
            else:
                final.extend(list(reversed(all_coords)))
        
        dist = sum(hm(final[i][0], final[i][1], final[i+1][0], final[i+1][1])
                   for i in range(len(final)-1))
        
        # Simplify
        tp = max(30, int(dist / 15))
        if len(final) > tp * 1.5:
            step = len(final) // tp
            final = final[::step]
        
        dist = sum(hm(final[i][0], final[i][1], final[i+1][0], final[i+1][1])
                   for i in range(len(final)-1))
        clat = sum(p[0] for p in final) / len(final)
        clon = sum(p[1] for p in final) / len(final)
        
        print(f"  {name}: {dist:.0f}m {len(final)}pts center=({clat:.4f},{clon:.4f})")
        
        sql_lines.append(f"-- {name}: {rid}")
        sql_lines.append(f"DELETE FROM route_points WHERE route_id = '{rid}';")
        sql_lines.append(f"UPDATE routes SET distance = ROUND({dist}, 2),")
        sql_lines.append(f"  start_lat = ROUND({final[0][0]}, 6), start_lng = ROUND({final[0][1]}, 6),")
        sql_lines.append(f"  center_lat = ROUND({clat}, 6), center_lng = ROUND({clon}, 6)")
        sql_lines.append(f"WHERE id = '{rid}';")
        sql_lines.append("")
        
        for i in range(0, len(final), 50):
            batch = final[i:i+50]
            vals = [f"('{rid}', {i+j}, ROUND({b[0]}, 6), ROUND({b[1]}, 6), NULL)" for j, b in enumerate(batch)]
            sql_lines.append("INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES")
            sql_lines.append(",\n".join(vals) + ";")
        sql_lines.append("")

sql_path = r"D:\AI\StrideMoor\sz_bay_routes.sql"
with open(sql_path, "w", encoding="utf-8") as f:
    f.write("-- Shenzhen Bay Park routes\n".join(sql_lines))
    f.write("\n")

print(f"\n✅ SQL written to {sql_path}")
