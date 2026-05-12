// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Route {
  String get id => throw _privateConstructorUsedError;
  String get creatorId => throw _privateConstructorUsedError;
  String? get creatorName => throw _privateConstructorUsedError;
  String? get creatorAvatar => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// 简化后的轨迹几何数据（经纬度数组）
  List<Map<String, double>> get geometry => throw _privateConstructorUsedError;

  /// 总距离（米）
  double get distance => throw _privateConstructorUsedError;

  /// 累计爬升（米）
  double get elevationGain => throw _privateConstructorUsedError;

  /// 难度: easy, moderate, hard
  String get difficulty => throw _privateConstructorUsedError;

  /// 路面类型: 0=普通, 1=大马路, 2=绿道, 3=坡道, 4=跑道, 5=河边, 6=土路
  int get roadType => throw _privateConstructorUsedError;

  /// 热度（被陪跑次数）
  int get popularity => throw _privateConstructorUsedError;

  /// 起点 {lat, lng}
  Map<String, double>? get startPoint => throw _privateConstructorUsedError;

  /// 中心点 {lat, lng}
  Map<String, double>? get centerPoint => throw _privateConstructorUsedError;

  /// 标签
  List<String> get tags => throw _privateConstructorUsedError;

  /// 评分 0-5
  double get rating => throw _privateConstructorUsedError;

  /// 被收藏数
  int get favoriteCount => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// 城市
  String? get city => throw _privateConstructorUsedError;

  /// 来自原跑步记录的指标（可选）
  int get avgPace => throw _privateConstructorUsedError;
  int get avgCadence => throw _privateConstructorUsedError;
  double get avgStride => throw _privateConstructorUsedError;
  int get calories => throw _privateConstructorUsedError;
  int get avgHeartRate => throw _privateConstructorUsedError;
  double get elevationLoss => throw _privateConstructorUsedError;
  int? get totalTime => throw _privateConstructorUsedError;
  int? get maxHeartRate => throw _privateConstructorUsedError;
  int? get maxCadence => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RouteCopyWith<Route> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteCopyWith<$Res> {
  factory $RouteCopyWith(Route value, $Res Function(Route) then) =
      _$RouteCopyWithImpl<$Res, Route>;
  @useResult
  $Res call(
      {String id,
      String creatorId,
      String? creatorName,
      String? creatorAvatar,
      String name,
      String? description,
      List<Map<String, double>> geometry,
      double distance,
      double elevationGain,
      String difficulty,
      int roadType,
      int popularity,
      Map<String, double>? startPoint,
      Map<String, double>? centerPoint,
      List<String> tags,
      double rating,
      int favoriteCount,
      DateTime? createdAt,
      String? city,
      int avgPace,
      int avgCadence,
      double avgStride,
      int calories,
      int avgHeartRate,
      double elevationLoss,
      int? totalTime,
      int? maxHeartRate,
      int? maxCadence});
}

/// @nodoc
class _$RouteCopyWithImpl<$Res, $Val extends Route>
    implements $RouteCopyWith<$Res> {
  _$RouteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? creatorId = null,
    Object? creatorName = freezed,
    Object? creatorAvatar = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? geometry = null,
    Object? distance = null,
    Object? elevationGain = null,
    Object? difficulty = null,
    Object? roadType = null,
    Object? popularity = null,
    Object? startPoint = freezed,
    Object? centerPoint = freezed,
    Object? tags = null,
    Object? rating = null,
    Object? favoriteCount = null,
    Object? createdAt = freezed,
    Object? city = freezed,
    Object? avgPace = null,
    Object? avgCadence = null,
    Object? avgStride = null,
    Object? calories = null,
    Object? avgHeartRate = null,
    Object? elevationLoss = null,
    Object? totalTime = freezed,
    Object? maxHeartRate = freezed,
    Object? maxCadence = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      creatorId: null == creatorId
          ? _value.creatorId
          : creatorId // ignore: cast_nullable_to_non_nullable
              as String,
      creatorName: freezed == creatorName
          ? _value.creatorName
          : creatorName // ignore: cast_nullable_to_non_nullable
              as String?,
      creatorAvatar: freezed == creatorAvatar
          ? _value.creatorAvatar
          : creatorAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      geometry: null == geometry
          ? _value.geometry
          : geometry // ignore: cast_nullable_to_non_nullable
              as List<Map<String, double>>,
      distance: null == distance
          ? _value.distance
          : distance // ignore: cast_nullable_to_non_nullable
              as double,
      elevationGain: null == elevationGain
          ? _value.elevationGain
          : elevationGain // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      roadType: null == roadType
          ? _value.roadType
          : roadType // ignore: cast_nullable_to_non_nullable
              as int,
      popularity: null == popularity
          ? _value.popularity
          : popularity // ignore: cast_nullable_to_non_nullable
              as int,
      startPoint: freezed == startPoint
          ? _value.startPoint
          : startPoint // ignore: cast_nullable_to_non_nullable
              as Map<String, double>?,
      centerPoint: freezed == centerPoint
          ? _value.centerPoint
          : centerPoint // ignore: cast_nullable_to_non_nullable
              as Map<String, double>?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      favoriteCount: null == favoriteCount
          ? _value.favoriteCount
          : favoriteCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      avgPace: null == avgPace
          ? _value.avgPace
          : avgPace // ignore: cast_nullable_to_non_nullable
              as int,
      avgCadence: null == avgCadence
          ? _value.avgCadence
          : avgCadence // ignore: cast_nullable_to_non_nullable
              as int,
      avgStride: null == avgStride
          ? _value.avgStride
          : avgStride // ignore: cast_nullable_to_non_nullable
              as double,
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      avgHeartRate: null == avgHeartRate
          ? _value.avgHeartRate
          : avgHeartRate // ignore: cast_nullable_to_non_nullable
              as int,
      elevationLoss: null == elevationLoss
          ? _value.elevationLoss
          : elevationLoss // ignore: cast_nullable_to_non_nullable
              as double,
      totalTime: freezed == totalTime
          ? _value.totalTime
          : totalTime // ignore: cast_nullable_to_non_nullable
              as int?,
      maxHeartRate: freezed == maxHeartRate
          ? _value.maxHeartRate
          : maxHeartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      maxCadence: freezed == maxCadence
          ? _value.maxCadence
          : maxCadence // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RouteImplCopyWith<$Res> implements $RouteCopyWith<$Res> {
  factory _$$RouteImplCopyWith(
          _$RouteImpl value, $Res Function(_$RouteImpl) then) =
      __$$RouteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String creatorId,
      String? creatorName,
      String? creatorAvatar,
      String name,
      String? description,
      List<Map<String, double>> geometry,
      double distance,
      double elevationGain,
      String difficulty,
      int roadType,
      int popularity,
      Map<String, double>? startPoint,
      Map<String, double>? centerPoint,
      List<String> tags,
      double rating,
      int favoriteCount,
      DateTime? createdAt,
      String? city,
      int avgPace,
      int avgCadence,
      double avgStride,
      int calories,
      int avgHeartRate,
      double elevationLoss,
      int? totalTime,
      int? maxHeartRate,
      int? maxCadence});
}

/// @nodoc
class __$$RouteImplCopyWithImpl<$Res>
    extends _$RouteCopyWithImpl<$Res, _$RouteImpl>
    implements _$$RouteImplCopyWith<$Res> {
  __$$RouteImplCopyWithImpl(
      _$RouteImpl _value, $Res Function(_$RouteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? creatorId = null,
    Object? creatorName = freezed,
    Object? creatorAvatar = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? geometry = null,
    Object? distance = null,
    Object? elevationGain = null,
    Object? difficulty = null,
    Object? roadType = null,
    Object? popularity = null,
    Object? startPoint = freezed,
    Object? centerPoint = freezed,
    Object? tags = null,
    Object? rating = null,
    Object? favoriteCount = null,
    Object? createdAt = freezed,
    Object? city = freezed,
    Object? avgPace = null,
    Object? avgCadence = null,
    Object? avgStride = null,
    Object? calories = null,
    Object? avgHeartRate = null,
    Object? elevationLoss = null,
    Object? totalTime = freezed,
    Object? maxHeartRate = freezed,
    Object? maxCadence = freezed,
  }) {
    return _then(_$RouteImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      creatorId: null == creatorId
          ? _value.creatorId
          : creatorId // ignore: cast_nullable_to_non_nullable
              as String,
      creatorName: freezed == creatorName
          ? _value.creatorName
          : creatorName // ignore: cast_nullable_to_non_nullable
              as String?,
      creatorAvatar: freezed == creatorAvatar
          ? _value.creatorAvatar
          : creatorAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      geometry: null == geometry
          ? _value._geometry
          : geometry // ignore: cast_nullable_to_non_nullable
              as List<Map<String, double>>,
      distance: null == distance
          ? _value.distance
          : distance // ignore: cast_nullable_to_non_nullable
              as double,
      elevationGain: null == elevationGain
          ? _value.elevationGain
          : elevationGain // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      roadType: null == roadType
          ? _value.roadType
          : roadType // ignore: cast_nullable_to_non_nullable
              as int,
      popularity: null == popularity
          ? _value.popularity
          : popularity // ignore: cast_nullable_to_non_nullable
              as int,
      startPoint: freezed == startPoint
          ? _value._startPoint
          : startPoint // ignore: cast_nullable_to_non_nullable
              as Map<String, double>?,
      centerPoint: freezed == centerPoint
          ? _value._centerPoint
          : centerPoint // ignore: cast_nullable_to_non_nullable
              as Map<String, double>?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      favoriteCount: null == favoriteCount
          ? _value.favoriteCount
          : favoriteCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      avgPace: null == avgPace
          ? _value.avgPace
          : avgPace // ignore: cast_nullable_to_non_nullable
              as int,
      avgCadence: null == avgCadence
          ? _value.avgCadence
          : avgCadence // ignore: cast_nullable_to_non_nullable
              as int,
      avgStride: null == avgStride
          ? _value.avgStride
          : avgStride // ignore: cast_nullable_to_non_nullable
              as double,
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      avgHeartRate: null == avgHeartRate
          ? _value.avgHeartRate
          : avgHeartRate // ignore: cast_nullable_to_non_nullable
              as int,
      elevationLoss: null == elevationLoss
          ? _value.elevationLoss
          : elevationLoss // ignore: cast_nullable_to_non_nullable
              as double,
      totalTime: freezed == totalTime
          ? _value.totalTime
          : totalTime // ignore: cast_nullable_to_non_nullable
              as int?,
      maxHeartRate: freezed == maxHeartRate
          ? _value.maxHeartRate
          : maxHeartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      maxCadence: freezed == maxCadence
          ? _value.maxCadence
          : maxCadence // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$RouteImpl implements _Route {
  const _$RouteImpl(
      {required this.id,
      required this.creatorId,
      this.creatorName,
      this.creatorAvatar,
      required this.name,
      this.description,
      final List<Map<String, double>> geometry = const [],
      required this.distance,
      this.elevationGain = 0,
      this.difficulty = 'easy',
      this.roadType = 0,
      this.popularity = 0,
      final Map<String, double>? startPoint,
      final Map<String, double>? centerPoint,
      final List<String> tags = const [],
      this.rating = 0.0,
      this.favoriteCount = 0,
      this.createdAt,
      this.city,
      this.avgPace = 0,
      this.avgCadence = 0,
      this.avgStride = 0.0,
      this.calories = 0,
      this.avgHeartRate = 0,
      this.elevationLoss = 0.0,
      this.totalTime,
      this.maxHeartRate,
      this.maxCadence})
      : _geometry = geometry,
        _startPoint = startPoint,
        _centerPoint = centerPoint,
        _tags = tags;

  @override
  final String id;
  @override
  final String creatorId;
  @override
  final String? creatorName;
  @override
  final String? creatorAvatar;
  @override
  final String name;
  @override
  final String? description;

  /// 简化后的轨迹几何数据（经纬度数组）
  final List<Map<String, double>> _geometry;

  /// 简化后的轨迹几何数据（经纬度数组）
  @override
  @JsonKey()
  List<Map<String, double>> get geometry {
    if (_geometry is EqualUnmodifiableListView) return _geometry;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_geometry);
  }

  /// 总距离（米）
  @override
  final double distance;

  /// 累计爬升（米）
  @override
  @JsonKey()
  final double elevationGain;

  /// 难度: easy, moderate, hard
  @override
  @JsonKey()
  final String difficulty;

  /// 路面类型: 0=普通, 1=大马路, 2=绿道, 3=坡道, 4=跑道, 5=河边, 6=土路
  @override
  @JsonKey()
  final int roadType;

  /// 热度（被陪跑次数）
  @override
  @JsonKey()
  final int popularity;

  /// 起点 {lat, lng}
  final Map<String, double>? _startPoint;

  /// 起点 {lat, lng}
  @override
  Map<String, double>? get startPoint {
    final value = _startPoint;
    if (value == null) return null;
    if (_startPoint is EqualUnmodifiableMapView) return _startPoint;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// 中心点 {lat, lng}
  final Map<String, double>? _centerPoint;

  /// 中心点 {lat, lng}
  @override
  Map<String, double>? get centerPoint {
    final value = _centerPoint;
    if (value == null) return null;
    if (_centerPoint is EqualUnmodifiableMapView) return _centerPoint;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// 标签
  final List<String> _tags;

  /// 标签
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// 评分 0-5
  @override
  @JsonKey()
  final double rating;

  /// 被收藏数
  @override
  @JsonKey()
  final int favoriteCount;
  @override
  final DateTime? createdAt;

  /// 城市
  @override
  final String? city;

  /// 来自原跑步记录的指标（可选）
  @override
  @JsonKey()
  final int avgPace;
  @override
  @JsonKey()
  final int avgCadence;
  @override
  @JsonKey()
  final double avgStride;
  @override
  @JsonKey()
  final int calories;
  @override
  @JsonKey()
  final int avgHeartRate;
  @override
  @JsonKey()
  final double elevationLoss;
  @override
  final int? totalTime;
  @override
  final int? maxHeartRate;
  @override
  final int? maxCadence;

  @override
  String toString() {
    return 'Route(id: $id, creatorId: $creatorId, creatorName: $creatorName, creatorAvatar: $creatorAvatar, name: $name, description: $description, geometry: $geometry, distance: $distance, elevationGain: $elevationGain, difficulty: $difficulty, roadType: $roadType, popularity: $popularity, startPoint: $startPoint, centerPoint: $centerPoint, tags: $tags, rating: $rating, favoriteCount: $favoriteCount, createdAt: $createdAt, city: $city, avgPace: $avgPace, avgCadence: $avgCadence, avgStride: $avgStride, calories: $calories, avgHeartRate: $avgHeartRate, elevationLoss: $elevationLoss, totalTime: $totalTime, maxHeartRate: $maxHeartRate, maxCadence: $maxCadence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId) &&
            (identical(other.creatorName, creatorName) ||
                other.creatorName == creatorName) &&
            (identical(other.creatorAvatar, creatorAvatar) ||
                other.creatorAvatar == creatorAvatar) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._geometry, _geometry) &&
            (identical(other.distance, distance) ||
                other.distance == distance) &&
            (identical(other.elevationGain, elevationGain) ||
                other.elevationGain == elevationGain) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.roadType, roadType) ||
                other.roadType == roadType) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            const DeepCollectionEquality()
                .equals(other._startPoint, _startPoint) &&
            const DeepCollectionEquality()
                .equals(other._centerPoint, _centerPoint) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.favoriteCount, favoriteCount) ||
                other.favoriteCount == favoriteCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.avgPace, avgPace) || other.avgPace == avgPace) &&
            (identical(other.avgCadence, avgCadence) ||
                other.avgCadence == avgCadence) &&
            (identical(other.avgStride, avgStride) ||
                other.avgStride == avgStride) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.avgHeartRate, avgHeartRate) ||
                other.avgHeartRate == avgHeartRate) &&
            (identical(other.elevationLoss, elevationLoss) ||
                other.elevationLoss == elevationLoss) &&
            (identical(other.totalTime, totalTime) ||
                other.totalTime == totalTime) &&
            (identical(other.maxHeartRate, maxHeartRate) ||
                other.maxHeartRate == maxHeartRate) &&
            (identical(other.maxCadence, maxCadence) ||
                other.maxCadence == maxCadence));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        creatorId,
        creatorName,
        creatorAvatar,
        name,
        description,
        const DeepCollectionEquality().hash(_geometry),
        distance,
        elevationGain,
        difficulty,
        roadType,
        popularity,
        const DeepCollectionEquality().hash(_startPoint),
        const DeepCollectionEquality().hash(_centerPoint),
        const DeepCollectionEquality().hash(_tags),
        rating,
        favoriteCount,
        createdAt,
        city,
        avgPace,
        avgCadence,
        avgStride,
        calories,
        avgHeartRate,
        elevationLoss,
        totalTime,
        maxHeartRate,
        maxCadence
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteImplCopyWith<_$RouteImpl> get copyWith =>
      __$$RouteImplCopyWithImpl<_$RouteImpl>(this, _$identity);
}

abstract class _Route implements Route {
  const factory _Route(
      {required final String id,
      required final String creatorId,
      final String? creatorName,
      final String? creatorAvatar,
      required final String name,
      final String? description,
      final List<Map<String, double>> geometry,
      required final double distance,
      final double elevationGain,
      final String difficulty,
      final int roadType,
      final int popularity,
      final Map<String, double>? startPoint,
      final Map<String, double>? centerPoint,
      final List<String> tags,
      final double rating,
      final int favoriteCount,
      final DateTime? createdAt,
      final String? city,
      final int avgPace,
      final int avgCadence,
      final double avgStride,
      final int calories,
      final int avgHeartRate,
      final double elevationLoss,
      final int? totalTime,
      final int? maxHeartRate,
      final int? maxCadence}) = _$RouteImpl;

  @override
  String get id;
  @override
  String get creatorId;
  @override
  String? get creatorName;
  @override
  String? get creatorAvatar;
  @override
  String get name;
  @override
  String? get description;
  @override

  /// 简化后的轨迹几何数据（经纬度数组）
  List<Map<String, double>> get geometry;
  @override

  /// 总距离（米）
  double get distance;
  @override

  /// 累计爬升（米）
  double get elevationGain;
  @override

  /// 难度: easy, moderate, hard
  String get difficulty;
  @override

  /// 路面类型: 0=普通, 1=大马路, 2=绿道, 3=坡道, 4=跑道, 5=河边, 6=土路
  int get roadType;
  @override

  /// 热度（被陪跑次数）
  int get popularity;
  @override

  /// 起点 {lat, lng}
  Map<String, double>? get startPoint;
  @override

  /// 中心点 {lat, lng}
  Map<String, double>? get centerPoint;
  @override

  /// 标签
  List<String> get tags;
  @override

  /// 评分 0-5
  double get rating;
  @override

  /// 被收藏数
  int get favoriteCount;
  @override
  DateTime? get createdAt;
  @override

  /// 城市
  String? get city;
  @override

  /// 来自原跑步记录的指标（可选）
  int get avgPace;
  @override
  int get avgCadence;
  @override
  double get avgStride;
  @override
  int get calories;
  @override
  int get avgHeartRate;
  @override
  double get elevationLoss;
  @override
  int? get totalTime;
  @override
  int? get maxHeartRate;
  @override
  int? get maxCadence;
  @override
  @JsonKey(ignore: true)
  _$$RouteImplCopyWith<_$RouteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RouteFavorite _$RouteFavoriteFromJson(Map<String, dynamic> json) {
  return _RouteFavorite.fromJson(json);
}

/// @nodoc
mixin _$RouteFavorite {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get routeId => throw _privateConstructorUsedError;

  /// 标签: want_to_run / completed
  String get tag => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RouteFavoriteCopyWith<RouteFavorite> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteFavoriteCopyWith<$Res> {
  factory $RouteFavoriteCopyWith(
          RouteFavorite value, $Res Function(RouteFavorite) then) =
      _$RouteFavoriteCopyWithImpl<$Res, RouteFavorite>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String routeId,
      String tag,
      DateTime? createdAt});
}

/// @nodoc
class _$RouteFavoriteCopyWithImpl<$Res, $Val extends RouteFavorite>
    implements $RouteFavoriteCopyWith<$Res> {
  _$RouteFavoriteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? routeId = null,
    Object? tag = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      routeId: null == routeId
          ? _value.routeId
          : routeId // ignore: cast_nullable_to_non_nullable
              as String,
      tag: null == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RouteFavoriteImplCopyWith<$Res>
    implements $RouteFavoriteCopyWith<$Res> {
  factory _$$RouteFavoriteImplCopyWith(
          _$RouteFavoriteImpl value, $Res Function(_$RouteFavoriteImpl) then) =
      __$$RouteFavoriteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String routeId,
      String tag,
      DateTime? createdAt});
}

/// @nodoc
class __$$RouteFavoriteImplCopyWithImpl<$Res>
    extends _$RouteFavoriteCopyWithImpl<$Res, _$RouteFavoriteImpl>
    implements _$$RouteFavoriteImplCopyWith<$Res> {
  __$$RouteFavoriteImplCopyWithImpl(
      _$RouteFavoriteImpl _value, $Res Function(_$RouteFavoriteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? routeId = null,
    Object? tag = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$RouteFavoriteImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      routeId: null == routeId
          ? _value.routeId
          : routeId // ignore: cast_nullable_to_non_nullable
              as String,
      tag: null == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteFavoriteImpl implements _RouteFavorite {
  const _$RouteFavoriteImpl(
      {required this.id,
      required this.userId,
      required this.routeId,
      this.tag = 'want_to_run',
      this.createdAt});

  factory _$RouteFavoriteImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteFavoriteImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String routeId;

  /// 标签: want_to_run / completed
  @override
  @JsonKey()
  final String tag;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'RouteFavorite(id: $id, userId: $userId, routeId: $routeId, tag: $tag, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteFavoriteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.tag, tag) || other.tag == tag) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, userId, routeId, tag, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteFavoriteImplCopyWith<_$RouteFavoriteImpl> get copyWith =>
      __$$RouteFavoriteImplCopyWithImpl<_$RouteFavoriteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteFavoriteImplToJson(
      this,
    );
  }
}

abstract class _RouteFavorite implements RouteFavorite {
  const factory _RouteFavorite(
      {required final String id,
      required final String userId,
      required final String routeId,
      final String tag,
      final DateTime? createdAt}) = _$RouteFavoriteImpl;

  factory _RouteFavorite.fromJson(Map<String, dynamic> json) =
      _$RouteFavoriteImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get routeId;
  @override

  /// 标签: want_to_run / completed
  String get tag;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$RouteFavoriteImplCopyWith<_$RouteFavoriteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RouteLeaderboardEntry {
  String get id => throw _privateConstructorUsedError;
  String get routeId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get userNickname => throw _privateConstructorUsedError;
  String? get userAvatar => throw _privateConstructorUsedError;
  String get runId => throw _privateConstructorUsedError;

  /// 总用时（秒）
  int get totalTime => throw _privateConstructorUsedError;

  /// 平均配速（秒/公里）
  int? get avgPace => throw _privateConstructorUsedError;

  /// 在此路线打卡次数
  int get runCount => throw _privateConstructorUsedError;

  /// 平均心率
  int? get avgHeartRate => throw _privateConstructorUsedError;

  /// 平均步频
  int? get avgCadence => throw _privateConstructorUsedError;
  DateTime? get recordedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RouteLeaderboardEntryCopyWith<RouteLeaderboardEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteLeaderboardEntryCopyWith<$Res> {
  factory $RouteLeaderboardEntryCopyWith(RouteLeaderboardEntry value,
          $Res Function(RouteLeaderboardEntry) then) =
      _$RouteLeaderboardEntryCopyWithImpl<$Res, RouteLeaderboardEntry>;
  @useResult
  $Res call(
      {String id,
      String routeId,
      String userId,
      String? userNickname,
      String? userAvatar,
      String runId,
      int totalTime,
      int? avgPace,
      int runCount,
      int? avgHeartRate,
      int? avgCadence,
      DateTime? recordedAt});
}

/// @nodoc
class _$RouteLeaderboardEntryCopyWithImpl<$Res,
        $Val extends RouteLeaderboardEntry>
    implements $RouteLeaderboardEntryCopyWith<$Res> {
  _$RouteLeaderboardEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? userId = null,
    Object? userNickname = freezed,
    Object? userAvatar = freezed,
    Object? runId = null,
    Object? totalTime = null,
    Object? avgPace = freezed,
    Object? runCount = null,
    Object? avgHeartRate = freezed,
    Object? avgCadence = freezed,
    Object? recordedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routeId: null == routeId
          ? _value.routeId
          : routeId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userNickname: freezed == userNickname
          ? _value.userNickname
          : userNickname // ignore: cast_nullable_to_non_nullable
              as String?,
      userAvatar: freezed == userAvatar
          ? _value.userAvatar
          : userAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
      totalTime: null == totalTime
          ? _value.totalTime
          : totalTime // ignore: cast_nullable_to_non_nullable
              as int,
      avgPace: freezed == avgPace
          ? _value.avgPace
          : avgPace // ignore: cast_nullable_to_non_nullable
              as int?,
      runCount: null == runCount
          ? _value.runCount
          : runCount // ignore: cast_nullable_to_non_nullable
              as int,
      avgHeartRate: freezed == avgHeartRate
          ? _value.avgHeartRate
          : avgHeartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      avgCadence: freezed == avgCadence
          ? _value.avgCadence
          : avgCadence // ignore: cast_nullable_to_non_nullable
              as int?,
      recordedAt: freezed == recordedAt
          ? _value.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RouteLeaderboardEntryImplCopyWith<$Res>
    implements $RouteLeaderboardEntryCopyWith<$Res> {
  factory _$$RouteLeaderboardEntryImplCopyWith(
          _$RouteLeaderboardEntryImpl value,
          $Res Function(_$RouteLeaderboardEntryImpl) then) =
      __$$RouteLeaderboardEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String routeId,
      String userId,
      String? userNickname,
      String? userAvatar,
      String runId,
      int totalTime,
      int? avgPace,
      int runCount,
      int? avgHeartRate,
      int? avgCadence,
      DateTime? recordedAt});
}

/// @nodoc
class __$$RouteLeaderboardEntryImplCopyWithImpl<$Res>
    extends _$RouteLeaderboardEntryCopyWithImpl<$Res,
        _$RouteLeaderboardEntryImpl>
    implements _$$RouteLeaderboardEntryImplCopyWith<$Res> {
  __$$RouteLeaderboardEntryImplCopyWithImpl(_$RouteLeaderboardEntryImpl _value,
      $Res Function(_$RouteLeaderboardEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? userId = null,
    Object? userNickname = freezed,
    Object? userAvatar = freezed,
    Object? runId = null,
    Object? totalTime = null,
    Object? avgPace = freezed,
    Object? runCount = null,
    Object? avgHeartRate = freezed,
    Object? avgCadence = freezed,
    Object? recordedAt = freezed,
  }) {
    return _then(_$RouteLeaderboardEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routeId: null == routeId
          ? _value.routeId
          : routeId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userNickname: freezed == userNickname
          ? _value.userNickname
          : userNickname // ignore: cast_nullable_to_non_nullable
              as String?,
      userAvatar: freezed == userAvatar
          ? _value.userAvatar
          : userAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
      totalTime: null == totalTime
          ? _value.totalTime
          : totalTime // ignore: cast_nullable_to_non_nullable
              as int,
      avgPace: freezed == avgPace
          ? _value.avgPace
          : avgPace // ignore: cast_nullable_to_non_nullable
              as int?,
      runCount: null == runCount
          ? _value.runCount
          : runCount // ignore: cast_nullable_to_non_nullable
              as int,
      avgHeartRate: freezed == avgHeartRate
          ? _value.avgHeartRate
          : avgHeartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      avgCadence: freezed == avgCadence
          ? _value.avgCadence
          : avgCadence // ignore: cast_nullable_to_non_nullable
              as int?,
      recordedAt: freezed == recordedAt
          ? _value.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$RouteLeaderboardEntryImpl implements _RouteLeaderboardEntry {
  const _$RouteLeaderboardEntryImpl(
      {required this.id,
      required this.routeId,
      required this.userId,
      this.userNickname,
      this.userAvatar,
      required this.runId,
      required this.totalTime,
      this.avgPace,
      this.runCount = 0,
      this.avgHeartRate,
      this.avgCadence,
      this.recordedAt});

  @override
  final String id;
  @override
  final String routeId;
  @override
  final String userId;
  @override
  final String? userNickname;
  @override
  final String? userAvatar;
  @override
  final String runId;

  /// 总用时（秒）
  @override
  final int totalTime;

  /// 平均配速（秒/公里）
  @override
  final int? avgPace;

  /// 在此路线打卡次数
  @override
  @JsonKey()
  final int runCount;

  /// 平均心率
  @override
  final int? avgHeartRate;

  /// 平均步频
  @override
  final int? avgCadence;
  @override
  final DateTime? recordedAt;

  @override
  String toString() {
    return 'RouteLeaderboardEntry(id: $id, routeId: $routeId, userId: $userId, userNickname: $userNickname, userAvatar: $userAvatar, runId: $runId, totalTime: $totalTime, avgPace: $avgPace, runCount: $runCount, avgHeartRate: $avgHeartRate, avgCadence: $avgCadence, recordedAt: $recordedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteLeaderboardEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userNickname, userNickname) ||
                other.userNickname == userNickname) &&
            (identical(other.userAvatar, userAvatar) ||
                other.userAvatar == userAvatar) &&
            (identical(other.runId, runId) || other.runId == runId) &&
            (identical(other.totalTime, totalTime) ||
                other.totalTime == totalTime) &&
            (identical(other.avgPace, avgPace) || other.avgPace == avgPace) &&
            (identical(other.runCount, runCount) ||
                other.runCount == runCount) &&
            (identical(other.avgHeartRate, avgHeartRate) ||
                other.avgHeartRate == avgHeartRate) &&
            (identical(other.avgCadence, avgCadence) ||
                other.avgCadence == avgCadence) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      routeId,
      userId,
      userNickname,
      userAvatar,
      runId,
      totalTime,
      avgPace,
      runCount,
      avgHeartRate,
      avgCadence,
      recordedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteLeaderboardEntryImplCopyWith<_$RouteLeaderboardEntryImpl>
      get copyWith => __$$RouteLeaderboardEntryImplCopyWithImpl<
          _$RouteLeaderboardEntryImpl>(this, _$identity);
}

abstract class _RouteLeaderboardEntry implements RouteLeaderboardEntry {
  const factory _RouteLeaderboardEntry(
      {required final String id,
      required final String routeId,
      required final String userId,
      final String? userNickname,
      final String? userAvatar,
      required final String runId,
      required final int totalTime,
      final int? avgPace,
      final int runCount,
      final int? avgHeartRate,
      final int? avgCadence,
      final DateTime? recordedAt}) = _$RouteLeaderboardEntryImpl;

  @override
  String get id;
  @override
  String get routeId;
  @override
  String get userId;
  @override
  String? get userNickname;
  @override
  String? get userAvatar;
  @override
  String get runId;
  @override

  /// 总用时（秒）
  int get totalTime;
  @override

  /// 平均配速（秒/公里）
  int? get avgPace;
  @override

  /// 在此路线打卡次数
  int get runCount;
  @override

  /// 平均心率
  int? get avgHeartRate;
  @override

  /// 平均步频
  int? get avgCadence;
  @override
  DateTime? get recordedAt;
  @override
  @JsonKey(ignore: true)
  _$$RouteLeaderboardEntryImplCopyWith<_$RouteLeaderboardEntryImpl>
      get copyWith => throw _privateConstructorUsedError;
}
