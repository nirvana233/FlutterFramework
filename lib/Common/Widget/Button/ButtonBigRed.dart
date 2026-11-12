import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Widget/Button/ButtonBig.dart';
import 'package:flutter_framework/Util/Extension/ColorUtil.dart';

class ButtonBigRed extends StatelessWidget {
  final String content;
  final VoidCallback onTap;
  final double fontSize;
  final double? width;
  final double? height;
  final bool isLoading;
  final EdgeInsets? padding;
  final Gradient? gradient;

  const ButtonBigRed({
    super.key,
    required this.content,
    required this.onTap,
    this.fontSize = 17,
    this.width,
    this.height,
    this.isLoading = false,
    this.padding,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonBig(
      backgroundColor: ColorsUtil.appThemeColor,
      textColor: const Color(0xFFFFFFFF),
      content: content,
      onTap: onTap,
      fontSize: fontSize,
      width: width,
      height: height,
      borderRadius: const BorderRadius.all(
        Radius.circular(23),
      ),
      padding: padding,
      isLoading: isLoading,
      gradient: gradient,
    );
  }
}
