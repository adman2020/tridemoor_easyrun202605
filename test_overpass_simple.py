#!/usr/bin/env python3
import requests, json

headers = {"Accept": "application/json"}
q = '[out:json];area[name="深圳"]->.sz;way[leisure="park"](area.sz);out center tags 5;'
r = requests.post("https://overpass-api.de/api/interpreter", 
                  data={"data": q}, headers=headers, timeout=30)
print("Status:", r.status_code)
print("Resp:", r.text[:300])
