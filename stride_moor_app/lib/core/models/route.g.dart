// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RouteFavoriteImpl _$$RouteFavoriteImplFromJson(Map<String, dynamic> json) =>
    _$RouteFavoriteImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      routeId: json['routeId'] as String,
      tag: json['tag'] as String? ?? 'want_to_run',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$RouteFavoriteImplToJson(_$RouteFavoriteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'routeId': instance.routeId,
      'tag': instance.tag,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
