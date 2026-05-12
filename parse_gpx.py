import xml.etree.ElementTree as ET
import math

# WGS84 → GCJ-02 conversion
_a = 6378245.0
_ee = 0.00669342162296594323

def _in_china(lat, lng):
    return not (lng < 72.004 or lng > 137.8347 or lat < 0.8293 or lat > 55.8271)

def _transform_lat(x, y):
    ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * math.sqrt(abs(x))
    ret += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    ret += (20.0 * math.sin(y * math.pi) + 40.0 * math.sin(y / 3.0 * math.pi)) * 2.0 / 3.0
    ret += (160.0 * math.sin(y / 12.0 * math.pi) + 320.0 * math.sin(y * math.pi / 30.0)) * 2.0 / 3.0
    return ret

def _transform_lng(x, y):
    ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(abs(x))
    ret += (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    ret += (20.0 * math.sin(x * math.pi) + 40.0 * math.sin(x / 3.0 * math.pi)) * 2.0 / 3.0
    ret += (150.0 * math.sin(x / 12.0 * math.pi) + 300.0 * math.sin(x / 30.0 * math.pi)) * 2.0 / 3.0
    return ret

def wgs84_to_gcj02(lat, lng):
    if not _in_china(lat, lng):
        return lat, lng
    dlat = _transform_lat(lng - 105.0, lat - 35.0)
    dlng = _transform_lng(lng - 105.0, lat - 35.0)
    radlat = lat / 180.0 * math.pi
    magic = 1 - _ee * math.sin(radlat) * math.sin(radlat)
    magic = max(0.0, min(1.0, magic))
    sqrtmagic = math.sqrt(magic)
    dlat = (dlat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtmagic) * math.pi)
    dlng = (dlng * 180.0) / (_a / sqrtmagic * math.cos(radlat) * math.pi)
    return lat + dlat, lng + dlng

# Parse GPX
gpx_path = r'C:\Users\Administered\.openclaw\media\qqbot\downloads\1903925712\16B982FB78829C1ECBDEADBA968743ED\23b9af00-0162-48ae-96f2-48f016b106eb.gpx'
ns = '{http://www.topografix.com/GPX/1/0}'

tree = ET.parse(gpx_path)
root = tree.getroot()

# Find trk element
trk = root.find(f'{ns}trk')
assert trk is not None, "trk not found"

# Extensions data
ext = trk.find(f'{ns}extensions')
total_time = float(ext.find(f'{ns}totalTime').text)
total_distance = float(ext.find(f'{ns}totalDistance').text)
elevation_gain = float(ext.find(f'{ns}cumulativeClimb').text)
elevation_loss = float(ext.find(f'{ns}cumulativeDecrease').text)

# Track points
trkseg = trk.find(f'{ns}trkseg')
points = []
for trkpt in trkseg.findall(f'{ns}trkpt'):
    lat = float(trkpt.get('lat'))
    lon = float(trkpt.get('lon'))
    gcj_lat, gcj_lon = wgs84_to_gcj02(lat, lon)
    points.append({'lat': round(gcj_lat, 6), 'lng': round(gcj_lon, 6)})

# Simplify: take every 5th point
simplified = points[::5]
if points and points[-1] not in simplified:
    simplified.append(points[-1])

# Calculate center
center_lat = sum(p['lat'] for p in simplified) / len(simplified)
center_lng = sum(p['lng'] for p in simplified) / len(simplified)

# Avg pace: seconds per km
avg_pace = round(total_time / (total_distance / 1000))

print(f"Total time: {total_time}s")
print(f"Total distance: {total_distance}m")
print(f"Elevation gain: {elevation_gain}m")
print(f"Elevation loss: {elevation_loss}m")
print(f"Avg pace: {avg_pace}s/km")
print(f"Center: ({center_lat:.6f}, {center_lng:.6f})")
print(f"Start: ({simplified[0]['lat']}, {simplified[0]['lng']})")
print(f"Points count: {len(simplified)} (simplified from {len(points)})")
print()

# Output Dart code
print("/// 景发小区800米下 测试路线数据")
print("/// 源GPX：5月6日华为健康导出")
print("/// 坐标已从 WGS84 转换为 GCJ-02（高德地图坐标系）")
print()
print("import 'route.dart' as app_route;")
print()
print("app_route.Route testRoute = app_route.Route(")
print("  id: 'dev_test_jingfa_800',")
print("  creatorId: 'dev_test',")
print("  creatorName: '测试路线',")
print("  name: '景发小区800米下',")
print("  description: '深圳景发小区环形路线，约810m。由晨跑 GPS 记录生成，用于 ghost running 测试。',")
print(f"  distance: {total_distance},")
print(f"  elevationGain: {elevation_gain},")
print(f"  avgPace: {avg_pace},")
print("  difficulty: 'easy',")
print("  tags: ['测试', '深圳', '小区'],")
print("  city: '深圳',")
print(f"  totalTime: {int(total_time)},")
print("  geometry: [")
for p in simplified:
    print(f"    {{'lat': {p['lat']}, 'lng': {p['lng']}}},")
print("  ],")
print(f"  startPoint: {{'lat': {simplified[0]['lat']}, 'lng': {simplified[0]['lng']}}},")
print(f"  centerPoint: {{'lat': {center_lat:.6f}, 'lng': {center_lng:.6f}}},")
print(");")
