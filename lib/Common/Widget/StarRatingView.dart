import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 星评展示组件（只读，5颗星）
///
/// 使用示例：
/// ```dart
/// StarRatingView(rating: 3.5)               // 默认尺寸
/// StarRatingView(rating: 4.0, starSize: 16) // 自定义星星大小
/// ```
///
/// 参数说明：
/// - [rating]：0.0~5.0，支持小数，按比例填充星星
/// - [starSize]：单颗星高度，默认 13.2（Figma: Frame 377）
/// - [gap]：星星间距，默认 1.0625（Figma: gap 1.0625px）
class StarRatingView extends StatelessWidget {
  // 当前星星 svg 的 viewBox 是 48x48，图形本身左右大约各有 4px 留白。
  // 直接按整张 viewBox 裁切会让 0.x 评分看起来比例失真，所以这里按可视区域换算。
  static const double _svgViewportSize = 48.0;
  static const double _svgHorizontalInset = 4.0;

  final double rating;
  final double starSize;
  final double gap;

  const StarRatingView({
    super.key,
    required this.rating,
    this.starSize = 13.2,
    this.gap = 1.0625,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedRating = rating.clamp(0.0, 5.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final double fillPercent = (clampedRating - i).clamp(0.0, 1.0);
            final double visualWidthFactor = _calculateVisualWidthFactor(fillPercent);
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
              child: SizedBox(
                width: starSize,
                height: starSize,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SvgPicture.asset(
                        'assets/images/svg/rate_star.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (fillPercent > 0)
                      Positioned.fill(
                        child: ClipRect(
                          clipper: _StarFillClipper(visualWidthFactor),
                          child: SvgPicture.asset(
                            'assets/images/svg/rate_star2.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  double _calculateVisualWidthFactor(double fillPercent) {
    if (fillPercent <= 0) return 0;
    if (fillPercent >= 1) return 1;

    const double insetRatio = _svgHorizontalInset / _svgViewportSize;
    const double visibleRatio = (_svgViewportSize - _svgHorizontalInset * 2) / _svgViewportSize;
    return (insetRatio + visibleRatio * fillPercent).clamp(0.0, 1.0);
  }
}

class _StarFillClipper extends CustomClipper<Rect> {
  final double widthFactor;

  _StarFillClipper(this.widthFactor);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * widthFactor, size.height);

  @override
  bool shouldReclip(_StarFillClipper oldClipper) => widthFactor != oldClipper.widthFactor;
}
