import 'dart:core';
import 'dart:ui';

import 'package:flutter_framework/Util/Translations/MyLocalization.dart';
import 'package:get/get.dart';

class MyTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => localizations;

  static Locale fallbackLocale() {
    return const Locale('en');
  }

  static List<Locale> localeSupportList() {
    List<Locale> list = [];
    for (String key in localizations.keys) {
      Locale locale = Locale(key);
      list.add(locale);
    }

    return list;
  }
}
