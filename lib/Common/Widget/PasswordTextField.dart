import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 密码输入框组件
/// 带浮动标签、显示/隐藏密码按钮
class PasswordTextField extends StatefulWidget {
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

  const PasswordTextField({
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
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final colors = getAppFigmaColors;
    final bool hasError = widget.errorText != null;
    final bgColor = widget.backgroundColor ?? colors.colorBgElementB96;

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
                  color: hasError ? colors.colorTextPrimaryRed : colors.colorBgElementB80,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      obscureText: !_passwordVisible,
                      enabled: widget.enabled,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: colors.colorTextPrimaryB0,
                        fontSize: FigmaVariables.fontSize16,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
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
                  // 显示/隐藏密码按钮
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: FigmaVariables.spacing8),
                      child: SvgPicture.asset(
                        _passwordVisible
                            ? 'assets/images/svg/common_eye_password.svg'
                            : 'assets/images/svg/common_eye_password-1.svg',
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
                'PASSWORD',
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
              child: _buildErrorMessage(widget.errorText!, colors),
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
