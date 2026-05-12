// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Run {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;

  /// 关联路线ID（可选，独自跑可能无路线）
  String? get routeId => throw _privateConstructorUsedError;

  /// 开始时间（仅日期有效，精确时间请用 startTimeIso）
  DateTime get startTime => throw _privateConstructorUsedError;

  /// 结束时间（仅日期有效，精确时间请用 endTimeIso）
  DateTime? get endTime => throw _privateConstructorUsedError;

  /// 后端返回的原始 start_time ISO 字符串（时区信息完整）
  String? get startTimeIso => throw _privateConstructorUsedError;

  /// 后端返回的原始 end_time ISO 字符串（时区信息完整）
  String? get endTimeIso => throw _privateConstructorUsedError;

  /// 总距离（米）
  double get totalDistance => throw _privateConstructorUsedError;

  /// 总用时（秒）
  int get totalTime => throw _privateConstructorUsedError;

  /// 平均配速（秒/公里）
  int? get avgPace => throw _privateConstructorUsedError;

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

  /// 最大心率
  int? get maxHeartRate => throw _privateConstructorUsedError;

  /// 最大步频
  int? get maxCadence => throw _privateConstructorUsedError;

  /// 卡路里估算
  int? get calories => throw _privateConstructorUsedError;

  /// 天气
  String? get weather => throw _privateConstructorUsedError;

  /// 温度
  double? get temperature => throw _privateConstructorUsedError;

  /// GPX文件URL
  String? get gpxFileUrl => throw _privateConstructorUsedError;

  /// 设备类型
  String? get deviceType => throw _privateConstructorUsedError;

  /// 跑步模式
  String get mode => throw _privateConstructorUsedError;

  /// 分段数据
  List<RunSplit> get splits => throw _privateConstructorUsedError;

  /// 轨迹采样点（简化存储，完整数据存GPX）
  List<RunSample> get samples => throw _privateConstructorUsedError;

  /// 挑战的比拼指标（如 pace / heart_rate / cadence 等），仅挑战跑有
  String? get goalMetric => throw _privateConstructorUsedError;

  /// 伴跑/挑战跑的对手跑步记录（详情接口返回）
  Run? get opponentRun => throw _privateConstructorUsedError;

  /// GPS采样点最小外接矩形（用于伴跑/挑战前距离校验）
  RunBounds? get bounds => throw _privateConstructorUsedError;

  /// 伴跑/挑战跑的对手GPS轨迹采样点
  List<RunSample> get opponentSamples => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RunCopyWith<Run> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RunCopyWith<$Res> {
  factory $RunCopyWith(Run value, $Res Function(Run) then) =
      _$RunCopyWithImpl<$Res, Run>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String? routeId,
      DateTime startTime,
      DateTime? endTime,
      String? startTimeIso,
      String? endTimeIso,
      double totalDistance,
      int totalTime,
      int? avgPace,
      int? avgHeartRate,
      int? avgCadence,
      double? avgStrideLength,
      double elevationGain,
      double elevationLoss,
      int? maxHeartRate,
      int? maxCadence,
      int? calories,
      String? weather,
      double? temperature,
      String? gpxFileUrl,
      String? deviceType,
      String mode,
      List<RunSplit> splits,
      List<RunSample> samples,
      String? goalMetric,
      Run? opponentRun,
      RunBounds? bounds,
      List<RunSample> opponentSamples});

  $RunCopyWith<$Res>? get opponentRun;
}

/// @nodoc
class _$RunCopyWithImpl<$Res, $Val extends Run> implements $RunCopyWith<$Res> {
  _$RunCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? routeId = freezed,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? startTimeIso = freezed,
    Object? endTimeIso = freezed,
    Object? totalDistance = null,
    Object? totalTime = null,
    Object? avgPace = freezed,
    Object? avgHeartRate = freezed,
    Object? avgCadence = freezed,
    Object? avgStrideLength = freezed,
    Object? elevationGain = null,
    Object? elevationLoss = null,
    Object? maxHeartRate = freezed,
    Object? maxCadence = freezed,
    Object? calories = freezed,
    Object? weather = freezed,
    Object? temperature = freezed,
    Object? gpxFileUrl = freezed,
    Object? deviceType = freezed,
    Object? mode = null,
    Object? splits = null,
    Object? samples = null,
    Object? goalMetric = freezed,
    Object? opponentRun = freezed,
    Object? bounds = freezed,
    Object? opponentSamples = null,
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
      routeId: freezed == routeId
          ? _value.routeId
          : routeId // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startTimeIso: freezed == startTimeIso
          ? _value.startTimeIso
          : startTimeIso // ignore: cast_nullable_to_non_nullable
              as String?,
      endTimeIso: freezed == endTimeIso
          ? _value.endTimeIso
          : endTimeIso // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDistance: null == totalDistance
          ? _value.totalDistance
          : totalDistance // ignore: cast_nullable_to_non_nullable
              as double,
      totalTime: null == totalTime
          ? _value.totalTime
          : totalTime // ignore: cast_nullable_to_non_nullable
              as int,
      avgPace: freezed == avgPace
          ? _value.avgPace
          : avgPace // ignore: cast_nullable_to_non_nullable
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
      maxHeartRate: freezed == maxHeartRate
          ? _value.maxHeartRate
          : maxHeartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      maxCadence: freezed == maxCadence
          ? _value.maxCadence
          : maxCadence // ignore: cast_nullable_to_non_nullable
              as int?,
      calories: freezed == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int?,
      weather: freezed == weather
          ? _value.weather
          : weather // ignore: cast_nullable_to_non_nullable
              as String?,
      temperature: freezed == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double?,
      gpxFileUrl: freezed == gpxFileUrl
          ? _value.gpxFileUrl
          : gpxFileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceType: freezed == deviceType
          ? _value.deviceType
          : deviceType // ignore: cast_nullable_to_non_nullable
              as String?,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      splits: null == splits
          ? _value.splits
          : splits // ignore: cast_nullable_to_non_nullable
              as List<RunSplit>,
      samples: null == samples
          ? _value.samples
          : samples // ignore: cast_nullable_to_non_nullable
              as List<RunSample>,
      goalMetric: freezed == goalMetric
          ? _value.goalMetric
          : goalMetric // ignore: cast_nullable_to_non_nullable
              as String?,
      opponentRun: freezed == opponentRun
          ? _value.opponentRun
          : opponentRun // ignore: cast_nullable_to_non_nullable
              as Run?,
      bounds: freezed == bounds
          ? _value.bounds
          : bounds // ignore: cast_nullable_to_non_nullable
              as RunBounds?,
      opponentSamples: null == opponentSamples
          ? _value.opponentSamples
          : opponentSamples // ignore: cast_nullable_to_non_nullable
              as List<RunSample>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $RunCopyWith<$Res>? get opponentRun {
    if (_value.opponentRun == null) {
      return null;
    }

    return $RunCopyWith<$Res>(_value.opponentRun!, (value) {
      return _then(_value.copyWith(opponentRun: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RunImplCopyWith<$Res> implements $RunCopyWith<$Res> {
  factory _$$RunImplCopyWith(_$RunImpl value, $Res Function(_$RunImpl) then) =
      __$$RunImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String? routeId,
      DateTime startTime,
      DateTime? endTime,
      String? startTimeIso,
      String? endTimeIso,
      double totalDistance,
      int totalTime,
      int? avgPace,
      int? avgHeartRate,
      int? avgCadence,
      double? avgStrideLength,
      double elevationGain,
      double elevationLoss,
      int? maxHeartRate,
      int? maxCadence,
      int? calories,
      String? weather,
      double? temperature,
      String? gpxFileUrl,
      String? deviceType,
      String mode,
      List<RunSplit> splits,
      List<RunSample> samples,
      String? goalMetric,
      Run? opponentRun,
      RunBounds? bounds,
      List<RunSample> opponentSamples});

  @override
  $RunCopyWith<$Res>? get opponentRun;
}

/// @nodoc
class __$$RunImplCopyWithImpl<$Res> extends _$RunCopyWithImpl<$Res, _$RunImpl>
    implements _$$RunImplCopyWith<$Res> {
  __$$RunImplCopyWithImpl(_$RunImpl _value, $Res Function(_$RunImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? routeId = freezed,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? startTimeIso = freezed,
    Object? endTimeIso = freezed,
    Object? totalDistance = null,
    Object? totalTime = null,
    Object? avgPace = freezed,
    Object? avgHeartRate = freezed,
    Object? avgCadence = freezed,
    Object? avgStrideLength = freezed,
    Object? elevationGain = null,
    Object? elevationLoss = null,
    Object? maxHeartRate = freezed,
    Object? maxCadence = freezed,
    Object? calories = freezed,
    Object? weather = freezed,
    Object? temperature = freezed,
    Object? gpxFileUrl = freezed,
    Object? deviceType = freezed,
    Object? mode = null,
    Object? splits = null,
    Object? samples = null,
    Object? goalMetric = freezed,
    Object? opponentRun = freezed,
    Object? bounds = freezed,
    Object? opponentSamples = null,
  }) {
    return _then(_$RunImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      routeId: freezed == routeId
          ? _value.routeId
          : routeId // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startTimeIso: freezed == startTimeIso
          ? _value.startTimeIso
          : startTimeIso // ignore: cast_nullable_to_non_nullable
              as String?,
      endTimeIso: freezed == endTimeIso
          ? _value.endTimeIso
          : endTimeIso // ignore: cast_nullable_to_non_nullable
              as String?,
      totalDistance: null == totalDistance
          ? _value.totalDistance
          : totalDistance // ignore: cast_nullable_to_non_nullable
              as double,
      totalTime: null == totalTime
          ? _value.totalTime
          : totalTime // ignore: cast_nullable_to_non_nullable
              as int,
      avgPace: freezed == avgPace
          ? _value.avgPace
          : avgPace // ignore: cast_nullable_to_non_nullable
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
      maxHeartRate: freezed == maxHeartRate
          ? _value.maxHeartRate
          : maxHeartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      maxCadence: freezed == maxCadence
          ? _value.maxCadence
          : maxCadence // ignore: cast_nullable_to_non_nullable
              as int?,
      calories: freezed == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int?,
      weather: freezed == weather
          ? _value.weather
          : weather // ignore: cast_nullable_to_non_nullable
              as String?,
      temperature: freezed == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double?,
      gpxFileUrl: freezed == gpxFileUrl
          ? _value.gpxFileUrl
          : gpxFileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceType: freezed == deviceType
          ? _value.deviceType
          : deviceType // ignore: cast_nullable_to_non_nullable
              as String?,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      splits: null == splits
          ? _value._splits
          : splits // ignore: cast_nullable_to_non_nullable
              as List<RunSplit>,
      samples: null == samples
          ? _value._samples
          : samples // ignore: cast_nullable_to_non_nullable
              as List<RunSample>,
      goalMetric: freezed == goalMetric
          ? _value.goalMetric
          : goalMetric // ignore: cast_nullable_to_non_nullable
              as String?,
      opponentRun: freezed == opponentRun
          ? _value.opponentRun
          : opponentRun // ignore: cast_nullable_to_non_nullable
              as Run?,
      bounds: freezed == bounds
          ? _value.bounds
          : bounds // ignore: cast_nullable_to_non_nullable
              as RunBounds?,
      opponentSamples: null == opponentSamples
          ? _value._opponentSamples
          : opponentSamples // ignore: cast_nullable_to_non_nullable
              as List<RunSample>,
    ));
  }
}

/// @nodoc

class _$RunImpl implements _Run {
  const _$RunImpl(
      {required this.id,
      required this.userId,
      this.routeId,
      required this.startTime,
      this.endTime,
      this.startTimeIso,
      this.endTimeIso,
      this.totalDistance = 0,
      this.totalTime = 0,
      this.avgPace,
      this.avgHeartRate,
      this.avgCadence,
      this.avgStrideLength,
      this.elevationGain = 0,
      this.elevationLoss = 0,
      this.maxHeartRate,
      this.maxCadence,
      this.calories,
      this.weather,
      this.temperature,
      this.gpxFileUrl,
      this.deviceType,
      this.mode = 'solo',
      final List<RunSplit> splits = const [],
      final List<RunSample> samples = const [],
      this.goalMetric,
      this.opponentRun,
      this.bounds,
      final List<RunSample> opponentSamples = const []})
      : _splits = splits,
        _samples = samples,
        _opponentSamples = opponentSamples;

  @override
  final String id;
  @override
  final String userId;

  /// 关联路线ID（可选，独自跑可能无路线）
  @override
  final String? routeId;

  /// 开始时间（仅日期有效，精确时间请用 startTimeIso）
  @override
  final DateTime startTime;

  /// 结束时间（仅日期有效，精确时间请用 endTimeIso）
  @override
  final DateTime? endTime;

  /// 后端返回的原始 start_time ISO 字符串（时区信息完整）
  @override
  final String? startTimeIso;

  /// 后端返回的原始 end_time ISO 字符串（时区信息完整）
  @override
  final String? endTimeIso;

  /// 总距离（米）
  @override
  @JsonKey()
  final double totalDistance;

  /// 总用时（秒）
  @override
  @JsonKey()
  final int totalTime;

  /// 平均配速（秒/公里）
  @override
  final int? avgPace;

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

  /// 最大心率
  @override
  final int? maxHeartRate;

  /// 最大步频
  @override
  final int? maxCadence;

  /// 卡路里估算
  @override
  final int? calories;

  /// 天气
  @override
  final String? weather;

  /// 温度
  @override
  final double? temperature;

  /// GPX文件URL
  @override
  final String? gpxFileUrl;

  /// 设备类型
  @override
  final String? deviceType;

  /// 跑步模式
  @override
  @JsonKey()
  final String mode;

  /// 分段数据
  final List<RunSplit> _splits;

  /// 分段数据
  @override
  @JsonKey()
  List<RunSplit> get splits {
    if (_splits is EqualUnmodifiableListView) return _splits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_splits);
  }

  /// 轨迹采样点（简化存储，完整数据存GPX）
  final List<RunSample> _samples;

  /// 轨迹采样点（简化存储，完整数据存GPX）
  @override
  @JsonKey()
  List<RunSample> get samples {
    if (_samples is EqualUnmodifiableListView) return _samples;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_samples);
  }

  /// 挑战的比拼指标（如 pace / heart_rate / cadence 等），仅挑战跑有
  @override
  final String? goalMetric;

  /// 伴跑/挑战跑的对手跑步记录（详情接口返回）
  @override
  final Run? opponentRun;

  /// GPS采样点最小外接矩形（用于伴跑/挑战前距离校验）
  @override
  final RunBounds? bounds;

  /// 伴跑/挑战跑的对手GPS轨迹采样点
  final List<RunSample> _opponentSamples;

  /// 伴跑/挑战跑的对手GPS轨迹采样点
  @override
  @JsonKey()
  List<RunSample> get opponentSamples {
    if (_opponentSamples is EqualUnmodifiableListView) return _opponentSamples;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_opponentSamples);
  }

  @override
  String toString() {
    return 'Run(id: $id, userId: $userId, routeId: $routeId, startTime: $startTime, endTime: $endTime, startTimeIso: $startTimeIso, endTimeIso: $endTimeIso, totalDistance: $totalDistance, totalTime: $totalTime, avgPace: $avgPace, avgHeartRate: $avgHeartRate, avgCadence: $avgCadence, avgStrideLength: $avgStrideLength, elevationGain: $elevationGain, elevationLoss: $elevationLoss, maxHeartRate: $maxHeartRate, maxCadence: $maxCadence, calories: $calories, weather: $weather, temperature: $temperature, gpxFileUrl: $gpxFileUrl, deviceType: $deviceType, mode: $mode, splits: $splits, samples: $samples, goalMetric: $goalMetric, opponentRun: $opponentRun, bounds: $bounds, opponentSamples: $opponentSamples)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RunImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.startTimeIso, startTimeIso) ||
                other.startTimeIso == startTimeIso) &&
            (identical(other.endTimeIso, endTimeIso) ||
                other.endTimeIso == endTimeIso) &&
            (identical(other.totalDistance, totalDistance) ||
                other.totalDistance == totalDistance) &&
            (identical(other.totalTime, totalTime) ||
                other.totalTime == totalTime) &&
            (identical(other.avgPace, avgPace) || other.avgPace == avgPace) &&
            (identical(other.avgHeartRate, avgHeartRate) ||
                other.avgHeartRate == avgHeartRate) &&
            (identical(other.avgCadence, avgCadence) ||
                other.avgCadence == avgCadence) &&
            (identical(other.avgStrideLength, avgStrideLength) ||
                other.avgStrideLength == avgStrideLength) &&
            (identical(other.elevationGain, elevationGain) ||
                other.elevationGain == elevationGain) &&
            (identical(other.elevationLoss, elevationLoss) ||
                other.elevationLoss == elevationLoss) &&
            (identical(other.maxHeartRate, maxHeartRate) ||
                other.maxHeartRate == maxHeartRate) &&
            (identical(other.maxCadence, maxCadence) ||
                other.maxCadence == maxCadence) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.weather, weather) || other.weather == weather) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature) &&
            (identical(other.gpxFileUrl, gpxFileUrl) ||
                other.gpxFileUrl == gpxFileUrl) &&
            (identical(other.deviceType, deviceType) ||
                other.deviceType == deviceType) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality().equals(other._splits, _splits) &&
            const DeepCollectionEquality().equals(other._samples, _samples) &&
            (identical(other.goalMetric, goalMetric) ||
                other.goalMetric == goalMetric) &&
            (identical(other.opponentRun, opponentRun) ||
                other.opponentRun == opponentRun) &&
            (identical(other.bounds, bounds) || other.bounds == bounds) &&
            const DeepCollectionEquality()
                .equals(other._opponentSamples, _opponentSamples));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        userId,
        routeId,
        startTime,
        endTime,
        startTimeIso,
        endTimeIso,
        totalDistance,
        totalTime,
        avgPace,
        avgHeartRate,
        avgCadence,
        avgStrideLength,
        elevationGain,
        elevationLoss,
        maxHeartRate,
        maxCadence,
        calories,
        weather,
        temperature,
        gpxFileUrl,
        deviceType,
        mode,
        const DeepCollectionEquality().hash(_splits),
        const DeepCollectionEquality().hash(_samples),
        goalMetric,
        opponentRun,
        bounds,
        const DeepCollectionEquality().hash(_opponentSamples)
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RunImplCopyWith<_$RunImpl> get copyWith =>
      __$$RunImplCopyWithImpl<_$RunImpl>(this, _$identity);
}

abstract class _Run implements Run {
  const factory _Run(
      {required final String id,
      required final String userId,
      final String? routeId,
      required final DateTime startTime,
      final DateTime? endTime,
      final String? startTimeIso,
      final String? endTimeIso,
      final double totalDistance,
      final int totalTime,
      final int? avgPace,
      final int? avgHeartRate,
      final int? avgCadence,
      final double? avgStrideLength,
      final double elevationGain,
      final double elevationLoss,
      final int? maxHeartRate,
      final int? maxCadence,
      final int? calories,
      final String? weather,
      final double? temperature,
      final String? gpxFileUrl,
      final String? deviceType,
      final String mode,
      final List<RunSplit> splits,
      final List<RunSample> samples,
      final String? goalMetric,
      final Run? opponentRun,
      final RunBounds? bounds,
      final List<RunSample> opponentSamples}) = _$RunImpl;

  @override
  String get id;
  @override
  String get userId;
  @override

  /// 关联路线ID（可选，独自跑可能无路线）
  String? get routeId;
  @override

  /// 开始时间（仅日期有效，精确时间请用 startTimeIso）
  DateTime get startTime;
  @override

  /// 结束时间（仅日期有效，精确时间请用 endTimeIso）
  DateTime? get endTime;
  @override

  /// 后端返回的原始 start_time ISO 字符串（时区信息完整）
  String? get startTimeIso;
  @override

  /// 后端返回的原始 end_time ISO 字符串（时区信息完整）
  String? get endTimeIso;
  @override

  /// 总距离（米）
  double get totalDistance;
  @override

  /// 总用时（秒）
  int get totalTime;
  @override

  /// 平均配速（秒/公里）
  int? get avgPace;
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

  /// 最大心率
  int? get maxHeartRate;
  @override

  /// 最大步频
  int? get maxCadence;
  @override

  /// 卡路里估算
  int? get calories;
  @override

  /// 天气
  String? get weather;
  @override

  /// 温度
  double? get temperature;
  @override

  /// GPX文件URL
  String? get gpxFileUrl;
  @override

  /// 设备类型
  String? get deviceType;
  @override

  /// 跑步模式
  String get mode;
  @override

  /// 分段数据
  List<RunSplit> get splits;
  @override

  /// 轨迹采样点（简化存储，完整数据存GPX）
  List<RunSample> get samples;
  @override

  /// 挑战的比拼指标（如 pace / heart_rate / cadence 等），仅挑战跑有
  String? get goalMetric;
  @override

  /// 伴跑/挑战跑的对手跑步记录（详情接口返回）
  Run? get opponentRun;
  @override

  /// GPS采样点最小外接矩形（用于伴跑/挑战前距离校验）
  RunBounds? get bounds;
  @override

  /// 伴跑/挑战跑的对手GPS轨迹采样点
  List<RunSample> get opponentSamples;
  @override
  @JsonKey(ignore: true)
  _$$RunImplCopyWith<_$RunImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RunSample {
  DateTime get timestamp => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double? get altitude => throw _privateConstructorUsedError;

  /// 瞬时配速（秒/公里）
  int? get pace => throw _privateConstructorUsedError;
  int? get heartRate => throw _privateConstructorUsedError;
  int? get cadence => throw _privateConstructorUsedError;
  double? get strideLength => throw _privateConstructorUsedError;

  /// 距起点距离（米）
  double get distanceFromStart => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RunSampleCopyWith<RunSample> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RunSampleCopyWith<$Res> {
  factory $RunSampleCopyWith(RunSample value, $Res Function(RunSample) then) =
      _$RunSampleCopyWithImpl<$Res, RunSample>;
  @useResult
  $Res call(
      {DateTime timestamp,
      double latitude,
      double longitude,
      double? altitude,
      int? pace,
      int? heartRate,
      int? cadence,
      double? strideLength,
      double distanceFromStart});
}

/// @nodoc
class _$RunSampleCopyWithImpl<$Res, $Val extends RunSample>
    implements $RunSampleCopyWith<$Res> {
  _$RunSampleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? altitude = freezed,
    Object? pace = freezed,
    Object? heartRate = freezed,
    Object? cadence = freezed,
    Object? strideLength = freezed,
    Object? distanceFromStart = null,
  }) {
    return _then(_value.copyWith(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      altitude: freezed == altitude
          ? _value.altitude
          : altitude // ignore: cast_nullable_to_non_nullable
              as double?,
      pace: freezed == pace
          ? _value.pace
          : pace // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRate: freezed == heartRate
          ? _value.heartRate
          : heartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      cadence: freezed == cadence
          ? _value.cadence
          : cadence // ignore: cast_nullable_to_non_nullable
              as int?,
      strideLength: freezed == strideLength
          ? _value.strideLength
          : strideLength // ignore: cast_nullable_to_non_nullable
              as double?,
      distanceFromStart: null == distanceFromStart
          ? _value.distanceFromStart
          : distanceFromStart // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RunSampleImplCopyWith<$Res>
    implements $RunSampleCopyWith<$Res> {
  factory _$$RunSampleImplCopyWith(
          _$RunSampleImpl value, $Res Function(_$RunSampleImpl) then) =
      __$$RunSampleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime timestamp,
      double latitude,
      double longitude,
      double? altitude,
      int? pace,
      int? heartRate,
      int? cadence,
      double? strideLength,
      double distanceFromStart});
}

/// @nodoc
class __$$RunSampleImplCopyWithImpl<$Res>
    extends _$RunSampleCopyWithImpl<$Res, _$RunSampleImpl>
    implements _$$RunSampleImplCopyWith<$Res> {
  __$$RunSampleImplCopyWithImpl(
      _$RunSampleImpl _value, $Res Function(_$RunSampleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? altitude = freezed,
    Object? pace = freezed,
    Object? heartRate = freezed,
    Object? cadence = freezed,
    Object? strideLength = freezed,
    Object? distanceFromStart = null,
  }) {
    return _then(_$RunSampleImpl(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      altitude: freezed == altitude
          ? _value.altitude
          : altitude // ignore: cast_nullable_to_non_nullable
              as double?,
      pace: freezed == pace
          ? _value.pace
          : pace // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRate: freezed == heartRate
          ? _value.heartRate
          : heartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      cadence: freezed == cadence
          ? _value.cadence
          : cadence // ignore: cast_nullable_to_non_nullable
              as int?,
      strideLength: freezed == strideLength
          ? _value.strideLength
          : strideLength // ignore: cast_nullable_to_non_nullable
              as double?,
      distanceFromStart: null == distanceFromStart
          ? _value.distanceFromStart
          : distanceFromStart // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$RunSampleImpl implements _RunSample {
  const _$RunSampleImpl(
      {required this.timestamp,
      required this.latitude,
      required this.longitude,
      this.altitude,
      this.pace,
      this.heartRate,
      this.cadence,
      this.strideLength,
      this.distanceFromStart = 0});

  @override
  final DateTime timestamp;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final double? altitude;

  /// 瞬时配速（秒/公里）
  @override
  final int? pace;
  @override
  final int? heartRate;
  @override
  final int? cadence;
  @override
  final double? strideLength;

  /// 距起点距离（米）
  @override
  @JsonKey()
  final double distanceFromStart;

  @override
  String toString() {
    return 'RunSample(timestamp: $timestamp, latitude: $latitude, longitude: $longitude, altitude: $altitude, pace: $pace, heartRate: $heartRate, cadence: $cadence, strideLength: $strideLength, distanceFromStart: $distanceFromStart)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RunSampleImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.altitude, altitude) ||
                other.altitude == altitude) &&
            (identical(other.pace, pace) || other.pace == pace) &&
            (identical(other.heartRate, heartRate) ||
                other.heartRate == heartRate) &&
            (identical(other.cadence, cadence) || other.cadence == cadence) &&
            (identical(other.strideLength, strideLength) ||
                other.strideLength == strideLength) &&
            (identical(other.distanceFromStart, distanceFromStart) ||
                other.distanceFromStart == distanceFromStart));
  }

  @override
  int get hashCode => Object.hash(runtimeType, timestamp, latitude, longitude,
      altitude, pace, heartRate, cadence, strideLength, distanceFromStart);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RunSampleImplCopyWith<_$RunSampleImpl> get copyWith =>
      __$$RunSampleImplCopyWithImpl<_$RunSampleImpl>(this, _$identity);
}

abstract class _RunSample implements RunSample {
  const factory _RunSample(
      {required final DateTime timestamp,
      required final double latitude,
      required final double longitude,
      final double? altitude,
      final int? pace,
      final int? heartRate,
      final int? cadence,
      final double? strideLength,
      final double distanceFromStart}) = _$RunSampleImpl;

  @override
  DateTime get timestamp;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double? get altitude;
  @override

  /// 瞬时配速（秒/公里）
  int? get pace;
  @override
  int? get heartRate;
  @override
  int? get cadence;
  @override
  double? get strideLength;
  @override

  /// 距起点距离（米）
  double get distanceFromStart;
  @override
  @JsonKey(ignore: true)
  _$$RunSampleImplCopyWith<_$RunSampleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
