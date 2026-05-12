import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/run.dart';
import '../modules/discover/discover_page.dart';
import '../modules/discover/feed_page.dart';
import '../modules/discover/post_detail_page.dart';
import '../modules/discover/run_detail_page.dart';
import '../modules/discover/run_history_page.dart';
import '../modules/discover/route_detail_page.dart';
import '../modules/discover/route_square_page.dart';
import '../modules/discover/route_leaderboard_page.dart';
import '../modules/discover/challenge_ranking_page.dart';
import '../modules/profile/broadcast_settings_page.dart';
import '../modules/auth/login_page.dart';
import '../modules/auth/register_page.dart';
import '../modules/profile/challenge_history_page.dart';
import '../modules/profile/device_management_page.dart';
import '../modules/profile/import_history_page.dart';
import '../modules/profile/friends_page.dart';
import '../modules/profile/friend_detail_page.dart';
import '../modules/profile/paojing_page.dart';
import '../modules/profile/profile_page.dart';
import '../modules/profile/settings_page.dart';
import '../modules/profile/running_stats_page.dart';
import '../modules/run/gps_search_page.dart';
import '../modules/run/run_finish_page.dart';
import '../modules/run/run_preparation_page.dart';
import '../modules/run/running_page.dart';
import '../modules/routes/comparison_report_page.dart';
import '../modules/routes/my_routes_page.dart';
import '../modules/routes/nearby_routes_page.dart';
import '../modules/run/run_trace_select_page.dart';
import '../modules/routes/routes_home_page.dart';
import '../modules/routes/upload_route_page.dart';
import '../widgets/shell_scaffold.dart';
import '../core/providers/user_provider.dart';

/// 全局路由配置 Provider
final routerProvider = Provider<GoRouter>((ref) {
  // 监听用户状态变化，触发路由重定向重新评估
  final refreshNotifier = ValueNotifier<bool>(false);
  ref.listen(userProvider, (prev, next) {
    refreshNotifier.value = !refreshNotifier.value;
  });

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final userAsync = ref.read(userProvider);
      final isLoading = userAsync is AsyncLoading;
      final isLoggedIn = userAsync.value != null;
      final path = state.uri.path;
      final isAuthPage = path == '/login' || path == '/register';

      // 加载中不执行重定向，避免自动登录过程中跳转
      if (isLoading) return null;

      // 未登录且访问非认证页 → 去登录
      if (!isLoggedIn && !isAuthPage) return '/login';

      // 已登录且访问认证页 → 去首页
      if (isLoggedIn && isAuthPage) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      // 底部导航壳 — 发现 / 运动 / 跑迹 / 我的
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 发现 Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DiscoverPage(),
                routes: [
                  GoRoute(
                    path: 'feed',
                    builder: (context, state) => const FeedPage(),
                  ),
                  GoRoute(
                    path: 'post/:postId',
                    builder: (context, state) {
                      final postId = state.pathParameters['postId']!;
                      return PostDetailPage(postId: postId);
                    },
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const RunHistoryPage(),
                  ),
                  GoRoute(
                    path: 'run/:runId',
                    builder: (context, state) {
                      final runId = state.pathParameters['runId']!;
                      return RunDetailPage(runId: runId);
                    },
                  ),
                  GoRoute(
                    path: 'square',
                    builder: (context, state) => const RouteSquarePage(),
                  ),
                  GoRoute(
                    path: 'route/:routeId',
                    builder: (context, state) {
                      final routeId = state.pathParameters['routeId']!;
                      return RouteDetailPage(routeId: routeId);
                    },
                    routes: [
                      GoRoute(
                        path: 'leaderboard',
                        builder: (context, state) {
                          final routeId = state.pathParameters['routeId']!;
                          return RouteLeaderboardPage(routeId: routeId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'ranking',
                    builder: (context, state) => const ChallengeRankingPage(),
                  ),
                ],
              ),
            ],
          ),
          // 运动 Tab (占位，点击直接跳转准备页)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/run',
                builder: (context, state) => const RunPreparationPage(),
                routes: [
                  GoRoute(
                    path: 'gps',
                    builder: (context, state) => const GpsSearchPage(),
                  ),
                  GoRoute(
                    path: 'ongoing',
                    builder: (context, state) => const RunningPage(),
                  ),
                  GoRoute(
                    path: 'finish',
                    builder: (context, state) {
                      final run = state.extra as Run?;
                      return RunFinishPage(run: run);
                    },
                  ),
                ],
              ),
            ],
          ),
          // 跑迹 Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/routes',
                builder: (context, state) => const RoutesHomePage(),
                routes: [
                  GoRoute(
                    path: 'my',
                    builder: (context, state) => const MyRoutesPage(),
                  ),
                  GoRoute(
                    path: 'nearby',
                    builder: (context, state) => const NearbyRoutesPage(),
                  ),
                  GoRoute(
                    path: 'upload',
                    builder: (context, state) => const UploadRoutePage(),
                  ),
                  GoRoute(
                    path: 'comparison',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return ComparisonReportPage(
                        runA: extra?['runA'],
                        runB: extra?['runB'],
                      );
                    },
                  ),
                  GoRoute(
                    path: 'friends/select',
                    builder: (context, state) => const RunTraceSelectPage(),
                  ),
                ],
              ),
            ],
          ),
          // 我的 Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'broadcast',
                    builder: (context, state) => const BroadcastSettingsPage(),
                  ),
                  GoRoute(
                    path: 'challenges',
                    builder: (context, state) => const ChallengeHistoryPage(),
                  ),
                  GoRoute(
                    path: 'stats',
                    builder: (context, state) => const RunningStatsPage(),
                  ),
                  GoRoute(
                    path: 'devices',
                    builder: (context, state) => const DeviceManagementPage(),
                  ),
                  GoRoute(
                    path: 'imports',
                    builder: (context, state) => const ImportHistoryPage(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsPage(),
                  ),
                  GoRoute(
                    path: 'paojing',
                    builder: (context, state) => const PaojingPage(),
                  ),
                  GoRoute(
                    path: 'friends',
                    builder: (context, state) => const FriendsPage(),
                    routes: [
                      GoRoute(
                        path: ':userId',
                        builder: (context, state) {
                          final userId = state.pathParameters['userId']!;
                          final nickname = state.extra as String? ?? '未知跑友';
                          return FriendDetailPage(userId: userId, nickname: nickname);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
