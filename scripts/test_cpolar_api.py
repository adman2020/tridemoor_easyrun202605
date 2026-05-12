"""Test the cpolar API endpoint end-to-end"""
import requests, json

CPOLAR = "https://fdb0e89.r17.cpolar.top"
PHONE = "13332995668"
PASS = "123456"

def test():
    # 1. Login
    r = requests.post(f"{CPOLAR}/api/v1/auth/login", json={"phone": PHONE, "password": PASS})
    print(f"Login: {r.status_code}")
    if r.status_code != 200:
        print(f"  {r.text[:300]}")
        return
    data = r.json()
    print(f"  code={data['code']}, has data= {bool(data.get('data'))}")
    token = data["data"]["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Routes list (as the app does)
    r = requests.get(f"{CPOLAR}/api/v1/routes?page=1&page_size=20", headers=headers)
    print(f"\nRoutes list: {r.status_code}")
    data = r.json()
    print(f"  code={data['code']}")
    rlist = data.get("data", {}).get("list", [])
    print(f"  got {len(rlist)} items")
    for route in rlist:
        print(f"    - {route.get('name', '?')} (city={route.get('city', '?')})")

if __name__ == "__main__":
    test()
