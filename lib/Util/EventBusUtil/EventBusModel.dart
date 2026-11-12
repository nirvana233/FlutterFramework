// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Common/Enum.dart';

/// 全局事件定义。发送：`eventBusUtil.fire(EventBusModelXxx())`；
/// 监听：`eventBusUtil.on<EventBusModelXxx>().listen(...)`，页面销毁时记得 cancel。
abstract class EventBusModelBase {}

/// App 界面语言切换
class EventBusModelLanguageChange extends EventBusModelBase {
  EventBusModelLanguageChange();
}

/// 路由变化（由 PageRouteObserver 派发）
class EventBusModelRouteChange extends EventBusModelBase {
  RouteSettings? settings;
  RouteSettings? previousSettings;
  RouteEnum routeType;

  EventBusModelRouteChange({
    required this.settings,
    this.previousSettings,
    required this.routeType,
  });
}

/// App 生命周期变化（由 AppMgr 派发）
class EventBusModelAppLifecycleStateChange extends EventBusModelBase {
  AppLifecycleState appLifecycleState;

  EventBusModelAppLifecycleStateChange({
    required this.appLifecycleState,
  });
}

/// 跨天（由 TimeMgr 派发）
class EventBusModelNewDayChange extends EventBusModelBase {
  EventBusModelNewDayChange();
}

/// 登录状态变化（登录 / 退出登录后由业务层派发）
class EventBusModelLoginStateChange extends EventBusModelBase {
  final bool isLogin;

  EventBusModelLoginStateChange({required this.isLogin});
}
