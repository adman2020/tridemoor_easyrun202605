#!/usr/bin/env python3
"""Get geometry from OSM for found ways/relations and generate route SQL."""
import requests, json, math, time, io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# Ways/relations with good geometry from Nominatim results
targets = [
    # (route_name_in_db, osm_type, osm_id, description)
    ("大沙河生态长廊", "relation", 15626532, "大沙河生态长廊→往返路线"),
    ("盐田海滨栈道", "way", 1235968198, "盐田海滨栈道→往返"),
    ("欢乐港湾-前海绿道", "way", 771513760, "欢乐港湾→环线"),
    ("人才公园环湖", "relation", 18459537, "人才公园→环湖"),
    ("香蜜公园环湖", "way", 540340500, "香蜜公园→环湖"),
]

def gcj02_offset(wgs_lat, wgs_lon):
    """WGS-84 → GCJ-02"""
    import math
    a = 6378245.0
    ee = 0.00669342162296594323
    dLat = transform_lat(wgs_lon - 105.0, wgs_lat - 35.0)
    dLon = transform_lon(wgs_lon - 105.0, wgs_lat - 35.0)
    radLat = wgs_lat / 180.0 * math.pi
    magic = math.sin(radLat)
    magic = 1 - ee * magic * magic
    sqrtMagic = math.sqrt(magic)
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * math.pi)
    dLon = (dLon * 180.0) / (a / sqrtMagic * math.cos(radLat) * math.pi)
    return wgs_lat + dLat, wgs_lon + dLon

def transform_lat(x, y):
    import math
    ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * math.sqrt(abs(x))
    ret += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    ret += (20.0 * math.sin(y * math.pi) + 40.0 * math.sin(y / 3.0 * math.pi)) * 2.0 / 3.0
    ret += (160.0 * math.sin(y / 12.0 * math.pi) + 320.0 * math.sin(y * math.pi / 30.0)) * 2.0 / 3.0
    return ret

def transform_lon(x, y):
    import math
    ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(abs(x))
    ret += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    ret += (20.0 * math.sin(x * math.pi) + 40.0 * math.sin(x / 3.0 * math.pi)) * 2.0 / 3.0
    ret += (150.0 * math.sin(x / 12.0 * math.pi) + 300.0 * math.sin(x / 30.0 * math.pi)) * 2.0 / 3.0
    return ret

print("获取 OSM 几何数据...")
all_routes = []

for name, osm_type, osm_id, desc in targets:
    try:
        if osm_type == "relation":
            url = f"https://api.openstreetmap.org/api/0.6/relation/{osm_id}/full.json"
        else:
            url = f"https://api.openstreetmap.org/api/0.6/way/{osm_id}/full.json"
        
        r = requests.get(url, headers={"User-Agent": "StrideMoor/1.0"}, timeout=15)
        if r.status_code != 200:
            print(f"  ❌ {name}: HTTP {r.status_code}")
            time.sleep(1)
            continue
        
        data = r.json()
        elements = data.get("elements", [])
        
        # Collect node coordinates
        nodes_map = {}
        for e in elements:
            if e.get("type") == "node":
                nodes_map[e["id"]] = (e["lat"], e["lon"])
        
        # Find the target way/relation
        if osm_type == "relation":
            # Find outer boundary members
            target_ways = []
            for e in elements:
                if e.get("type") == "relation" and e.get("id") == osm_id:
                    for member in e.get("members", []):
                        if member.get("type") == "way" and member.get("role") in ("outer", ""):
                            target_ways.append(member["ref"])
            # Get those ways
            all_coords = []
            for w_id in target_ways:
                for e in elements:
                    if e.get("type") == "way" and e.get("id") == w_id:
                        coords = []
                        for nid in e.get("nodes", []):
                            if nid in nodes_map:
                                coords.append(nodes_map[nid])
                        if len(coords) >= 2:
                            all_coords.extend(coords)
                        break
            coords = all_coords
        else:  # way
            for e in elements:
                if e.get("type") == "way" and e.get("id") == osm_id:
                    coords = []
                    for nid in e.get("nodes", []):
                        if nid in nodes_map:
                            coords.append(nodes_map[nid])
                    break
                else:
                    coords = [(e.get("lat"), e.get("lon")) for e in elements 
                              if e.get("type") == "node" and e.get("lat") is not None]
        
        if len(coords) < 3:
            print(f"  ⚠️ {name}: 仅 {len(coords)} 点，跳过")
            time.sleep(1)
            continue
        
        # Calculate distance (WGS-84, Haversine)
        import math as m
        total_m = 0
        for i in range(len(coords)-1):
            lat1, lon1 = coords[i]
            lat2, lon2 = coords[i+1]
            dy = (lat2 - lat1) * 111320
            dx = (lon2 - lon1) * 111320 * m.cos(m.radians((lat1+lat2)/2))
            total_m += m.sqrt(dx*dx + dy*dy)
        
        km = total_m / 1000
        print(f"  ✅ {name}: {km:.1f}km ({len(coords)}pts)")
        
        # Convert to GCJ-02
        gcj_coords = [gcj02_offset(lat, lon) for lat, lon in coords]
        
        # Simplify: keep every ~10m to reduce points
        step = max(1, len(gcj_coords) // 200)
        simplified = gcj_coords[::step]
        
        # Pad to get target distance if needed
        # For loop routes, close the polygon
        target_dist = {
            "大沙河生态长廊": 19000,
            "盐田海滨栈道": 15000,
            "欢乐港湾-前海绿道": 8600,
            "人才公园环湖": 3200,
            "香蜜公园环湖": 2300,
        }.get(name, int(km * 1000))
        
        all_routes.append({
            "name": name,
            "coords": simplified,
            "km": km,
            "pts": len(simplified)
        })
        
        time.sleep(1)
    except Exception as e:
        print(f"  ❌ {name}: 异常 {e}")
        time.sleep(1)

# Summary
print(f"\n\n成功获取 {len(all_routes)} 条路线:")
for r in all_routes:
    print(f"  {r['name']:20s} {r['km']:.1f}km ({r['pts']}pts)")
