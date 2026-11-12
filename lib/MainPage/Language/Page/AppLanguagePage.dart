import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Common/Widget/CommonAppbar.dart';
import 'package:flutter_framework/MainPage/Language/ViewModel/LanguageViewModel.dart';
import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:get/get.dart';

/// App 界面语言选择页（Android 使用；iOS 跳系统设置，见 LanguageViewModel.openAppLanguageSetting）
class AppLanguagePage extends StatefulWidget {
  const AppLanguagePage({super.key});

  @override
  State<AppLanguagePage> createState() => _AppLanguagePageState();
}

class _AppLanguagePageState extends State<AppLanguagePage> {
  late String _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = PreferenceUtil.instance.getAppLanguageItem(true);
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var bottom = mediaQuery.padding.bottom;
    final languageCodes = LanguageViewModel.instance.supportedLanguageCodes;
    var count = languageCodes.length;

    return Scaffold(
      backgroundColor: getAppFigmaColors.colorBgElementB96,
      appBar: CommonAppbar(
        title: "applang".tr,
      ),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: getAppFigmaColors.colorBgElementB100,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: count,
                      itemBuilder: (context, index) {
                        if (index < count) {
                          var key = languageCodes[index];
                          var languageName = LanguageViewModel.instance.languageName(key);
                          bool isSelected = _selectedItem == key;

                          return GestureDetector(
                            onTap: () {
                              if (mounted) {
                                LanguageViewModel.instance.changeAppLanguage(key);
                                Get.back();
                                VibrationMgr.instance.selection();
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: getAppFigmaColors.colorBgElementB90,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        languageName,
                                        style: TextStyle(
                                          fontSize: FigmaVariables.fontSize16,
                                          color: getAppFigmaColors.colorTextPrimaryB20,
                                          fontWeight: FontWeight.w400,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        size: 20,
                                        color: getAppFigmaColors.colorSecondary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: getAppFigmaColors.colorBgElementB100,
                  ),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottom),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "language_not_availabe".tr,
                      style: TextStyle(
                        color: getAppFigmaColors.colorTextRegularB50,
                        fontSize: FigmaVariables.fontSize12,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
