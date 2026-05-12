#!/usr/bin/env python3
with open('D:\\AI\\StrideMoor\\scripts\\generate_realistic_routes.py', 'r', encoding='utf-8') as f:
    data = f.read()

# Remove windiness parameter - just use distance directly
data = data.replace('wrap_dist(dist_km, slat, dir_lat, dir_lng, windiness=1.0)', 'wrap_dist(dist_km, slat, dir_lat, dir_lng)')
data = data.replace('wrap_dist(dist_km, slat, dir_lat, dir_lng, windiness=1.2)', 'wrap_dist(dist_km, slat, dir_lat, dir_lng)')
data = data.replace('wrap_dist(dist_km, slat, dir_lat, dir_lng, windiness=1.5)', 'wrap_dist(dist_km, slat, dir_lat, dir_lng)')

# Remove unused windiness param from wrap_dist
data = data.replace('def wrap_dist(distance_km, start_lat, dir_lat, dir_lng, windiness=1.0):', 'def wrap_dist(distance_km, start_lat, dir_lat, dir_lng):')

# Remove windiness from calculation
data = data.replace('span_deg = distance_km * deg_per_km / windiness', 'span_deg = distance_km * deg_per_km')

with open('D:\\AI\\StrideMoor\\scripts\\generate_realistic_routes.py', 'w', encoding='utf-8') as f:
    f.write(data)
print('Done')
