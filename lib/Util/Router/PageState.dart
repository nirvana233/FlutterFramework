import 'package:flutter_framework/Util/Router/Route.dart';

/// 按路由名登记「还在栈里」的页面（被其它页盖住也算）。
///
/// 命名路由由 [PageRouteObserver] 在 push / pop / replace / remove 时维护。
/// [BaseFulWidget] 仍会按 widget 类型写一份，供按页面类型判断的场景使用。
class PageStateMgr {
  static PageStateMgr? _instance;
  static PageStateMgr get instance => _instance ??= PageStateMgr._();
  PageStateMgr._();

  final Map<String, bool> _pageStateMap = {};

  bool contains(String pageName) {
    return _pageStateMap[pageName] == true;
  }

  bool containsAny(Iterable<String> pageNames) {
    for (final name in pageNames) {
      if (contains(name)) return true;
    }
    return false;
  }

  /// 该路由入栈。无名路由（弹窗 / Sheet）忽略。
  void markEntered(String? pageName) {
    if (pageName == null || pageName.isEmpty) return;
    _pageStateMap[pageName] = true;
  }

  /// 该路由出栈。
  void markLeft(String? pageName) {
    if (pageName == null || pageName.isEmpty) return;
    _pageStateMap[pageName] = false;
  }

  bool getPageState(String pageName) {
    return contains(pageName);
  }

  void setPageState(String pageName, bool state) {
    _pageStateMap[pageName] = state;
  }

  void clearPageState() {
    _pageStateMap.clear();
  }

  bool isMainPageExist() {
    return contains(mainPage);
  }
}
