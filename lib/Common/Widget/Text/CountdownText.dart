import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:get/get.dart';

class CountdownText extends StatefulWidget {
  final int countdownSeconds;
  final Function(String, bool)? callback;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final bool? isBlock;

  const CountdownText({
    super.key,
    required this.countdownSeconds,
    this.callback,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.isBlock,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  RxString countdownText = ''.obs;
  int countdownSeconds = 0;

  void startCountdown(int? seconds) {
    _timer?.cancel();
    if (seconds != null) {
      countdownSeconds = seconds;
    }

    if (countdownSeconds <= 0) {
      widget.callback?.call('', true);
      return;
    }
    _timer = timerStartDateTime(
      1,
      countdownSeconds,
      (dataStr, isEnd) {
        widget.callback?.call(dataStr, isEnd);
        countdownText.value = dataStr;
        if (isEnd) {
          _timer?.cancel();
        }
      },
      refreshRightNow: true,
      isShowDay: true,
    );
  }

  /// 重置倒计时，使用当前widget的countdownSeconds或指定的seconds
  void resetCountdown([int? newSeconds]) {
    final seconds = newSeconds ?? widget.countdownSeconds;
    countdownSeconds = seconds + 1;
    startCountdown(null);
  }

  @override
  void initState() {
    super.initState();
    resetCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!(widget.isBlock ?? false)) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            countdownText.value,
            style: TextStyle(
              fontSize: widget.fontSize ?? 9,
              color: widget.color ?? const Color.fromARGB(255, 255, 255, 255),
              fontWeight: widget.fontWeight ?? FontWeight.w500,
            ),
            textAlign: widget.textAlign ?? TextAlign.left,
          ),
        );
      } else {
        // 解析倒计时文本获取小时、分钟和秒数
        final parts = countdownText.value.split(':');
        final hours = parts.isNotEmpty ? parts[0] : '00';
        final minutes = parts.length > 1 ? parts[1] : '00';
        final seconds = parts.length > 2 ? parts[2] : '00';
        // 返回三个红色方块，每个方块内部分别显示小时、分钟和秒，中间用冒号分割
        if (parts.length > 1) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center, // 水平居中对齐
            children: [
              _buildTimeBlock(hours),
              const Text(':', style: TextStyle(color: Color(0xFFF9533F), fontSize: 16)),
              _buildTimeBlock(minutes),
              const Text(':', style: TextStyle(color: Color(0xFFF9533F), fontSize: 16)),
              _buildTimeBlock(seconds),
            ],
          );
        } else {
          // 返回天数
          return _buildTimeBlock(hours, true);
        }
      }
    });
  }

  // 创建时间块的方法
  Widget _buildTimeBlock(String time, [bool isDay = false]) {
    return Container(
      width: isDay ? 40 : 16,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFF9533F), // 红色背景
        borderRadius: BorderRadius.circular(4), // 可选，根据需要调整圆角
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 1.0,
      ), // 根据需要调整内边距
      margin: const EdgeInsets.symmetric(horizontal: 2.0), // 可选，根据需要调整方块之间的间距
      child: Center(
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 10, // 根据需要调整字体大小
            color: Colors.white, // 白色文字
          ),
        ),
      ),
    );
  }
}
