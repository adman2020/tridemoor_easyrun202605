#!/usr/bin/env python3
"""Verify route data."""
import mysql.connector as mc

db = mc.connect(host="127.0.0.1", port=3308, user="root",
                password="stridemoor_root_2026", database="stridemoor")
c = db.cursor()

c.execute("SELECT COUNT(*) FROM route_points")
print(f"Route points: {c.fetchone()[0]}")

c.execute("SELECT COUNT(*) FROM routes WHERE thumbnail_url IS NOT NULL")
print(f"Routes with map: {c.fetchone()[0]}")

print("\nRoute point distribution:")
c.execute("""
    SELECT r.name, COUNT(rp.point_index), MIN(rp.latitude), MAX(rp.latitude)
    FROM routes r
    LEFT JOIN route_points rp ON r.id = rp.route_id
    GROUP BY r.id, r.name
    ORDER BY r.name
""")
for row in c.fetchall():
    print(f"  {row[0]:25s}  {row[1]:4d} pts  lat [{row[2]:.5f} - {row[3]:.5f}]")

# Check a sample route map
c.execute("SELECT id, name, thumbnail_url FROM routes LIMIT 1")
r = c.fetchone()
print(f"\nSample: {r[1]} -> {r[2]}")

db.close()
