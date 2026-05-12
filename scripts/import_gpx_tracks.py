#!/usr/bin/env python3
"""
Parse GPX files from the user's actual runs and import them into StrideMoor DB
as routes (跑迹) with WGS-84 to GCJ-02 coordinate conversion.
"""

import re, math, uuid, random, json, mysql.connector as mc
from datetime import datetime, timezone

import sys
sys.stdout.reconfigure(encoding='utf-8')

# DB config
DB = dict(host="127.0.0.1", port=3308, user="root",
          password="stridemoor_root_2026", database="stridemoor")

# GPX file paths
GPX_FILES = [
    {
        "path": r"C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\c4e33d97-72c4-4fc7-89e7-285c5a8621f2.gpx",
        "name": "娄底晨跑10公里",
        "city": "娄底",
        "tags": ["晨跑", "城市路跑", "湖南"],
        "desc": "娄底城区10公里晨跑路线，经湖南娄底市区道路",
        "creator_id": "44ccc87b-871f-48b0-aed5-cd1b9c21a6cb"
    },
    {
        "path": r"C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\4c3ad50b-e4f2-494a-9cd9-d73c7f10298f.gpx",
        "name": "湘潭晨跑10公里",
        "city": "湘潭",
        "tags": ["晨跑", "城市路跑", "湖南"],
        "desc": "湘潭城区10公里晨跑路线，经湖南湘潭市区道路",
        "creator_id": "44ccc87b-871f-48b0-aed5-cd1b9c21a6cb"
    },
    {
        "path": r"C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\aa90755b-971c-4a81-b69f-a61fc029baa0.xml",
        "name": "环香蜜湖10公里路线",
        "city": "深圳",
        "tags": ["晨跑", "周末跑", "深圳", "香蜜湖"],
        "desc": "深圳香蜜湖10公里环湖晨跑路线，经香蜜湖路、红荔西路沿线",
        "creator_id": "44ccc87b-871f-48b0-aed5-cd1b9c21a6cb"
    }
]

# Coordinate conversion: WGS-84 to GCJ-02
def wgs84_to_gcj02(lat, lng):
    """Convert WGS-84 (GPS) to GCJ-02 (Mars coordinate system)."""
    pi = 3.14159265358979323846
    a = 6378245.0
    ee = 0.00669342162296594323
    
    def out_of_china(lat, lng):
        return lng < 72.004 or lng > 137.8347 or lat < 0.8293 or lat > 55.8271
    
    if out_of_china(lat, lng):
        return lat, lng
    
    def transform_lat(x, y):
        ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * math.sqrt(abs(x))
        ret += (20.0 * math.sin(6.0 * x * pi) + 20.0 * math.sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * math.sin(y * pi) + 40.0 * math.sin(y / 3.0 * pi)) * 2.0 / 3.0
        ret += (160.0 * math.sin(y / 12.0 * pi) + 320.0 * math.sin(y * pi / 30.0)) * 2.0 / 3.0
        return ret
    
    def transform_lng(x, y):
        ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(abs(x))
        ret += (20.0 * math.sin(6.0 * x * pi) + 20.0 * math.sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * math.sin(x * pi) + 40.0 * math.sin(x / 3.0 * pi)) * 2.0 / 3.0
        ret += (150.0 * math.sin(x / 12.0 * pi) + 300.0 * math.sin(x / 30.0 * pi)) * 2.0 / 3.0
        return ret
    
    dlat = transform_lat(lng - 105.0, lat - 35.0)
    dlng = transform_lng(lng - 105.0, lat - 35.0)
    radlat = lat / 180.0 * pi
    magic = math.sin(radlat)
    magic = 1 - ee * magic * magic
    sqrtmagic = math.sqrt(magic)
    dlat = (dlat * 180.0) / ((a * (1 - ee)) / (magic * sqrtmagic) * pi)
    dlng = (dlng * 180.0) / (a / sqrtmagic * math.cos(radlat) * pi)
    return lat + dlat, lng + dlng


def parse_gpx(filepath):
    """Parse GPX file and extract track points."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lats = [float(x) for x in re.findall(r'lat="(.*?)"', content)]
    lons = [float(x) for x in re.findall(r'lon="(.*?)"', content)]
    eles = [float(e) for e in re.findall(r'<ele>(.*?)</ele>', content)]
    times = [t for t in re.findall(r'<time>(.*?)</time>', content) if t]
    
    pts = []
    for i in range(len(lats)):
        gcj_lat, gcj_lon = wgs84_to_gcj02(lats[i], lons[i])
        pt = {
            'lat': gcj_lat,
            'lon': gcj_lon,
        }
        if i < len(eles):
            pt['ele'] = eles[i]
        if i < len(times):
            pt['time'] = times[i]
        pts.append(pt)
    
    return pts


def haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))


def downsample(pts, target=120):
    """Downsample track points to target count."""
    if len(pts) <= target:
        return pts
    step = len(pts) / target
    sampled = []
    for i in range(target):
        idx = min(int(i * step), len(pts) - 1)
        sampled.append(pts[idx])
    # Ensure first and last are included
    if sampled[0] != pts[0]:
        sampled[0] = pts[0]
    if sampled[-1] != pts[-1]:
        sampled[-1] = pts[-1]
    return sampled


def insert_route_points(route_id, pts):
    """Insert route points into DB."""
    db = mc.connect(**DB)
    c = db.cursor()
    
    sql = "INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES (%s, %s, %s, %s, %s)"
    batch = []
    for i, p in enumerate(pts):
        alt = round(p.get('ele', 50), 1)
        batch.append((route_id, i, round(p['lat'], 7), round(p['lon'], 7), alt))
    
    try:
        c.executemany(sql, batch)
        db.commit()
        print(f"  + {len(batch)} route points inserted")
        return True
    except Exception as e:
        print(f"  ! Route points insert failed: {e}")
        db.rollback()
        return False
    finally:
        db.close()


def process_route(gpx_info):
    """Process one GPX file and insert/update into database."""
    print(f"\n{'='*60}")
    print(f"Processing: {gpx_info['name']}")
    print(f"{'='*60}")
    
    pts = parse_gpx(gpx_info['path'])
    print(f"  Parsed {len(pts)} track points")
    
    # Calculate metrics
    total_dist = 0
    ele_gain = 0
    ele_loss = 0
    
    for i in range(1, len(pts)):
        d = haversine(pts[i-1]['lat'], pts[i-1]['lon'], pts[i]['lat'], pts[i]['lon'])
        total_dist += d
        if i < len(pts) and 'ele' in pts[i] and 'ele' in pts[i-1]:
            diff = pts[i]['ele'] - pts[i-1]['ele']
            if diff > 0:
                ele_gain += diff
            else:
                ele_loss += abs(diff)
    
    dist_km = total_dist / 1000
    
    # Time calculation
    start_time = end_time = None
    for p in pts:
        if 'time' in p:
            t = datetime.fromisoformat(p['time'].replace('Z', '+00:00'))
            if start_time is None or t < start_time:
                start_time = t
            if end_time is None or t > end_time:
                end_time = t
    
    duration_seconds = 0
    if start_time and end_time:
        duration_seconds = (end_time - start_time).total_seconds()
    
    avg_pace = 0
    if dist_km > 0 and duration_seconds > 0:
        avg_pace = int(duration_seconds / dist_km)
    
    calories = int(dist_km * 55)
    
    if dist_km < 5:
        difficulty = 1
    elif dist_km < 10:
        difficulty = 2
    elif dist_km < 15:
        difficulty = 3
    else:
        difficulty = 4
    
    start_lat = round(pts[0]['lat'], 7)
    start_lng = round(pts[0]['lon'], 7)
    center_lat = round(sum(p['lat'] for p in pts) / len(pts), 7)
    center_lng = round(sum(p['lon'] for p in pts) / len(pts), 7)
    
    print(f"  Distance: {dist_km:.2f} km")
    print(f"  Duration: {duration_seconds:.0f}s ({duration_seconds/60:.1f} min)")
    print(f"  Avg pace: {avg_pace}s/km")
    print(f"  Elevation gain: {ele_gain:.1f}m / loss: {ele_loss:.1f}m")
    print(f"  Start: {start_lat:.6f}, {start_lng:.6f}")
    print(f"  Center: {center_lat:.6f}, {center_lng:.6f}")
    
    # Downsample
    pts_db = downsample(pts, 120)
    print(f"  Downsampled to {len(pts_db)} points")
    
    # Check if route exists
    db = mc.connect(**DB)
    c = db.cursor()
    c.execute("SELECT id FROM routes WHERE name = %s", (gpx_info['name'],))
    existing = c.fetchone()
    
    if existing:
        route_id = existing[0]
        c.execute("SELECT COUNT(*) FROM route_points WHERE route_id = %s", (route_id,))
        pt_count = c.fetchone()[0]
        if pt_count > 0:
            print(f"  Route already complete ({pt_count} points). Skipping.")
            db.close()
            return route_id
        print(f"  Route exists but no points. Inserting points only.")
        db.close()
        insert_route_points(route_id, pts_db)
        return route_id
    
    # Insert new route
    route_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S.%f')[:23]
    
    sql_route = """INSERT INTO routes (
        id, creator_id, name, description, distance, elevation_gain, elevation_loss,
        difficulty, popularity, rating, rating_count,
        avg_pace, calories,
        tags, city,
        start_lat, start_lng, center_lat, center_lng,
        is_public, status, created_at, updated_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""
    
    values = (
        route_id,
        gpx_info['creator_id'],
        gpx_info['name'],
        gpx_info['desc'],
        round(dist_km * 1000, 2),
        round(ele_gain, 2),
        round(ele_loss, 2),
        difficulty,
        0,
        5.0,
        0,
        avg_pace,
        calories,
        json.dumps(gpx_info['tags'], ensure_ascii=False),
        gpx_info['city'],
        start_lat, start_lng,
        center_lat, center_lng,
        1, 1, now, now
    )
    
    try:
        c.execute(sql_route, values)
        db.commit()
        print(f"  + Route inserted: {route_id[:8]}")
        db.close()
        insert_route_points(route_id, pts_db)
    except Exception as e:
        print(f"  ! Route insert failed: {e}")
        db.rollback()
        db.close()
        return None
    
    return route_id


if __name__ == '__main__':
    print("=" * 60)
    print("StrideMoor - Import User GPX Tracks to PaoJi Plaza")
    print("=" * 60)
    
    for gpx_info in GPX_FILES:
        rid = process_route(gpx_info)
        if rid:
            db = mc.connect(**DB)
            c = db.cursor()
            c.execute("SELECT name FROM routes WHERE id = %s", (rid,))
            row = c.fetchone()
            if row:
                print(f"  => {row[0]} OK")
            c.execute("SELECT COUNT(*) FROM route_points WHERE route_id = %s", (rid,))
            print(f"  => Points: {c.fetchone()[0]}")
            db.close()
    
    print(f"\n{'='*60}")
    print("Done!")
    print(f"{'='*60}")
