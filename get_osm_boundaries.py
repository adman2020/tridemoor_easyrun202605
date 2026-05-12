#!/usr/bin/env python3
import requests, json, io, sys, math, time
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# Parks we know from Nominatim that DON'T have routes yet
new_parks = [
    ("中山公园", "way", 24871066),      # ~2.5km
    ("仙湖植物园", "way", 24870431),     # large
    ("华侨城湿地公园", "way", 139635685),
    ("园博园", "way", 184190657),
    ("荔香公园", "way", 431254701),
    ("皇岗公园", "relation", 3145855),
    ("彩田公园", "way", 497957806),
    ("翠竹公园", "way", 29924756),
    ("儿童公园", "way", 431680558),
    ("人民公园", "way", 544396815),
    ("四海公园", "way", 468248208),
    ("海滨公园", "way", 130867167),
    ("白沙岭公园", "way", 1045923366),
    ("华强北公园", "way", 1188525786),
    ("景田公园", "way", 157988172),
    ("福田园岭公园", "way", 11432831595),
]

print(f"Trying to get OSM boundaries for {len(new_parks)} parks...\n")

osmium_url = "https://osm-api.zeke-clymer.com/api/way"

for name, osm_type, osm_id in new_parks:
    try:
        if osm_type == "way":
            url = f"https://api.openstreetmap.org/api/0.6/way/{osm_id}/full.json"
        else:
            url = f"https://api.openstreetmap.org/api/0.6/relation/{osm_id}/full.json"
        
        r = requests.get(url, headers={"User-Agent": "StrideMoor/1.0"}, timeout=15)
        if r.status_code != 200:
            print(f"  ❌ {name:16s} API error {r.status_code}")
            continue
        
        data = r.json()
        elements = data.get("elements", [])
        
        # Find the way/relation we want
        ways = [e for e in elements if e.get("type") == "way" and e.get("tags",{}).get("name")]
        if not ways:
            # Try finding relation members
            members = [e for e in elements if e.get("type") == "way"]
            if members:
                ways = members
        
        if not ways:
            print(f"  ⚠️ {name:16s} 未找到way元素")
            continue
        
        # Use the first way (or the main one)
        way = ways[0]
        coords = [(nd["lat"], nd["lon"]) for nd in way.get("geometry", [])]
        if not coords:
            nodes = way.get("nodes", [])
            # Need to get node coordinates
            node_ids = nodes[:50]  # limit for query
            node_str = ",".join(str(n) for n in node_ids)
            url2 = f"https://api.openstreetmap.org/api/0.6/nodes?nodes={node_str}"
            r2 = requests.get(url2, headers={"User-Agent": "StrideMoor/1.0"}, timeout=15)
            # This approach is getting too complex
            print(f"  ⚠️ {name:16s} 需要逐一查节点坐标，跳过")
            continue
        
        if len(coords) < 3:
            print(f"  ⚠️ {name:16s} 坐标不足 ({len(coords)}点)")
            continue
        
        # Calculate perimeter
        perimeter = 0
        for i in range(len(coords)):
            lat1, lon1 = coords[i]
            lat2, lon2 = coords[(i + 1) % len(coords)]
            dy = (lat2 - lat1) * 111320
            dx = (lon2 - lon1) * 111320 * math.cos(math.radians((lat1+lat2)/2))
            perimeter += math.sqrt(dx*dx + dy*dy)
        
        km = perimeter / 1000
        marker = "✨" if km >= 2.0 else "🟡"
        print(f"  {marker} {name:16s} {km:>5.1f}km  ({len(coords)}点)")
        
        time.sleep(0.5)  # be nice to OSM API
    except Exception as e:
        print(f"  ❌ {name:16s} 异常: {e}")
