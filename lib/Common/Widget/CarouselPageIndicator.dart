import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';

/// 首页 banner 与阅读结束推荐共用的分页指示点，由父级提供页数和当前页。
class CarouselPageIndicator extends StatelessWidget {
  const CarouselPageIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.colors,
  });

  final int itemCount;
  final int currentIndex;
  final FigmaThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: FigmaVariables.spacing2),
          width: isActive ? FigmaVariables.spacing20 : FigmaVariables.spacing6,
          height: FigmaVariables.spacing4,
          decoration: BoxDecoration(
            color: isActive ? colors.colorSecondary : colors.colorBgElementB70,
            borderRadius: FigmaVariables.borderRadius24,
          ),
        );
      }),
    );
  }
}
