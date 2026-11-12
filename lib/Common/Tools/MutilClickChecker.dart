import 'package:flutter/material.dart';

/// 多次点击检测器Widget
/// 用于检测在指定时间间隔内的连续点击次数，达到要求次数后触发回调
class MutilClickChecker extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 需要的点击次数，默认5次
  final int requiredTaps;

  /// 最大点击间隔（毫秒），默认1秒
  final int maxInterval;

  /// 达到要求点击次数后的回调
  final VoidCallback onMultiTap;

  /// 点击行为，默认为不透明
  final HitTestBehavior behavior;

  const MutilClickChecker({
    super.key,
    required this.child,
    required this.onMultiTap,
    this.requiredTaps = 5,
    this.maxInterval = 1000,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<MutilClickChecker> createState() => _MutilClickCheckerState();
}

class _MutilClickCheckerState extends State<MutilClickChecker> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _onTap() {
    final now = DateTime.now();

    // 检查是否在时间间隔内
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds > widget.maxInterval) {
      _tapCount = 0; // 重置计数
    }

    _tapCount++;
    _lastTapTime = now;

    if (_tapCount >= widget.requiredTaps) {
      _tapCount = 0; // 重置计数
      widget.onMultiTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: _onTap,
      child: widget.child,
    );
  }
}
