import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// BottomSheet 顶栏收起按钮
///
/// common_arrow 旋转 90° 朝下；默认点击关闭当前 Sheet。
/// 热区最小 44×44，父级有高度约束时纵向撑满（如标题栏 Positioned top/bottom: 0）。
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({
    super.key,
    this.onTap,
    this.color,
    this.iconSize = 20,
    this.hitWidth = FigmaVariables.spacing44,
  });

  final VoidCallback? onTap;

  /// 图标颜色，默认 [FigmaThemeColors.colorBgElementB30]
  final Color? color;

  final double iconSize;

  /// 点击区域宽度
  final double hitWidth;

  void _handleTap() {
    VibrationMgr.instance.selection();
    if (onTap != null) {
      onTap!();
      return;
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? getFigmaColors.colorBgElementB30;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: hitWidth,
          minHeight: FigmaVariables.spacing44,
        ),
        child: Center(
          child: Transform.rotate(
            angle: 1.5708,
            child: SvgPicture.asset(
              'assets/images/svg/common_arrow.svg',
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(
                effectiveColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
