import 'package:flutter_framework/Util/Router/Route.dart';
import 'package:get/get.dart';

/// 启动流程收尾：决定闪屏结束后进入哪个页面
class LaunchViewModel {
  static LaunchViewModel? _instance;
  LaunchViewModel._internal();
  static LaunchViewModel get instance => _instance ??= LaunchViewModel._internal();

  /// 闪屏结束后的跳转。接入登录 / 引导页 / DeepLink 时在这里分流，例如：
  /// ```dart
  /// if (!PreferenceUtil.instance.isLogin()) return Get.offAllNamed(loginPage);
  /// ```
  Future<void> launchEnd() async {
    await Get.offAllNamed(mainPage);
  }
}
