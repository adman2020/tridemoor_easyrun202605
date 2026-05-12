import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/providers/paojin_provider.dart';

/// 我的跑境 —— 修仙跑者勋章墙
/// 华为健康风格，深色背景 + 暖金橘点缀
class PaojingPage extends ConsumerStatefulWidget {
  const PaojingPage({super.key});

  @override
  ConsumerState<PaojingPage> createState() => _PaojingPageState();
}

class _PaojingPageState extends ConsumerState<PaojingPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时自动拉取跑境数据
    Future.microtask(() => ref.read(paojingProvider.notifier).loadPaojing());
  }

  @override
  Widget build(BuildContext context) {
    final paojingAsync = ref.watch(paojingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '我的跑境',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: paojingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8533)),
        ),
        error: (error, _) => _buildError(error.toString()),
        data: (data) {
          if (data == null) {
            return _buildError('暂无跑境数据');
          }
          return _buildContent(data);
        },
      ),
    );
  }

  /// 错误状态
  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.white38, size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () => ref.read(paojingProvider.notifier).loadPaojing(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8533),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 主内容
  Widget _buildContent(PaojingData data) {
    final earned = data.earnedCount;
    final currentChar = data.currentChar;
    final currentName = data.currentName;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ======== 当前境界头部 ========
        SliverToBoxAdapter(child: _buildRealmHeader(currentChar, currentName, earned)),

        // ======== 跑境修炼进度条 ========
        SliverToBoxAdapter(child: _buildProgressBar(earned)),

        // ======== 勋章方格区 ========
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final badge = data.badges[index];
                return _buildBadgeCard(badge);
              },
              childCount: data.badges.length,
            ),
          ),
        ),

        // ======== 底部留白 ========
        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
      ],
    );
  }

  /// 当前境界头部
  Widget _buildRealmHeader(String char, String name, int earned) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x26FF8533),
            Color(0xFF252528),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0x4DFF8533)),
      ),
      child: Row(
        children: [
          // 跑境图标（100px lit 版）
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8533).withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/badges/paojing_small/${char}_100.png',
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前境界',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white54,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '已点亮 $earned/13 境',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFFFFAA66),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.auto_awesome, color: const Color(0xFFFFAA66), size: 28.sp),
        ],
      ),
    );
  }

  /// 跑境修炼进度条
  Widget _buildProgressBar(int earned) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '跑境修炼',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${(earned / 13 * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFAA66),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: earned / 13,
              minHeight: 6.h,
              backgroundColor: const Color(0xFF252528),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8533)),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  /// 单枚徽章卡片
  Widget _buildBadgeCard(PaojingBadge badge) {
    final isEarned = badge.earned;
    final shortName = badge.name.replaceAll('勋章', '');

    return Container(
      decoration: BoxDecoration(
        color: isEarned ? const Color(0xFF252528) : const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isEarned
              ? const Color(0x4DFF8533)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: const Color(0xFFFF8533).withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 勋章图标
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.asset(
              isEarned
                  ? 'assets/badges/paojing_small/${badge.char}_100.png'
                  : 'assets/badges/paojing_dim/${badge.char}_dim_80.png',
              width: 72.w,
              height: 72.w,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 6.h),
          // 境界名
          Text(
            shortName,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isEarned ? Colors.white : Colors.white38,
            ),
          ),
          SizedBox(height: 2.h),
          // 状态标签
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isEarned
                  ? const Color(0xFFFF8533).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              isEarned ? '已点亮' : '未激活',
              style: TextStyle(
                fontSize: 9.sp,
                color: isEarned ? const Color(0xFFFFAA66) : Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
