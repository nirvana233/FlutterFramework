import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Common/Enum.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/EventBusUtil/EventBusModel.dart';
import 'package:flutter_framework/Util/Router/PageState.dart';
import 'package:flutter_framework/Util/Router/Route.dart';

// Function(String? pageName, String? previousPageName)? popCallback;

class PageRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  final List<PageRoute<dynamic>> _pageRoutes = <PageRoute<dynamic>>[];

  void _setCurrentTrackedPage() {
    final currentRoute = _pageRoutes.isEmpty ? null : _pageRoutes.last;
    setCurrentPageName(currentRoute?.settings.name);
    setCurrentPageArguments(currentRoute?.settings.arguments);
  }

  /// 按真实路由实例重算存在态，避免移除旧同名路由时把仍在栈内的新路由标成离场。
  void _syncPageState(String? pageName) {
    if (pageName == null || pageName.isEmpty) return;
    PageStateMgr.instance.setPageState(
      pageName,
      _pageRoutes.any((route) => route.settings.name == pageName),
    );
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    if (route is PageRoute<dynamic>) {
      _pageRoutes.remove(route);
      _pageRoutes.add(route);
      _syncPageState(route.settings.name);
      _setCurrentTrackedPage();
    }
    eventBusUtil.fire(
      EventBusModelRouteChange(
        settings: route.settings,
        previousSettings: previousRoute?.settings,
        routeType: RouteEnum.push,
      ),
    );
    // logP('didPush: ${route.settings.name}  ${previousRoute?.settings.name}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    // logP('didPop: ${route.settings.name}  ${previousRoute?.settings.name}');
    if (route is PageRoute<dynamic>) {
      _pageRoutes.remove(route);
      _syncPageState(route.settings.name);
      _setCurrentTrackedPage();
    }
    eventBusUtil.fire(
      EventBusModelRouteChange(
        settings: route.settings,
        previousSettings: previousRoute?.settings,
        routeType: RouteEnum.pop,
      ),
    );
    super.didPop(route, previousRoute);
    // popCallback?.call(route.settings.name, previousRoute?.settings.name);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    // logP(
    //     'Replaced: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
    final oldPageName = oldRoute is PageRoute<dynamic> ? oldRoute.settings.name : null;
    final newPageName = newRoute is PageRoute<dynamic> ? newRoute.settings.name : null;
    final oldIndex = oldRoute is PageRoute<dynamic> ? _pageRoutes.indexOf(oldRoute) : -1;
    if (oldRoute is PageRoute<dynamic>) {
      _pageRoutes.remove(oldRoute);
    }
    if (newRoute is PageRoute<dynamic>) {
      if (oldIndex >= 0 && oldIndex <= _pageRoutes.length) {
        _pageRoutes.insert(oldIndex, newRoute);
      } else {
        _pageRoutes.add(newRoute);
      }
      _setCurrentTrackedPage();
    } else if (oldIndex >= 0) {
      _setCurrentTrackedPage();
    }
    _syncPageState(oldPageName);
    if (newPageName != oldPageName) {
      _syncPageState(newPageName);
    }
    eventBusUtil.fire(
      EventBusModelRouteChange(
        settings: newRoute?.settings,
        previousSettings: oldRoute?.settings,
        routeType: RouteEnum.replace,
      ),
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    // logP('Removed: ${route.settings.name}  ${previousRoute?.settings.name}');
    if (route is PageRoute<dynamic>) {
      final wasCurrent = _pageRoutes.isNotEmpty && identical(_pageRoutes.last, route);
      _pageRoutes.remove(route);
      _syncPageState(route.settings.name);
      if (wasCurrent) _setCurrentTrackedPage();
    }
    eventBusUtil.fire(
      EventBusModelRouteChange(
        settings: route.settings,
        previousSettings: previousRoute?.settings,
        routeType: RouteEnum.remove,
      ),
    );
    super.didRemove(route, previousRoute);
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    // logP(
    //     'Started gesture: ${route.settings.name}  ${previousRoute?.settings.name}');
    eventBusUtil.fire(
      EventBusModelRouteChange(
        settings: route.settings,
        previousSettings: previousRoute?.settings,
        routeType: RouteEnum.startUserGesture,
      ),
    );
    super.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    // logP('Stopped gesture');
    super.didStopUserGesture();
  }
}
