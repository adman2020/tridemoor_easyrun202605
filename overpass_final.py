#!/usr/bin/env python3
"""Fallback: Overpass + manual coordinates for remaining trails."""
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
    ret += (150*math.sin(x/12*math.pi) + 320*math.sin(x/30*math.pi))*2/3
    return ret

def overpass_query(query_str, timeout=30):
    r = requests.post("https://overpass-api.de/api/interpreter",
                      data={"data": query_str},
                      headers={"User-Agent": "StrideMoor/1.0"},
                      timeout=timeout)
    return r.json() if r.status_code == 200 else None

# Known parks we already have OSM boundaries for from earlier Nominatim searches
#深圳湾公园: approx center (22.5246, 113.988) - use Overpass to find park boundary
#盐田海滨栈道: starts ~(22.585, 114.259) ends ~(22.585, 114.326) 
#    actually goes from 沙头角 to 大梅沙 to 小梅沙
#欢乐港湾: (22.5463, 113.8810) - way 771513760 (tourism=attraction)
#奥体中心: (22.715, 114.060) - but note 乌鲁木齐 result before

# Use Overpass with very specific queries on areas near Shenzhen
queries = [
    ("深圳湾公园", """
[out:json][timeout:25];
area["name"="深圳"]->.sz;
way["leisure"="park"]["name"~"深圳湾"](area.sz);
out geom tags 30;
"""),
    ("盐田海滨栈道", """
[out:json][timeout:25];
area["name"="深圳"]->.sz;
way["name"~"盐田|海滨栈道"]["highway"](area.sz);
out geom tags 30;
"""),
    ("欢乐港湾", """
[out:json][timeout:25];
area["name"="深圳"]->.sz;
way(area.sz)["name"="欢乐港湾"];
out geom tags 30;
"""),
    ("大沙河", """
[out:json][timeout:25];
area["name"="深圳"]->.sz;
way["name"~"大沙河"]["highway"~"footway|cycleway|path"](area.sz);
out geom tags 30;
"""),
    ("福田河", """
[out:json][timeout:25];
area["name"="深圳"]->.sz;
way["name"~"福田河"]["highway"~"footway|cycleway|path"](area.sz);
out geom tags 30;
"""),
]

print("=== Overpass targeted queries ===\n")
found_data = {}

for label, q in queries:
    print(f"Querying {label}...")
    try:
        data = overpass_query(q)
        if data:
            elements = data.get("elements", [])
            print(f"  Got {len(elements)} elements")
            for e in elements[:5]:
                tags = e.get("tags", {})
                name = tags.get("name", "")
                highway = tags.get("highway", "")
                geom = e.get("geometry", [])
                coords = [(g["lat"], g["lon"]) for g in geom] if len(geom) > 0 else []
                print(f"    {name:30s} highway={highway:15s} pts={len(coords)}")
                if len(coords) >= 3:
                    found_data[label] = coords
        else:
            print(f"  No data")
    except Exception as e:
        print(f"  ❌ {e}")
    time.sleep(3)

print(f"\n=== Found {len(found_data)} with geometry ===\n")

# Now also try getting 深圳湾公园 by proximity
if "深圳湾公园" not in found_data:
    print("Trying direct OSM search for 深圳湾公园...")
    r = requests.get(
        "https://nominatim.openstreetmap.org/search"
        "?q=深圳湾公园&format=json&limit=3"
        "&viewbox=113.8,22.7,114.3,22.4&bounded=1"
        "&polygon_geojson=1",
        headers={"User-Agent": "StrideMoor/1.0"},
        timeout=10
    )
    if r.status_code == 200:
        for item in r.json():
            osm_type = item.get("osm_type")
            osm_id = item.get("osm_id")
            geo = item.get("geojson", {})
            print(f"  {osm_type}/{osm_id} geo={geo.get('type','')}")
            if geo.get("type") == "Polygon":
                ring = geo["coordinates"][0]
                print(f"    Polygon: {len(ring)} coords")
                found_data["深圳湾公园_geom"] = [(p[1], p[0]) for p in ring]
            elif geo.get("type") == "MultiPolygon":
                ring = geo["coordinates"][0][0]
                print(f"    MultiPolygon: {len(ring)} coords(first)")
                found_data["深圳湾公园_geom"] = [(p[1], p[0]) for p in ring]

# Also try for 盐田海滨栈道
if "盐田海滨栈道" not in found_data:
    print("\nTrying direct OSM for 盐田海滨栈道...")
    # Try getting way 1235968198 details
    r = requests.get("https://api.openstreetmap.org/api/0.6/way/1235968198/full.json",
                     headers={"User-Agent": "StrideMoor/1.0"}, timeout=10)
    if r.status_code == 200:
        data = r.json()
        nodes = {}
        for e in data.get("elements", []):
            if e.get("type") == "node":
                nodes[e["id"]] = (e["lat"], e["lon"])
        for e in data.get("elements", []):
            if e.get("type") == "way":
                coords = [nodes[n] for n in e.get("nodes", []) if n in nodes]
                if len(coords) >= 2:
                    found_data["盐田海滨栈道"] = coords
                    break
        else:
            print("  way resolved but no coordinates found")

print(f"\n=== Final geometries available: {list(found_data.keys())} ===\n")

# Generate SQL for all data
sql_lines = ["-- Remaining linear trails from Overpass", f"-- Generated 2026-05-07", 
             "SET NAMES utf8mb4;", ""]

all_routes = {}

# 深圳湾公园
for key in found_data:
    coords = found_data[key]
    name_tag = key.replace("_geom", "")
    perim = sum(hm(coords[i][0], coords[i][1],
                    coords[(i+1)%len(coords)][0], coords[(i+1)%len(coords)][1])
                for i in range(len(coords)))
    print(f"  {name_tag:20s}: {perim:.0f}m ({len(coords)}pts)")
    gcj_coords = [gcj02_offset(c[0],c[1]) for c in coords]
    if key == "深圳湾公园_geom":
        all_routes["深圳湾公园晨跑线"] = gcj_coords
    all_routes[key] = gcj_coords

# Print summary
print(f"\nGeo data ready: {len(all_routes)} routes")
for k in all_routes:
    print(f"  {k}: {len(all_routes[k])} pts")
