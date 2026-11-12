import 'package:flutter/material.dart';
import 'package:flutter_framework/Base/BaseLessWidget.dart';
import 'package:flutter_framework/Common/Widget/Button/ButtonBigRed.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

/// 通用空态与加载失败提示，支持页面传入插图、文案和重试操作。
class NotLoadedUI extends BaseLessWidget {
  final VoidCallback? onRefresh;
  final double topPadding;
  final double width;
  final double height;
  final String? message;

  /// 仅用于无重试操作的空态文案，未传时沿用默认样式。
  final TextStyle? messageStyle;
  final EdgeInsetsGeometry? messagePadding;
  final String? iconPath;
  final VoidCallback? messageBtnCallback;
  final String? messageBtnText;

  /// [NotLoadedUI] 加载状态显示组件。
  ///
  /// **使用场景：**
  ///
  /// | 场景 | 用法 |
  /// |------|------|
  /// | 网络/服务器异常（非200、请求失败） | 传 [onRefresh]，显示错误提示 + 重试按钮 |
  /// | 接口正常但数据为空（空状态）       | 传 [message]，不传按钮相关参数，无按钮 |
  /// | 空状态 + 自定义跳转按钮           | 传 [message] + [messageBtnCallback] + [messageBtnText] |
  ///
  /// **判断网络/服务器异常的依据：**
  /// - 请求抛出异常（catch 捕获）
  /// - 接口返回非 200 状态码（controller 层返回 null）
  ///
  /// **参数说明：**
  /// * [onRefresh]: 用于网络报错或者服务器报错，没有获取到数据的情况（加载失败）；与 [messageBtnCallback] 互斥。
  /// * [messageBtnCallback]: 用于单纯没有获取到服务器数据（空状态）的情况，此回调可选；与 [onRefresh] 互斥。
  /// * [messageBtnText]: [messageBtnCallback] 对应的按钮文本，可选。
  /// * [message]: 提示信息。在没有 [onRefresh] 的情况下，此参数为必传参数。
  ///
  /// 注意：[onRefresh] 和 [messageBtnCallback] 系列参数之间是互斥的。
  const NotLoadedUI({
    super.key,
    this.onRefresh,
    this.topPadding = 0.0,
    this.width = 140,
    this.height = 140,
    this.message,
    this.messageStyle,
    this.messagePadding,
    this.iconPath,
    this.messageBtnCallback,
    this.messageBtnText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: width,
                height: height,
                child: Builder(
                  builder: (context) {
                    final path = iconPath ?? 'assets/images/common/placeholder_no_result.png';
                    if (path.endsWith('.png')) {
                      return Image.asset(
                        path,
                        width: width,
                        height: height,
                      );
                    }
                    return SvgPicture.asset(
                      path,
                      width: width,
                      height: height,
                    );
                  },
                ),
              ),
              // 空状态 / 仅 message：无 onRefresh 时单独展示（与下方重试区互斥，避免重复）。
              if (isAvailable(message) && onRefresh == null)
                Padding(
                  padding: messagePadding ?? const EdgeInsets.only(top: 20, bottom: 20),
                  child: Text(
                    message ?? '',
                    textAlign: TextAlign.center,
                    style:
                        messageStyle ??
                        const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                  ),
                ),
              if (isAvailable(messageBtnCallback))
                IntrinsicWidth(
                  child: ButtonBigRed(
                    content: messageBtnText ?? '',
                    onTap: () {
                      messageBtnCallback?.call();
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              // 加载失败：有自定义 message（如服务端 msg+[code]）则优先展示；否则通用网络文案。
              if (onRefresh != null)
                Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            isAvailable(message) ? message! : 'connect_issue'.tr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (!isAvailable(message)) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'tap_button'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        IntrinsicWidth(
                          child: ButtonBigRed(
                            content: 'try_again'.tr,
                            onTap: () {
                              onRefresh?.call();
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );

          // 先保留父级宽度约束让多语言文案正常换行，再只在高度不足时整体缩放。
          final widthConstrainedContent = constraints.hasBoundedWidth
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: content,
                )
              : content;
          if (!constraints.hasBoundedHeight) return widthConstrainedContent;
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: widthConstrainedContent,
          );
        },
      ),
    );
  }
}
