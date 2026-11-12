import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Widget/Animation/LottieAnimationView.dart';
import 'package:flutter_framework/Common/Widget/SmartSafeArea.dart';
import 'package:flutter_framework/Util/Common/NetworkImageUtil.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// 全屏原图预览：按图片自身比例居中展示，支持捏合缩放。
/// 作者头像、后续聊天头像等入口通过 [ImagePreviewDialog.show] 打开。
class ImagePreviewDialog extends StatefulWidget {
  const ImagePreviewDialog({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  /// 地址无效时直接返回；点空白或关闭按钮退出。已放大时点图先复位。
  static Future<void> show(String? imageUrl) {
    if (!isAvailable(imageUrl)) return Future.value();
    return Get.dialog<void>(
      ImagePreviewDialog(imageUrl: imageUrl!),
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      useSafeArea: false,
    );
  }

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  final TransformationController _transform = TransformationController();
  bool _isOriginalReady = false;
  bool _isOriginalFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prefetchOriginal());
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// 先把原图写入缓存，再展示图片；loading 由弹窗自己叠 Lottie。
  Future<void> _prefetchOriginal() async {
    try {
      await NetworkImageUtil.cacheManager.downloadFile(
        widget.imageUrl,
        key: NetworkImageUtil.originalPreviewCacheKeyFor(widget.imageUrl),
      );
      if (mounted) {
        setState(() => _isOriginalReady = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOriginalFailed = true);
      }
    }
  }

  void _retryPrefetchOriginal() {
    setState(() => _isOriginalFailed = false);
    unawaited(_prefetchOriginal());
  }

  bool get _isZoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  void _onImageTap() {
    if (_isZoomed) {
      _transform.value = Matrix4.identity();
      return;
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // ===== 点击空白关闭 =====
          GestureDetector(
            onTap: Get.back,
            child: const ColoredBox(
              color: FigmaVariables.colorBgMaskB070,
              child: SizedBox.expand(),
            ),
          ),
          // ===== 原图 =====
          Positioned.fill(
            child: _isOriginalReady ? _buildImage() : const SizedBox.shrink(),
          ),
          // ===== 加载 =====
          if (!_isOriginalReady && !_isOriginalFailed)
            const Positioned.fill(
              child: LottieAnimationView(),
            ),
          // ===== 加载失败 =====
          if (_isOriginalFailed) _buildLoadFailed(),
          // ===== 关闭按钮 =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildCloseButton(),
          ),
        ],
      ),
    );
  }

  /// 原比例 contain + 捏合缩放；请求原图时用全局 Lottie 加载，避免空白等待。
  Widget _buildImage() {
    return SmartSafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FigmaVariables.spacing20,
          FigmaVariables.spacing40,
          FigmaVariables.spacing20,
          FigmaVariables.spacing20,
        ),
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 4,
          child: GestureDetector(
            onTap: _onImageTap,
            child: NetworkImageUtil(
              imageUrl: widget.imageUrl,
              imageType: NetworkImageSizeEnum.none,
              cacheKey: NetworkImageUtil.originalPreviewCacheKeyFor(widget.imageUrl),
              fit: BoxFit.contain,
              isNeedRedirect: false,
              useMemCacheResize: false,
              showPlaceholder: false,
              showLoadingShimmer: false,
              showError: false,
            ),
          ),
        ),
      ),
    );
  }

  /// 原图预取失败时展示错误提示，并允许用户重新请求。
  Widget _buildLoadFailed() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: FigmaVariables.colorTextPrimaryB100,
            size: FigmaVariables.spacing48,
          ),
          const SizedBox(height: FigmaVariables.spacing12),
          Text(
            'load_image_failed'.tr,
            style: const TextStyle(
              color: FigmaVariables.colorTextPrimaryB100,
              fontSize: FigmaVariables.fontSize16,
            ),
          ),
          const SizedBox(height: FigmaVariables.spacing12),
          IconButton(
            onPressed: _retryPrefetchOriginal,
            tooltip: 'retry'.tr,
            color: FigmaVariables.colorTextPrimaryB100,
            iconSize: FigmaVariables.spacing32,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  /// 右上角关闭；点击退出预览。
  Widget _buildCloseButton() {
    return SmartSafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(
            top: FigmaVariables.spacing8,
            right: FigmaVariables.spacing20,
          ),
          child: GestureDetector(
            onTap: Get.back,
            child: Semantics(
              button: true,
              label: 'close'.tr,
              child: Container(
                width: FigmaVariables.spacing32,
                height: FigmaVariables.spacing32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FigmaVariables.colorTextPrimaryB100,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/images/svg/common_close.svg',
                  width: FigmaVariables.spacing16,
                  height: FigmaVariables.spacing16,
                  colorFilter: const ColorFilter.mode(
                    FigmaVariables.colorTextPrimaryB100,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
