#!/usr/bin/env python3
"""Generate running records for ALL 33 routes using new + existing accounts."""
import uuid, random, io, sys
from datetime import datetime, timedelta
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

random.seed(20260508)

# ALL 33 routes
routes = [
    ("东湖公园绿道", "5c473ba3-e055-4d7d-aa26-a6515f2aaab9", 6720, 1),
    ("中心公园花径", "519ffc17-cf9b-434c-b496-b5b4f0e779bc", 2260, 1),
    ("人才公园海滨线", "4bf307ae-f4d4-4485-a433-b53ec6bb74bd", 6300, 1),
    ("人才公园环湖", "995aa063-40f0-4c8b-985f-823d708d46eb", 4537, 1),
    ("南山公园环山道", "62cce8c7-ece5-4d56-b1a7-338783422b96", 9470, 2),
    ("南山公园登顶路", "4e3137b5-d60f-4feb-99a2-e5a2f1e24375", 3460, 3),
    ("塘朗山越野跑", "f712c0ec-6af0-43b6-a056-3018c6bdb2c1", 8417, 3),
    ("塘朗山郊野径", "95c1e112-511c-4048-8856-9369360afebd", 12700, 3),
    ("大沙河生态长廊(19km)", "d590c5e5-f1e3-4e72-a8cf-c8ade4b83907", 19000, 1),
    ("大沙河生态长廊(7.4km)", "ee9ab030-977c-463f-93f0-2e2d823b0d60", 7400, 1),
    ("奥体中心绕圈", "9437791a-95cf-4b40-a291-f34a352a4f87", 3605, 1),
    ("景发小区800米路线", "a03bda63-3927-4e7e-938f-3772c28f4e4e", 807, 1),
    ("梅林水库绿道", "4a440fed-0ceb-4a4f-a0e1-324f48509148", 10445, 1),
    ("梧桐山绿道", "c2832561-5363-4849-bff2-4b5b79576a2c", 19300, 3),
    ("欢乐港湾-前海绿道", "3da7213f-475a-4f15-b14a-93f0121dc2c4", 7160, 1),
    ("洪湖公园晨跑", "68b1bd0b-5e85-4a02-a8b2-957453c5e46f", 12500, 1),
    ("深圳湾公园晨跑线", "86992120-3eec-4ce4-b44d-8da0c6691632", 3800, 1),
    ("深圳湾公园沿海跑道", "c3d5a64b-503e-401f-a068-c154aede5755", 5800, 1),
    ("环香蜜湖晨跑线路", "0dd1cb5e-ff40-4824-bf00-45941c50b81d", 5000, 2),
    ("环香蜜湖10公里路线", "34d9905f-77d2-4f2b-a9b6-01558381060d", 10258, 3),
    ("香蜜片区环线", "4146ca12-0de5-45c0-a6ac-8d9b7d86a17e", 10030, 3),
    ("盐田海滨栈道", "b3d17360-21b5-4366-bf80-8b77be911762", 15000, 1),
    ("福田CBD夜跑", "22ce365a-57b6-4a6b-b4ba-961c3ee8925c", 11200, 1),
    ("福田河绿道", "b5901b3c-5704-495d-a6da-b472f86001d3", 9800, 1),
    ("笔架山公园环山", "e3ba6405-0e30-4d1c-a801-b6e7f130f9a9", 5650, 2),
    ("荔枝公园环线", "ef056e1d-41a1-465e-afe4-ec48519b2a77", 10090, 1),
    ("莲花山公园绕湖", "d5c45106-da86-450c-ac37-169086dbf41b", 5880, 1),
    ("银湖山郊野径", "fa4f2f71-e158-49ba-8a0e-5c12828cdcf6", 10391, 3),
    ("香蜜公园夜跑", "843ebc2a-d6c2-4be9-8a75-8bbbd8935a11", 3500, 1),
    ("香蜜公园环湖", "b875099a-6606-4a00-af6a-f174dcafc331", 3537, 1),
    ("莲花山公园绕湖", "d5c45106-da86-450c-ac37-169086dbf41b", 5880, 1),
    ("马鹿山公园跑步线路", "06ed948b-039c-4ca2-a3c2-8eacc1b01416", 11310, 3),
    ("沿涓江往返10公里线路", "43e8a5a7-4cd4-499e-8f81-487eb124deb8", 10045, 3),
    ("湖湘公园线路", "7a39af60-32ea-4073-8754-eb5150900b86", 10109, 3),
]

# New accounts (15) + existing regular accounts (4)
new_users = [
    ("a0000001-0000-0000-0000-000000000001", "罗峰", 35, 65),
    ("a0000001-0000-0000-0000-000000000002", "洪", 42, 60),
    ("a0000001-0000-0000-0000-000000000003", "雷沉", 28, 70),
    ("a0000001-0000-0000-0000-000000000004", "徐欣", 33, 58),
    ("a0000001-0000-0000-0000-000000000005", "陈谷", 45, 55),
    ("a0000001-0000-0000-0000-000000000006", "野人", 38, 72),
    ("a0000001-0000-0000-0000-000000000007", "李耀", 36, 62),
    ("a0000001-0000-0000-0000-000000000008", "维妮娜", 30, 55),
    ("a0000001-0000-0000-0000-000000000009", "朱喜", 40, 58),
    ("a0000001-0000-0000-0000-000000000010", "赵若", 29, 60),
    ("a0000001-0000-0000-0000-000000000011", "杨武", 44, 56),
    ("a0000001-0000-0000-0000-000000000012", "白凤", 32, 62),
    ("a0000001-0000-0000-0000-000000000013", "贾斯丁", 26, 68),
    ("a0000001-0000-0000-0000-000000000014", "李耀辰", 34, 61),
    ("a0000001-0000-0000-0000-000000000015", "武极", 48, 58),
]
# Reuse some original seed users too
existing_users = [
    ("7862e67b-1e0f-428d-90b2-22df7c006d5e", "元瑶", 42, 55),
    ("a7ba8ceb-7190-4ed2-936d-73f1a5b059c4", "墨彩环", 46, 55),
    ("260e08a3-71a2-4c0e-8460-a76036cad4aa", "李化元", 38, 58),
    ("0f53bebe-0f0e-4396-a5a7-fc5053b3787a", "朝阳跑者陈哥", 35, 60),
    ("75c523bf-7f3f-4873-a59b-df8339812f1f", "福田跑团小美", 28, 55),
    ("c023fb36-98cc-4f6d-afaa-ac0cdd8b6c5e", "跑友小张", 33, 58),
]
all_users = new_users + existing_users

now = datetime.now()

def gen_run(rname, rid, dist_m, diff, uid, uname, age, hr_pct, days_ago_range=(1, 30)):
    rid_uuid = str(uuid.uuid4())
    days_ago = random.randint(days_ago_range[0], days_ago_range[1])
    run_date = now - timedelta(days=days_ago)
    
    if random.random() < 0.7:
        hour = random.randint(6, 9)
    else:
        hour = random.randint(17, 20)
    minute = random.randint(0, 59)
    second = random.randint(0, 59)
    run_date = run_date.replace(hour=hour, minute=minute, second=second, microsecond=random.randint(0, 999000))
    start_time = run_date.strftime("%Y-%m-%d %H:%M:%S.") + f"{run_date.microsecond:06d}"
    
    # Pace based on difficulty and age
    base_pace = random.randint(300, 420)
    if diff == 2: base_pace += 20
    if diff == 3: base_pace += 35
    if dist_m > 12000: base_pace += 10
    pace = base_pace + random.randint(-10, 10)
    
    total_time_secs = int(dist_m * pace / 1000)
    end_time = run_date + timedelta(seconds=total_time_secs)
    end_str = end_time.strftime("%Y-%m-%d %H:%M:%S.") + f"{end_time.microsecond:06d}"
    
    # Heart rate
    max_hr = 220 - age
    effort = max(0.5, min(0.95, 1.0 - (pace - 240) / 360))
    hr = int(max_hr * effort * (0.85 + hr_pct * 0.15 / 100))
    if diff == 1 and pace > 360: hr -= 10
    hr = max(90, min(190, hr))
    hr_min = hr - random.randint(10, 25)
    hr_max = hr + random.randint(10, 20)
    
    cadence = random.randint(155, 185)
    cad_max = cadence + random.randint(5, 15)
    stride = round(random.uniform(0.85, 1.25), 2)
    
    if diff == 1:
        elev_gain = random.randint(3, 25)
        elev_loss = random.randint(3, 25)
    elif diff == 2:
        elev_gain = random.randint(40, 120)
        elev_loss = elev_gain + random.randint(-10, 10)
    else:
        elev_gain = random.randint(120, 400)
        elev_loss = elev_gain + random.randint(-20, 20)
    
    cal_per_km = 55 if diff == 1 else (65 if diff == 2 else 80)
    cal = int(cal_per_km * dist_m / 1000 * random.uniform(0.9, 1.1))
    
    created = run_date - timedelta(minutes=random.randint(1, 30))
    created_str = created.strftime("%Y-%m-%d %H:%M:%S.") + f"{created.microsecond:06d}"
    
    weathers = ["晴", "多云", "晴", "多云", "阴"]
    weather = random.choice(weathers)
    temp = random.randint(18, 30)
    devices = ["Huawei Watch GT 3", "Garmin Forerunner 255", "Apple Watch S8", "手机", "小米手环8"]
    device = random.choice(devices)
    
    shared = 1 if random.random() < 0.6 else 0
    shares = random.randint(0, 5) if shared else 0
    likes = random.randint(0, 10) if shared else 0
    heat = likes + random.randint(0, 5)
    
    line = (
        f"INSERT INTO runs (id, user_id, route_id, start_time, end_time, total_time, total_distance, avg_pace, best_pace, "
        f"avg_heart_rate, max_heart_rate, avg_cadence, max_cadence, avg_stride_length, elevation_gain, elevation_loss, "
        f"calories, weather, temperature, device_type, is_shared, share_count, like_count, heat_count, created_at, updated_at) VALUES"
        f"('{rid_uuid}','{uid}','{rid}','{start_time}','{end_str}',{total_time_secs},{dist_m},{pace},{max(pace-random.randint(15,40),240)},"
        f"{hr},{hr_max},{cadence},{cad_max},{stride},{elev_gain},{elev_loss},{cal},'{weather}',{temp},'{device}',"
        f"{shared},{shares},{likes},{heat},'{created_str}','{created_str}');"
    )
    return line

# Generate: each route gets 1-4 runs from unique users
run_count = 0
sql_lines = [f"-- All 33 routes batch2 - {now.strftime('%Y-%m-%d %H:%M')}", "SET NAMES utf8mb4;", ""]

used_pairs = set()  # (route_id, user_id) to avoid duplicates per route

for rname, rid, dist_m, diff in routes:
    # Skip duplicates
    key = (rid, rname)
    
    if "莲花山公园绕湖" in rname:
        # Skip second occurrence since we already got one
        if (rid, "莲花山公园绕湖") in used_pairs:
            continue
    used_pairs.add(key)
    
    # New users get 1-2 routes each, for full coverage
    if dist_m < 2000:
        # Short routes: 1-2 runners
        runners = random.sample(all_users, min(2, len(all_users)))
    elif dist_m < 10000:
        runners = random.sample(all_users, min(3, len(all_users)))
    else:
        runners = random.sample(all_users, min(4, len(all_users)))
    
    for uid, uname, age, hr_pct in runners:
        run_count += 1
        # More recent for easier routes, spread out for harder
        days_range = (1, 14) if diff <= 2 else (3, 25)
        sql_lines.append(gen_run(rname, rid, dist_m, diff, uid, uname, age, hr_pct, days_range))

sql_path = r"D:\AI\StrideMoor\seed_runs_batch2.sql"
with open(sql_path, "w", encoding="utf-8") as f:
    f.write("\n".join(sql_lines))

print(f"Generated {run_count} runs covering {len(routes)} routes")
print(f"SQL: {sql_path}")
