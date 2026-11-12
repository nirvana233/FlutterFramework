import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Widget/Animation/LottieAnimationView.dart';
import 'package:flutter_framework/Common/Widget/CommonAppbar.dart';
import 'package:flutter_framework/MainPage/Example/ViewModel/ExampleListController.dart';
import 'package:flutter_framework/MainPage/Example/Widget/ExampleListItem.dart';
import 'package:flutter_framework/Util/Common/NotLoadedUI.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/RefreshLoader/RefreshLoaderUtil.dart';
import 'package:flutter_framework/Util/Router/RouteOpenPage.dart';
import 'package:get/get.dart';

/// 示例列表页：演示「网络请求 + 三态（加载中 / 失败 / 内容）+ 下拉刷新 + 上拉加载」的标准写法
class ExampleListPage extends StatefulWidget {
  const ExampleListPage({super.key, this.arguments});

  final dynamic arguments;

  @override
  State<ExampleListPage> createState() => _ExampleListPageState();
}

class _ExampleListPageState extends State<ExampleListPage> {
  late ExampleListController _controller;
  Map<String, dynamic>? arguments;

  @override
  void initState() {
    super.initState();
    arguments = widget.arguments is Map<String, dynamic>
        ? widget.arguments as Map<String, dynamic>
        : <String, dynamic>{};
    _controller = findGetxController(ExampleListController.new, permanent: false);
    _controller.init(arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: getAppFigmaColors.colorBgElementB96,
        appBar: CommonAppbar(title: 'example_list_title'.tr),
        body: _buildBody(),
      ),
    );
  }

  /// 三态：加载中 → Lottie；失败 → NotLoadedUI 重试；成功 → 列表
  Widget _buildBody() {
    if (_controller.isLoading.value) return const LottieAnimationView();
    if (_controller.hasError.value) {
      return NotLoadedUI(onRefresh: () => _controller.loadData());
    }
    return _buildContent();
  }

  /// 刷新列表
  Widget _buildContent() {
    return RefreshLoaderUtil(
      controller: _controller.refreshController,
      onRefresh: _controller.onRefresh,
      onLoading: _controller.onLoading,
      child: ListView.separated(
        padding: FigmaVariables.padding16,
        itemCount: _controller.dataList.length,
        separatorBuilder: (_, __) => const SizedBox(height: FigmaVariables.spacing12),
        itemBuilder: (context, index) {
          final item = _controller.dataList[index];
          return ExampleListItem(
            item: item,
            onTap: () => toExampleDetailPage(id: item.id ?? 0, title: item.title),
          );
        },
      ),
    );
  }
}
