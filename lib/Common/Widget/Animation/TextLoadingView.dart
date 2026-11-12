import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TextLoadingView extends StatefulWidget {
  final Duration duration;
  final Color? color;
  final double? fontSize;
  final double? width;
  final double? height;
  final Offset? offset;
  const TextLoadingView({
    super.key,
    this.color,
    this.fontSize,
    this.width,
    this.height,
    this.offset,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<TextLoadingView> createState() => _TextLoadingViewState();
}

class _TextLoadingViewState extends State<TextLoadingView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final RxInt _dotCount = 0.obs;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: widget.duration,
        )..addListener(() {
          if (_controller.status == AnimationStatus.completed) {
            _controller.repeat();
          }
          // 0, 1, 2, 3
          int dots = (_controller.value * 4).floor() % 4;
          _dotCount.value = dots;
        });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      String dots = '.' * _dotCount.value;
      return SizedBox(
        width: widget.width ?? 12,
        height: widget.height ?? 30,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: widget.offset ?? const Offset(0, -3),
            child: Text(
              dots,
              style: TextStyle(fontSize: widget.fontSize ?? 12, color: widget.color ?? Colors.grey),
            ),
          ),
        ),
      );
    });
  }
}
