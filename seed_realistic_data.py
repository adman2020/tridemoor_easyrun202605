#!/usr/bin/env python3
"""Seed realistic route data for StrideMoor"""
import requests, json, time

BASE = "http://localhost:8080/api/v1"

def login(phone, pwd):
    r = requests.post(f"{BASE}/auth/login", json={"phone": phone, "password": pwd})
    return r.json()["data"]["tokens"]["access_token"]

# ====== User tokens ======
t1 = login("13800000001", "test123456")  # 东君
t2 = login("13800000002", "test123456")  # 跑友小张

# New users registered above, let's get their tokens
t3 = login("13800000003", "test123456")  # 朝阳跑者陈哥
t4 = login("13800000004", "test123456")  # 南山阿杰
t5 = login("13800000005", "test123456")  # 福田跑团小美
print("All 5 users logged in")

users = {1: t1, 2: t2, 3: t3, 4: t4, 5: t5}

# ====== Create realistic routes for each user ======

# User 1 东君 - already has 3 routes (深湾晨跑, 莲花山环湖, 塘朗山越野)
# Let's add more with richer point data

routes_data = [
    # User 3 陈哥 - 2 routes
    {
        "token": t3,
        "routes": [
            {
                "name": "奥体中心绕圈",
                "description": "深圳大运中心体育场绕圈跑，标准400m跑道，适合间歇训练",
                "distance": 5000, "elevation_gain": 5, "difficulty": 1,
                "tags": ["操场", "绕圈", "训练"],
                "city": "深圳", "start_lat": 22.694, "start_lng": 114.212,
                "center_lat": 22.696, "center_lng": 114.215,
                "points": [{"latitude":22.694+(i*0.0003), "longitude":114.212+(j*0.0003), "altitude":10+i%3}
                          for i,(j) in enumerate([0,1,0,-1]*15)][:60]
            },
            {
                "name": "洪湖公园晨跑",
                "description": "罗湖洪湖公园环湖路线，荷花季节景色优美，清晨人少适合拉练",
                "distance": 3200, "elevation_gain": 8, "difficulty": 1,
                "tags": ["公园", "环湖", "罗湖"],
                "city": "深圳", "start_lat": 22.572, "start_lng": 114.123,
                "center_lat": 22.574, "center_lng": 114.126,
                "points": [{"latitude":22.572+0.002*i, "longitude":114.123+0.002*j, "altitude":8}
                          for i,j in [(0,0),(0.5,1),(1,1.5),(1.5,1),(2,0),(2,-1),(1.5,-1.5),(1,-1),(0.5,-0.5)]]
            }
        ]
    },
    # User 4 阿杰 - 2 routes
    {
        "token": t4,
        "routes": [
            {
                "name": "大沙河生态长廊",
                "description": "南山大沙河生态长廊绿道，从深圳湾一直到大学城，全程平坦适合LSD",
                "distance": 7000, "elevation_gain": 12, "difficulty": 1,
                "tags": ["绿道", "河滨", "LSD"],
                "city": "深圳", "start_lat": 22.533, "start_lng": 113.968,
                "center_lat": 22.545, "center_lng": 113.970,
                "points": [{"latitude":22.533+i*0.0012, "longitude":113.968+j*0.0003, "altitude":5+i%2}
                          for i in range(0,30) for j in [0,0.5]][:70]
            },
            {
                "name": "南山公园登顶路",
                "description": "南山公园登顶路线，海拔336米，登顶可俯瞰深圳湾和香港元朗",
                "distance": 2200, "elevation_gain": 310, "difficulty": 3,
                "tags": ["登山", "爬升", "南山"],
                "city": "深圳", "start_lat": 22.517, "start_lng": 113.918,
                "center_lat": 22.527, "center_lng": 113.920,
                "points": [{"latitude":22.517+i*0.0005, "longitude":113.918+i*0.0001, "altitude":10+i*8}
                          for i in range(0,35)]
            }
        ]
    },
    # User 5 小美 - 2 routes
    {
        "token": t5,
        "routes": [
            {
                "name": "中心公园花径",
                "description": "福田中心公园内的花间小径，沿途月季花和紫荆花盛开，适合放松跑",
                "distance": 2800, "elevation_gain": 5, "difficulty": 1,
                "tags": ["公园", "花径", "放松"],
                "city": "深圳", "start_lat": 22.545, "start_lng": 114.071,
                "center_lat": 22.548, "center_lng": 114.075,
                "points": [{"latitude":22.545+i*0.0004, "longitude":114.071+j*0.0004, "altitude":5+i%2}
                          for i,j in [(0,0),(2,1),(4,2),(6,3),(8,2),(10,0),(8,-1),(6,-2),(4,-1),(2,0)]]
            },
            {
                "name": "笔架山环山径",
                "description": "笔架山公园环山步道，公园内植被茂密，空气清新，福田跑友的日常打卡点",
                "distance": 4000, "elevation_gain": 85, "difficulty": 2,
                "tags": ["环山", "公园", "打卡"],
                "city": "深圳", "start_lat": 22.563, "start_lng": 114.077,
                "center_lat": 22.567, "center_lng": 114.082,
                "points": [{"latitude":22.563+i*0.0003, "longitude":114.077+j*0.0005, "altitude":50+i*2}
                          for i,j in [(0,0),(2,1),(4,3),(6,4),(8,5),(10,4),(12,3),(14,1),(12,0),(10,0),(8,1),(6,2),(4,1),(2,0)]]
            }
        ]
    },
    # More routes for User 2 跑友小张 - add 1 more
    {
        "token": t2,
        "routes": [
            {
                "name": "香蜜公园夜跑",
                "description": "香蜜公园夜间跑步路线，灯光柔和，路面平整，适合下班后夜跑放松",
                "distance": 3800, "elevation_gain": 8, "difficulty": 1,
                "tags": ["夜跑", "公园", "福田"],
                "city": "深圳", "start_lat": 22.555, "start_lng": 114.022,
                "center_lat": 22.558, "center_lng": 114.026,
                "points": [{"latitude":22.555+i*0.0004, "longitude":114.022+j*0.0005, "altitude":8+i%2}
                          for i,j in [(0,0),(1,1),(2,2),(3,3),(4,4),(5,3),(6,2),(5,1),(4,0),(3,0),(2,1),(1,0)]]
            }
        ]
    }
]

created_ids = {}
print("\n=== Creating routes ===")
for batch in routes_data:
    for r in batch["routes"]:
        resp = requests.post(f"{BASE}/routes", headers={"Authorization": f"Bearer {batch['token']}"}, json=r)
        d = resp.json()
        rid = d["data"]["id"]
        creator = d["data"]["creator_id"]
        name = d["data"]["name"]
        print(f"  {name}: {rid}")
        if creator not in created_ids:
            created_ids[creator] = []
        created_ids[creator].append(rid)

# ====== Create follow relationships ======
print("\n=== Creating follows ===")
# User 1 follows user 3, 4, 5 (东君关注跑友们)
for token, uid in [(t3, "0f53bebe-0f0e-4396-a5a7-fc5053b3787a"),
                   (t4, "57a155b3-73ae-42ad-a7c1-d8bcc43d5778"),
                   (t5, "75c523bf-7f3f-4873-a59b-df8339812f1f")]:
    # Follow user
    r = requests.post(f"{BASE}/users/{uid}/follow", headers={"Authorization": f"Bearer {t1}"})
    print(f"  User 1 follows {uid}: HTTP {r.status_code}")

# User 3, 4, 5 follow user 1
for token, name in [(t3, "User3"), (t4, "User4"), (t5, "User5")]:
    r = requests.post(f"{BASE}/users/76702697-d684-4567-9207-a25a5bad0d10/follow",
                     headers={"Authorization": f"Bearer {token}"})
    print(f"  {name} follows User 1: HTTP {r.status_code}")

# ====== Create favorites (cross-user) ======
print("\n=== Creating favorites ===")
# User 1 favorites new routes from user 3, 4, 5
for uid, rids in created_ids.items():
    if uid == "76702697-d684-4567-9207-a25a5bad0d10":  # skip own routes
        continue
    for rid in rids:
        r = requests.post(f"{BASE}/routes/{rid}/favorite", headers={"Authorization": f"Bearer {t1}"})
        print(f"  User 1 favorites {rid}: HTTP {r.status_code}")

# Users 3, 4, 5 favorite user 1 & user 2 routes
user1_routes = ["86992120-3eec-4ce4-b44d-8da0c6691632",
                "5aa84db1-c4f7-4d71-8876-49a9ca444ba8",
                "f712c0ec-6af0-43b6-a056-3018c6bdb2c1"]
user2_routes = ["22ce365a-57b6-4a6b-b4ba-961c3ee8925c",
                "4bf307ae-f4d4-4485-a433-b53ec6bb74bd"]

for t, name in [(t3, "User3"), (t4, "User4"), (t5, "User5")]:
    for rid in user1_routes[:2]:  # each user favorites 2 of user 1's routes
        r = requests.post(f"{BASE}/routes/{rid}/favorite", headers={"Authorization": f"Bearer {t}"})
        print(f"  {name} favorites {rid}: HTTP {r.status_code}")
    for rid in user2_routes[:1]:  # each user favorites 1 of user 2's routes
        r = requests.post(f"{BASE}/routes/{rid}/favorite", headers={"Authorization": f"Bearer {t}"})
        print(f"  {name} favorites {rid}: HTTP {r.status_code}")

# User 2 favorites all new routes
for uid, rids in created_ids.items():
    if uid == "c023fb36-98cc-4f6d-afaa-ac0cdd8b6c5e":  # skip own routes
        continue
    for rid in rids:
        r = requests.post(f"{BASE}/routes/{rid}/favorite", headers={"Authorization": f"Bearer {t2}"})
        print(f"  User 2 favorites {rid}: HTTP {r.status_code}")

print("\n=== Done! ===")
