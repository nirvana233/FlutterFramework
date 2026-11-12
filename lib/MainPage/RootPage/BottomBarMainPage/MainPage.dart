import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_framework/Base/BaseFulWidget.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Common/Widget/ExitTips.dart';
import 'package:flutter_framework/MainPage/RootPage/BottomBarMainPage/ViewModel/MainPageController.dart';
import 'package:flutter_framework/MainPage/RootPage/HomePage/Page/HomePage.dart';
import 'package:flutter_framework/MainPage/RootPage/MinePage/Page/MinePage.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:get/get.dart';

/// 主页：底部 Tab 容器（IndexedStack 保留各 Tab 状态 + 毛玻璃底栏）
/// 新增 Tab：在 [_tabConfigs] 和 [_pages] 同步追加
class MainPage extends BaseFulWidget {
  MainPage({super.key, super.arguments});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends BaseFulWidgetState<MainPage> {
  late final MainPageController _mainPageController;

  /// Tab 配置：图标 + 文案 key
  static const List<_TabItemConfig> _tabConfigs = [
    _TabItemConfig(icon: Icons.home_outlined, selectedIcon: Icons.home, labelKey: 'tab_home'),
    _TabItemConfig(icon: Icons.person_outline, selectedIcon: Icons.person, labelKey: 'tab_mine'),
  ];

  final List<Widget> _pages = const [HomePage(), MinePage()];

  @override
  void initState() {
    super.initState();
    _mainPageController = findGetxController(MainPageController.new);
    showSystemStatusBar();
    // 路由参数指定初始 Tab：toMainPage(tabIndex: 1)
    final arguments = widget.arguments;
    final tabIndex = arguments is Map ? arguments['tabIndex'] : null;
    if (tabIndex is int && tabIndex >= 0 && tabIndex < _pages.length) {
      _mainPageController.changeIndex(tabIndex);
    }
  }

  /// 底部导航栏总高度（含安全区）
  double get _bottomNavBarHeight {
    final bottom = MediaQuery.of(context).padding.bottom;
    return MainPageController.bottomNavBarBaseHeight +
        (bottom > 0 ? bottom : MainPageController.defaultBottomPadding);
  }

  /// 底部主导航：毛玻璃背景 + 图标文字
  Widget _buildBottomNavBar() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: FigmaVariables.blur12, sigmaY: FigmaVariables.blur12),
        child: Container(
          height: _bottomNavBarHeight,
          color: getAppFigmaColors.colorBgToolBarB10080,
          padding: EdgeInsets.only(
            bottom: bottom > 0 ? bottom : MainPageController.defaultBottomPadding,
          ),
          child: Row(
            children: List.generate(_tabConfigs.length, (index) {
              final config = _tabConfigs[index];
              final isSelected = _mainPageController.currentIndex.value == index;
              final color = isSelected
                  ? getAppFigmaColors.colorSecondary
                  : getAppFigmaColors.colorTextNoteB60;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTabTap(index),
                  child: SizedBox(
                    height: MainPageController.bottomNavBarBaseHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? config.selectedIcon : config.icon,
                          size: FigmaVariables.spacing24,
                          color: color,
                        ),
                        Text(
                          config.labelKey.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: FigmaVariables.fontSize12,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Tab点击处理
  void _onTabTap(int index) {
    if (_mainPageController.currentIndex.value == index) return;
    VibrationMgr.instance.selection();
    _mainPageController.changeIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return ExitTips(
      child: Scaffold(
        key: _mainPageController.scaffoldKey,
        // ===== 页面内容 + 底部导航栏 =====
        body: Obx(() {
          return Stack(
            children: [
              IndexedStack(index: _mainPageController.currentIndex.value, children: _pages),
              if (_mainPageController.isBottomBarVisible.value)
                Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNavBar()),
            ],
          );
        }),
      ),
    );
  }
}

/// Tab配置项
class _TabItemConfig {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;

  const _TabItemConfig({required this.icon, required this.selectedIcon, required this.labelKey});
}
