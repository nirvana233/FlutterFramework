import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Extension/ColorUtil.dart';
import 'package:get/get.dart';

/// 可展开 inline 文本的一段内容。
///
/// 用于在同一段可展开文本里给局部内容设置不同样式，例如回复文案里的
/// `@Alice: ` 前缀，或正文末尾的 ` @Bob` 后缀。
class ExpandableTextSegment {
  /// 当前片段的纯文本内容。
  final String text;

  /// 当前片段的局部样式；未设置时继承 [ExpandableInlineText.textStyle]。
  final TextStyle? style;

  const ExpandableTextSegment(this.text, {this.style});
}

/// 支持多段 [TextStyle] 的可展开/折叠文本组件。
///
/// 适用于内容整体需要按 [maxLines] 折叠，但其中某几段需要不同样式的场景，
/// 例如评论回复中的 `@用户名: 正文`，或 `正文 @用户名`。
///
/// 普通纯文本仍优先使用 [ExpandableText]。本组件只处理纯文本片段，不支持
/// `WidgetSpan` 或嵌入图片，避免破坏基于字符串长度的截断计算。
///
/// 使用示例：
/// ```dart
/// ExpandableInlineText(
///   segments: [
///     ExpandableTextSegment('@Alice: ', style: mentionStyle),
///     ExpandableTextSegment(reply.content ?? ''),
///     ExpandableTextSegment(' @Bob', style: mentionStyle),
///   ],
///   maxLines: 5,
///   textStyle: bodyStyle,
/// )
/// ```
class ExpandableInlineText extends StatefulWidget {
  /// 按展示顺序拼接的文本片段。
  final List<ExpandableTextSegment> segments;

  /// 折叠时显示的最大行数。
  final int maxLines;

  /// 默认正文样式，未设置时继承 [DefaultTextStyle]。
  final TextStyle? textStyle;

  /// 展开/收起按钮样式；未设置时沿用正文样式并改为主题色。
  final TextStyle? expandStyle;

  /// 展开按钮文案，默认为 `show_more`.tr。
  final String? expandText;

  /// 收起按钮文案，默认为 `show_less`.tr。
  final String? collapseText;

  /// 文本对齐方式。
  final TextAlign textAlign;

  /// 初始是否展开。
  final bool initialExpanded;

  /// 展开状态变化回调。
  final ValueChanged<bool>? onExpandedChanged;

  const ExpandableInlineText({
    super.key,
    required this.segments,
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
  State<ExpandableInlineText> createState() => _ExpandableInlineTextState();
}

class _ExpandableInlineTextState extends State<ExpandableInlineText> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  void didUpdateWidget(covariant ExpandableInlineText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_plainTextOf(oldWidget.segments) != _plainTextOf(widget.segments)) {
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
    final textStyle = widget.textStyle ?? DefaultTextStyle.of(context).style;
    final linkStyle = textStyle.merge(
      widget.expandStyle ?? TextStyle(color: ColorsUtil.appThemeColor),
    );
    final expandText = widget.expandText ?? 'show_more'.tr;
    final collapseText = widget.collapseText ?? 'show_less'.tr;
    final maxLines = widget.maxLines;
    final plainText = _plainTextOf(widget.segments);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final textScaler = MediaQuery.textScalerOf(context);

        final linkText = _isExpanded ? collapseText : expandText;
        final link = TextSpan(
          children: [
            if (!_isExpanded)
              TextSpan(
                text: '\u2026 ',
                style: textStyle,
              ),
            if (_isExpanded) const TextSpan(text: ' '),
            TextSpan(
              text: linkText,
              style: linkStyle,
            ),
          ],
        );

        final linkPainter = TextPainter(
          text: link,
          textAlign: widget.textAlign,
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: maxLines,
        );
        linkPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);
        final linkSize = linkPainter.size;

        final content = _buildContentSpan(plainText.length, textStyle);
        final textPainter = TextPainter(
          text: content,
          textAlign: widget.textAlign,
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: maxLines,
        );
        textPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);
        final textSize = textPainter.size;

        final needsTruncation = textPainter.didExceedMaxLines;
        TextSpan textSpan;

        if (needsTruncation) {
          if (_isExpanded) {
            textSpan = TextSpan(
              style: textStyle,
              children: [
                content,
                link,
              ],
            );
          } else {
            final position = textPainter.getPositionForOffset(
              Offset(
                textSize.width - linkSize.width,
                textSize.height,
              ),
            );
            final endOffset = textPainter.getOffsetBefore(position.offset) ?? 0;

            textSpan = TextSpan(
              style: textStyle,
              children: [
                _buildContentSpan(max(endOffset, 0), textStyle),
                link,
              ],
            );
          }
        } else {
          textSpan = content;
        }

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

  TextSpan _buildContentSpan(int endOffset, TextStyle textStyle) {
    var remaining = endOffset;
    final children = <TextSpan>[];

    for (final segment in widget.segments) {
      if (remaining <= 0) break;
      final take = min(remaining, segment.text.length);
      if (take > 0) {
        children.add(
          TextSpan(
            text: segment.text.substring(0, take),
            style: segment.style,
          ),
        );
      }
      remaining -= take;
    }

    return TextSpan(style: textStyle, children: children);
  }

  static String _plainTextOf(List<ExpandableTextSegment> segments) {
    return segments.map((segment) => segment.text).join();
  }
}
