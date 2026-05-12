#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
驰陌 StrideMoor 测试数据生成器 v3 —— 全面重置版

【凡人修仙传人物 + 16条深圳经典跑步路线 + 完整GPS轨迹】

策略：清空旧数据 → 创建新数据
"""

import uuid, random, math, bcrypt, sys
import mysql.connector
from datetime import datetime, timedelta

DB = dict(host="127.0.0.1", port=3308, user="root",
          password="stridemoor_root_2026", database="stridemoor")
PWD = "123456"
PWD_HASH = bcrypt.hashpw(PWD.encode(), bcrypt.gensalt(10)).decode()
NOW = datetime.now()

# ====================================================================
# 凡人修仙传 · 16 位角色
# ====================================================================
CHARS = [
    # (phone, nickname, gender, height, weight, base_pace, hr, cadence, persona)
    ("13800000101", "韩立",     1, 175, 68, 4.8,  148, 180, "天南第一散修，步法沉稳，耐力惊人"),
    ("13800000102", "南宫婉",   2, 168, 54, 5.6,  152, 176, "掩月宗圣女，步伐轻盈，气息悠长"),
    ("13800000103", "元瑶",     2, 165, 52, 6.0,  150, 174, "灵界仙子，身法飘逸，节奏感极佳"),
    ("13800000104", "紫灵",     2, 166, 53, 5.8,  155, 172, "妙音门少主，步频精准，控速如音律"),
    ("13800000105", "银月",     2, 167, 55, 5.5,  146, 178, "灵界银狼，持久力惊人，配速稳定"),
    ("13800000106", "向之礼",   1, 172, 65, 6.2,  140, 170, "天南老怪，悠哉慢跑，养生派"),
    ("13800000107", "李化元",   1, 178, 72, 5.2,  150, 176, "黄枫谷掌门，基本功扎实，稳扎稳打"),
    ("13800000108", "厉飞雨",   1, 180, 70, 4.5,  155, 185, "疾风剑客，爆发力强，短距离王者"),
    ("13800000109", "墨彩环",   2, 163, 50, 6.5,  145, 170, "墨府千金，轻松跑为主，重体验"),
    ("13800000110", "陈巧倩",   2, 164, 51, 6.3,  148, 173, "黄枫谷弟子，匀速跑法，稳步提升"),
    ("13800000111", "金童",     1, 170, 63, 4.8,  155, 185, "噬金虫化身，短步高频，爆发强"),
    ("13800000112", "啼魂",     1, 176, 70, 5.0,  150, 178, "上古魂兽，耐力无穷，长途制霸"),
    ("13800000113", "冰凤",     2, 169, 56, 5.7,  148, 175, "天冰灵凤，节奏如冰泉，清冽稳定"),
    ("13800000114", "乾老魔",   1, 174, 69, 5.4,  152, 175, "魔道巨擘，越跑越猛，后程发力"),
    ("13800000115", "温天仁",   1, 177, 71, 5.1,  150, 177, "天道门天才，均衡发展，无短板"),
    ("13800000116", "黄枫谷",   1, 173, 66, 5.9,  147, 174, "黄枫谷合称，团队跑者，稳定输出"),
]

# ====================================================================
# 16 条深圳经典跑步路线（坐标来自实地/高德/百度地图）
# ====================================================================
ROUTES = [
    {
        "name": "深圳湾公园沿海跑道",
        "desc": "深圳湾公园沿海步道，平坦开阔，面朝大海，适合晨跑和夜跑",
        "dist": 5000, "elev_gain": 10, "elev_loss": 10,
        "diff": 1, "city": "南山",
        "center": (22.5236, 113.9630),
        "points": [
            (22.5221,113.9520),(22.5213,113.9545),(22.5208,113.9570),
            (22.5202,113.9595),(22.5197,113.9620),(22.5192,113.9645),
            (22.5187,113.9670),(22.5182,113.9695),(22.5175,113.9720),
            (22.5168,113.9745),(22.5160,113.9770),
        ],
    },
    {
        "name": "南山公园环山道",
        "desc": "南山公园环山路线，有坡度变化，适合进阶跑者练习爬坡",
        "dist": 7000, "elev_gain": 180, "elev_loss": 180,
        "diff": 2, "city": "南山",
        "center": (22.5340, 113.9440),
        "points": [
            (22.5350,113.9300),(22.5345,113.9330),(22.5342,113.9360),
            (22.5338,113.9390),(22.5340,113.9420),(22.5343,113.9450),
            (22.5348,113.9480),(22.5350,113.9510),(22.5345,113.9540),
            (22.5340,113.9570),
        ],
    },
    {
        "name": "莲花山公园绕湖",
        "desc": "莲花山公园绕湖跑道，绿树成荫，邓小平像下是经典起点",
        "dist": 3000, "elev_gain": 15, "elev_loss": 15,
        "diff": 1, "city": "福田",
        "center": (22.5592, 114.0530),
        "points": [
            (22.5590,114.0490),(22.5588,114.0510),(22.5585,114.0530),
            (22.5588,114.0550),(22.5592,114.0570),(22.5595,114.0550),
            (22.5598,114.0530),(22.5595,114.0510),(22.5592,114.0490),
        ],
    },
    {
        "name": "塘朗山郊野径",
        "desc": "塘朗山郊野径，爬升大，可俯瞰深圳市区全貌，挑战型跑者必跑",
        "dist": 10000, "elev_gain": 350, "elev_loss": 350,
        "diff": 3, "city": "南山",
        "center": (22.5760, 114.0150),
        "points": [
            (22.5730,114.0020),(22.5740,114.0050),(22.5750,114.0080),
            (22.5760,114.0110),(22.5770,114.0140),(22.5780,114.0170),
            (22.5790,114.0200),(22.5785,114.0230),(22.5775,114.0260),
            (22.5765,114.0290),
        ],
    },
    {
        "name": "福田河绿道",
        "desc": "福田河绿道贯穿市中心，经过笔架山、中心公园，市区跑者最爱",
        "dist": 8000, "elev_gain": 20, "elev_loss": 20,
        "diff": 1, "city": "福田",
        "center": (22.5495, 114.0530),
        "points": [
            (22.5430,114.0600),(22.5445,114.0585),(22.5460,114.0570),
            (22.5475,114.0555),(22.5490,114.0540),(22.5505,114.0525),
            (22.5520,114.0510),(22.5535,114.0495),(22.5550,114.0480),
            (22.5565,114.0465),
        ],
    },
    {
        "name": "大沙河生态长廊",
        "desc": "深圳版塞纳河，从大学城到深圳湾，绿道全程沿河，风景优美",
        "dist": 6000, "elev_gain": 8, "elev_loss": 8,
        "diff": 1, "city": "南山",
        "center": (22.5525, 113.9655),
        "points": [
            (22.5580,113.9670),(22.5565,113.9665),(22.5550,113.9660),
            (22.5535,113.9655),(22.5520,113.9650),(22.5505,113.9645),
            (22.5490,113.9640),(22.5475,113.9635),
        ],
    },
    {
        "name": "香蜜公园环湖",
        "desc": "香蜜公园环境优雅，环湖跑道平坦舒适，福田区跑者必打卡",
        "dist": 2500, "elev_gain": 5, "elev_loss": 5,
        "diff": 1, "city": "福田",
        "center": (22.5490, 114.0300),
        "points": [
            (22.5485,114.0280),(22.5488,114.0295),(22.5492,114.0305),
            (22.5496,114.0315),(22.5498,114.0325),(22.5495,114.0330),
            (22.5490,114.0325),(22.5487,114.0310),(22.5485,114.0295),
            (22.5485,114.0280),
        ],
    },
    {
        "name": "笔架山公园环山",
        "desc": "笔架山三峰并立，环山跑道起伏有致，深圳跑团经典拉练路线",
        "dist": 5500, "elev_gain": 120, "elev_loss": 120,
        "diff": 2, "city": "福田",
        "center": (22.5650, 114.0800),
        "points": [
            (22.5630,114.0770),(22.5640,114.0785),(22.5650,114.0800),
            (22.5660,114.0815),(22.5670,114.0830),(22.5675,114.0845),
            (22.5670,114.0855),(22.5660,114.0840),(22.5650,114.0825),
            (22.5640,114.0805),(22.5630,114.0785),
        ],
    },
    {
        "name": "梧桐山绿道",
        "desc": "梧桐山深圳第一峰，绿道沿山而上，考验跑者综合实力的经典路线",
        "dist": 15000, "elev_gain": 500, "elev_loss": 500,
        "diff": 3, "city": "罗湖",
        "center": (22.5800, 114.2200),
        "points": [
            (22.5700,114.2100),(22.5720,114.2130),(22.5745,114.2155),
            (22.5770,114.2180),(22.5795,114.2205),(22.5810,114.2230),
            (22.5825,114.2255),(22.5835,114.2280),(22.5830,114.2305),
            (22.5820,114.2320),(22.5805,114.2300),(22.5790,114.2275),
            (22.5775,114.2250),(22.5760,114.2225),(22.5745,114.2200),
            (22.5730,114.2170),(22.5715,114.2140),(22.5700,114.2115),
        ],
    },
    {
        "name": "深圳中心公园绿道",
        "desc": "市中心难得的绿洲，从笔架山到滨河大道，穿越城市森林",
        "dist": 4000, "elev_gain": 8, "elev_loss": 8,
        "diff": 1, "city": "福田",
        "center": (22.5450, 114.0700),
        "points": [
            (22.5480,114.0690),(22.5470,114.0695),(22.5460,114.0700),
            (22.5450,114.0705),(22.5440,114.0705),(22.5430,114.0700),
            (22.5420,114.0695),(22.5410,114.0690),
        ],
    },
    {
        "name": "银湖山郊野径",
        "desc": "银湖山山林小道，越野跑者天堂，碎石路+树根路考验脚踝力量",
        "dist": 12000, "elev_gain": 280, "elev_loss": 280,
        "diff": 3, "city": "罗湖",
        "center": (22.5900, 114.0900),
        "points": [
            (22.5850,114.0850),(22.5865,114.0870),(22.5880,114.0890),
            (22.5895,114.0910),(22.5910,114.0930),(22.5925,114.0950),
            (22.5935,114.0970),(22.5940,114.0990),(22.5935,114.1010),
            (22.5925,114.0995),(22.5915,114.0975),(22.5900,114.0955),
            (22.5885,114.0935),(22.5870,114.0915),(22.5860,114.0895),
            (22.5850,114.0870),
        ],
    },
    {
        "name": "梅林水库绿道",
        "desc": "梅林水库旁文艺小清新绿道，石板路依山傍水，适合慢跑恢复",
        "dist": 8000, "elev_gain": 60, "elev_loss": 60,
        "diff": 1, "city": "福田",
        "center": (22.5700, 114.0450),
        "points": [
            (22.5670,114.0400),(22.5680,114.0420),(22.5690,114.0440),
            (22.5700,114.0460),(22.5710,114.0480),(22.5720,114.0500),
            (22.5730,114.0485),(22.5725,114.0465),(22.5715,114.0445),
            (22.5705,114.0425),(22.5695,114.0410),
        ],
    },
    {
        "name": "人才公园环湖",
        "desc": "深圳人才公园环湖塑胶跑道，后海CBD夜景尽收眼底，科技感十足",
        "dist": 2500, "elev_gain": 5, "elev_loss": 5,
        "diff": 1, "city": "南山",
        "center": (22.5300, 113.9400),
        "points": [
            (22.5295,113.9380),(22.5298,113.9395),(22.5305,113.9405),
            (22.5310,113.9415),(22.5315,113.9425),(22.5312,113.9435),
            (22.5305,113.9425),(22.5300,113.9410),(22.5295,113.9395),
        ],
    },
    {
        "name": "东湖公园绿道",
        "desc": "东湖公园环湖+林间道，罗湖区跑者的大本营，清晨鸟语花香",
        "dist": 5000, "elev_gain": 25, "elev_loss": 25,
        "diff": 1, "city": "罗湖",
        "center": (22.5600, 114.1400),
        "points": [
            (22.5580,114.1370),(22.5585,114.1390),(22.5590,114.1405),
            (22.5595,114.1420),(22.5605,114.1430),(22.5615,114.1435),
            (22.5620,114.1420),(22.5615,114.1400),(22.5605,114.1385),
            (22.5595,114.1375),
        ],
    },
    {
        "name": "盐田海滨栈道",
        "desc": "世界最长海滨栈道，从沙头角到大梅沙，海景无敌，跑者天堂",
        "dist": 12000, "elev_gain": 30, "elev_loss": 30,
        "diff": 1, "city": "盐田",
        "center": (22.5500, 114.2600),
        "points": [
            (22.5400,114.2300),(22.5420,114.2340),(22.5440,114.2380),
            (22.5460,114.2420),(22.5480,114.2460),(22.5500,114.2500),
            (22.5520,114.2540),(22.5540,114.2580),(22.5560,114.2620),
            (22.5580,114.2660),(22.5600,114.2700),(22.5620,114.2740),
            (22.5640,114.2780),(22.5650,114.2800),
        ],
    },
    {
        "name": "欢乐港湾-前海绿道",
        "desc": "欢乐港湾摩天轮下沿海跑道，前海新晋网红跑线，夜景璀璨",
        "dist": 7000, "elev_gain": 10, "elev_loss": 10,
        "diff": 1, "city": "宝安",
        "center": (22.5350, 113.8900),
        "points": [
            (22.5300,113.8820),(22.5310,113.8845),(22.5320,113.8870),
            (22.5330,113.8895),(22.5340,113.8920),(22.5350,113.8945),
            (22.5360,113.8970),(22.5370,113.8995),(22.5380,113.8970),
            (22.5370,113.8945),(22.5360,113.8920),(22.5350,113.8895),
            (22.5340,113.8870),(22.5330,113.8845),
        ],
    },
]


def gen_uid():
    return str(uuid.uuid4())

def clean_all(c):
    """清空所有表数据"""
    tables = ["route_leaderboards","run_samples","challenges","runs","routes","friendships","users"]
    c.execute("SET FOREIGN_KEY_CHECKS = 0")
    for t in tables:
        c.execute(f"DELETE FROM {t}")
    c.execute("SET FOREIGN_KEY_CHECKS = 1")
    print("  ✅ 旧数据已清空")

def insert_users(c):
    """插入凡人修仙传角色"""
    print("\n👤 创建 16 位凡人修仙传角色...")
    uids = {}
    for phone, nick, g, h, w, pace, hr, cad, _ in CHARS:
        _uid = gen_uid()
        ts = NOW - timedelta(days=random.randint(15, 40))
        c.execute("""INSERT INTO users (id,phone,password_hash,nickname,gender,height,weight,
            total_distance,total_runs,total_time,created_at,updated_at)
            VALUES (%s,%s,%s,%s,%s,%s,%s,0,0,0,%s,%s)""",
            (_uid, phone, PWD_HASH, nick, g, h, w, ts, ts))
        uids[nick] = _uid
        print(f"  ✅ {nick} ({phone})")
    return uids

def add_dongjun(c):
    """保留东君用户"""
    c.execute("SELECT id FROM users WHERE phone='13332995668'")
    row = c.fetchone()
    if row:
        print("  ✅ 东君 (已有)")
        return row[0]
    _uid = gen_uid()
    ts = NOW - timedelta(days=30)
    c.execute("""INSERT INTO users (id,phone,password_hash,nickname,gender,height,weight,
        total_distance,total_runs,total_time,created_at,updated_at)
        VALUES (%s,%s,%s,%s,%s,%s,%s,0,0,0,%s,%s)""",
        (_uid, "13332995668", PWD_HASH, "东君", 1, 175, 68, ts, ts))
    print("  ✅ 东君 (新创建)")
    return _uid

def insert_routes(c, all_uids):
    """创建16条路线"""
    print("\n🗺️ 创建 16 条深圳经典跑步路线...")
    rmap = {}
    for rd in ROUTES:
        rid = gen_uid()
        creator = random.choice(all_uids)
        slat, slng = rd["points"][0]
        clat, clng = rd["center"]
        ts = NOW - timedelta(days=random.randint(5, 20))
        c.execute("""INSERT INTO routes (id,creator_id,name,description,distance,
            elevation_gain,elevation_loss,difficulty,popularity,city,
            start_lat,start_lng,center_lat,center_lng,
            is_public,status,created_at,updated_at)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,0,%s,%s,%s,%s,%s,1,1,%s,%s)""",
            (rid, creator, rd["name"], rd["desc"], rd["dist"],
             rd["elev_gain"], rd["elev_loss"], rd["diff"], rd["city"],
             slat, slng, clat, clng, ts, ts))
        rmap[rd["name"]] = dict(id=rid, data=rd)
        stars = "★" * rd["diff"]
        print(f"  ✅ {rd['name']} ({rd['dist']/1000:.0f}km/{stars}/{rd['city']})")
    return rmap

def gen_gps(pts, total_sec, interval=5):
    """沿路线生成GPS点"""
    n = len(pts)
    total = total_sec // interval
    out = []
    for i in range(total):
        t = i / total
        si = min(int(t * (n - 1)), n - 2)
        st = (t * (n - 1)) - si
        lat = pts[si][0] + (pts[si+1][0] - pts[si][0]) * st + random.uniform(-3e-5, 3e-5)
        lng = pts[si][1] + (pts[si+1][1] - pts[si][1]) * st + random.uniform(-3e-5, 3e-5)
        out.append((round(lat, 7), round(lng, 7)))
    return out

def insert_runs(c, user_map, route_map):
    """每个用户跑多条路线"""
    print("\n🏃 生成跑步记录（含GPS轨迹）...")
    nicknames = list(user_map.keys())
    char_info = {c[1]: c for c in CHARS}
    runs_out = []

    for nick, user_uid in user_map.items():
        # CHARS tuple: (phone,nick,gender,height,weight,pace,hr,cad,persona)
        info = char_info.get(nick, ("", "", 1, 170, 65, 5.5, 148, 175, ""))
        base_pace = info[5] if len(info) > 5 else 5.5
        base_hr = info[6] if len(info) > 6 else 148
        base_cad = info[7] if len(info) > 7 else 175

        # 每人跑4~6条路线
        chosen = random.sample(list(route_map.keys()), min(random.randint(4, 6), len(route_map)))
        for rname in chosen:
            rd = route_map[rname]["data"]
            rid = route_map[rname]["id"]
            run_id = gen_uid()
            pace = base_pace + (rd["diff"] - 2) * 0.25 + random.uniform(-0.25, 0.25)
            pace = max(pace, 3.5)
            run_sec = int((rd["dist"] / 1000) * pace * 60)

            days_ago = random.randint(1, 12)
            hour = random.choice([6,7,8,17,18,19,20,21])
            start = NOW - timedelta(days=days_ago, hours=24-hour, minutes=random.randint(0,59))
            end = start + timedelta(seconds=run_sec)

            avg_hr = int(base_hr + random.gauss(0, 6))
            avg_cad = int(base_cad + random.gauss(0, 4))
            best_pace = round(pace - random.uniform(0.2, 0.8), 2)
            avg_stride = round(1000 / (pace * 60) * avg_cad / 100, 2)
            calories = int((rd["dist"] / 1000) * 65)
            weather = random.choice(["晴","多云","晴","晴","多云"])

            c.execute("""INSERT INTO runs (id,user_id,route_id,start_time,end_time,total_time,
                total_distance,avg_pace,best_pace,avg_heart_rate,max_heart_rate,
                avg_cadence,max_cadence,avg_stride_length,elevation_gain,elevation_loss,
                calories,weather,temperature,device_type,is_shared,share_count,like_count,created_at,updated_at)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                (run_id, user_uid, rid, start, end, run_sec,
                 rd["dist"], round(pace, 2), best_pace, avg_hr, avg_hr + random.randint(8, 20),
                 avg_cad, avg_cad + random.randint(5, 10), avg_stride,
                 rd["elev_gain"], rd["elev_loss"], calories,
                 weather, random.randint(18, 28), "iPhone 16 Pro",
                 random.randint(0, 1), random.randint(0, 25), random.randint(0, 18),
                 start, end))

            # GPS采样
            samples = gen_gps(rd["points"], run_sec, 5)
            batch_sql = """INSERT INTO run_samples (run_id,sample_time,latitude,longitude,
                altitude,pace,heart_rate,cadence,stride_length,distance_from_start) VALUES """
            rows = []
            for j, (lat, lng) in enumerate(samples):
                st = start + timedelta(seconds=j * 5)
                alt = 10 + (j / len(samples)) * rd["elev_gain"] * 0.5
                hr_v = avg_hr + int(random.gauss(0, 7))
                cad_v = avg_cad + int(random.gauss(0, 3))
                p_inst = round(pace + random.gauss(0, 0.25), 2)
                dist_pct = round(rd["dist"] * (j / len(samples)), 2)
                rows.append(
                    f"('{run_id}','{st.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]}',"
                    f"{lat},{lng},{alt:.1f},{p_inst},{hr_v},{cad_v},{avg_stride},{dist_pct})"
                )
            for k in range(0, len(rows), 500):
                c.execute(batch_sql + ",".join(rows[k:k+500]))

            runs_out.append(dict(run_id=run_id, user_id=user_uid, route_name=rname))
            print(f"  ✅ {nick} · {rd['name']} ({rd['dist']/1000:.0f}km @ {pace:.1f}) [{len(samples)} GPS点]")
    return runs_out

def insert_friendships(c, all_uids):
    """好友关系"""
    print("\n🤝 建立好友关系...")
    cnt = 0
    for i in range(len(all_uids)):
        for j in range(i+1, len(all_uids)):
            if random.random() < 0.5:
                fid = gen_uid()
                a, b = sorted([all_uids[i], all_uids[j]])
                c.execute("""INSERT INTO friendships (id,user_id_a,user_id_b,status,created_at,updated_at)
                    VALUES (%s,%s,%s,'accepted',%s,%s)""",
                    (fid, a, b, NOW - timedelta(days=random.randint(3, 14)), NOW))
                cnt += 1
    print(f"  ✅ {cnt} 对好友关系")

def insert_challenges(c, all_runs, all_uids, rmap):
    """挑战记录"""
    print("\n⚔️ 创建挑战记录...")
    ghosts = ["real_replay","target_pace","steady_pace","rabbit"]
    goals = ["avg_pace","avg_cadence","avg_heart_rate"]
    cnt = 0
    selected = random.sample(all_runs, min(15, len(all_runs)))
    for run in selected:
        opp = random.choice([u for u in all_uids if u != run["user_id"]])
        rid = rmap[run["route_name"]]["id"]
        cid = gen_uid()
        ghost = random.choice(ghosts)
        goal = random.choice(goals)
        ts = NOW - timedelta(days=random.randint(1, 6))

        c.execute("SELECT total_time, avg_pace FROM runs WHERE id=%s", (run["run_id"],))
        rrow = c.fetchone()
        result = '{"total_time":%.0f,"avg_pace":%.2f}' % (rrow[0] if rrow else 0, rrow[1] if rrow else 0)

        # 75%已完成
        completed = ts if random.random() < 0.75 else None
        expires = NOW + timedelta(days=7)
        status = "completed" if completed else "accepted"

        c.execute("""INSERT INTO challenges (id,route_id,challenger_id,challenger_run_id,
            invitee_id,ghost_mode,goal_metric,challenger_result,status,
            created_at,completed_at,expires_at)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
            (cid, rid, run["user_id"], run["run_id"], opp,
             ghost, goal, result, status, ts, completed, expires))
        cnt += 1
    print(f"  ✅ {cnt} 条挑战记录")

def update_leaderboards(c, route_map):
    """排行榜"""
    print("\n📊 更新路线排行榜...")
    for rname, rinfo in route_map.items():
        rid = rinfo["id"]
        c.execute("SELECT COUNT(*) FROM runs WHERE route_id=%s", (rid,))
        total = c.fetchone()[0]
        c.execute("UPDATE routes SET popularity=%s WHERE id=%s", (total, rid))

        c.execute("""SELECT r.user_id,r.total_time,r.avg_pace,r.id,r.start_time
            FROM runs r INNER JOIN (SELECT user_id,MIN(total_time) bt FROM runs WHERE route_id=%s GROUP BY user_id) best
            ON r.user_id=best.user_id AND r.total_time=best.bt
            WHERE r.route_id=%s ORDER BY r.total_time LIMIT 10""", (rid, rid))
        for row in c.fetchall():
            lb_id = gen_uid()
            try:
                c.execute("""INSERT INTO route_leaderboards (id,route_id,user_id,run_id,total_time,avg_pace,recorded_at,created_at,updated_at)
                    VALUES (%s,%s,%s,%s,%s,%s,%s,NOW(),NOW())""",
                    (lb_id, rid, row[0], row[3], row[1], row[2], row[4]))
            except:
                pass
        print(f"  ✅ {rname}: {total} 次打卡")


def main():
    conn = mysql.connector.connect(**DB)
    c = conn.cursor()
    print("✅ 已连接 stridemoor 数据库")

    clean_all(c)
    conn.commit()

    # 1. 创建凡人修仙传用户
    user_map = insert_users(c)
    conn.commit()

    # 2. 添加东君
    dj_id = add_dongjun(c)
    conn.commit()
    user_map["东君"] = dj_id

    all_uids = list(user_map.values())
    print(f"\n📌 共 {len(all_uids)} 位用户")

    # 3. 创建路线
    route_map = insert_routes(c, all_uids)
    conn.commit()

    # 4. 跑步记录 + GPS
    all_runs = insert_runs(c, user_map, route_map)
    conn.commit()

    # 5. 好友
    insert_friendships(c, all_uids)
    conn.commit()

    # 6. 挑战
    insert_challenges(c, all_runs, all_uids, route_map)
    conn.commit()

    # 7. 排行榜
    update_leaderboards(c, route_map)
    conn.commit()

    c.close()
    conn.close()

    # 统计
    conn2 = mysql.connector.connect(**DB)
    c2 = conn2.cursor()
    for q, label in [
        ("SELECT COUNT(*) FROM users", "用户"),
        ("SELECT COUNT(*) FROM routes", "路线"),
        ("SELECT COUNT(*) FROM runs", "跑步记录"),
        ("SELECT COUNT(*) FROM run_samples", "GPS采样点"),
        ("SELECT COUNT(*) FROM friendships WHERE status='accepted'", "好友关系"),
        ("SELECT COUNT(*) FROM challenges", "挑战"),
    ]:
        c2.execute(q)
        print(f"  {label}: {c2.fetchone()[0]}")
    c2.close()
    conn2.close()

    print(f"\n{'='*55}")
    print(f"🎉 测试数据生成完成！")
    print(f"{'='*55}")
    print(f"👥 角色: 凡人修仙传 16 人 + 东君")
    print(f"🗺️ 路线: 16 条深圳经典线路")
    print(f"📱 密码: {PWD}")
    print(f"📞 测试号: 13800000101 ~ 13800000116")
    print(f"{'='*55}")


if __name__ == "__main__":
    main()
