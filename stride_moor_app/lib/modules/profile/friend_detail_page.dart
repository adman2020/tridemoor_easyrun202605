import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/theme.dart';
import '../../core/providers/app_providers.dart';

/// 跑友详情页
class FriendDetailPage extends ConsumerStatefulWidget {
  final String userId;
  final String nickname;

  const FriendDetailPage({
    super.key,
    required this.userId,
    this.nickname = '未知跑友',
  });

  @override
  ConsumerState<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends ConsumerState<FriendDetailPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  static const List<String> _realmNames = [
    '炼气', '筑基', '丹凝', '婴生', '化神', '炼虚',
    '合元', '大乘', '真仙', '金仙', '太乙', '大罗', '道祖',
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.getUserStats(widget.userId);
      if (resp.code == 0 && resp.data != null) {
        setState(() => _stats = resp.data!);
      } else {
        setState(() => _error = resp.message ?? '加载失败');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  int _getRealmIndex() {
    if (_stats == null) return 0;
    final realm = _stats!['realm'];
    if (realm is int) return realm;
    return 0;
  }

  double _getTotalDistance() {
    if (_stats == null) return 0;
    final v = _stats!['total_distance'];
    if (v is num) return v.toDouble();
    return 0;
  }

  int _getTotalRuns() {
    if (_stats == null) return 0;
    final v = _stats!['total_runs'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int _getTotalTime() {
    if (_stats == null) return 0;
    final v = _stats!['total_time'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int _getTotalCalories() {
    if (_stats == null) return 0;
    final v = _stats!['total_calories'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h${m}min';
    return '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nickname)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败', style: TextStyle(fontSize: 15.sp, color: context.textSecondary)),
            SizedBox(height: 8.h),
            TextButton(onPressed: _loadStats, child: const Text('重试')),
          ],
        ),
      );
    }

    final realmIndex = _getRealmIndex();
    final realmName = realmIndex < _realmNames.length ? _realmNames[realmIndex] : '未知';
    final distance = _getTotalDistance();
    final runs = _getTotalRuns();
    final durationSeconds = _getTotalTime();
    final calories = _getTotalCalories();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // 头像 + 昵称 + 跑境
          _buildHeader(realmName),
          SizedBox(height: 24.h),

          // 数据卡片：当前跑境
          _buildRealmCard(realmName),
          SizedBox(height: 16.h),

          // 四维数据卡片
          _buildStatsGrid(distance, runs, durationSeconds, calories),
          SizedBox(height: 16.h),

          // 备注
          Text(
            '数据实时更新，与跑友一起进步',
            style: TextStyle(fontSize: 12.sp, color: context.textTertiary),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildHeader(String realmName) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40.r,
          backgroundColor: AppColors.orange.withValues(alpha: 0.1),
          child: Text(
            widget.nickname.isNotEmpty ? widget.nickname[0] : '?',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.orange,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          widget.nickname,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            '当前跑境 · $realmName',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealmCard(String realmName) {
    // 境界标签颜色
    final color = realmName == '道祖'
        ? const Color(0xFFFFD700)
        : realmName == '大罗' || realmName == '太乙'
            ? const Color(0xFFC0C0C0)
            : AppColors.orange;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 32.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            realmName,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '修仙第 ${_getRealmIndex() + 1} 境 / 共 13 境',
            style: TextStyle(fontSize: 13.sp, color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double distance, int runs, int durationSeconds, int calories) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '跑步数据',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildStatItem(Icons.route, '总里程', '${distance.toStringAsFixed(1)} km')),
              Expanded(child: _buildStatItem(Icons.directions_run, '跑步次数', '$runs 次')),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildStatItem(Icons.timer_outlined, '总时长', _formatDuration(durationSeconds))),
              Expanded(child: _buildStatItem(Icons.local_fire_department, '累计消耗', '${_formatCalories(calories)}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: AppColors.orange),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.orange,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatCalories(int cal) {
    if (cal >= 1000) {
      return '${(cal / 1000).toStringAsFixed(1)}k kcal';
    }
    return '$cal kcal';
  }
}
