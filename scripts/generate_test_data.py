#!/usr/bin/env python3
"""
驰陌 / StrideMoor 测试数据生成器 v2
生成：用户、跑迹（路线）、跑步记录、GPS采样、好友关系、挑战记录、排行榜
"""

import uuid
import random
import math
import bcrypt
import mysql.connector
from datetime import datetime, timedelta

# ========== 数据库配置 ==========
DB_CONFIG = {
    "host": "127.0.0.1",
    "port": 3308,
    "user": "root",
    "password": "stridemoor_root_2026",
    "database": "stridemoor",
}

# ========== 统一密码 ==========
PASSWORD = "123456"
PASSWORD_HASH = bcrypt.hashpw(PASSWORD.encode(), bcrypt.gensalt(10)).decode()

# ========== 深圳跑道路线坐标 ==========
ROUTES_DATA = [
    {
        "name": "深圳湾公园沿海跑道",
        "description": "深圳湾公园沿海步道，平坦开阔，适合晨跑和夜跑，沿途可见海景",
        "distance": 5000, "elevation_gain": 10, "elevation_loss": 10,
        "difficulty": 1, "city": "深圳",
        "center": (22.5236, 113.9630),
        "points": [
            (22.5221, 113.9520), (22.5213, 113.9545), (22.5208, 113.9570),
            (22.5202, 113.9595), (22.5197, 113.9620), (22.5192, 113.9645),
            (22.5187, 113.9670), (22.5182, 113.9695), (22.5175, 113.9720),
            (22.5168, 113.9745), (22.5160, 113.9770),
        ],
    },
    {
        "name": "南山公园环山道",
        "description": "南山公园环山路线，有一定坡度，适合进阶跑者练习爬坡",
        "distance": 7000, "elevation_gain": 180, "elevation_loss": 180,
        "difficulty": 2, "city": "深圳",
        "center": (22.5340, 113.9440),
        "points": [
            (22.5350, 113.9300), (22.5345, 113.9330), (22.5342, 113.9360),
            (22.5338, 113.9390), (22.5340, 113.9420), (22.5343, 113.9450),
            (22.5348, 113.9480), (22.5350, 113.9510), (22.5345, 113.9540),
            (22.5340, 113.9570),
        ],
    },
    {
        "name": "莲花山公园绕湖",
        "description": "莲花山公园绕湖跑道，绿树成荫，适合轻松跑和恢复跑",
        "distance": 3000, "elevation_gain": 15, "elevation_loss": 15,
        "difficulty": 1, "city": "深圳",
        "center": (22.5592, 114.0530),
        "points": [
            (22.5590, 114.0490), (22.5588, 114.0510), (22.5585, 114.0530),
            (22.5588, 114.0550), (22.5592, 114.0570), (22.5595, 114.0550),
            (22.5598, 114.0530), (22.5595, 114.0510), (22.5592, 114.0490),
        ],
    },
    {
        "name": "塘朗山郊野径",
        "description": "塘朗山郊野径，爬升较大，沿途可俯瞰深圳市区，适合挑战型跑者",
        "distance": 10000, "elevation_gain": 350, "elevation_loss": 350,
        "difficulty": 3, "city": "深圳",
        "center": (22.5760, 114.0150),
        "points": [
            (22.5730, 114.0020), (22.5740, 114.0050), (22.5750, 114.0080),
            (22.5760, 114.0110), (22.5770, 114.0140), (22.5780, 114.0170),
            (22.5790, 114.0200), (22.5785, 114.0230), (22.5775, 114.0260),
            (22.5765, 114.0290),
        ],
    },
    {
        "name": "福田河绿道",
        "description": "福田河绿道贯穿市中心，沿途经过多个公园，风景优美",
        "distance": 8000, "elevation_gain": 20, "elevation_loss": 20,
        "difficulty": 1, "city": "深圳",
        "center": (22.5495, 114.0530),
        "points": [
            (22.5430, 114.0600), (22.5445, 114.0585), (22.5460, 114.0570),
            (22.5475, 114.0555), (22.5490, 114.0540), (22.5505, 114.0525),
            (22.5520, 114.0510), (22.5535, 114.0495), (22.5550, 114.0480),
            (22.5565, 114.0465),
        ],
    },
    {
        "name": "大沙河生态长廊",
        "description": "大沙河生态长廊，沿河跑道视野开阔，适合散步式慢跑",
        "distance": 6000, "elevation_gain": 8, "elevation_loss": 8,
        "difficulty": 1, "city": "深圳",
        "center": (22.5525, 113.9655),
        "points": [
            (22.5580, 113.9670), (22.5565, 113.9665), (22.5550, 113.9660),
            (22.5535, 113.9655), (22.5520, 113.9650), (22.5505, 113.9645),
            (22.5490, 113.9640), (22.5475, 113.9635),
        ],
    },
]

# ========== 测试用户 ==========
TEST_USERS = [
    {"phone": "13800000002", "nickname": "风行者",     "gender": 1, "height": 178, "weight": 72, "pace": 5.0,  "hr": 148, "cadence": 178},
    {"phone": "13800000003", "nickname": "南山小鹿",    "gender": 2, "height": 163, "weight": 52, "pace": 6.2,  "hr": 155, "cadence": 172},
    {"phone": "13800000004", "nickname": "夜跑达人",    "gender": 1, "height": 175, "weight": 68, "pace": 5.8,  "hr": 150, "cadence": 175},
    {"phone": "13800000005", "nickname": "步频高手",    "gender": 1, "height": 170, "weight": 65, "pace": 5.5,  "hr": 145, "cadence": 182},
    {"phone": "13800000006", "nickname": "健康跑者",    "gender": 2, "height": 165, "weight": 55, "pace": 7.0,  "hr": 140, "cadence": 168},
]


def gen_uuid():
    return str(uuid.uuid4())


def insert_users(cursor):
    """批量插入测试用户"""
    print("\n👤 创建测试用户...")
    user_map = {}
    for u in TEST_USERS:
        uid = gen_uuid()
        now = datetime.now() - timedelta(days=random.randint(10, 30))
        cursor.execute("""
            INSERT INTO users (id, phone, password_hash, nickname, gender, height, weight,
                               total_distance, total_runs, total_time, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 0, 0, 0, %s, %s)
        """, (uid, u["phone"], PASSWORD_HASH, u["nickname"],
              u["gender"], u["height"], u["weight"], now, now))
        user_map[u["nickname"]] = uid
        print(f"  ✅ {u['nickname']} ({u['phone']})")
    return user_map


def insert_routes(cursor, all_user_ids):
    """批量创建路线"""
    print("\n🗺️ 创建跑迹路线...")
    route_map = {}
    for rd in ROUTES_DATA:
        rid = gen_uuid()
        creator = random.choice(all_user_ids)
        start_lat, start_lng = rd["points"][0]
        center_lat, center_lng = rd["center"]
        now = datetime.now() - timedelta(days=random.randint(3, 10))
        cursor.execute("""
            INSERT INTO routes (id, creator_id, name, description, distance,
                                elevation_gain, elevation_loss, difficulty, popularity,
                                city, start_lat, start_lng, center_lat, center_lng,
                                is_public, status, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 0, %s, %s, %s, %s, %s, 1, 1, %s, %s)
        """, (rid, creator, rd["name"], rd["description"],
              rd["distance"], rd["elevation_gain"], rd["elevation_loss"],
              rd["difficulty"], rd["city"],
              start_lat, start_lng, center_lat, center_lng, now, now))
        route_map[rd["name"]] = {"id": rid, "data": rd}
        print(f"  ✅ {rd['name']} ({rd['distance']/1000:.0f}km, 难度{'★'*rd['difficulty']})")
    return route_map


def gen_gps_samples(route_points, total_seconds, sample_interval=5):
    """沿路线生成GPS采样点"""
    samples = []
    n_points = len(route_points)
    total_samples = total_seconds // sample_interval

    for i in range(total_samples):
        t = i / total_samples
        seg_idx = min(int(t * (n_points - 1)), n_points - 2)
        seg_t = (t * (n_points - 1)) - seg_idx

        lat = route_points[seg_idx][0] + (route_points[seg_idx + 1][0] - route_points[seg_idx][0]) * seg_t
        lng = route_points[seg_idx][1] + (route_points[seg_idx + 1][1] - route_points[seg_idx][1]) * seg_t

        # GPS漂移
        lat += random.uniform(-0.00004, 0.00004)
        lng += random.uniform(-0.00004, 0.00004)
        samples.append((round(lat, 7), round(lng, 7)))
    return samples


def insert_runs_and_samples(cursor, user_map, route_map):
    """为每个用户创建跑步记录+GPS采样"""
    print("\n🏃 生成跑步记录与GPS采样...")
    all_runs = []

    for nickname, uid in user_map.items():
        u = next(uu for uu in TEST_USERS if uu["nickname"] == nickname)
        base_pace = u["pace"]
        num_runs = random.randint(4, 7)

        for i in range(num_runs):
            route_name = random.choice(list(route_map.keys()))
            rinfo = route_map[route_name]
            rdata = rinfo["data"]
            rid = rinfo["id"]
            run_id = gen_uuid()

            # 跑步时长
            pace = base_pace + (rdata["difficulty"] - 2) * 0.3 + random.uniform(-0.3, 0.3)
            total_time_sec = int((rdata["distance"] / 1000) * pace * 60)
            total_time_sec = max(total_time_sec, 600)

            # 时间：过去1-15天
            days_ago = random.randint(1, 14)
            hour = random.choice([6, 7, 8, 17, 18, 19, 20, 21])
            start_time = datetime.now() - timedelta(days=days_ago, hours=24 - hour,
                                                     minutes=random.randint(0, 59))
            end_time = start_time + timedelta(seconds=total_time_sec)

            # 运动数据
            avg_hr = int(u["hr"] + random.gauss(0, 8))
            max_hr = avg_hr + random.randint(10, 25)
            avg_cadence = int(u["cadence"] + random.gauss(0, 5))
            max_cadence = avg_cadence + random.randint(5, 12)
            avg_stride = round(1000 / (pace * 60) * avg_cadence / 100, 2)
            best_pace = round(pace - random.uniform(0.2, 0.8), 2)
            calories = int((rdata["distance"] / 1000) * 65)
            weather = random.choice(["晴", "多云", "晴", "晴", "多云", "阴"])

            cursor.execute("""
                INSERT INTO runs (id, user_id, route_id, start_time, end_time, total_time,
                                  total_distance, avg_pace, best_pace,
                                  avg_heart_rate, max_heart_rate,
                                  avg_cadence, max_cadence, avg_stride_length,
                                  elevation_gain, elevation_loss, calories,
                                  weather, temperature, device_type,
                                  is_shared, share_count, like_count,
                                  created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s)
            """, (run_id, uid, rid,
                  start_time, end_time, total_time_sec,
                  rdata["distance"], round(pace, 2), best_pace,
                  avg_hr, max_hr, avg_cadence, max_cadence, avg_stride,
                  rdata["elevation_gain"], rdata["elevation_loss"], calories,
                  weather, random.randint(18, 28), "iPhone 16 Pro",
                  random.choice([0, 1]), random.randint(0, 20), random.randint(0, 15),
                  start_time, end_time))

            # GPS采样（每5秒一个点）
            samples = gen_gps_samples(rdata["points"], total_time_sec, 5)
            sample_rows = []
            for j, (lat, lng) in enumerate(samples):
                st = start_time + timedelta(seconds=j * 5)
                alt = round(10 + (j / len(samples)) * rdata["elevation_gain"] * 0.5, 1) if rdata["elevation_gain"] > 0 else 10
                hr_val = avg_hr + int(random.gauss(0, 8))
                cad_val = avg_cadence + int(random.gauss(0, 4))
                pace_instant = round(pace + random.gauss(0, 0.3), 2)
                dist = round(rdata["distance"] * (j / len(samples)), 2)

                sample_rows.append(
                    f"('{run_id}','{st.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]}',{lat},{lng},{alt},{pace_instant},{hr_val},{cad_val},{avg_stride},{dist})"
                )

            # 分批插入采样点
            batch_size = 500
            base_sql = """INSERT INTO run_samples (run_id, sample_time, latitude, longitude,
                                                    altitude, pace, heart_rate, cadence,
                                                    stride_length, distance_from_start) VALUES """
            for k in range(0, len(sample_rows), batch_size):
                batch = sample_rows[k:k + batch_size]
                cursor.execute(base_sql + ",".join(batch))

            all_runs.append({"run_id": run_id, "user_id": uid, "route_name": route_name})
            d = rdata["distance"] / 1000
            print(f"  ✅ {nickname} · {route_name} ({d:.0f}km @ {pace:.1f}min/km) [{len(samples)} GPS点]")

    return all_runs


def insert_friendships(cursor, user_map, existing_users):
    """建立好友关系（user_id_a < user_id_b）"""
    print("\n🤝 建立好友关系...")
    all_ids = list(user_map.values()) + list(existing_users.values())
    count = 0
    for i in range(len(all_ids)):
        for j in range(i + 1, len(all_ids)):
            if random.random() < 0.55:
                fid = gen_uuid()
                now = datetime.now() - timedelta(days=random.randint(3, 14))
                # 保证 user_id_a < user_id_b（满足 CHECK 约束）
                a, b = sorted([all_ids[i], all_ids[j]])
                cursor.execute("""
                    INSERT INTO friendships (id, user_id_a, user_id_b, status, created_at, updated_at)
                    VALUES (%s, %s, %s, 'accepted', %s, %s)
                """, (fid, a, b, now, now))
                count += 1
    print(f"  ✅ 已建立 {count} 对好友关系")


def insert_challenges(cursor, all_runs, all_user_ids, route_map):
    """创建挑战记录"""
    print("\n⚔️ 创建挑战记录...")
    ghost_modes = ["real_replay", "target_pace", "steady_pace", "rabbit", "tortoise_hare"]
    goal_metrics = ["avg_pace", "avg_cadence", "avg_heart_rate"]
    statuses = ["completed", "completed", "completed", "accepted"]
    count = 0
    for run in all_runs[:8]:
        opponent = random.choice([uid for uid in all_user_ids if uid != run["user_id"]])
        route_id = route_map[run["route_name"]]["id"]
        ghost_mode = random.choice(ghost_modes)
        goal = random.choice(goal_metrics)
        status = random.choice(statuses)

        cid = gen_uuid()
        now = datetime.now() - timedelta(days=random.randint(1, 5))
        completed_at = now if status == "completed" else None
        expires_at = now + timedelta(days=7)

        # 挑战者的跑步结果指标
        cursor.execute("SELECT total_time, avg_pace, avg_cadence, avg_heart_rate FROM runs WHERE id = %s", (run["run_id"],))
        rdata = cursor.fetchone()
        result_json = '{"total_time": %.0f, "avg_pace": %.2f}' % (rdata[0] if rdata else 0, rdata[1] if rdata else 0)

        cursor.execute("""
            INSERT INTO challenges (id, route_id, challenger_id, challenger_run_id,
                                    invitee_id, ghost_mode, goal_metric,
                                    challenger_result, status,
                                    created_at, completed_at, expires_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (cid, route_id, run["user_id"], run["run_id"],
              opponent, ghost_mode, goal,
              result_json, status, now, completed_at, expires_at))
        count += 1
    print(f"  ✅ {count} 条挑战记录")


def update_leaderboards(cursor, all_user_ids, route_map):
    """更新路线热度和排行榜"""
    print("\n📊 更新路线排行榜...")
    for route_name, rinfo in route_map.items():
        rid = rinfo["id"]

        # 统计热度
        cursor.execute("SELECT COUNT(*) FROM runs WHERE route_id = %s", (rid,))
        total = cursor.fetchone()[0]
        cursor.execute("UPDATE routes SET popularity = %s WHERE id = %s", (total, rid))

        # 排行榜（按总用时，取每个用户最佳成绩）
        cursor.execute("""
            SELECT r.user_id, r.total_time, r.avg_pace, r.id, r.start_time
            FROM runs r
            INNER JOIN (
                SELECT user_id, MIN(total_time) as best_time
                FROM runs WHERE route_id = %s GROUP BY user_id
            ) best ON r.user_id = best.user_id AND r.total_time = best.best_time
            WHERE r.route_id = %s
            ORDER BY r.total_time ASC LIMIT 10
        """, (rid, rid))
        for rank, row in enumerate(cursor.fetchall(), 1):
            lb_id = gen_uuid()
            try:
                cursor.execute("""
                    INSERT INTO route_leaderboards (id, route_id, user_id, run_id,
                                                    total_time, avg_pace, recorded_at,
                                                    created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, (lb_id, rid, row[0], row[3],
                      row[1], row[2], row[4]))
            except Exception as e:
                # 跳过重复键
                pass
        print(f"  ✅ {route_name}: {total} 次打卡, 排行榜已更新")


def main():
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()
    print("✅ 已连接 stridemoor 数据库")

    # 获取已有用户
    cursor.execute("SELECT id, nickname FROM users")
    existing_users = {row[1]: row[0] for row in cursor.fetchall()}
    print(f"📌 已有用户: {', '.join(existing_users.keys())}")

    # 1. 创建测试用户
    user_map = insert_users(cursor)
    conn.commit()

    # 合并用户ID列表
    all_user_ids = list(existing_users.values()) + list(user_map.values())

    # 2. 创建路线
    route_map = insert_routes(cursor, all_user_ids)
    conn.commit()

    # 3. 创建跑步记录 + GPS采样
    all_runs = insert_runs_and_samples(cursor, user_map, route_map)
    conn.commit()

    # 4. 建立好友关系
    insert_friendships(cursor, user_map, existing_users)
    conn.commit()

    # 5. 创建挑战
    insert_challenges(cursor, all_runs, all_user_ids, route_map)
    conn.commit()

    # 6. 更新排行榜
    update_leaderboards(cursor, all_user_ids, route_map)
    conn.commit()

    cursor.close()
    conn.close()

    print(f"\n{'='*50}")
    print(f"🎉 测试数据生成完成！")
    print(f"{'='*50}")
    print(f"👤 用户总计: {len(all_user_ids)} 位（新增 {len(user_map)} 位）")
    print(f"🗺️ 路线: {len(route_map)} 条")
    print(f"🏃 跑步记录: {len(all_runs)} 条（含完整GPS采样）")
    print(f"🤝 好友关系: 已建立")
    print(f"⚔️ 挑战记录: 已创建")
    print(f"📊 排行榜: 已更新")
    print(f"{'='*50}")
    print(f"\n📱 登录密码: {PASSWORD}")
    print(f"👥 新增测试账号: 13800000002 ~ 13800000006")
    print(f"   已有账号: 13800000001 (测试跑者), 13332995668 (东君), 13900000001 (测试跑者2)")


if __name__ == "__main__":
    main()
