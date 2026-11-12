import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_framework/Util/SheetAndAlter/Toast.dart';
import 'package:get/get.dart';

/// 双击退出提示 Widget
/// 封装了双击返回键退出应用的逻辑
///
/// 使用示例：
/// ```dart
/// // 基本使用
/// ExitTips(
///   child: Scaffold(...),
/// )
///
/// // 自定义提示文本和时间间隔
/// ExitTips(
///   exitTipText: "再按一次退出",
///   exitIntervalSeconds: 3,
///   child: Scaffold(...),
/// )
///
/// // 使用自定义退出处理
/// ExitTips(
///   onExit: () {
///     // 自定义退出逻辑，比如保存数据
///     print("准备退出应用");
///     SystemNavigator.pop();
///   },
///   child: Scaffold(...),
/// )
///
/// // 禁用退出功能
/// ExitTips(
///   enabled: false,
///   child: Scaffold(...),
/// )
/// ```
class ExitTips extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 退出提示文本，默认为"再次按返回键退出应用"
  final String? exitTipText;

  /// 退出间隔时间（秒），默认为2秒
  final int exitIntervalSeconds;

  /// 自定义退出处理函数，如果提供则使用此函数而不是默认的 SystemNavigator.pop()
  final VoidCallback? onExit;

  /// 是否启用退出功能，默认为 true
  final bool enabled;

  const ExitTips({
    super.key,
    required this.child,
    this.exitTipText,
    this.exitIntervalSeconds = 2,
    this.onExit,
    this.enabled = true,
  });

  @override
  State<ExitTips> createState() => _ExitTipsState();
}

class _ExitTipsState extends State<ExitTips> {
  /// 上次按返回键的时间
  DateTime? _lastPressedAt;

  /// 处理返回按钮点击
  bool _onWillPop() {
    if (!widget.enabled) {
      return true; // 如果未启用，直接允许退出
    }

    if (_lastPressedAt == null ||
        DateTime.now().difference(_lastPressedAt!) >
            Duration(seconds: widget.exitIntervalSeconds)) {
      // 第一次按返回键或距离上次按返回键超过指定时间
      _lastPressedAt = DateTime.now();
      showToast(widget.exitTipText ?? 'general_message_6'.tr);
      return false; // 不退出应用
    }

    // 在指定时间内再次按返回键，执行退出操作
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      SystemNavigator.pop();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onWillPop();
        }
      },
      canPop: false,
      child: widget.child,
    );
  }
}
