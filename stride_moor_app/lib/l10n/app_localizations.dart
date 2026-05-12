import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'驰陌'**
  String get appName;

  /// No description provided for @appNameEN.
  ///
  /// In zh, this message translates to:
  /// **'StrideMoor'**
  String get appNameEN;

  /// No description provided for @slogan.
  ///
  /// In zh, this message translates to:
  /// **'驰于阡陌，自在奔跑'**
  String get slogan;

  /// No description provided for @sloganEN.
  ///
  /// In zh, this message translates to:
  /// **'Stride in Moor, Run at Ease'**
  String get sloganEN;

  /// No description provided for @tabDiscover.
  ///
  /// In zh, this message translates to:
  /// **'发现'**
  String get tabDiscover;

  /// No description provided for @tabRun.
  ///
  /// In zh, this message translates to:
  /// **'运动'**
  String get tabRun;

  /// No description provided for @tabRoutes.
  ///
  /// In zh, this message translates to:
  /// **'跑迹'**
  String get tabRoutes;

  /// No description provided for @tabProfile.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get tabProfile;

  /// No description provided for @startRun.
  ///
  /// In zh, this message translates to:
  /// **'开始跑步'**
  String get startRun;

  /// No description provided for @runModeSolo.
  ///
  /// In zh, this message translates to:
  /// **'独自跑'**
  String get runModeSolo;

  /// No description provided for @runModeCompanion.
  ///
  /// In zh, this message translates to:
  /// **'伴跑'**
  String get runModeCompanion;

  /// No description provided for @runModeChallenge.
  ///
  /// In zh, this message translates to:
  /// **'挑战跑'**
  String get runModeChallenge;

  /// No description provided for @runModeSoloDesc.
  ///
  /// In zh, this message translates to:
  /// **'自由跑步，记录个人数据'**
  String get runModeSoloDesc;

  /// No description provided for @runModeCompanionDesc.
  ///
  /// In zh, this message translates to:
  /// **'选择路线，与跑伴影子同步'**
  String get runModeCompanionDesc;

  /// No description provided for @runModeChallengeDesc.
  ///
  /// In zh, this message translates to:
  /// **'向排行榜对手发起挑战'**
  String get runModeChallengeDesc;

  /// No description provided for @ghostModeRealReplay.
  ///
  /// In zh, this message translates to:
  /// **'真实回放'**
  String get ghostModeRealReplay;

  /// No description provided for @ghostModeConstantPace.
  ///
  /// In zh, this message translates to:
  /// **'匀速目标'**
  String get ghostModeConstantPace;

  /// No description provided for @ghostModeRabbit.
  ///
  /// In zh, this message translates to:
  /// **'兔子模式'**
  String get ghostModeRabbit;

  /// No description provided for @ghostModeTortoiseHare.
  ///
  /// In zh, this message translates to:
  /// **'龟兔模式'**
  String get ghostModeTortoiseHare;

  /// No description provided for @ghostModeGoalChallenge.
  ///
  /// In zh, this message translates to:
  /// **'目标挑战'**
  String get ghostModeGoalChallenge;

  /// No description provided for @distance.
  ///
  /// In zh, this message translates to:
  /// **'距离'**
  String get distance;

  /// No description provided for @duration.
  ///
  /// In zh, this message translates to:
  /// **'用时'**
  String get duration;

  /// No description provided for @pace.
  ///
  /// In zh, this message translates to:
  /// **'配速'**
  String get pace;

  /// No description provided for @heartRate.
  ///
  /// In zh, this message translates to:
  /// **'心率'**
  String get heartRate;

  /// No description provided for @cadence.
  ///
  /// In zh, this message translates to:
  /// **'步频'**
  String get cadence;

  /// No description provided for @strideLength.
  ///
  /// In zh, this message translates to:
  /// **'步幅'**
  String get strideLength;

  /// No description provided for @elevation.
  ///
  /// In zh, this message translates to:
  /// **'爬升'**
  String get elevation;

  /// No description provided for @calories.
  ///
  /// In zh, this message translates to:
  /// **'卡路里'**
  String get calories;

  /// No description provided for @km.
  ///
  /// In zh, this message translates to:
  /// **'公里'**
  String get km;

  /// No description provided for @m.
  ///
  /// In zh, this message translates to:
  /// **'米'**
  String get m;

  /// No description provided for @min.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get min;

  /// No description provided for @sec.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get sec;

  /// No description provided for @times.
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get times;

  /// No description provided for @hours.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get hours;

  /// No description provided for @bpm.
  ///
  /// In zh, this message translates to:
  /// **'次/分'**
  String get bpm;

  /// No description provided for @spm.
  ///
  /// In zh, this message translates to:
  /// **'步/分'**
  String get spm;

  /// No description provided for @kcal.
  ///
  /// In zh, this message translates to:
  /// **'千卡'**
  String get kcal;

  /// No description provided for @gpsSearching.
  ///
  /// In zh, this message translates to:
  /// **'搜星中'**
  String get gpsSearching;

  /// No description provided for @gpsWeak.
  ///
  /// In zh, this message translates to:
  /// **'信号弱'**
  String get gpsWeak;

  /// No description provided for @gpsGood.
  ///
  /// In zh, this message translates to:
  /// **'信号良好'**
  String get gpsGood;

  /// No description provided for @gpsLost.
  ///
  /// In zh, this message translates to:
  /// **'信号丢失'**
  String get gpsLost;

  /// No description provided for @gpsSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'正在搜索 GPS 卫星信号，请确保在开阔地带'**
  String get gpsSearchHint;

  /// No description provided for @gpsGoodHint.
  ///
  /// In zh, this message translates to:
  /// **'GPS 信号良好，可以开始跑步'**
  String get gpsGoodHint;

  /// No description provided for @gpsWeakHint.
  ///
  /// In zh, this message translates to:
  /// **'信号较弱，建议移动到开阔地带'**
  String get gpsWeakHint;

  /// No description provided for @running.
  ///
  /// In zh, this message translates to:
  /// **'跑步中'**
  String get running;

  /// No description provided for @paused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get paused;

  /// No description provided for @finish.
  ///
  /// In zh, this message translates to:
  /// **'结束'**
  String get finish;

  /// No description provided for @resume.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get resume;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @runFinished.
  ///
  /// In zh, this message translates to:
  /// **'跑步完成！'**
  String get runFinished;

  /// No description provided for @lockScreen.
  ///
  /// In zh, this message translates to:
  /// **'屏幕已锁定'**
  String get lockScreen;

  /// No description provided for @unlockHint.
  ///
  /// In zh, this message translates to:
  /// **'上滑解锁'**
  String get unlockHint;

  /// No description provided for @saveAsRoute.
  ///
  /// In zh, this message translates to:
  /// **'保存为路线'**
  String get saveAsRoute;

  /// No description provided for @shareResult.
  ///
  /// In zh, this message translates to:
  /// **'分享成绩'**
  String get shareResult;

  /// No description provided for @backToHome.
  ///
  /// In zh, this message translates to:
  /// **'返回首页'**
  String get backToHome;

  /// No description provided for @route.
  ///
  /// In zh, this message translates to:
  /// **'路线'**
  String get route;

  /// No description provided for @myRoutes.
  ///
  /// In zh, this message translates to:
  /// **'我的跑迹'**
  String get myRoutes;

  /// No description provided for @nearbyRoutes.
  ///
  /// In zh, this message translates to:
  /// **'附近推荐'**
  String get nearbyRoutes;

  /// No description provided for @uploadRoute.
  ///
  /// In zh, this message translates to:
  /// **'上传跑迹'**
  String get uploadRoute;

  /// No description provided for @routeSquare.
  ///
  /// In zh, this message translates to:
  /// **'跑迹广场'**
  String get routeSquare;

  /// No description provided for @favorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favorite;

  /// No description provided for @goRun.
  ///
  /// In zh, this message translates to:
  /// **'去伴跑'**
  String get goRun;

  /// No description provided for @broadcastSettings.
  ///
  /// In zh, this message translates to:
  /// **'播报设置'**
  String get broadcastSettings;

  /// No description provided for @broadcastFrequency.
  ///
  /// In zh, this message translates to:
  /// **'播报频率'**
  String get broadcastFrequency;

  /// No description provided for @broadcastContent.
  ///
  /// In zh, this message translates to:
  /// **'播报内容'**
  String get broadcastContent;

  /// No description provided for @voiceStyle.
  ///
  /// In zh, this message translates to:
  /// **'语音风格'**
  String get voiceStyle;

  /// No description provided for @voiceStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get voiceStandard;

  /// No description provided for @voiceJianghu.
  ///
  /// In zh, this message translates to:
  /// **'江湖'**
  String get voiceJianghu;

  /// No description provided for @voiceCoach.
  ///
  /// In zh, this message translates to:
  /// **'教练'**
  String get voiceCoach;

  /// No description provided for @voiceToxic.
  ///
  /// In zh, this message translates to:
  /// **'毒舌'**
  String get voiceToxic;

  /// No description provided for @profile.
  ///
  /// In zh, this message translates to:
  /// **'个人中心'**
  String get profile;

  /// No description provided for @runningStats.
  ///
  /// In zh, this message translates to:
  /// **'跑步统计'**
  String get runningStats;

  /// No description provided for @challengeRecord.
  ///
  /// In zh, this message translates to:
  /// **'挑战记录'**
  String get challengeRecord;

  /// No description provided for @deviceManagement.
  ///
  /// In zh, this message translates to:
  /// **'设备管理'**
  String get deviceManagement;

  /// No description provided for @friends.
  ///
  /// In zh, this message translates to:
  /// **'关注跑友'**
  String get friends;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @totalDistance.
  ///
  /// In zh, this message translates to:
  /// **'总里程'**
  String get totalDistance;

  /// No description provided for @totalRuns.
  ///
  /// In zh, this message translates to:
  /// **'总次数'**
  String get totalRuns;

  /// No description provided for @totalDuration.
  ///
  /// In zh, this message translates to:
  /// **'总时长'**
  String get totalDuration;

  /// No description provided for @totalCalories.
  ///
  /// In zh, this message translates to:
  /// **'累计消耗'**
  String get totalCalories;

  /// No description provided for @comparisonReport.
  ///
  /// In zh, this message translates to:
  /// **'对比报告'**
  String get comparisonReport;

  /// No description provided for @details.
  ///
  /// In zh, this message translates to:
  /// **'详细数据'**
  String get details;

  /// No description provided for @advantage.
  ///
  /// In zh, this message translates to:
  /// **'优势'**
  String get advantage;

  /// No description provided for @improvement.
  ///
  /// In zh, this message translates to:
  /// **'待改进'**
  String get improvement;

  /// No description provided for @nextGoal.
  ///
  /// In zh, this message translates to:
  /// **'下次目标'**
  String get nextGoal;

  /// No description provided for @easy.
  ///
  /// In zh, this message translates to:
  /// **'轻松'**
  String get easy;

  /// No description provided for @moderate.
  ///
  /// In zh, this message translates to:
  /// **'中等'**
  String get moderate;

  /// No description provided for @hard.
  ///
  /// In zh, this message translates to:
  /// **'挑战'**
  String get hard;

  /// No description provided for @feed.
  ///
  /// In zh, this message translates to:
  /// **'跑友动态'**
  String get feed;

  /// No description provided for @runHistory.
  ///
  /// In zh, this message translates to:
  /// **'运动记录'**
  String get runHistory;

  /// No description provided for @recentRuns.
  ///
  /// In zh, this message translates to:
  /// **'最近跑步'**
  String get recentRuns;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get yesterday;

  /// No description provided for @recentRunPace.
  ///
  /// In zh, this message translates to:
  /// **'配速'**
  String get recentRunPace;

  /// No description provided for @challengeRanking.
  ///
  /// In zh, this message translates to:
  /// **'挑战榜'**
  String get challengeRanking;

  /// No description provided for @actionRecord.
  ///
  /// In zh, this message translates to:
  /// **'运动记录'**
  String get actionRecord;

  /// No description provided for @actionSquare.
  ///
  /// In zh, this message translates to:
  /// **'跑迹广场'**
  String get actionSquare;

  /// No description provided for @actionRanking.
  ///
  /// In zh, this message translates to:
  /// **'挑战榜'**
  String get actionRanking;

  /// No description provided for @unitKm.
  ///
  /// In zh, this message translates to:
  /// **'公里'**
  String get unitKm;

  /// No description provided for @unitTimes.
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get unitTimes;

  /// No description provided for @unitHours.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get unitHours;

  /// No description provided for @trajectoryMap.
  ///
  /// In zh, this message translates to:
  /// **'轨迹地图'**
  String get trajectoryMap;

  /// No description provided for @leaderboard.
  ///
  /// In zh, this message translates to:
  /// **'排行榜'**
  String get leaderboard;

  /// No description provided for @hot.
  ///
  /// In zh, this message translates to:
  /// **'热门'**
  String get hot;

  /// No description provided for @nearby.
  ///
  /// In zh, this message translates to:
  /// **'附近'**
  String get nearby;

  /// No description provided for @latest.
  ///
  /// In zh, this message translates to:
  /// **'最新'**
  String get latest;

  /// No description provided for @notificationSettings.
  ///
  /// In zh, this message translates to:
  /// **'通知设置'**
  String get notificationSettings;

  /// No description provided for @accountSettings.
  ///
  /// In zh, this message translates to:
  /// **'账号设置'**
  String get accountSettings;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'查看更多'**
  String get more;

  /// No description provided for @nextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get nextStep;

  /// No description provided for @searchingGPS.
  ///
  /// In zh, this message translates to:
  /// **'GPS搜星'**
  String get searchingGPS;

  /// No description provided for @selectRoute.
  ///
  /// In zh, this message translates to:
  /// **'选择路线'**
  String get selectRoute;

  /// No description provided for @selectRouteHint.
  ///
  /// In zh, this message translates to:
  /// **'从我的跑迹中选择'**
  String get selectRouteHint;

  /// No description provided for @broadcastSettingsHint.
  ///
  /// In zh, this message translates to:
  /// **'频率 / 内容 / 语音风格'**
  String get broadcastSettingsHint;

  /// No description provided for @runMode.
  ///
  /// In zh, this message translates to:
  /// **'选择模式'**
  String get runMode;

  /// No description provided for @ghostMode.
  ///
  /// In zh, this message translates to:
  /// **'伴跑模式'**
  String get ghostMode;

  /// No description provided for @notificationDev.
  ///
  /// In zh, this message translates to:
  /// **'通知功能开发中'**
  String get notificationDev;

  /// No description provided for @feedDetailDev.
  ///
  /// In zh, this message translates to:
  /// **'跑友动态详情页开发中'**
  String get feedDetailDev;

  /// No description provided for @shareDev.
  ///
  /// In zh, this message translates to:
  /// **'分享功能开发中'**
  String get shareDev;

  /// No description provided for @devComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'功能开发中'**
  String get devComingSoon;

  /// No description provided for @viewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get viewAll;

  /// No description provided for @people.
  ///
  /// In zh, this message translates to:
  /// **'人'**
  String get people;

  /// No description provided for @searchDev.
  ///
  /// In zh, this message translates to:
  /// **'搜索功能开发中'**
  String get searchDev;

  /// No description provided for @checkIns.
  ///
  /// In zh, this message translates to:
  /// **'打卡'**
  String get checkIns;

  /// No description provided for @rating.
  ///
  /// In zh, this message translates to:
  /// **'评分'**
  String get rating;

  /// No description provided for @creatorNickname.
  ///
  /// In zh, this message translates to:
  /// **'创造者昵称'**
  String get creatorNickname;

  /// No description provided for @createdAt.
  ///
  /// In zh, this message translates to:
  /// **'创建于'**
  String get createdAt;

  /// No description provided for @runnerNum.
  ///
  /// In zh, this message translates to:
  /// **'跑者'**
  String get runnerNum;

  /// No description provided for @runDetail.
  ///
  /// In zh, this message translates to:
  /// **'跑步详情'**
  String get runDetail;

  /// No description provided for @splitPace.
  ///
  /// In zh, this message translates to:
  /// **'分段配速'**
  String get splitPace;

  /// No description provided for @comparisonPK.
  ///
  /// In zh, this message translates to:
  /// **'伴跑PK'**
  String get comparisonPK;

  /// No description provided for @youVs.
  ///
  /// In zh, this message translates to:
  /// **'你 vs'**
  String get youVs;

  /// No description provided for @routeRoutes.
  ///
  /// In zh, this message translates to:
  /// **'跑迹'**
  String get routeRoutes;

  /// No description provided for @viewSavedRoutes.
  ///
  /// In zh, this message translates to:
  /// **'查看收藏的路线和上传的跑迹'**
  String get viewSavedRoutes;

  /// No description provided for @discoverNearbyRoutes.
  ///
  /// In zh, this message translates to:
  /// **'发现周边热门跑步路线'**
  String get discoverNearbyRoutes;

  /// No description provided for @generateFromRun.
  ///
  /// In zh, this message translates to:
  /// **'将跑步记录生成路线分享'**
  String get generateFromRun;

  /// No description provided for @selectRunRecord.
  ///
  /// In zh, this message translates to:
  /// **'选择跑步记录'**
  String get selectRunRecord;

  /// No description provided for @selectRunRecordHint.
  ///
  /// In zh, this message translates to:
  /// **'从历史记录中选择一条跑步记录生成跑迹'**
  String get selectRunRecordHint;

  /// No description provided for @generate.
  ///
  /// In zh, this message translates to:
  /// **'生成'**
  String get generate;

  /// No description provided for @routeGenerated.
  ///
  /// In zh, this message translates to:
  /// **'路线生成成功！'**
  String get routeGenerated;

  /// No description provided for @myRouteTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的路线'**
  String get myRouteTitle;

  /// No description provided for @nearbyRoutesMap.
  ///
  /// In zh, this message translates to:
  /// **'附近跑迹地图'**
  String get nearbyRoutesMap;

  /// No description provided for @kmRunWithPace.
  ///
  /// In zh, this message translates to:
  /// **'跑步'**
  String get kmRunWithPace;

  /// No description provided for @runnerNickname.
  ///
  /// In zh, this message translates to:
  /// **'跑者昵称'**
  String get runnerNickname;

  /// No description provided for @editProfileDev.
  ///
  /// In zh, this message translates to:
  /// **'编辑资料功能开发中'**
  String get editProfileDev;

  /// No description provided for @notificationSettingsDev.
  ///
  /// In zh, this message translates to:
  /// **'通知设置功能开发中'**
  String get notificationSettingsDev;

  /// No description provided for @accountSettingsDev.
  ///
  /// In zh, this message translates to:
  /// **'账号设置功能开发中'**
  String get accountSettingsDev;

  /// No description provided for @aboutApp.
  ///
  /// In zh, this message translates to:
  /// **'关于驰陌'**
  String get aboutApp;

  /// No description provided for @challengeMetric.
  ///
  /// In zh, this message translates to:
  /// **'挑战维度'**
  String get challengeMetric;

  /// No description provided for @finishRunConfirm.
  ///
  /// In zh, this message translates to:
  /// **'结束后将生成跑步记录和对比报告。'**
  String get finishRunConfirm;

  /// No description provided for @checkInLeaderboard.
  ///
  /// In zh, this message translates to:
  /// **'打卡榜'**
  String get checkInLeaderboard;

  /// No description provided for @checkInStreak.
  ///
  /// In zh, this message translates to:
  /// **'连续打卡'**
  String get checkInStreak;

  /// No description provided for @timesCheckIn.
  ///
  /// In zh, this message translates to:
  /// **'次打卡'**
  String get timesCheckIn;

  /// No description provided for @peopleRan.
  ///
  /// In zh, this message translates to:
  /// **'人已跑'**
  String get peopleRan;

  /// No description provided for @alreadyFavorited.
  ///
  /// In zh, this message translates to:
  /// **'已收藏路线'**
  String get alreadyFavorited;

  /// No description provided for @runs.
  ///
  /// In zh, this message translates to:
  /// **'跑步'**
  String get runs;

  /// No description provided for @viewAllArrow.
  ///
  /// In zh, this message translates to:
  /// **'查看全部 →'**
  String get viewAllArrow;

  /// No description provided for @challengerRank.
  ///
  /// In zh, this message translates to:
  /// **'挑战者排名'**
  String get challengerRank;

  /// No description provided for @defenderRank.
  ///
  /// In zh, this message translates to:
  /// **'被挑战者排名'**
  String get defenderRank;

  /// No description provided for @challengeCount.
  ///
  /// In zh, this message translates to:
  /// **'挑战'**
  String get challengeCount;

  /// No description provided for @successCount.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get successCount;

  /// No description provided for @defended.
  ///
  /// In zh, this message translates to:
  /// **'被挑战'**
  String get defended;

  /// No description provided for @defendSuccess.
  ///
  /// In zh, this message translates to:
  /// **'防守成功'**
  String get defendSuccess;

  /// No description provided for @currentPace.
  ///
  /// In zh, this message translates to:
  /// **'当前配速'**
  String get currentPace;

  /// No description provided for @currentDistance.
  ///
  /// In zh, this message translates to:
  /// **'已跑距离'**
  String get currentDistance;

  /// No description provided for @currentDuration.
  ///
  /// In zh, this message translates to:
  /// **'跑步用时'**
  String get currentDuration;

  /// No description provided for @currentHeartRate.
  ///
  /// In zh, this message translates to:
  /// **'当前心率'**
  String get currentHeartRate;

  /// No description provided for @currentCadence.
  ///
  /// In zh, this message translates to:
  /// **'当前步频'**
  String get currentCadence;

  /// No description provided for @currentStride.
  ///
  /// In zh, this message translates to:
  /// **'当前步幅'**
  String get currentStride;

  /// No description provided for @lagDistance.
  ///
  /// In zh, this message translates to:
  /// **'落后/领先距离'**
  String get lagDistance;

  /// No description provided for @opponentSplitPace.
  ///
  /// In zh, this message translates to:
  /// **'对手分段配速'**
  String get opponentSplitPace;

  /// No description provided for @goalStatus.
  ///
  /// In zh, this message translates to:
  /// **'挑战目标达标状态'**
  String get goalStatus;

  /// No description provided for @paceDeviation.
  ///
  /// In zh, this message translates to:
  /// **'配速偏差提醒'**
  String get paceDeviation;

  /// No description provided for @climbAlert.
  ///
  /// In zh, this message translates to:
  /// **'爬坡提醒'**
  String get climbAlert;

  /// No description provided for @motivation.
  ///
  /// In zh, this message translates to:
  /// **'激励播报'**
  String get motivation;

  /// No description provided for @sprintAlert.
  ///
  /// In zh, this message translates to:
  /// **'终点冲刺提醒'**
  String get sprintAlert;

  /// No description provided for @broadcastEveryXMeters.
  ///
  /// In zh, this message translates to:
  /// **'每跑 {meters} 米播报一次'**
  String broadcastEveryXMeters(Object meters);

  /// No description provided for @broadcastEveryXMinutes.
  ///
  /// In zh, this message translates to:
  /// **'每 {minutes} 分钟播报一次'**
  String broadcastEveryXMinutes(Object minutes);

  /// No description provided for @broadcastAbnormalOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅在数据异常时播报'**
  String get broadcastAbnormalOnly;

  /// No description provided for @broadcastSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'建议勾选 3-5 项，超出时系统按优先级轮播'**
  String get broadcastSuggestion;

  /// No description provided for @hoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'小时前'**
  String get hoursAgo;

  /// No description provided for @connectedDevices.
  ///
  /// In zh, this message translates to:
  /// **'已连接设备'**
  String get connectedDevices;

  /// No description provided for @addDevice.
  ///
  /// In zh, this message translates to:
  /// **'添加设备'**
  String get addDevice;

  /// No description provided for @heartRateBelt.
  ///
  /// In zh, this message translates to:
  /// **'心率带'**
  String get heartRateBelt;

  /// No description provided for @battery.
  ///
  /// In zh, this message translates to:
  /// **'电量'**
  String get battery;

  /// No description provided for @disconnected.
  ///
  /// In zh, this message translates to:
  /// **'已断开'**
  String get disconnected;

  /// No description provided for @scanningBLE.
  ///
  /// In zh, this message translates to:
  /// **'正在扫描附近 BLE 设备...'**
  String get scanningBLE;

  /// No description provided for @scanNearbyDevices.
  ///
  /// In zh, this message translates to:
  /// **'扫描附近设备'**
  String get scanNearbyDevices;

  /// No description provided for @days.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get days;

  /// No description provided for @loginTitle.
  ///
  /// In zh, this message translates to:
  /// **'欢迎回来'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'登录后继续你的跑步之旅'**
  String get loginSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get phoneNumber;

  /// No description provided for @enterPhone.
  ///
  /// In zh, this message translates to:
  /// **'请输入手机号'**
  String get enterPhone;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get enterPassword;

  /// No description provided for @login.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @noAccount.
  ///
  /// In zh, this message translates to:
  /// **'还没有账号？'**
  String get noAccount;

  /// No description provided for @registerNow.
  ///
  /// In zh, this message translates to:
  /// **'立即注册'**
  String get registerNow;

  /// No description provided for @enterPhoneAndPassword.
  ///
  /// In zh, this message translates to:
  /// **'请输入手机号和密码'**
  String get enterPhoneAndPassword;

  /// No description provided for @registerTitle.
  ///
  /// In zh, this message translates to:
  /// **'注册账号'**
  String get registerTitle;

  /// No description provided for @createAccount.
  ///
  /// In zh, this message translates to:
  /// **'创建新账号'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'加入驰陌，开启你的跑步社区之旅'**
  String get registerSubtitle;

  /// No description provided for @nickname.
  ///
  /// In zh, this message translates to:
  /// **'昵称'**
  String get nickname;

  /// No description provided for @nicknameOptional.
  ///
  /// In zh, this message translates to:
  /// **'昵称（可选）'**
  String get nicknameOptional;

  /// No description provided for @nicknameHint.
  ///
  /// In zh, this message translates to:
  /// **'给自己起个好听的名字'**
  String get nicknameHint;

  /// No description provided for @setPassword.
  ///
  /// In zh, this message translates to:
  /// **'请设置密码（至少6位）'**
  String get setPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get confirmPassword;

  /// No description provided for @reenterPassword.
  ///
  /// In zh, this message translates to:
  /// **'请再次输入密码'**
  String get reenterPassword;

  /// No description provided for @register.
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get register;

  /// No description provided for @haveAccount.
  ///
  /// In zh, this message translates to:
  /// **'已有账号？'**
  String get haveAccount;

  /// No description provided for @goLogin.
  ///
  /// In zh, this message translates to:
  /// **'去登录'**
  String get goLogin;

  /// No description provided for @fillAllFields.
  ///
  /// In zh, this message translates to:
  /// **'请填写完整信息'**
  String get fillAllFields;

  /// No description provided for @passwordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次输入的密码不一致'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In zh, this message translates to:
  /// **'密码长度至少为6位'**
  String get passwordTooShort;

  /// No description provided for @noRunRecord.
  ///
  /// In zh, this message translates to:
  /// **'暂无跑步记录，快去开始第一次跑步吧！'**
  String get noRunRecord;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @noRoute.
  ///
  /// In zh, this message translates to:
  /// **'暂无路线'**
  String get noRoute;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'需要定位权限才能使用跑步功能'**
  String get locationPermissionDenied;

  /// No description provided for @supportDevices.
  ///
  /// In zh, this message translates to:
  /// **'支持设备: Apple Watch、Garmin、华为手环/手表、小米手环、Polar H10 等 BLE 心率设备'**
  String get supportDevices;

  /// No description provided for @postDetail.
  ///
  /// In zh, this message translates to:
  /// **'动态详情'**
  String get postDetail;

  /// No description provided for @comment.
  ///
  /// In zh, this message translates to:
  /// **'评论'**
  String get comment;

  /// No description provided for @comments.
  ///
  /// In zh, this message translates to:
  /// **'评论'**
  String get comments;

  /// No description provided for @like.
  ///
  /// In zh, this message translates to:
  /// **'赞'**
  String get like;

  /// No description provided for @liked.
  ///
  /// In zh, this message translates to:
  /// **'已赞'**
  String get liked;

  /// No description provided for @sendComment.
  ///
  /// In zh, this message translates to:
  /// **'发送评论'**
  String get sendComment;

  /// No description provided for @enterComment.
  ///
  /// In zh, this message translates to:
  /// **'写点什么...'**
  String get enterComment;

  /// No description provided for @noComments.
  ///
  /// In zh, this message translates to:
  /// **'暂无评论，快来抢沙发吧'**
  String get noComments;

  /// No description provided for @loadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更多'**
  String get loadMore;

  /// No description provided for @routesTabMy.
  ///
  /// In zh, this message translates to:
  /// **'我的跑迹'**
  String get routesTabMy;

  /// No description provided for @routesTabFriends.
  ///
  /// In zh, this message translates to:
  /// **'跑友跑迹'**
  String get routesTabFriends;

  /// No description provided for @routesTabUpload.
  ///
  /// In zh, this message translates to:
  /// **'上传管理'**
  String get routesTabUpload;

  /// No description provided for @myRoute.
  ///
  /// In zh, this message translates to:
  /// **'我的路线'**
  String get myRoute;

  /// No description provided for @friendName.
  ///
  /// In zh, this message translates to:
  /// **'跑友名'**
  String get friendName;

  /// No description provided for @unfavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get unfavorite;

  /// No description provided for @uploadPending.
  ///
  /// In zh, this message translates to:
  /// **'审核中'**
  String get uploadPending;

  /// No description provided for @uploadApproved.
  ///
  /// In zh, this message translates to:
  /// **'已上架'**
  String get uploadApproved;

  /// No description provided for @uploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'上传失败'**
  String get uploadFailed;

  /// No description provided for @uploadRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get uploadRetry;

  /// No description provided for @uploadNew.
  ///
  /// In zh, this message translates to:
  /// **'上传新跑迹'**
  String get uploadNew;

  /// No description provided for @uploadRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余'**
  String get uploadRemaining;

  /// No description provided for @uploadCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消上传'**
  String get uploadCancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
