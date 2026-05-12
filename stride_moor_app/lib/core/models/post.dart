import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';
import 'run.dart';
import 'route.dart';

part 'post.freezed.dart';

/// 跑友动态模型
@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String userId,
    /// 关联跑步记录ID
    String? runId,
    /// 关联路线ID
    String? routeId,
    /// 动态文字内容
    String? content,
    /// 创建时间
    required DateTime createdAt,
    /// 发布者信息（Preload）
    User? user,
    /// 关联跑步记录（Preload）
    Run? run,
    /// 关联路线（Preload）
    Route? route,
    /// 点赞数（聚合字段）
    @Default(0) int likeCount,
    /// 评论数（聚合字段）
    @Default(0) int commentCount,
    /// 当前用户是否已点赞
    @Default(false) bool isLiked,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) {
    User? user;
    final userJson = json['user'];
    if (userJson is Map<String, dynamic>) {
      user = User.fromJson(userJson);
    }

    Run? run;
    final runJson = json['run'];
    if (runJson is Map<String, dynamic>) {
      run = Run.fromJson(runJson);
    }

    Route? route;
    final routeJson = json['route'];
    if (routeJson is Map<String, dynamic>) {
      route = Route.fromJson(routeJson);
    }

    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      runId: json['run_id'] as String?,
      routeId: json['route_id'] as String?,
      content: json['content'] as String?,
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String),
      user: user,
      run: run,
      route: route,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isLiked: (json['is_liked'] as bool?) ?? false,
    );
  }
}

/// 动态评论模型
@freezed
class PostComment with _$PostComment {
  const factory PostComment({
    required String id,
    required String postId,
    required String userId,
    required String content,
    required DateTime createdAt,
    User? user,
  }) = _PostComment;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    User? user;
    final userJson = json['user'];
    if (userJson is Map<String, dynamic>) {
      user = User.fromJson(userJson);
    }

    return PostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String),
      user: user,
    );
  }
}
