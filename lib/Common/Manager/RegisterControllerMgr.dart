import 'package:flutter_framework/MainPage/RootPage/BottomBarMainPage/ViewModel/MainPageController.dart';
import 'package:get/get.dart';

/// 全局常驻 Controller 的注册 / 注销
///
/// - [register]：App 启动时调用（main.dart init），注册跨页面共享、需常驻的 Controller
/// - [unregister]：退出登录 / token 失效时调用，清理与账号相关的 Controller
class RegisterControllerMgr {
  static RegisterControllerMgr? _instance;
  RegisterControllerMgr._();
  static RegisterControllerMgr get instance => _instance ??= RegisterControllerMgr._();

  Future<void> register() async {
    if (!Get.isRegistered<MainPageController>()) {
      Get.put(MainPageController(), permanent: true);
    }
  }

  Future<void> unregister() async {
    // 示例：账号相关的 Controller 在这里删除，下次使用时由 findGetxController 重新创建
    // if (Get.isRegistered<UserController>()) {
    //   await Get.delete<UserController>(force: true);
    // }
  }
}
