import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Debug/GM/GMPage.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/AppThemeMgr.dart';
import 'package:flutter_framework/Common/Widget/CommonAppbar.dart';
import 'package:flutter_framework/Common/Widget/Dialog/ClearCacheDialog.dart';
import 'package:flutter_framework/Common/Widget/ToggleSwitchView.dart';
import 'package:flutter_framework/MainPage/Language/ViewModel/LanguageViewModel.dart';
import 'package:flutter_framework/MainPage/RootPage/BottomBarMainPage/ViewModel/MainPageController.dart';
import 'package:flutter_framework/MainPage/RootPage/MinePage/ViewModel/MineController.dart';
import 'package:flutter_framework/MainPage/RootPage/MinePage/Widget/SettingItem.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/Const.dart';
import 'package:flutter_framework/Util/Router/RouteOpenPage.dart';
import 'package:get/get.dart';

/// 我的 Tab：通用设置项（语言、主题、震动、缓存、协议、版本、调试入口）
class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  late final MineController _controller;

  @override
  void initState() {
    super.initState();
    _controller = findGetxController(MineController.new);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colors = getAppFigmaColors;
      final languageViewModel = LanguageViewModel.instance;
      return Scaffold(
        backgroundColor: colors.colorBgElementB96,
        appBar: CommonAppbar(title: 'tab_mine'.tr, automaticallyImplyLeading: false),
        body: ListView(
          padding: const EdgeInsets.only(
            top: FigmaVariables.spacing12,
            bottom: MainPageController.bottomNavBarBaseHeight + FigmaVariables.spacing48,
          ),
          children: [
            // ===== 偏好设置 =====
            SettingItem(
              title: 'applang'.tr,
              value: languageViewModel.languageName(
                languageViewModel.appLanguage.value.languageCode,
              ),
              onTap: languageViewModel.openAppLanguageSetting,
            ),
            SettingItem(
              title: 'dark_mode'.tr,
              trailing: ToggleSwitchView(
                value: AppThemeMgr.instance.isDarkMode.value,
                onChanged: _controller.setDarkMode,
              ),
            ),
            SettingItem(
              title: 'vibration'.tr,
              trailing: ToggleSwitchView(
                value: _controller.isVibrationEnabled.value,
                onChanged: _controller.setVibrationEnabled,
              ),
            ),
            SettingItem(
              title: 'clear_cache'.tr,
              showDivider: false,
              onTap: () => showClearCacheDialog(onConfirm: _controller.clearCache),
            ),
            const SizedBox(height: FigmaVariables.spacing12),
            // ===== 协议 & 关于 =====
            SettingItem(title: 'terms'.tr, onTap: toWebViewPage_Terms),
            SettingItem(title: 'privacy'.tr, onTap: toWebViewPage_Privacy),
            SettingItem(
              title: 'version'.tr,
              value: _controller.version.value,
              showDivider: isTestClient,
            ),
            // ===== 调试入口（仅测试包） =====
            if (isTestClient)
              SettingItem(
                title: 'gm_tools'.tr,
                showDivider: false,
                onTap: () => Get.to(() => const GMPage()),
              ),
          ],
        ),
      );
    });
  }
}
