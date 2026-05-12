#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io, requests, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Query Lianhuashan Park area for paths and running ways
query = """
[out:json];
(
  way["highway"]["foot"!="no"](22.545,114.045,22.565,114.065);
  way["leisure"~"track|running|pit"](22.545,114.045,22.565,114.065);
  way["route"="running"](22.545,114.045,22.565,114.065);
);
out geom;
"""

h = {"User-Agent": "StrideMoor/1.0"}
r = requests.post('https://overpass-api.de/api/interpreter', data={'data': query}, headers=h, timeout=30)
data = r.json()
elems = data.get('elements', [])
print(f"Total ways: {len(elems)}")

# Group by highway type
types = {}
for e in elems:
    t = e.get('tags', {}).get('highway', e.get('tags', {}).get('leisure', 'unknown'))
    npts = len(e.get('geometry', []))
    if t not in types:
        types[t] = {'count': 0, 'pts': 0}
    types[t]['count'] += 1
    types[t]['pts'] += npts

for k, v in sorted(types.items(), key=lambda x: -x[1]['pts']):
    print(f"  {k}: {v['count']} ways, {v['pts']} total points")

# Show first few ways with names
print("\nNamed ways:")
for e in elems[:10]:
    name = e.get('tags', {}).get('name', '')
    if name:
        geom = e.get('geometry', [])
        pts = len(geom)
        first = (geom[0]['lat'], geom[0]['lon']) if geom else '?'
        print(f"  {name}: {pts}pts, start={first}")
