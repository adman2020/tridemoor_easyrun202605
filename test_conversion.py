#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Test WGS84 -> GCJ02 conversion accuracy"""
import sys, io, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Standard GCJ-02 algorithm (Evil Transform)
# Reference: https://on4wp7.codeplex.com/SourceControl/changeset/view/21483#353936
# Published by wuyongzheng

sq = math.sqrt
sin = math.sin
cos = math.cos
atan2 = math.atan2
pi = math.pi

a = 6378245.0
ee = 0.00669342162296594323

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

def wgs84_to_gcj02(wgs_lat, wgs_lng):
    """Standard WGS-84 to GCJ-02 conversion"""
    x = wgs_lng - 105.0
    y = wgs_lat - 35.0
    dLat = transform_lat(x, y)
    dLon = transform_lon(x, y)
    rad_lat = wgs_lat/180.0*pi
    magic = sin(rad_lat)
    magic = 1 - ee*magic*magic
    sqrt_magic = sq(magic)
    dLat = (dLat*180.0)/((a*(1-ee))/(magic*sqrt_magic)*pi)
    dLon = (dLon*180.0)/(a/sqrt_magic*cos(rad_lat)*pi)
    return wgs_lat+dLat, wgs_lng+dLon

# Test points in Shenzhen
test_points = [
    ('洪湖公园中心', 22.566, 114.118),  # Approximate
    ('莲花山公园南门', 22.550, 114.049),  # Seed data center
    ('笔架山公园', 22.565, 114.076),  # Seed data center
    ('世界之窗', 22.537, 113.975),  # Known landmark
]

print("WGS-84 -> GCJ-02 Test:")
print("="*70)
for name, lat, lng in test_points:
    gcj_lat, gcj_lng = wgs84_to_gcj02(lat, lng)
    dlat = gcj_lat - lat
    dlng = gcj_lng - lng
    print(f"{name:16s}: WGS({lat:.4f},{lng:.4f}) -> GCJ({gcj_lat:.4f},{gcj_lng:.4f})")
    print(f"{'':16s}  Offset: dLat={dlat:+.5f}° dLon={dlng:+.5f}° = ({abs(dlat)*111000:.0f}m, {abs(dlng)*111000*cos(lat*pi/180):.0f}m)")
    
# Also test reverse
print()
print("Reverse (GCJ-02 -> WGS-84) Test:")
print("="*70)
# The 景发小区 route that worked: center = (22.5504, 114.0392) - this is GCJ-02
gcj_test_lat, gcj_test_lng = 22.5504, 114.0392
# Convert back to WGS-84
# For reverse, we use iterative approach
wgs_lat, wgs_lng = gcj_test_lat, gcj_test_lng
for _ in range(5):
    g_lat, g_lng = wgs84_to_gcj02(wgs_lat, wgs_lng)
    wgs_lat -= (g_lat - gcj_test_lat)
    wgs_lng -= (g_lng - gcj_test_lng)

print(f"景发小区 GCJ center: ({gcj_test_lat:.4f}, {gcj_test_lng:.4f})")
print(f"  Reverse to WGS:    ({wgs_lat:.4f}, {wgs_lng:.4f})")
print(f"  Difference:        dLat={gcj_test_lat-wgs_lat:+.5f} dLng={gcj_test_lng-wgs_lng:+.5f}")
