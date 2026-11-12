import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
import 'package:get/get.dart';

void showAlter(
  Widget content, {
  required bool needScale,
  Color backgroundColor = const Color.fromARGB(255, 255, 255, 255),
  bool useSafeArea = true,
  bool barrierDismissible = false,
  double borderRadius = 12.0,
  double scale = 1.5,
  Clip clipBehavior = Clip.antiAlias,
  Color barrierColor = const Color.fromARGB(200, 0, 0, 0),
  VoidCallback? onDismiss,
}) {
  Get.dialog(
    Transform.scale(
      scale: needScale ? (isWideDevice ? scale : 1.0) : 1.0,
      child: Dialog(
        backgroundColor: backgroundColor,
        insetPadding: EdgeInsets.zero, // 去除对话框与屏幕边缘的间距// 保证内容不会溢出屏幕边缘
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          clipBehavior: clipBehavior,
          borderRadius: BorderRadius.circular(borderRadius), // 应用与 Dialog 相同的圆角半径
          child: content,
        ), // 保证内容不会溢出屏幕边缘
      ),
    ),
    useSafeArea: useSafeArea, // 保证内容不会溢出屏幕边缘
    barrierDismissible: barrierDismissible, // 点击蒙层关闭对话框
    barrierColor: barrierColor, // 自定义遮罩层颜色和透明度
  ).then((value) {
    onDismiss?.call();
  });
}
