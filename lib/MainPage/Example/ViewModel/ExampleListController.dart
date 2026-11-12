import 'package:flutter_framework/MainPage/Example/Model/ExampleModel.dart';
import 'package:flutter_framework/MainPage/Example/ViewModel/ExampleService.dart';
import 'package:flutter_framework/Util/RefreshLoader/RefreshLoaderUtil.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// 示例列表页状态：首次加载 / 下拉刷新 / 上拉加载更多 / 空态 / 错误态
class ExampleListController extends GetxController {
  static const int pageSize = 15;

  final RefreshController refreshController = RefreshController();

  final RxList<ExampleItem> dataList = <ExampleItem>[].obs;

  /// 首次加载中（展示整页 loading）
  final RxBool isLoading = true.obs;

  /// 首次加载失败（展示错误态 + 重试）
  final RxBool hasError = false.obs;

  int _pageIndex = 1;
  bool _hasMore = true;

  Future<void> init({Map<String, dynamic>? arguments}) async {
    await loadData();
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }

  /// 首次加载 / 错误态重试
  Future<void> loadData() async {
    isLoading.value = true;
    hasError.value = false;
    final success = await _fetch(pageIndex: 1);
    isLoading.value = false;
    hasError.value = !success && dataList.isEmpty;
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    final success = await _fetch(pageIndex: 1);
    RefreshStateUtil.finishRefresh(refreshController, success: success);
  }

  /// 上拉加载更多
  Future<void> onLoading() async {
    if (!_hasMore) {
      RefreshStateUtil.finishLoadMore(refreshController, success: true, noMore: true);
      return;
    }
    final success = await _fetch(pageIndex: _pageIndex + 1);
    RefreshStateUtil.finishLoadMore(refreshController, success: success, noMore: !_hasMore);
  }

  Future<bool> _fetch({required int pageIndex}) async {
    final result = await ExampleService.getExampleList(pageIndex: pageIndex, pageSize: pageSize);
    if (result == null) {
      return false;
    }
    final list = result.list ?? [];
    if (pageIndex == 1) {
      dataList.assignAll(list);
    } else {
      dataList.addAll(list);
    }
    _pageIndex = pageIndex;
    _hasMore = list.length >= pageSize && dataList.length < (result.total ?? 0);
    return true;
  }
}
