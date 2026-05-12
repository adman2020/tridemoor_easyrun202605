#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io, requests
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

queries = [
    ("overpass-api.de POST", "https://overpass-api.de/api/interpreter", {"data": '[out:json];node(22.55,114.05,22.56,114.06);out;'}),
    ("overpass-api.de GET", "https://overpass-api.de/api/interpreter?data=[out:json];node(22.55,114.05,22.56,114.06);out;", {}),
    ("overpass.kumi.systems", "https://overpass.kumi.systems/api/interpreter", {"data": '[out:json];node(22.55,114.05,22.56,114.06);out;'}),
]

for name, url, data in queries:
    try:
        h = {"User-Agent": "StrideMoor/1.0", "Accept": "application/json"}
        if data:
            r = requests.post(url, data=data, headers=h, timeout=15)
        else:
            r = requests.get(url, headers=h, timeout=15)
        
        if r.text.startswith('{'):
            d = r.json()
            print(f"OK {name}: {len(d.get('elements',[]))} elements")
        else:
            print(f"FAIL {name}: {r.status_code} {r.text[:80].strip()}")
    except Exception as e:
        print(f"FAIL {name}: {str(e)[:60]}")
