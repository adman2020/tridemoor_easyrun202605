#!/usr/bin/env python3
"""Check data linkage detail."""
import mysql.connector as mc
db = mc.connect(host="127.0.0.1", port=3308, user="root",
                password="stridemoor_root_2026", database="stridemoor")
c = db.cursor()

# Check post->run linkage detail
c.execute("""
    SELECT p.id, p.content, p.user_id, p.run_id, p.route_id,
           r.route_id as run_route
    FROM posts p
    LEFT JOIN runs r ON p.run_id = r.id
    LIMIT 40
""")
rows = c.fetchall()
print(f"Posts: {len(rows)}")
with_route = sum(1 for r in rows if r[4] or r[5])
print(f"  linked to route directly or via run: {with_route}")

# Check which users have what roles
c.execute("SELECT id, nickname FROM users")
users = {r[0]: r[1] for r in c.fetchall()}
print(f"\nUsers: {len(users)}")

# Check 大衍神君 
c.execute("SELECT id, nickname FROM users WHERE nickname LIKE '%大衍%'")
r = c.fetchone()
if r:
    dyd_id = r[0]
    # his posts
    c.execute("SELECT p.id, p.content, r.route_id FROM posts p JOIN runs r ON p.run_id=r.id WHERE p.user_id=%s", (dyd_id,))
    his_posts = c.fetchall()
    print(f"\n大衍神君 ({dyd_id[:8]}..): {len(his_posts)} posts")
    for hp in his_posts:
        print(f"  post={hp[0][:8]}..  route={'Y' if hp[2] else 'N'}")
    
    # his runs
    c.execute("SELECT id, route_id, total_distance FROM runs WHERE user_id=%s", (dyd_id,))
    his_runs = c.fetchall()
    print(f"  大衍神君 runs: {len(his_runs)}")
    for hr in his_runs:
        rpt = 0
        if hr[1]:
            c.execute("SELECT COUNT(*) FROM route_points WHERE route_id=%s", (hr[1],))
            rpt = c.fetchone()[0]
        print(f"    run={hr[0][:8]}..  route={'Y' if hr[1] else 'N'}  pts={rpt}  dist={hr[2]}")

# Check my users (凡人修仙传)
my_users = ["韩立", "银月", "南宫婉", "厉飞雨", "元瑶", "紫灵"]
print(f"\n--- 凡人修仙传 users ---")
for uname in my_users:
    c.execute("SELECT id FROM users WHERE nickname=%s", (uname,))
    r = c.fetchone()
    if r:
        uid = r[0]
        c.execute("SELECT COUNT(*) FROM posts WHERE user_id=%s", (uid,))
        n_posts = c.fetchone()[0]
        c.execute("SELECT COUNT(*) FROM runs WHERE user_id=%s", (uid,))
        n_runs = c.fetchone()[0]
        c.execute("SELECT r.id, r.route_id FROM runs r WHERE r.user_id=%s AND r.route_id IS NOT NULL LIMIT 3", (uid,))
        routes_used = c.fetchall()
        has_route_pts = False
        for ru in routes_used:
            if ru[1]:
                c.execute("SELECT COUNT(*) FROM route_points WHERE route_id=%s", (ru[1],))
                if c.fetchone()[0] > 0:
                    has_route_pts = True
        print(f"  {uname:8s}: {n_posts} posts  {n_runs} runs  has_route_points={'Y' if has_route_pts else 'N'}")

db.close()
