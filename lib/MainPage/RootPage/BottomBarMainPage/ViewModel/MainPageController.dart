import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 主页（底部 Tab）状态
class MainPageController extends GetxController {
  // 底部导航栏固定高度(不含安全区)
  static const double bottomNavBarBaseHeight = 55.0;
  // 无安全区时的默认底部间距
  static const double defaultBottomPadding = 15.0;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  //RxBool 来表示底部导航栏的显示状态
  var isBottomBarVisible = true.obs;

  //RxInt 来表示当前选中的 BottomBar 项的索引
  var currentIndex = 0.obs;

  // 方法：切换底部导航栏的显示状态
  void toggleBottomBar(bool isVisible) {
    isBottomBarVisible.value = isVisible;
  }

  // 方法：切换 BottomBar 项
  void changeIndex(int index) {
    currentIndex.value = index;
  }

  int getIndex() {
    return currentIndex.value;
  }
}
