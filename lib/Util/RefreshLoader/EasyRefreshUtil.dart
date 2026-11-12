import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:get/get.dart';

/// EasyRefresh 下拉刷新头部样式枚举。
enum EasyRefreshHeaderStyle {
  materialClassic,
  classic,
}

class EasyRefreshStateUtil {
  const EasyRefreshStateUtil._();

  static void finishRefresh(
    EasyRefreshController? controller, {
    required bool success,
    bool resetFooterState = true,
  }) {
    if (controller == null) return;

    controller.finishRefresh(
      success ? IndicatorResult.success : IndicatorResult.fail,
      true,
    );
    if (resetFooterState) {
      controller.resetFooter();
    }
  }

  static void finishLoadMore(
    EasyRefreshController? controller, {
    required bool success,
    bool noMore = false,
  }) {
    if (controller == null) return;

    if (!success) {
      controller.finishLoad(IndicatorResult.fail, true);
      return;
    }

    controller.finishLoad(
      noMore ? IndicatorResult.noMore : IndicatorResult.success,
      true,
    );
  }

  static void resetNoData(EasyRefreshController? controller) {
    controller?.resetFooter();
  }
}

class EasyRefreshUtil extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onLoad;
  final EasyRefreshController? controller;
  final bool enablePullDown;
  final bool enablePullUp;
  final Widget? child;
  final ERChildBuilder? childBuilder;
  final Color? headerColor;
  final bool showFooter;
  final double footerOffset;
  final EasyRefreshHeaderStyle headerStyle;

  const EasyRefreshUtil({
    super.key,
    required this.onRefresh,
    this.onLoad,
    this.controller,
    this.enablePullDown = true,
    this.enablePullUp = true,
    this.child,
    this.childBuilder,
    this.headerColor,
    this.showFooter = true,
    this.footerOffset = 60,
    this.headerStyle = EasyRefreshHeaderStyle.materialClassic,
  }) : assert(child != null || childBuilder != null);

  @override
  State<EasyRefreshUtil> createState() => _EasyRefreshUtilState();
}

class _EasyRefreshUtilState extends State<EasyRefreshUtil> {
  static const double _footerContentHeight = 60;

  double get _footerHeight => _footerContentHeight + widget.footerOffset;

  Header? _buildHeader() {
    if (!widget.enablePullDown) return null;

    switch (widget.headerStyle) {
      case EasyRefreshHeaderStyle.materialClassic:
        return MaterialHeader(
          backgroundColor: const Color(0xFFFF695B),
          color: widget.headerColor ?? Colors.white,
        );
      case EasyRefreshHeaderStyle.classic:
        return ClassicHeader(
          showMessage: false,
          iconTheme: const IconThemeData(color: Colors.grey),
          textStyle: const TextStyle(color: Colors.grey),
          // Pull down to refresh
          dragText: 'pull_down_refresh'.tr,
          // Release to refresh
          armedText: 'release_refresh'.tr,
          // Refreshing...
          readyText: 'refreshing'.tr,
          // Refreshing...
          processingText: 'refreshing'.tr,
          // Refresh completed
          processedText: 'refresh_completed'.tr,
          // Refresh failed
          failedText: 'refresh_failed'.tr,
        );
    }
  }

  Footer? _buildFooter() {
    if (!widget.enablePullUp) return null;

    return BuilderFooter(
      triggerOffset: _footerHeight,
      clamping: false,
      position: IndicatorPosition.above,
      infiniteOffset: _footerHeight,
      processedDuration: Duration.zero,
      builder: (context, state) {
        if (!widget.showFooter) {
          return SizedBox(height: state.offset);
        }

        return SizedBox(
          height: state.offset,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: _footerHeight,
              child: SizedBox(
                height: _footerHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFooterContent(state),
                    SizedBox(height: widget.footerOffset),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterContent(IndicatorState state) {
    Widget body;
    if (state.result == IndicatorResult.noMore) {
      body = Text('loading_issue_2'.tr, style: const TextStyle(color: Colors.grey));
    } else if (state.result == IndicatorResult.fail) {
      body = Text('loading_issue_3'.tr, style: const TextStyle(color: Colors.grey));
    } else if (state.mode == IndicatorMode.processing || state.mode == IndicatorMode.ready) {
      body = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 25.0,
            height: 25.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Text('error_message_17'.tr, style: const TextStyle(color: Colors.grey)),
        ],
      );
    } else {
      body = Text('loading_issue_1'.tr, style: const TextStyle(color: Colors.grey));
    }

    return SizedBox(
      height: _footerContentHeight,
      child: Center(child: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = _buildHeader();
    final footer = _buildFooter();
    const spring = SpringDescription(
      mass: 1,
      stiffness: 364.718677686,
      damping: 35.2,
    );
    final onRefresh = widget.enablePullDown
        ? () async {
            await widget.onRefresh();
            VibrationMgr.instance.selection();
          }
        : null;
    final onLoad = widget.enablePullUp && widget.onLoad != null
        ? () async {
            await widget.onLoad!();
            VibrationMgr.instance.selection();
          }
        : null;

    if (widget.childBuilder != null) {
      return EasyRefresh.builder(
        controller: widget.controller,
        header: header,
        footer: footer,
        spring: spring,
        onRefresh: onRefresh,
        onLoad: onLoad,
        childBuilder: widget.childBuilder!,
      );
    }

    return EasyRefresh(
      controller: widget.controller,
      header: header,
      footer: footer,
      spring: spring,
      onRefresh: onRefresh,
      onLoad: onLoad,
      child: widget.child!,
    );
  }
}
