import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';

/// 设置列表项：左侧标题，右侧值文本 / 自定义组件 / 箭头
class SettingItem extends StatelessWidget {
  final String title;

  /// 右侧值文本（与 [trailing] 二选一）
  final String? value;

  /// 右侧自定义组件（如开关），传入后不显示箭头
  final Widget? trailing;

  final VoidCallback? onTap;

  /// 是否显示底部分割线
  final bool showDivider;

  const SettingItem({
    super.key,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = getAppFigmaColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              VibrationMgr.instance.selection();
              onTap!();
            },
      child: Container(
        padding: FigmaVariables.paddingH16,
        constraints: const BoxConstraints(minHeight: FigmaVariables.spacing52),
        decoration: BoxDecoration(
          color: colors.colorBgElementB100,
          border: showDivider
              ? Border(bottom: BorderSide(color: colors.colorBgElementB90, width: 0.5))
              : null,
        ),
        child: Row(
          children: [
            // ===== 标题 =====
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: colors.colorTextPrimaryB20,
                  fontSize: FigmaVariables.fontSize16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // ===== 右侧值 / 自定义组件 / 箭头 =====
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(left: FigmaVariables.spacing8),
                child: Text(
                  value!,
                  style: TextStyle(
                    color: colors.colorTextRegularB50,
                    fontSize: FigmaVariables.fontSize14,
                  ),
                ),
              ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: FigmaVariables.spacing20,
                color: colors.colorTextSynopsisB70,
              ),
          ],
        ),
      ),
    );
  }
}
