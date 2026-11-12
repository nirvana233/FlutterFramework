import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/BottomSheet/ConfirmBottomSheet.dart';
import 'package:flutter_framework/Common/Popup/PopupQueueMgr.dart';
import 'package:flutter_framework/Common/Popup/PopupType.dart';

import '../../../Util/Common/LogUtil.dart';

class BottomSheetMgr {
  static BottomSheetMgr? _instance;
  BottomSheetMgr._internal();
  static BottomSheetMgr get instance => _instance ??= BottomSheetMgr._internal();

  // 显示底部确认弹框
  void showConfirmBottomSheet({
    required BuildContext context,
    String? message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    String? confirmText,
    String? cancelText,
    Color? activeColor,
    Color? cancelColor,
    bool changeColor = false,
  }) {
    showPageBottomSheet(
      context,
      ConfirmBottomSheet(
        onOK: onConfirm,
        onCancel: onCancel,
        message: message ?? '',
        confirmText: confirmText,
        cancelText: cancelText,
        activeColor: activeColor,
        cancelColor: cancelColor,
        changeColor: changeColor,
      ),
    );
  }

  // 显示底部弹框
  Future<void> showPageBottomSheet(
    BuildContext context,
    Widget child, {
    Color backgroundColor = Colors.white,
    bool isDismissible = true,
    Color? barrierColor,
    bool isScrollControlled = true,
    bool enableDrag = true,
    bool? requestFocus,
    VoidCallback? onDismiss,
  }) async {
    try {
      // 显示模态底部框，flutter原生方法
      await showModalBottomSheet(
        context: context,
        backgroundColor: backgroundColor,
        isDismissible: isDismissible,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.5),
            topRight: Radius.circular(12.5),
          ),
        ),
        barrierColor: barrierColor is Color ? barrierColor : null,
        isScrollControlled: isScrollControlled,
        enableDrag: enableDrag,
        requestFocus: requestFocus,
        // 设置背景蒙层为透明
        builder: (BuildContext context) {
          return child;
        },
      ).then((value) {
        // 当模态底部表单关闭时，这里的代码会被调用
        onDismiss?.call();
      });
    } catch (e) {
      logW(e.toString());
    }
  }

  /// 通过队列显示底部弹窗
  ///
  /// 这个方法将底部弹窗添加到 PopupQueueMgr 的队列中，
  /// 确保底部弹窗也能按优先级排序，与其他弹窗协调显示
  void showPageBottomSheetWithQueue({
    required PopupType popupId,
    required BuildContext context,
    required Widget child,
    Color backgroundColor = Colors.white,
    bool isDismissible = true,
    Color? barrierColor,
    bool isScrollControlled = true,
    bool enableDrag = true,
    VoidCallback? onDismiss,
    VoidCallback? onComplete,
  }) {
    PopupQueueMgr.instance.addPopup(
      id: popupId,
      showPopup: () {
        final completer = Completer<void>();

        showPageBottomSheet(
              context,
              child,
              backgroundColor: backgroundColor,
              isDismissible: isDismissible,
              barrierColor: barrierColor,
              isScrollControlled: isScrollControlled,
              enableDrag: enableDrag,
              onDismiss: () {
                onDismiss?.call();
                if (!completer.isCompleted) {
                  completer.complete();
                }
              },
            )
            .then((_) {
              if (!completer.isCompleted) {
                completer.complete();
              }
            })
            .catchError((error) {
              if (!completer.isCompleted) {
                completer.complete();
              }
            });

        return completer.future;
      },
      onComplete: onComplete,
    );
  }

  /// 通过队列显示确认底部弹窗
  void showConfirmBottomSheetWithQueue({
    required PopupType popupId,
    required BuildContext context,
    String? message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    String? confirmText,
    String? cancelText,
    Color? activeColor,
    Color? cancelColor,
    bool changeColor = false,
    VoidCallback? onComplete,
  }) {
    showPageBottomSheetWithQueue(
      popupId: popupId,
      context: context,
      child: ConfirmBottomSheet(
        onOK: onConfirm,
        onCancel: onCancel,
        message: message ?? '',
        confirmText: confirmText,
        cancelText: cancelText,
        activeColor: activeColor,
        cancelColor: cancelColor,
        changeColor: changeColor,
      ),
      onComplete: onComplete,
    );
  }

  double getBottomSheetHeight(BuildContext context, int line, double itemHeight, int padding) {
    var mediaQuery = MediaQuery.of(context);
    var height = (line * itemHeight) + (line - 1) * padding;
    if (mediaQuery.size.height * 0.7 < height) {
      height = mediaQuery.size.height * 0.7;
    }

    return height;
  }
}
