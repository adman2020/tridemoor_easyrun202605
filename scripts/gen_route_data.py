#!/usr/bin/env python3
"""Generate route_points GPS data for all routes, and route map images."""
import mysql.connector as mc
import math, random, os

DB = dict(host="127.0.0.1", port=3308, user="root",
          password="stridemoor_root_2026", database="stridemoor")

OUT_IMAGES = r"D:\AI\StrideMoor\backend\uploads\route_maps"
os.makedirs(OUT_IMAGES, exist_ok=True)

db = mc.connect(**DB)
c = db.cursor()

# Fetch all routes
c.execute("SELECT id, name, distance, start_lat, start_lng, center_lat, center_lng FROM routes")
routes = c.fetchall()
print(f"Found {len(routes)} routes")

# Clear existing route_points
c.execute("DELETE FROM route_points")
print("Cleared existing route_points")

# For each route, determine shape type and generate points
def generate_points(name, dist_km, start_lat, start_lng, center_lat, center_lng, num_points=60):
    """Generate GPS points for a route based on its type and location."""
    name_lower = name.lower()
    
    # Determine route shape
    if any(w in name_lower for w in ["环湖", "绕湖", "绕"]):
        # Circular/lake route - go around center
        return generate_circular(start_lat, start_lng, center_lat, center_lng, dist_km, num_points)
    elif any(w in name_lower for w in ["环山", "环山"]):
        # Mountain loop - irregular circle
        return generate_circular(start_lat, start_lng, center_lat, center_lng, dist_km, num_points, wobble=0.002)
    elif any(w in name_lower for w in ["栈道", "海滨"]):
        # Seaside linear route
        return generate_linear(start_lat, start_lng, center_lat, center_lng, dist_km, num_points, wobble=0.001, rname=name)
    elif any(w in name_lower for w in ["郊野", "山郊"]):
        # Winding trail
        return generate_linear(start_lat, start_lng, center_lat, center_lng, dist_km, num_points, wobble=0.003, winding=True, rname=name)
    else:
        # Default: out-and-back or linear
        return generate_linear(start_lat, start_lng, center_lat, center_lng, dist_km, num_points, rname=name)

def generate_circular(slat, slng, clat, clng, dist_km, n, wobble=0.001):
    """Generate points in a circular/oval path."""
    pts = []
    # Determine radius from distance
    r_deg = dist_km * 0.00001  # approx degree per km
    
    for i in range(n):
        angle = (2 * math.pi * i) / n
        # Make slight oval
        rx = r_deg * (0.8 + 0.2 * math.sin(angle * 2))
        ry = r_deg * (0.8 + 0.2 * math.cos(angle * 1.5))
        # Add wobble
        w = random.uniform(-wobble, wobble)
        lat = clat + rx * math.cos(angle) + w
        lng = clng + ry * math.sin(angle) + w * 0.5
        # Add optional altitude variation
        alt = round(random.uniform(10, 50) + 20 * math.sin(angle * 3), 1)
        pts.append((lat, lng, alt))
    return pts

def generate_linear(slat, slng, clat, clng, dist_km, n, wobble=0.001, winding=False, rname=""):
    """Generate points along a linear path with possible wobble."""
    pts = []
    
    # Direction vector from start to center (and beyond, for out-and-back)
    dlng = clng - slng
    dlat = clat - slat
    
    # Total distance in degrees
    total_d = math.sqrt(dlat**2 + dlng**2)
    if total_d < 0.0001:
        total_d = 0.01
    
    # For out-and-back: go from start to far point and back to start
    # Far point: extend from start through center
    ratio = 1.2
    end_lat = slat + dlat * ratio
    end_lng = slng + dlng * ratio
    
    # Generate points along the path
    for i in range(n):
        t = i / (n - 1)  # 0..1
        # Linear position
        base_lat = slat + (end_lat - slat) * t
        base_lng = slng + (end_lng - slng) * t
        
        # Perpendicular wobble
        if winding:
            w = wobble * math.sin(t * math.pi * 6) * (1 + 0.5 * math.sin(t * 3))
        else:
            w = wobble * math.sin(t * math.pi * 4) * 0.5
        
        # Perpendicular direction
        perp_lat = -dlng / total_d * w
        perp_lng = dlat / total_d * w
        
        lat = base_lat + perp_lat + random.uniform(-wobble*0.3, wobble*0.3)
        lng = base_lng + perp_lng + random.uniform(-wobble*0.3, wobble*0.3)
        
        # Altitude variation
        alt = random.uniform(5, 30) + 15 * math.sin(t * math.pi * 5) if "山" in rname else random.uniform(3, 15)
        if "海" in rname or "滨" in rname:
            alt = random.uniform(2, 8)
        pts.append((lat, lng, round(alt, 1)))
    
    return pts

# Generate and insert points
total_pts = 0

for r in routes:
    rid, rname, dist, slat, slng, clat, clng = r
    if slat is None or slng is None:
        print(f"  SKIP {rname}: no GPS data")
        continue
    
    n_pts = max(40, min(100, int(dist * 8 / 1000)))  # ~8 points per km
    slat, slng, clat, clng = float(slat), float(slng), float(clat), float(clng)
    dist = float(dist)
    pts = generate_points(rname, dist, slat, slng, clat, clng, n_pts)
    
    # Insert
    sql = "INSERT INTO route_points (route_id, point_index, latitude, longitude, altitude) VALUES (%s, %s, %s, %s, %s)"
    batch = []
    for i, (lat, lng, alt) in enumerate(pts):
        batch.append((rid, i, round(lat, 7), round(lng, 7), alt))
        # Batch insert every 50
        if len(batch) >= 50:
            c.executemany(sql, batch)
            db.commit()
            batch = []
    
    if batch:
        c.executemany(sql, batch)
        db.commit()
    
    total_pts += len(pts)
    print(f"  {rname:20s}: {len(pts)} points generated")

print(f"\nTotal: {total_pts} route points inserted")

# Now generate route map images (simple route visualization)
print("\nGenerating route map images...")
for r in routes:
    rid, rname, dist, slat, slng, clat, clng = r
    # Get route points
    c.execute("SELECT latitude, longitude FROM route_points WHERE route_id = %s ORDER BY point_index", (rid,))
    pts = [(float(p[0]), float(p[1])) for p in c.fetchall()]
    if len(pts) < 3:
        continue
    
    # Draw route map on a canvas
    try:
        from PIL import Image, ImageDraw
        
        # Scale points to canvas
        lats = [p[0] for p in pts]
        lngs = [p[1] for p in pts]
        min_lat, max_lat = float(min(lats)), float(max(lats))
        min_lng, max_lng = float(min(lngs)), float(max(lngs))
        
        pad = 0.0005
        min_lat -= pad; max_lat += pad
        min_lng -= pad; max_lng += pad
        
        lat_rng = max_lat - min_lat
        lng_rng = max_lng - min_lng
        if lat_rng < 0.0001: lat_rng = 0.001
        if lng_rng < 0.0001: lng_rng = 0.001
        
        w, h = 400, 300
        canvas = Image.new("RGBA", (w, h), (28, 28, 48, 255))
        draw = ImageDraw.Draw(canvas)
        
        # Draw route path
        path_pts = []
        for lat, lng in pts:
            px = int((lng - min_lng) / lng_rng * (w - 40) + 20)
            py = int((max_lat - lat) / lat_rng * (h - 40) + 20)
            path_pts.append((px, py))
        
        # Draw start marker (green circle)
        sx, sy = path_pts[0]
        draw.ellipse([sx-4, sy-4, sx+4, sy+4], fill=(50, 200, 80, 255))
        draw.ellipse([sx-2, sy-2, sx+2, sy+2], fill=(100, 255, 130, 255))
        
        # Draw end marker (red circle)
        ex, ey = path_pts[-1]
        draw.ellipse([ex-4, ey-4, ex+4, ey+4], fill=(200, 50, 50, 255))
        
        # Draw path as gradient segments (green to red)
        for i in range(len(path_pts)-1):
            t = i / (len(path_pts)-1)
            r_col = int(50 + 150 * t)
            g_col = int(200 - 150 * t)
            draw.line([path_pts[i], path_pts[i+1]], fill=(r_col, g_col, 100, 180), width=3)
        
        # Draw grid dots
        for x in range(0, w, 40):
            for y in range(0, h, 40):
                draw.point((x, y), fill=(50, 50, 70, 60))
        
        # Save
        fname = f"{rid[:36]}_map.png"
        fpath = os.path.join(OUT_IMAGES, fname)
        canvas.save(fpath)
        thumb_url = f"/static/route_maps/{fname}"
        
        # Update route with thumbnail_url
        c.execute("UPDATE routes SET thumbnail_url = %s WHERE id = %s", (thumb_url, rid))
        db.commit()
        print(f"  map saved: {rname} -> {fname}")
    except ImportError:
        print(f"  PIL not available, skipping maps")
        break

db.close()
print("\nDone! Route points and map images generated.")
