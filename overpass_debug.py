#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Debug Overpass response"""
import requests

query = "[out:json];(way[\"leisure\"=\"park\"](22.54,114.04,22.57,114.07););out geom 5;"
r = requests.post('https://overpass-api.de/api/interpreter', data={'data': query}, timeout=30)
ct = r.headers.get('content-type', '')
print(f'Status: {r.status_code}')
print(f'Content-Type: {ct}')
print(f'Body (first 500 chars): {r.text[:500]}')
