import requests, json

base = 'https://68fe2436.r17.cpolar.top/api/v1'

# Login
r = requests.post(f'{base}/auth/login', json={'phone':'13332995668','password':'123456'}, timeout=10)
data = r.json()
token = data['data']['tokens']['access_token']
headers = {'Authorization': f'Bearer {token}'}
print('LOGIN OK')

# List devices
r = requests.get(f'{base}/devices', headers=headers, timeout=10)
j = r.json()
print('GET /devices: code=%s items=%s' % (j['code'], len(j.get('data',{}).get('list',[]))))

# Bind device
body = {'name':'Apple Watch','device_type':'smartwatch','brand':'Apple','model':'Watch Ultra 2','conn_type':'apple_health','mac_addr':'AA:BB:CC:DD:EE:01'}
r = requests.post(f'{base}/devices', json=body, headers=headers, timeout=10)
j = r.json()
dev_id = j.get('data',{}).get('id','')
print('POST /devices: code=%s name=%s id=%s' % (j['code'], j.get('data',{}).get('name','?'), dev_id[:15]))

# Update battery
r = requests.patch(f'{base}/devices/%s' % dev_id, json={'battery':80}, headers=headers, timeout=10)
j = r.json()
print('PATCH /devices: code=%s battery=%s' % (j['code'], j.get('data',{}).get('battery','?')))

# Unbind
r = requests.delete(f'{base}/devices/%s' % dev_id, headers=headers, timeout=10)
j = r.json()
print('DELETE /devices: code=%s' % j['code'])

print('ALL TESTS PASSED')
