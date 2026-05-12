import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/providers/run_provider.dart';
import '../../l10n/app_localizations.dart';

/// 播报设置页 —— 频率 / 播报参数 / 语言模式
class BroadcastSettingsPage extends ConsumerStatefulWidget {
  const BroadcastSettingsPage({super.key});

  @override
  ConsumerState<BroadcastSettingsPage> createState() => _BroadcastSettingsPageState();
}

class _BroadcastSettingsPageState extends ConsumerState<BroadcastSettingsPage> {
  BroadcastFrequency _frequency = BroadcastFrequency.every1000m;
  final List<String> _selectedItems = ['pace', 'distance', 'duration', 'heart_rate'];
  String _voiceStyle = 'standard';

  /// 适用于独跑模式的播报项（伴跑/挑战专属项不显示）
  static const _soloKeys = [
    'pace', 'distance', 'duration', 'heart_rate',
    'cadence', 'stride_length',
    'goal_status', 'pace_deviation', 'climb', 'motivation', 'sprint',
  ];

  /// 伴跑/挑战专属的播报项（仅在对应模式下显示）
  static const _companionKeys = [
    'lag', 'opponent_pace',
  ];

  String _broadcastLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'pace': return '当前配速';
      case 'distance': return '当前距离';
      case 'duration': return '运动时长';
      case 'heart_rate': return '实时心率';
      case 'cadence': return '步频';
      case 'stride_length': return '步幅';
      case 'lag': return '落后距离';
      case 'opponent_pace': return '对手配速';
      case 'goal_status': return '目标进度';
      case 'pace_deviation': return '配速异常';
      case 'climb': return '爬升提醒';
      case 'motivation': return '鼓励语录';
      case 'sprint': return '冲刺提醒';
      default: return key;
    }
  }

  String _broadcastSubtitle(String key) {
    switch (key) {
      case 'pace': return '播报每公里的平均配速';
      case 'distance': return '播报累计跑步距离';
      case 'duration': return '播报累计运动时长';
      case 'heart_rate': return '播报实时心率数据';
      case 'cadence': return '播报每分钟步频';
      case 'stride_length': return '播报平均步幅';
      case 'lag': return '跟伴跑/对手的距离差距';
      case 'opponent_pace': return '显示对手的配速对比';
      case 'goal_status': return '距离/时间/卡路里目标完成情况';
      case 'pace_deviation': return '配速突然变快或变慢时提醒';
      case 'climb': return '爬升超过5米时播报';
      case 'motivation': return '随机播放鼓励语句';
      case 'sprint': return '终点前自动触发冲刺提醒';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final runMode = ref.watch(runSessionProvider.select((s) => s.runMode));
    final isSolo = runMode == RunMode.solo;
    final keys = isSolo ? _soloKeys : [..._soloKeys, ..._companionKeys];

    return Scaffold(
      appBar: AppBar(title: Text('语音播报')),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          // ═══════ 第一行：播放频率 ═══════
          Text('播放频率', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 10.h),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
              side: BorderSide(color: context.dividerColor),
            ),
            child: Column(
              children: BroadcastFrequency.values.map((freq) {
                return RadioListTile<BroadcastFrequency>(
                  title: Text(freq.label, style: TextStyle(fontSize: 14.sp)),
                  subtitle: Text(
                    freq.isDistance && freq.distanceMeters != null
                        ? '每 ${freq.distanceMeters! ~/ 1000} 公里播报一次'
                        : freq.isTime && freq.timeSeconds != null
                            ? '每 ${freq.timeSeconds! ~/ 60} 分钟播报一次'
                            : '仅在配速异常时播报',
                    style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
                  ),
                  value: freq,
                  groupValue: _frequency,
                  activeColor: AppColors.orange,
                  onChanged: (value) {
                    if (value != null) setState(() => _frequency = value);
                  },
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 24.h),

          // ═══════ 第二行：播报参数（无标签，直接展示选项） ═══════
          SizedBox(height: 4.h),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
              side: BorderSide(color: context.dividerColor),
            ),
            child: Column(
              children: keys.map((key) {
                final isCompanionItem = _companionKeys.contains(key);
                return Opacity(
                  opacity: isCompanionItem && isSolo ? 0.35 : 1.0,
                  child: CheckboxListTile(
                    title: Text(
                      _broadcastLabel(key, l10n),
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    subtitle: Text(
                      _broadcastSubtitle(key),
                      style: TextStyle(fontSize: 11.sp, color: context.textSecondary),
                    ),
                    value: _selectedItems.contains(key),
                    activeColor: AppColors.orange,
                    onChanged: isCompanionItem && isSolo
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedItems.add(key);
                              } else {
                                _selectedItems.remove(key);
                              }
                            });
                          },
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 24.h),

          // ═══════ 第三行：语音风格 ═══════
          Text('语音风格', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text('选择语音播报的风格',
              style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
          SizedBox(height: 10.h),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
              side: BorderSide(color: context.dividerColor),
            ),
            child: Column(
              children: AppConstants.voiceStyles.map((style) {
                final id = style['id']!;
                final name = style['name']!;
                final desc = style['desc']!;
                return RadioListTile<String>(
                  title: Text(name, style: TextStyle(fontSize: 14.sp)),
                  subtitle: Text(desc, style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
                  value: id,
                  groupValue: _voiceStyle,
                  activeColor: AppColors.orange,
                  onChanged: (value) {
                    if (value != null) setState(() => _voiceStyle = value);
                  },
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(runSessionProvider.notifier).configure(
                      frequency: _frequency,
                      items: List.from(_selectedItems),
                      voice: _voiceStyle,
                    );
                Navigator.pop(context);
              },
              child: Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
