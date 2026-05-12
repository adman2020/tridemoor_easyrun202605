#!/usr/bin/env python3
"""清理 stridemoor 数据库中的重复数据"""
import mysql.connector

db = mysql.connector.connect(host="127.0.0.1", port=3308,
                             user="root", password="stridemoor_root_2026",
                             database="stridemoor")
c = db.cursor()
c.execute("SET FOREIGN_KEY_CHECKS = 0")

# 1. 清理重复用户（按手机号，保留最早的）
c.execute("SELECT MIN(id) FROM users GROUP BY phone")
keep = [r[0] for r in c.fetchall()]
c.execute("SELECT id FROM users")  # 获取所有用户
all_ids = [r[0] for r in c.fetchall()]
del_ids = [uid for uid in all_ids if uid not in keep]

if del_ids:
    for did in del_ids:
        for tbl, col in [("friendships", "user_id_a"), ("friendships", "user_id_b"),
                          ("challenges", "challenger_id"), ("challenges", "invitee_id"),
                          ("runs", "user_id"), ("route_leaderboards", "user_id")]:
            c.execute(f"DELETE FROM {tbl} WHERE {col} = %s", (did,))
        c.execute("DELETE FROM routes WHERE creator_id = %s", (did,))
        c.execute("DELETE FROM users WHERE id = %s", (did,))
    print(f"清理 {len(del_ids)} 个重复用户")
else:
    print("无重复用户")

# 2. 清理重复路线（按名称，保留最早的）
c.execute("SELECT MIN(id) FROM routes GROUP BY name")
keep_r = [r[0] for r in c.fetchall()]
c.execute("SELECT id FROM routes")
all_r = [r[0] for r in c.fetchall()]
del_r = [rid for rid in all_r if rid not in keep_r]

if del_r:
    for rid in del_r:
        c.execute("DELETE FROM route_leaderboards WHERE route_id = %s", (rid,))
        c.execute("DELETE FROM challenges WHERE route_id = %s", (rid,))
        c.execute("DELETE FROM runs WHERE route_id = %s", (rid,))
        c.execute("DELETE FROM routes WHERE id = %s", (rid,))
    print(f"清理 {len(del_r)} 条重复路线")
else:
    print("无重复路线")

c.execute("SET FOREIGN_KEY_CHECKS = 1")
db.commit()

# 最终统计
c.execute("SELECT COUNT(*) FROM users")
users = c.fetchone()[0]
c.execute("SELECT COUNT(*) FROM routes")
routes = c.fetchone()[0]
c.execute("SELECT COUNT(*) FROM runs")
runs = c.fetchone()[0]
c.execute("SELECT COUNT(*) FROM run_samples")
samples = c.fetchone()[0]
c.execute("SELECT COUNT(*) FROM friendships WHERE status='accepted'")
friends = c.fetchone()[0]
c.execute("SELECT COUNT(*) FROM challenges")
challenges = c.fetchone()[0]

print(f"\n{'='*40}")
print("📊 最终数据统计")
print(f"{'='*40}")
print(f"👤 用户:     {users}")
print(f"🗺️ 路线:     {routes}")
print(f"🏃 跑步记录: {runs}")
print(f"📍 GPS采样:  {samples}")
print(f"🤝 好友关系: {friends}")
print(f"⚔️ 挑战:     {challenges}")
print(f"{'='*40}")

db.close()
