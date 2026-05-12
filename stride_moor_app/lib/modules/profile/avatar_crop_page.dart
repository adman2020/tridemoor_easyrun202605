import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../config/theme.dart' show AppColors;

/// 手动头像裁剪页面
///
/// 用户通过 InteractiveViewer 缩放/拖动图片，
/// 在固定圆形裁剪框内调整位置，
/// 点击确认后裁剪为 512x512 正方形返回。
///
/// ⚠️ 关键设计：不预解码 ui.Image（会卡 UI 线程），展示用 Image.file 异步加载，
///   裁剪时再解码原图计算坐标。
class AvatarCropPage extends StatefulWidget {
  final String imagePath;

  const AvatarCropPage({super.key, required this.imagePath});

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  final TransformationController _transformCtrl = TransformationController();
  /// 图片在屏幕上的显示尺寸（Image.file + BoxFit.contain 后的实际渲染尺寸）
  Size _displaySize = Size.zero;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    // 立即用屏幕尺寸确定显示区域，不等待图片解码
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLayout());
  }

  void _initLayout() {
    if (!mounted) return;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height - kToolbarHeight;
    setState(() {
      // 留边距，不贴边
      _displaySize = Size(screenW - 24, (screenH - 80).clamp(100, screenH));
    });
    // 再下一帧居中（此时 Image.file 还没加载完，但尺寸已确定）
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerImage());
  }

  void _centerImage() {
    // 不进行任何平移。InteractiveViewer 由 Center 定位在 body 中间，
    // SizedBox 填充 InteractiveViewer，图片居中在裁剪框正下方。
    _transformCtrl.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  /// 根据 InteractiveViewer 当前变换矩阵计算裁剪区域并裁切
  Future<Uint8List?> _cropSelectedArea() async {
    try {
      setState(() => _isCropping = true);

      // 在后台线程加载原图（可能较大，但只在点击确认时执行）
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes,
        targetWidth: 2048, targetHeight: 2048,
      );
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();

      // 计算 BoxFit.contain 在 _displaySize 内实际渲染区域
      final fitScaleW = _displaySize.width / imgW;
      final fitScaleH = _displaySize.height / imgH;
      final fitScale = fitScaleW < fitScaleH ? fitScaleW : fitScaleH;
      final renderedW = imgW * fitScale;
      final renderedH = imgH * fitScale;
      final imgOffX = (_displaySize.width - renderedW) / 2;
      final imgOffY = (_displaySize.height - renderedH) / 2;

      // 获取 body 尺寸（裁剪框所在区域）
      final bodySize = MediaQuery.of(context).size;
      final bodyH = bodySize.height - kToolbarHeight;
      final bodyShortest = bodySize.width < bodyH ? bodySize.width : bodyH;
      // 裁剪框直径（与 UI 中 Center widget 一致）
      final cropSize = bodyShortest * 0.75;

      // 从变换矩阵提取 scale 和 translation
      final matrix = _transformCtrl.value;
      final mScale = matrix.getMaxScaleOnAxis();
      final tx = matrix[12];
      final ty = matrix[13];

      // 裁剪框中心 = Container（Viewport）中心
      final cropCx = _displaySize.width / 2;
      final cropCy = _displaySize.height / 2;

      // 裁剪框中心 → 显示图片坐标（相对于 SizedBox 原点）
      // 矩阵 translate+scale 表示 SizedBox 在 Viewport 内的变换
      final cxOnSizedBox = (cropCx - tx) / mScale;
      final cyOnSizedBox = (cropCy - ty) / mScale;

      // 图片在 SizedBox 内由 BoxFit.contain 居中渲染
      // SizedBox 内图片左上角偏移 = imgOffX/Y
      final cxOnRendered = cxOnSizedBox - imgOffX;
      final cyOnRendered = cyOnSizedBox - imgOffY;

      // 渲染图片 → 原始图片（像素坐标）
      final cxOnImg = cxOnRendered / fitScale;
      final cyOnImg = cyOnRendered / fitScale;

      // 裁剪框尺寸 → 原始图片坐标
      final cropOnImg = (cropSize / mScale) / fitScale;

      // 正方形裁剪区域（原图坐标）
      final half = cropOnImg / 2;
      final srcLeft = (cxOnImg - half).clamp(0.0, imgW);
      final srcTop = (cyOnImg - half).clamp(0.0, imgH);
      final srcRight = (cxOnImg + half).clamp(0.0, imgW);
      final srcBottom = (cyOnImg + half).clamp(0.0, imgH);
      final srcW = srcRight - srcLeft;
      final srcH = srcBottom - srcTop;
      if (srcW <= 0 || srcH <= 0) {
        img.dispose();
        return null;
      }

      // 裁剪并缩放到 512x512
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(srcLeft, srcTop, srcW, srcH),
        Rect.fromLTWH(0, 0, 512, 512),
        Paint(),
      );
      final picture = recorder.endRecording();
      final dstImage = await picture.toImage(512, 512);
      final byteData =
          await dstImage.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      dstImage.dispose();
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('[AvatarCropPage] 裁剪失败: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isCropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cropSize = screenSize.shortestSide * 0.75;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('调整头像'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          TextButton(
            onPressed: _isCropping
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    final bytes = await _cropSelectedArea();
                    if (context.mounted) navigator.pop(bytes);
                  },
            child: _isCropping
                ? SizedBox(
                    width: 20.r, height: 20.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary,
                    ),
                  )
                : Text(
                    '确认',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 可缩放拖动图片（Image.file 原生异步加载，不卡 UI）
          Center(
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.5,
              maxScale: 4.0,
              constrained: false,
              child: SizedBox(
                width: _displaySize.width,
                height: _displaySize.height,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  // 图片非正方形时有渐入效果，不显示空白
                  frameBuilder: (_, child, frame, __) {
                    return frame == null ? const SizedBox() : child;
                  },
                ),
              ),
            ),
          ),
          // 裁剪框遮罩（框外半透明，框内可见）
          IgnorePointer(
            child: ClipPath(
              clipper: _CropOverlayClipper(cropSize: cropSize),
              child: Container(color: Colors.black54),
            ),
          ),
          // 裁剪框边框
          IgnorePointer(
            child: Center(
              child: Container(
                width: cropSize,
                height: cropSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(cropSize / 2),
                ),
              ),
            ),
          ),
          // 底部提示
          Positioned(
            bottom: 60.h,
            left: 0, right: 0,
            child: Center(
              child: Text(
                '双指缩放拖动以调整位置',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 裁剪遮罩：裁剪框内透明，框外半透明黑
class _CropOverlayClipper extends CustomClipper<Path> {
  final double cropSize;
  _CropOverlayClipper({required this.cropSize});

  @override
  Path getClip(Size size) {
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: cropSize / 2,
      ));
    return Path.combine(PathOperation.reverseDifference, outer, inner);
  }

  @override
  bool shouldReclip(covariant _CropOverlayClipper old) =>
      old.cropSize != cropSize;
}
