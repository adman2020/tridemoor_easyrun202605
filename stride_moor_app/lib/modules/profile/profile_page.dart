import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/paojin_provider.dart';
import '../../core/providers/challenge_provider.dart';
import '../../core/models/user.dart';
import 'avatar_crop_page.dart';
import 'ghost_mode_rules_page.dart';
import 'paojing_rules_page.dart';
import 'challenge_rules_page.dart';

/// 个人中心页 —— 主页 / 设置 / 数据统计入口

/// 每次缓存更新时递增，用于强制 Image.file 重建，避免 Flutter 内存缓存
int _avatarCacheGen = 0;

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildUserHeader(context, l10n, user, ref)),
          SliverToBoxAdapter(child: _buildStatsCard(context, l10n, user)),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMenuSection(context, [
                  _buildPaojingMenuItem(context, ref),
                  _buildChallengeMenuItem(context, ref),
                  _MenuItem(
                    icon: Icons.bar_chart,
                    title: l10n.runningStats,
                    subtitle: '周/月/年训练数据',
                    onTap: () => context.push('/profile/stats'),
                  ),
                ]),
                SizedBox(height: 16.h),
                _buildMenuSection(context, [
                  _MenuItem(
                    icon: Icons.settings_voice,
                    title: l10n.broadcastSettings,
                    subtitle: '频率 / 内容 / 语音风格',
                    onTap: () => context.push('/profile/broadcast'),
                  ),
                  _MenuItem(
                    icon: Icons.smart_toy_outlined,
                    title: 'AI智能功能',
                    subtitle: '查看VIP权益与功能解锁',
                    onTap: () => context.push('/profile/settings'),
                  ),
                  _MenuItem(
                    icon: Icons.bluetooth,
                    title: l10n.deviceManagement,
                    subtitle: '已连接 1 台设备',
                    onTap: () => context.push('/profile/devices'),
                  ),
                  _MenuItem(
                    icon: Icons.history,
                    title: '导入记录',
                    subtitle: '健康平台导入的历史',
                    onTap: () => context.push('/profile/imports'),
                  ),
                  _buildFriendsMenuItem(context, ref, l10n),
                  _MenuItem(
                    icon: Icons.lock_outline,
                    title: '修改密码',
                    onTap: () => _showChangePasswordDialog(context, ref),
                  ),
                ]),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.only(left: 20.w, bottom: 8.h),
                  child: Text('帮助菜单',
                    style: TextStyle(fontSize: 13.sp, color: const Color(0xFF888888)),
                  ),
                ),
                _buildMenuSection(context, [
                  _MenuItem(
                    icon: Icons.emoji_people,
                    title: '伴跑规则',
                    subtitle: '5种伴跑模式说明',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const GhostModeRulesPage()),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.auto_awesome,
                    title: '跑境规则',
                    subtitle: '十三境晋升条件',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const PaojingRulesPage()),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.emoji_events_outlined,
                    title: '挑战跑规则',
                    subtitle: '异步竞技与胜负判定',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const ChallengeRulesPage()),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: l10n.about,
                    onTap: () => _showAboutDialog(context, l10n),
                  ),
                ]),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(userProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('退出登录'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: Size(double.infinity, 48.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    const base = AppConstants.baseUrl;
    final prefix = base.endsWith('/api/v1') ? base.substring(0, base.length - 6) : base;
    return '$prefix$url';
  }

  Widget _buildUserHeader(BuildContext context, AppLocalizations l10n, User? user, WidgetRef ref) {
    final nickname = user?.nickname ?? l10n.runnerNickname;
    final userId = user?.id ?? '-';
    // 检查本地缓存（优先），没有则走网络 URL
    final cacheFile = File('${Directory.systemTemp.path}/avatar_cache.png');
    final hasCache = cacheFile.existsSync();
    // 从 user provider 获取 URL，若为 null 则从 Hive 持久化缓存读取
    String? avatarUrl = _resolveImageUrl(user?.avatarUrl);
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final storageService = ref.read(storageServiceProvider);
      avatarUrl = _resolveImageUrl(storageService.getCachedAvatarUrl());
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 24.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAvatarOptions(context, ref),
            child: Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: hasCache
                  ? ClipOval(
                      child: Image.file(
                        cacheFile,
                        key: ValueKey('avatar_$_avatarCacheGen'),
                        width: 72.w,
                        height: 72.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.person, size: 36.sp, color: Colors.white),
                      ),
                    )
                  : avatarUrl != null && avatarUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 72.w,
                            height: 72.w,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person, size: 36.sp, color: Colors.white),
                          ),
                        )
                      : Icon(Icons.person, size: 36.sp, color: Colors.white),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ID: $userId',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.8)),
            onPressed: () => _showEditProfileDialog(context, l10n, user, ref),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(context, ref, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(context, ref, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 头像本地缓存路径
  File get _avatarCacheFile =>
      File('${Directory.systemTemp.path}/avatar_cache.png');

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref, ImageSource source) async {
    // 在异步操作前捕获 Navigator
    final navigator = Navigator.of(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
    if (pickedFile == null) return;

    // ★ 跳转到手动裁剪页面，用户可缩放拖动选择区域
    final bytes = await navigator.push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => AvatarCropPage(imagePath: pickedFile.path),
      ),
    );
    if (bytes == null) return; // 用户取消裁剪

    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';

    // ★ 先存本地缓存，保证立刻显示（无论上传是否成功）
    try {
      await _avatarCacheFile.writeAsBytes(bytes);
      _avatarCacheGen++;
      // 强制刷新用户状态，触发 widget 重建，改用本地缓存图
      final staleUser = ref.read(userProvider).value;
      if (staleUser != null) {
        ref.read(userProvider.notifier).setUser(staleUser.copyWith(avatar: '_local_cache_'));
      }
    } catch (e) {
      debugPrint('[AvatarCache] 写入临时缓存失败: $e');
    }

    try {
      final apiService = ref.read(apiServiceProvider);
      final resp = await apiService.uploadAvatar(bytes, fileName);
      if (resp.isSuccess && resp.data != null) {
        final String? newAvatarUrl = resp.data!['url'] as String?
            ?? resp.data!['avatar'] as String?
            ?? resp.data!['data'] as String?;
        debugPrint('[AvatarUpload] URL from response: $newAvatarUrl');

        if (newAvatarUrl != null) {
          // 持久化到 Hive，覆盖安装后还能从 Hive 恢复 URL
          final storageService = ref.read(storageServiceProvider);
          await storageService.setCachedAvatarUrl(newAvatarUrl);

          final currentUser = ref.read(userProvider).value;
          if (currentUser != null) {
            // 更新真实 URL（本地缓存图继续显示，不打断）
            ref.read(userProvider.notifier).setUser(
              currentUser.copyWith(avatar: newAvatarUrl),
            );
          }
        }

        // 后台同步（不 await，避免 loading 覆盖）
        ref.read(userProvider.notifier).loadUserProfile();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('头像上传成功'), behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传失败: ${resp.message}'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      debugPrint('[AvatarUpload] 上传异常: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context, AppLocalizations l10n, User? user, WidgetRef ref) async {
    final api = ref.read(apiServiceProvider);
    int? currentGender;
    String? currentEmail;
    double? currentWeight;
    int? currentHeight;
    try {
      final resp = await api.getUserProfile();
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data!;
        currentGender = data['gender'] as int?;
        currentEmail = data['email'] as String?;
        currentWeight = (data['weight'] as num?)?.toDouble();
        currentHeight = data['height'] as int?;
      }
    } catch (_) {}

    final nicknameController = TextEditingController(text: user?.nickname ?? '');
    final bioController = TextEditingController(text: user?.bio ?? '');
    final emailController = TextEditingController(text: currentEmail ?? '');
    final weightController = TextEditingController(text: currentWeight?.toString() ?? '');
    final heightController = TextEditingController(text: currentHeight?.toString() ?? '');
    int selectedGender = currentGender ?? 2;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('编辑资料'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '个人简介',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: '性别',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('女')),
                    DropdownMenuItem(value: 1, child: Text('男')),
                    DropdownMenuItem(value: 2, child: Text('保密')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => selectedGender = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '身高 (cm)',
                    hintText: '例如 175',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '体重 (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final weightText = weightController.text.trim();
                final weightValue = weightText.isNotEmpty ? double.tryParse(weightText) : null;
                final heightText = heightController.text.trim();
                final heightValue = heightText.isNotEmpty ? int.tryParse(heightText) : null;
                final error = await ref.read(userProvider.notifier).updateProfile(
                  nickname: nicknameController.text.trim(),
                  bio: bioController.text.trim(),
                  gender: selectedGender,
                  height: heightValue,
                  weight: weightValue,
                  email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                );
                if (context.mounted) {
                  if (error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('更新成功'), behavior: SnackBarBehavior.floating),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('更新失败: $error'), behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, AppLocalizations l10n, User? user) {
    final distance = (user?.totalDistanceKm ?? 0).toStringAsFixed(1);
    final runs = (user?.totalRuns ?? 0).toString();
    final hours = ((user?.totalDurationSeconds ?? 0) / 3600).toStringAsFixed(1);

    return Transform.translate(
      offset: Offset(0, -20.h),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(value: distance, unit: l10n.km, label: l10n.totalDistance),
                _StatItem(value: runs, unit: l10n.times, label: l10n.totalRuns),
                _StatItem(value: hours, unit: l10n.hours, label: l10n.totalDuration),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _MenuItem _buildPaojingMenuItem(BuildContext context, WidgetRef ref) {
    final paojingAsync = ref.watch(paojingProvider);
    String subtitle;
    if (paojingAsync.isLoading || paojingAsync.hasError) {
      subtitle = '修仙十三境 · 加载中...';
    } else {
      final earned = paojingAsync.value?.earnedCount ?? 0;
      subtitle = '修仙十三境 · $earned/13已点亮';
    }
    return _MenuItem(
      icon: Icons.auto_awesome,
      title: '我的跑境',
      subtitle: subtitle,
      onTap: () => context.push('/profile/paojing'),
    );
  }

  _MenuItem _buildFriendsMenuItem(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final countAsync = ref.watch(followingCountProvider);
    final count = countAsync.valueOrNull ?? 0;
    final subtitle = count > 0 ? '$count 位关注' : '暂无关注';
    return _MenuItem(
      icon: Icons.people,
      title: l10n.friends,
      subtitle: subtitle,
      onTap: () => context.push('/profile/friends'),
    );
  }

  _MenuItem _buildChallengeMenuItem(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final challengesAsync = ref.watch(myChallengesProvider);
    final userAsync = ref.watch(userProvider);
    final userId = userAsync.value?.id;

    String subtitle;
    if (challengesAsync.isLoading) {
      subtitle = '加载中...';
    } else if (challengesAsync.hasError) {
      subtitle = '加载失败';
    } else {
      final items = challengesAsync.value ?? [];
      final total = items.length;
      int winCount = 0;
      if (userId != null) {
        for (final item in items) {
          if (item.resultFor(userId) == 'win') winCount++;
        }
      }
      subtitle = '$total${l10n.times}挑战 · $winCount${l10n.times}胜利';
    }

    return _MenuItem(
      icon: Icons.emoji_events,
      title: l10n.challengeRecord,
      subtitle: subtitle,
      onTap: () => context.push('/profile/challenges'),
    );
  }

  Widget _buildMenuSection(BuildContext context, List<_MenuItem> items) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: context.dividerColor),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(entry.value.icon, color: AppColors.orange, size: 20.sp),
                ),
                title: Text(
                  entry.value.title,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                ),
                subtitle: entry.value.subtitle != null
                    ? Text(entry.value.subtitle!, style: TextStyle(fontSize: 12.sp, color: context.textSecondary))
                    : null,
                trailing: Icon(Icons.chevron_right, color: context.textTertiary),
                onTap: entry.value.onTap,
              ),
              if (!isLast) const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改密码'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '旧密码',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '新密码',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '确认新密码',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldPwd = oldPasswordController.text.trim();
              final newPwd = newPasswordController.text.trim();
              final confirmPwd = confirmPasswordController.text.trim();

              if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写完整信息'), behavior: SnackBarBehavior.floating),
                );
                return;
              }
              if (newPwd != confirmPwd) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次输入的新密码不一致'), behavior: SnackBarBehavior.floating),
                );
                return;
              }
              if (newPwd.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('密码长度至少为6位'), behavior: SnackBarBehavior.floating),
                );
                return;
              }

              Navigator.pop(ctx);
              final error = await ref.read(userProvider.notifier).changePassword(
                oldPassword: oldPwd,
                newPassword: newPwd,
              );
              if (context.mounted) {
                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码修改成功'), behavior: SnackBarBehavior.floating),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('修改失败: $error'), behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8533).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: const Icon(Icons.directions_run, color: Color(0xFFFF8533), size: 18),
            ),
            SizedBox(width: 12.w),
            Text(l10n.aboutApp, style: TextStyle(color: Colors.white, fontSize: 17.sp)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '驰陌 / StrideMoor',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              '驰于阡陌，自在奔跑',
              style: TextStyle(color: Colors.white54, fontSize: 13.sp),
            ),
            SizedBox(height: 4.h),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (ctx, snap) {
                final ver = snap.data?.version ?? '2.0.9';
                return Text(
                  'v$ver',
                  style: TextStyle(color: Colors.white30, fontSize: 12.sp),
                );
              },
            ),
            SizedBox(height: 16.h),
            const Divider(color: Colors.white10),
            SizedBox(height: 12.h),
            Text(
              '以路线为锚点，用数据对比帮助朋友改进跑步技术，有目标地跑步。',
              style: TextStyle(color: Colors.white38, fontSize: 12.sp, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _StatItem({required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.orange),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Text(label, style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
