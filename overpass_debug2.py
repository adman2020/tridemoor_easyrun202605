#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Overpass API with proper headers"""
import requests

# Use GET method
query = "[out:json];(way[\"leisure\"=\"park\"](22.54,114.04,22.57,114.07););out geom 5;"
headers = {'Accept': 'application/json'}
r = requests.get('https://overpass-api.de/api/interpreter', 
                 params={'data': query}, headers=headers, timeout=30)
print(f'Status: {r.status_code}')
print(f'Body (first 500 chars): {r.text[:500]}')
