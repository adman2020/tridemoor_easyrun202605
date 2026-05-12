#!/usr/bin/env python3
import sys, io, json, urllib.request
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYWNmMzIzMDYtMTkyYS00ZGZiLTk0MTYtM2YzMmQ2MGRkNjBlIiwicGhvbmUiOiIxMzgwMDAwMDEwNSIsImlzcyI6InN0cmlkZW1vb3IiLCJzdWIiOiJhY2YzMjMwNi0xOTJhLTRkZmItOTQxNi0zZjMyZDYwZGQ2MGUiLCJleHAiOjE3ODA3NTM1OTUsImlhdCI6MTc3ODE2MTU5NX0.KirfsrpyKiO3R4n9T7QbDeMgnSNiQlcVoZrsZRYSq7g"

req = urllib.request.Request(
    "http://localhost:8080/api/v1/routes?page_size=100",
    headers={"Authorization": f"Bearer {TOKEN}"}
)
resp = urllib.request.urlopen(req)
data = json.loads(resp.read())
routes = data.get("data", {}).get("list", [])

# 已修复的真实路线
real = {
    "洪湖公园晨跑", "福田CBD夜跑", "荔枝公园环线",
    "莲花山公园绕湖", "莲花山环湖跑",
    "笔架山公园环山", "笔架山环山径",
    "东湖公园绿道",
    "深圳中心公园绿道", "中心公园花径",
    "南山公园环山道", "南山公园登顶路",
    "景发小区800米路线",
}

# 原始seed有真实轨迹
seed_gps = {
    "环香蜜湖晨跑线路", "环香蜜湖10公里路线", "香蜜片区环线",
    "马鹿山公园跑步线路", "湖湘公园线路", "沿涓江往返10公里线路",
}

diff_map = {1: "入门", 2: "中级", 3: "困难"}

done = []
pending = []

for r in routes:
    n = r["name"]
    d = r.get("distance", 0)
    km = d / 1000 if d > 100 else d
    diff = diff_map.get(r.get("difficulty"), "?")
    desc = r.get("description", "")[:20] if r.get("description") else "-"
    info = f"{n:18s}  {km:>6.1f}km  {diff:4s}"

    if n in real:
        done.append(f"  [{'真实' if n!='景发小区800米路线' else '手动'}][✅] {info}")
    elif n in seed_gps:
        done.append(f"  [原始seed][✅] {info}")
    else:
        pending.append(f"  [待更新][⚠️] {info}")

done.sort()
pending.sort()

print("=" * 55)
print(f"  跑迹广场 - 路线状态统计（共{len(routes)}条）")
print("=" * 55)

print(f"\n✅ 已正确 / 真实GPS/坐标（{len(done)}条）：")
for l in done:
    print(l)

print(f"\n⚠️  待更新（{len(pending)}条）：")
for l in pending:
    print(l)

print(f"\n{'=' * 55}")
print(f"  合计：{len(done)} 条正确 + {len(pending)} 条待更新 = {len(routes)} 条")
