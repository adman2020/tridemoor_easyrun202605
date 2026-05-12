#!/usr/bin/env python3
"""Check route_points and 大衍神君 data."""
import mysql.connector as mc

db = mc.connect(host="127.0.0.1", port=3308, user="root",
                password="stridemoor_root_2026", database="stridemoor")
c = db.cursor()

c.execute("SELECT COUNT(*) FROM route_points")
print(f"Route points: {c.fetchone()[0]}")

c.execute("SELECT id, name, start_lat, start_lng, gpx_file_url, thumbnail_url FROM routes LIMIT 16")
print("Routes:")
for r in c.fetchall():
    lat = "YES" if r[2] else "NO"
    print(f"  {r[0][:8]}.. {r[1]:20s}  lat={lat}  gpx={'Y' if r[4] else 'N'}  thumb={'Y' if r[5] else 'N'}")

c.execute("SELECT id, nickname, realm FROM users WHERE nickname LIKE '%大衍%'")
for r in c.fetchall():
    print(f"\n大衍神君: id={r[0][:8]}..  nick={r[1]}  realm={r[2]}")

c.execute("SELECT id, nickname, realm FROM users WHERE nickname LIKE '%君'")
print("\nUsers ending with 君:")
for r in c.fetchall():
    print(f"  {r[0][:8]}..  {r[1]:8s}  realm={r[2]}")

db.close()
