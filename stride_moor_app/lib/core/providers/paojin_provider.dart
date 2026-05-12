import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import 'app_providers.dart';

/// 跑境数据结构
class PaojingBadge {
  final String char;
  final String name;
  final bool earned;

  PaojingBadge({required this.char, required this.name, required this.earned});

  factory PaojingBadge.fromJson(Map<String, dynamic> json) {
    return PaojingBadge(
      char: json['char'] as String? ?? '',
      name: json['name'] as String? ?? '',
      earned: json['earned'] as bool? ?? false,
    );
  }
}

class PaojingData {
  final int currentRealm;
  final String currentChar;
  final String currentName;
  final double progress;
  final List<PaojingBadge> badges;
  final Map<String, dynamic>? nextRule;

  PaojingData({
    required this.currentRealm,
    required this.currentChar,
    required this.currentName,
    required this.progress,
    required this.badges,
    this.nextRule,
  });

  factory PaojingData.fromJson(Map<String, dynamic> json) {
    final badgeList = (json['badges'] as List<dynamic>?)
            ?.map((e) => PaojingBadge.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PaojingData(
      currentRealm: json['current_realm'] as int? ?? 0,
      currentChar: json['current_char'] as String? ?? '',
      currentName: json['current_name'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      badges: badgeList,
      nextRule: json['next_rule'] as Map<String, dynamic>?,
    );
  }

  /// 已点亮数量
  int get earnedCount => badges.where((b) => b.earned).length;
}

/// 跑境升级通知
class PaojingUpgradeResult {
  final bool upgraded;
  final int newRealm;
  final String newChar;
  final String newName;

  PaojingUpgradeResult({
    required this.upgraded,
    required this.newRealm,
    required this.newChar,
    required this.newName,
  });

  factory PaojingUpgradeResult.fromJson(Map<String, dynamic> json) {
    return PaojingUpgradeResult(
      upgraded: json['upgraded'] as bool? ?? false,
      newRealm: json['new_realm'] as int? ?? 0,
      newChar: json['new_char'] as String? ?? '',
      newName: json['new_name'] as String? ?? '',
    );
  }
}

/// 跑境状态 Provider
final paojingProvider = StateNotifierProvider<PaojingNotifier, AsyncValue<PaojingData?>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return PaojingNotifier(api);
});

class PaojingNotifier extends StateNotifier<AsyncValue<PaojingData?>> {
  final ApiService _api;

  PaojingNotifier(this._api) : super(const AsyncValue.data(null));

  /// 加载跑境数据（有缓存时静默刷新，不闪 loading）
  Future<void> loadPaojing() async {
    // 已有缓存数据 → 静默刷新，避免 UI 闪动
    if (state.value != null) {
      try {
        final resp = await _api.getPaojing();
        if (resp.isSuccess && resp.data != null) {
          state = AsyncValue.data(PaojingData.fromJson(resp.data!));
        }
        // 失败静默忽略，保留旧数据
      } catch (_) {
        // 静默忽略
      }
      return;
    }

    // 首次加载才显示 loading
    state = const AsyncValue.loading();
    try {
      final resp = await _api.getPaojing();
      if (resp.isSuccess && resp.data != null) {
        state = AsyncValue.data(PaojingData.fromJson(resp.data!));
      } else {
        state = AsyncValue.error(resp.message, StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 赛后判境
  Future<PaojingUpgradeResult?> checkUpgrade() async {
    try {
      final resp = await _api.checkPaojingUpgrade();
      if (resp.isSuccess && resp.data != null) {
        final result = PaojingUpgradeResult.fromJson(resp.data!);
        // 判境后刷新数据
        await loadPaojing();
        return result;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
