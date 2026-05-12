import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../config/constants.dart';
import 'storage_service.dart';

/// 后端统一响应结构
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? parser) {
    return ApiResponse(
      code: json['code'] ?? -1,
      message: json['message'] ?? '',
      data: parser != null && json['data'] != null ? parser(json['data']) : json['data'] as T?,
    );
  }

  bool get isSuccess => code == 0;
}

/// Token 对
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresIn: json['expires_in'] ?? 0,
    );
  }
}

/// 网络请求服务封装
class ApiService {
  late final Dio _dio;
  final Logger _logger = Logger();
  final StorageService _storage;

  bool _isRefreshing = false;

  /// 内存缓存 token（解决 Hive 异步写入/读取时序问题）
  String? _memoryAccessToken;

  /// 设置 token（同时写 Hive + 内存）
  Future<void> _saveToken(String accessToken, String refreshToken) async {
    _memoryAccessToken = accessToken;
    await _storage.setAccessToken(accessToken);
    await _storage.setRefreshToken(refreshToken);
  }

  /// 读取 token（优先内存，fallback Hive）
  String? _getAccessToken() {
    return _memoryAccessToken ?? _storage.getAccessToken();
  }

  ApiService({required StorageService storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');

          // 注入 Access Token（非公开路由）
          if (!_isPublicRoute(options.path)) {
            final token = _getAccessToken();
            _logger.i('INTERCEPTOR: path=${options.path}, token长度=${token?.length ?? 0}');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              _logger.w('INTERCEPTOR: ⚠️ token 为空! path=${options.path}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');

          // 处理后端业务错误码 1003（Token 过期但 HTTP 200）
          // 例如 /auth/refresh 返回的刷新失败
          if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            final code = data['code'] as int? ?? 0;
            if (code == 1003) {
              _logger.w('Token 过期(业务码): path=${response.requestOptions.path}');
              final dioError = DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: data['message'] ?? 'Token 已过期',
              );
              return handler.reject(dioError);
            }
          }

          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          _logger.e('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');

          // 处理 401 / 业务认证错误：Token 过期，尝试刷新
          final isAuthError = e.response?.statusCode == 401 ||
              (e.error != null && (e.error.toString().contains('认证失败') || e.error.toString().contains('Token')));

          if (isAuthError && !_isPublicRoute(e.requestOptions.path)) {
            if (!_isRefreshing) {
              _isRefreshing = true;
              try {
                final refreshed = await _refreshToken();
                if (refreshed) {
                  // 刷新成功，重试原请求
                  final token = _storage.getAccessToken();
                  final options = e.requestOptions;
                  options.headers['Authorization'] = 'Bearer $token';
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                }
                // refresh token 确实无效，清除持久化 token
                _memoryAccessToken = null;
                await _storage.clearTokens();
              } catch (err) {
                _logger.e('Token 刷新网络失败: $err');
                // 网络问题：不清除持久化 token，只清除内存 token
                _memoryAccessToken = null;
              } finally {
                _isRefreshing = false;
              }
            } else {
              // 其他请求正在刷新中，直接传播错误，由业务层处理
              _memoryAccessToken = null;
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// 判断是否为公开路由（无需 Token）
  bool _isPublicRoute(String path) {
    // 去除 baseUrl 和查询参数，只保留 path 部分
    var cleanPath = path;
    if (cleanPath.contains('?')) {
      cleanPath = cleanPath.substring(0, cleanPath.indexOf('?'));
    }
    // 若 path 包含 baseUrl，截取相对路径
    const baseUrl = AppConstants.baseUrl;
    if (cleanPath.startsWith(baseUrl)) {
      cleanPath = cleanPath.substring(baseUrl.length);
    }
    // 确保以 / 开头
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    final publicPaths = ['/auth/register', '/auth/login', '/auth/refresh', '/health'];
    return publicPaths.any((p) => cleanPath == p || cleanPath.startsWith('$p/'));
  }

  /// 刷新 Token
  Future<bool> _refreshToken() async {
    final refreshToken = _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}), // 不携带旧 Access Token
      );
      final resp = ApiResponse<Map<String, dynamic>>.fromJson(response.data, (d) => d as Map<String, dynamic>);
      if (resp.isSuccess && resp.data != null) {
        final tokens = TokenPair.fromJson(resp.data!);
        await _saveToken(tokens.accessToken, tokens.refreshToken);
        return true;
      }
    } catch (e) {
      _logger.e('刷新 Token 请求失败: $e');
    }
    return false;
  }

  // ==================== 认证相关 ====================

  /// 注册
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String phone,
    required String password,
    required String email,
    required double weight,
    String? nickname,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      'email': email,
      'weight': weight,
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 登录
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });

    final resp = ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);

    // 登录成功，保存 Token
    if (resp.isSuccess && resp.data != null) {
      // 后端返回格式: { tokens: { access_token, refresh_token, expires_in }, user_info: {...} }
      final tokenData = resp.data!['tokens'] ?? resp.data!;
      if (tokenData is Map && tokenData.containsKey('access_token')) {
        final at = tokenData['access_token'] as String;
        final rt = tokenData['refresh_token'] as String;
        _logger.i('LOGIN: 保存 token, access长度=${at.length}');
        await _saveToken(at, rt);
      }
    }

    return resp;
  }

  /// 登出
  Future<void> logout() async {
    _memoryAccessToken = null;
    await _storage.clearTokens();
  }

  // ==================== 用户相关 ====================

  /// 获取当前用户信息
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    final token = _getAccessToken();
    _logger.i('getUserProfile: token长度=${token?.length ?? 0}');
    final response = await _dio.get('/user/profile');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 更新用户资料
  Future<ApiResponse<Map<String, dynamic>>> updateUserProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/user/profile', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 修改密码
  Future<ApiResponse<Map<String, dynamic>>> updatePassword(String oldPassword, String newPassword) async {
    final response = await _dio.put('/user/password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 跑步记录相关 ====================

  /// 开始跑步
  Future<ApiResponse<Map<String, dynamic>>> startRun({String? routeId}) async {
    final response = await _dio.post('/runs/start', data: {
      if (routeId != null) 'route_id': routeId,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 上传采样数据
  Future<ApiResponse<Map<String, dynamic>>> uploadSamples(String runId, List<Map<String, dynamic>> samples) async {
    final response = await _dio.post('/runs/$runId/samples', data: {'samples': samples});
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 结束跑步
  Future<ApiResponse<Map<String, dynamic>>> finishRun(String runId, Map<String, dynamic> data) async {
    final response = await _dio.post('/runs/$runId/finish', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 删除跑步记录
  Future<ApiResponse<Map<String, dynamic>>> deleteRun(String runId) async {
    final response = await _dio.delete('/runs/$runId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 清理距离为 0 的无效跑步记录
  Future<ApiResponse<Map<String, dynamic>>> cleanZeroRuns() async {
    final response = await _dio.delete('/runs/clean-zero');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 获取跑步历史平均值（语音播报用）
  Future<ApiResponse<Map<String, dynamic>>> getRunAverages() async {
    final response = await _dio.get('/runs/averages');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 跑步记录列表
  Future<ApiResponse<Map<String, dynamic>>> getRunList({int page = 1, int pageSize = 10}) async {
    final response = await _dio.get('/runs', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 跑步详情
  Future<ApiResponse<Map<String, dynamic>>> getRunDetail(String runId) async {
    final response = await _dio.get('/runs/$runId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 路线相关 ====================

  /// 创建路线
  Future<ApiResponse<Map<String, dynamic>>> createRoute(Map<String, dynamic> data) async {
    final response = await _dio.post('/routes', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 路线列表
  Future<ApiResponse<Map<String, dynamic>>> getRouteList({
    int page = 1,
    int pageSize = 10,
    String? city,
    int? difficulty,
    double? distanceMin,
    double? distanceMax,
    String? keyword,
    String? sortBy,
  }) async {
    final response = await _dio.get('/routes', queryParameters: {
      'page': page,
      'page_size': pageSize,
      if (city != null) 'city': city,
      if (difficulty != null) 'difficulty': difficulty,
      if (distanceMin != null) 'distance_min': distanceMin,
      if (distanceMax != null) 'distance_max': distanceMax,
      if (keyword != null) 'keyword': keyword,
      if (sortBy != null) 'sort_by': sortBy,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 路线详情
  Future<ApiResponse<Map<String, dynamic>>> getRouteDetail(String routeId) async {
    final response = await _dio.get('/routes/$routeId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 更新路线
  Future<ApiResponse<Map<String, dynamic>>> updateRoute(String routeId, Map<String, dynamic> data) async {
    final response = await _dio.put('/routes/$routeId', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 删除路线
  Future<ApiResponse<Map<String, dynamic>>> deleteRoute(String routeId) async {
    final response = await _dio.delete('/routes/$routeId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 路线规则校验（Phase 2）
  Future<ApiResponse<Map<String, dynamic>>> validateRoute(Map<String, dynamic> data) async {
    final response = await _dio.post('/routes/validate', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 收藏路线
  Future<ApiResponse<Map<String, dynamic>>> favoriteRoute(String routeId) async {
    final response = await _dio.post('/routes/$routeId/favorite');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 取消收藏
  Future<ApiResponse<Map<String, dynamic>>> unfavoriteRoute(String routeId) async {
    final response = await _dio.delete('/routes/$routeId/favorite');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 我的收藏列表
  Future<ApiResponse<Map<String, dynamic>>> getFavoriteList({int page = 1, int pageSize = 10}) async {
    final response = await _dio.get('/routes/favorites', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 收藏跑友跑步记录（跑迹收藏）
  Future<ApiResponse<Map<String, dynamic>>> bookmarkRun(String runId) async {
    final response = await _dio.post('/runs/$runId/bookmark');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 取消收藏跑友跑步记录
  Future<ApiResponse<Map<String, dynamic>>> unbookmarkRun(String runId) async {
    final response = await _dio.delete('/runs/$runId/bookmark');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 获取我的跑友跑迹收藏列表
  Future<ApiResponse<Map<String, dynamic>>> getBookmarkedRuns() async {
    final response = await _dio.get('/runs/bookmarks/list');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 附近路线
  Future<ApiResponse<Map<String, dynamic>>> getNearbyRoutes({
    required double lat,
    required double lng,
    double radius = 5000,
    int limit = 20,
  }) async {
    final response = await _dio.get('/routes/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'limit': limit,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 路线评分
  Future<ApiResponse<Map<String, dynamic>>> rateRoute(String routeId, double rating) async {
    final response = await _dio.post('/routes/$routeId/rate', data: {'rating': rating});
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 路线排行榜
  /// sortBy: 空=打卡榜(run_count DESC), time_asc=成绩榜(total_time ASC)
  Future<ApiResponse<Map<String, dynamic>>> getRouteLeaderboard(String routeId, {int page = 1, int pageSize = 20, String? sortBy}) async {
    final response = await _dio.get('/routes/$routeId/leaderboard', queryParameters: {
      'page': page,
      'page_size': pageSize,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 好友相关 ====================

  /// 发送好友申请
  Future<ApiResponse<Map<String, dynamic>>> sendFriendRequest(String toUserId) async {
    final response = await _dio.post('/friends/requests', data: {'to_user_id': toUserId});
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 待处理申请列表
  Future<ApiResponse<Map<String, dynamic>>> getPendingRequests({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/friends/requests/pending', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 接受好友申请
  Future<ApiResponse<Map<String, dynamic>>> acceptFriendRequest(String requestId) async {
    final response = await _dio.post('/friends/requests/$requestId/accept');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 拒绝好友申请
  Future<ApiResponse<Map<String, dynamic>>> rejectFriendRequest(String requestId) async {
    final response = await _dio.post('/friends/requests/$requestId/reject');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 好友列表
  Future<ApiResponse<Map<String, dynamic>>> getFriendList({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/friends', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 删除好友
  Future<ApiResponse<Map<String, dynamic>>> removeFriend(String friendId) async {
    final response = await _dio.delete('/friends/$friendId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 伴跑相关 ====================

  /// 完成伴跑（热度+1）
  Future<ApiResponse<Map<String, dynamic>>> companionRun(String runId) async {
    final response = await _dio.post('/runs/$runId/companion');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 挑战/伴跑PK相关 ====================

  /// 发起挑战
  Future<ApiResponse<Map<String, dynamic>>> createChallenge(Map<String, dynamic> data) async {
    final response = await _dio.post('/challenges', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 挑战列表
  Future<ApiResponse<Map<String, dynamic>>> getChallengeList({
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get('/challenges', queryParameters: {
      if (status != null) 'status': status,
      'page': page,
      'page_size': pageSize,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 挑战详情
  Future<ApiResponse<Map<String, dynamic>>> getChallengeDetail(String challengeId) async {
    final response = await _dio.get('/challenges/$challengeId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 接受挑战
  Future<ApiResponse<Map<String, dynamic>>> acceptChallenge(String challengeId) async {
    final response = await _dio.post('/challenges/$challengeId/accept');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 开始挑战
  Future<ApiResponse<Map<String, dynamic>>> startChallenge(String challengeId) async {
    final response = await _dio.post('/challenges/$challengeId/start');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 完成挑战
  Future<ApiResponse<Map<String, dynamic>>> completeChallenge(String challengeId, Map<String, dynamic> data) async {
    final response = await _dio.post('/challenges/$challengeId/complete', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 取消挑战
  Future<ApiResponse<Map<String, dynamic>>> cancelChallenge(String challengeId) async {
    final response = await _dio.post('/challenges/$challengeId/cancel');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 对比报告
  Future<ApiResponse<Map<String, dynamic>>> getComparisonReport(String challengeId) async {
    final response = await _dio.get('/challenges/$challengeId/comparison');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 动态相关 ====================

  /// 创建动态
  Future<ApiResponse<Map<String, dynamic>>> createPost({required String content, String? runId, String? routeId}) async {
    final response = await _dio.post('/posts', data: {
      'content': content,
      if (runId != null) 'run_id': runId,
      if (routeId != null) 'route_id': routeId,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 动态列表
  Future<ApiResponse<Map<String, dynamic>>> getPostList({int page = 1, int pageSize = 10}) async {
    final response = await _dio.get('/posts', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 动态详情
  Future<ApiResponse<Map<String, dynamic>>> getPostDetail(String postId) async {
    final response = await _dio.get('/posts/$postId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 发表评论
  Future<ApiResponse<Map<String, dynamic>>> createComment(String postId, String content) async {
    final response = await _dio.post('/posts/$postId/comments', data: {'content': content});
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 评论列表
  Future<ApiResponse<Map<String, dynamic>>> getComments(String postId, {int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/posts/$postId/comments', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 点赞
  Future<ApiResponse<Map<String, dynamic>>> likePost(String postId) async {
    final response = await _dio.post('/posts/$postId/like');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 取消点赞
  Future<ApiResponse<Map<String, dynamic>>> unlikePost(String postId) async {
    final response = await _dio.delete('/posts/$postId/like');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 文件上传相关 ====================

  /// 上传头像
  Future<ApiResponse<Map<String, dynamic>>> uploadAvatar(List<int> fileBytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final response = await _dio.post('/upload/avatar', data: formData);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 上传 GPX
  Future<ApiResponse<Map<String, dynamic>>> uploadGPX(List<int> fileBytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final response = await _dio.post('/upload/gpx', data: formData);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 关注相关 ====================

  /// 关注用户
  Future<ApiResponse<Map<String, dynamic>>> followUser(String userId) async {
    final response = await _dio.post('/users/$userId/follow');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 取消关注
  Future<ApiResponse<Map<String, dynamic>>> unfollowUser(String userId) async {
    final response = await _dio.delete('/users/$userId/follow');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 判断是否已关注
  Future<ApiResponse<Map<String, dynamic>>> isFollowing(String userId) async {
    final response = await _dio.get('/users/followings', queryParameters: {'user_id': userId});
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 获取关注列表
  Future<ApiResponse<Map<String, dynamic>>> getFollowings({int page = 1, int pageSize = 100}) async {
    final response = await _dio.get('/users/followings', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 获取指定用户的跑步统计数据（跑友详情用）
  Future<ApiResponse<Map<String, dynamic>>> getUserStats(String userId) async {
    final response = await _dio.get('/users/$userId/stats');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 获取当前用户热度统计数据（跑迹-我的热度）
  Future<ApiResponse<Map<String, dynamic>>> getHeatStats() async {
    final response = await _dio.get('/user/stats/heats');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== AI 分析相关 ====================

  /// AI 跑情分析（AI 接口响应较慢，单独设 60s 超时）
  Future<ApiResponse<Map<String, dynamic>>> runAnalysis(String runId) async {
    final response = await _dio.post('/ai/run-analysis',
      data: {'run_id': runId},
      options: Options(receiveTimeout: const Duration(seconds: 60), sendTimeout: const Duration(seconds: 15)),
    );
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 获取 AI 分析缓存（从数据库读取，不走 AI）
  Future<ApiResponse<Map<String, dynamic>>> getAnalysis(String runId) async {
    final response = await _dio.get('/ai/analyses/$runId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== AI 功能权益 ====================

  /// 获取当前用户的 AI 功能权益列表
  Future<ApiResponse<Map<String, dynamic>>> getAIFeatures() async {
    final response = await _dio.get('/ai/features');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 跑境相关 ====================

  /// 获取用户跑境信息
  Future<ApiResponse<Map<String, dynamic>>> getPaojing() async {
    final response = await _dio.get('/user/paojing');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 赛后触发跑境判境
  Future<ApiResponse<Map<String, dynamic>>> checkPaojingUpgrade() async {
    final response = await _dio.post('/user/paojing/check');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  // ==================== 设备管理相关 ====================

  /// 获取设备列表
  Future<ApiResponse<Map<String, dynamic>>> getDeviceList() async {
    final response = await _dio.get('/devices');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 绑定新设备
  Future<ApiResponse<Map<String, dynamic>>> bindDevice(Map<String, dynamic> data) async {
    final response = await _dio.post('/devices', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 更新设备信息
  Future<ApiResponse<Map<String, dynamic>>> updateDevice(String deviceId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/devices/$deviceId', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 解绑设备
  Future<ApiResponse<Map<String, dynamic>>> unbindDevice(String deviceId) async {
    final response = await _dio.delete('/devices/$deviceId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 导入第三方跑步记录
  Future<ApiResponse<Map<String, dynamic>>> importRun(Map<String, dynamic> data) async {
    final response = await _dio.post('/runs/import', data: data);
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 获取导入历史
  Future<ApiResponse<Map<String, dynamic>>> getImportHistory() async {
    final response = await _dio.get('/runs/import/history');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }

  /// 删除导入记录
  Future<ApiResponse<Map<String, dynamic>>> deleteImported(String importId) async {
    final response = await _dio.delete('/runs/import/$importId');
    return ApiResponse.fromJson(response.data, (d) => d as Map<String, dynamic>);
  }
}
