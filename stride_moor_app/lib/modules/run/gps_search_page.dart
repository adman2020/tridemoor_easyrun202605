import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';

/// GPS 搜星页
class GpsSearchPage extends ConsumerStatefulWidget {
  const GpsSearchPage({super.key});

  @override
  ConsumerState<GpsSearchPage> createState() => _GpsSearchPageState();
}

class _GpsSearchPageState extends ConsumerState<GpsSearchPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // 模拟搜星过程
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(gpsStatusProvider.notifier).state = GpsStatus.good;
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {







    final gpsStatus = ref.watch(gpsStatusProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildGpsIndicator(gpsStatus),
              SizedBox(height: 40.h),
              Text(
                _getStatusLabel(gpsStatus, l10n),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                _getStatusHint(gpsStatus, l10n),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              if (gpsStatus.canStart)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/run/ongoing'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                    ),
                    child: Text(
                      l10n.startRun,
                      style: TextStyle(fontSize: 18.sp),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                    ),
                    child: Text(
                      l10n.loading,
                      style: TextStyle(fontSize: 18.sp),
                    ),
                  ),
                ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsIndicator(GpsStatus status) {
    final color = status == GpsStatus.good
        ? AppColors.success
        : status == GpsStatus.searching
            ? AppColors.warning
            : AppColors.error;

    return SizedBox(
      width: 160.w,
      height: 160.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 脉冲动画
          if (status == GpsStatus.searching)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 160.w * (0.5 + _pulseController.value * 0.5),
                  height: 160.w * (0.5 + _pulseController.value * 0.5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1 * (1 - _pulseController.value)),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          // 主圆
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: status == GpsStatus.searching
                ? Center(
                    child: SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  )
                : Icon(status.icon, size: 48.sp, color: color),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(GpsStatus status, AppLocalizations l10n) {
    switch (status) {
      case GpsStatus.searching:
        return l10n.gpsSearching;
      case GpsStatus.weak:
        return l10n.gpsWeak;
      case GpsStatus.good:
        return l10n.gpsGood;
      case GpsStatus.lost:
        return l10n.gpsLost;
    }
  }

  String _getStatusHint(GpsStatus status, AppLocalizations l10n) {
    switch (status) {
      case GpsStatus.searching:
        return l10n.gpsSearchHint;
      case GpsStatus.weak:
        return l10n.gpsWeakHint;
      case GpsStatus.good:
        return l10n.gpsGoodHint;
      case GpsStatus.lost:
        return l10n.gpsWeakHint;
    }
  }
}
