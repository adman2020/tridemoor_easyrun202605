/// 跑境勋章定义（依据《境界-配速體系.md》）
/// 前五境：单次距离成就
/// 后八戒：全马用时成就

/// 跑者当前跑境数据
class RealmProgress {
  final String currentRealm;
  final List<String> unlockedBadges;
  final String name;
  final String achievementDesc;
  final String? nextRealmName;
  final String? nextRealmRequirement;
  final double progress;

  const RealmProgress({
    required this.currentRealm,
    required this.unlockedBadges,
    required this.name,
    required this.achievementDesc,
    this.nextRealmName,
    this.nextRealmRequirement,
    this.progress = 0.0,
  });
}

/// 勋章定义（单枚）
class Medal {
  final String name; // 全称，如"气引"
  final String code; // 单字代号，如"气" — 对应图片文件名
  final String desc; // 境界描述

  const Medal({
    required this.name,
    required this.code,
    required this.desc,
  });

  /// 图片路径：已解锁（亮色） — 用80px版本，保证 dim 和 small 路径都兼容
  String get litPath => 'assets/badges/paojing_small/${code}_80.png';

  /// 图片路径：未解锁（灰色）
  String get dimPath => 'assets/badges/paojing_dim/${code}_dim_80.png';

  static const all = <Medal>[
    Medal(name: '气引', code: '气', desc: '步履奠基'),
    Medal(name: '筑仙', code: '筑', desc: '渐入佳境'),
    Medal(name: '丹凝', code: '丹', desc: '初露锋芒'),
    Medal(name: '婴生', code: '婴', desc: '脱胎换骨'),
    Medal(name: '化神', code: '化', desc: '元神合一'),
    Medal(name: '炼虚', code: '虚', desc: '虚空破妄'),
    Medal(name: '合元', code: '合', desc: '元气归元'),
    Medal(name: '大乘', code: '乘', desc: '大乘圆满'),
    Medal(name: '真仙', code: '真', desc: '真我本相'),
    Medal(name: '金仙', code: '金', desc: '金刚不坏'),
    Medal(name: '太乙', code: '太', desc: '太乙归真'),
    Medal(name: '大罗', code: '罗', desc: '大罗天行'),
    Medal(name: '道祖', code: '道', desc: '万法归一'),
  ];

  static const double _halfMarathon = 21.0975;
  static const double _fullMarathon = 42.195;

  /// 全马门槛配速（秒/km）
  static const Map<String, int> _upperRealmPaces = {
    '虚': 255, // 全马 < 3:00:00 → 配速 < 4:15/km
    '合': 235, // 全马 < 2:45:00 → 配速 < 3:55/km
    '乘': 213, // 全马 < 2:30:00 → 配速 < 3:33/km
    '真': 199, // 全马 < 2:20:00 → 配速 < 3:19/km
    '金': 192, // 全马 < 2:15:00 → 配速 < 3:12/km
    '太': 185, // 全马 < 2:10:00 → 配速 < 3:05/km
    '罗': 178, // 全马 < 2:05:00 → 配速 < 2:58/km
    '道': 170, // 全马 < 2:00:00 → 配速 < 2:50/km
  };

  /// 根据多维度条件计算当前跑境
  /// - [bestSingleRunKm]: 最佳单次跑步距离(km)
  /// - [bestMarathonPaceSec]: 最佳全马配速(秒/km)
  /// - [companionRuns]: 已完成在线伴跑次数
  /// - [challengesWon]: 已挑战成功次数
  /// - [feedPosts]: 已发布动态数
  static RealmProgress calculate({
    required double bestSingleRunKm,
    int? bestMarathonPaceSec,
    int companionRuns = 0,
    int challengesWon = 0,
    int feedPosts = 0,
  }) {
    // 判境条件定义：[距离要求km, 伴跑次数, 挑战次数, 动态数]
    // 达到所有条件才算解锁该境界
    bool _unlocked(int idx) {
      switch (idx) {
        case 0: return true; // 炼气：开始跑就算
        case 1: return bestSingleRunKm >= 5.0 && companionRuns >= 1; // 筑基
        case 2: return bestSingleRunKm >= 10.0 && challengesWon >= 2; // 结丹
        case 3: return bestSingleRunKm >= _halfMarathon && challengesWon >= 5; // 元婴
        case 4: return bestSingleRunKm >= _fullMarathon && feedPosts >= 1; // 化神
        default: return false;
      }
    }

    // 1. 确定下五境（需要距离+社交条件）
    final lowerCodes = <String>['气'];
    for (int i = 1; i <= 4; i++) {
      if (_unlocked(i)) {
        lowerCodes.add(all[i].code);
      }
    }

    final hasFullMarathon = bestSingleRunKm >= _fullMarathon;
    final hasFeedPostAll = feedPosts >= 1;
    final canReachUpper = hasFullMarathon && hasFeedPostAll && bestMarathonPaceSec != null;

    // 2. 如果未满足上八境基础条件（全马+动态），最多到化神
    if (!canReachUpper || bestSingleRunKm < _fullMarathon) {
      final currentCode = lowerCodes.last;
      final currentIdx = all.indexWhere((m) => m.code == currentCode);
      final current = all[currentIdx];

      String? nextName;
      String? nextReq;
      double progress = 1.0;
      if (currentIdx < all.length - 1) {
        final next = all[currentIdx + 1];
        nextName = next.name;
        nextReq = _nextRequirement(currentIdx, bestSingleRunKm,
            companionRuns: companionRuns, challengesWon: challengesWon, feedPosts: feedPosts);
        progress = _progressTowardNext(currentIdx, bestSingleRunKm,
            bestMarathonPace: null, companionRuns: companionRuns, challengesWon: challengesWon, feedPosts: feedPosts);
      }

      return RealmProgress(
        currentRealm: currentCode,
        unlockedBadges: lowerCodes,
        name: current.name,
        achievementDesc: current.desc,
        nextRealmName: nextName,
        nextRealmRequirement: nextReq,
        progress: progress,
      );
    }

    // 3. 有全马记录 + 已发动态，判定上八境
    final upperCodes = <String>['化']; // 跑完全马+发动态即得化神
    if (bestMarathonPaceSec != null) {
      for (final entry in _upperRealmPaces.entries) {
        if (bestMarathonPaceSec <= entry.value) {
          upperCodes.add(entry.key);
        }
      }
    }

    // 合并去重并按 all 顺序排序
    final allCodes = lowerCodes.toSet();
    allCodes.addAll(upperCodes);
    final sortedUnlocked = all.where((m) => allCodes.contains(m.code)).map((m) => m.code).toList();

    final currentCode = sortedUnlocked.last;
    final currentIdx = all.indexWhere((m) => m.code == currentCode);
    final current = all[currentIdx];

    String? nextName;
    String? nextReq;
    double progress = 1.0;
    if (currentIdx < all.length - 1) {
      final next = all[currentIdx + 1];
      nextName = next.name;
      nextReq = _nextRequirement(currentIdx, bestSingleRunKm,
          bestMarathonPace: bestMarathonPaceSec, companionRuns: companionRuns, challengesWon: challengesWon, feedPosts: feedPosts);
      progress = _progressTowardNext(currentIdx, bestSingleRunKm,
          bestMarathonPace: bestMarathonPaceSec, companionRuns: companionRuns, challengesWon: challengesWon, feedPosts: feedPosts);
    }

    return RealmProgress(
      currentRealm: currentCode,
      unlockedBadges: sortedUnlocked,
      name: current.name,
      achievementDesc: current.desc,
      nextRealmName: nextName,
      nextRealmRequirement: nextReq,
      progress: progress,
    );
  }

  static String _nextRequirement(int currentIdx, double bestKm, {int? bestMarathonPace, int companionRuns = 0, int challengesWon = 0, int feedPosts = 0}) {
    if (currentIdx >= all.length - 1) return '已至巅峰';

    String _dist() => '距离${bestKm.toStringAsFixed(1)}km';
    String _companion() => '伴跑$companionRuns次';
    String _challenge() => '挑战$challengesWon次';
    String _post() => feedPosts > 0 ? '已发动态' : '未发动态';

    switch (currentIdx) {
      case 0:
        return '5km + 1次伴跑（$_dist(), $_companion()）';
      case 1:
        return '10km + 2次挑战（$_dist(), $_challenge()）';
      case 2:
        return '半马21.1km + 5次挑战（$_dist(), $_challenge()）';
      case 3:
        return '全马42.2km + 发动态（$_dist(), $_post()）';
      case 4:
        return '全马破3（当前${bestMarathonPace != null ? _formatPace(bestMarathonPace) : '暂无全马记录'}）';
      case 5:
        return '全马破2:45（当前${bestMarathonPace != null ? _formatPace(bestMarathonPace) : '暂无全马记录'}）';
      case 6:
        return '全马破2:30（当前${bestMarathonPace != null ? _formatPace(bestMarathonPace) : '暂无全马记录'}）';
      case 7:
        return '全马破2:20（当前${bestMarathonPace != null ? _formatPace(bestMarathonPace) : '暂无全马记录'}）';
      case 8:
        return '全马破2:15（当前${bestMarathonPace != null ? _formatPace(bestMarathonPace) : '暂无全马记录'}）';
      case 9:
        return '全马破2:10（当前${bestMarathonPace != null ? _formatPace(bestMarathonPace) : '暂无全马记录'}）';
      case 10:
        return '全马破2:05（当前${bestMarathonPace != null ? _formatPace(bestMarathonPace) : '暂无全马记录'}）';
      case 11:
        return '全马破2h（当前${bestMarathonPace != null ? _formatPace(bestMarathonPace) : '暂无全马记录'}）';
      default:
        return '';
    }
  }

  /// 综合多维度进度计算，取各维度的最小值（短板决定进度）
  static double _progressTowardNext(int currentIdx, double bestKm, {int? bestMarathonPace, int companionRuns = 0, int challengesWon = 0, int feedPosts = 0}) {
    switch (currentIdx) {
      case 0: // 炼气→筑基：5km + 1伴跑
        return _minOf([(bestKm / 5.0).clamp(0.0, 1.0), (companionRuns / 1.0).clamp(0.0, 1.0)]);
      case 1: // 筑基→结丹：10km + 2挑战
        return _minOf([((bestKm - 5) / 5.0).clamp(0.0, 1.0), (challengesWon / 2.0).clamp(0.0, 1.0)]);
      case 2: // 结丹→元婴：半马 + 5挑战
        return _minOf([((bestKm - 10) / (_halfMarathon - 10)).clamp(0.0, 1.0), (challengesWon / 5.0).clamp(0.0, 1.0)]);
      case 3: // 元婴→化神：全马 + 1动态
        return _minOf([((bestKm - _halfMarathon) / (_fullMarathon - _halfMarathon)).clamp(0.0, 1.0), (feedPosts / 1.0).clamp(0.0, 1.0)]);
      case 4: {
        final p = bestMarathonPace ?? 341;
        return ((341.0 - p) / (341.0 - 255.0)).clamp(0.0, 1.0);
      }
      case 5: {
        final p = bestMarathonPace ?? 255;
        return ((255.0 - p) / 20.0).clamp(0.0, 1.0);
      }
      case 6: {
        final p = bestMarathonPace ?? 235;
        return ((235.0 - p) / 22.0).clamp(0.0, 1.0);
      }
      case 7: {
        final p = bestMarathonPace ?? 213;
        return ((213.0 - p) / 14.0).clamp(0.0, 1.0);
      }
      case 8: {
        final p = bestMarathonPace ?? 199;
        return ((199.0 - p) / 7.0).clamp(0.0, 1.0);
      }
      case 9: {
        final p = bestMarathonPace ?? 192;
        return ((192.0 - p) / 7.0).clamp(0.0, 1.0);
      }
      case 10: {
        final p = bestMarathonPace ?? 185;
        return ((185.0 - p) / 7.0).clamp(0.0, 1.0);
      }
      case 11: {
        final p = bestMarathonPace ?? 178;
        return ((178.0 - p) / 8.0).clamp(0.0, 1.0);
      }
      default:
        return 1.0;
    }
  }

  /// 取多维度进度最小值（木桶效应）
  static double _minOf(List<double> values) {
    return values.reduce((a, b) => a < b ? a : b);
  }

  static String _formatPace(int secondsPerKm) {
    final m = secondsPerKm ~/ 60;
    final s = secondsPerKm % 60;
    return '${m}:${s.toString().padLeft(2, '0')}/km';
  }
}
