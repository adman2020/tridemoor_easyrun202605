#!/usr/bin/env python3
"""
Re-generate realistic GPS trajectories for StrideMoor routes.
Distance stored in DB is in METERS.
"""
import mysql.connector as mc, math, random, sys

random.seed(42)
DB = dict(host="127.0.0.1", port=3308, user="stridemoor",
          password="stridemoor_pass_2026", database="stridemoor")

def gauss_filter(pts, w=2):
    n = len(pts); r = list(pts)
    for i in range(w, n-w):
        la = sum(pts[j][0] for j in range(i-w,i+w+1))/(2*w+1)
        lo = sum(pts[j][1] for j in range(i-w,i+w+1))/(2*w+1)
        r[i] = (la, lo)
    return r

def path_dist(pts):
    s = 0
    for i in range(1, len(pts)):
        dy = (pts[i][0]-pts[i-1][0])*111000
        dx = (pts[i][1]-pts[i-1][1])*111000*math.cos(math.radians((pts[i][0]+pts[i-1][0])/2))
        s += math.hypot(dx, dy)
    return s

def endpoint(dist_km, lat, dl, dn):
    """Return (dlat, dlng) that gives approx dist_km straight-line span."""
    cl = math.cos(math.radians(lat))
    lw = abs(dl); nw = abs(dn); tw = lw + nw
    if tw > 0: lw /= tw; nw /= tw
    deg_per_km = (lw + nw * cl) / 111.0
    span = dist_km * deg_per_km * 1.0
    return dl * span, dn * span

def gen_loop(clat, clng, km):
    r = km/(2*math.pi) * 1.25  # 椭圆+扰动导致实际周长偏短，补偿25%
    rlat = r/111.0; rlng = r/(111.0*math.cos(math.radians(clat)))
    a = rlat*random.uniform(0.8, 1.0); b = rlng*random.uniform(0.7, 0.9)
    ang = random.uniform(0, math.pi)
    n = min(150, max(30, int(km*12)))
    pts = []
    for i in range(n+1):
        t = 2*math.pi*i/n
        w = 1+0.08*math.sin(3*t)+0.05*math.cos(5*t)+0.03*math.sin(7*t+0.5)
        ex = a*w*math.cos(t); ey = b*w*math.sin(t)
        lat = clat+ex*math.cos(ang)-ey*math.sin(ang)
        lng = clng+ex*math.sin(ang)+ey*math.cos(ang)
        pts.append((round(lat,7), round(lng,7)))
    return gauss_filter(pts)

def gen_linear(slat, slng, km, dl, dn):
    dlat, dlng = endpoint(km*1.05, slat, dl*0.9+dn*0.1, dn)  # 5% overshoot for S-curve shortening
    n = min(150, max(20, int(km*10)))
    pts = []
    for i in range(n+1):
        t = i/n
        lat = slat+dlat*t; lng = slng+dlng*t
        s = 0.002*math.sin(3*math.pi*t+0.7)
        pts.append((round(lat+s*0.8,7), round(lng+s*0.5,7)))
    return pts

def gen_coastal(slat, slng, km, dl, dn):
    dlat, dlng = endpoint(km*1.05, slat, dl, dn)  # 5% for curve
    n = min(150, max(30, int(km*10)))
    elat = slat+dlat; elng = slng+dlng
    bulge = random.uniform(0.003, 0.008)
    pts = []
    for i in range(n+1):
        t = i/n
        lat = slat+dlat*t; lng = slng+dlng*t
        a = 4*t*(1-t)
        lng -= a*bulge*math.sin(math.radians(lat*50))
        lat += a*bulge*0.2*math.cos(math.radians(lng*30))
        pts.append((round(lat,7), round(lng,7)))
    return gauss_filter(pts, w=1)

def gen_mountain(slat, slng, km, dl, dn):
    dlat, dlng = endpoint(km*1.05, slat, dl, dn)  # slight overshoot for winding
    n = min(200, max(35, int(km*12)))
    pts = []
    for i in range(n+1):
        t = i/n
        lat = slat+dlat*t; lng = slng+dlng*t
        lat += 0.003*math.sin(2.5*math.pi*t+0.7)+0.002*math.sin(5*math.pi*t+2.1)
        lng += 0.003*math.cos(3*math.pi*t+1.2)+0.002*math.cos(4*math.pi*t+0.8)
        pts.append((round(lat,7), round(lng,7)))
    return gauss_filter(pts, w=2)

RULES = {
    "欢乐港湾-前海绿道": "coastal", "梅林水库绿道": "linear",
    "深圳中心公园绿道": "linear", "东湖公园绿道": "linear",
    "南山公园环山道": "linear", "塘朗山郊野径": "mountain",
    "人才公园环湖": "loop", "盐田海滨栈道": "coastal",
    "福田河绿道": "linear", "香蜜公园环湖": "loop",
    "梧桐山绿道": "mountain", "深圳湾公园沿海跑道": "coastal",
    "大沙河生态长廊": "linear", "莲花山公园绕湖": "loop",
    "笔架山公园环山": "loop", "银湖山郊野径": "mountain",
}

def main():
    db = mc.connect(**DB); c = db.cursor()
    c.execute("SELECT id,name,distance,start_lat,start_lng,center_lat,center_lng FROM routes")
    routes = c.fetchall()
    ok = 0
    for row in routes:
        rid, name, dist_m, slat, slng, clat, clng = row
        t = RULES.get(name.strip())
        if not t: print(f"  -- {name.strip()} no rule"); continue
        slat = float(slat or 22.55); slng = float(slng or 114.0)
        clat = float(clat or slat+0.005); clng = float(clng or slng+0.005)
        km = float(dist_m)/1000
        dl, dn = clat-slat, clng-slng
        l = math.hypot(dl, dn)
        if l < 0.0001: dl, dn = math.cos(random.random()*6.28), math.sin(random.random()*6.28)
        else: dl, dn = dl/l, dn/l
        if t == "loop": pts = gen_loop(clat, clng, km)
        elif t == "coastal": pts = gen_coastal(slat, slng, km, dl, dn)
        elif t == "mountain": pts = gen_mountain(slat, slng, km, dl, dn)
        else: pts = gen_linear(slat, slng, km, dl, dn)
        actual_m = path_dist(pts)
        pct = actual_m/(km*1000)*100
        lat_rng = (min(p[0] for p in pts), max(p[0] for p in pts))
        lng_rng = (min(p[1] for p in pts), max(p[1] for p in pts))
        c.execute("DELETE FROM route_points WHERE route_id=%s", (rid,))
        batch = [(rid, i, pts[i][0], pts[i][1]) for i in range(len(pts))]
        c.executemany("INSERT INTO route_points(route_id,point_index,latitude,longitude) VALUES(%s,%s,%s,%s)", batch)
        db.commit()
        good = 85 < pct < 120
        if good: ok += 1
        print(f"  {'OK' if good else '??'} {name.strip():20s} {t:8s} {len(pts):3d}pts {actual_m/1000:.2f}/{km:.1f}km ({pct:.0f}%)  lat[{lat_rng[0]:.4f}~{lat_rng[1]:.4f}] lng[{lng_rng[0]:.4f}~{lng_rng[1]:.4f}]")
    print(f"\n{ok}/{len(routes)} routes within +-20%")
    c.execute("SELECT COUNT(*) FROM route_points")
    print(f"Total route_points: {c.fetchone()[0]}")
    db.close()

if __name__ == "__main__":
    main()
