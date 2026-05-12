#!/usr/bin/env python3
"""Test route generation for one route first."""
import math, random
random.seed(42)

# Test: 深圳湾公园沿海跑道 · 5.0km
# start=(22.52210,113.95200)  center=(22.52360,113.96300)
slat, slng = 22.52210, 113.95200
clat, clng = 22.52360, 113.96300
dist = 5.0

print(f"Test: coastal route, {dist}km")
print(f"start=({slat},{slng}) center=({clat},{clng})")

# Direction from start to center
dl = float(clat) - float(slat)
dn = float(clng) - float(slng)
length = math.sqrt(dl*dl + dn*dn)
print(f"direction=({dl:.6f},{dn:.6f}) length={length:.6f}")

dir_lat = dl / length
dir_lng = dn / length

cos_lat = math.cos(math.radians(float(slat)))
print(f"cos_lat={cos_lat:.6f}")

lat_weight = abs(dir_lat)
lng_weight = abs(dir_lng)
total_w = lat_weight + lng_weight
lat_weight /= total_w
lng_weight /= total_w

scale = dist / 111.0 / (lat_weight + lng_weight * cos_lat)
print(f"scale={scale:.6f}")
end_lat = slat + dir_lat * scale * 2.0
end_lng = slng + dir_lng * scale * 2.0
print(f"end=({end_lat:.6f},{end_lng:.6f})")

# Now generate coastal points
num_points = max(30, int(dist * 10))
print(f"num_points={num_points}")

pts = []
mid_lat = (slat + end_lat) / 2
mid_lng = (slng + end_lng) / 2
bulge = 0.005 * 0.5

for i in range(num_points + 1):
    t = i / num_points
    lat = slat + (end_lat - slat) * t
    lng = slng + (end_lng - slng) * t
    arc = 4 * t * (1 - t)
    lng -= arc * bulge * math.sin(math.radians(lat * 100))
    lat += arc * bulge * 0.3 * math.cos(math.radians(lng * 50))
    lat += 0.0003 * math.sin(5 * math.pi * t)
    lng += 0.0004 * math.cos(5 * math.pi * t + 0.3)
    pts.append((round(lat, 7), round(lng, 7)))

# Calculate real distance
real_m = 0
for i in range(1, len(pts)):
    dy = (pts[i][0] - pts[i-1][0]) * 111000
    dx = (pts[i][1] - pts[i-1][1]) * 111000 * math.cos(math.radians((pts[i][0] + pts[i-1][0])/2))
    real_m += math.sqrt(dx*dx + dy*dy)

print(f"real distance: {real_m/1000:.2f}km  ({len(pts)} points)")
print(f"lat range: {min(p[0] for p in pts):.6f}~{max(p[0] for p in pts):.6f}")
print(f"lng range: {min(p[1] for p in pts):.6f}~{max(p[1] for p in pts):.6f}")
print("\nFirst 5 points:")
for p in pts[:5]:
    print(f"  ({p[0]:.7f}, {p[1]:.7f})")
