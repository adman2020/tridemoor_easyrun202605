import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/theme.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/api_service.dart';

/// VIP 等级名称
const _vipTierNames = {
  1: '白银',
  2: '黄金',
  3: '钻石',
  4: '星耀',
  5: '王者',
};

/// VIP 等级图标
const _vipTierIcons = {
  1: '🥈',
  2: '🥇',
  3: '💎',
  4: '⭐',
  5: '👑',
};

/// AI 功能项数据
class _AIFeatureItem {
  final String id;
  final String name;
  final String description;
  final int minVipTier;
  final String icon;
  final bool unlocked;

  _AIFeatureItem({
    required this.id,
    required this.name,
    required this.description,
    required this.minVipTier,
    required this.icon,
    required this.unlocked,
  });

  factory _AIFeatureItem.fromJson(Map<String, dynamic> json) {
    return _AIFeatureItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      minVipTier: (json['min_vip_tier'] as num).toInt(),
      icon: json['icon'] as String,
      unlocked: json['unlocked'] as bool,
    );
  }
}

/// 设置页 —— AI智能功能权益展示
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final ApiService _api;
  late Future<_FetchResult> _fetchFuture;

  @override
  void initState() {
    super.initState();
    _api = ref.read(apiServiceProvider);
    _fetchFuture = _fetch();
  }

  Future<_FetchResult> _fetch() async {
    final res = await _api.getAIFeatures();
    if (res.isSuccess && res.data != null) {
      final features = (res.data!['features'] as List)
          .map((f) => _AIFeatureItem.fromJson(f as Map<String, dynamic>))
          .toList();
      return _FetchResult(
        vipTier: (res.data!['vip_tier'] as num).toInt(),
        isVip: res.data!['is_vip'] as bool,
        features: features,
      );
    }
    throw Exception('获取AI功能列表失败');
  }

  String _vipTierName(int tier) => _vipTierNames[tier] ?? '普通';
  String _vipTierIcon(int tier) => _vipTierIcons[tier] ?? '🏅';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: FutureBuilder<_FetchResult>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  SizedBox(height: 12.h),
                  Text('加载失败', style: TextStyle(color: context.textSecondary)),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => setState(() => _fetchFuture = _fetch()),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final result = snapshot.data!;

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              // ========== VIP 权益卡片 ==========
              if (result.isVip) _buildVipCard(result.vipTier),

              // ========== AI智能功能 ==========
              SizedBox(height: 24.h),
              _buildSectionHeader('AI智能功能', Icons.smart_toy_outlined),
              SizedBox(height: 8.h),
              ...result.features.map((f) => _buildFeatureItem(f)),
              SizedBox(height: 24.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVipCard(int vipTier) {
    final name = _vipTierName(vipTier);
    final icon = _vipTierIcon(vipTier);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withOpacity(0.15),
            AppColors.orange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // VIP 图标
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(icon, style: TextStyle(fontSize: 28.sp)),
          ),
          SizedBox(width: 16.w),
          // VIP 名称 + 提示
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$name会员',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'VIP $vipTier',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '已解锁 $vipTier 项 AI 功能权益',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.orange),
        SizedBox(width: 6.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(_AIFeatureItem feature) {
    final unlocked = feature.unlocked;
    final tierName = _vipTierNames[feature.minVipTier] ?? 'VIP';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 功能图标
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppColors.orange.withOpacity(0.1)
                    : AppColors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: Text(feature.icon, style: TextStyle(fontSize: 20.sp)),
            ),
            SizedBox(width: 12.w),
            // 功能名称 + 描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: unlocked
                          ? context.textPrimary
                          : context.textSecondary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    feature.description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // 状态
            if (unlocked)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14.sp, color: AppColors.success),
                    SizedBox(width: 3.w),
                    Text(
                      '$tierName可用',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('VIP升级功能开发中，敬请期待'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14.sp, color: AppColors.orange),
                      SizedBox(width: 3.w),
                      Text(
                        '需 $tierName',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// API 返回数据封装
class _FetchResult {
  final int vipTier;
  final bool isVip;
  final List<_AIFeatureItem> features;

  _FetchResult({
    required this.vipTier,
    required this.isVip,
    required this.features,
  });
}
