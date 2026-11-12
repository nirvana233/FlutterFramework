import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_framework/Common/Extension/extension.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/Const.dart';
import 'package:flutter_framework/Util/RefreshLoader/RefreshLoaderUtil.dart';
import 'package:flutter_framework/Util/Router/PageState.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// import 'package:screen_protector/screen_protector.dart';

class BaseFulWidget extends StatefulWidget {
  final dynamic arguments;

  BaseFulWidget({super.key, this.arguments});

  RefreshController? refreshController;

  void dealRefreshState(
    int pageIndex,
    int pageSize,
    List? list,
    RefreshController? controller, {
    bool reqSuc = true,
  }) {
    if (controller != null) {
      refreshController = controller;
    }
    if (pageIndex == 1) {
      RefreshStateUtil.finishRefresh(
        refreshController,
        success: reqSuc,
        resetFooterState: reqSuc,
      );
    } else {
      final noMore = reqSuc && (list == null || list.isEmpty || list.length < pageSize);
      RefreshStateUtil.finishLoadMore(
        refreshController,
        success: reqSuc,
        noMore: noMore,
      );
    }
  }

  @override
  State<BaseFulWidget> createState() => BaseFulWidgetState();
}

showSystemStatusBar() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
}

hideSystemStatusBar() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
}

setSystemStatusBarLight() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
}

setSystemStatusBarDark() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
}

void screenshotOff() async {
  if (isTestClient || isTestServer) {
    return;
  }
  // await ScreenProtector.preventScreenshotOn();
  await NoScreenshot.instance.screenshotOff();
}

void screenshotOn() async {
  if (isTestClient || isTestServer) {
    return;
  }
  // await ScreenProtector.preventScreenshotOff();
  await NoScreenshot.instance.screenshotOn();
}

void unFocusScope(BuildContext context) {
  FocusScopeNode currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus) {
    currentFocus.unfocus();
  }
}

///发送事件
void eventBusFire(dynamic event) {
  eventBusUtil.fire(event);
}

///监听事件
///T 事件传递对象类型
///listener 监听回调
StreamSubscription<T> eventBusOn<T>(Function(dynamic) listener) {
  return eventBusUtil.on<T>().listen((obj) {
    listener(obj);
  });
}

class BaseFulWidgetState<T extends BaseFulWidget> extends State<T> {
  /// 同类型页面发生交接时，旧 State 可跳过离场写入，避免覆盖新页面的存在态。
  @protected
  bool get shouldMarkPageLeftOnDispose => true;

  @override
  void initState() {
    PageStateMgr.instance.setPageState(
      '/${widget.runtimeType.toString().firstLetterLowerCase}',
      true,
    );
    super.initState();
  }

  @override
  void dispose() {
    if (shouldMarkPageLeftOnDispose) {
      PageStateMgr.instance.setPageState(
        '/${widget.runtimeType.toString().firstLetterLowerCase}',
        false,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
