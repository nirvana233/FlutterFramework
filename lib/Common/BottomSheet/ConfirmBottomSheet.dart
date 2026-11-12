import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 底部确认弹框
class ConfirmBottomSheet extends StatelessWidget {
  final VoidCallback? onOK;
  final VoidCallback? onCancel;
  final String message;
  String? confirmText;
  String? cancelText;
  final Color? activeColor;
  final Color? cancelColor;
  final bool changeColor;

  ConfirmBottomSheet({
    super.key,
    required this.message,
    this.onOK,
    this.onCancel,
    this.confirmText,
    this.cancelText,
    this.activeColor,
    this.cancelColor,
    this.changeColor = false,
  });

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var activeColor = this.activeColor ?? const Color(0XFF4D4F56);
    var cancelColor = this.cancelColor ?? const Color(0XFFE52E2E);
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min, // 控制高度
        children: [
          const SizedBox(
            height: 32,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0XFF7E839D),
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(
            height: 26,
          ),
          Divider(height: 1, color: const Color(0XFF444750).withValues(alpha: 0.06)),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Get.back();
                onOK?.call();
              },
              child: Text(
                confirmText ?? 'confirm'.tr,
                style: TextStyle(
                  color: changeColor ? activeColor : cancelColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: const Color(0XFF444750).withValues(alpha: 0.06)),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Get.back();
                onCancel?.call();
              },
              child: Text(
                cancelText ?? 'cancel'.tr,
                style: TextStyle(
                  color: changeColor ? cancelColor : activeColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: mediaQuery.padding.bottom + 20),
        ],
      ),
    );
  }
}
