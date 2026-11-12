import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Widget/Button/ButtonBig.dart';

class ButtonBigWhite extends StatelessWidget {
  final String content;
  final VoidCallback onTap;
  final double fontSize;
  final double? width;
  final double? height;
  final bool isLoading;
  final Gradient? gradient;
  final EdgeInsets? padding;
  const ButtonBigWhite({
    super.key,
    required this.content,
    required this.onTap,
    this.fontSize = 17,
    this.width,
    this.height,
    this.gradient,
    this.padding,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonBig(
      backgroundColor: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF7E839D),
      content: content,
      onTap: onTap,
      fontSize: fontSize,
      width: width,
      height: height,
      borderRadius: const BorderRadius.all(Radius.circular(23)),
      gradient: gradient,
      padding: padding,
      isLoading: isLoading,
    );
  }
}
