import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/providers/paojin_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/user.dart';
import 'feed_page.dart';

/// 发现页 —— 首页 Feed + 入口聚合
/// 适配 A版暗色 + C版亮色 双主题
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  int _quoteRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    // 页面加载时自动拉取跑境数据（跟 PaojingPage 一致）
    Future.microtask(() => ref.read(paojingProvider.notifier).loadPaojing());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, l10n, user)),
          SliverToBoxAdapter(child: _buildQuickActions(context, l10n)),
          SliverToBoxAdapter(child: _buildAchievements(context, ref, user)),
          // 跑友动态标题
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.feed, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: context.textPrimary)),
                  TextButton(
                    onPressed: () => context.push('/feed'),
                    child: Text(l10n.more, style: TextStyle(fontSize: 13.sp, color: AppColors.orange)),
                  ),
                ],
              ),
            ),
          ),
          _buildFeedList(context, ref),
          SliverPadding(padding: EdgeInsets.only(bottom: 32.h)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, User? user) {
    final isDark = context.isDark;
    return Container(
      color: context.bgColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 品牌栏
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50.r),
                      child: Image.asset(
                        isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_minimal.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // 品牌名
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: isDark ? [AppColors.orange, AppColors.mint] : [AppColors.orange, AppColors.navy],
                        ).createShader(bounds),
                        child: Text(l10n.appName, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
                      ),
                      Text(l10n.appNameEN, style: TextStyle(fontSize: 8.sp, color: context.textTertiary, letterSpacing: 1)),
                    ],
                  ),
                  const Spacer(),
                  // 铃铛
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.notificationDev),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(50.r),
                        border: Border.all(color: context.dividerColor),
                      ),
                      child: Icon(Icons.notifications_none, color: context.textSecondary, size: 18.sp),
                    ),
                  ),
                ],
              ),
            ),
            // Slogan
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDark ? [AppColors.orange, AppColors.mint] : [AppColors.orange, AppColors.navy],
                      ).createShader(bounds),
                      child: Text(l10n.slogan, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                    ),
                    SizedBox(height: 6.h),
                    Text(l10n.sloganEN, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, color: context.textTertiary, letterSpacing: 3)),
                  ],
                ),
              ),
            ),
            // 本周数据概览
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: context.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(child: _StatItem(label: l10n.km, subLabel: l10n.totalDistance, value: (user?.totalDistanceKm ?? 0).toStringAsFixed(1))),
                    _VerticalDivider(),
                    Expanded(child: _StatItem(label: l10n.times, subLabel: l10n.runs, value: (user?.totalRuns ?? 0).toString())),
                    _VerticalDivider(),
                    Expanded(child: _StatItem(label: l10n.hours, subLabel: l10n.totalDuration, value: ((user?.totalDurationSeconds ?? 0) / 3600).toStringAsFixed(1))),
                    _VerticalDivider(),
                    Expanded(child: _StatItem(label: l10n.calories, subLabel: l10n.totalCalories, value: (user?.totalCalories ?? 0).toString())),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    final isDark = context.isDark;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.history, label: l10n.actionRecord,
              gradient: [AppColors.orange, AppColors.orangeLight],
              onTap: () => context.push('/history'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _ActionCard(
              icon: Icons.map, label: l10n.actionSquare,
              gradient: isDark ? [AppColors.mint, const Color(0xFF00D4AA)] : [AppColors.navy, const Color(0xFF2E5A8C)],
              onTap: () => context.push('/square'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _ActionCard(
              icon: Icons.emoji_events, label: l10n.actionRanking,
              gradient: [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
              onTap: () => context.push('/ranking'),
            ),
          ),
        ],
      ),
    );
  }



  // ======== 13境定义（与 境界-配速體系.md 一致） ========
  static const _realms = [
    _Realm('气', '气引', '跑过即是气引', 0, null),
    _Realm('筑', '筑仙', '单次≥5km', 5.0, null),
    _Realm('丹', '丹凝', '单次≥10km', 10.0, null),
    _Realm('婴', '婴生', '单次≥21.1km（半马）', 21.0975, null),
    _Realm('化', '化神', '单次≥42.2km（全马）', 42.195, null),
    _Realm('虚', '炼虚', '全马<3:00（配速<4:15/km）', 42.195, 10800),   // 3h
    _Realm('合', '合元', '全马<2:45', 42.195, 9900),    // 2:45
    _Realm('乘', '大乘', '全马<2:30', 42.195, 9000),    // 2:30
    _Realm('真', '真仙', '全马<2:20', 42.195, 8400),    // 2:20
    _Realm('金', '金仙', '全马<2:15', 42.195, 8100),    // 2:15
    _Realm('太', '太乙', '全马<2:10', 42.195, 7800),    // 2:10
    _Realm('罗', '大罗', '全马<2:05', 42.195, 7500),    // 2:05
    _Realm('道', '道祖', '全马<2:00', 42.195, 7200),    // 2:00
  ];

  // char → index 映射
  static Map<String, int> get _realmIndices {
    final map = <String, int>{};
    for (int i = 0; i < _realms.length; i++) {
      map[_realms[i].char] = i;
    }
    return map;
  }

  /// 跑境成就栏（使用后端 paojing 接口，跟「我的跑境」一致）
  Widget _buildAchievements(BuildContext context, WidgetRef ref, User? user) {
    final paojingAsync = ref.watch(paojingProvider);
    final paojingData = paojingAsync.valueOrNull;

    // 提取数据：优先用后端，没有后备
    var badges = paojingData?.badges ?? [];
    final currentName = paojingData?.currentName ?? (user != null ? '气引' : '');
    final currentRealm = paojingData?.currentRealm ?? 0;
    final hasData = user != null && user.totalRuns > 0;

    // 修复后端空badges问题：确保当前境界已点亮
    if (paojingData != null && badges.isNotEmpty) {
      final fixed = badges.map((b) {
        final realmIdx = _realmIndices[b.char] ?? 999;
        return PaojingBadge(char: b.char, name: b.name, earned: b.earned || realmIdx <= currentRealm);
      }).toList();
      badges = fixed;
    }

    final earnedCount = badges.where((b) => b.earned).length;
    final nextRule = paojingData?.nextRule;
    final progress = paojingData?.progress ?? (earnedCount / 13);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
      child: GestureDetector(
        onTap: () => context.push('/profile/paojing'),
        child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 12.w),
              child: Row(
                children: [
                  Container(
                    width: 32.w, height: 32.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.orange, AppColors.orangeLight],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 16.sp),
                  ),
                  SizedBox(width: 10.w),
                  Text('当前跑境 · $currentName',
                      style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: context.textPrimary)),
                  const Spacer(),
                  Text('$earnedCount/13',
                      style: TextStyle(fontSize: 12.sp, color: context.textTertiary)),
                ],
              ),
            ),
            // 进度条
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress, minHeight: 6.h,
                      backgroundColor: context.dividerColor,
                      valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  if (nextRule != null)
                    Text(_buildNextRuleText(nextRule!),
                        style: TextStyle(fontSize: 12.sp, color: context.textTertiary))
                  else if (hasData && nextRule == null && earnedCount >= 13)
                    Text('十三境圆满，跑道之祖！',
                        style: TextStyle(fontSize: 13.sp, color: AppColors.orange))
                  else if (!hasData)
                    Text('跑起来，开启你的跑境之路',
                        style: TextStyle(fontSize: 12.sp, color: context.textTertiary)),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            // 勋章横滑
            SizedBox(
              height: 68.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                itemCount: badges.isNotEmpty ? badges.length : _realms.length,
                itemBuilder: (context, index) {
                  if (badges.isNotEmpty) {
                    final b = badges[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: GestureDetector(
                        onTap: b.earned ? null : () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${b.name}：${b.char}境'),
                            duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              b.earned
                                  ? 'assets/badges/paojing_small/${b.char}_80.png'
                                  : 'assets/badges/paojing_dim/${b.char}_dim_80.png',
                              width: 46.w, height: 46.w,
                              errorBuilder: (_, __, ___) => Container(
                                width: 46.w, height: 46.w,
                                decoration: BoxDecoration(
                                  color: context.dividerColor,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Center(child: Text(b.char, style: TextStyle(fontSize: 16.sp, color: context.textTertiary))),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(b.char, style: TextStyle(fontSize: 10.sp,
                                color: b.earned ? context.textPrimary : context.textTertiary)),
                          ],
                        ),
                      ),
                    );
                  }
                  // 无后端数据时用本地
                  final r = _realms[index];
                  final isUnlocked = index == 0; // 至少第一境
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          isUnlocked
                              ? 'assets/badges/paojing_small/${r.char}_80.png'
                              : 'assets/badges/paojing_dim/${r.char}_dim_80.png',
                          width: 46.w, height: 46.w,
                          errorBuilder: (_, __, ___) => Container(
                            width: 46.w, height: 46.w,
                            decoration: BoxDecoration(
                              color: context.dividerColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(child: Text(r.char, style: TextStyle(fontSize: 16.sp, color: context.textTertiary))),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(r.char, style: TextStyle(fontSize: 10.sp,
                            color: isUnlocked ? context.textPrimary : context.textTertiary)),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8.h),
            // 金句区
            Divider(height: 1, color: context.dividerColor),
            GestureDetector(
              onTap: () {
                // 重新随机一条金句
                setState(() => _quoteRefreshKey++);
              },
              child: Padding(
                padding: EdgeInsets.all(16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28.w, height: 28.w,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.auto_awesome, size: 14.sp, color: AppColors.orange),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_dailyQuote(currentRealm),
                            style: TextStyle(fontSize: 15.sp, color: context.textPrimary, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                        SizedBox(height: 4.h),
                        Text(_dailyTip(currentRealm),
                            style: TextStyle(fontSize: 12.sp, color: context.textTertiary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
      ),
    );
  }



  /// 每日金句（按境界分层 + 每日候选池 + 随机取）
  String _dailyQuote(int realm) {
    final tierQuotes = [
      // Tier 0: 新手激励 (realm 0-2)
      [
        '千里之行，始于足下',
        '跑过的路，每一步都算数',
        '跑得慢没关系，跑得久才见真章',
        '不为赶路，只为感受路',
        '今天迈出第一步，就是最好的开始',
        '跑步没有捷径，但每一步都在靠近',
        '别怕慢，坚持就是速度',
        '脚下的路，会记得你的努力',
        '用脚步丈量世界，从今天开始',
        '每一次出发，都比原地踏步强',
      ],
      // Tier 1: 进阶鼓励 (realm 3-5)
      [
        '今日的汗水，是明天的勋章',
        '马拉松不是一场比赛，是一场修行',
        '跑出去，世界就是你的',
        '心有跑境，足下有风',
        '半马是起点，全马是考验',
        '突破舒适区，才能遇见更强的自己',
        '真正的对手，是昨天的自己',
        '每一次长跑，都是一次自我对话',
        '跑过风雨，才能看到不一样的风景',
        '速度和距离不重要，坚持跑下去才重要',
      ],
      // Tier 2: 高手境界 (realm 6-8)
      [
        '风雨无阻，方见彩虹',
        '脚步所向，皆是坦途',
        '驰于阡陌，自在奔跑',
        '跑过春夏秋冬，方知岁月静好',
        '配速是数字，心境才是境界',
        '每一步都在书写自己的传奇',
        '跑步的最高境界，是和自己和解',
        '耐得住寂寞，才守得住繁华',
        '赛道上的对手，只有自己',
        '三小时的全马，需要全身心的投入',
      ],
      // Tier 3: 巅峰之语 (realm 9-12)
      [
        '登峰造极，不过是一场新的开始',
        '道法自然，跑亦如此',
        '脚步即道，每一步都是修行',
        '我跑故我在',
        '速度的极致，是内心的宁静',
        '不求与人相比，只求超越自己',
        '道祖之路，永无止境',
        '十三境之上，仍有星辰大海',
      ],
    ];

    final tierIndex = realm < 3 ? 0 : realm < 6 ? 1 : realm < 9 ? 2 : 3;
    final tierPool = tierQuotes[tierIndex];
    // 从该层级每天取 4 条候选，再随机抽 1 条
    final poolSize = 4;
    final day = DateTime.now().day;
    final groupStart = (day * 3) % (tierPool.length - poolSize);
    final dailyPool = tierPool.sublist(groupStart, groupStart + poolSize);
    return dailyPool[Random().nextInt(dailyPool.length)];
  }

  /// 每日小贴士（按境界分层 + 每日候选池 + 随机取）
  String _dailyTip(int realm) {
    final tierTips = [
      // Tier 0: 新手 (realm 0-2)
      [
        '慢慢来，比较快',
        '保持节奏，比冲刺更重要',
        '先跑起来，再谈速度',
        '每一次出发，都是新的开始',
        '跑两公里也是英雄',
        '不用跟别人比，跟昨天的自己比',
        '坚持本身就是胜利',
        '心率稳了，配速自然会上去',
        '别想太远，先完成今天这一跑',
        '跑步最好的时机，就是现在',
      ],
      // Tier 1: 进阶 (realm 3-5)
      [
        '心有跑境，足下有风',
        '跑步是最好的修行',
        '汗水不会骗人',
        '跑起来，风会拥抱你',
        '半马不是终点，是新的起点',
        '步频稳定，长跑无忧',
        '学会倾听身体的声音',
        '配速是练出来的，不是想出来的',
        '每一公里都是积累',
        '跑步没有奇迹，只有积累',
      ],
      // Tier 2: 高手 (realm 6-8)
      [
        '路在脚下，境在心中',
        '跑过春夏秋冬，方知岁月静好',
        '全马不是极限，是开始',
        '控制配速，就是控制比赛',
        '核心力量是长跑的基石',
        '学会分配体力，比拼命更重要',
        '跑得好，不如跑得稳',
        '每一次PB，都是对过去的告别',
        '高强度训练和恢复同样重要',
        '用数据说话，但不要被数据束缚',
      ],
      // Tier 3: 巅峰 (realm 9-12)
      [
        '道在脚下，无需远求',
        '跑过千山万水，归来仍是少年',
        '速度是表象，境界是本质',
        '身体有极限，但意志没有',
        '真正的自由，是掌控自己的身体',
        '跑者的修行，永无止境',
        '最好的对手，是昨日的自己',
        '超越极限的那一刻，你已不是原来的你',
        '道祖之路，每一步都是风景',
      ],
    ];

    final tierIndex = realm < 3 ? 0 : realm < 6 ? 1 : realm < 9 ? 2 : 3;
    final tierPool = tierTips[tierIndex];
    // 从该层级每天取 4 条候选，再随机抽 1 条
    final poolSize = min(4, tierPool.length);
    final day = DateTime.now().day;
    final groupStart = (day * 7) % (tierPool.length - poolSize);
    final dailyPool = tierPool.sublist(groupStart, groupStart + poolSize);
    return dailyPool[Random().nextInt(dailyPool.length)];
  }

  String _buildNextRuleText(Map<String, dynamic> rule) {
    final type = rule['type'] as String? ?? '';
    final current = rule['current'] as String? ?? '';
    final target = rule['target'] as String? ?? '';
    if (type == 'distance') {
      return '距下一境还需单次跑 $target（当前最长 $current）';
    } else if (type == 'marathon_pace') {
      return '距下一境还需全马跑进 $target（当前 $current）';
    }
    return target.isNotEmpty ? '距下一境：$target' : '';
  }

  Widget _buildFeedList(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postListProvider(1));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Center(
                child: Text(
                  '暂无动态，快去分享你的跑步记录吧！',
                  style: TextStyle(fontSize: 14.sp, color: context.textSecondary),
                ),
              ),
            ),
          );
        }
        final displayPosts = posts.take(4).toList();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = displayPosts[index];
              return FeedCard(
                post: post,
                onTap: () => context.push('/post/${post.id}'),
              );
            },
            childCount: displayPosts.length,
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Center(
            child: SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
            ),
          ),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Center(
            child: Text(
              '加载失败: $err',
              style: TextStyle(fontSize: 13.sp, color: context.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// 跑境界定
class _Realm {
  final String char;
  final String name;
  final String condition;
  final double minKm; // 单次最小距离
  final int? maxMarathonSec; // 全马最慢用时（秒），null表示不限制

  const _Realm(this.char, this.name, this.condition, this.minKm, this.maxMarathonSec);

  bool unlocked(double bestKm, int? bestMarathonSec) {
    if (bestKm < minKm) return false;
    if (maxMarathonSec != null && bestMarathonSec == null) return false;
    if (maxMarathonSec != null && bestMarathonSec! > maxMarathonSec!) return false;
    return true;
  }
}

// ===== 子组件（全部使用 context 扩展，不再传 isDark 参数）=====

class _StatItem extends StatelessWidget {
  final String label;
  final String subLabel;
  final String value;
  const _StatItem({required this.label, required this.subLabel, required this.value});

  @override
  Widget build(BuildContext context) {
    // 根据数值长度自动缩放字号，避免溢出
    final fontSize = value.length > 7
        ? 16.sp
        : value.length > 5
            ? 20.sp
            : value.length > 3
                ? 24.sp
                : 28.sp;

    return Column(
      children: [
        Text(subLabel, style: TextStyle(fontSize: 11.sp, color: context.textTertiary)),
        SizedBox(height: 4.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: context.textPrimary)),
                TextSpan(text: ' $label', style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40.h, color: context.dividerColor);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48.w, height: 48.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(height: 10.h),
            Text(label, style: TextStyle(fontSize: 13.sp, color: context.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}




