import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// 邮箱输入框组件
/// 带浮动标签、清除按钮
class EmailTextField extends StatelessWidget {
  /// 输入框控制器
  final TextEditingController controller;

  /// 焦点节点
  final FocusNode? focusNode;

  /// 占位符文字
  final String? placeholder;

  /// 错误提示文字
  final String? errorText;

  /// 是否启用
  final bool enabled;

  /// 输入内容变化回调
  final ValueChanged<String>? onChanged;

  /// 提交回调
  final ValueChanged<String>? onSubmitted;

  /// 背景颜色（用于浮动标签背景）
  final Color? backgroundColor;

  const EmailTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.placeholder,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = getAppFigmaColors;
    final bool hasError = errorText != null;
    final bool showClearButton = controller.text.isNotEmpty && enabled;
    final bgColor = backgroundColor ?? colors.colorBgElementB96;

    return SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 输入框容器
          Positioned(
            left: 0,
            right: 0,
            top: 13,
            child: Container(
              height: 51,
              padding: const EdgeInsets.symmetric(horizontal: FigmaVariables.spacing16),
              decoration: BoxDecoration(
                borderRadius: FigmaVariables.borderRadius12,
                border: Border.all(
                  color: colors.colorBgElementB80,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.emailAddress,
                      enabled: enabled,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      textAlign: TextAlign.left,
                      selectionControls: MaterialTextSelectionControls(),
                      style: TextStyle(
                        color: colors.colorTextPrimaryB0,
                        fontSize: FigmaVariables.fontSize16,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: placeholder,
                        hintStyle: TextStyle(
                          color: colors.colorTextSynopsisB70,
                          fontSize: FigmaVariables.fontSize16,
                          fontWeight: FontWeight.w700,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  // 清除按钮
                  if (showClearButton)
                    GestureDetector(
                      onTap: () => controller.clear(),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: FigmaVariables.spacing8),
                        child: SvgPicture.asset(
                          'assets/images/svg/common_close.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            colors.colorTextRegularB50,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 浮动标签
          Positioned(
            left: FigmaVariables.spacing16,
            top: 4,
            child: Container(
              color: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                // EMAIL
                'email_label'.tr,
                style: TextStyle(
                  color: colors.colorTextRegularB50,
                  fontSize: FigmaVariables.fontSize14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // 错误提示
          if (hasError)
            Positioned(
              left: 0,
              bottom: -20,
              child: _buildErrorMessage(errorText!, colors),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message, FigmaThemeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/svg/common_warn.svg',
          width: 16,
          height: 16,
        ),
        const SizedBox(width: FigmaVariables.spacing4),
        Text(
          message,
          style: TextStyle(
            color: colors.colorSecondary,
            fontSize: FigmaVariables.fontSize12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
