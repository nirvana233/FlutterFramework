// ignore_for_file: non_constant_identifier_names

import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/StringUtil.dart';
import 'package:flutter_framework/Util/Router/Route.dart';
import 'package:get/get.dart';

/// 页面跳转统一入口：业务代码调用 `toXxxPage()`，不直接拼 `Get.toNamed(路由, arguments)`，
/// 便于集中维护参数结构与跳转前置逻辑。

//todo:回到主页（清空页面栈）
Future<void> toMainPage({int? tabIndex}) async {
  await Get.offAllNamed(mainPage, arguments: {'tabIndex': ?tabIndex});
}

//todo:WebView
Future<void> toWebViewPage(Map arguments) async {
  try {
    await Get.toNamed(webViewPage, arguments: arguments);
  } catch (e) {
    logE(e.toString());
  }
}

Future<void> toWebViewPage_Terms() async {
  await Get.toNamed(
    webViewPage,
    arguments: {
      'url': termsOfServiceUrl,
      'title': 'terms'.tr,
    },
  );
}

Future<void> toWebViewPage_Privacy() async {
  await Get.toNamed(
    webViewPage,
    arguments: {
      'url': privacyPolicyUrl,
      'title': 'privacy'.tr,
    },
  );
}

//todo:App 语言设置
Future<void> toAppLanguagePage() async {
  await Get.toNamed(appLanguagePage);
}

//todo:Example 模块
Future<void> toExampleListPage() async {
  await Get.toNamed(exampleListPage);
}

Future<void> toExampleDetailPage({required int id, String? title}) async {
  await Get.toNamed(exampleDetailPage, arguments: {'id': id, 'title': ?title});
}
