import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Common/Widget/CommonAppbar.dart';
import 'package:flutter_framework/MainPage/RootPage/BottomBarMainPage/ViewModel/MainPageController.dart';
import 'package:flutter_framework/Util/Router/RouteOpenPage.dart';
import 'package:get/get.dart';

/// 首页 Tab（框架占位）：放功能示例入口，新项目替换为真实首页
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: getAppFigmaColors.colorBgElementB96,
        appBar: CommonAppbar(title: 'tab_home'.tr, automaticallyImplyLeading: false),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            FigmaVariables.spacing16,
            FigmaVariables.spacing16,
            FigmaVariables.spacing16,
            MainPageController.bottomNavBarBaseHeight + FigmaVariables.spacing48,
          ),
          children: [
            _buildEntryCard(
              icon: Icons.list_alt,
              title: 'example_list_title'.tr,
              desc: 'example_list_desc'.tr,
              onTap: toExampleListPage,
            ),
            const SizedBox(height: FigmaVariables.spacing12),
            _buildEntryCard(
              icon: Icons.language,
              title: 'privacy'.tr,
              desc: 'example_webview_desc'.tr,
              onTap: toWebViewPage_Privacy,
            ),
          ],
        ),
      ),
    );
  }

  /// 功能入口卡片：图标 + 标题 + 描述
  Widget _buildEntryCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    final colors = getAppFigmaColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        VibrationMgr.instance.selection();
        onTap();
      },
      child: Container(
        padding: FigmaVariables.padding16,
        decoration: BoxDecoration(
          color: colors.colorBgElementB100,
          borderRadius: FigmaVariables.borderRadius12,
        ),
        child: Row(
          children: [
            Icon(icon, size: FigmaVariables.spacing28, color: colors.colorPrimaryDefault),
            const SizedBox(width: FigmaVariables.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.colorTextPrimaryB20,
                      fontSize: FigmaVariables.fontSize16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: FigmaVariables.spacing4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: colors.colorTextRegularB50,
                      fontSize: FigmaVariables.fontSize12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: FigmaVariables.spacing20,
              color: colors.colorTextSynopsisB70,
            ),
          ],
        ),
      ),
    );
  }
}
