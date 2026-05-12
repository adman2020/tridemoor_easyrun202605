#!/usr/bin/env python3
"""Verify post data: pace correctness and like/comment counts."""
import requests, json

BASE = "http://localhost:8080/api/v1"

# Login
resp = requests.post(f"{BASE}/auth/login", json={
    "phone": "13800000101", "password": "123456"
})
token = resp.json()["data"]["tokens"]["access_token"]
headers = {"Authorization": f"Bearer {token}"}

# Get posts
resp = requests.get(f"{BASE}/posts?page=1&page_size=10", headers=headers)
data = resp.json()

if data["code"] != 0:
    print(f"Error: {data}")
    exit(1)

posts = data["data"]["list"]
print(f"\n📊 共 {data['data']['total']} 条动态\n")

pace_errors = 0
for p in posts:
    run = p.get("run")
    nm = p.get("user", {}).get("nickname", "?")
    lk = p.get("like_count", 0)
    cm = p.get("comment_count", 0)
    content_short = p.get("content", "")[:30]
    
    if run:
        dist = run["total_distance"]
        secs = run["total_time"]
        pace = run.get("avg_pace")
        calc_pace = round((secs / 60.0) / (dist / 1000.0), 2) if dist > 0 and secs > 0 else 0
        diff = abs(pace - calc_pace) if pace else 999
        ok = "✅" if diff < 0.01 else "❌"
        if diff >= 0.01:
            pace_errors += 1
        print(f"{ok} {nm:6s} | {dist/1000:.1f}km/{secs}s | 配速={pace:.2f}(应={calc_pace:.2f}) | 👍{lk} 💬{cm}")
    else:
        print(f"📝 {nm:6s} | (无跑步记录) | 👍{lk} 💬{cm}")

print(f"\n{'='*50}")
print(f"配速比对: {pace_errors}/10 有误差 ✅ 全部正确" if pace_errors == 0 else f"配速比对: {pace_errors}/10 有误差 ⚠️")
print(f"like_count: {'✅ 有值' if all(p.get('like_count', -1) >= 0 for p in posts) else '❌ 缺失'}")
print(f"comment_count: {'✅ 有值' if all(p.get('comment_count', -1) >= 0 for p in posts) else '❌ 缺失'}")
