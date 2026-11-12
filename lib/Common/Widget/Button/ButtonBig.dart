import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Widget/Animation/LoadingView.dart';
import 'package:flutter_framework/Util/Extension/ColorUtil.dart';

class ButtonBig extends StatelessWidget {
  final String? content;
  final VoidCallback? onTap;
  final double fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final EdgeInsets? padding;
  final bool isLoading;
  final Widget? widget;
  const ButtonBig({
    super.key,
    this.content,
    this.onTap,
    this.fontSize = 17,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.gradient,
    this.padding,
    this.isLoading = false,
    this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: height ?? 46,
        width: width ?? double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor ?? ColorsUtil.appThemeColor,
            borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(23)),
            gradient: gradient,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 2),
              child: isLoading
                  ? LoadingView(
                      color: textColor,
                    )
                  : widget ??
                        Text(
                          content ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: textColor ?? const Color(0xFFFFFFFF),
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
