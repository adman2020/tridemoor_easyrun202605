import 'dart:math';

/// GPS 工具类
class GpsUtils {
  GpsUtils._();

  static const double _earthRadius = 6371000; // 米

  /// Haversine 公式计算两点距离（米）
  static double distance(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadius * c;
  }

  /// 计算累计距离（沿轨迹点数组）
  static double totalDistance(List<Map<String, double>> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += distance(
        points[i - 1]['lat']!,
        points[i - 1]['lng']!,
        points[i]['lat']!,
        points[i]['lng']!,
      );
    }
    return total;
  }

  /// Douglas-Peucker 轨迹简化算法
  static List<Map<String, double>> simplify(
    List<Map<String, double>> points, {
    double epsilon = 5.0, // 米
  }) {
    if (points.length <= 2) return List.from(points);

    int index = -1;
    double maxDist = 0.0;

    for (int i = 1; i < points.length - 1; i++) {
      final dist = _pointToLineDistance(
        points[i]['lat']!,
        points[i]['lng']!,
        points.first['lat']!,
        points.first['lng']!,
        points.last['lat']!,
        points.last['lng']!,
      );
      if (dist > maxDist) {
        maxDist = dist;
        index = i;
      }
    }

    if (maxDist > epsilon) {
      final left = simplify(points.sublist(0, index + 1), epsilon: epsilon);
      final right = simplify(points.sublist(index), epsilon: epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    }

    return [points.first, points.last];
  }

  /// 点到线段距离（米）
  static double _pointToLineDistance(
    double px, double py,
    double x1, double y1,
    double x2, double y2,
  ) {
    final A = px - x1;
    final B = py - y1;
    final C = x2 - x1;
    final D = y2 - y1;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    double param = -1;
    if (lenSq != 0) param = dot / lenSq;

    double xx, yy;
    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }

    final dx = px - xx;
    final dy = py - yy;
    return sqrt(dx * dx + dy * dy);
  }

  static double _toRadians(double degree) => degree * pi / 180.0;
}
