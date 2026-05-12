#!/usr/bin/env python3
"""Check what the API actually returns for paces."""
import requests, json

BASE = 'http://localhost:8080/api/v1'
r = requests.post(f'{BASE}/auth/login', json={'phone':'13800000101','password':'123456'})
token = r.json()['data']['tokens']['access_token']

r = requests.get(f'{BASE}/posts?page=1&page_size=5', headers={'Authorization': f'Bearer {token}'})
posts = r.json()['data']['list']

nick = lambda p: p.get('user',{}).get('nickname','?')
for p in posts:
    run = p.get('run')
    if run:
        d = float(run['total_distance'])/1000
        t = run['total_time']
        pace = float(run['avg_pace'])
        pm, ps = int(pace), int((pace - int(pace))*60)
        calc = round((t/60.0)/d, 2) if d > 0 else 0
        print("{:6s}: {:.1f}km in {:d}:{:02d} = {:d}:{:02d}/km (calc={:.2f}) check={}".format(
            nick(p), d, t//60, t%60, pm, ps, calc, "OK" if abs(pace-calc)<0.02 else "MISMATCH"))
