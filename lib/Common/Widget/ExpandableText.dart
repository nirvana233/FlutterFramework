import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Extension/ColorUtil.dart';
import 'package:get/get.dart';

/// 可展开/折叠的文本组件
///
/// 特点：
/// - 超过最大行数时自动截断，末尾显示 "... 展开"
/// - 展开后显示全部文字 + "收起"
/// - 点击整个区域（包括行间空白）可切换展开/折叠状态
///
/// 使用示例：
/// ```dart
/// ExpandableText(
///   text: '这是一段很长的文字...',
///   maxLines: 3,
/// )
/// ```
class ExpandableText extends StatefulWidget {
  /// 要显示的文本内容
  final String text;

  /// 折叠时显示的最大行数，默认为 3
  final int maxLines;

  /// 文本样式
  final TextStyle? textStyle;

  /// 展开/收起按钮的样式
  final TextStyle? expandStyle;

  /// 展开时显示的文字，默认为 'show_more'.tr
  final String? expandText;

  /// 收起时显示的文字，默认为 'show_less'.tr
  final String? collapseText;

  /// 文本对齐方式
  final TextAlign textAlign;

  /// 初始是否展开，默认为 false
  final bool initialExpanded;

  /// 展开/折叠状态变化回调
  final ValueChanged<bool>? onExpandedChanged;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.textStyle,
    this.expandStyle,
    this.expandText,
    this.collapseText,
    this.textAlign = TextAlign.start,
    this.initialExpanded = false,
    this.onExpandedChanged,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  void didUpdateWidget(covariant ExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _isExpanded = widget.initialExpanded;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpandedChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        widget.textStyle ??
        const TextStyle(
          fontSize: 14,
          color: Color(0xFF0D0D0D),
          height: 1.4,
        );
    final linkStyle =
        widget.expandStyle ??
        TextStyle(
          fontSize: 14,
          color: ColorsUtil.appThemeColor,
        );
    final expandText = widget.expandText ?? 'show_more'.tr;
    final collapseText = widget.collapseText ?? 'show_less'.tr;
    final maxLines = widget.maxLines;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final textScaler = MediaQuery.textScalerOf(context);

        // 创建链接文本 span
        final linkText = _isExpanded ? collapseText : expandText;
        final link = TextSpan(
          children: [
            if (!_isExpanded)
              TextSpan(
                text: '\u2026 ', // ...
                style: textStyle,
              ),
            if (_isExpanded) const TextSpan(text: ' '),
            TextSpan(
              text: linkText,
              style: linkStyle,
            ),
          ],
        );

        // 测量链接宽度
        final linkPainter = TextPainter(
          text: link,
          textAlign: widget.textAlign,
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: maxLines,
        );
        linkPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);
        final linkSize = linkPainter.size;

        // 创建内容文本 span
        final content = TextSpan(text: widget.text, style: textStyle);

        // 测量内容
        final textPainter = TextPainter(
          text: content,
          textAlign: widget.textAlign,
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: maxLines,
        );
        textPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);
        final textSize = textPainter.size;

        // 判断是否需要截断
        final needsTruncation = textPainter.didExceedMaxLines;
        TextSpan textSpan;

        if (needsTruncation) {
          if (_isExpanded) {
            // 展开状态：显示完整文字 + 收起
            textSpan = TextSpan(
              style: textStyle,
              children: [
                TextSpan(text: widget.text),
                link,
              ],
            );
          } else {
            // 折叠状态：计算截断位置
            final position = textPainter.getPositionForOffset(
              Offset(
                textSize.width - linkSize.width,
                textSize.height,
              ),
            );
            final endOffset = textPainter.getOffsetBefore(position.offset) ?? 0;
            final truncatedText = widget.text.substring(0, max(endOffset, 0));

            textSpan = TextSpan(
              style: textStyle,
              children: [
                TextSpan(text: truncatedText),
                link,
              ],
            );
          }
        } else {
          // 不需要截断：直接显示
          textSpan = content;
        }

        // 用 GestureDetector 包裹，点击整个区域都可以展开/折叠
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: needsTruncation || _isExpanded ? _toggleExpanded : null,
          child: RichText(
            text: textSpan,
            softWrap: true,
            textDirection: textDirection,
            textAlign: widget.textAlign,
            textScaler: textScaler,
            overflow: TextOverflow.clip,
          ),
        );
      },
    );
  }
}
