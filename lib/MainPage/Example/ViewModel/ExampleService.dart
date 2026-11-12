import 'package:flutter_framework/MainPage/Example/Mock/ExampleMockServer.dart';
import 'package:flutter_framework/MainPage/Example/Model/ExampleModel.dart';
import 'package:flutter_framework/Util/Common/ApiConfig.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/NetWorkManager/NetWorkManagerUtil.dart';

/// 示例模块接口层：只负责请求与解析，不持有页面状态
class ExampleService {
  ExampleService._();

  /// 是否使用本地 Mock 数据（后端接口就绪后改为 false）
  static const bool useMock = true;

  /// 获取示例列表（查询类接口：失败只打日志返回 null，由页面渲染错误态）
  static Future<ExampleResult?> getExampleList({
    required int pageIndex,
    required int pageSize,
  }) async {
    try {
      final Map<String, dynamic>? data;
      if (useMock) {
        data = await ExampleMockServer.exampleList(pageIndex: pageIndex, pageSize: pageSize);
      } else {
        final response = await NetWorkManagerUtil.instance.get(
          urlExampleList,
          params: {'pageIndex': pageIndex, 'pageSize': pageSize},
        );
        data = response.statusCode == 200 && response.data is Map<String, dynamic>
            ? response.data
            : null;
      }
      if (data == null) {
        logW('getExampleList http error');
        return null;
      }
      final model = ExampleModel.fromJson(data);
      if (model.code == 200) {
        return model.result;
      }
      logW('getExampleList business error: ${model.msg} [${model.code}]');
    } catch (e) {
      logE('getExampleList error: $e');
    }
    return null;
  }
}
