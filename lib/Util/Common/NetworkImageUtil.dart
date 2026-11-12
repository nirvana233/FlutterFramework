import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_framework/Base/BaseLessWidget.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/NetworkImageShimmer.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 项目统一网络图片组件。
/// 默认集成缓存、占位图、错误兜底和图片压缩参数拼接，页面展示远程图片时优先复用。
///
/// `imageType` 用于约定常见图片尺寸，`imageSize` 可覆盖预设像素尺寸，
/// `isNeedRedirect` 控制是否自动拼接压缩参数（需图片服务支持 `?w=&h=`，见 Tools.getRedirectImageUrl）。
/// 常见场景：
/// - 封面图：默认 `cover`（540*720）
/// - 头像：`avatar`（148*148）/ `userHead`（68*68），或显式 `width/height`
/// - 新增业务尺寸：在 [NetworkImageSizeEnum] 追加枚举并在 [getImageSize] 登记
class NetworkImageUtil extends BaseLessWidget {
  /// 静态单例缓存管理器，避免每个实例创建新的缓存管理器
  /// 这样可以统一管理图片缓存，减少内存占用
  static final DefaultCacheManager _sharedCacheManager = DefaultCacheManager();

  /// 获取共享的缓存管理器实例（供外部清理缓存使用）
  static DefaultCacheManager get cacheManager => _sharedCacheManager;

  /// 原图预览使用独立缓存，避免覆盖旧版和缩略图共用的 URL 缓存。
  static String originalPreviewCacheKeyFor(String url) {
    return 'original-preview-v1:$url';
  }

  /// 清理所有图片缓存（用于内存压力时调用）
  static Future<void> clearCache() async {
    try {
      // await _sharedCacheManager.emptyCache();
      // logD('NetworkImageUtil: 图片缓存已清理');
      logD('NetworkImageUtil: 图片缓存需要清理');
    } catch (e) {
      logE('NetworkImageUtil: Clear cache failed $e');
    }
  }

  /// 支持 http/https 远程地址，也支持本地 asset 路径。
  final String? imageUrl;
  final double? width;
  final double? height;

  /// 常见业务图片尺寸枚举，会影响压缩参数与缓存尺寸。
  final NetworkImageSizeEnum imageType;

  /// 网络图片的目标像素尺寸 (宽, 高)，优先于 [imageType]，包括 none。
  /// 用于 CDN 压缩参数，不影响布局，也不会再乘设备 DPR。
  /// 内存解码只约束宽边并保持源图比例：服务端未按规格裁剪时，
  /// 由上层 BoxFit.cover 裁剪，不会拉伸变形。
  /// 两个值都必须大于 0；未传或无效时沿用 [imageType]。
  final (int, int)? imageSize;

  /// 非空时覆盖默认缓存 key；自定义 [imageSize] 默认按规格隔离缓存，
  /// 未指定自定义尺寸时仍沿用原始 URL key。
  final String? cacheKey;

  final BoxFit? fit;
  final bool showPlaceholder;
  final bool showError;
  // 占位图的图
  final String? placeholderImageUrl;

  /// 是否自动拼接图片压缩参数。
  /// 业务接口返回原图地址时通常保持 `true`，特殊地址或本地资源可关闭。
  final bool isNeedRedirect;
  final bool isCircle;

  /// [BoxFit.cover] 等裁剪模式下，控制可见区域对齐（如竖版头像取顶部）。
  final Alignment alignment;
  final Color? placeholderColor;
  final String? placeholderImage;
  final String? errorImage;
  final int maxRetryAttempts;
  final Duration? cacheTimeout;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final bool useOldImageOnUrlChange;

  /// 加载态扫光默认开启；对动效敏感或已有自定义加载效果的调用点可关闭。
  final bool showLoadingShimmer;

  /// 是否通过 memCacheWidth/memCacheHeight 对图片做内存解码缩放。
  /// 关闭后 [imageType] / [imageSize] 仍会用于服务端图片裁剪参数。
  final bool useMemCacheResize;

  const NetworkImageUtil({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.imageType = NetworkImageSizeEnum.cover,
    this.imageSize,
    this.cacheKey,
    this.fit = BoxFit.fill,
    this.showPlaceholder = true,
    this.showError = true,
    this.isNeedRedirect = true,
    this.isCircle = false,
    this.alignment = Alignment.center,
    this.placeholderColor,
    this.placeholderImage,
    this.placeholderImageUrl,
    this.errorImage,
    this.maxRetryAttempts = 3,
    this.cacheTimeout,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = Duration.zero,
    this.useOldImageOnUrlChange = false,
    this.showLoadingShimmer = true,
    this.useMemCacheResize = true,
  });

  /// 根据业务图片类型返回默认压缩尺寸。
  (int, int) getImageSize(NetworkImageSizeEnum size) {
    switch (size) {
      case NetworkImageSizeEnum.none:
        return (0, 0);
      case NetworkImageSizeEnum.cover:
        return (540, 720);
      case NetworkImageSizeEnum.avatar:
        return (148, 148);
      case NetworkImageSizeEnum.userHead:
        return (68, 68);
      case NetworkImageSizeEnum.banner:
        return (750, 276);
      case NetworkImageSizeEnum.illustration:
        return (750, 1500);
    }
  }

  String? get _placeholderAssetPath => placeholderImage ?? placeholderImageUrl;

  Widget _buildPlaceholderWidget() {
    final assetPath = _placeholderAssetPath;
    if (assetPath != null && assetPath.isNotEmpty) {
      if (assetPath.toLowerCase().endsWith('.svg')) {
        return _withPlaceholderBackground(
          SvgPicture.asset(
            assetPath,
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
          ),
        );
      }
      return _withPlaceholderBackground(
        Image.asset(
          assetPath,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
        ),
      );
    }

    return SvgPicture.asset(
      'assets/images/svg/placeholder_image.svg',
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  Widget _withPlaceholderBackground(Widget child) {
    final color = placeholderColor;
    return color == null ? child : ColoredBox(color: color, child: child);
  }

  /// 加载占位：保留现有占位优先级，并按需叠加统一扫光动画。
  Widget _buildLoadingWidget() {
    final Widget placeholder;
    if (isAvailable(placeholderImageUrl)) {
      placeholder = _buildPlaceholderWidget();
    } else if (placeholderColor != null) {
      placeholder = DecoratedBox(
        decoration: BoxDecoration(color: placeholderColor),
      );
    } else if (showPlaceholder) {
      placeholder = _buildPlaceholderWidget();
    } else {
      return const SizedBox();
    }

    if (!showLoadingShimmer) return placeholder;
    return NetworkImageLoadingShimmer(child: placeholder);
  }

  @override
  Widget build(BuildContext context) {
    final customImageSize = switch (imageSize) {
      (final w, final h) when w > 0 && h > 0 => (w, h),
      _ => null,
    };
    final (w, h) = customImageSize ?? getImageSize(imageType);
    // 没有像素尺寸时，memCache 按逻辑宽 × DPR，避免小头像在高分屏发糊。
    final memCacheWidth = useMemCacheResize
        ? w > 0
              ? w
              : width != null
              ? (width! * MediaQuery.devicePixelRatioOf(context)).ceil()
              : null
        : null;
    // 自定义规格源图比例未知，只约束宽边让解码保比例，高边交给 cover 裁剪；
    // 预设尺寸输入比例已知，可同时约束宽高强制缩到规格。
    final memCacheHeight = useMemCacheResize && customImageSize == null && h > 0 ? h : null;
    Widget imageWidget = SizedBox(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      child: isAvailable(imageUrl)
          ? (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'))
                ? CachedNetworkImage(
                    // cacheManager: ImageCacheManagers.get(stalePeriod: cacheTimeout),
                    cacheManager: _sharedCacheManager,
                    // 实际图片的URL
                    imageUrl: isNeedRedirect
                        ? getRedirectImageUrl(
                            imageUrl!,
                            w: w,
                            h: h,
                            needClip:
                                customImageSize != null || imageType != NetworkImageSizeEnum.none,
                          )
                        : imageUrl!,
                    // 自定义规格不复用旧原图或其它裁剪图；原有调用保持原始 URL 缓存。
                    cacheKey:
                        cacheKey ??
                        (customImageSize == null
                            ? imageUrl!
                            : 'image-size-v1:$w:$h:$isNeedRedirect:${imageUrl!}'),
                    // 设置HTTP头部
                    httpHeaders: const {
                      'User-Agent': 'NovelTime/1.0',
                      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                      'Accept-Encoding': 'gzip, deflate, br',
                      'Connection': 'keep-alive',
                    },
                    // 关键：保持内存缓存，避免重新加载动画
                    // 仅预设尺寸指定 h>0 时传 memCacheHeight；否则只传宽，避免竖图被压扁
                    // （同时指定 memCacheWidth + memCacheHeight 会强制缩到该尺寸，改变宽高比）
                    memCacheWidth: memCacheWidth,
                    memCacheHeight: memCacheHeight,
                    // 加载态入口：内存缓存直接出图，磁盘缓存解码时可能短暂进入。
                    progressIndicatorBuilder: (context, url, downloadProgress) {
                      return _buildLoadingWidget();
                    },
                    // // 网络下载完成后的淡入动画（缓存加载时不会有动画）
                    // fadeInDuration: const Duration(milliseconds: 0),
                    // fadeOutDuration: const Duration(milliseconds: 0),
                    fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 500),
                    fadeOutDuration: fadeOutDuration ?? Duration.zero,
                    useOldImageOnUrlChange: useOldImageOnUrlChange,
                    // 加载失败时的错误图
                    errorWidget: (context, url, error) {
                      // 记录错误日志但不抛出异常,避免崩溃上报到Firebase
                      logE("Image load failed: $url, error: $error");
                      if (showError) {
                        return _buildPlaceholderWidget();
                      }
                      return const SizedBox();
                    },
                    // 错误监听器 - 捕获所有加载错误,防止崩溃
                    errorListener: (error) {
                      // 静默记录错误,不向上抛出异常
                      logE("CachedNetworkImage error listener: $imageUrl, error: $error");
                    },
                    fit: fit,
                    alignment: alignment,
                    filterQuality: FilterQuality.high,
                  )
                : Image.asset(
                    imageUrl!,
                    width: width,
                    height: height,
                    fit: fit,
                    alignment: alignment,
                  )
          : showPlaceholder
          ? _buildPlaceholderWidget()
          : const SizedBox(),
    );

    return isCircle ? ClipOval(child: imageWidget) : imageWidget;
  }
}

enum NetworkImageSizeEnum {
  none,
  // 封面图 540*720
  cover,
  // 头像 148*148
  avatar,
  // 小头像 68*68
  userHead,
  // 横幅 750*276
  banner,
  // 大图 / 立绘 750*1500
  illustration,
}
