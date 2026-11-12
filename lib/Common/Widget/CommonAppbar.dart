import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Widget/CommonBackButton.dart';
import 'package:flutter_framework/Common/Widget/SmartAppBar.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';

/// 通用 AppBar 组件
///
/// 基于 [SmartAppBar]，自动处理 Android 10 刘海屏；默认样式统一（居中标题、无 elevation）。
///
/// ## 常规用法
/// ```dart
/// appBar: CommonAppbar(title: 'xxx'.tr),
/// ```
///
/// ## 在标题栏上方/下方挂自定义内容（横幅、提示条等）
/// 不要直接把横幅叠在 [CommonAppbar] 外面却仍用默认 `primary: true`：
/// - Android 10 上 [SmartAppBar] 会再叠加顶部安全区，外层 [PreferredSize] 高度若
///   只写 `kToolbarHeight + banner` 会裁切工具栏，返回箭头被状态栏压住。
///
/// 推荐：外层统一处理安全区，工具栏传 `primary: false`。
///
/// ```dart
/// // 结构：状态栏安全区 → 可选横幅（标题栏上方）→ 工具栏
/// // 参考：ProfileEditPage 邮箱验证横幅
/// final topSafe = topSafeHeightOf(context); // DeviceUtil.dart
/// final bannerH = showBanner ? 40.0 : 0.0;
/// appBar: PreferredSize(
///   preferredSize: Size.fromHeight(topSafe + bannerH + kToolbarHeight),
///   child: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       SizedBox(height: topSafe),
///       if (showBanner) bannerWidget,
///       CommonAppbar(title: 'xxx'.tr, primary: false),
///     ],
///   ),
/// ),
/// ```
///
/// - 横幅在**标题栏下方**：`CommonAppbar(primary: false)` 放 Column 第一项，横幅第二项。
/// - 高度必须与 Column 真实子节点之和一致；Android 10 顶部安全区用 [topSafeHeightOf] /
///   [smartTopSafeHeight]，不要裸用 `MediaQuery.padding.top`。
class CommonAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  /// 是否由本组件处理顶部状态栏/刘海安全区。
  ///
  /// - `true`（默认）：作为 `Scaffold.appBar` 单独使用时，与 [SmartAppBar] 一致，
  ///   Android 10 会在高度与布局上叠加修正后的顶部安全区。
  /// - `false`：父级已用 `SizedBox(height: topSafeHeightOf(context))` 等预留安全区，
  ///   或把本组件嵌在自定义 [PreferredSize] / Column 里时使用，避免双重 top padding。
  ///   此时 [preferredSize] 仅为 [kToolbarHeight]，不再加刘海高度。
  final bool primary;

  const CommonAppbar({
    super.key,
    required this.title,
    this.backgroundColor,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = getAppFigmaColors;
    final bgColor = backgroundColor ?? colors.colorBgElementB100;

    return SmartAppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      primary: primary,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading:
          leading ??
          (Navigator.canPop(context) && automaticallyImplyLeading
              ? const CommonBackButton(size: 20)
              : null),
      title: Text(
        title,
        style: TextStyle(
          color: colors.colorTextPrimaryB0,
          fontSize: FigmaVariables.fontSize20,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize {
    // 与 SmartAppBar 的 Android 10 尺寸保持一致：内部会额外叠加顶部安全区，
    // 若此处仍固定 kToolbarHeight，Scaffold 分配高度不足会切掉工具栏，箭头被状态栏压住。
    // primary == false 时安全区由外层负责，高度仅保留工具栏本身。
    if (primary && DeviceUtil.instance.isAndroid10) {
      return Size.fromHeight(kToolbarHeight + smartTopSafeHeight);
    }
    return const Size.fromHeight(kToolbarHeight);
  }
}
