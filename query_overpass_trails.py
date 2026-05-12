#!/usr/bin/env python3
"""Query Overpass for linear trails in Shenzhen by name keywords."""
import requests, json, time, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

query = """[out:json];
area["name"="深圳"]->.sz;
(
  way["name"~"大沙河|海滨栈道|深圳湾公园|福田河|银湖山|塘朗山|梧桐山"](area.sz);
);
out center tags 30;
"""

print("Sending focused Overpass query for linear trails...")
r = requests.post("https://overpass-api.de/api/interpreter",
                  data={"data": query},
                  headers={"User-Agent": "StrideMoor/1.0"},
                  timeout=60)

print(f"Status: {r.status_code}")
if r.status_code == 200:
    data = r.json()
    elements = data.get("elements", [])
    print(f"Got {len(elements)} elements\n")
    for e in elements:
        tags = e.get("tags", {})
        name = tags.get("name", "")
        highway = tags.get("highway", "")
        leisure = tags.get("leisure", "")
        center = e.get("center", {})
        lat = center.get("lat", 0)
        lon = center.get("lon", 0)
        print(f"  {name:30s} highway={highway:15s} leisure={leisure:10s} ({lat:.4f},{lon:.4f})")
else:
    print(f"Error: {r.text[:500]}")
