import requests, json

# Login
r = requests.post('https://api.8keya.com/api/v1/auth/login',
    json={'phone':'13800000021','password':'test123456'})
token = r.json()['data']['tokens']['access_token']
headers = {'Authorization': f'Bearer {token}'}

# Check routes
r = requests.get('https://api.8keya.com/api/v1/routes?page=1&size=33', headers=headers)
data = r.json()
print(f'Routes total: {data["data"]["total"]}')
if data['data']['total'] > 0:
    for rt in data['data']['list'][:10]:
        print(f'  {rt["name"]} - {rt["city"]} - {rt["distance"]}m')
    if data['data']['total'] > 10:
        print(f'  ... and {data["data"]["total"] - 10} more')

print()

# Check runs for this user
r = requests.get('https://api.8keya.com/api/v1/runs?page=1&size=33', headers=headers)
data = r.json()
print(f'Runs total for luofeng: {data["data"]["total"]}')

# Check route square / popular
for endpoint in ['/routes/hot', '/routes/popular', '/routes/featured', '/discover/hot']:
    try:
        r = requests.get(f'https://api.8keya.com/api/v1{endpoint}?page=1&size=5', headers=headers, timeout=5)
        print(f'{endpoint}: status={r.status_code}, {r.text[:200]}')
    except Exception as e:
        print(f'{endpoint}: error - {e}')
