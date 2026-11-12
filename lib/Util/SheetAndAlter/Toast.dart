import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:get/get.dart';

void showToastBlack(
  String msg, {
  int duration = 3,
  Color? textColor,
  TextAlign textAlign = TextAlign.center,
}) {
  _showCustomText(
    msg,
    duration: duration,
    textColor: textColor,
    textAlign: textAlign,
  );
}

// 自定义宽度的Toast
void _showCustomText(
  String msg, {
  int duration = 3,
  Color? textColor,
  double? width,
  AlignmentGeometry? position,
  EdgeInsetsGeometry? contentPadding,
  EdgeInsetsGeometry? margin,
  BorderRadiusGeometry? borderRadius,
  Color? backgroundColor,
  TextStyle? textStyle,
  bool onlyOne = true,
  TextAlign textAlign = TextAlign.center,
  VibrationType? vibrationType,
}) {
  try {
    BotToast.showCustomText(
      toastBuilder: (textCancel) => Container(
        margin: margin ?? _getDefaultMargin(position),
        child: Container(
          width: width ?? MediaQuery.of(Get.context!).size.width * 0.8,
          padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0x8A000000),
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          child: Text(
            msg,
            style: textStyle ?? TextStyle(color: textColor ?? Colors.white, fontSize: 17.0),
            textAlign: textAlign,
          ),
        ),
      ),
      duration: Duration(seconds: duration),
      align: position ?? Alignment.bottomCenter,
      onlyOne: onlyOne,
    );
    if (vibrationType != null) {
      VibrationMgr.instance.vibrate(vibrationType);
    }
  } catch (e) {
    logE(e.toString());
  }
}

// 根据位置获取默认边距
EdgeInsetsGeometry _getDefaultMargin(AlignmentGeometry? position) {
  if (position == null || position == Alignment.bottomCenter) {
    return const EdgeInsets.only(bottom: 40, left: 16, right: 16);
  } else if (position == Alignment.topCenter) {
    return const EdgeInsets.only(top: 40, left: 16, right: 16);
  } else if (position == Alignment.center) {
    return const EdgeInsets.symmetric(horizontal: 16);
  } else {
    return const EdgeInsets.all(16);
  }
}

showSnackBar(String msg, {int duration = 3, Color? textColor, VibrationType? vibrationType}) {
  Get.showSnackbar(
    GetSnackBar(
      messageText: Align(
        alignment: Alignment.center,
        child: Text(
          msg,
          style: TextStyle(color: textColor ?? Colors.white, fontSize: 17.0),
          textAlign: TextAlign.center,
        ),
      ),
      borderRadius: 12.0,
      barBlur: 7.0,
      backgroundColor: const Color(0xFF000000).withValues(alpha: 0.5),
      duration: Duration(seconds: duration),
      margin: EdgeInsets.only(bottom: DeviceUtil.instance.bottomSafeHeight + 80),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      maxWidth: Get.width * 0.8,
      snackStyle: SnackStyle.FLOATING,
      snackPosition: SnackPosition.BOTTOM,
      isDismissible: true,
      overlayBlur: 0,
      dismissDirection: DismissDirection.horizontal,
    ),
  );
  if (vibrationType != null) {
    VibrationMgr.instance.vibrate(vibrationType);
  }
}

/// Toast 出入场动画：入场自上落下，退场向下沉。
///
/// 必须顶掉 bot_toast 默认的 textAnimation —— 它会用 [Opacity] 包整个 Toast 做渐显渐隐，
/// 而 [Opacity] 为了整体降 alpha 必须先 saveLayer，被圈进离屏层的 [BackdropFilter] 就
/// 采样不到真实背景，毛玻璃整段失效、直到动画结束（alpha 恰好为 1、不再开层）才突然出现。
/// 注意与底色自带的 alpha 无关：那只是一次带 alpha 的填色，不开层，不影响 blur。
/// 因此这里只做位移、全程不碰透明度。
///
/// `dismissed` 与 `reverse` 同属退场：bot_toast 在祖先的 initState 里就调了 `forward()`，
/// 首帧不可能是 `dismissed`，故 `dismissed` 只代表反放已结束（停在退场终点，不会闪回入场起点）。
Widget _wrapToastAnimation(
  AnimationController controller,
  CancelFunc cancelFunc,
  Widget child,
) {
  return AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final bool isExiting =
          controller.status == AnimationStatus.reverse ||
          controller.status == AnimationStatus.dismissed;
      final double eased = Curves.easeOutCubic.transform(controller.value);
      return Transform.translate(
        // 入场 -20 → 0（自上落下），退场 0 → +16（向下沉）
        offset: Offset(
          0,
          isExiting
              ? (1 - eased) * FigmaVariables.spacing16
              : (eased - 1) * FigmaVariables.spacing20,
        ),
        child: child,
      );
    },
  );
}

/// 展示全局短提示，默认在当前页面中央显示，连续触发时只保留最新一条。
void showToast(
  String msg, {
  int duration = 3,
  Color? textColor,
  Color? backgroundColor,
  AlignmentGeometry align = Alignment.center,
  TextAlign textAlign = TextAlign.center,
  VibrationType? vibrationType,
}) {
  try {
    logP("showToast: $msg");
    BotToast.showCustomText(
      // ===== 居中提示内容 =====
      toastBuilder: (textCancel) => Padding(
        padding: FigmaVariables.paddingH16,
        child: ConstrainedBox(
          // 不限最大宽度：外层 paddingH16 已把可用宽度收为「屏幕宽 - 两侧 16」，
          // 交给布局约束传递，平板与旋转/分屏时自动跟随
          constraints: const BoxConstraints(minHeight: FigmaVariables.spacing48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: FigmaVariables.borderRadius12,
              boxShadow: [
                BoxShadow(
                  color: FigmaVariables.colorBgShadowB030.withValues(alpha: 0.1),
                  blurRadius: FigmaVariables.blur10,
                  offset: const Offset(0, FigmaVariables.spacing2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: FigmaVariables.borderRadius12,
              // 毛玻璃：底色自带 alpha 透出模糊后的背景，动画只做位移不叠 Opacity，
              // 否则 saveLayer 会让这里采样不到真实背景（详见 _wrapToastAnimation）
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: FigmaVariables.blur4,
                  sigmaY: FigmaVariables.blur4,
                ),
                child: ColoredBox(
                  color: backgroundColor ?? getAppFigmaColors.colorBgToastB10050,
                  child: Padding(
                    padding: FigmaVariables.paddingH20 + FigmaVariables.paddingV12,
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(
                        msg,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: textAlign,
                        textWidthBasis: TextWidthBasis.longestLine,
                        style: TextStyle(
                          color: textColor ?? getAppFigmaColors.colorBgElementB100,
                          fontSize: FigmaVariables.fontSize16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      wrapToastAnimation: _wrapToastAnimation,
      duration: Duration(seconds: duration),
      align: align,
      onlyOne: true, // 确保只显示一个
      clickClose: true, // 点击toast关闭
      ignoreContentClick: true, // 忽略toast内容的点击，让点击事件穿透
      animationDuration: const Duration(milliseconds: 300), // 入场动画时长
      animationReverseDuration: const Duration(milliseconds: 200), // 退场渐隐动画时长
    );
    if (vibrationType != null) {
      VibrationMgr.instance.vibrate(vibrationType);
    }
  } catch (e) {
    logE(e.toString());
  }
}

void showToastNormalError(Object? msg, {bool withVibration = true, String? code}) {
  String s = msg != null ? ': ${msg.toString()}' : '';
  if (isAvailable(code)) {
    s = '  $s[$code]';
  }
  showToast("${'error_message_9'.tr}$s");
  if (withVibration) {
    VibrationMgr.instance.error();
  }
}
