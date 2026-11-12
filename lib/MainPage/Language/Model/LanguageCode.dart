mixin LanguageCode {
  // 语言代码到locale字符串的映射表
  static const Map<String, String> _localeMap = {
    // 基于MyLocalization.dart中支持的语言
    'en': 'en_US',
    'fil': 'fil_PH',
    'id': 'id_ID',
    'nl': 'nl_NL',
    'sv': 'sv_SE',
    'da': 'da_DK',
    'fi': 'fi_FI',
    'no': 'no_NO',
    'af': 'af_ZA',
    'ms': 'ms_MY',
    'pt': 'pt_PT',
    'es': 'es_ES',
    'hi': 'hi_IN',
    'te': 'te_IN',
    'ta': 'ta_IN',
    'th': 'th_TH',
    'ar': 'ar_SA',
    'vi': 'vi_VN',
    'km': 'km_KH',
    'ro': 'ro_RO',
    'sw': 'sw_KE',
    'de': 'de_DE',
    'fr': 'fr_FR',
    'ru': 'ru_RU',
    'tr': 'tr_TR',
    'pl': 'pl_PL',
    'it': 'it_IT',
    'cs': 'cs_CZ',
    'gu': 'gu_IN',
    'el': 'el_GR',
    'he': 'he_IL',
    'uk': 'uk_UA',
    'hu': 'hu_HU',
    'sk': 'sk_SK',
    'sr': 'sr_RS',
    'bg': 'bg_BG',
    'az': 'az_AZ',
    'hr': 'hr_HR',
    'ca': 'ca_ES',
    'be': 'be_BY',
    'fa': 'fa_IR',
    'ja': 'ja_JP',
    'ko': 'ko_KR',
    'kk': 'kk_KZ',
    'sl': 'sl_SI',
    'lt': 'lt_LT',
    'et': 'et_EE',
    'lv': 'lv_LV',
    'ka': 'ka_GE',
    // 其他常见语言
    'zh': 'zh_CN',
  };

  // 将语言代码转换为locale字符串
  String getLocaleString(String languageCode) {
    return _localeMap[languageCode] ?? 'en_US';
  }
}
