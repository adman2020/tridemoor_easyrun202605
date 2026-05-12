import mysql.connector as mc, json, requests

DB = dict(host="127.0.0.1", port=3308, user="root",
          password="stridemoor_root_2026", database="stridemoor")

db = mc.connect(**DB)
c = db.cursor()

c.execute("SELECT id, name, city, ROUND(distance,1), avg_pace, is_public, status, creator_id FROM routes ORDER BY created_at DESC LIMIT 20")
for r in c.fetchall():
    print(f"{r[0][:8]} | {r[1]:25s} | city={r[2]} | dist={r[3]:>8.1f}m | pace={r[4]}s | pub={r[5]} | st={r[6]} | creator={r[7][:8]}")
db.close()

print("\n--- Testing API ---")

# Get auth token first
r = requests.post("http://localhost:8080/api/v1/auth/login", json={"phone":"13332995668","password":"123456"})
token = r.json()["data"]["tokens"]["access_token"]
print(f"Token: {token[:20]}...")

# Get routes
r = requests.get("http://localhost:8080/api/v1/routes", headers={"Authorization": f"Bearer {token}"})
data = r.json()
print(f"Status: {data.get('code')}, data type: {type(data.get('data'))}")

routes = data.get("data", [])
# data might be a list or dict with a list inside
if isinstance(routes, dict):
    routes = routes.get("routes", routes.get("list", []))
    print(f"Routes from nested dict: got {len(routes)} items")
elif isinstance(routes, list):
    print(f"Routes from list: got {len(routes)} items")
else:
    print(f"Unexpected data format: {str(data)[:200]}")
    routes = []

for r_data in routes:
    print(f"  - {r_data.get('name', '?')}")
