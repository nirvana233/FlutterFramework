import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:get/get.dart';

class Tag extends StatelessWidget {
  final String label;
  final TagType type;
  final EdgeInsets? padding;
  final bool affectedByNight;

  const Tag(
    this.label, {
    super.key,
    this.type = TagType.normal,
    this.padding,
    this.affectedByNight = false,
  });

  @override
  Widget build(BuildContext context) {
    final FigmaThemeColors colors;
    if (affectedByNight) {
      colors = getFigmaColors;
    } else {
      colors = FigmaVariables.light;
    }

    // 使用 FigmaVariables 设计令牌支持明暗模式
    Color backColor = switch (type) {
      // Figma: colorBgElementB96 (#F5F5F5 light / #333333 dark)
      TagType.normal => colors.colorBgElementB96,
      // Figma: colorBgLabelBlue (#D8ECFF light / #2D3A47 dark)
      TagType.completed => colors.colorBgLabelBlue,
      // Figma: colorBgLabelRed
      TagType.primary => colors.colorBgLabelRed,
      // Figma: colorBgLabelGreenLight (#E0EFE2 light / #2A402D dark)
      TagType.onGoing => colors.colorBgLabelGreenLight,
    };

    Color foreColor = switch (type) {
      // Figma: colorTextRegularB50 (#808080 light / #999999 dark)
      TagType.normal => colors.colorTextRegularB50,
      // Figma: colorTextLabelBlue (#0C9CFF light / #5AAFFF dark)
      TagType.completed => colors.colorTextLabelBlue,
      // Figma: colorTextPrimaryRed
      TagType.primary => colors.colorTextPrimaryRed,
      // Figma: 绿色标签文字（固定颜色）
      TagType.onGoing => FigmaVariables.colorTextLabelGreen,
    };

    return Container(
      height: 14,
      alignment: Alignment.center,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: backColor,
        borderRadius: FigmaVariables.borderRadius3,
      ),
      child: Text(
        type == TagType.completed
            // Completed
            ? 'completednew'.tr
            : type == TagType.onGoing
            // Ongoing
            ? 'ongoing'.tr
            : label,
        style: TextStyle(
          color: foreColor,
          fontSize: 10,
          height: 1.0,
        ),
      ),
    );
  }
}

enum TagType { completed, onGoing, primary, normal }
