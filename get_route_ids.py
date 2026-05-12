#!/usr/bin/env python3
"""Get route IDs for routes we want to update with OSM data."""
import requests, json, io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYWNmMzIzMDYtMTkyYS00ZGZiLTk0MTYtM2YzMmQ2MGRkNjBlIiwicGhvbmUiOiIxMzgwMDAwMDEwNSIsImlzcyI6InN0cmlkZW1vb3IiLCJzdWIiOiJhY2YzMjMwNi0xOTJhLTRkZmItOTQxNi0zZjMyZDYwZGQ2MGUiLCJleHAiOjE3ODA3NTM1OTUsImlhdCI6MTc3ODE2MTU5NX0.KirfsrpyKiO3R4n9T7QbDeMgnSNiQlcVoZrsZRYSq7g"

r = requests.get("http://localhost:8080/api/v1/routes?page=1&page_size=100",
                 headers={"Authorization": f"Bearer {TOKEN}"}, timeout=10)
routes = r.json().get("data", {}).get("list", [])

targets = ["大沙河生态长廊", "人才公园环湖", "人才公园海滨线", 
           "香蜜公园环湖", "香蜜公园夜跑", "欢乐港湾-前海绿道"]

for t in targets:
    matches = [rt for rt in routes if rt.get("name") == t]
    for m in matches:
        print(f"ID: {m['id']}  NAME: {m['name']:20s}  DIST: {m['distance']:>8}  KM: {float(m['distance'])/1000:.1f}")
