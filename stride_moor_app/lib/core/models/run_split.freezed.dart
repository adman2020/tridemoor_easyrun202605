// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run_split.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RunSplit {
  String get id => throw _privateConstructorUsedError;
  String get runId => throw _privateConstructorUsedError;
  int get splitIndex => throw _privateConstructorUsedError;

  /// 分段距离（米）
  double get distance => throw _privateConstructorUsedError;

  /// 分段用时（秒）
  int get time => throw _privateConstructorUsedError;

  /// 分段配速（秒/公里）
  int? get pace => throw _privateConstructorUsedError;

  /// 平均心率
  int? get avgHeartRate => throw _privateConstructorUsedError;

  /// 平均步频
  int? get avgCadence => throw _privateConstructorUsedError;

  /// 平均步幅（米）
  double? get avgStrideLength => throw _privateConstructorUsedError;

  /// 累计爬升（米）
  double get elevationGain => throw _privateConstructorUsedError;

  /// 累计下降（米）
  double get elevationLoss => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RunSplitCopyWith<RunSplit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RunSplitCopyWith<$Res> {
  factory $RunSplitCopyWith(RunSplit value, $Res Function(RunSplit) then) =
      _$RunSplitCopyWithImpl<$Res, RunSplit>;
  @useResult
  $Res call(
      {String id,
      String runId,
      int splitIndex,
      double distance,
      int time,
      int? pace,
      int? avgHeartRate,
      int? avgCadence,
      double? avgStrideLength,
      double elevationGain,
      double elevationLoss});
}

/// @nodoc
class _$RunSplitCopyWithImpl<$Res, $Val extends RunSplit>
    implements $RunSplitCopyWith<$Res> {
  _$RunSplitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? runId = null,
    Object? splitIndex = null,
    Object? distance = null,
    Object? time = null,
    Object? pace = freezed,
    Object? avgHeartRate = freezed,
    Object? avgCadence = freezed,
    Object? avgStrideLength = freezed,
    Object? elevationGain = null,
    Object? elevationLoss = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
      splitIndex: null == splitIndex
          ? _value.splitIndex
          : splitIndex // ignore: cast_nullable_to_non_nullable
              as int,
      distance: null == distance
          ? _value.distance
          : distance // ignore: cast_nullable_to_non_nullable
              as double,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as int,
      pace: freezed == pace
          ? _value.pace
          : pace // ignore: cast_nullable_to_non_nullable
              as int?,
      avgHeartRate: freezed == avgHeartRate
          ? _value.avgHeartRate
          : avgHeartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      avgCadence: freezed == avgCadence
          ? _value.avgCadence
          : avgCadence // ignore: cast_nullable_to_non_nullable
              as int?,
      avgStrideLength: freezed == avgStrideLength
          ? _value.avgStrideLength
          : avgStrideLength // ignore: cast_nullable_to_non_nullable
              as double?,
      elevationGain: null == elevationGain
          ? _value.elevationGain
          : elevationGain // ignore: cast_nullable_to_non_nullable
              as double,
      elevationLoss: null == elevationLoss
          ? _value.elevationLoss
          : elevationLoss // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RunSplitImplCopyWith<$Res>
    implements $RunSplitCopyWith<$Res> {
  factory _$$RunSplitImplCopyWith(
          _$RunSplitImpl value, $Res Function(_$RunSplitImpl) then) =
      __$$RunSplitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String runId,
      int splitIndex,
      double distance,
      int time,
      int? pace,
      int? avgHeartRate,
      int? avgCadence,
      double? avgStrideLength,
      double elevationGain,
      double elevationLoss});
}

/// @nodoc
class __$$RunSplitImplCopyWithImpl<$Res>
    extends _$RunSplitCopyWithImpl<$Res, _$RunSplitImpl>
    implements _$$RunSplitImplCopyWith<$Res> {
  __$$RunSplitImplCopyWithImpl(
      _$RunSplitImpl _value, $Res Function(_$RunSplitImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? runId = null,
    Object? splitIndex = null,
    Object? distance = null,
    Object? time = null,
    Object? pace = freezed,
    Object? avgHeartRate = freezed,
    Object? avgCadence = freezed,
    Object? avgStrideLength = freezed,
    Object? elevationGain = null,
    Object? elevationLoss = null,
  }) {
    return _then(_$RunSplitImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
      splitIndex: null == splitIndex
          ? _value.splitIndex
          : splitIndex // ignore: cast_nullable_to_non_nullable
              as int,
      distance: null == distance
          ? _value.distance
          : distance // ignore: cast_nullable_to_non_nullable
              as double,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as int,
      pace: freezed == pace
          ? _value.pace
          : pace // ignore: cast_nullable_to_non_nullable
              as int?,
      avgHeartRate: freezed == avgHeartRate
          ? _value.avgHeartRate
          : avgHeartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      avgCadence: freezed == avgCadence
          ? _value.avgCadence
          : avgCadence // ignore: cast_nullable_to_non_nullable
              as int?,
      avgStrideLength: freezed == avgStrideLength
          ? _value.avgStrideLength
          : avgStrideLength // ignore: cast_nullable_to_non_nullable
              as double?,
      elevationGain: null == elevationGain
          ? _value.elevationGain
          : elevationGain // ignore: cast_nullable_to_non_nullable
              as double,
      elevationLoss: null == elevationLoss
          ? _value.elevationLoss
          : elevationLoss // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$RunSplitImpl implements _RunSplit {
  const _$RunSplitImpl(
      {required this.id,
      required this.runId,
      required this.splitIndex,
      this.distance = 1000,
      required this.time,
      this.pace,
      this.avgHeartRate,
      this.avgCadence,
      this.avgStrideLength,
      this.elevationGain = 0,
      this.elevationLoss = 0});

  @override
  final String id;
  @override
  final String runId;
  @override
  final int splitIndex;

  /// 分段距离（米）
  @override
  @JsonKey()
  final double distance;

  /// 分段用时（秒）
  @override
  final int time;

  /// 分段配速（秒/公里）
  @override
  final int? pace;

  /// 平均心率
  @override
  final int? avgHeartRate;

  /// 平均步频
  @override
  final int? avgCadence;

  /// 平均步幅（米）
  @override
  final double? avgStrideLength;

  /// 累计爬升（米）
  @override
  @JsonKey()
  final double elevationGain;

  /// 累计下降（米）
  @override
  @JsonKey()
  final double elevationLoss;

  @override
  String toString() {
    return 'RunSplit(id: $id, runId: $runId, splitIndex: $splitIndex, distance: $distance, time: $time, pace: $pace, avgHeartRate: $avgHeartRate, avgCadence: $avgCadence, avgStrideLength: $avgStrideLength, elevationGain: $elevationGain, elevationLoss: $elevationLoss)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RunSplitImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.runId, runId) || other.runId == runId) &&
            (identical(other.splitIndex, splitIndex) ||
                other.splitIndex == splitIndex) &&
            (identical(other.distance, distance) ||
                other.distance == distance) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.pace, pace) || other.pace == pace) &&
            (identical(other.avgHeartRate, avgHeartRate) ||
                other.avgHeartRate == avgHeartRate) &&
            (identical(other.avgCadence, avgCadence) ||
                other.avgCadence == avgCadence) &&
            (identical(other.avgStrideLength, avgStrideLength) ||
                other.avgStrideLength == avgStrideLength) &&
            (identical(other.elevationGain, elevationGain) ||
                other.elevationGain == elevationGain) &&
            (identical(other.elevationLoss, elevationLoss) ||
                other.elevationLoss == elevationLoss));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      runId,
      splitIndex,
      distance,
      time,
      pace,
      avgHeartRate,
      avgCadence,
      avgStrideLength,
      elevationGain,
      elevationLoss);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RunSplitImplCopyWith<_$RunSplitImpl> get copyWith =>
      __$$RunSplitImplCopyWithImpl<_$RunSplitImpl>(this, _$identity);
}

abstract class _RunSplit implements RunSplit {
  const factory _RunSplit(
      {required final String id,
      required final String runId,
      required final int splitIndex,
      final double distance,
      required final int time,
      final int? pace,
      final int? avgHeartRate,
      final int? avgCadence,
      final double? avgStrideLength,
      final double elevationGain,
      final double elevationLoss}) = _$RunSplitImpl;

  @override
  String get id;
  @override
  String get runId;
  @override
  int get splitIndex;
  @override

  /// 分段距离（米）
  double get distance;
  @override

  /// 分段用时（秒）
  int get time;
  @override

  /// 分段配速（秒/公里）
  int? get pace;
  @override

  /// 平均心率
  int? get avgHeartRate;
  @override

  /// 平均步频
  int? get avgCadence;
  @override

  /// 平均步幅（米）
  double? get avgStrideLength;
  @override

  /// 累计爬升（米）
  double get elevationGain;
  @override

  /// 累计下降（米）
  double get elevationLoss;
  @override
  @JsonKey(ignore: true)
  _$$RunSplitImplCopyWith<_$RunSplitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
