#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Overpass API: get park boundary / road coordinates for Shenzhen running routes"""
import json, requests, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

PARKS = {
    "Lianhuashan Park": (22.54, 114.04, 22.57, 114.07),
    "Shenzhen Bay Park": (22.50, 113.93, 22.54, 114.00),
    "Dasha River": (22.52, 113.94, 22.58, 113.97),
    "Meilin Reservoir": (22.56, 114.00, 22.59, 114.04),
    "Talent Park": (22.509, 113.935, 22.526, 113.952),
    "Xiangmi Park": (22.536, 114.015, 22.555, 114.045),
    "Bijiashan Park": (22.552, 114.065, 22.572, 114.085),
    "Central Park": (22.525, 114.055, 22.555, 114.080),
    "Donghu Park": (22.545, 114.130, 22.575, 114.155),
    "Honghu Park": (22.555, 114.108, 22.575, 114.130),
    "Yinhushan": (22.555, 114.070, 22.595, 114.100),
    "Nanshan Park": (22.490, 113.885, 22.515, 113.940),
    "Futian CBD": (22.530, 114.045, 22.550, 114.065),
}

for park, (slat, slng, nlat, nlng) in PARKS.items():
    query = f"""
    [out:json];
    (
      way["highway"]["name"~"跑步|跑道|步道|绿道|栈道|健身步道"]({slat},{slng},{nlat},{nlng});
      way["leisure"="track"]({slat},{slng},{nlat},{nlng});
      way["footway"]({slat},{slng},{nlat},{nlng});
      way["leisure"="running_track"]({slat},{slng},{nlat},{nlng});
    );
    out geom 999;
    """
    try:
        r = requests.post('https://overpass-api.de/api/interpreter',
                          data={'data': query}, timeout=20)
        data = r.json()
        elems = data.get('elements', [])
        print(f"\n=== {park} ({slat},{slng},{nlat},{nlng}) ===")
        if not elems:
            print("  No running tracks found")
        else:
            for e in elems[:5]:
                name = e.get('tags', {}).get('name', 'unnamed')
                highway = e.get('tags', {}).get('highway', '')
                npts = len(e.get('geometry', []))
                if e.get('type') == 'node':
                    lat, lon = e.get('lat',0), e.get('lon',0)
                    print(f"  Node: {name} ({lat:.6f}, {lon:.6f})")
                else:
                    geom = e.get('geometry', [])
                    if geom:
                        lat, lon = geom[0]['lat'], geom[0]['lon']
                        print(f"  Way: {name} [{npts}pts] ({lat:.6f}, {lon:.6f})")
    except Exception as e:
        print(f"  Error: {e}")
