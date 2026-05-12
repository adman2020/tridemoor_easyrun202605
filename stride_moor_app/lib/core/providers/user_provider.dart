import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../config/constants.dart';
import 'app_providers.dart';

/// 当前用户状态
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return UserNotifier(apiService: apiService, storageService: storageService);
});

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _apiService;
  final StorageService _storageService;

  UserNotifier({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(const AsyncValue.data(null)) {
    // 初始化时尝试自动登录
    _tryAutoLogin();
  }

  /// 尝试自动登录（从 Hive 读取 Token，验证是否有效）
  Future<void> _tryAutoLogin() async {
    if (AppConstants.devMode) {
      // 开发模式：自动用测试账号登录后端
      if (AppConstants.autoLoginTestUser) {
        try {
          await login(phone: '13800000001', password: 'test123456');
        } catch (_) {
          state = const AsyncValue.data(null);
        }
      } else {
        final savedNickname = _storageService.getNickname();
        if (savedNickname != null && savedNickname.isNotEmpty) {
          state = AsyncValue.data(User(
            id: 'dev_user_001',
            nickname: savedNickname,
            createdAt: DateTime.now(),
          ));
        }
      }
      return;
    }
    final token = _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final resp = await _apiService.getUserProfile();
        if (resp.isSuccess && resp.data != null) {
          final user = User.fromJson(resp.data!);
          state = AsyncValue.data(user);
        } else {
          // 业务失败（token 可能已被拦截器处理），静默降级为未登录
          state = const AsyncValue.data(null);
        }
      } catch (e) {
        // 网络问题：token 仍然保留在本地，下次打开 App 会再次尝试
        // 不设置 error 状态，避免路由重定向到登录页时闪烁
        state = const AsyncValue.data(null);
      }
    }
  }

  /// 加载当前用户信息
  Future<void> loadUserProfile() async {
    state = const AsyncValue.loading();
    try {
      final resp = await _apiService.getUserProfile();
      if (resp.isSuccess && resp.data != null) {
        final user = User.fromJson(resp.data!);
        state = AsyncValue.data(user);
      } else {
        state = AsyncValue.error(resp.message, StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 注册
  Future<String?> register({
    required String phone,
    required String password,
    required String email,
    required double weight,
    String? nickname,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (AppConstants.devMode) {
        // 开发模式：本地 mock 注册
        final displayName = (nickname != null && nickname.isNotEmpty) ? nickname : phone;
        await _storageService.setNickname(displayName);
        state = AsyncValue.data(User(
          id: 'dev_user_001',
          nickname: displayName,
          phone: phone,
          email: email,
          createdAt: DateTime.now(),
        ));
        return null;
      }
      final resp = await _apiService.register(
        phone: phone,
        password: password,
        email: email,
        weight: weight,
        nickname: nickname,
      );
      if (resp.isSuccess) {
        // 注册成功，自动登录
        return await login(phone: phone, password: password);
      } else {
        state = const AsyncValue.data(null);
        return resp.message;
      }
    } catch (e) {
      state = const AsyncValue.data(null);
      return e.toString();
    }
  }

  /// 登录
  Future<String?> login({
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 开发模式（autoLoginTestUser=false）时用 mock 数据
      if (AppConstants.devMode && !AppConstants.autoLoginTestUser) {
        final savedNickname = _storageService.getNickname();
        final displayName = (savedNickname != null && savedNickname.isNotEmpty)
            ? savedNickname
            : phone;
        await _storageService.setNickname(displayName);
        state = AsyncValue.data(User(
          id: 'dev_user_001',
          nickname: displayName,
          phone: phone,
          createdAt: DateTime.now(),
        ));
        return null;
      }
      // 开发模式（autoLoginTestUser=true）或生产模式：调真实 API
      final resp = await _apiService.login(phone: phone, password: password);
      if (resp.isSuccess) {
        // 登录成功，加载用户信息
        await loadUserProfile();
        return null;
      } else {
        state = const AsyncValue.data(null);
        return resp.message;
      }
    } catch (e) {
      state = const AsyncValue.data(null);
      return e.toString();
    }
  }

  /// 更新用户资料
  Future<String?> updateProfile({
    String? nickname,
    String? bio,
    int? gender,
    int? height,
    DateTime? birthday,
    double? weight,
    String? email,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nickname != null) data['nickname'] = nickname;
      if (bio != null) data['bio'] = bio;
      if (gender != null) data['gender'] = gender;
      if (height != null) data['height'] = height;
      if (birthday != null) data['birthday'] = birthday.toIso8601String().split('T')[0];
      if (weight != null) data['weight'] = weight;
      if (email != null) data['email'] = email;

      final resp = await _apiService.updateUserProfile(data);
      if (resp.isSuccess) {
        await loadUserProfile();
        return null;
      }
      return resp.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// 修改密码
  Future<String?> changePassword({required String oldPassword, required String newPassword}) async {
    try {
      final resp = await _apiService.updatePassword(oldPassword, newPassword);
      if (resp.isSuccess) {
        return null;
      }
      return resp.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// 登出
  Future<void> logout() async {
    await _apiService.logout();
    state = const AsyncValue.data(null);
  }

  void setUser(User user) {
    state = AsyncValue.data(user);
  }

  void clearUser() {
    state = const AsyncValue.data(null);
  }

  /// 是否已登录
  bool get isLoggedIn => state.value != null;
}
