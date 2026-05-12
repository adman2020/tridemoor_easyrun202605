#!/usr/bin/env python3
"""Generate realistic running records for each route, multiple users."""
import uuid, random, math, io, sys
from datetime import datetime, timedelta
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# All routes (name, id, dist_m, difficulty)
routes = [
    ("东湖公园绿道", "5c473ba3-e055-4d7d-aa26-a6515f2aaab9", 6720, 1),
    ("中心公园花径", "519ffc17-cf9b-434c-b496-b5b4f0e779bc", 2260, 1),
    ("人才公园海滨线", "4bf307ae-f4d4-4485-a433-b53ec6bb74bd", 6300, 1),
    ("人才公园环湖", "995aa063-40f0-4c8b-985f-823d708d46eb", 4537, 1),
    ("南山公园环山道", "62cce8c7-ece5-4d56-b1a7-338783422b96", 9470, 2),
    ("南山公园登顶路", "4e3137b5-d60f-4feb-99a2-e5a2f1e24375", 3460, 3),
    ("塘朗山越野跑", "f712c0ec-6af0-43b6-a056-3018c6bdb2c1", 8417, 3),
    ("塘朗山郊野径", "95c1e112-511c-4048-8856-9369360afebd", 12700, 3),
    ("大沙河生态长廊", "d590c5e5-f1e3-4e72-a8cf-c8ade4b83907", 19000, 1),
    ("大沙河生态长廊", "ee9ab030-977c-463f-93f0-2e2d823b0d60", 7400, 1),
    ("奥体中心绕圈", "9437791a-95cf-4b40-a291-f34a352a4f87", 3605, 1),
    ("景发小区800米路线", "a03bda63-3927-4e7e-938f-3772c28f4e4e", 807, 1),
    ("梅林水库绿道", "4a440fed-0ceb-4a4f-a0e1-324f48509148", 10445, 1),
    ("梧桐山绿道", "c2832561-5363-4849-bff2-4b5b79576a2c", 19300, 3),
    ("欢乐港湾-前海绿道", "3da7213f-475a-4f15-b14a-93f0121dc2c4", 7160, 1),
    ("洪湖公园晨跑", "68b1bd0b-5e85-4a02-a8b2-957453c5e46f", 12500, 1),
    ("深圳湾公园晨跑线", "86992120-3eec-4ce4-b44d-8da0c6691632", 3800, 1),
    ("深圳湾公园沿海跑道", "c3d5a64b-503e-401f-a068-c154aede5755", 5800, 1),
    ("环香蜜湖晨跑线路", "0dd1cb5e-ff40-4824-bf00-45941c50b81d", 5000, 2),
    ("盐田海滨栈道", "b3d17360-21b5-4366-bf80-8b77be911762", 15000, 1),
    ("福田CBD夜跑", "22ce365a-57b6-4a6b-b4ba-961c3ee8925c", 11200, 1),
    ("福田河绿道", "b5901b3c-5704-495d-a6da-b472f86001d3", 9800, 1),
    ("笔架山公园环山", "e3ba6405-0e30-4d1c-a801-b6e7f130f9a9", 5650, 2),
    ("荔枝公园环线", "ef056e1d-41a1-465e-afe4-ec48519b2a77", 10090, 1),
    ("莲花山公园绕湖", "d5c45106-da86-450c-ac37-169086dbf41b", 5880, 1),
    ("银湖山郊野径", "fa4f2f71-e158-49ba-8a0e-5c12828cdcf6", 10391, 3),
    ("香蜜公园夜跑", "843ebc2a-d6c2-4be9-8a75-8bbbd8935a11", 3500, 1),
    ("香蜜公园环湖", "b875099a-6606-4a00-af6a-f174dcafc331", 3537, 1),
]

# Users (pick 10 main runners, skip duplicates)
users = [
    ("acf32306-192a-4dfb-9416-3f32d60dd60e", "银月", 36, 70),    # pace=5:30, hr=155
    ("4019e9a3-2056-410e-8249-85b88d245062", "厉飞雨", 24, 68),  # faster: 4:30-5:30
    ("cc5d41e6-c681-4c05-aa6f-101ac071cd06", "啼魂", 48, 62),
    ("b8b387d9-4bfe-4de3-a441-e56a0e760224", "韩立", 36, 72),
    ("664cf4cc-ee65-44ff-8403-7c82c82e471b", "南宫婉", 40, 58),
    ("7862e67b-1e0f-428d-90b2-22df7c006d5e", "元瑶", 42, 55),
    ("eb577996-0b55-4bba-b9d4-82d5a20f3ccb", "向之礼", 34, 65),
    ("2d575e7d-5bd0-4abf-ad8f-17b09fba9b3f", "紫灵", 38, 60),
    ("a4eb8adb-d1de-4cc9-a9c8-4402e5869db1", "乾老魔", 44, 58),
    ("e12300e3-01c9-496b-902b-df5c86ffa37f", "温天仁", 30, 68),
    ("a7ba8ceb-7190-4ed2-936d-73f1a5b059c4", "墨彩环", 46, 55),
    ("11cef625-dd60-4659-ad0f-fa439eec909c", "金童", 28, 70),
    ("755c0403-9c89-436e-93c3-48a095232d9d", "陈巧倩", 50, 52),
    ("7565d507-ce60-430f-9fdf-bd72ced9115c", "冰凤", 32, 65),
    ("bfd2dac1-3787-41b7-838a-8a4834505a27", "黄枫谷", 38, 60),
    ("76702697-d684-4567-9207-a25a5bad0d10", "东君", 22, 72),
]

# Pace (seconds/km) based on difficulty and user base_pace
# base_pace[0] = pace_sec_per_km for flat, +30s for hill, +60s for mountain
def pace_sec(dist_m, difficulty, base_pace_sec):
    base = base_pace_sec
    if difficulty == 2: base += 20  # hill adds 20s/km
    if difficulty == 3: base += 40  # mountain adds 40s/km
    if dist_m > 10000: base += 10   # long run +10s
    if dist_m > 15000: base += 10   # very long +10s
    return base + random.randint(-10, 10)  # natural variation

def hr_avg(pace_sec, difficulty, age, hr_max_pct):
    # Estimate heart rate based on pace and age
    max_hr = 220 - age
    # Faster pace = higher HR (lower pace_sec = faster)
    # For a runner, pace_sec 300 = 5:00/km, 420 = 7:00/km
    effort = max(0.5, min(0.95, 1.0 - (pace_sec - 240) / 360))
    hr = int(max_hr * effort * (0.85 + hr_max_pct * 0.15))
    # Easy flat routes can have lower HR
    if difficulty == 1 and pace_sec > 360: hr -= 10
    return max(90, min(190, hr))

# Generate runs
random.seed(42)
sql_parts = []
sql_lines = [
    "-- Generated running records for route check-in & ranking demo",
    "SET NAMES utf8mb4;",
    f"-- Generated: 2026-05-08",
    ""
]

now = datetime.now()
run_id = 0

for rname, rid, dist_m, diff in routes:
    # Each route gets 1-2 runners
    num_runners = 1 if dist_m < 2000 else (2 if dist_m < 10000 else 3)
    chosen = random.sample(users, min(num_runners, len(users)))
    
    for uid, uname, age, hr_pct in chosen:
        run_id += 1
        rid_uuid = str(uuid.uuid4())
        
        # Random date in last 3 weeks, weighted toward recent
        days_ago = int(random.expovariate(1/7))  # avg ~7 days ago
        days_ago = min(days_ago, 21)  # max 21 days ago
        run_date = now - timedelta(days=days_ago)
        # Random time: 6:00-9:00 or 17:00-20:00 (typical running times)
        if random.random() < 0.7:
            hour = random.randint(6, 9)
        else:
            hour = random.randint(17, 20)
        minute = random.randint(0, 59)
        second = random.randint(0, 59)
        run_date = run_date.replace(hour=hour, minute=minute, second=second, microsecond=random.randint(0, 999000))
        start_time = run_date.strftime("%Y-%m-%d %H:%M:%S.") + f"{run_date.microsecond:06d}"
        
        # End time = start + pace * distance
        base_pace = random.randint(300, 420)  # 5:00 - 7:00 /km base
        pace = pace_sec(dist_m, diff, base_pace)
        total_time_secs = dist_m * pace / 1000
        end_time = run_date + timedelta(seconds=int(total_time_secs))
        end_str = end_time.strftime("%Y-%m-%d %H:%M:%S.") + f"{end_time.microsecond:06d}"
        
        # Heart rate
        hr = hr_avg(pace, diff, age, hr_pct/100)
        hr_min = hr - random.randint(10, 25)
        hr_max = hr + random.randint(10, 20)
        
        # Cadence (steps/min)
        cadence = random.randint(155, 185)
        cad_max = cadence + random.randint(5, 15)
        
        # Stride length (cm)
        stride = round(random.uniform(0.85, 1.25), 2)
        
        # Elevation
        if diff == 1:
            elev_gain = random.randint(5, 30)
            elev_loss = random.randint(5, 30)
        elif diff == 2:
            elev_gain = random.randint(50, 150)
            elev_loss = elev_gain + random.randint(-10, 10)
        else:
            elev_gain = random.randint(150, 500)
            elev_loss = elev_gain + random.randint(-20, 20)
        
        # Calories (rough: 0.7 * weight_kg * km)
        # But we don't have weight, use rough: 60 cal/km for flat, 80 for mountain
        cal_per_km = 55 if diff == 1 else (65 if diff == 2 else 80)
        cal = int(cal_per_km * dist_m / 1000 * random.uniform(0.9, 1.1))
        
        # Created_at slightly before start_time (import time)
        created = run_date - timedelta(minutes=random.randint(1, 30))
        created_str = created.strftime("%Y-%m-%d %H:%M:%S.") + f"{created.microsecond:06d}"
        
        # Weather
        weathers = ["晴", "多云", "阴", "晴", "晴", "多云"]
        weather = random.choice(weathers)
        temp = random.randint(18, 30)
        
        # Device
        devices = ["Huawei Watch GT 3", "Apple Watch S8", "Garmin Forerunner 255", 
                   "手机", "小米手环8", "Huawei Band 7"]
        device = random.choice(devices)
        
        sql_lines.append(f"INSERT INTO runs (id, user_id, route_id, start_time, end_time, total_time, total_distance, avg_pace, best_pace, avg_heart_rate, max_heart_rate, avg_cadence, max_cadence, avg_stride_length, elevation_gain, elevation_loss, calories, weather, temperature, device_type, is_shared, share_count, like_count, heat_count, created_at, updated_at) VALUES (")
        sql_lines.append(f"  '{rid_uuid}',")
        sql_lines.append(f"  '{uid}',")
        sql_lines.append(f"  '{rid}',")
        sql_lines.append(f"  '{start_time}',")
        sql_lines.append(f"  '{end_str}',")
        sql_lines.append(f"  {int(total_time_secs)},")
        sql_lines.append(f"  {dist_m},")
        sql_lines.append(f"  {pace},")
        sql_lines.append(f"  {max(pace - random.randint(15, 40), 240)},")  # best pace faster
        sql_lines.append(f"  {hr},")
        sql_lines.append(f"  {hr_max},")
        sql_lines.append(f"  {cadence},")
        sql_lines.append(f"  {cad_max},")
        sql_lines.append(f"  {stride},")
        sql_lines.append(f"  {elev_gain},")
        sql_lines.append(f"  {elev_loss},")
        sql_lines.append(f"  {cal},")
        sql_lines.append(f"  '{weather}',")
        sql_lines.append(f"  {temp},")
        sql_lines.append(f"  '{device}',")
        # Randomly share half the runs
        shared = 1 if random.random() < 0.5 else 0
        shares = random.randint(0, 5) if shared else 0
        likes = random.randint(0, 10) if shared else 0
        heat = likes + random.randint(0, 5)
        sql_lines.append(f"  {shared},")
        sql_lines.append(f"  {shares},")
        sql_lines.append(f"  {likes},")
        sql_lines.append(f"  {heat},")
        sql_lines.append(f"  '{created_str}',")
        sql_lines.append(f"  '{created_str}'")
        sql_lines.append(f");")
        
        # Add a route_points entry if we want to simulate GPS
        # (skip for now, just the run record)

sql_path = r"D:\AI\StrideMoor\seed_runs.sql"
with open(sql_path, "w", encoding="utf-8") as f:
    f.write("\n".join(sql_lines))
print(f"✅ Generated {run_id} runs across {len(routes)} routes")
print(f"   SQL written to {sql_path}")
