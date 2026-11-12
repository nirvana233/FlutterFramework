import 'package:get/get.dart';

/// 全局字体配置
///
/// 默认使用系统字体；引入自定义字体时：
/// 1. 字体文件放到 `assets/fonts/`，在 pubspec.yaml 的 `fonts` 段声明 family
/// 2. 修改 [primaryFontFamily]，并把该 family 放到 [getFontFamilyFallback] 列表首位
class FontConfig {
  FontConfig._();

  /// App 主字体，null 表示使用系统默认字体
  static const String? primaryFontFamily = null;

  /// 多语言字体回退链：主字体缺少 CJK、阿拉伯文等字形时按顺序回退到系统字体
  static List<String> getFontFamilyFallback() {
    if (GetPlatform.isIOS) {
      return const [
        // 系统（拉丁/西里尔/希腊/越南/土耳其等）
        '.AppleSystemUIFont',
        '.SF Pro Text',
        // Emoji
        'Apple Color Emoji',
        // 中文（简/繁/港）
        'PingFang SC',
        'PingFang TC',
        'PingFang HK',
        // 日文、韩文
        'Hiragino Sans',
        'Apple SD Gothic Neo',
        // 阿拉伯文、波斯文
        'Geeza Pro',
        'Noto Naskh Arabic',
        // 希伯来文
        'Arial Hebrew',
        // 印度系
        'Kohinoor Devanagari',
        'Devanagari Sangam MN',
        'Kohinoor Gujarati',
        'Kohinoor Telugu',
        'Tamil Sangam MN',
        // 东南亚
        'Thonburi',
        'Khmer Sangam MN',
        'Khmer MN',
        // 格鲁吉亚文
        'Noto Sans Georgian',
        'Sylfaen',
        // 最终兜底
        'Helvetica Neue',
        'Arial',
        'sans-serif',
      ];
    } else {
      return const [
        // 系统（拉丁/西里尔/希腊/越南/土耳其等）
        'Roboto',
        // Emoji
        'Noto Color Emoji',
        // 中文（双写法兼容不同 Android 机型 family 名）
        'NotoSansSC',
        'Noto Sans SC',
        'NotoSansJP',
        'Noto Sans JP',
        'NotoSansKR',
        'Noto Sans KR',
        // 阿拉伯文、波斯文
        'NotoSansArabic',
        'Noto Sans Arabic',
        'Noto Naskh Arabic',
        // 希伯来文
        'Noto Sans Hebrew',
        // 印度系
        'Noto Sans Devanagari',
        'Noto Sans Gujarati',
        'Noto Sans Telugu',
        'Noto Sans Tamil',
        // 东南亚
        'Noto Sans Thai',
        'Noto Sans Khmer',
        // 格鲁吉亚文
        'Noto Sans Georgian',
        // 广覆盖 + 平台最终兜底
        'Noto Sans',
        'sans-serif',
      ];
    }
  }
}
