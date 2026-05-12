import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';

/// 关注跑友页
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  List<Map<String, dynamic>>? _followings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowings();
  }

  Future<void> _loadFollowings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.getFollowings(page: 1, pageSize: 100);
      if (resp.code == 0 && resp.data != null) {
        final raw = resp.data!['list'];
        if (raw is List) {
          setState(() =>
              _followings = raw.cast<Map<String, dynamic>>());
        }
      } else {
        setState(() => _error = resp.message ?? '加载失败');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.friends)),
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
            TextButton(onPressed: _loadFollowings, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_followings == null || _followings!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48.sp, color: context.textTertiary),
            SizedBox(height: 12.h),
            Text('还没有关注跑友', style: TextStyle(fontSize: 15.sp, color: context.textSecondary)),
            SizedBox(height: 4.h),
            Text('去发现页找找有趣的跑者吧', style: TextStyle(fontSize: 13.sp, color: context.textTertiary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowings,
      child: ListView.builder(
        padding: EdgeInsets.all(20.w),
        itemCount: _followings!.length,
        itemBuilder: (context, index) {
          final user = _followings![index];
          final nickname = user['nickname'] as String? ?? '未知跑友';
          final phone = user['phone'] as String? ?? '';
          final avatar = user['avatar'] as String?;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  backgroundColor: AppColors.orange.withValues(alpha: 0.1),
                  child: avatar == null
                      ? Text(nickname.isNotEmpty ? nickname[0] : '?',
                          style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 18.sp))
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nickname,
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
                      if (phone.isNotEmpty)
                        Text(phone,
                            style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final userId = user['following_id'] as String? ?? '';
                    if (userId.isNotEmpty) {
                      context.push('/profile/friends/$userId', extra: nickname);
                    }
                  },
                  child: const Text('查看'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
