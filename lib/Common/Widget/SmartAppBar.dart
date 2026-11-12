import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';

/// 智能 AppBar：在标准 [AppBar] API 上修复 Android 10 刘海识别失效。
///
/// 二级页优先用 [CommonAppbar]；需要 actions / bottom / 自定义 title 时再直接用本组件。
///
/// ## `primary` 与定制布局
/// - `primary: true`（默认）：本组件负责顶部安全区。Android 10 上 [preferredSize]
///   会额外加上 [smartTopSafeHeight]，build 时在系统 padding 异常时手动补 top。
/// - `primary: false`：外层已预留状态栏/刘海（或嵌在自定义 appBar Column 中），
///   不再叠加安全区高度与手动 padding。嵌套示例与 [CommonAppbar] 文档一致。
///
/// 顶部安全区请用 [topSafeHeightOf] / [smartTopSafeHeight]（见 DeviceUtil），
/// 不要裸写 `MediaQuery.padding.top` 或普通 [SafeArea]。
class SmartAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SmartAppBar({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.backgroundColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
    this.toolbarHeight,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
  });

  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;

  /// 是否由本 AppBar 处理顶部安全区。定制外层布局时传 false，见类注释。
  final bool primary;
  final bool? centerTitle;
  final bool excludeHeaderSemantics;
  final double? titleSpacing;
  final double toolbarOpacity;
  final double bottomOpacity;
  final double? toolbarHeight;
  final double? leadingWidth;
  final TextStyle? toolbarTextStyle;
  final TextStyle? titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;

  @override
  Size get preferredSize {
    final double height = toolbarHeight ?? kToolbarHeight;
    final double bottomHeight = bottom?.preferredSize.height ?? 0.0;
    // primary 为 false 时顶部安全区由外层处理，不再叠加刘海高度
    if (primary && DeviceUtil.instance.isAndroid10) {
      // 添加可能的刘海高度，会在 build 时动态调整
      final double topPadding = smartTopSafeHeight;
      return Size.fromHeight(height + bottomHeight + topPadding);
    }
    return Size.fromHeight(height + bottomHeight);
  }

  @override
  State<SmartAppBar> createState() => _SmartAppBarState();
}

class _SmartAppBarState extends State<SmartAppBar> {
  @override
  Widget build(BuildContext context) {
    // 检查是否需要修复刘海（仅 Android 10 刘海识别失效、且本 AppBar 负责顶部安全区时）
    // 渲染期实时取值：修复启动期 immersive 状态栏隐藏导致缓存回落到兜底 28 的问题
    final systemTopPadding = MediaQuery.of(context).padding.top;
    final fixedTopPadding = topSafeHeightOf(context);
    final needsFix =
        widget.primary &&
        (fixedTopPadding - systemTopPadding).abs() > 5 &&
        DeviceUtil.instance.isAndroid10;

    // 正常情况使用标准 AppBar（Flutter 自动处理安全区）
    if (!needsFix) {
      return AppBar(
        key: widget.key,
        leading: widget.leading,
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        title: widget.title,
        actions: widget.actions,
        flexibleSpace: widget.flexibleSpace,
        bottom: widget.bottom,
        elevation: widget.elevation,
        scrolledUnderElevation: widget.scrolledUnderElevation,
        shadowColor: widget.shadowColor,
        surfaceTintColor: widget.surfaceTintColor,
        shape: widget.shape,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        iconTheme: widget.iconTheme,
        actionsIconTheme: widget.actionsIconTheme,
        primary: widget.primary,
        centerTitle: widget.centerTitle,
        excludeHeaderSemantics: widget.excludeHeaderSemantics,
        titleSpacing: widget.titleSpacing,
        toolbarOpacity: widget.toolbarOpacity,
        bottomOpacity: widget.bottomOpacity,
        toolbarHeight: widget.toolbarHeight,
        leadingWidth: widget.leadingWidth,
        toolbarTextStyle: widget.toolbarTextStyle,
        titleTextStyle: widget.titleTextStyle,
        systemOverlayStyle: widget.systemOverlayStyle,
      );
    }

    // Android 10 刘海屏修复：使用自定义 AppBar
    return Container(
      padding: EdgeInsets.only(top: fixedTopPadding),
      color: widget.backgroundColor ?? Colors.white,
      child: AppBar(
        key: widget.key,
        leading: widget.leading,
        automaticallyImplyLeading: false, // 手动处理 leading
        title: widget.title,
        actions: widget.actions,
        flexibleSpace: widget.flexibleSpace,
        bottom: widget.bottom,
        elevation: widget.elevation,
        scrolledUnderElevation: widget.scrolledUnderElevation,
        shadowColor: widget.shadowColor,
        surfaceTintColor: widget.surfaceTintColor,
        shape: widget.shape,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        iconTheme: widget.iconTheme,
        actionsIconTheme: widget.actionsIconTheme,
        primary: false, // 已手动处理安全区
        centerTitle: widget.centerTitle,
        excludeHeaderSemantics: widget.excludeHeaderSemantics,
        titleSpacing: widget.titleSpacing,
        toolbarOpacity: widget.toolbarOpacity,
        bottomOpacity: widget.bottomOpacity,
        toolbarHeight: widget.toolbarHeight,
        leadingWidth: widget.leadingWidth,
        toolbarTextStyle: widget.toolbarTextStyle,
        titleTextStyle: widget.titleTextStyle,
        systemOverlayStyle: widget.systemOverlayStyle,
      ),
    );
  }
}
