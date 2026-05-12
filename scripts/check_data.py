#!/usr/bin/env python3
"""Check current data state: runs, posts, routes."""
import mysql.connector

db = mysql.connector.connect(host="127.0.0.1", port=3308, user="root",
                              password="stridemoor_root_2026", database="stridemoor")
c = db.cursor()

c.execute("SELECT COUNT(*) FROM runs")
print(f"Runs: {c.fetchone()[0]}")

c.execute("SELECT COUNT(*) FROM posts")
print(f"Posts: {c.fetchone()[0]}")

c.execute("SELECT COUNT(*) FROM routes")
print(f"Routes: {c.fetchone()[0]}")

c.execute("""
    SELECT p.id, p.user_id, p.run_id, p.route_id,
           r.id as run_id2, r.route_id as run_route_id, r.total_distance, r.gpx_file_url
    FROM posts p
    LEFT JOIN runs r ON p.run_id = r.id
    LIMIT 20
""")
rows = c.fetchall()
print(f"\nPosts with linked runs:")
for row in rows:
    pid, uid, run_id, route_id, rid2, r_route_id, dist, gpx = row
    has_run = "YES" if rid2 else "NO"
    has_route = "YES" if r_route_id else "NO"
    has_gpx = "YES" if gpx else "NO"
    print(f"  Post {pid[:8]}.. user={uid[:8]}..  has_run={has_run}  has_route={has_route}  gpx={has_gpx}  dist={dist}")

# Check routes table
c.execute("SELECT id, name, distance, gpx_file_url FROM routes LIMIT 10")
print(f"\nRoutes:")
for row in c.fetchall():
    rid, name, dist, gpx = row
    has_gpx = "YES" if gpx else "NO"
    print(f"  {rid[:8]}..  {name:20s}  {dist:6.2f}km  gpx={has_gpx}")

db.close()
