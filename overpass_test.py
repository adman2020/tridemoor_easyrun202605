#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Simple Overpass test"""
import requests, json

query = "[out:json];(way[\"leisure\"=\"park\"](22.54,114.04,22.57,114.07););out geom 5;"
r = requests.post('https://overpass-api.de/api/interpreter', data={'data': query}, timeout=30)
data = r.json()
elems = data.get('elements', [])
print(f'Elements: {len(elems)}')
for e in elems[:3]:
    print(e.get('tags',{}).get('name','?'), len(e.get('geometry',[])))
