import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Model/CommonModel.dart';
import 'package:flutter_framework/Util/Common/ApiConfig.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/Const.dart';
import 'package:flutter_framework/Util/EventBusUtil/EventBusModel.dart';

class AppMgr {
  static AppMgr? _instance;
  static AppMgr get instance => _instance ??= AppMgr._();
  AppMgr._();

  BuildContext? appContext;

  void init() {
    // 初始化App管理器
  }

  /// 获取域名：未开启 [isEnableCloudDomain] 时直接返回 [baseUrl]；
  /// 开启后优先读缓存，其次请求 `initBaseUrl + urlCloudRouteDomain` 拉取，失败兜底 [baseUrl]
  Future<String> getDomain() async {
    if (!isEnableCloudDomain) {
      return baseUrl;
    }
    String domin = PreferenceUtil.instance.getDomain() ?? "";
    if (isAvailable(domin)) {
      logW('Cached domain: $domin');
      // 与云端拉取成功时一致：同步内存 baseUrl 来源，避免冷启动后 Dio 已切换但 testUrl/直接 baseUrl 仍是默认值
      if (isTestServer) {
        testUrl = domin;
      } else {
        productUrl = domin;
      }
      return domin;
    }

    // 使用 Dio 发起请求，复用同一 client；validateStatus 放行所有状态码，
    // 由业务层判断 statusCode，避免非 2xx 被当作异常上报并丢失重试分支
    final url = '$initBaseUrl$urlCloudRouteDomain';
    final deviceId = await DeviceUtil.getDeviceId();
    final client = dio.Dio(
      dio.BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: dio.ResponseType.json,
        validateStatus: (_) => true,
        headers: {
          "deviceId": deviceId,
        },
      ),
    );

    // 最多重试 3 次，失败后返回 baseUrl
    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        logP('Fetch domain ===>>> $url (attempt ${attempt + 1})');
        final response = await client.get(url);
        logP('Fetch domain response <<<=== ${response.data}');

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            CommonModel model = CommonModel.fromJson(data);
            if (model.code == 200) {
              var url = model.result;
              if (isAvailable(url)) {
                if (isTestServer) {
                  testUrl = url!;
                } else {
                  productUrl = url!;
                }
                logW('Fetched new domain: $url');
                await PreferenceUtil.instance.setDomain(url!);
                return url!;
              }
            }
          }
        }
        // 响应异常，等待后重试
        logW('getDomain unexpected response, statusCode: ${response.statusCode}');
        if (attempt < maxRetries - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        logE('AppMgr: getDomain exception: $e');
        // 检查是否是 DNS 解析失败
        final isDnsError = e.toString().contains('Failed host lookup');

        // 检查是否是 DNS 解析失败，且当前是正式服环境
        // 如果是，则切换到备用域名 productUrlApi
        if (!isTestServer && isDnsError && productUrl != productUrlApi) {
          logW('DNS lookup failed, switch to fallback domain: $productUrlApi');
          productUrl = productUrlApi;
        }
        if (attempt < maxRetries - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    logW('getDomain failed after $maxRetries attempts, using default domain: $baseUrl');
    return baseUrl;
  }

  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // logP('didChangeAppLifecycleState: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        eventBusUtil.dispose();
        break;
      case AppLifecycleState.hidden:
        break;
    }
    eventBusUtil.fire(
      EventBusModelAppLifecycleStateChange(
        appLifecycleState: state,
      ),
    );
  }
}
