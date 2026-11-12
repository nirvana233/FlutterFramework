import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Widget/Animation/LottieAnimationView.dart';

class WaitingMgr {
  static WaitingMgr? _instance;
  WaitingMgr._internal();
  static WaitingMgr get instance => _instance ??= WaitingMgr._internal();

  OverlayEntry? _overlayEntry;

  /// 显示Loading
  /// [context] 上下文
  void show(BuildContext? context, {Color? color}) {
    if (context == null) {
      return;
    }
    // 防止重复创建
    if (_overlayEntry != null) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: color ?? Colors.transparent,
          child: const LottieAnimationView(),
        );
      },
    );

    // 插入到Overlay中
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 关闭Loading
  void hide() {
    // 确保在移除前entry存在
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }
}
