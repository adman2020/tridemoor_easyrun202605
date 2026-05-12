#!/usr/bin/env python3
"""Convert avg_pace and best_pace from min/km (decimal) to sec/km (int)."""
import mysql.connector

DB = dict(host='127.0.0.1', port=3308, user='root',
          password='stridemoor_root_2026', database='stridemoor')
conn = mysql.connector.connect(**DB)
c = conn.cursor()

# Convert runs.avg_pace and best_pace
c.execute('SELECT id, avg_pace, best_pace FROM runs WHERE avg_pace IS NOT NULL OR best_pace IS NOT NULL')
runs = c.fetchall()
for r in runs:
    rid, avg, best = r
    avg_sec = int(round(float(avg) * 60)) if avg else None
    best_sec = int(round(float(best) * 60)) if best else None
    c.execute('UPDATE runs SET avg_pace = %s, best_pace = %s WHERE id = %s', (avg_sec, best_sec, rid))

c.execute("ALTER TABLE runs MODIFY COLUMN avg_pace INT DEFAULT NULL")
c.execute("ALTER TABLE runs MODIFY COLUMN best_pace INT DEFAULT NULL")
print("runs: done")

# Convert route_leaderboards
c.execute('SELECT id, avg_pace FROM route_leaderboards WHERE avg_pace IS NOT NULL')
lbs = c.fetchall()
for lid, pace in lbs:
    c.execute('UPDATE route_leaderboards SET avg_pace = %s WHERE id = %s', (int(round(float(pace) * 60)), lid))
c.execute("ALTER TABLE route_leaderboards MODIFY COLUMN avg_pace INT DEFAULT NULL")
print("route_leaderboards: done")

# Convert run_splits pace
c.execute('SELECT id, pace FROM run_splits WHERE pace IS NOT NULL')
splits = c.fetchall()
for sid, pace in splits:
    c.execute('UPDATE run_splits SET pace = %s WHERE id = %s', (int(round(float(pace) * 60)), sid))
c.execute("ALTER TABLE run_splits MODIFY COLUMN pace INT DEFAULT NULL")
print("run_splits: done")

conn.commit()

# Verify
c.execute("""SELECT u.nickname, r.total_distance, r.total_time, r.avg_pace
    FROM runs r JOIN users u ON r.user_id = u.id
    WHERE r.is_shared = 1 ORDER BY r.avg_pace LIMIT 5""")
print("\n验证（秒/公里）:")
for r in c.fetchall():
    nick, dist, secs, pace = r
    pace_sec = int(pace)
    d_km = float(dist) / 1000
    calc_sec = int(round((secs / 60.0) / d_km * 60))  # expected sec/km
    ok = "OK" if abs(pace_sec - calc_sec) <= 2 else "MISMATCH"
    print(f"  {nick}: {d_km:.1f}km {secs//60}:{secs%60:02d} = {pace_sec//60}:{pace_sec%60:02d}/km (expect {calc_sec//60}:{calc_sec%60:02d}) {ok}")

c.close()
conn.close()
