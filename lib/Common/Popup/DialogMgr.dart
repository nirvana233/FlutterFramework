import 'dart:async';

import 'package:flutter_framework/Common/Debug/TestMgr.dart';
import 'package:flutter_framework/Common/Dialog/LogPasswordDialog.dart';
import 'package:flutter_framework/Common/Dialog/Permission/PermissionDialog.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Common/Popup/PopupQueueMgr.dart';
import 'package:flutter_framework/Common/Popup/PopupType.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/StringUtil.dart';
import 'package:flutter_framework/Util/PermissionManager/PermissionManager.dart';
import 'package:flutter_framework/Util/SheetAndAlter/Alter.dart';
import 'package:flutter_framework/Util/SheetAndAlter/Toast.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// 全局居中弹窗管理：需要排队的弹窗统一通过 [PopupQueueMgr] 入队，避免叠弹
class DialogMgr {
  static DialogMgr? _instance;
  DialogMgr._internal();
  static DialogMgr get instance => _instance ??= DialogMgr._internal();
  // 正式包查看日志的密码（新项目请修改）
  static const String _correctPassword = 'Admin@123';

  void showTalkerPasswordDialog() {
    VibrationMgr.instance.success();
    showAlter(
      LogPasswordDialog(
        onConfirm: (password) {
          if (password == _correctPassword) {
            Get.back();
            _showTalkerScreen();
            TestMgr.instance.showTest(Get.context!);
          } else {
            showToast('Password error!');
          }
        },
      ),
      needScale: false,
    );
  }

  void _showTalkerScreen() {
    if (talker != null) {
      Get.to(() => TalkerScreen(talker: talker!, isLogsExpanded: false));
    } else {
      logE('Talker not initialized');
    }
  }

  Future<void> showNotificationPermissionDialogWithQueue() async {
    final hasPermission = await PermissionManager.instance.hasNotificationPermission();
    if (hasPermission) {
      return;
    }

    final completer = Completer<void>();
    PopupQueueMgr.instance.addPopup(
      id: PopupType.PermissionDialog,
      showPopup: () {
        showAlter(
          PermissionDialog(
            title: 'enable_notifacation'.tr,
            description: 'permission_notification'.tr,
            confirmText: 'allow'.tr,
            cancelText: 'later'.tr,
            onConfirm: () {
              PermissionManager.instance.handleNotificationPermission();
            },
            onCancel: () {
              logD('onCancel');
            },
          ),
          needScale: true,
          onDismiss: () {
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );
        return completer.future;
      },
    );
  }

  /// 打开应用商店详情页（iOS App Store / Android Play Store）
  Future<void> openStorePage() async {
    if (GetPlatform.isIOS) {
      await launchUrl(Uri.parse(appStoreAppUrl), mode: LaunchMode.externalApplication);
      return;
    }
    await openPlayStoreRating();
  }

  Future<void> openPlayStoreRating() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String packageName = packageInfo.packageName;
    final Uri androidUri = Uri.parse('market://details?id=$packageName');
    final Uri webUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
    try {
      // 优先尝试直接打开 Play Store App
      if (await canLaunchUrl(androidUri)) {
        await launchUrl(androidUri, mode: LaunchMode.externalApplication);
      } else {
        // 回退到浏览器打开网页版
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // 如果失败，再尝试网页版
      await launchUrl(webUri, mode: LaunchMode.platformDefault);
    }
  }
}
