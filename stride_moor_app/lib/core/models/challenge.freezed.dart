// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'challenge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Challenge {
  String get id => throw _privateConstructorUsedError;
  String get routeId => throw _privateConstructorUsedError;

  /// 挑战者
  String get challengerId => throw _privateConstructorUsedError;
  String? get challengerRunId => throw _privateConstructorUsedError;

  /// 被邀请者
  String? get inviteeId => throw _privateConstructorUsedError;

  /// 陪跑模式: real_replay / constant / rabbit / tortoise_hare / goal
  String get ghostMode => throw _privateConstructorUsedError;

  /// 目标挑战维度: pace / heart_rate / cadence / stride_length
  String? get goalMetric => throw _privateConstructorUsedError;

  /// 状态: pending / running / completed
  String get status => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChallengeCopyWith<Challenge> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChallengeCopyWith<$Res> {
  factory $ChallengeCopyWith(Challenge value, $Res Function(Challenge) then) =
      _$ChallengeCopyWithImpl<$Res, Challenge>;
  @useResult
  $Res call(
      {String id,
      String routeId,
      String challengerId,
      String? challengerRunId,
      String? inviteeId,
      String ghostMode,
      String? goalMetric,
      String status,
      DateTime? createdAt,
      DateTime? completedAt});
}

/// @nodoc
class _$ChallengeCopyWithImpl<$Res, $Val extends Challenge>
    implements $ChallengeCopyWith<$Res> {
  _$ChallengeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? challengerId = null,
    Object? challengerRunId = freezed,
    Object? inviteeId = freezed,
    Object? ghostMode = null,
    Object? goalMetric = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
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
      challengerId: null == challengerId
          ? _value.challengerId
          : challengerId // ignore: cast_nullable_to_non_nullable
              as String,
      challengerRunId: freezed == challengerRunId
          ? _value.challengerRunId
          : challengerRunId // ignore: cast_nullable_to_non_nullable
              as String?,
      inviteeId: freezed == inviteeId
          ? _value.inviteeId
          : inviteeId // ignore: cast_nullable_to_non_nullable
              as String?,
      ghostMode: null == ghostMode
          ? _value.ghostMode
          : ghostMode // ignore: cast_nullable_to_non_nullable
              as String,
      goalMetric: freezed == goalMetric
          ? _value.goalMetric
          : goalMetric // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChallengeImplCopyWith<$Res>
    implements $ChallengeCopyWith<$Res> {
  factory _$$ChallengeImplCopyWith(
          _$ChallengeImpl value, $Res Function(_$ChallengeImpl) then) =
      __$$ChallengeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String routeId,
      String challengerId,
      String? challengerRunId,
      String? inviteeId,
      String ghostMode,
      String? goalMetric,
      String status,
      DateTime? createdAt,
      DateTime? completedAt});
}

/// @nodoc
class __$$ChallengeImplCopyWithImpl<$Res>
    extends _$ChallengeCopyWithImpl<$Res, _$ChallengeImpl>
    implements _$$ChallengeImplCopyWith<$Res> {
  __$$ChallengeImplCopyWithImpl(
      _$ChallengeImpl _value, $Res Function(_$ChallengeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routeId = null,
    Object? challengerId = null,
    Object? challengerRunId = freezed,
    Object? inviteeId = freezed,
    Object? ghostMode = null,
    Object? goalMetric = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(_$ChallengeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routeId: null == routeId
          ? _value.routeId
          : routeId // ignore: cast_nullable_to_non_nullable
              as String,
      challengerId: null == challengerId
          ? _value.challengerId
          : challengerId // ignore: cast_nullable_to_non_nullable
              as String,
      challengerRunId: freezed == challengerRunId
          ? _value.challengerRunId
          : challengerRunId // ignore: cast_nullable_to_non_nullable
              as String?,
      inviteeId: freezed == inviteeId
          ? _value.inviteeId
          : inviteeId // ignore: cast_nullable_to_non_nullable
              as String?,
      ghostMode: null == ghostMode
          ? _value.ghostMode
          : ghostMode // ignore: cast_nullable_to_non_nullable
              as String,
      goalMetric: freezed == goalMetric
          ? _value.goalMetric
          : goalMetric // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$ChallengeImpl implements _Challenge {
  const _$ChallengeImpl(
      {required this.id,
      required this.routeId,
      required this.challengerId,
      this.challengerRunId,
      this.inviteeId,
      this.ghostMode = 'real_replay',
      this.goalMetric,
      this.status = 'pending',
      this.createdAt,
      this.completedAt});

  @override
  final String id;
  @override
  final String routeId;

  /// 挑战者
  @override
  final String challengerId;
  @override
  final String? challengerRunId;

  /// 被邀请者
  @override
  final String? inviteeId;

  /// 陪跑模式: real_replay / constant / rabbit / tortoise_hare / goal
  @override
  @JsonKey()
  final String ghostMode;

  /// 目标挑战维度: pace / heart_rate / cadence / stride_length
  @override
  final String? goalMetric;

  /// 状态: pending / running / completed
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'Challenge(id: $id, routeId: $routeId, challengerId: $challengerId, challengerRunId: $challengerRunId, inviteeId: $inviteeId, ghostMode: $ghostMode, goalMetric: $goalMetric, status: $status, createdAt: $createdAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChallengeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.challengerId, challengerId) ||
                other.challengerId == challengerId) &&
            (identical(other.challengerRunId, challengerRunId) ||
                other.challengerRunId == challengerRunId) &&
            (identical(other.inviteeId, inviteeId) ||
                other.inviteeId == inviteeId) &&
            (identical(other.ghostMode, ghostMode) ||
                other.ghostMode == ghostMode) &&
            (identical(other.goalMetric, goalMetric) ||
                other.goalMetric == goalMetric) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      routeId,
      challengerId,
      challengerRunId,
      inviteeId,
      ghostMode,
      goalMetric,
      status,
      createdAt,
      completedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChallengeImplCopyWith<_$ChallengeImpl> get copyWith =>
      __$$ChallengeImplCopyWithImpl<_$ChallengeImpl>(this, _$identity);
}

abstract class _Challenge implements Challenge {
  const factory _Challenge(
      {required final String id,
      required final String routeId,
      required final String challengerId,
      final String? challengerRunId,
      final String? inviteeId,
      final String ghostMode,
      final String? goalMetric,
      final String status,
      final DateTime? createdAt,
      final DateTime? completedAt}) = _$ChallengeImpl;

  @override
  String get id;
  @override
  String get routeId;
  @override

  /// 挑战者
  String get challengerId;
  @override
  String? get challengerRunId;
  @override

  /// 被邀请者
  String? get inviteeId;
  @override

  /// 陪跑模式: real_replay / constant / rabbit / tortoise_hare / goal
  String get ghostMode;
  @override

  /// 目标挑战维度: pace / heart_rate / cadence / stride_length
  String? get goalMetric;
  @override

  /// 状态: pending / running / completed
  String get status;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get completedAt;
  @override
  @JsonKey(ignore: true)
  _$$ChallengeImplCopyWith<_$ChallengeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Comparison {
  String get id => throw _privateConstructorUsedError;
  String? get challengeId => throw _privateConstructorUsedError;
  String get runAId => throw _privateConstructorUsedError;
  String get runBId => throw _privateConstructorUsedError;

  /// 总体差异摘要
  Map<String, dynamic>? get overallDiff => throw _privateConstructorUsedError;

  /// 分段对比详情 JSON
  Map<String, dynamic> get splitsJson => throw _privateConstructorUsedError;

  /// AI诊断建议 JSON
  Map<String, dynamic> get diagnosisJson => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ComparisonCopyWith<Comparison> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ComparisonCopyWith<$Res> {
  factory $ComparisonCopyWith(
          Comparison value, $Res Function(Comparison) then) =
      _$ComparisonCopyWithImpl<$Res, Comparison>;
  @useResult
  $Res call(
      {String id,
      String? challengeId,
      String runAId,
      String runBId,
      Map<String, dynamic>? overallDiff,
      Map<String, dynamic> splitsJson,
      Map<String, dynamic> diagnosisJson,
      DateTime? createdAt});
}

/// @nodoc
class _$ComparisonCopyWithImpl<$Res, $Val extends Comparison>
    implements $ComparisonCopyWith<$Res> {
  _$ComparisonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? challengeId = freezed,
    Object? runAId = null,
    Object? runBId = null,
    Object? overallDiff = freezed,
    Object? splitsJson = null,
    Object? diagnosisJson = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      challengeId: freezed == challengeId
          ? _value.challengeId
          : challengeId // ignore: cast_nullable_to_non_nullable
              as String?,
      runAId: null == runAId
          ? _value.runAId
          : runAId // ignore: cast_nullable_to_non_nullable
              as String,
      runBId: null == runBId
          ? _value.runBId
          : runBId // ignore: cast_nullable_to_non_nullable
              as String,
      overallDiff: freezed == overallDiff
          ? _value.overallDiff
          : overallDiff // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      splitsJson: null == splitsJson
          ? _value.splitsJson
          : splitsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      diagnosisJson: null == diagnosisJson
          ? _value.diagnosisJson
          : diagnosisJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ComparisonImplCopyWith<$Res>
    implements $ComparisonCopyWith<$Res> {
  factory _$$ComparisonImplCopyWith(
          _$ComparisonImpl value, $Res Function(_$ComparisonImpl) then) =
      __$$ComparisonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? challengeId,
      String runAId,
      String runBId,
      Map<String, dynamic>? overallDiff,
      Map<String, dynamic> splitsJson,
      Map<String, dynamic> diagnosisJson,
      DateTime? createdAt});
}

/// @nodoc
class __$$ComparisonImplCopyWithImpl<$Res>
    extends _$ComparisonCopyWithImpl<$Res, _$ComparisonImpl>
    implements _$$ComparisonImplCopyWith<$Res> {
  __$$ComparisonImplCopyWithImpl(
      _$ComparisonImpl _value, $Res Function(_$ComparisonImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? challengeId = freezed,
    Object? runAId = null,
    Object? runBId = null,
    Object? overallDiff = freezed,
    Object? splitsJson = null,
    Object? diagnosisJson = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$ComparisonImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      challengeId: freezed == challengeId
          ? _value.challengeId
          : challengeId // ignore: cast_nullable_to_non_nullable
              as String?,
      runAId: null == runAId
          ? _value.runAId
          : runAId // ignore: cast_nullable_to_non_nullable
              as String,
      runBId: null == runBId
          ? _value.runBId
          : runBId // ignore: cast_nullable_to_non_nullable
              as String,
      overallDiff: freezed == overallDiff
          ? _value._overallDiff
          : overallDiff // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      splitsJson: null == splitsJson
          ? _value._splitsJson
          : splitsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      diagnosisJson: null == diagnosisJson
          ? _value._diagnosisJson
          : diagnosisJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$ComparisonImpl implements _Comparison {
  const _$ComparisonImpl(
      {required this.id,
      this.challengeId,
      required this.runAId,
      required this.runBId,
      final Map<String, dynamic>? overallDiff,
      final Map<String, dynamic> splitsJson = const {},
      final Map<String, dynamic> diagnosisJson = const {},
      this.createdAt})
      : _overallDiff = overallDiff,
        _splitsJson = splitsJson,
        _diagnosisJson = diagnosisJson;

  @override
  final String id;
  @override
  final String? challengeId;
  @override
  final String runAId;
  @override
  final String runBId;

  /// 总体差异摘要
  final Map<String, dynamic>? _overallDiff;

  /// 总体差异摘要
  @override
  Map<String, dynamic>? get overallDiff {
    final value = _overallDiff;
    if (value == null) return null;
    if (_overallDiff is EqualUnmodifiableMapView) return _overallDiff;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// 分段对比详情 JSON
  final Map<String, dynamic> _splitsJson;

  /// 分段对比详情 JSON
  @override
  @JsonKey()
  Map<String, dynamic> get splitsJson {
    if (_splitsJson is EqualUnmodifiableMapView) return _splitsJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_splitsJson);
  }

  /// AI诊断建议 JSON
  final Map<String, dynamic> _diagnosisJson;

  /// AI诊断建议 JSON
  @override
  @JsonKey()
  Map<String, dynamic> get diagnosisJson {
    if (_diagnosisJson is EqualUnmodifiableMapView) return _diagnosisJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_diagnosisJson);
  }

  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Comparison(id: $id, challengeId: $challengeId, runAId: $runAId, runBId: $runBId, overallDiff: $overallDiff, splitsJson: $splitsJson, diagnosisJson: $diagnosisJson, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ComparisonImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.challengeId, challengeId) ||
                other.challengeId == challengeId) &&
            (identical(other.runAId, runAId) || other.runAId == runAId) &&
            (identical(other.runBId, runBId) || other.runBId == runBId) &&
            const DeepCollectionEquality()
                .equals(other._overallDiff, _overallDiff) &&
            const DeepCollectionEquality()
                .equals(other._splitsJson, _splitsJson) &&
            const DeepCollectionEquality()
                .equals(other._diagnosisJson, _diagnosisJson) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      challengeId,
      runAId,
      runBId,
      const DeepCollectionEquality().hash(_overallDiff),
      const DeepCollectionEquality().hash(_splitsJson),
      const DeepCollectionEquality().hash(_diagnosisJson),
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ComparisonImplCopyWith<_$ComparisonImpl> get copyWith =>
      __$$ComparisonImplCopyWithImpl<_$ComparisonImpl>(this, _$identity);
}

abstract class _Comparison implements Comparison {
  const factory _Comparison(
      {required final String id,
      final String? challengeId,
      required final String runAId,
      required final String runBId,
      final Map<String, dynamic>? overallDiff,
      final Map<String, dynamic> splitsJson,
      final Map<String, dynamic> diagnosisJson,
      final DateTime? createdAt}) = _$ComparisonImpl;

  @override
  String get id;
  @override
  String? get challengeId;
  @override
  String get runAId;
  @override
  String get runBId;
  @override

  /// 总体差异摘要
  Map<String, dynamic>? get overallDiff;
  @override

  /// 分段对比详情 JSON
  Map<String, dynamic> get splitsJson;
  @override

  /// AI诊断建议 JSON
  Map<String, dynamic> get diagnosisJson;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ComparisonImplCopyWith<_$ComparisonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
