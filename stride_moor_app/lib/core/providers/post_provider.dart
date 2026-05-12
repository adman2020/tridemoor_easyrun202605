import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/constants.dart';
import '../../core/models/post.dart';
import '../../core/models/user.dart';
import '../../core/models/run.dart';
import '../../core/services/api_service.dart';
import 'app_providers.dart';
import 'user_provider.dart';
import '../seed_data/routes_seed.dart';

/// Mock 动态数据（后端未就绪时使用）
List<Post> _mockPosts() {
  final now = DateTime.now();
  return [
    Post(
      id: 'post_1',
      userId: 'user_1',
      user: User(
        id: 'user_1',
        nickname: '东君',
        avatar: '',
      ),
      content: '今天晨跑8公里，天气不错！',
      createdAt: now.subtract(const Duration(hours: 2)),
      likeCount: 12,
      commentCount: 3,
      isLiked: false,
      run: Run(
        id: 'run_1',
        userId: 'user_1',
        startTime: now.subtract(const Duration(hours: 3)),
        endTime: now.subtract(const Duration(hours: 2)),
        totalDistance: 8000,
        totalTime: 2400,
        avgPace: 300,
        samples: [
          RunSample(latitude: 39.9042, longitude: 116.4074, timestamp: now.subtract(const Duration(hours: 3)), altitude: 50),
          RunSample(latitude: 39.9050, longitude: 116.4080, timestamp: now.subtract(const Duration(minutes: 150)), altitude: 52),
          RunSample(latitude: 39.9060, longitude: 116.4090, timestamp: now.subtract(const Duration(minutes: 120)), altitude: 51),
        ],
      ),
      route: myRoutesSeed[0], // 我的路线，点击收藏后会出现在跑友跑迹中
    ),
    Post(
      id: 'post_2',
      userId: 'user_2',
      user: User(
        id: 'user_2',
        nickname: '跑友小王',
        avatar: '',
      ),
      content: '坚持打卡第30天 💪',
      createdAt: now.subtract(const Duration(hours: 5)),
      likeCount: 28,
      commentCount: 8,
      isLiked: true,
      run: Run(
        id: 'run_2',
        userId: 'user_2',
        startTime: now.subtract(const Duration(hours: 6)),
        endTime: now.subtract(const Duration(hours: 5)),
        totalDistance: 5000,
        totalTime: 1500,
        avgPace: 300,
        samples: [
          RunSample(latitude: 39.9142, longitude: 116.4174, timestamp: now.subtract(const Duration(hours: 6)), altitude: 55),
          RunSample(latitude: 39.9150, longitude: 116.4180, timestamp: now.subtract(const Duration(minutes: 330)), altitude: 56),
        ],
      ),
    ),
  ];
}

/// 动态列表 Provider（带分页）
final postListProvider = FutureProvider.family<List<Post>, int>((ref, page) async {
  ref.watch(userProvider); // invalidate on user switch
  
  // devMode 或后端 404 时用 mock 数据
  if (AppConstants.devMode) {
    await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟
    return _mockPosts();
  }
  
  final api = ref.read(apiServiceProvider);
  try {
    final response = await api.getPostList(page: page, pageSize: 10);

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message);
    }

    final data = response.data!;
    final list = (data['list'] ?? data['posts'] ?? []) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Post.fromJson(e))
        .toList();
  } catch (e) {
    rethrow;
  }
});

/// 动态详情 Provider
final postDetailProvider = FutureProvider.family<Post, String>((ref, postId) async {
  ref.watch(userProvider);
  
  // devMode 或 mock ID 直接返回 mock
  if (AppConstants.devMode || postId.startsWith('post_')) {
    final mock = _mockPosts().firstWhere(
      (p) => p.id == postId,
      orElse: () => _mockPosts().first,
    );
    return mock;
  }
  
  final api = ref.read(apiServiceProvider);
  try {
    final response = await api.getPostDetail(postId);

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message);
    }

    final data = response.data!;
    final postJson = Map<String, dynamic>.from(data['post'] as Map<String, dynamic>? ?? data);
    return Post.fromJson(postJson);
  } catch (e) {
    rethrow;
  }
});

/// 评论列表 Provider
final postCommentsProvider = FutureProvider.family<List<PostComment>, String>((ref, postId) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.getComments(postId, page: 1, pageSize: 50);

  if (!response.isSuccess || response.data == null) {
    throw Exception(response.message);
  }

  final data = response.data!;
  final list = (data['list'] ?? data['comments'] ?? []) as List<dynamic>;
  return list
      .whereType<Map<String, dynamic>>()
      .map((e) => PostComment.fromJson(e))
      .toList();
});

/// 点赞/取消点赞状态管理
class LikePostNotifier extends StateNotifier<AsyncValue<bool>> {
  final ApiService _api;
  final String _postId;

  LikePostNotifier(this._api, this._postId) : super(const AsyncValue.data(false));

  Future<void> toggle(bool currentlyLiked) async {
    state = const AsyncValue.loading();
    try {
      if (currentlyLiked) {
        final resp = await _api.unlikePost(_postId);
        if (!resp.isSuccess) throw Exception(resp.message);
        state = const AsyncValue.data(false);
      } else {
        final resp = await _api.likePost(_postId);
        if (!resp.isSuccess) throw Exception(resp.message);
        state = const AsyncValue.data(true);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 单个帖子的点赞状态 Provider
final likePostProvider = StateNotifierProvider.family<LikePostNotifier, AsyncValue<bool>, String>(
  (ref, postId) => LikePostNotifier(ref.read(apiServiceProvider), postId),
);

/// 发表评论
class CreateCommentNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final String _postId;

  CreateCommentNotifier(this._api, this._postId) : super(const AsyncValue.data(null));

  Future<void> submit(String content) async {
    if (content.trim().isEmpty) return;
    state = const AsyncValue.loading();
    try {
      final resp = await _api.createComment(_postId, content.trim());
      if (!resp.isSuccess) throw Exception(resp.message);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final createCommentProvider = StateNotifierProvider.family<CreateCommentNotifier, AsyncValue<void>, String>(
  (ref, postId) => CreateCommentNotifier(ref.read(apiServiceProvider), postId),
);
