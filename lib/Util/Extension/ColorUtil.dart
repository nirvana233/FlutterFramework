import 'dart:ui';

class HexColor extends Color {
  // //主题色
  // static Color appThemeColor    = Color(0xFFFF4B3B);
  // static Color appBarThemeColor = Color(0xFFF1F2F7);
  // static Color tabBarThemeColor = Color(0xFFF1F2F7);
  // static Color pageThemeColor   = Color(0xFFF1F2F7);

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  static colorFromInt(int hex, {double alpha = 1}) {
    if (alpha < 0) {
      alpha = 0;
    } else if (alpha > 1) {
      alpha = 1;
    }
    return Color.fromRGBO(
      (hex & 0xFF0000) >> 16,
      (hex & 0x00FF00) >> 8,
      (hex & 0x0000FF) >> 0,
      alpha,
    );
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

//传int 0x--，透明度可自定义
class ColorsUtil {
  /// 十六进制颜色，
  /// hex, 十六进制值，例如：0xffffff,
  /// alpha, 透明度 [0.0,1.0]

  // //主题色
  // static Color tabBarThemeColor = Color(0xFFF4F5F6);
  // static Color pageThemeColor = Color(0xFFF4F5F6);

  //主题色
  // static Color appThemeColor    = Color(0xFFFF4B3B);
  static Color appThemeColor = const Color(0xFFFF4C3A);
  static Color appBarThemeColor = const Color(0xFFF1F2F7);
  static Color tabBarThemeColor = const Color(0xFFF1F2F7);
  static Color pageThemeColor = const Color(0xFFF1F2F7);

  static Color hexColor(int hex, {double alpha = 1.0}) {
    if (alpha < 0) {
      alpha = 0;
    } else if (alpha > 1) {
      alpha = 1;
    }
    return Color.fromRGBO(
      (hex & 0xFF0000) >> 16,
      (hex & 0x00FF00) >> 8,
      (hex & 0x0000FF) >> 0,
      alpha,
    );
  }
}
