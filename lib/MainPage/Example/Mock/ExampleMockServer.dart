/// 示例模块的本地 Mock 响应：后端接口未就绪时按真实响应结构返回假数据，
/// 接口联调完成后把 [ExampleService.useMock] 改为 false 即可。
class ExampleMockServer {
  ExampleMockServer._();

  static const int _total = 45;

  /// 模拟 GET [urlExampleList] 的响应体
  static Future<Map<String, dynamic>> exampleList({
    required int pageIndex,
    required int pageSize,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final start = (pageIndex - 1) * pageSize;
    final count = (_total - start).clamp(0, pageSize);
    return {
      'code': 200,
      'msg': '',
      'sysAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'result': {
        'total': _total,
        'list': List.generate(count, (i) {
          final id = start + i + 1;
          return {
            'id': id,
            'title': 'Example item $id',
            'desc': 'This is a mock description for item $id.',
            'cover': 'https://picsum.photos/seed/$id/270/360',
          };
        }),
      },
    };
  }
}
