import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/models/run.dart';
import '../../core/providers/route_provider.dart';

/// 跑迹选择页 —— 从收藏的跑友跑迹中选择一条作为伴跑/挑战跑素材
///
/// 返回选中的 bookmark 数据 `Map<String, dynamic>`，格式：
/// {
///   "run": Run对象JSON,
///   "route": Route对象JSON（来自run.route）,
///   "friend_name": "昵称",
///   "friend_avatar": "头像URL"
/// }
class RunTraceSelectPage extends ConsumerWidget {
  const RunTraceSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(friendsRoutesProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('选择跑迹'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 48.sp, color: context.textTertiary),
                  SizedBox(height: 12.h),
                  Text('暂无收藏的跑迹', style: TextStyle(color: context.textSecondary)),
                  SizedBox(height: 8.h),
                  Text(
                    '先去跑迹广场或跑友动态收藏跑友的跑步记录',
                    style: TextStyle(color: context.textTertiary, fontSize: 12.sp),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final runJson = item['run'] as Map<String, dynamic>?;
              if (runJson == null) return const SizedBox.shrink();

              final run = Run.fromJson(runJson);
              return _RunTraceCard(
                run: run,
                runJson: runJson,
                onTap: () {
                  final routeJson = runJson['route'] as Map<String, dynamic>?;
                  final userJson = runJson['user'] as Map<String, dynamic>?;
                  final result = <String, dynamic>{
                    'run': runJson,
                    if (routeJson != null) 'route': routeJson,
                    'friend_name': userJson?['nickname'] as String? ?? userJson?['username'] as String? ?? '跑友',
                    'friend_avatar': userJson?['avatar'] as String?,
                  };
                  context.pop<Map<String, dynamic>>(result);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RunTraceCard extends StatelessWidget {
  final Run run;
  final Map<String, dynamic> runJson;
  final VoidCallback onTap;

  const _RunTraceCard({
    required this.run,
    required this.runJson,
    required this.onTap,
  });

  String get _friendName {
    final user = runJson['user'] as Map<String, dynamic>?;
    return user?['nickname'] as String? ?? user?['username'] as String? ?? '跑友';
  }

  String? get _friendAvatar {
    final user = runJson['user'] as Map<String, dynamic>?;
    return user?['avatar'] as String?;
  }

  String? get _routeName {
    final route = runJson['route'] as Map<String, dynamic>?;
    return route?['name'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = run.totalDistance / 1000;
    final avgPaceStr = run.avgPace != null && run.avgPace! > 0
        ? '${run.avgPace! ~/ 60}\'${(run.avgPace! % 60).toString().padLeft(2, '0')}'
        : '--';
    final durationStr = run.totalTime > 0
        ? '${run.totalTime ~/ 60}分${run.totalTime % 60}秒'
        : '--';

    return Card(
      color: context.surfaceColor,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: context.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 跑友 + 路线名
              Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundImage: _friendAvatar != null
                        ? NetworkImage(_friendAvatar!)
                        : null,
                    child: _friendAvatar == null
                        ? Icon(Icons.person, size: 20.sp, color: context.textTertiary)
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _friendName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _routeName ?? '未知路线',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.textTertiary),
                ],
              ),
              SizedBox(height: 12.h),
              // 运动指标
              Row(
                children: [
                  _statItem(context, '距离', '${distanceKm.toStringAsFixed(1)}km'),
                  _divider(context),
                  _statItem(context, '配速', avgPaceStr),
                  _divider(context),
                  _statItem(context, '用时', durationStr),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: context.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 30.h,
      color: context.dividerColor,
    );
  }
}
