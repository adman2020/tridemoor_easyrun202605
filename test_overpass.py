#!/usr/bin/env python3
import requests, json

# Try different Overpass endpoints and methods
queries = [
    ("POST overpass-api.de", "https://overpass-api.de/api/interpreter", {"data": '[out:json];node(22.55,114.05,22.56,114.06);out;', '_accept': 'application/json'}),
    ("GET overpass-api.de", "https://overpass-api.de/api/interpreter", {"data": '[out:json];node(22.55,114.05,22.56,114.06);out;'}),
    ("POST main OSM", "https://overpass.openstreetmap.fr/api/interpreter", {"data": '[out:json];node(22.55,114.05,22.56,114.06);out;'}),
    ("POST kumi", "https://overpass.kumi.systems/api/interpreter", {"data": '[out:json];node(22.55,114.05,22.56,114.06);out;'}),
]

for name, url, data in queries:
    try:
        h = {"User-Agent": "StrideMoor/1.0", "Accept": "application/json"}
        if "_accept" in data:
            h["Accept"] = data["_accept"]
            del data["_accept"]
        r = requests.post(url, data=data, headers=h, timeout=15)
        d = r.json() if r.text.startswith('{') else None
        if d and d.get('elements'):
            print(f"✅ {name}: {len(d['elements'])} nodes")
        else:
            txt = r.text[:100]
            print(f"❌ {name}: {r.status_code} {txt}")
    except Exception as e:
        print(f"❌ {name}: {str(e)[:60]}")
