import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:get/get.dart';

/// App 级别主题管理器（明暗模式）
///
/// UI 取色统一用 `getAppFigmaColors`（见 FigmaVariables），它会根据 [isDarkMode] 返回对应主题；
/// 在 `Obx` 中读取颜色即可在切换主题时自动刷新。
class AppThemeMgr {
  static AppThemeMgr? _instance;
  AppThemeMgr._internal();
  static AppThemeMgr get instance => _instance ??= AppThemeMgr._internal();

  /// App 级别的暗色模式开关（默认 light，持久化在 PreferenceUtil）
  final RxBool isDarkMode = false.obs;

  /// 从本地读取主题设置（PreferenceUtil.init 之后调用）
  void init() {
    isDarkMode.value = PreferenceUtil.instance.getIsDarkMode();
  }

  /// 切换主题
  void toggleTheme() {
    setDarkMode(!isDarkMode.value);
  }

  /// 设置主题
  void setDarkMode(bool value) {
    isDarkMode.value = value;
    PreferenceUtil.instance.setIsDarkMode(value);
  }

  /// 是否为亮色模式
  bool get isLightMode => !isDarkMode.value;
}
