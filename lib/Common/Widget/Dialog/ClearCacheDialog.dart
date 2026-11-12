import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:get/get.dart';

/// Clear Cache 确认弹窗
class ClearCacheDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ClearCacheDialog({
    super.key,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          width: 311,
          decoration: BoxDecoration(
            color: getAppFigmaColors.colorBgElementB100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and Subtitle
              Container(
                width: 311,
                padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: getAppFigmaColors.colorBgElementB80,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'clear_cache'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: getAppFigmaColors.colorTextPrimaryB0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      // This will free up space on your device. Your library and reading history will not be affected.
                      'free_up_space'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: getAppFigmaColors.colorTextRegularB50,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Buttons
              Container(
                width: 311,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildButton(
                      // Clear
                      text: 'clear_cache_btn'.tr,
                      textColor: getAppFigmaColors.colorTextPrimaryB0,
                      onTap: () {
                        VibrationMgr.instance.selection();
                        Get.back();
                        onConfirm();
                      },
                      showBorder: true,
                    ),
                    _buildButton(
                      // Cancel
                      text: 'cancel'.tr,
                      textColor: getAppFigmaColors.colorTextRegularB50,
                      onTap: () {
                        VibrationMgr.instance.selection();
                        Get.back();
                        onCancel?.call();
                      },
                      showBorder: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color textColor,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: getAppFigmaColors.colorBgElementB80,
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// 显示 Clear Cache 弹窗
void showClearCacheDialog({
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  Get.dialog(
    ClearCacheDialog(
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
    barrierDismissible: false,
  );
}
