#!/usr/bin/env python3
"""Try Overpass with pure syntax (no regex) for Shenzhen parks."""
import requests, json, sys, io, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# Pure syntax - no regex, no filtering on names with special chars
q = """[out:json][timeout:30];
(
  way(22.48,113.93,22.55,114.05)["leisure"="park"];
  way(22.48,113.93,22.55,114.05)["leisure"="nature_reserve"];
);
out geom tags 30;
"""

print("Querying parks in Shenzhen area (bbox: 22.48-22.55, 113.93-114.05)...")
r = requests.post("https://overpass-api.de/api/interpreter",
                  data={"data": q},
                  headers={"User-Agent": "StrideMoor/1.0"},
                  timeout=30)
print(f"Status: {r.status_code}")
if r.status_code == 200:
    data = r.json()
    elements = data.get("elements", [])
    print(f"Elements: {len(elements)}")
    for e in elements:
        tags = e.get("tags", {})
        name = tags.get("name", "")
        leisure = tags.get("leisure", "")
        geom = e.get("geometry", [])
        if name:
            print(f"  {name:30s} {leisure:15s} {len(geom)} pts ({e['id']})")
        else:
            print(f"  (unnamed) {leisure:15s} {len(geom)} pts ({e['id']})")
else:
    print(f"Response: {r.text[:300]}")

# Also try to find the Shenzhen Bay Park coastal path
print("\nQuerying coastline paths...")
q2 = """[out:json][timeout:30];
way(22.48,113.93,22.55,114.05)["highway"~"footway|cycleway|path"];
out geom tags 30;
"""
r2 = requests.post("https://overpass-api.de/api/interpreter",
                   data={"data": q2},
                   headers={"User-Agent": "StrideMoor/1.0"},
                   timeout=30)
if r2.status_code == 200:
    data2 = r2.json()
    elems = data2.get("elements", [])
    print(f"Footways in bbox: {len(elems)}")
    # Show only named ones
    for e in elems:
        tags = e.get("tags", {})
        name = tags.get("name", "")
        if name:
            geom = e.get("geometry", [])
            print(f"  {name:40s} highway={tags.get('highway',''):15s} {len(geom)} pts")
else:
    print(f"  Error: {r2.status_code}")
