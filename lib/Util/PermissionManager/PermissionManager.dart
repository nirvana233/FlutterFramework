import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// 系统权限统一入口
///
/// 新增权限时注意同步原生配置：
/// - iOS：Info.plist 的 `NSxxxUsageDescription`，以及 ios/Podfile 中 permission_handler 的宏开关
/// - Android：AndroidManifest.xml 的 `<uses-permission>`
class PermissionManager {
  static PermissionManager? _instance;
  PermissionManager._internal();
  static PermissionManager get instance => _instance ??= PermissionManager._internal();

  /// 判断是否有推送权限
  /// 返回true表示有权限，false表示没有权限
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    logD('hasNotificationPermission status: $status');
    return status.isGranted;
  }

  Future<bool> isAndroid11Bellow() async {
    if (GetPlatform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt <= 30; // Android 11 的 SDK 版本是 30
    }
    return false; // 非 Android 设备
  }

  /// 综合处理推送权限
  /// 检查权限，如果没有权限则请求，如果被永久拒绝则打开设置
  /// 返回true表示最终有权限或已引导用户到设置页面
  Future<bool> handleNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      logD('handleNotificationPermission status: $status');
      if (status.isGranted) {
        return true;
      }

      if (GetPlatform.isAndroid) {
        if (status.isPermanentlyDenied) {
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
          return false;
        }
        final isUnderAndroid11 = await isAndroid11Bellow();
        if (isUnderAndroid11) {
          // 权限被永久拒绝，打开设置页面
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
          return false;
        }
      } else if (GetPlatform.isIOS) {
        if (status.isPermanentlyDenied || status.isDenied) {
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
          return false;
        }
      }

      // 请求权限
      final requestStatus = await Permission.notification.request();
      return requestStatus.isGranted;
    } catch (e) {
      logE(e);
    }
    return false;
  }

  /// 通用权限申请：已授权直接返回 true；被永久拒绝时跳转系统设置
  Future<bool> handlePermission(Permission permission) async {
    try {
      final status = await permission.status;
      logD('handlePermission $permission status: $status');
      if (status.isGranted || status.isLimited) {
        return true;
      }
      if (status.isPermanentlyDenied || status.isRestricted) {
        await AppSettings.openAppSettings();
        return false;
      }
      final requestStatus = await permission.request();
      return requestStatus.isGranted || requestStatus.isLimited;
    } catch (e) {
      logE(e);
    }
    return false;
  }
}
