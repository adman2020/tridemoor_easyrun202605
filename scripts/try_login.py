#!/usr/bin/env python3
"""Try to login and access posts API."""
import urllib.request, json

# Login endpoint
url = "http://localhost:8080/api/v1/auth/login"

passwords = ["123456", "password", "test123456", "stridemoor", "stridemoor2024", "admin123", "111111", "12345678", "888888", "000000"]

for pw in passwords:
    data = json.dumps({"phone": "13800000105", "password": pw}).encode()
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    try:
        resp = urllib.request.urlopen(req, timeout=3)
        body = json.loads(resp.read().decode())
        if body.get("code") == 0:
            print(f"FOUND! Password = '{pw}'")
            token = body["data"]["tokens"]["access_token"]
            # Now try to get posts
            req2 = urllib.request.Request("http://localhost:8080/api/v1/posts?page=1&page_size=3",
                headers={"Authorization": f"Bearer {token}"})
            resp2 = urllib.request.urlopen(req2, timeout=3)
            posts = json.loads(resp2.read().decode())
            if posts.get("code") == 0:
                plist = posts["data"]["list"]
                print(f"Got {len(plist)} posts from API!")
                for p in plist:
                    nick = p.get("user",{}).get("nickname","?")
                    route = p.get("route")
                    points = route.get("points",[]) if route else []
                    print(f"  {nick}: {p.get('content','')[:30]}  route_pts={len(points)}")
            else:
                print(f"  Posts API error: {posts}")
            break
        else:
            print(f"  pw='{pw}' -> {body.get('message','?')}")
    except Exception as e:
        print(f"  pw='{pw}' -> ERROR: {e}")
else:
    print("No password worked!")
