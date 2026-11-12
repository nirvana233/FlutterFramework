import 'package:app_settings/app_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_framework/MainPage/Language/Model/AppLanguageDict.dart';
import 'package:flutter_framework/MainPage/Language/Model/LanguageCode.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/EventBusUtil/EventBusModel.dart';
import 'package:flutter_framework/Util/Router/RouteOpenPage.dart';
import 'package:flutter_framework/Util/Translations/MyLocalization.dart';
import 'package:flutter_framework/Util/Translations/MyTranslations.dart';
import 'package:get/get.dart';

/// App 界面语言管理
///
/// - iOS：跟随系统「设置 → App → 语言」（per-app language），App 内入口跳系统设置
/// - Android：优先使用 App 内选择并持久化的语言，未选择时跟随设备语言
/// - 支持的语言 = `MyLocalization.dart` 中的 key（由 tools/localization 生成）
class LanguageViewModel with LanguageCode {
  static LanguageViewModel? _instance;
  LanguageViewModel._internal();
  static LanguageViewModel get instance => _instance ??= LanguageViewModel._internal();

  ///设备语言（iOS 在系统设置里改过 App 语言后，这里拿到的是 App 语言）
  final Locale? _deviceLocale = Get.deviceLocale;

  ///皮肤语言 App语言
  var appLanguage = MyTranslations.fallbackLocale().obs;

  Locale get deviceLocale => _deviceLocale ?? MyTranslations.fallbackLocale();

  /// 支持的语言 code 列表（顺序同 MyLocalization）
  List<String> get supportedLanguageCodes => localizations.keys.toList();

  /// 语言 code 对应的展示名
  String languageName(String code) => languageCodeToNameDict[code] ?? code;

  //todo：初始化配置数据
  Future<void> init() async {
    await _initAppLanguage();
  }

  //TODO: 初始化app语言环境
  Future<void> _initAppLanguage() async {
    Locale? locale = _deviceLocale;
    if (isAvailable(locale?.languageCode)) {
      if (locale?.languageCode == 'nn' || locale?.languageCode == 'nb') {
        //如果设备语言环境为挪威语 特殊处理
        locale = const Locale('no', 'Norsk');
      }

      if (GetPlatform.isIOS) {
        if (localizations.keys.contains(locale?.languageCode)) {
          appLanguage.value = locale!;
        }
      } else {
        var lan = PreferenceUtil.instance.getAppLanguageItem(false);
        if (isAvailable(lan) && localizations.keys.contains(lan)) {
          appLanguage.value = Locale(lan);
        } else if (localizations.keys.contains(locale?.languageCode)) {
          appLanguage.value = locale!;
        }
      }
    }
    Get.updateLocale(appLanguage.value);
    PreferenceUtil.instance.setAppLanguageItem(appLanguage.value.languageCode);
    logD('App language: ${appLanguage.value.languageCode}');
  }

  /// 切换 App 语言（Android 语言页调用）
  Future<void> changeAppLanguage(String code) async {
    if (!localizations.keys.contains(code)) {
      logW('Unsupported app language: $code');
      return;
    }
    final locale = Locale(code);
    appLanguage.value = locale;
    await PreferenceUtil.instance.setAppLanguageItem(code);
    await Get.updateLocale(locale);
    eventBusUtil.fire(EventBusModelLanguageChange());
  }

  /// 打开 App 语言设置：iOS 跳系统设置，Android 进 App 内语言页
  Future<void> openAppLanguageSetting() async {
    if (GetPlatform.isIOS) {
      await AppSettings.openAppSettings();
    } else {
      await toAppLanguagePage();
    }
  }

  bool isRTL() {
    return isAppRTL();
  }

  bool isAppRTL() {
    return appLanguage.value.languageCode == 'he' ||
        appLanguage.value.languageCode == 'fa' ||
        appLanguage.value.languageCode == 'ar';
  }
}
