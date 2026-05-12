#!/usr/bin/env python3
"""Verify all run paces are realistic and consistent."""
import mysql.connector

DB = dict(host='127.0.0.1', port=3308, user='root',
          password='stridemoor_root_2026', database='stridemoor')
conn = mysql.connector.connect(**DB)
c = conn.cursor()

c.execute("""SELECT u.nickname, r.total_distance, r.total_time, r.avg_pace
    FROM runs r JOIN users u ON r.user_id = u.id
    WHERE r.is_shared = 1 ORDER BY u.nickname, r.start_time""")

print(f"{'昵称':>8} {'距离':>8} {'耗时':>8}  {'配速':>8}  验证")
print("-" * 50)
unrealistic = 0
for nick, dist, secs, pace in c.fetchall():
    dist_km = float(dist) / 1000
    pace = float(pace) if pace else 0
    calc_pace = round((secs / 60.0) / dist_km, 2) if dist_km > 0 else 0
    ok = "✅" if pace and abs(pace - calc_pace) < 0.02 else "❌"
    time_str = f"{secs//60}:{secs%60:02d}"
    print(f"{nick:>8} {dist_km:>5.1f}km {time_str:>8}  {pace:>6.2f}  {ok}")

# Check all runs for extreme values
c.execute("""SELECT u.nickname, r.total_distance, r.total_time, r.avg_pace, r.id
    FROM runs r JOIN users u ON r.user_id = u.id
    WHERE r.avg_pace < 4.5 OR r.avg_pace > 8.0""")
bad = c.fetchall()
print(f"\n{'='*50}")
print(f"极端值检查: {len(bad)} 条配速<4.5或>8.0")
for nick, dist, secs, pace, rid in bad[:5]:
    print(f"  {nick} {float(dist)/1000:.1f}km {secs}s 配速={pace}")

c.close()
conn.close()
