import 'package:flutter_framework/Util/Const.dart';

// 内网测试
const String innerTestUrl = "https://inner-test.example.com";
// 仿真测试（公网 sim）
const String simTestUrl = "https://sim-api.example.com";
// 当前测试服（可变，GM 可在内网/仿真间切换）
String testUrl = simTestUrl;

// 启动时用于拉取动态域名的入口地址
String initialUrl = "https://app.example.com";
// 正式服
String productUrl = "https://api.example.com";
// 正式服备用（DNS 解析失败时切换）
String productUrlApi = "https://api-backup.example.com";

//获取baseUrl
String get baseUrl => isTestServer ? testUrl : productUrl;
String get initBaseUrl => isTestServer ? testUrl : initialUrl;

/// 是否启用「启动时从云端拉取动态域名」（见 AppMgr.getDomain）
/// 关闭时直接使用 [baseUrl]
const bool isEnableCloudDomain = false;

///============================ 接口路径 ============================
/// 新增接口按模块分组，统一在此定义，禁止在业务代码中硬编码路径

///动态域名
const String urlCloudRouteDomain = "/cloud/route/domain";

///示例模块（MainPage/Example）
const String urlExampleList = "/example/list";

/// 正式包不打印响应体的接口（响应过大或含敏感数据），测试包仍完整打印
const Map<String, bool> apiNotPrintMap = {};
