import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Common/Widget/Animation/LoadingView.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// 下拉刷新头部样式枚举
enum RefreshHeaderStyle {
  waterDrop, // Material 水滴样式（默认）
  waterDropUnfollow, // 水滴样式，完全显示后不再跟随内容
  materialClassic, // Material 经典样式
  classic, // 经典文字+图标样式
}

class RefreshStateUtil {
  const RefreshStateUtil._();

  static void finishRefresh(
    RefreshController? controller, {
    required bool success,
    bool resetFooterState = true,
  }) {
    if (controller == null) return;

    if (success) {
      controller.refreshCompleted(resetFooterState: resetFooterState);
    } else {
      controller.refreshFailed();
    }

    // 兜底处理偶发的 header 状态未回收，避免刷新动画残留。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isRefresh) {
        controller.refreshToIdle();
      }
    });
  }

  static void finishLoadMore(
    RefreshController? controller, {
    required bool success,
    bool noMore = false,
  }) {
    if (controller == null) return;

    if (!success) {
      controller.loadFailed();
      return;
    }

    if (noMore) {
      controller.loadNoData();
    } else {
      controller.loadComplete();
    }
  }

  /// 内容未撑满视口时，`hideFooterWhenNotFull` 会藏掉 footer，上拉无法触发。
  /// 布局完成后再看 `maxScrollExtent`：还没溢出且仍有下一页，就直接请求，不经过 footer。
  static void scheduleLoadMoreIfNotFill({
    required bool Function() isMounted,
    required RefreshController controller,
    required bool hasMore,
    required bool isBusy,
    required Future<bool> Function() loadMore,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted() || !hasMore || isBusy) return;
      final position = controller.position;
      if (position == null) return;
      if (position.maxScrollExtent > position.minScrollExtent) return;
      unawaited(loadMore());
    });
  }
}

/// 项目统一的下拉刷新/上拉加载容器。
/// 默认集成刷新头、加载更多 footer 和轻震动反馈，列表页优先复用此组件。
///
/// 使用约定：
/// - 下拉刷新完成后，外部负责调用 `controller.refreshCompleted()`
/// - 上拉加载完成后，外部负责调用 `controller.loadComplete()` / `loadNoData()`
class RefreshLoaderUtil extends StatefulWidget {
  final VoidCallback onRefresh;
  final VoidCallback onLoading;
  final RefreshController controller;
  final bool enablePullDown;
  final bool enablePullUp;
  final Widget child;

  /// 视口外的预布局范围（逻辑像素）；null 时沿用子列表配置。
  /// 直接交给 SmartRefresher，保证其重建列表时保留缓存范围。
  final double? cacheExtent;

  /// Footer 向上偏移的距离，用于避免被底部导航栏或底部悬浮区域遮挡。
  /// 有底部导航的页面通常保持默认值，无底部遮挡时可按需调小。
  final double footerOffset;

  /// 内容未撑满一屏时是否隐藏上拉 footer。详情列表若还有下一页，应关掉以免无法翻页。
  final bool hideFooterWhenNotFull;

  /// 下拉刷新头部样式，默认为水滴样式
  final RefreshHeaderStyle headerStyle;

  const RefreshLoaderUtil({
    super.key,
    required this.onRefresh,
    required this.onLoading,
    required this.controller,
    this.enablePullDown = true,
    this.enablePullUp = true,
    this.cacheExtent,
    this.footerOffset = 60,
    this.hideFooterWhenNotFull = true,
    this.headerStyle = RefreshHeaderStyle.waterDrop,
    required this.child,
  });

  @override
  State<RefreshLoaderUtil> createState() => _RefreshLoaderUtilState();
}

class _RefreshLoaderUtilState extends State<RefreshLoaderUtil> {
  static const double _footerContentHeight = 60;

  /// 根据枚举构建对应的下拉刷新头部
  Widget _buildHeader() {
    switch (widget.headerStyle) {
      case RefreshHeaderStyle.waterDrop:
        return WaterDropMaterialHeader(
          backgroundColor: getAppFigmaColors.colorSecondary,
        );
      case RefreshHeaderStyle.waterDropUnfollow:
        return WaterDropHeader(
          waterDropColor: getAppFigmaColors.colorSecondary,
          refresh: LoadingView(
            width: FigmaVariables.spacing24,
            height: FigmaVariables.spacing24,
            color: getAppFigmaColors.colorPrimaryDefault,
          ),
        );
      case RefreshHeaderStyle.materialClassic:
        return MaterialClassicHeader(
          color: getAppFigmaColors.colorSecondary,
          backgroundColor: getAppFigmaColors.colorBgElementB100Light,
        );
      case RefreshHeaderStyle.classic:
        return ClassicHeader(
          // Refreshing...
          refreshingText: 'refreshing'.tr,
          // Refresh completed
          completeText: 'refresh_completed'.tr,
          // Pull down to refresh
          idleText: 'pull_down_refresh'.tr,
          // Release to refresh
          releaseText: 'release_refresh'.tr,
          // Refresh failed
          failedText: 'refresh_failed'.tr,
          textStyle: const TextStyle(color: Colors.grey),
        );
    }
  }

  /// 构建上拉加载 footer 内容。
  /// 统一处理 idle/loading/failed/noMore 等状态文案与样式。
  Widget _buildFooterContent(LoadStatus? mode) {
    Widget body;
    if (mode == LoadStatus.idle) {
      body = Text('loading_issue_1'.tr, style: const TextStyle(color: Colors.grey));
    } else if (mode == LoadStatus.loading) {
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
    } else if (mode == LoadStatus.failed) {
      body = Text('loading_issue_3'.tr, style: const TextStyle(color: Colors.grey));
    } else if (mode == LoadStatus.canLoading) {
      body = Text('loading_issue_1'.tr, style: const TextStyle(color: Colors.grey));
    } else {
      body = Text('loading_issue_2'.tr, style: const TextStyle(color: Colors.grey));
    }
    return SizedBox(
      height: _footerContentHeight,
      child: Center(child: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration(
      footerTriggerDistance: 80,
      hideFooterWhenNotFull: widget.hideFooterWhenNotFull,
      headerBuilder: () => _buildHeader(),
      footerBuilder: () => CustomFooter(
        height: _footerContentHeight + widget.footerOffset,
        builder: (context, mode) {
          // footer 内容在上方，底部留白用于滚动到导航栏下方
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFooterContent(mode),
              SizedBox(height: widget.footerOffset),
            ],
          );
        },
      ),
      springDescription: const SpringDescription(
        mass: 1,
        stiffness: 364.718677686,
        damping: 35.2,
      ),
      child: SmartRefresher(
        dragStartBehavior: DragStartBehavior.down,
        // 下拉刷新
        enablePullDown: widget.enablePullDown,
        // 上拉加载数据
        enablePullUp: widget.enablePullUp,
        controller: widget.controller,
        cacheExtent: widget.cacheExtent,
        onRefresh: () {
          widget.onRefresh();
          VibrationMgr.instance.selection();
        },
        onLoading: () {
          widget.onLoading();
          VibrationMgr.instance.selection();
        },
        child: widget.child,
      ),
    );
  }
}
