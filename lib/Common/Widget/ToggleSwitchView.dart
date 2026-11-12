import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';

/// 通用开关组件
/// Figma Button/Channel 样式: 圆角 17px, padding 1.4px, 边框 0.7px
/// - 开启状态: colorSecondary 背景，滑块在右边
/// - 关闭状态: colorBgElementB90 背景，滑块在左边
class ToggleSwitchView extends StatelessWidget {
  /// 开关状态
  final bool value;

  /// 状态改变回调
  final ValueChanged<bool>? onChanged;

  /// 开关宽度，默认 40
  final double width;

  /// 开关高度，默认 22
  final double height;

  /// 滑块大小，默认 18
  final double thumbSize;

  /// 开启时的背景颜色，默认 colorSecondary
  final Color? activeColor;

  /// 关闭时的背景颜色，默认 colorBgElementB90
  final Color? inactiveColor;

  /// 边框颜色
  final Color? borderColor;

  /// 开关内边距
  final EdgeInsetsGeometry padding;

  /// 边框宽度
  final double borderWidth;

  /// 开关圆角
  final double borderRadius;

  /// 是否启用震动反馈，默认 true
  final bool enableVibration;

  /// 动画时长，默认 200ms
  final Duration animationDuration;

  const ToggleSwitchView({
    super.key,
    required this.value,
    this.onChanged,
    this.width = 40,
    this.height = 22,
    this.thumbSize = 18,
    this.activeColor,
    this.inactiveColor,
    this.borderColor,
    this.padding = const EdgeInsets.all(1.4),
    this.borderWidth = 0.7,
    this.borderRadius = 17,
    this.enableVibration = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onChanged != null) {
          if (enableVibration) {
            VibrationMgr.instance.selection();
          }
          onChanged!(!value);
        }
      },
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: value
              ? (activeColor ?? getAppFigmaColors.colorSecondary)
              : (inactiveColor ?? getAppFigmaColors.colorBgElementB90),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? getAppFigmaColors.colorBgElementB100,
            width: borderWidth,
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: animationDuration,
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: getAppFigmaColors.colorBgElementB100,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: FigmaVariables.colorBgShadowB030.withValues(alpha: 0.15),
                      blurRadius: 2.84,
                      offset: const Offset(0, 1.42),
                    ),
                    const BoxShadow(
                      color: Color(0x3B000000), // rgba(0,0,0,0.23)
                      blurRadius: 0.71,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 自管状态的开关（[ToggleSwitchView] 的非受控版）
///
/// 点击后自己刷新滑块 UI，外部只需在 [onChanged] 里处理副作用 / 落库，无需持有
/// 状态或 setState。适用于「外部不掌控显示值」的场景（如设置项开关）。
///
/// 若外部需要完全掌控显示值（可拒绝变化、异步确认后才生效、失败回弹），用受控的
/// [ToggleSwitchView]。本组件以 [initialValue] 作初值，外部改变 [initialValue]
/// 时会跟随同步，避免列表复用 Element 时残留旧值。
class AutoToggleSwitchView extends StatefulWidget {
  /// 初始开关状态
  final bool initialValue;

  /// 状态改变回调（仅通知，无需回传新值）
  final ValueChanged<bool>? onChanged;

  final double width;
  final double height;
  final double thumbSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double borderRadius;
  final bool enableVibration;
  final Duration animationDuration;

  const AutoToggleSwitchView({
    super.key,
    required this.initialValue,
    this.onChanged,
    this.width = 40,
    this.height = 22,
    this.thumbSize = 18,
    this.activeColor,
    this.inactiveColor,
    this.borderColor,
    this.padding = const EdgeInsets.all(1.4),
    this.borderWidth = 0.7,
    this.borderRadius = 17,
    this.enableVibration = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AutoToggleSwitchView> createState() => _AutoToggleSwitchViewState();
}

class _AutoToggleSwitchViewState extends State<AutoToggleSwitchView> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant AutoToggleSwitchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部初值变化时跟随，避免与外部数据源失同步
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  void _handleChanged(bool v) {
    setState(() => _value = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    return ToggleSwitchView(
      value: _value,
      onChanged: _handleChanged,
      width: widget.width,
      height: widget.height,
      thumbSize: widget.thumbSize,
      activeColor: widget.activeColor,
      inactiveColor: widget.inactiveColor,
      borderColor: widget.borderColor,
      padding: widget.padding,
      borderWidth: widget.borderWidth,
      borderRadius: widget.borderRadius,
      enableVibration: widget.enableVibration,
      animationDuration: widget.animationDuration,
    );
  }
}
