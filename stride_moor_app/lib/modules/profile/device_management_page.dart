import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/models/device.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/device_provider.dart';
import '../../core/services/ble_service.dart';
import '../../l10n/app_localizations.dart';
import 'health_sync_page.dart';

/// 设备管理页 —— 绑定设备 + 健康数据导入
class DeviceManagementPage extends ConsumerWidget {
  const DeviceManagementPage({super.key});

  /// 设备类型对应的图标
  static IconData _deviceIcon(String deviceType) {
    switch (deviceType) {
      case DeviceCategory.smartwatch:
        return Icons.watch;
      case DeviceCategory.fitnessBand:
        return Icons.electric_bike;
      case DeviceCategory.hrMonitor:
        return Icons.favorite;
      case DeviceCategory.smartRing:
        return Icons.diamond;
      default:
        return Icons.devices_other;
    }
  }

  /// 设备类型对应的主题色
  static Color _deviceColor(String deviceType) {
    switch (deviceType) {
      case DeviceCategory.smartwatch:
        return AppColors.primary;
      case DeviceCategory.fitnessBand:
        return Colors.teal;
      case DeviceCategory.hrMonitor:
        return AppColors.heartRate;
      case DeviceCategory.smartRing:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deviceListAsync = ref.watch(deviceListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviceManagement)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(deviceListProvider);
        },
        child: deviceListAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildErrorView(context, ref, l10n),
          data: (devices) => ListView(
            padding: EdgeInsets.all(20.w),
            children: [
              // ---- 已连接设备 ----
              Text(l10n.connectedDevices, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 12.h),
              if (devices.isEmpty)
                _buildEmptyHint(context)
              else
                ...devices.map((d) => _buildDeviceCard(context, ref, d, l10n)),

              SizedBox(height: 24.h),

              // ---- 添加新设备 ----
              Text(l10n.addDevice, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 12.h),
              _buildAddDeviceButtons(context, ref, l10n),

              SizedBox(height: 24.h),

              // ---- 健康平台同步 ----
              Text('健康数据同步', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 12.h),
              _buildSyncSection(context, ref, l10n),

              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/profile/imports'),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('查看导入历史'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),

              SizedBox(height: 12.h),
              Text(
                '支持设备: Apple Watch、Garmin、华为手环/手表、小米手环、Polar H10 等 BLE 心率设备',
                style: TextStyle(fontSize: 13.sp, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 空设备列表提示
  Widget _buildEmptyHint(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: context.dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
        child: Column(
          children: [
            Icon(Icons.bluetooth_disabled, size: 48.w, color: context.textSecondary),
            SizedBox(height: 12.h),
            Text('暂无已绑定的设备', style: TextStyle(color: context.textSecondary, fontSize: 15.sp)),
          ],
        ),
      ),
    );
  }

  /// 错误视图
  Widget _buildErrorView(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64.w, color: context.textSecondary),
          SizedBox(height: 16.h),
          Text('加载失败', style: TextStyle(fontSize: 16.sp)),
          SizedBox(height: 8.h),
          Text('请下拉刷新重试', style: TextStyle(fontSize: 13.sp, color: context.textSecondary)),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(deviceListProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 设备卡片
  Widget _buildDeviceCard(BuildContext context, WidgetRef ref, Device device, AppLocalizations l10n) {
    final color = _deviceColor(device.deviceType);
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: context.dividerColor),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(_deviceIcon(device.deviceType), color: color),
        ),
        title: Text(device.name, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${DeviceCategory.label(device.deviceType)} · ${device.brand} ${device.model}'
          '${device.battery != null ? ' · 电量 ${device.battery}%' : ''}'
          ' · ${device.isConnected ? '已连接' : '离线'}',
          style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
        ),
        trailing: TextButton(
          onPressed: () => _showUnbindConfirm(context, ref, device, l10n),
          child: Text(l10n.cancel, style: TextStyle(color: context.textSecondary)),
        ),
      ),
    );
  }

  /// 添加设备按钮区
  Widget _buildAddDeviceButtons(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showBleScanSheet(context, ref),
            icon: const Icon(Icons.bluetooth_searching),
            label: Text(l10n.scanNearbyDevices),
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14.h)),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showManualBindDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('手动绑定设备'),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14.h)),
          ),
        ),
      ],
    );
  }

  /// 健康平台同步区
  Widget _buildSyncSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final devicesAsync = ref.watch(deviceListProvider);
    final healthDevices = devicesAsync.whenOrNull(
      data: (devices) => devices
          .where((d) => ['apple_health', 'huawei_health', 'garmin', 'health_connect'].contains(d.connType))
          .toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (healthDevices != null && healthDevices.isNotEmpty)
          ...healthDevices.map((d) => _buildSyncButton(context, ref, d))
        else ...[
          _buildSyncButton(context, ref, null),
        ],
      ],
    );
  }

  /// 单个同步按钮
  Widget _buildSyncButton(BuildContext context, WidgetRef ref, Device? device) {
    final label = device != null ? '从 ${device.name} 同步' : '从健康平台同步';
    final subtitle = device != null
        ? ConnType.label(device.connType)
        : 'Apple Health / Health Connect / 华为运动健康';
    final icon = device?.connType == ConnType.huaweiHealth
        ? Icons.watch
        : Icons.sync;

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: context.dividerColor),
      ),
      child: ListTile(
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppColors.success),
        ),
        title: Text(label),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp, color: context.textSecondary)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => HealthSyncPage(
                deviceId: device?.id,
                connType: device?.connType,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 解绑确认弹窗
  void _showUnbindConfirm(BuildContext context, WidgetRef ref, Device device, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解绑设备'),
        content: Text('确定要解绑 ${device.name} 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doUnbind(context, ref, device);
            },
            child: Text('确定', style: TextStyle(color: AppColors.heartRate)),
          ),
        ],
      ),
    );
  }

  Future<void> _doUnbind(BuildContext context, WidgetRef ref, Device device) async {
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.unbindDevice(device.id);
      if (resp.isSuccess) {
        ref.invalidate(deviceListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${device.name} 已解绑'), behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解绑失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  /// BLE 扫描底部弹窗
  void _showBleScanSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => _BleScanSheet(),
    ).then((result) {
      if (result != null && context.mounted) {
        _doBind(context, ref, result as Map<String, dynamic>);
      }
    });
  }

  /// 手动绑定表单弹窗
  void _showManualBindDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController(text: 'Apple');
    String deviceType = DeviceCategory.smartwatch;
    String connType = ConnType.appleHealth;
    String model = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动绑定设备'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '设备名称', hintText: '如 我的Apple Watch'),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(labelText: '品牌', hintText: 'Apple / Huawei / Garmin'),
                ),
                SizedBox(height: 8.h),
                TextField(
                  onChanged: (v) => model = v,
                  decoration: const InputDecoration(labelText: '型号（可选）', hintText: '如 Watch Ultra 2'),
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: deviceType,
                  decoration: const InputDecoration(labelText: '设备类型'),
                  items: [
                    const DropdownMenuItem(value: 'smartwatch', child: Text('智能手表')),
                    const DropdownMenuItem(value: 'fitness_band', child: Text('手环')),
                    const DropdownMenuItem(value: 'hr_monitor', child: Text('心率带')),
                    const DropdownMenuItem(value: 'smart_ring', child: Text('智能戒指')),
                    const DropdownMenuItem(value: 'other', child: Text('其他')),
                  ],
                  onChanged: (v) => setState(() => deviceType = v ?? deviceType),
                ),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  value: connType,
                  decoration: const InputDecoration(labelText: '同步方式'),
                  items: [
                    const DropdownMenuItem(value: 'apple_health', child: Text('Apple Health')),
                    const DropdownMenuItem(value: 'huawei_health', child: Text('华为运动健康')),
                    const DropdownMenuItem(value: 'health_connect', child: Text('Health Connect')),
                    const DropdownMenuItem(value: 'garmin', child: Text('Garmin Connect')),
                    const DropdownMenuItem(value: 'ble', child: Text('蓝牙直连')),
                  ],
                  onChanged: (v) => setState(() => connType = v ?? connType),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || brandCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              _doBind(context, ref, {
                'name': nameCtrl.text,
                'brand': brandCtrl.text,
                'model': model,
                'device_type': deviceType,
                'conn_type': connType,
              });
            },
            child: const Text('绑定'),
          ),
        ],
      ),
    );
  }

  Future<void> _doBind(BuildContext context, WidgetRef ref, Map<String, dynamic> data) async {
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.bindDevice(data);
      if (resp.isSuccess) {
        ref.invalidate(deviceListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${data['name']} 绑定成功'), behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('绑定失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

// ==================== BLE 扫描底部弹窗 ====================

/// BLE 扫描设备底部弹窗
///
/// 使用 MockBleService 模拟设备扫描、连接流程。
/// 点击设备 → 模拟连接（1-3秒延迟，80%成功率）→ 成功后弹出绑定确认。
class _BleScanSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BleScanSheet> createState() => _BleScanSheetState();
}

class _BleScanSheetState extends ConsumerState<_BleScanSheet> {
  final List<BleScanResult> _foundDevices = [];
  StreamSubscription<BleScanResult>? _scanSub;
  StreamSubscription<BleDeviceState>? _stateSub;
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingName;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    final ble = ref.read(bleServiceProvider);
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    _scanSub = ble.scanResults.listen((device) {
      if (mounted) {
        setState(() => _foundDevices.add(device));
      }
    });

    _stateSub = ble.deviceStateStream.listen((state) {
      if (!mounted) return;
      if (state == BleDeviceState.error) {
        setState(() => _isConnecting = false);
        _showSnack('连接失败，请重试');
      } else if (state == BleDeviceState.connected) {
        setState(() => _isConnecting = false);
        // 连接成功后关闭弹窗并传回服务器绑定
        Navigator.of(context).pop({
          'name': ble.connectedDeviceName ?? '未知设备',
          'brand': _connectingName?.split(' ').first ?? '未知',
          'device_type': 'smartwatch',
          'conn_type': 'ble',
        });
      }
    });

    ble.startScan(timeout: const Duration(seconds: 10));
  }

  void _connectDevice(BleScanResult device) {
    final ble = ref.read(bleServiceProvider);
    ble.stopScan();
    setState(() {
      _isConnecting = true;
      _connectingName = device.name;
    });
    ble.connect(device.id);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _stateSub?.cancel();
    ref.read(bleServiceProvider).stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            width: 32.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // 标题
          Row(
            children: [
              Text('扫描设备', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_isConnecting)
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_isScanning)
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                ),
              if (_isScanning)
                SizedBox(width: 8.w),
              Text(
                _isConnecting ? '连接中...' : (_isScanning ? '扫描中...' : '扫描完成'),
                style: TextStyle(fontSize: 13.sp, color: context.textSecondary),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '模拟扫描到 7 个设备（Mock 模式）',
            style: TextStyle(fontSize: 12.sp, color: context.textTertiary),
          ),
          SizedBox(height: 12.h),

          // 设备列表
          if (_foundDevices.isEmpty && _isScanning)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Center(
                child: Text(
                  '正在搜索附近的 BLE 设备...',
                  style: TextStyle(fontSize: 14.sp, color: context.textSecondary),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _foundDevices.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: context.dividerColor),
                itemBuilder: (context, index) {
                  final device = _foundDevices[index];
                  return _BleDeviceTile(
                    device: device,
                    enabled: !_isConnecting,
                    onTap: () => _connectDevice(device),
                  );
                },
              ),
            ),

          SizedBox(height: 12.h),

          // 手动绑定按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭扫描弹窗
                // 在父级打开手动绑定
              },
              child: const Text('未找到设备？手动绑定'),
            ),
          ),
        ],
      ),
    );
  }
}

/// BLE 设备列表项
class _BleDeviceTile extends StatelessWidget {
  final BleScanResult device;
  final bool enabled;
  final VoidCallback onTap;

  const _BleDeviceTile({
    required this.device,
    required this.enabled,
    required this.onTap,
  });

  Color _rssiColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.grey;
  }

  String _rssiLabel(int rssi) {
    if (rssi >= -50) return '强';
    if (rssi >= -70) return '中';
    return '弱';
  }

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'smartwatch':
        return Icons.watch;
      case 'fitness_band':
        return Icons.electric_bike;
      case 'hr_monitor':
        return Icons.favorite;
      case 'smart_ring':
        return Icons.diamond;
      default:
        return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: [
            // 设备图标
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(_deviceIcon(device.deviceType), color: AppColors.primary, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            // 设备信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${device.brand} · ${device.typeLabel}',
                    style: TextStyle(fontSize: 12.sp, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            // RSSI 信号强度
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _rssiColor(device.rssi).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${_rssiLabel(device.rssi)} ${device.rssi}dBm',
                style: TextStyle(fontSize: 11.sp, color: _rssiColor(device.rssi)),
              ),
            ),
            SizedBox(width: 8.w),
            // 连接箭头
            Icon(Icons.chevron_right, color: context.textTertiary, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
