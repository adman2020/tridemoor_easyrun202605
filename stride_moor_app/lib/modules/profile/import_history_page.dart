import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/models/device.dart';
import '../../core/providers/device_provider.dart';
import '../../core/providers/app_providers.dart';

/// 导入历史页
///
/// 查看从健康平台导入的记录，支持删除。
class ImportHistoryPage extends ConsumerWidget {
  const ImportHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(importHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('导入历史')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(importHistoryProvider);
        },
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64.w, color: context.textSecondary),
                SizedBox(height: 16.h),
                Text('加载失败', style: TextStyle(fontSize: 16.sp)),
                SizedBox(height: 8.h),
                Text('$err', style: TextStyle(fontSize: 13.sp, color: context.textSecondary)),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(importHistoryProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
          data: (records) {
            if (records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64.w, color: context.textSecondary),
                    SizedBox(height: 16.h),
                    Text('暂无导入记录',
                      style: TextStyle(fontSize: 16.sp, color: context.textSecondary)),
                    SizedBox(height: 8.h),
                    Text('从健康平台同步跑步记录后会出现在这里',
                      style: TextStyle(fontSize: 13.sp, color: context.textTertiary)),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/profile/devices'),
                      icon: const Icon(Icons.sync),
                      label: const Text('去同步'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(20.w),
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = records[index];
                return _buildRecordItem(context, ref, record);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecordItem(BuildContext context, WidgetRef ref, ImportRecord record) {
    // 来源图标
    IconData sourceIcon;
    String sourceLabel;
    switch (record.source) {
      case 'apple_health':
        sourceIcon = Icons.watch;
        sourceLabel = 'Apple Health';
        break;
      case 'huawei_health':
        sourceIcon = Icons.watch;
        sourceLabel = '华为运动健康';
        break;
      case 'health_connect':
        sourceIcon = Icons.health_and_safety;
        sourceLabel = 'Health Connect';
        break;
      case 'garmin':
        sourceIcon = Icons.watch;
        sourceLabel = 'Garmin Connect';
        break;
      default:
        sourceIcon = Icons.sync;
        sourceLabel = record.source;
    }

    final dateStr = '${record.importedAt.year}/${record.importedAt.month}/${record.importedAt.day} '
        '${record.importedAt.hour.toString().padLeft(2, '0')}:${record.importedAt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.heartRate,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除导入记录'),
            content: const Text('删除后关联的跑步记录也会被移除，确定删除吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('删除', style: TextStyle(color: AppColors.heartRate)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        try {
          final api = ref.read(apiServiceProvider);
          await api.deleteImported(record.id);
          ref.invalidate(importHistoryProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已删除导入记录'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('删除失败: $e'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.heartRate,
              ),
            );
          }
          ref.invalidate(importHistoryProvider);
        }
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 4.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: context.dividerColor),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(sourceIcon, color: AppColors.success, size: 22.sp),
          ),
          title: Text(sourceLabel,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              Text('导入时间: $dateStr',
                style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
              if (record.deviceId != null)
                Text('设备ID: ${record.deviceId}',
                  style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
            ],
          ),
          trailing: Icon(Icons.chevron_right, color: context.textTertiary),
          onTap: () {
            // 查看关联的跑步记录
            context.push('/discover/run/${record.runId}');
          },
        ),
      ),
    );
  }
}
