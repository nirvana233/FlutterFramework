import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:get/get.dart';

/// 通用返回按钮组件
/// 使用 Material Icon arrow_back_ios_new
/// 自带 padding，点击 padding 区域也可触发返回
class CommonBackButton extends StatelessWidget {
  /// 按钮尺寸，默认20
  final double size;

  /// 图标颜色，默认使用主题颜色
  final Color? color;

  /// 点击回调，默认使用 Get.back()
  final VoidCallback? onTap;

  /// 内边距，默认16
  final EdgeInsetsGeometry padding;

  const CommonBackButton({
    super.key,
    this.size = 20,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.back(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: padding,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.arrow_back_ios_new,
            color: color ?? getAppFigmaColors.colorTextPrimaryB0,
            size: size,
          ),
        ),
      ),
    );
  }
}
