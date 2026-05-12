#!/usr/bin/env python3
"""Check API post response structure."""
import urllib.request, json

resp = urllib.request.urlopen("http://localhost:8080/api/v1/posts?page=1&page_size=5", timeout=5)
data = json.loads(resp.read().decode())
posts = data.get("data", {}).get("list", [])
print(f"Total from API: {len(posts)}")
for p in posts:
    u = p.get("user", {})
    run = p.get("run")
    route = p.get("route")
    rpts = route.get("route_points", []) if route else []
    tu = route.get("thumbnail_url", "N") if route else "N"
    nick = u.get("nickname", "?")
    content = p.get("content", "")[:40]
    rid = p.get("run_id", "N")
    print(f"\n{nick}: {content}")
    print(f"  run_id={rid[:8] if rid != 'N' else 'N'}  route={p.get('route_id','N')[:8]}")
    print(f"  run.route_id={run.get('route_id','N')[:8] if run and run.get('route_id') else 'N'}")
    print(f"  route.thumbnail={tu[:35]}  route_points={len(rpts)}")
    if route and route.get("thumbnail_url"):
        print(f"  thumbnail_url={route.get('thumbnail_url')}")
    if rpts:
        print(f"  first point: lat={rpts[0].get('latitude')} lng={rpts[0].get('longitude')}")
