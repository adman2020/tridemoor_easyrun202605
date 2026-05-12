import 'gps_utils.dart';

/// 路线匹配算法
/// 
/// 核心逻辑：
/// 1. 起终点距离 < 100m
/// 2. 总距离偏差 < 10%
/// 3. DTW 轨迹相似度 > 85%
class RouteMatcher {
  RouteMatcher._();

  static const double _endpointThreshold = 100.0; // 米
  static const double _distanceTolerance = 0.10; // 10%
  static const double _similarityThreshold = 0.85;

  /// 判断两条轨迹是否为同一路线
  static bool isSameRoute(
    List<Map<String, double>> traceA,
    List<Map<String, double>> traceB, {
    double? knownDistanceA,
    double? knownDistanceB,
  }) {
    if (traceA.length < 2 || traceB.length < 2) return false;

    // 1. 起终点匹配
    final startDist = GpsUtils.distance(
      traceA.first['lat']!, traceA.first['lng']!,
      traceB.first['lat']!, traceB.first['lng']!,
    );
    final endDist = GpsUtils.distance(
      traceA.last['lat']!, traceA.last['lng']!,
      traceB.last['lat']!, traceB.last['lng']!,
    );
    if (startDist > _endpointThreshold || endDist > _endpointThreshold) {
      return false;
    }

    // 2. 距离匹配
    final distA = knownDistanceA ?? GpsUtils.totalDistance(traceA);
    final distB = knownDistanceB ?? GpsUtils.totalDistance(traceB);
    if (distA <= 0 || distB <= 0) return false;
    final distDiff = (distA - distB).abs() / distA;
    if (distDiff > _distanceTolerance) {
      return false;
    }

    // 3. DTW 相似度
    final dtwDist = _dtwDistance(traceA, traceB);
    final maxLen = distA > distB ? distA : distB;
    final similarity = 1 - (dtwDist / maxLen);

    return similarity > _similarityThreshold;
  }

  /// 简化版 DTW（动态时间规整）
  static double _dtwDistance(
    List<Map<String, double>> a,
    List<Map<String, double>> b,
  ) {
    final n = a.length;
    final m = b.length;
    final dtw = List.generate(n, (_) => List<double>.filled(m, double.infinity));
    dtw[0][0] = 0;

    for (int i = 1; i < n; i++) {
      for (int j = 1; j < m; j++) {
        final cost = GpsUtils.distance(
          a[i]['lat']!, a[i]['lng']!,
          b[j]['lat']!, b[j]['lng']!,
        );
        dtw[i][j] = cost +
            [dtw[i - 1][j], dtw[i][j - 1], dtw[i - 1][j - 1]]
                .reduce((min, val) => val < min ? val : min);
      }
    }

    return dtw[n - 1][m - 1];
  }

  /// 分段对齐：用 Frechet 距离匹配对应分段
  static List<int> alignSplits(
    List<Map<String, double>> traceA,
    List<Map<String, double>> traceB, {
    int splitCount = 5,
  }) {
    // TODO: 实现基于 Frechet 距离的分段对齐
    // 简化实现：按距离等比例分段
    return List.generate(splitCount, (i) => i);
  }
}
