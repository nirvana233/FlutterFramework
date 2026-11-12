import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 通用勾选框组件
/// 使用 edit_chose.svg 和 edit_unselect.svg 图标
class CheckBoxView extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  final bool enableHaptic;
  final EdgeInsetsGeometry padding;

  const CheckBoxView({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 20,
    this.enableHaptic = true,
    this.padding = const EdgeInsets.all(0),
  });

  void _handleTap() {
    if (onChanged != null) {
      if (enableHaptic) {
        VibrationMgr.instance.selection();
      }
      onChanged!(!value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: Padding(
        padding: padding,
        child: SvgPicture.asset(
          value ? 'assets/images/svg/edit_chose.svg' : 'assets/images/svg/edit_unselect.svg',
          width: size,
          height: size,
        ),
      ),
    );
  }
}
