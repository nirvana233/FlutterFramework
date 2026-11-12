// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

// 是否显示设备预览
const bool isShowDevicePreview = kDebugMode && false;

// 是否开启日志
const bool isLog = true;
// 是否开启http日志
const bool isHttpLog = true;

// 是否测试客户端（显示调试按钮、GM 页等）
const bool isTestClient = true;
// 是否测试服务器
const bool isTestServer = true;

// 是否测试模式
bool get isTestMode => isTestClient || false;

String get testServerPrefix => isTestServer ? 'test_' : 'release_';

const String appName = "FlutterFramework";

//Hive typeId（全局唯一，新增必须递增取值，不可复用已占用的 ID）
// 示例：const int exampleCacheTypeId = 1;
