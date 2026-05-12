#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
驰陌 StrideMoor 测试数据生成器 v4 -- 全面补全版

在 v3 基础上补充:
  - posts      跑友动态表(引用 runs)
  - post_comments  动态评论
  - post_likes     动态点赞
  - run_splits     跑步分段数据
  - comparisons    挑战对比数据

用法:
  python generate_test_data_v4.py          # 默认追加
  python generate_test_data_v4.py --clean  # 清空以上表后重建
"""

import uuid, random, sys, json, mysql.connector
from datetime import datetime, timedelta

DB = dict(host="127.0.0.1", port=3308, user="root",
          password="stridemoor_root_2026", database="stridemoor")
NOW = datetime.now()

# ====================================================================
# 修仙跑者的人设和文案风格
# ====================================================================
POST_STYLES = {
    "韩立": {
        "style": "沉稳低调,如常平淡叙述",
        "phrases": [
            "今日修炼结束,丹田微热,步履沉稳。{},小有所成。",
            "修炼之道,贵在持之以恒。今日{},道友共勉。",
            "凡人之躯,亦可登天。今日{},离大道更近一步。",
            "不骄不躁,一步一个脚印。{},心无旁骛。",
            "天南散修,不求闻达,只问道心。{}。",
        ]
    },
    "银月": {
        "style": "灵性优雅,带狼族特色",
        "phrases": [
            "银月之下,踏风而行。{},正好。",
            "灵界银狼,不争朝夕,只求自在。{},心旷神怡。",
            "月华流转,脚步轻盈。{},如沐春风。",
            "今日的灵气特别充沛,{},感觉能跑到天亮。",
            "狼的耐力是刻在骨子里的,{},慢慢来。",
        ]
    },
    "南宫婉": {
        "style": "清冷优雅,如月宫仙子",
        "phrases": [
            "掩月宗心法讲求呼吸韵律,今日{},气定神闲。",
            "月色如此,不跑可惜。{},灵台清明。",
            "修炼如饮茶,急不得。{},正好体悟天道。",
            "脚步是我的琴弦,{},便是今日的奏鸣曲。",
            "掩月心法第三层,贵在持久。{},不负月色。",
        ]
    },
    "厉飞雨": {
        "style": "热血豪爽,追求速度",
        "phrases": [
            "疾风知劲草!今日{},快意恩仇!",
            "跑得越快,烦恼追不上我!{},痛快!",
            "天下武功,唯快不破。{},还有谁!",
            "今日状态爆棚!{},感觉能破宗门记录!",
            "要么不跑,要么跑个痛快!{},这就是我的道!",
        ]
    },
    "元瑶": {
        "style": "灵动飘逸,如仙如幻",
        "phrases": [
            "灵界仙子,不染尘埃。{},身轻如燕。",
            "步伐即是舞步,{},自在逍遥。",
            "天地为舞台,{},便是今日的一支舞。",
            "顺其自然,随缘而行。{},一切刚好。",
            "灵气绕身,{},仿佛下一刻就要飞升。",
        ]
    },
    "紫灵": {
        "style": "精准控速,音律之道",
        "phrases": [
            "妙音门外门弟子,每一步都是音律。{},节奏正好。",
            "配速如同音准,{},不多不少刚刚好。",
            "把跑步当成弹琴,{},指尖生花。",
            "心中有谱,脚下有拍。{},今日演奏完毕。",
            "音律之道贵在精准,{},不差分毫。",
        ]
    },
    "向之礼": {
        "style": "悠哉养生,佛系慢跑",
        "phrases": [
            "年纪大了,不跟年轻人拼速度。{},养身第一。",
            "跑得慢才能跑得远,{},乐在其中。",
            "天南老怪的生活哲学:能跑就行。{},舒服!",
            "不比配速,不比距离,{},开心就好。",
            "养生跑,保命跑,{},慢悠悠才是真谛。",
        ]
    },
    "李化元": {
        "style": "稳重扎实,宗门风范",
        "phrases": [
            "黄枫谷修炼法则:基本功最重要。{},稳扎稳打。",
            "为师者当以身作则,今日{},弟子们看好了。",
            "修炼没有捷径,{},方为正道。",
            "大道至简,{},便是今日功课。",
            "黄枫谷绝学:匀速往返跑。{},朴实无华。",
        ]
    },
    "墨彩环": {
        "style": "轻松随性,重在体验",
        "phrases": [
            "墨府千金,重在体验而非成绩。{},开心就好。",
            "今日天气正好,{},不负好时光。",
            "跑步是为了更好地吃!{},然后去觅食。",
            "打卡!{},又是美好的一天。",
            "不追求什么,{},快乐跑步。",
        ]
    },
    "陈巧倩": {
        "style": "励志向上,稳步提升",
        "phrases": [
            "黄枫谷弟子,每天进步一点点。{},又比昨天强了!",
            "勤能补拙,{},坚持才是王道。",
            "今天的汗水是明天的基石。{},继续加油!",
            "从三公里到五公里,{},每一步都算数。",
            "不要跟别人比,跟昨天的自己比。{},进步了!",
        ]
    },
    "金童": {
        "style": "短小精悍,爆发力强",
        "phrases": [
            "我是短距离之王!{},爆发力拉满!",
            "小身材大能量!{},步频拉到飞起!",
            "噬金虫就是效率的化身!{},又快又狠!",
            "一步顶别人两步!{},这就是天赋!",
            "短平快,我的节奏!{},太爽了!",
        ]
    },
    "啼魂": {
        "style": "耐力怪物,持续输出",
        "phrases": [
            "上古魂兽之力,无穷无尽。{},我还行!",
            "耐力是我的招牌,{},只是热身而已。",
            "魂兽奔跑不知疲倦,{},再来十公里!",
            "越跑越精神的体质,{},根本停不下来。",
            '我的字典里没有「停下来」三个字。{},继续!',
        ]
    },
    "冰凤": {
        "style": "清冽冷静,节奏稳定",
        "phrases": [
            "天冰灵凤,心如止水。{},呼吸如冰泉。",
            "冷靜,是奔跑的秘訣。{},節奏不亂。",
            "冰鳳血脈,耐力綿長。{},穩如磐石。",
            "不為外物所動,{},心如寒冰。",
            "清冽的節奏,{},正是冰鳳的風格。",
        ]
    },
    "乾老魔": {
        "style": "后程发力,越跑越猛",
        "phrases": [
            "前面让你们嚣张,后面看我表演!{},魔威滔天!",
            "越跑越狠,越跑越狂!{},这就是魔道!",
            "前慢后快是策略,{},让你们见识下真本事!",
            "魔道巨擘,后发制人。{},一鸣惊人!",
            "热身完毕,现在才开始!{},魔焰滔天!",
        ]
    },
    "温天仁": {
        "style": "均衡发展,无懈可击",
        "phrases": [
            "天道门讲究均衡之道。{},没有短板。",
            "速度与耐力兼修,{},才是天道门的真传。",
            "不偏科的天才,{},全方位碾压。",
            "完美的配速,完美的步频,{},天道如此。",
            "均衡即王道,{},无懈可击的一天。",
        ]
    },
    "黄枫谷": {
        "style": "团队协作,稳定输出",
        "phrases": [
            "黄枫谷合称,今天也是团队跑!{},不离不弃!",
            "一个人可以跑得很快,但一群人跑得更远。{},团队万岁!",
            "黄枫谷跑团日常:{},全員完賽!",
            "团队的力量,{},互相带节奏。",
            "黄枫谷合称出战!{},整齐划一!",
        ]
    },
    "东君": {
        "style": "大气从容,道法自然",
        "phrases": [
            "东君驾临,{},今日修炼完成。",
            "大道自然,{},天地同频。",
            "日月为伴,{},气贯长虹。",
            "朝阳初升,{},新的一天从跑步开始。",
            "不求速度,不争长短,{},道法自然。",
        ]
    }
}

# 默认文案(用于未定义的角色)
DEFAULT_PHRASES = [
    "今日打卡,{},跑完收工!",
    "坚持跑步第{}天,感觉自己又强了!",
    "跑步治愈一切,{},心情舒畅!",
    "日常跑一跑,{},身心愉悦!",
    "今日份跑步打卡!{},又是元气满满的一天!",
]

# 评论模板
COMMENT_BANK = [
    "厉害!这配速我望尘莫及",
    "太强了道友!一起加油",
    "这条路我也跑过,风景确实好",
    "今天状态不错啊,下次约跑",
    "这个距离可以的,坚持就是胜利",
    "修仙跑步两不误,道友真乃时间管理大师",
    "不错不错,建议配速再稳一点",
    "这个心率很舒服,养生跑法",
    "步频控制得很好,高手",
    "深圳这个天气还能跑这么远,佩服",
    "路线很赞,求分享GPS轨迹",
    "带我一起跑啊!",
    "这配速......大佬受我一拜",
    "凡人修仙传跑团欢迎你",
    "早上跑还是晚上跑的?想跟你同路线",
    "打卡机报到!今日份的羡慕已送达",
    "请问这是什么路线?看起来很漂亮",
    "稳定输出,月度跑量又要破纪录了",
    "支持!每天进步一点点",
    "膝盖还疼吗?注意休息恢复",
    "下次跑梧桐山叫我!",
    "深圳湾公园确实是跑步圣地",
    "这步频,专业的啊",
    "银狼血脉果然名不虚传",
    "厉飞雨道友一如既往地快",
]

# 回复模板(嵌套在评论中)
REPLY_BANK = [
    "谢谢道友!继续努力",
    "哈哈哈下次一起",
    "对,早上六点跑的,空气好",
    "没问题,回头分享轨迹",
    "膝盖好多了,谢谢关心",
    "梧桐山一起搞起!",
    "道友过奖了,还差得远",
    "必须的,团队力量大",
    "嗯嗯,坚持就是胜利",
    "节奏还得再找找,今天状态一般",
]


def gen_uid():
    return str(uuid.uuid4())


def create_missing_tables(c):
    """创建可能缺失的表(posts, post_comments, post_likes)"""
    tables = [
        ("""
        CREATE TABLE IF NOT EXISTS `posts` (
            `id` CHAR(36) PRIMARY KEY COMMENT 'UUID',
            `user_id` CHAR(36) NOT NULL COMMENT '用户ID',
            `run_id` CHAR(36) COMMENT '关联跑步记录ID',
            `route_id` CHAR(36) COMMENT '关联路线ID',
            `content` TEXT NOT NULL COMMENT '动态内容',
            `created_at` DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
            INDEX `idx_post_user` (`user_id`),
            INDEX `idx_post_run` (`run_id`),
            INDEX `idx_post_route` (`route_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='跑友动态表';
        """),
        ("""
        CREATE TABLE IF NOT EXISTS `post_comments` (
            `id` CHAR(36) PRIMARY KEY COMMENT 'UUID',
            `post_id` CHAR(36) NOT NULL COMMENT '动态ID',
            `user_id` CHAR(36) NOT NULL COMMENT '评论用户ID',
            `content` TEXT NOT NULL COMMENT '评论内容',
            `created_at` DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
            INDEX `idx_comment_post` (`post_id`),
            INDEX `idx_comment_user` (`user_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='动态评论表';
        """),
        ("""
        CREATE TABLE IF NOT EXISTS `post_likes` (
            `post_id` CHAR(36) NOT NULL COMMENT '动态ID',
            `user_id` CHAR(36) NOT NULL COMMENT '点赞用户ID',
            `created_at` DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
            PRIMARY KEY (`post_id`, `user_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='动态点赞表';
        """),
    ]
    for sql in tables:
        try:
            c.execute(sql)
        except mysql.connector.Error as e:
            # 如果表已存在就忽略
            if "already exists" not in str(e):
                raise e
    print("  ✅ 缺失的表已创建")


def clean_social_tables(c):
    """清空社交相关表"""
    tables = ["post_likes", "post_comments", "posts", "run_splits", "comparisons"]
    c.execute("SET FOREIGN_KEY_CHECKS = 0")
    for t in tables:
        c.execute(f"DELETE FROM {t}")
    c.execute("SET FOREIGN_KEY_CHECKS = 1")
    print("  ✅ 旧社交数据已清空")


def get_user_map(c):
    """获取所有用户映射 {nickname: (uid, gender, height, weight)}"""
    c.execute("SELECT id, nickname, gender, height, weight FROM users")
    users = {}
    for row in c.fetchall():
        users[row[1]] = row  # (id, nickname, gender, height, weight)
    print(f"  ✅ 读取 {len(users)} 位用户")
    return users


def get_route_map(c):
    """获取路线映射 {route_id: name}"""
    c.execute("SELECT id, name FROM routes")
    routes = {}
    for row in c.fetchall():
        routes[row[0]] = row[1]
    print(f"  ✅ 读取 {len(routes)} 条路线")
    return routes


def get_shared_runs(c):
    """获取已共享的跑步记录"""
    c.execute("""
        SELECT r.id, r.user_id, r.route_id, r.total_distance, r.avg_pace,
               r.total_time, r.start_time, r.is_shared, u.nickname
        FROM runs r
        JOIN users u ON r.user_id = u.id
        WHERE r.is_shared = 1
        ORDER BY r.start_time DESC
    """)
    runs = c.fetchall()
    print(f"  ✅ 读取 {len(runs)} 条共享跑步记录")
    return runs


def generate_run_pace_description(pace, distance, nickname):
    """根据配速和距离生成描述文字"""
    dist_km = distance / 1000 if distance else 0
    if pace:
        if pace < 4.5:
            pace_tag = "飞一样的速度"
        elif pace < 5.0:
            pace_tag = "高手配速"
        elif pace < 5.5:
            pace_tag = "稳扎稳打"
        elif pace < 6.0:
            pace_tag = "舒适节奏"
        else:
            pace_tag = "养生慢跑"

        total_min = int(dist_km * pace) if dist_km else 0
        main_stat = f"{dist_km:.1f}公里 @ {pace:.1f}配速,用时{total_min}分钟"
    else:
        pace_tag = ""
        main_stat = f"{dist_km:.1f}公里"

    return main_stat, pace_tag


def generate_posts(c, users, routes_map, shared_runs):
    """为共享的跑步记录生成跑友动态"""
    print("\n📝 生成跑友动态 (posts)...")

    all_uids = {uid: nick for uid, nick in
                [(u[0], u[1]) for u in users.values()]}

    # 按用户分组跑步记录,每个人最多5条动态(一天一条)
    user_runs = {}
    for run in shared_runs:
        rid, uid, route_id, dist, pace, total_time, start_time, is_shared, nick = run
        if uid not in user_runs:
            user_runs[uid] = []
        user_runs[uid].append(run)

    posts_created = 0
    post_records = []

    for uid, runs in user_runs.items():
        nick = all_uids.get(uid, "未知")
        style = POST_STYLES.get(nick, {"style": "普通", "phrases": DEFAULT_PHRASES})
        phrases = style["phrases"]

        for idx, run in enumerate(runs[:5]):  # 每人最多5条
            rid, _, route_id, dist, pace, total_time, start_time, is_shared, _ = run
            dist_km = dist / 1000 if dist else 0

            # 生成描述
            main_stat, pace_tag = generate_run_pace_description(pace, dist, nick)
            route_name = routes_map.get(route_id, "未知路线")
            phrase = phrases[idx % len(phrases)]

            if pace_tag:
                content = phrase.format(f"{route_name} · {main_stat} · {pace_tag}")
            else:
                content = phrase.format(f"{route_name} · {main_stat}")

            post_id = gen_uid()
            c.execute("""
                INSERT INTO posts (id, user_id, run_id, route_id, content, created_at)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (post_id, uid, rid, route_id, content,
                  start_time + timedelta(minutes=1)))

            post_records.append({
                "post_id": post_id,
                "user_id": uid,
                "run_id": rid,
                "nickname": nick,
            })
            posts_created += 1

    print(f"  ✅ 生成 {posts_created} 条动态")
    return post_records


def generate_likes(c, post_records, all_uids):
    """生成动态点赞"""
    print("\n❤️ 生成动态点赞 (post_likes)...")

    like_count = 0
    for post in post_records:
        # 每条动态3-12个点赞
        other_users = [uid for uid in all_uids if uid != post["user_id"]]
        likers = random.sample(other_users, min(random.randint(3, 12), len(other_users)))

        for liker_uid in likers:
            try:
                ts = NOW - timedelta(hours=random.randint(1, 48))
                c.execute("""
                    INSERT IGNORE INTO post_likes (post_id, user_id, created_at)
                    VALUES (%s, %s, %s)
                """, (post["post_id"], liker_uid, ts))
                like_count += 1
            except:
                pass

    print(f"  ✅ 生成 {like_count} 个点赞")


def generate_comments(c, post_records, all_uids, nicknames):
    """生成动态评论"""
    print("\n💬 生成动态评论 (post_comments)...")

    comment_count = 0
    for post in post_records:
        # 每条动态2-6条评论
        others = [uid for uid in all_uids if uid != post["user_id"]]
        if len(others) < 1:
            continue

        num_comments = random.randint(2, 6)
        commenters = random.sample(others, min(num_comments, len(others)))

        for commenter in commenters:
            content = random.choice(COMMENT_BANK)
            comment_id = gen_uid()
            ts = NOW - timedelta(hours=random.randint(1, 48))

            c.execute("""
                INSERT INTO post_comments (id, post_id, user_id, content, created_at)
                VALUES (%s, %s, %s, %s, %s)
            """, (comment_id, post["post_id"], commenter, content, ts))
            comment_count += 1

            # 30%概率有回复(原作者回复)
            if random.random() < 0.3:
                reply_content = random.choice(REPLY_BANK)
                reply_id = gen_uid()
                reply_ts = ts + timedelta(minutes=random.randint(5, 120))
                c.execute("""
                    INSERT INTO post_comments (id, post_id, user_id, content, created_at)
                    VALUES (%s, %s, %s, %s, %s)
                """, (reply_id, post["post_id"], post["user_id"], reply_content, reply_ts))
                comment_count += 1

    print(f"  ✅ 生成 {comment_count} 条评论")


def generate_run_splits(c):
    """为所有没有分段的跑步记录生成分段数据"""
    print("\n📊 生成跑步分段数据 (run_splits)...")

    # 获取没有分段的跑步记录
    c.execute("""
        SELECT r.id, r.total_distance, r.total_time, r.avg_pace,
               r.avg_heart_rate, r.avg_cadence, r.avg_stride_length,
               r.elevation_gain
        FROM runs r
        LEFT JOIN run_splits s ON r.id = s.run_id
        WHERE s.run_id IS NULL
    """)
    runs_no_splits = c.fetchall()
    print(f"  ✅ 发现 {len(runs_no_splits)} 条跑步记录需要生成分段数据")

    if not runs_no_splits:
        print("  i️  所有跑步记录已有分段数据,跳过")
        return

    split_count = 0
    for run in runs_no_splits:
        rid, total_dist, total_time, avg_pace, avg_hr, avg_cad, avg_stride, elev_gain = run

        if not total_dist or not total_time:
            continue

        # mysql.connector returns Decimal for DECIMAL columns, convert to float
        total_dist = float(total_dist) if total_dist else 0
        total_time = int(total_time) if total_time else 0
        avg_pace = float(avg_pace) if avg_pace else None
        avg_hr = int(avg_hr) if avg_hr else None
        avg_cad = int(avg_cad) if avg_cad else None
        avg_stride = float(avg_stride) if avg_stride else None
        elev_gain = float(elev_gain) if elev_gain else 0

        dist_km = total_dist / 1000
        num_splits = max(1, int(dist_km))

        for i in range(num_splits):
            split_sec = int(total_time / num_splits) if num_splits > 0 else 0
            split_dist = total_dist / num_splits if num_splits > 0 else total_dist
            split_pace = round(avg_pace + random.gauss(0, 0.15), 2) if avg_pace else None
            split_hr = int(avg_hr + random.gauss(0, 3)) if avg_hr else None
            split_cad = int(avg_cad + random.gauss(0, 2)) if avg_cad else None
            split_stride = round(avg_stride + random.gauss(0, 0.02), 2) if avg_stride else None
            split_elev = elev_gain / num_splits if elev_gain else 0

            split_id = gen_uid()
            c.execute("""
                INSERT INTO run_splits (id, run_id, split_index, distance, time,
                    pace, avg_heart_rate, avg_cadence, avg_stride_length,
                    elevation_gain, elevation_loss, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
            """, (split_id, rid, i, round(split_dist, 2), split_sec,
                  split_pace, split_hr, split_cad, split_stride,
                  round(split_elev, 2), round(split_elev * 0.8, 2)))
            split_count += 1

    print(f"  ✅ 生成 {split_count} 条分段数据")


def generate_comparisons(c):
    """为已完成的挑战生成对比数据（使用该用户的其他跑步记录作为对比基准）"""
    print("\n⚖️ 生成挑战对比数据 (comparisons)...")

    # 获取已完成的挑战 + 挑战者的其他跑步记录
    c.execute("""
        SELECT ch.id, ch.challenger_run_id, ch.challenger_id,
               r1.total_distance as dist1, r1.total_time as time1, r1.avg_pace as pace1,
               r1.avg_heart_rate as hr1, r1.avg_cadence as cad1,
               r1.avg_stride_length as stride1, r1.elevation_gain as elev1
        FROM challenges ch
        JOIN runs r1 ON ch.challenger_run_id = r1.id
        WHERE ch.status = 'completed'
        AND ch.id NOT IN (SELECT challenge_id FROM comparisons WHERE challenge_id IS NOT NULL)
    """)
    challenges = c.fetchall()
    print(f"  ✅ 发现 {len(challenges)} 个已完成挑战（待生成对比）")

    comparison_count = 0
    for ch in challenges:
        cid, run_a, challenger_id, dist1, time1, pace1, hr1, cad1, stride1, elev1 = ch
        # Convert Decimal to native Python types
        dist1 = float(dist1) if dist1 else 0
        time1 = int(time1) if time1 else 0
        pace1 = float(pace1) if pace1 else None
        hr1 = int(hr1) if hr1 else None
        cad1 = int(cad1) if cad1 else None
        stride1 = float(stride1) if stride1 else None
        elev1 = float(elev1) if elev1 else 0

        # 找挑战者的其他跑步记录作为对比（run_b）
        c.execute("""
            SELECT id, total_time, avg_pace, avg_heart_rate, avg_cadence
            FROM runs WHERE user_id = %s AND id != %s
            ORDER BY start_time DESC LIMIT 1
        """, (challenger_id, run_a))
        other_run = c.fetchone()
        if not other_run:
            continue

        run_b_id = other_run[0]
        old_time1 = int(other_run[1]) if other_run[1] else time1
        old_pace1 = float(other_run[2]) if other_run[2] else pace1
        old_hr1 = int(other_run[3]) if other_run[3] else (hr1 or 0)
        old_cad1 = int(other_run[4]) if other_run[4] else (cad1 or 0)

        # 创建对比 JSON
        def compare_val(a, b, higher_better=False):
            if a is None or b is None:
                return "—"
            if higher_better:
                return f"{'↑' if a > b else '↓'} (+{abs(a-b):.0f})" if a != b else "="
            else:
                return f"{'↑' if a > b else '↓'} ({'+' if a > b else ''}{round(a-b, 2) if isinstance(a, float) else a-b})" if a != b else "="

        overall_diff = {
            "total_time": {"a": time1, "b": old_time1,
                           "diff": compare_val(time1, old_time1)},
            "avg_pace": {"a": pace1, "b": old_pace1,
                         "diff": compare_val(pace1, old_pace1)},
            "avg_heart_rate": {"a": hr1, "b": old_hr1,
                               "diff": compare_val(hr1, old_hr1)},
            "avg_cadence": {"a": cad1, "b": old_cad1,
                            "diff": compare_val(cad1, old_cad1)},
        }

        overall_json = json.dumps(overall_diff, ensure_ascii=False)

        comp_id = gen_uid()
        try:
            c.execute("""
                INSERT INTO comparisons (id, challenge_id, run_a_id, run_b_id,
                    overall_diff, created_at)
                VALUES (%s, %s, %s, %s, %s, NOW())
            """, (comp_id, cid, run_a, run_b_id, overall_json))
            comparison_count += 1
        except mysql.connector.Error as e:
            print(f"  ⚠️  对比插入失败: {e}")

    print(f"  ✅ 生成 {comparison_count} 条对比数据")


def main():
    conn = mysql.connector.connect(**DB)
    c = conn.cursor()
    print("✅ 已连接 stridemoor 数据库")

    # 1. 确保表存在
    create_missing_tables(c)
    conn.commit()

    # 2. 获取现有数据
    users = get_user_map(c)
    routes_map = get_route_map(c)
    shared_runs = get_shared_runs(c)

    all_uids = [u[0] for u in users.values()]
    nicknames = {u[0]: u[1] for u in users.values()}

    # 3. 生成 posts
    post_records = generate_posts(c, users, routes_map, shared_runs)
    conn.commit()

    # 4. 生成 likes
    generate_likes(c, post_records, all_uids)
    conn.commit()

    # 5. 生成 comments
    generate_comments(c, post_records, all_uids, nicknames)
    conn.commit()

    # 6. 生成 run_splits
    generate_run_splits(c)
    conn.commit()

    # 7. 生成 comparisons
    generate_comparisons(c)
    conn.commit()

    # 统计结果
    print(f"\n{'='*55}")
    print(f"📊 最终统计")
    print(f"{'='*55}")
    stats = [
        ("posts 动态", "SELECT COUNT(*) FROM posts"),
        ("post_comments 评论", "SELECT COUNT(*) FROM post_comments"),
        ("post_likes 点赞", "SELECT COUNT(*) FROM post_likes"),
        ("run_splits 分段数据", "SELECT COUNT(*) FROM run_splits"),
        ("comparisons 对比数据", "SELECT COUNT(*) FROM comparisons"),
    ]
    for label, sql in stats:
        c.execute(sql)
        print(f"  {label}: {c.fetchone()[0]}")

    print(f"\n{'='*55}")
    print(f"🎉 v4 测试数据补全完成!")
    print(f"{'='*55}")
    print(f"📱 登录手机号: 13800000101 ~ 13800000116")
    print(f"📱 东君: 13332995668")
    print(f"🔑 密码: 123456")
    print(f"{'='*55}")

    c.close()
    conn.close()


if __name__ == "__main__":
    main()
