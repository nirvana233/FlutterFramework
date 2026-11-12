import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
import 'package:get/get_utils/src/platform/platform.dart';

/// 智能 SafeArea，自动修复 Android 10 刘海识别失效问题
/// 接口与原生 SafeArea 完全一致，可直接替换
class SmartSafeArea extends StatelessWidget {
  const SmartSafeArea({
    super.key,
    required this.child,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
  });

  final Widget child;
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;
  final EdgeInsets minimum;
  final bool maintainBottomViewPadding;

  @override
  Widget build(BuildContext context) {
    return _Android10CutoutFix(
      enabled: top, // 仅在需要 top 安全区时修复
      child: SafeArea(
        key: key,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        minimum: minimum,
        maintainBottomViewPadding: maintainBottomViewPadding,
        child: child,
      ),
    );
  }
}

/// 内部修复组件：仅在 Android 10 + 刘海屏 + insets.top 为 0 时注入修正值
class _Android10CutoutFix extends StatelessWidget {
  const _Android10CutoutFix({
    required this.child,
    required this.enabled,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final mediaQuery = MediaQuery.of(context);
    final isAndroid = GetPlatform.isAndroid;

    // 仅在 Android 上处理
    if (!isAndroid) return child;

    // 使用新函数获取修正后的顶部高度
    final fixedTop = smartTopSafeHeight;
    //getFixedTopPadding(context);
    final originalTop = mediaQuery.padding.top;

    // 如果修正后的值与原值不同,说明需要修复
    if (fixedTop != originalTop) {
      final EdgeInsets fixedPadding = mediaQuery.padding.copyWith(top: fixedTop);
      return MediaQuery(
        data: mediaQuery.copyWith(padding: fixedPadding),
        child: child,
      );
    }

    // 不需要修复,直接返回
    return child;
  }
}
