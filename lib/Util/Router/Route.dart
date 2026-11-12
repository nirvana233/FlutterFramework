// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Page/WebViewPage.dart';
import 'package:flutter_framework/MainPage/Example/Page/ExampleDetailPage.dart';
import 'package:flutter_framework/MainPage/Example/Page/ExampleListPage.dart';
import 'package:flutter_framework/MainPage/Language/Page/AppLanguagePage.dart';
import 'package:flutter_framework/MainPage/Launch/LaunchPage.dart';
import 'package:flutter_framework/MainPage/RootPage/BottomBarMainPage/MainPage.dart';

String? _currentPageName;
dynamic _currentPageArguments;

// ==================== 路由常量 ====================
// 新增页面：1. 在这里定义常量  2. 在 [routes] 登记  3. 跳转方法写到 RouteOpenPage.dart
const String launchPage = '/launchPage';
const String mainPage = '/mainPage';
const String webViewPage = '/webViewPage';
const String appLanguagePage = '/appLanguagePage';

// ==================== Example 模块路由 ====================
/// 示例列表页
const String exampleListPage = '/exampleListPage';

/// 示例详情页
const String exampleDetailPage = '/exampleDetailPage';

/// 路由表
/// - 无参页面：`(context) => XxxPage()`
/// - 必带参数：`(context, arguments) => XxxPage(arguments: arguments)`
/// - 可选参数：`(context, [arguments]) => XxxPage(arguments: arguments)`
final Map<String, dynamic> routes = {
  launchPage: (context) => LaunchPage(),
  mainPage: (context, [arguments]) => MainPage(arguments: arguments),
  webViewPage: (context, arguments) => WebViewPage(arguments: arguments),
  appLanguagePage: (context) => const AppLanguagePage(),

  // Example 模块
  exampleListPage: (context) => const ExampleListPage(),
  exampleDetailPage: (context, arguments) => ExampleDetailPage(arguments: arguments),
};

Widget _buildRoutePage(Function pageContentBuilder, BuildContext context, Object? arguments) {
  try {
    return pageContentBuilder(context, arguments);
  } on NoSuchMethodError {
    return pageContentBuilder(context);
  }
}

/// 无转场动画的路由：进入与返回均直接切换（transitionDuration = 0）
/// 新增需要「无动画」的页面时，仅在此登记路由名即可。
const Set<String> _noTransitionRoutes = {
  // 示例：splashPage,
};

var generateRoute = (RouteSettings settings) {
  final String? name = settings.name;
  final Function? pageContentBuilder = routes[name];
  if (pageContentBuilder == null) {
    return null;
  }

  final WidgetBuilder builder = (context) =>
      _buildRoutePage(pageContentBuilder, context, settings.arguments);

  // 无转场动画路由（见 [_noTransitionRoutes]）：进入与返回均直接切换
  if (_noTransitionRoutes.contains(name)) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, _, __) => builder(context),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  return MaterialPageRoute(settings: settings, builder: builder);
};

/// 当前栈顶命名路由（由 PageRouteObserver 维护）
String? get currentPageName {
  return _currentPageName;
}

dynamic get currentPageArguments {
  return _currentPageArguments;
}

void setCurrentPageName(String? name) {
  _currentPageName = name;
}

void setCurrentPageArguments(dynamic arguments) {
  _currentPageArguments = arguments;
}
