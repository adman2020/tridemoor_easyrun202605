"""Test the route matching algorithm by simulating a run along 湖湘公园线路"""
import mysql.connector as mc, requests, json, random, math

DB = dict(host="127.0.0.1", port=3308, user="root",
          password="stridemoor_root_2026", database="stridemoor")
API = "http://localhost:8080/api/v1"
PHONE = "13332995668"
PASS = "123456"

db = mc.connect(**DB)
c = db.cursor()

# 1. Get 湖湘公园线路's route points
route_id = "7a39af60-32ea-4073-8754-eb5150900b86"
c.execute("SELECT latitude, longitude FROM route_points WHERE route_id = %s ORDER BY point_index", (route_id,))
route_pts = c.fetchall()
print(f"湖湘公园线路: {len(route_pts)} route points")

# 2. Simulate a run: take every 3rd route point + add GPS noise (~5m)
random.seed(42)
run_pts = []
for i, row in enumerate(route_pts):
    lat, lng = float(row[0]), float(row[1])
    if i % 3 == 0:
        noise_lat = random.gauss(0, 0.000045)  # ~5m noise
        noise_lng = random.gauss(0, 0.000045)
        run_pts.append({
            "latitude": lat + noise_lat,
            "longitude": lng + noise_lng,
            "sample_time": f"2026-05-03T08:00:{i//3:02d}.000+08:00",
            "pace": 360.0,
            "distance_from_start": i * 85.0  # rough per-point distance
        })
print(f"Simulated {len(run_pts)} run samples")

# 3. Login
r = requests.post(f"{API}/auth/login", json={"phone": PHONE, "password": PASS})
token = r.json()["data"]["tokens"]["access_token"]
headers = {"Authorization": f"Bearer {token}"}
user_id = r.json()["data"]["user_info"]["id"]
print(f"\nUser: {user_id[:12]}...")

# 4. Start a run (NO route_id - let auto-match find it)
r = requests.post(f"{API}/runs/start", json={}, headers=headers)
run_id = r.json()["data"]["run_id"]
print(f"Started run: {run_id[:12]}...")

# 5. Upload simulated GPS samples
sample_req = {"samples": run_pts}
r = requests.post(f"{API}/runs/{run_id}/samples", json=sample_req, headers=headers)
print(f"Uploaded samples: {r.json()}")

# 6. Finish run
total_distance = len(route_pts) * 85.0
total_time = 3853  # ~64 min
finish_req = {
    "end_time": "2026-05-03T09:05:00.000+08:00",
    "total_time": total_time,
    "total_distance": total_distance,
    "avg_pace": 383,
    "best_pace": 310,
    "avg_heart_rate": 148,
    "max_heart_rate": 172,
    "avg_cadence": 172,
    "max_cadence": 186,
    "avg_stride_length": 1.05,
    "elevation_gain": 50.7,
    "elevation_loss": 50.6,
    "calories": 555,
}
r = requests.post(f"{API}/runs/{run_id}/finish", json=finish_req, headers=headers)
print(f"Finished run: {r.json()}")

import time
# 7. Check if route was auto-matched (wait for goroutine)
time.sleep(1)
r = requests.get(f"{API}/runs/{run_id}", headers=headers)
run_data = r.json()
matched_route_id = run_data.get("data", {}).get("route_id")
print(f"\n▶ Auto-matched route_id: {matched_route_id}")

if matched_route_id == route_id:
    print("✅ 匹配成功！正确关联到湖湘公园线路")
elif matched_route_id:
    print(f"⚠️ 匹配到不同的路线: {matched_route_id}")
    c.execute("SELECT name FROM routes WHERE id = %s", (matched_route_id,))
    result = c.fetchone()
    print(f"   路线名称: {result[0] if result else '未知'}")
else:
    print("❌ 匹配失败，route_id 为空")

# 8. Check leaderboard
r = requests.get(f"{API}/routes/{route_id}/leaderboard", headers=headers)
lb = r.json()
print(f"\n▶ 排行榜: {lb}")
for entry in lb.get("data", {}).get("list", []):
    print(f"  {entry.get('run_count')}次 - user={entry.get('user_id','')[:10]}... pace={entry.get('avg_pace')}")

db.close()
