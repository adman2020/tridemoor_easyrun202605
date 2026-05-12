// Generate interpolated geometry from waypoints (cosine interpolation, no noise)
function interpolatePath(waypoints, ptsPerSeg) {
  const result = [];
  for (let s = 0; s < waypoints.length - 1; s++) {
    const [lat0, lng0] = waypoints[s];
    const [lat1, lng1] = waypoints[s + 1];
    for (let i = 0; i < ptsPerSeg; i++) {
      const t = i / ptsPerSeg;
      const ct = (1 - Math.cos(t * Math.PI)) / 2;
      const lat = parseFloat((lat0 + (lat1 - lat0) * ct).toFixed(6));
      const lng = parseFloat((lng0 + (lng1 - lng0) * ct).toFixed(6));
      result.push({lat, lng});
    }
  }
  // deduplicate consecutive identical points
  const deduped = [result[0]];
  for (let i = 1; i < result.length; i++) {
    const prev = deduped[deduped.length-1];
    if (result[i].lat !== prev.lat || result[i].lng !== prev.lng) {
      deduped.push(result[i]);
    }
  }
  return deduped;
}

function formatGeometry(pts) {
  return pts.map(p => "      {'lat':" + p.lat + ",'lng':" + p.lng + "}").join(',\n');
}

// Friend routes waypoints
const friendRoutes = [
  { // 1. 梧桐山 - 11 wpts
    name: 'friend_route_001', wpts: [
      [22.5820, 114.2150],
      [22.5840, 114.2170],
      [22.5860, 114.2195],
      [22.5882, 114.2220],
      [22.5900, 114.2245],
      [22.5915, 114.2225],
      [22.5900, 114.2200],
      [22.5880, 114.2180],
      [22.5860, 114.2165],
      [22.5840, 114.2150],
      [22.5825, 114.2142],
    ], ptsPerSeg: 15
  },
  { // 2. 大沙河
    name: 'friend_route_002', wpts: [
      [22.5380, 113.9500],
      [22.5398, 113.9518],
      [22.5420, 113.9540],
      [22.5445, 113.9558],
      [22.5468, 113.9572],
      [22.5485, 113.9578],
    ], ptsPerSeg: 25
  },
  { // 3. 人才公园
    name: 'friend_route_003', wpts: [
      [22.5200, 113.9400],
      [22.5218, 113.9422],
      [22.5238, 113.9435],
      [22.5248, 113.9420],
      [22.5230, 113.9402],
      [22.5200, 113.9400],
    ], ptsPerSeg: 20
  },
  { // 4. 红树林
    name: 'friend_route_004', wpts: [
      [22.5200, 114.0200],
      [22.5220, 114.0225],
      [22.5245, 114.0250],
      [22.5275, 114.0280],
      [22.5305, 114.0305],
      [22.5330, 114.0328],
      [22.5350, 114.0340],
      [22.5330, 114.0325],
      [22.5305, 114.0300],
      [22.5275, 114.0275],
      [22.5245, 114.0250],
      [22.5220, 114.0225],
      [22.5200, 114.0200],
    ], ptsPerSeg: 12
  },
  { // 5. 大运中心
    name: 'friend_route_005', wpts: [
      [22.6900, 114.2100],
      [22.6915, 114.2125],
      [22.6930, 114.2130],
      [22.6938, 114.2110],
      [22.6925, 114.2090],
      [22.6908, 114.2085],
      [22.6900, 114.2100],
    ], ptsPerSeg: 20
  },
  { // 6. 妈祖湾
    name: 'friend_route_006', wpts: [
      [22.4950, 113.8800],
      [22.4968, 113.8825],
      [22.4988, 113.8855],
      [22.5008, 113.8868],
      [22.5025, 113.8845],
      [22.5018, 113.8815],
      [22.4995, 113.8795],
      [22.4970, 113.8798],
      [22.4950, 113.8800],
    ], ptsPerSeg: 15
  },
  { // 7. 光明小镇
    name: 'friend_route_007', wpts: [
      [22.7600, 113.9500],
      [22.7625, 113.9520],
      [22.7655, 113.9540],
      [22.7685, 113.9560],
      [22.7715, 113.9580],
      [22.7740, 113.9595],
    ], ptsPerSeg: 20
  },
  { // 8. 东湖公园
    name: 'friend_route_008', wpts: [
      [22.5750, 114.1350],
      [22.5768, 114.1370],
      [22.5785, 114.1395],
      [22.5802, 114.1405],
      [22.5810, 114.1385],
      [22.5795, 114.1360],
      [22.5775, 114.1342],
      [22.5750, 114.1350],
    ], ptsPerSeg: 20
  },
];

for (const r of friendRoutes) {
  const pts = interpolatePath(r.wpts, r.ptsPerSeg);
  console.log('=== ' + r.name + ' === ' + pts.length + ' pts');
  console.log(formatGeometry(pts));
  console.log('');
}
