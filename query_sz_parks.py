#!/usr/bin/env python3
import urllib.request, urllib.parse, json, io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# Use Nominatim to search for parks in Shenzhen
# More reliable than Overpass for simple queries
base = "https://nominatim.openstreetmap.org/search"

# Known Shenzhen parks >2km that might have OSM data
shenzhen_parks = [
    "深圳湾公园", "莲花山公园", "笔架山公园", "东湖公园",
    "中山公园", "中心公园", "南山公园", "塘朗山公园",
    "洪湖公园", "香蜜公园", "人才公园", "梅林公园",
    "银湖山公园", "梧桐山公园", "大沙河公园", "仙湖植物园",
    "华侨城湿地公园", "园博园", "荔香公园", "皇岗公园",
    "彩田公园", "翠竹公园", "儿童公园", "人民公园",
    "荔枝公园", "四海公园", "海滨公园", "白沙岭公园",
    "华强北公园", "景田公园", "福田园岭公园",
    # Linear/greenway parks
    "大沙河生态长廊", "福田河绿道",
]

results = []
for name in shenzhen_parks:
    try:
        params = urllib.parse.urlencode({
            "q": name + " 深圳", "format": "json", "limit": 1,
            "accept-language": "zh"
        })
        req = urllib.request.Request(f"{base}?{params}",
                                     headers={"User-Agent": "StrideMoor/1.0"})
        resp = urllib.request.urlopen(req, timeout=10)
        data = json.loads(resp.read())
        if data:
            r = data[0]
            lat = float(r["lat"])
            lon = float(r["lon"])
            osm_type = r.get("osm_type", "?")
            osm_id = r.get("osm_id", "?")
            results.append((name, lat, lon, osm_type, osm_id))
            print(f"  ✅ {name:20s} ({lat:.4f}, {lon:.4f}) [{osm_type}]")
        else:
            print(f"  ❌ {name:20s} 未找到")
        import time
        time.sleep(1)  # Nominatim rate limit
    except Exception as e:
        print(f"  ⚠️ {name:20s} 查询失败: {e}")

print(f"\n找到 {len(results)}/{len(shenzhen_parks)} 个公园")

# Now check which ones we already have routes for
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYWNmMzIzMDYtMTkyYS00ZGZiLTk0MTYtM2YzMmQ2MGRkNjBlIiwicGhvbmUiOiIxMzgwMDAwMDEwNSIsImlzcyI6InN0cmlkZW1vb3IiLCJzdWIiOiJhY2YzMjMwNi0xOTJhLTRkZmItOTQxNi0zZjMyZDYwZGQ2MGUiLCJleHAiOjE3ODA3NTM1OTUsImlhdCI6MTc3ODE2MTU5NX0.KirfsrpyKiO3R4n9T7QbDeMgnSNiQlcVoZrsZRYSq7g"
req = urllib.request.Request("http://localhost:8080/api/v1/routes?page=1&page_size=100",
                              headers={"Authorization": f"Bearer {TOKEN}"})
resp = urllib.request.urlopen(req)
routes_data = json.loads(resp.read())
db_names = set(r["name"] for r in routes_data.get("data", {}).get("list", []))

print(f"\n数据库现有 {len(db_names)} 条路线")
print(f"\n{'公园':20s}  {'坐标':>20s}  {'状态'}")
print("-" * 55)
for name, lat, lon, osm_type, osm_id in results:
    # Check if park is covered by existing route
    short = name.replace("公园", "").replace("深圳", "")
    covered = [r for r in db_names if short in r]
    if covered:
        print(f"  {name:20s} ({lat:.4f}, {lon:.4f})  ✅ 已有: {', '.join(covered[:2])}")
    else:
        print(f"  {name:20s} ({lat:.4f}, {lon:.4f})  ✨ 可新增")
