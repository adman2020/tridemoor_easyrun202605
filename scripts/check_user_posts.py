#!/usr/bin/env python3
"""Check what posts the API returns."""
import mysql.connector as mc

db = mc.connect(host="127.0.0.1", port=3308, user="root",
                password="stridemoor_root_2026", database="stridemoor")
c = db.cursor()

# List all users
c.execute("SELECT id, nickname, avatar FROM users")
print("=== ALL USERS ===")
for r in c.fetchall():
    print(f"  {r[0][:8]}..  {r[1]:12s}  avatar={'Y' if r[2] else 'N'}")

# List all posts with user info
print("\n=== ALL POSTS ===")
c.execute("""
    SELECT p.id, u.nickname, p.content, p.run_id, p.route_id, p.created_at
    FROM posts p
    JOIN users u ON p.user_id = u.id
    ORDER BY p.created_at DESC
    LIMIT 50
""")
for r in c.fetchall():
    has_run = 'Y' if r[3] else 'N'
    has_route = 'Y' if r[4] else 'N'
    print(f"  {r[1]:12s}  {r[2][:30]:30s}  run={has_run}  route={has_route}  {r[5]}")

# Check friendships - maybe user needs to be friends
print("\n=== FRIENDSHIPS ===")
c.execute("SELECT user_a, user_b, status FROM friendships")
for r in c.fetchall():
    # Get nicknames
    c.execute("SELECT nickname FROM users WHERE id=%s", (r[0],))
    na = c.fetchone()[0] if c.rowcount > 0 else "?"
    c.execute("SELECT nickname FROM users WHERE id=%s", (r[1],))
    nb = c.fetchone()[0] if c.rowcount > 0 else "?"
    print(f"  {na:12s} <-> {nb:12s}  status={r[2]}")

# Check the API response directly  
print("\n=== API /api/v1/posts ===")
import urllib.request, json
try:
    resp = urllib.request.urlopen("http://localhost:8080/api/v1/posts?page=1&page_size=20", timeout=5)
    data = json.loads(resp.read().decode())
    if data.get("code") == 0:
        posts = data.get("data", {}).get("list", [])
        print(f"  Total posts from API: {len(posts)}")
        for p in posts:
            u = p.get("user", {})
            route = p.get("route")
            run = p.get("run")
            has_route_pts = "?"
            if route:
                route_id = route.get("id")
                c.execute("SELECT COUNT(*) FROM route_points WHERE route_id=%s", (route_id,))
                has_route_pts = c.fetchone()[0]
            map_img = route.get("thumbnail_url") if route else "N"
            print(f"  {u.get('nickname','?'):12s}  route_pts={has_route_pts:3d}  thumb={map_img[:30] if map_img else 'N':30s}  run_route_pt={'Y' if run and run.get('route_id') else 'N'}")
    else:
        print(f"  API error: {data}")
except Exception as e:
    print(f"  Failed to call API: {e}")

db.close()
