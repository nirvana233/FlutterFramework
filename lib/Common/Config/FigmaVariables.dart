import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Manager/AppThemeMgr.dart';

/// Figma Design Tokens - 支持明暗模式
///
/// 新项目接入设计稿时，用 Figma 导出的变量覆盖这里的数值（命名尽量保持不变，
/// 以便 Skill / 规范中的示例继续适用）；新增 Token 按分组追加。
///
/// - 主题色（随明暗模式变化）：`getAppFigmaColors.colorXxx`
/// - 固定值（字号 / 间距 / 圆角 / 模糊 / 固定色）：`FigmaVariables.xxx`
///
/// ==================== 透明度转换规则 ====================
/// Flutter 颜色格式: 0xAARRGGBB (AA 是不透明度)
/// Figma/CSS rgba 中的 alpha 值也是不透明度 (opacity)
///
/// 常用不透明度对照表:
/// | 不透明度 | Alpha (hex) | Alpha (dec) |
/// |---------|-------------|-------------|
/// | 100%    | 0xFF        | 255         |
/// | 80%     | 0xCC        | 204         |
/// | 70%     | 0xB2        | 178         |
/// | 50%     | 0x7F        | 127         |
/// | 30%     | 0x4C        | 76          |
/// | 20%     | 0x33        | 51          |
/// | 0%      | 0x00        | 0           |
///
/// 注意: Figma JSON 中 "#RRGGBBAA" 格式，AA 在末尾
///       Flutter Color 中 "0xAARRGGBB" 格式，AA 在开头
/// ========================================================
class FigmaVariables {
  FigmaVariables._();

  // ==================== Theme Colors (支持明暗模式) ====================

  /// 强制覆盖主题：非空时 [getFigmaColors] 返回此值。
  /// 用于需固定明暗的局部场景（如始终暗色的播放页），退出时还原为 null。
  static FigmaThemeColors? forcedThemeOverride;

  /// 获取当前主题颜色
  static FigmaThemeColors _of() {
    // 先读 isDarkMode，保证外层 Obx 在覆盖期间也能订阅到主题变化
    final isDarkMode = AppThemeMgr.instance.isDarkMode.value;
    if (forcedThemeOverride != null) return forcedThemeOverride!;
    return isDarkMode ? dark : light;
  }

  /// 亮色主题
  static const FigmaThemeColors light = FigmaThemeColors(
    // Text Colors
    colorTextPrimaryB0: Color(0xFF000000),
    colorTextPrimaryB20: Color(0xFF333333),
    colorTextSecondaryB30: Color(0xFF4C4C4C),
    colorTextRegularB50: Color(0xFF808080),
    colorTextNoteB60: Color(0xFF999999),
    colorTextSynopsisB70: Color(0xFFB3B3B3),
    colorTextPrimaryRed: Color(0xFFFF4B3B),
    colorTextSecondaryRed: Color(0xFFFF695A),
    colorTextLabelBlue: Color(0xFF0C9CFF),
    // Brand Colors
    colorPrimaryDefault: Color(0xFFFF4B3B),
    colorPrimaryActive: Color(0xFFD8493C),
    colorPrimaryDisabled: Color(0xFFF5DBD9),
    colorSecondary: Color(0xFFFF695A),
    // Surface Colors
    colorBgElementB0: Color(0xFF000000),
    colorBgElementB30: Color(0xFF4C4C4C),
    colorBgElementB50: Color(0xFF808080),
    colorBgElementB60: Color(0xFF999999),
    colorBgElementB70: Color(0xFFB3B3B3),
    colorBgElementB80: Color(0xFFCCCCCC),
    colorBgElementB90: Color(0xFFE6E6E6),
    colorBgElementB96: Color(0xFFF5F5F5),
    colorBgElementB100: Color(0xFFFFFFFF),
    colorBgElementB100Light: Color(0xFFFFFFFF),
    colorBgElementB010: Color(0x19000000),
    colorBgElementB020: Color(0x33000000),
    colorBgToolBarB10080: Color(0xCCFFFFFF),
    colorBgToastB10050: Color(0x7F000000),
    popupWindowBg: Color(0xFFFFFFFF),
    // Label Colors
    colorBgLabelBlue: Color(0xFFD8ECFF),
    colorBgLabelRed: Color(0xFFFFE7E1),
    colorBgLabelGreenLight: Color(0xFFE0EFE2),
    colorBgLabelGreenDark: Color(0xFF72C767),
  );

  /// 暗色主题
  static const FigmaThemeColors dark = FigmaThemeColors(
    // Text Colors
    colorTextPrimaryB0: Color(0xFFCCCCCC),
    colorTextPrimaryB20: Color(0xFFCCCCCC),
    colorTextSecondaryB30: Color(0xFF999999),
    colorTextRegularB50: Color(0xFF999999),
    colorTextNoteB60: Color(0xFF808080),
    colorTextSynopsisB70: Color(0xFF4C4C4C),
    colorTextPrimaryRed: Color(0xFFC9483D),
    colorTextSecondaryRed: Color(0xFFD46763),
    colorTextLabelBlue: Color(0xFF5AAFFF),
    // Brand Colors
    colorPrimaryDefault: Color(0xFFC9483D),
    colorPrimaryActive: Color(0xFF983931),
    colorPrimaryDisabled: Color(0xFF8E716F),
    colorSecondary: Color(0xFFD46763),
    // Surface Colors
    colorBgElementB0: Color(0xFFCCCCCC),
    colorBgElementB30: Color(0xFFB3B3B3),
    colorBgElementB50: Color(0xFF999999),
    colorBgElementB60: Color(0xFF808080),
    colorBgElementB70: Color(0xFF4C4C4C),
    colorBgElementB80: Color(0xFF333333),
    colorBgElementB90: Color(0xFF191919),
    colorBgElementB96: Color(0xFF141414),
    colorBgElementB100: Color(0xFF262626),
    colorBgElementB100Light: Color(0xFFCCCCCC),
    colorBgElementB010: Color(0x19FFFFFF),
    colorBgElementB020: Color(0xFF4C4C4C),
    colorBgToolBarB10080: Color(0xCC191919),
    colorBgToastB10050: Color(0x7FFFFFFF),
    popupWindowBg: Color(0xFF4C4C4C),
    // Label Colors
    colorBgLabelBlue: Color(0xFF2D3A47),
    colorBgLabelRed: Color(0xFF4D2E2E),
    colorBgLabelGreenLight: Color(0xFF2A402D),
    colorBgLabelGreenDark: Color(0xFF297B1E),
  );

  // ==================== Constants (固定值，不随主题变化) ====================

  // Font Size
  static const double fontSize8 = 8.0;
  static const double fontSize10 = 10.0;
  static const double fontSize12 = 12.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize24 = 24.0;
  static const double fontSize32 = 32.0;

  // Spacing
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;
  static const double spacing32 = 32.0;
  static const double spacing36 = 36.0;
  static const double spacing40 = 40.0;
  static const double spacing44 = 44.0;
  static const double spacing48 = 48.0;
  static const double spacing52 = 52.0;
  static const double spacing60 = 60.0;

  // Radius
  static const double radius3 = 3.0;
  static const double radius6 = 6.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius24 = 24.0;

  // Blur
  static const double blur4 = 4.0;
  static const double blur8 = 8.0;
  static const double blur10 = 10.0;
  static const double blur12 = 12.0;
  static const double blur40 = 40.0;

  // Font Family（null = 系统字体，见 FontConfig）
  static const String? fontPrimary = null;

  // Fixed Colors
  /// 固定白色文字 - B100
  static const Color colorTextPrimaryB100 = Color(0xFFFFFFFF);

  /// 固定绿色文字
  static const Color colorTextLabelGreen = Color(0xFF28A745);

  /// 阴影 - B0 30%
  static const Color colorBgShadowB030 = Color(0x4C000000);

  /// 遮罩 - B0 30%
  static const Color colorBgMaskB030 = Color(0x4C000000);

  /// 遮罩 - B0 70%
  static const Color colorBgMaskB070 = Color(0xB2000000);

  /// 遮罩 - B0 100%
  static const Color colorBgMaskB100 = Color(0xFF000000);

  // ==================== BorderRadius Helpers ====================

  static BorderRadius get borderRadius3 => BorderRadius.circular(radius3);
  static BorderRadius get borderRadius6 => BorderRadius.circular(radius6);
  static BorderRadius get borderRadius8 => BorderRadius.circular(radius8);
  static BorderRadius get borderRadius12 => BorderRadius.circular(radius12);
  static BorderRadius get borderRadius16 => BorderRadius.circular(radius16);
  static BorderRadius get borderRadius24 => BorderRadius.circular(radius24);

  // ==================== EdgeInsets Helpers ====================

  // All
  static EdgeInsets get padding2 => const EdgeInsets.all(spacing2);
  static EdgeInsets get padding4 => const EdgeInsets.all(spacing4);
  static EdgeInsets get padding6 => const EdgeInsets.all(spacing6);
  static EdgeInsets get padding8 => const EdgeInsets.all(spacing8);
  static EdgeInsets get padding12 => const EdgeInsets.all(spacing12);
  static EdgeInsets get padding16 => const EdgeInsets.all(spacing16);
  static EdgeInsets get padding20 => const EdgeInsets.all(spacing20);
  static EdgeInsets get padding24 => const EdgeInsets.all(spacing24);

  // Horizontal
  static EdgeInsets get paddingH4 => const EdgeInsets.symmetric(horizontal: spacing4);
  static EdgeInsets get paddingH8 => const EdgeInsets.symmetric(horizontal: spacing8);
  static EdgeInsets get paddingH12 => const EdgeInsets.symmetric(horizontal: spacing12);
  static EdgeInsets get paddingH16 => const EdgeInsets.symmetric(horizontal: spacing16);
  static EdgeInsets get paddingH20 => const EdgeInsets.symmetric(horizontal: spacing20);
  static EdgeInsets get paddingH24 => const EdgeInsets.symmetric(horizontal: spacing24);

  // Vertical
  static EdgeInsets get paddingV4 => const EdgeInsets.symmetric(vertical: spacing4);
  static EdgeInsets get paddingV8 => const EdgeInsets.symmetric(vertical: spacing8);
  static EdgeInsets get paddingV12 => const EdgeInsets.symmetric(vertical: spacing12);
  static EdgeInsets get paddingV16 => const EdgeInsets.symmetric(vertical: spacing16);
  static EdgeInsets get paddingV20 => const EdgeInsets.symmetric(vertical: spacing20);
  static EdgeInsets get paddingV24 => const EdgeInsets.symmetric(vertical: spacing24);
}

/// 主题颜色集合（light / dark 各一份）
class FigmaThemeColors {
  const FigmaThemeColors({
    // Text Colors
    required this.colorTextPrimaryB0,
    required this.colorTextPrimaryB20,
    required this.colorTextSecondaryB30,
    required this.colorTextRegularB50,
    required this.colorTextNoteB60,
    required this.colorTextSynopsisB70,
    required this.colorTextPrimaryRed,
    required this.colorTextSecondaryRed,
    required this.colorTextLabelBlue,
    // Brand Colors
    required this.colorPrimaryDefault,
    required this.colorPrimaryActive,
    required this.colorPrimaryDisabled,
    required this.colorSecondary,
    // Surface Colors
    required this.colorBgElementB0,
    required this.colorBgElementB30,
    required this.colorBgElementB50,
    required this.colorBgElementB60,
    required this.colorBgElementB70,
    required this.colorBgElementB80,
    required this.colorBgElementB90,
    required this.colorBgElementB96,
    required this.colorBgElementB100,
    required this.colorBgElementB100Light,
    required this.colorBgElementB010,
    required this.colorBgElementB020,
    required this.colorBgToolBarB10080,
    required this.colorBgToastB10050,
    required this.popupWindowBg,
    // Label Colors
    required this.colorBgLabelBlue,
    required this.colorBgLabelRed,
    required this.colorBgLabelGreenLight,
    required this.colorBgLabelGreenDark,
  });

  // ==================== Text Colors ====================

  /// 主要文字 - B0
  final Color colorTextPrimaryB0;

  /// 主要文字 - B20
  final Color colorTextPrimaryB20;

  /// 次要文字 - B30
  final Color colorTextSecondaryB30;

  /// 常规文字 - B50
  final Color colorTextRegularB50;

  /// 注释文字 - B60
  final Color colorTextNoteB60;

  /// 简介 / 占位文字 - B70
  final Color colorTextSynopsisB70;

  /// 主色文字
  final Color colorTextPrimaryRed;

  /// 次主色文字
  final Color colorTextSecondaryRed;

  /// 蓝色标签文字 / 链接
  final Color colorTextLabelBlue;

  // ==================== Brand Colors ====================

  /// 品牌主色
  final Color colorPrimaryDefault;

  /// 主色 - 按下态
  final Color colorPrimaryActive;

  /// 主色 - 禁用态
  final Color colorPrimaryDisabled;

  /// 次主色（选中态、强调）
  final Color colorSecondary;

  // ==================== Surface Colors ====================

  /// 元素背景 - B0
  final Color colorBgElementB0;

  /// 元素背景 - B30
  final Color colorBgElementB30;

  /// 元素背景 - B50
  final Color colorBgElementB50;

  /// 元素背景 - B60
  final Color colorBgElementB60;

  /// 元素背景 - B70
  final Color colorBgElementB70;

  /// 元素背景 - B80（边框、禁用）
  final Color colorBgElementB80;

  /// 元素背景 - B90（分割线）
  final Color colorBgElementB90;

  /// 元素背景 - B96（页面底色）
  final Color colorBgElementB96;

  /// 元素背景 - B100（卡片、导航栏）
  final Color colorBgElementB100;

  /// 元素背景 - B100（暗色下仍偏亮）
  final Color colorBgElementB100Light;

  /// 元素背景 - B0 10% 透明度
  final Color colorBgElementB010;

  /// 元素背景 - B0 20% 透明度
  final Color colorBgElementB020;

  /// 工具栏背景 - B100 80% 透明度（毛玻璃）
  final Color colorBgToolBarB10080;

  /// Toast 背景 - 50% 透明度
  final Color colorBgToastB10050;

  /// 弹窗背景
  final Color popupWindowBg;

  // ==================== Label Colors ====================

  /// 蓝色标签背景
  final Color colorBgLabelBlue;

  /// 红色标签背景
  final Color colorBgLabelRed;

  /// 浅绿色标签背景
  final Color colorBgLabelGreenLight;

  /// 深绿色标签背景
  final Color colorBgLabelGreenDark;
}

/// App 级别的主题颜色：根据 AppThemeMgr.isDarkMode 返回对应主题
FigmaThemeColors get getAppFigmaColors {
  return AppThemeMgr.instance.isDarkMode.value ? FigmaVariables.dark : FigmaVariables.light;
}

/// 与 [getAppFigmaColors] 相同，额外支持 [FigmaVariables.forcedThemeOverride] 局部强制主题
FigmaThemeColors get getFigmaColors => FigmaVariables._of();
