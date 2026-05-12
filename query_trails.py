#!/usr/bin/env python3
"""Try to get specific Shenzhen trail/linear route data from OSM API."""
import requests, json, time, math, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# Parks/trails that need better data - query by name via Nominatim
queries = [
    "深圳梅林水库绿道",
    "深圳大沙河生态长廊",
    "深圳湾公园海滨栈道",
    "深圳盐田海滨栈道",
    "深圳欢乐港湾",
    "深圳福田河绿道",
    "深圳人才公园",
    "深圳奥体中心",
    "深圳香蜜公园",
    "深圳塘朗山",
    "深圳梧桐山",
    "深圳银湖山",
]

results = []
for q in queries:
    try:
        url = "https://nominatim.openstreetmap.org/search"
        params = {"q": q, "format": "json", "limit": 5, "polygon_geojson": 1}
        r = requests.get(url, params=params,
                         headers={"User-Agent": "StrideMoor/1.0"},
                         timeout=10)
        data = r.json()
        for item in data:
            osm_type = item.get("osm_type", "")
            osm_id = item.get("osm_id", 0)
            lat = float(item.get("lat", 0))
            lon = float(item.get("lon", 0))
            geojson = item.get("geojson", {})
            typ = item.get("type", "")
            clss = item.get("class", "")
            display = item.get("display_name", "")[:60]
            results.append((q, osm_type, osm_id, lat, lon, clss, typ, geojson, display))
        time.sleep(1)  # Nominatim rate limit
    except Exception as e:
        print(f"  ❌ {q}: {e}")

print(f"\n{'查询':20s} {'类型':6s} {'ID':>10s} {'坐标':>20s} {'类别':8s} {'名称'}")
print("-"*90)
for q, t, oid, lat, lon, clss, typ, geo, disp in results:
    coords = f"({lat:.4f},{lon:.4f})"
    geom_type = geo.get("type", "") if geo else ""
    print(f"  {q:20s} {t:6s} {oid:>10d} {coords:>20s} {clss:8s} {disp[:40]}")

# Now for each result with polygon data, calculate perimeter
print(f"\n\n=== 有边界数据的公园（计算周长） ===")
for q, t, oid, lat, lon, clss, typ, geo, disp in results:
    if not geo or geo.get("type") not in ("Polygon", "MultiPolygon"):
        continue
    coords_list = geo["coordinates"]
    if geo["type"] == "MultiPolygon":
        coords_list = coords_list[0]
    if not coords_list:
        continue
    ring = coords_list[0] if geo["type"] == "Polygon" else coords_list
    perim = 0
    for i in range(len(ring)):
        clat, clon = ring[i][1], ring[i][0]
        nlat, nlon = ring[(i+1)%len(ring)][1], ring[(i+1)%len(ring)][0]
        dy = (nlat - clat) * 111320
        dx = (nlon - clon) * 111320 * math.cos(math.radians((clat+nlat)/2))
        perim += math.sqrt(dx*dx + dy*dy)
    km = perim / 1000
    print(f"  {q:20s} {km:>5.1f}km ({len(ring)}pts)")
    time.sleep(0.2)
