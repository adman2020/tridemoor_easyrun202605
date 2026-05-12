#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io, requests, json, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def wgs84_to_gcj02(wgs_lat, wgs_lng):
    a, ee = 6378245.0, 0.00669342162296594323
    x, y = wgs_lng - 105.0, wgs_lat - 35.0
    dLon = 300.0 + x + 2.0*y + 0.1*x*x + 0.1*x*y + 0.1*math.sqrt(abs(x))
    dLon += (20.0*math.sin(6.0*x*math.pi) + 20.0*math.sin(2.0*x*math.pi))*2.0/3.0
    dLon += (20.0*math.sin(x*math.pi) + 40.0*math.sin(x/3.0*math.pi))*2.0/3.0
    dLon += (150.0*math.sin(x/12.0*math.pi) + 300.0*math.sin(x/30.0*math.pi))*2.0/3.0
    dLat = -100.0 + 2.0*x + 3.0*y + 0.2*y*y + 0.1*x*y + 0.2*math.sqrt(abs(x))
    dLat += (20.0*math.sin(6.0*x*math.pi) + 20.0*math.sin(2.0*x*math.pi))*2.0/3.0
    dLat += (20.0*math.sin(y*math.pi) + 40.0*math.sin(y/3.0*math.pi))*2.0/3.0
    dLon += (160.0*math.sin(y/12.0*math.pi) + 320.0*math.sin(y*math.pi/30.0))*2.0/3.0
    rad_lat = wgs_lat/180.0*math.pi
    magic = math.sin(rad_lat); magic = 1 - 0.00669342162296594323*magic*magic
    sqrt_magic = math.sqrt(magic)
    dLat = (dLat*180.0)/((6378245.0*(1-0.00669342162296594323))/(magic*sqrt_magic)*math.pi)
    dLon = (dLon*180.0)/(6378245.0/sqrt_magic*math.cos(rad_lat)*math.pi)
    return wgs_lat+dLat, wgs_lng+dLon

def osm_to_gcj(elem):
    """Convert OSM geometry to GCJ-02 points"""
    pts = []
    for node in elem.get('geometry', []):
        gcj = wgs84_to_gcj02(node['lat'], node['lon'])
        pts.append(gcj)
    return pts

def get_park_boundary(name, lat, lng, radius_deg=0.02):
    """Query OSM for a park boundary/way"""
    # Try to get the park relation/way first
    q1 = f"""
    [out:json][timeout:15];
    (
      relation["leisure"="park"]["name"~"{name}"]({lat-radius_deg},{lng-radius_deg},{lat+radius_deg},{lng+radius_deg});
      way["leisure"="park"]["name"~"{name}"]({lat-radius_deg},{lng-radius_deg},{lat+radius_deg},{lng+radius_deg});
    );
    out geom;
    """
    h = {"User-Agent": "StrideMoor/1.0"}
    r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q1}, headers=h, timeout=15)
    return r.json()

# Test: get Lianhuashan Park boundary
data = get_park_boundary("莲花山公园", 22.555, 114.055)
elems = data.get('elements', [])
print(f"Lianhuashan Park: {len(elems)} elements")

# For each element, get the perimeter
for e in elems[:3]:
    etype = e.get('type', '?')
    tags = e.get('tags', {})
    name = tags.get('name', 'unnamed')
    geom = e.get('geometry', [])
    pts = len(geom)
    
    if etype == 'relation':
        members = e.get('members', [])
        print(f"  {etype} '{name}': {pts} geom pts, {len(members)} members")
        # Try out geom for members
        for m in members[:5]:
            print(f"    member: {m.get('type')} role={m.get('role','')} ref={m.get('ref',0)}")
    elif etype == 'way' and pts > 0:
        # Convert to GCJ
        gcj_pts = osm_to_gcj(e)
        first = gcj_pts[0] if gcj_pts else (0,0)
        last = gcj_pts[-1] if gcj_pts else (0,0)
        print(f"  {etype} '{name}': {pts} pts, GCJ first=({first[0]:.6f},{first[1]:.6f}) last=({last[0]:.6f},{last[1]:.6f})")

# Also try to get park footways
q2 = """
[out:json][timeout:15];
(
  way["highway"="footway"](22.55,114.045,22.565,114.065);
  way["highway"="steps"](22.55,114.045,22.565,114.065);
  way["highway"="pedestrian"](22.55,114.045,22.565,114.065);
);
out geom;
"""
r = requests.post('https://overpass-api.de/api/interpreter', data={'data': q2}, headers=h, timeout=15)
ways = r.json().get('elements', [])
print(f"\nFootways in Lianhuashan: {len(ways)}")
# Sample a few
for w in ways[:5]:
    name = w.get('tags', {}).get('name', 'unnamed')
    geom = w.get('geometry', [])
    print(f"  {name}: {len(geom)} pts")
