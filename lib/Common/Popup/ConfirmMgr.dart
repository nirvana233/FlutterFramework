import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Common/Widget/Animation/LoadingView.dart';
import 'package:get/get.dart';

class ConfirmMgr {
  static ConfirmMgr? _instance;
  ConfirmMgr._internal();
  static ConfirmMgr get instance => _instance ??= ConfirmMgr._internal();

  /// 显示新版确认弹窗（基于 Figma 设计）
  ///
  /// [title] 标题文字
  /// [message] 内容描述
  /// [content] 自定义内容 Widget，显示在标题/内容区域下方、按钮上方
  /// [bottomWidget] 自定义底部 Widget，显示在按钮下方（如 Contact Support）；不传则不占位
  /// [onConfirm] 确认回调
  /// [onCancel] 取消回调
  /// [confirmText] 确认按钮文字，默认使用 'confirm'.tr
  /// [cancelText] 取消按钮文字，默认使用 'cancel'.tr
  /// [confirmWidget] 自定义确认按钮内容 Widget（如 Icon + 文字），传入时优先于 [confirmText]
  /// [cancelWidget] 自定义取消按钮内容 Widget，传入时优先于 [cancelText]
  /// [isOnlyConfirm] 是否只显示确认按钮
  /// [barrierDismissible] 点击遮罩是否关闭
  /// [isDestructive] 确认按钮是否为危险操作（红色）
  /// [confirmResult] 点击确认时通过 Get.back 返回的结果
  /// [cancelResult] 点击取消时通过 Get.back 返回的结果
  /// [onConfirmAsync] 可选：确认按钮转圈，返回 true 才关窗；未传时行为与原先一致
  Future<T?> showConfirmNew<T>({
    String? title,
    String? message,
    Widget? content,
    Widget? bottomWidget,
    Function? onConfirm,
    Function? onCancel,
    Future<bool> Function()? onConfirmAsync,
    String? confirmText,
    String? cancelText,
    Widget? confirmWidget,
    Widget? cancelWidget,
    bool isOnlyConfirm = false,
    bool barrierDismissible = true,
    bool isDestructive = true,
    FigmaThemeColors? themeColors,
    T? confirmResult,
    T? cancelResult,
  }) {
    final colors = themeColors ?? getAppFigmaColors;
    final footer = bottomWidget;
    var isConfirmLoading = false;

    return Get.dialog<T>(
      barrierDismissible: onConfirmAsync == null ? barrierDismissible : false,
      barrierColor: FigmaVariables.colorBgMaskB070,
      StatefulBuilder(
        builder: (context, setState) {
          Future<void> handleConfirm() async {
            if (isConfirmLoading) return;
            if (onConfirmAsync != null) {
              setState(() => isConfirmLoading = true);
              var shouldClose = false;
              try {
                shouldClose = await onConfirmAsync();
                if (shouldClose && (Get.isDialogOpen ?? false)) {
                  if (confirmResult != null) {
                    Get.back(result: confirmResult);
                  } else {
                    Get.back();
                  }
                  onConfirm?.call();
                }
              } finally {
                if (!shouldClose && (Get.isDialogOpen ?? false)) {
                  setState(() => isConfirmLoading = false);
                }
              }
              return;
            }
            if (confirmResult != null) {
              Get.back(result: confirmResult);
            } else {
              Get.back();
            }
            onConfirm?.call();
          }

          void handleCancel() {
            if (isConfirmLoading) return;
            if (cancelResult != null) {
              Get.back(result: cancelResult);
            } else {
              Get.back();
            }
            onCancel?.call();
          }

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 311,
                decoration: BoxDecoration(
                  color: colors.colorBgElementB100,
                  borderRadius: FigmaVariables.borderRadius12,
                ),
                padding: const EdgeInsets.all(FigmaVariables.spacing28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        if (title != null)
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: FigmaVariables.fontPrimary,
                              fontSize: FigmaVariables.fontSize20,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              color: colors.colorTextPrimaryB0,
                            ),
                          ),
                        if (message != null) ...[
                          SizedBox(height: title != null ? FigmaVariables.spacing12 : 0),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: FigmaVariables.fontPrimary,
                              fontSize: FigmaVariables.fontSize16,
                              fontWeight: FontWeight.w400,
                              height: 1,
                              color: colors.colorTextRegularB50,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (content != null) ...[
                      const SizedBox(height: FigmaVariables.spacing28),
                      content,
                    ],
                    const SizedBox(height: FigmaVariables.spacing28),
                    Column(
                      children: [
                        _buildButton(
                          text: confirmText ?? 'confirm'.tr,
                          child: confirmWidget,
                          onTap: handleConfirm,
                          isPrimary: true,
                          isDestructive: isDestructive,
                          colors: colors,
                          isLoading: isConfirmLoading,
                        ),
                        if (!isOnlyConfirm) ...[
                          const SizedBox(height: FigmaVariables.spacing12),
                          _buildButton(
                            text: cancelText ?? 'cancel'.tr,
                            child: cancelWidget,
                            onTap: handleCancel,
                            isPrimary: false,
                            isDestructive: false,
                            colors: colors,
                            enabled: !isConfirmLoading,
                          ),
                        ],
                        if (footer != null) ...[
                          const SizedBox(height: FigmaVariables.spacing12),
                          footer,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建按钮
  Widget _buildButton({
    String? text,
    Widget? child,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isDestructive,
    required FigmaThemeColors colors,
    bool isLoading = false,
    bool enabled = true,
  }) {
    final canTap = enabled && !isLoading;
    // 主按钮（确认）
    if (isPrimary) {
      return GestureDetector(
        onTap: canTap ? onTap : null,
        child: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive ? colors.colorPrimaryDefault : colors.colorPrimaryDefault,
            borderRadius: FigmaVariables.borderRadius24,
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const LoadingView(
                  width: FigmaVariables.spacing16,
                  height: FigmaVariables.spacing16,
                  strokeWidth: FigmaVariables.spacing2,
                  color: FigmaVariables.colorTextPrimaryB100,
                )
              : (child ??
                    Text(
                      text ?? '',
                      style: const TextStyle(
                        fontFamily: FigmaVariables.fontPrimary,
                        fontSize: FigmaVariables.fontSize16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: FigmaVariables.colorTextPrimaryB100,
                      ),
                    )),
        ),
      );
    }

    // 次按钮（取消）
    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          color: colors.colorBgElementB100,
          borderRadius: FigmaVariables.borderRadius24,
          border: Border.all(
            color: colors.colorBgElementB70,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child:
            child ??
            Text(
              text ?? '',
              style: TextStyle(
                fontFamily: FigmaVariables.fontPrimary,
                fontSize: FigmaVariables.fontSize16,
                fontWeight: FontWeight.w700,
                height: 1,
                color: colors.colorTextSecondaryB30,
              ),
            ),
      ),
    );
  }

  /// 只显示确认按钮的弹窗
  Future<T?> showOKConfirmNew<T>({
    String? title,
    String? message,
    Function? onConfirm,
    String? confirmText,
    Widget? confirmWidget,
    bool barrierDismissible = true,
    bool isDestructive = false,
  }) {
    return showConfirmNew<T>(
      title: title,
      message: message,
      onConfirm: onConfirm,
      confirmText: confirmText,
      confirmWidget: confirmWidget,
      isOnlyConfirm: true,
      barrierDismissible: barrierDismissible,
      isDestructive: isDestructive,
    );
  }

  /// 显示纵向按钮确认弹窗
  ///
  /// UI 风格与 DeleteAccountDialog 保持一致：
  /// 标题/内容区域与按钮区域分块，按钮纵向排列并使用分割线
  Future<T?> showConfirmVerticalNew<T>({
    String? title,
    String? message,
    Function? onConfirm,
    Function? onCancel,
    String? confirmText,
    String? cancelText,
    Widget? confirmWidget,
    Widget? cancelWidget,
    bool isOnlyConfirm = false,
    bool barrierDismissible = true,
    bool isDestructive = true,
  }) {
    final colors = getAppFigmaColors;

    return Get.dialog<T>(
      barrierDismissible: barrierDismissible,
      barrierColor: FigmaVariables.colorBgMaskB070,
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 311,
            decoration: BoxDecoration(
              color: colors.colorBgElementB100,
              borderRadius: FigmaVariables.borderRadius12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    left: FigmaVariables.spacing20,
                    right: FigmaVariables.spacing20,
                    top: FigmaVariables.spacing28,
                    bottom: FigmaVariables.spacing20,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colors.colorBgElementB80,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (title != null)
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: FigmaVariables.fontPrimary,
                            fontSize: FigmaVariables.fontSize20,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: colors.colorTextPrimaryB0,
                          ),
                        ),
                      if (message != null) ...[
                        SizedBox(height: title != null ? FigmaVariables.spacing12 : 0),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: FigmaVariables.fontPrimary,
                            fontSize: FigmaVariables.fontSize16,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                            color: colors.colorTextRegularB50,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: FigmaVariables.spacing20),
                  child: Column(
                    children: [
                      _buildVerticalButton(
                        text: confirmText ?? 'confirm'.tr,
                        child: confirmWidget,
                        textColor: isDestructive
                            ? colors.colorTextSecondaryRed
                            : colors.colorPrimaryDefault,
                        showBorder: !isOnlyConfirm,
                        onTap: () {
                          VibrationMgr.instance.selection();
                          Get.back();
                          onConfirm?.call();
                        },
                      ),
                      if (!isOnlyConfirm)
                        _buildVerticalButton(
                          text: cancelText ?? 'cancel'.tr,
                          child: cancelWidget,
                          textColor: colors.colorTextRegularB50,
                          showBorder: false,
                          onTap: () {
                            VibrationMgr.instance.selection();
                            Get.back();
                            onCancel?.call();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 只显示确认按钮的纵向按钮弹窗
  Future<T?> showOKConfirmVerticalNew<T>({
    String? title,
    String? message,
    Function? onConfirm,
    String? confirmText,
    Widget? confirmWidget,
    bool barrierDismissible = true,
    bool isDestructive = false,
  }) {
    return showConfirmVerticalNew<T>(
      title: title,
      message: message,
      onConfirm: onConfirm,
      confirmText: confirmText,
      confirmWidget: confirmWidget,
      isOnlyConfirm: true,
      barrierDismissible: barrierDismissible,
      isDestructive: isDestructive,
    );
  }

  Widget _buildVerticalButton({
    String? text,
    Widget? child,
    required Color textColor,
    required VoidCallback onTap,
    required bool showBorder,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    final colors = getAppFigmaColors;

    return GestureDetector(
      onTap: isDisabled || isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: colors.colorBgElementB80,
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Center(
          child: isLoading
              ? LoadingView(
                  width: 16,
                  height: 16,
                  color: textColor,
                )
              : (child ??
                    Text(
                      text ?? '',
                      style: TextStyle(
                        fontFamily: FigmaVariables.fontPrimary,
                        fontSize: FigmaVariables.fontSize16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: textColor,
                      ),
                    )),
        ),
      ),
    );
  }
}
