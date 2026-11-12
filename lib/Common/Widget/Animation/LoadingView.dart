import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Extension/ColorUtil.dart';

class LoadingView extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool isCupertino;
  const LoadingView({
    super.key,
    this.width,
    this.height,
    this.color,
    this.strokeWidth,
    this.isCupertino = false,
  });
  final double? strokeWidth;
  @override
  Widget build(BuildContext context) {
    // RepaintBoundary：转圈动画每帧只重绘本层，不牵连父级大界面（详情底栏 / 毛玻璃等）
    return RepaintBoundary(
      child: SizedBox(
        width: width ?? 16,
        height: height ?? 16,
        child: CircularProgressIndicator(
          color: color ?? ColorsUtil.appThemeColor,
          strokeWidth: strokeWidth ?? 2,
        ),
      ),
    );
  }
}
