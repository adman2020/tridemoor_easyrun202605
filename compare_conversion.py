#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Compare OLD buggy conversion vs STANDARD conversion"""
import sys, io, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
pi = math.pi; sin = math.sin; cos = math.cos; sq = math.sqrt
a, ee = 6378245.0, 0.00669342162296594323

# ===== OLD (BUGGY) conversion =====
def old_convert(wgs_lat, wgs_lng):
    x, y = wgs_lng - 105.0, wgs_lat - 35.0
    dLon = 300.0 + x + 2.0*y + 0.1*x*x + 0.1*x*y + 0.1*math.sqrt(abs(x))
    dLon += (20.0*math.sin(6.0*x*math.pi) + 20.0*math.sin(2.0*x*math.pi))*2.0/3.0
    dLon += (20.0*math.sin(x*math.pi) + 40.0*math.sin(x/3.0*math.pi))*2.0/3.0
    dLon += (150.0*math.sin(x/12.0*math.pi) + 300.0*math.sin(x/30.0*math.pi))*2.0/3.0
    dLat = -100.0 + 2.0*x + 3.0*y + 0.2*y*y + 0.1*x*y + 0.2*math.sqrt(abs(x))
    dLat += (20.0*math.sin(6.0*x*math.pi) + 20.0*math.sin(2.0*x*math.pi))*2.0/3.0
    dLat += (20.0*math.sin(y*math.pi) + 40.0*math.sin(y/3.0*math.pi))*2.0/3.0
    # BUG: lat term (160,320) added to dLon instead of dLat!
    dLon += (160.0*math.sin(y/12.0*math.pi) + 320.0*math.sin(y*math.pi/30.0))*2.0/3.0
    # dLat is MISSING this lat term!
    rad_lat = wgs_lat/180.0*math.pi
    magic = math.sin(rad_lat); magic = 1 - ee*magic*magic
    sqrt_magic = math.sqrt(magic)
    dLat = (dLat*180.0)/((a*(1-ee))/(magic*sqrt_magic)*math.pi)
    dLon = (dLon*180.0)/(a/sqrt_magic*math.cos(rad_lat)*math.pi)
    return wgs_lat+dLat, wgs_lng+dLon

# ===== CORRECT standard conversion =====
def transform_lat(x, y):
    ret = -100.0 + 2.0*x + 3.0*y + 0.2*y*y + 0.1*x*y + 0.2*sq(abs(x))
    ret += (20.0*sin(6.0*x*pi) + 20.0*sin(2.0*x*pi))*2.0/3.0
    ret += (20.0*sin(y*pi) + 40.0*sin(y/3.0*pi))*2.0/3.0
    ret += (160.0*sin(y/12.0*pi) + 320.0*sin(y*pi/30.0))*2.0/3.0
    return ret

def transform_lon(x, y):
    ret = 300.0 + x + 2.0*y + 0.1*x*x + 0.1*x*y + 0.1*sq(abs(x))
    ret += (20.0*sin(6.0*x*pi) + 20.0*sin(2.0*x*pi))*2.0/3.0
    ret += (20.0*sin(x*pi) + 40.0*sin(x/3.0*pi))*2.0/3.0
    ret += (150.0*sin(x/12.0*pi) + 300.0*sin(x/30.0*pi))*2.0/3.0
    return ret

def correct_convert(wgs_lat, wgs_lng):
    x, y = wgs_lng - 105.0, wgs_lat - 35.0
    dLat = transform_lat(x, y)
    dLon = transform_lon(x, y)
    rad_lat = wgs_lat/180.0*pi
    magic = sin(rad_lat); magic = 1 - ee*magic*magic
    sqrt_magic = sq(magic)
    dLat = (dLat*180.0)/((a*(1-ee))/(magic*sqrt_magic)*pi)
    dLon = (dLon*180.0)/(a/sqrt_magic*cos(rad_lat)*pi)
    return wgs_lat+dLat, wgs_lng+dLon

# Test: Wikiloc GPX 洪湖公园 start point (WGS-84)
wgs_lat, wgs_lng = 22.559667, 114.114748

old_gcj_lat, old_gcj_lng = old_convert(wgs_lat, wgs_lng)
correct_gcj_lat, correct_gcj_lng = correct_convert(wgs_lat, wgs_lng)

print(f"WGS-84:               ({wgs_lat:.6f}, {wgs_lng:.6f})")
print(f"OLD (buggy) -> GCJ:   ({old_gcj_lat:.6f}, {old_gcj_lng:.6f})")
print(f"CORRECT -> GCJ:       ({correct_gcj_lat:.6f}, {correct_gcj_lng:.6f})")
print()
print(f"OLD dLat={old_gcj_lat-wgs_lat:+.5f} dLon={old_gcj_lng-wgs_lng:+.5f}")
print(f"OK   dLat={correct_gcj_lat-wgs_lat:+.5f} dLon={correct_gcj_lng-wgs_lng:+.5f}")
diff_lat = old_gcj_lat - correct_gcj_lat
diff_lng = old_gcj_lng - correct_gcj_lng
print()
print(f"DIFFERENCE: dLat={diff_lat:.5f} dLon={diff_lng:.5f}")
print(f"  = ({diff_lat*111000:.0f}m, {diff_lng*111000*cos(22.56*pi/180):.0f}m)")
