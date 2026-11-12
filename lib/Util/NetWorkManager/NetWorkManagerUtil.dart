import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart' as dio;
import 'package:dio/io.dart';
import 'package:flutter_framework/Common/Config/ClientErrorCode.dart';
import 'package:flutter_framework/Common/Config/ServerErrorCode.dart';
import 'package:flutter_framework/Common/Manager/RegisterControllerMgr.dart';
import 'package:flutter_framework/Common/Manager/TimeMgr.dart';
import 'package:flutter_framework/MainPage/Language/ViewModel/LanguageViewModel.dart';
import 'package:flutter_framework/Util/Common/ApiConfig.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/Const.dart';
import 'package:flutter_framework/Util/EventBusUtil/EventBusModel.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retry/retry.dart';

typedef ProgressCallback = void Function(int count, int total);

class NetWorkManagerUtil extends GetxController {
  static NetWorkManagerUtil? _instance;
  NetWorkManagerUtil._internal();
  static NetWorkManagerUtil get instance => _instance ??= NetWorkManagerUtil._internal();

  late dio.BaseOptions baseOptions;
  late dio.Dio _dio;
  late dio.CancelToken? _cancelToken;
  late dio.CancelToken? _downLoadCancelToken;

  static HttpClient? _sharedHttpClient;
  bool isInitialized = false;

  /// GM：网络响应日志是否 format JSON（默认关闭；initDio 从本地同步）
  bool isHttpResponseFormatJson = false;

  /// 同步内存开关并落本地
  Future<void> setHttpResponseFormatJson(bool value) async {
    isHttpResponseFormatJson = value;
    await PreferenceUtil.instance.setHttpResponseFormatJson(value);
  }

  /// 请求日志是否拼接 baseUrl 打印完整 URL
  static const bool isHttpLogFullUrl = true;

  /// 等待初始化完成的 Completer
  Completer<void>? _initCompleter;

  // 图片缓存目录路径
  Directory? _imageCacheDir;

  bool get needFullStackTrace => isTestClient && false;

  /// 等待 Dio 初始化完成
  /// 所有网络请求调用前需要先调用此方法确保 Dio 已初始化
  Future<void> ensureInitialized() async {
    if (isInitialized) return;
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    // 如果没有初始化且没有正在进行的初始化，等待初始化
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return !isInitialized;
    });
  }

  // 初始化 Dio (需要传入已获取的 domain)
  Future<void> initDio(String domain) async {
    if (isInitialized) return;
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<void>();

    try {
      baseOptions = await initBaseOptions(domain);
      _dio = dio.Dio(baseOptions);

      _downLoadCancelToken = dio.CancelToken();
      // 配置优化的HttpClient适配器
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        return _getOptimizedHttpClient();
      };

      // 初始化图片缓存目录
      await _initImageCacheDir();

      // 从本地同步响应日志 format 开关到内存
      isHttpResponseFormatJson = PreferenceUtil.instance.getHttpResponseFormatJson();

      isInitialized = true;
      _initCompleter!.complete();
      logP('Dio 初始化完成，baseUrl: $domain');
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  // 初始化图片缓存目录
  Future<void> _initImageCacheDir() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _imageCacheDir = Directory('${tempDir.path}/image_cache');
      if (!_imageCacheDir!.existsSync()) {
        await _imageCacheDir!.create(recursive: true);
        logD('图片缓存目录已创建: ${_imageCacheDir!.path}');
      }
    } catch (e) {
      logE('Init image cache directory failed: $e');
    }
  }

  // 创建优化的HttpClient
  static HttpClient _getOptimizedHttpClient() {
    if (_sharedHttpClient != null) {
      return _sharedHttpClient!;
    }

    _sharedHttpClient = HttpClient();

    // 连接池优化 - 针对移动应用优化的参数
    _sharedHttpClient!.maxConnectionsPerHost = 6; // 移动设备推荐4个连接（平衡性能和资源）
    _sharedHttpClient!.connectionTimeout = const Duration(seconds: 15); // 连接建立超时
    _sharedHttpClient!.idleTimeout = const Duration(seconds: 60); // 空闲连接保持60秒（移动网络切换频繁）

    // TLS优化
    // 禁止全局信任任意 TLS 证书。测试环境若确需自签名证书，应仅对白名单域名放行。
    // _sharedHttpClient!.badCertificateCallback = (
    //   X509Certificate cert,
    //   String host,
    //   int port,
    // ) {
    //   return true;
    // };

    // logD("HttpClient优化配置完成：连接池大小4，连接超时10s，空闲保持60s");
    return _sharedHttpClient!;
  }

  String _requestLogUrl(String url) {
    if (!isHttpLogFullUrl || url.startsWith('http://') || url.startsWith('https://')) return url;
    if (!isInitialized) return url;
    return '${baseOptions.baseUrl}$url';
  }

  /// 请求入口 log 时序：测试包先打再 init（await 前堆栈更全）；正式包先 init 再打（与旧行为一致）。
  /// [log] 内自行判断 [isHttpLog] 并调用 [logD]；未开日志时直接返回。
  Future<void> _logRequestStart(void Function() log) async {
    if (!isHttpLog) return;
    if (needFullStackTrace) {
      log();
      return;
    }
    await ensureInitialized();
    log();
  }

  /// 动态更新 baseUrl（domain 获取后调用）
  void updateBaseUrl(String newDomain) {
    if (isInitialized && baseOptions.baseUrl != newDomain) {
      baseOptions.baseUrl = newDomain;
      logW('Dio baseUrl updated: $newDomain');
    }
  }

  Future<dio.BaseOptions> initBaseOptions(String domain) async {
    Map<String, dynamic> headers = await getHeader();

    // 添加连接优化相关头部
    headers.addAll({
      'Connection': 'keep-alive',
      'Keep-Alive': 'timeout=30, max=100',
      // 支持HTTP/2
      'Upgrade-Insecure-Requests': '1',
    });

    dio.BaseOptions baseOptions = dio.BaseOptions(
      baseUrl: domain,
      connectTimeout: const Duration(seconds: 15), // 与HttpClient保持一致
      sendTimeout: const Duration(seconds: 15), // 发送请求数据超时（小说应用请求体较小）
      receiveTimeout: const Duration(seconds: 20), // 接收响应超时（考虑章节内容可能较大）
      headers: headers,
      // contentTypes: 'application/json; charset=utf-8',
      responseType: dio.ResponseType.json,
      // 启用持久连接
      persistentConnection: true,
      // 启用请求/响应压缩
      followRedirects: true,
      maxRedirects: 3,
    );

    return baseOptions;
  }

  Future<void> refreshBaseOptions({int? resetTime}) async {
    baseOptions.headers = await getHeader();
    if (isAvailable(resetTime)) {
      baseOptions.connectTimeout = Duration(seconds: resetTime!);
      baseOptions.sendTimeout = Duration(seconds: resetTime);
      baseOptions.receiveTimeout = Duration(seconds: resetTime);
    }
  }

  /// 公共请求头。新项目按后端约定在这里增删字段（签名、渠道号等）。
  static Future<Map<String, dynamic>> getHeader() async {
    String? deviceId = await DeviceUtil.getDeviceId();
    PackageInfo packageInfo = await DeviceUtil.instance.getPackageInfo();
    final deviceLocale = LanguageViewModel.instance.deviceLocale;
    final Map<String, dynamic> headers = {
      "Content-Type": "application/json",
      //平台
      "platform": GetPlatform.isIOS ? "ios" : "android",
      //App 界面语言
      "language": LanguageViewModel.instance.appLanguage.value.languageCode,
      //设备语言
      "mobileLanguage": "${deviceLocale.languageCode}_${deviceLocale.countryCode}",
      "timestamp": getTimeSeconds(),
      "deviceId": deviceId,
      "Authorization": "Bearer ${PreferenceUtil.instance.getToken() ?? ""}",
      'version': packageInfo.version,
      //时区名
      'timeZone': DateTime.now().timeZoneName,
    };

    return headers;
  }

  // 判断是否应该重试的方法
  static bool _shouldRetry(Exception e) {
    if (e is dio.DioException) {
      // 网络连接错误、超时等情况需要重试
      return e.type == dio.DioExceptionType.connectionTimeout ||
          e.type == dio.DioExceptionType.sendTimeout ||
          e.type == dio.DioExceptionType.receiveTimeout ||
          e.type == dio.DioExceptionType.connectionError ||
          (e.type == dio.DioExceptionType.unknown && e.error is SocketException);
    }
    // 其他异常也可以重试
    return e is SocketException || e is HttpException;
  }

  // 执行带重试的网络请求
  Future<dio.Response> _executeWithRetry(
    Future<dio.Response> Function() operation,
    int retryTimes,
    String url,
  ) async {
    final r = RetryOptions(
      maxAttempts: retryTimes + 1,
      delayFactor: const Duration(seconds: 1), // 初始延迟1秒
      maxDelay: const Duration(seconds: 10), // 最大延迟10秒
      randomizationFactor: 0.25, // 添加25%的随机化，避免雷鸣群效应
    );

    try {
      return await r.retry(
        operation,
        retryIf: (e) => _shouldRetry(e),
        onRetry: (e) => {
          if (isHttpLog) {logW("Network request retrying... $url error: $e")},
        },
      );
    } catch (e) {
      if (isHttpLog) {
        logE("<<<=== Network request failed, retried $retryTimes times: $url $e");
      }
      return dio.Response(
        statusCode: ClientErrorCode.networkRequestFailed,
        data: {'error': e.toString()},
        requestOptions: dio.RequestOptions(path: url),
      );
    }
  }

  // get 请求
  Future<dio.Response> get(
    String url, {
    required Map<String, dynamic> params,
    ProgressCallback? onReceiveProgress,
    int retryTimes = 0,
    Duration? customReceiveTimeout,
  }) async {
    await _logRequestStart(() {
      logD("===>>> ${_requestLogUrl(url)}   params: $params");
    });
    await ensureInitialized();
    await refreshBaseOptions();

    operation() async {
      final response = await _dio.get(
        url,
        queryParameters: params,
        cancelToken: _cancelToken = dio.CancelToken(),
        onReceiveProgress: onReceiveProgress,
        options: customReceiveTimeout != null
            ? dio.Options(receiveTimeout: customReceiveTimeout)
            : null,
      );
      return parseResponse(response, url);
    }

    return await _executeWithRetry(operation, retryTimes, url);
  }

  // post 请求
  Future<dio.Response> post(
    String url, {
    required Map<String, dynamic> params,
    Map<String, dynamic>? logParams,
    ProgressCallback? onReceiveProgress,
    int retryTimes = 0,
    Duration? customReceiveTimeout,
    bool returnHttpErrorResponse = false,
  }) async {
    await _logRequestStart(() {
      logD("===>>> ${_requestLogUrl(url)}   params: ${logParams ?? params}");
    });
    await ensureInitialized();
    await refreshBaseOptions();

    operation() async {
      dio.Response response = await _dio.post(
        url,
        data: params,
        cancelToken: _cancelToken = dio.CancelToken(),
        onReceiveProgress: onReceiveProgress,
        options: customReceiveTimeout != null || returnHttpErrorResponse
            ? dio.Options(
                receiveTimeout: customReceiveTimeout,
                validateStatus: returnHttpErrorResponse ? (_) => true : null,
              )
            : null,
      );
      return parseResponse(response, url);
    }

    return await _executeWithRetry(operation, retryTimes, url);
  }

  // put 请求
  Future<dio.Response> put(
    String url, {
    required Map<String, dynamic> data,
    int retryTimes = 0,
  }) async {
    await _logRequestStart(() {
      logD("===>>> ${_requestLogUrl(url)}   data: $data");
    });
    await ensureInitialized();
    await refreshBaseOptions();

    operation() async {
      final response = await _dio.put(
        url,
        data: data,
        cancelToken: _cancelToken = dio.CancelToken(),
      );
      return parseResponse(response, url);
    }

    return await _executeWithRetry(operation, retryTimes, url);
  }

  // delete 请求
  Future<dio.Response> delete(String url, {int retryTimes = 0}) async {
    await _logRequestStart(() {
      logD("===>>> ${_requestLogUrl(url)}");
    });
    await ensureInitialized();
    await refreshBaseOptions();

    operation() async {
      final response = await _dio.delete(url, cancelToken: _cancelToken = dio.CancelToken());
      return parseResponse(response, url);
    }

    return await _executeWithRetry(operation, retryTimes, url);
  }

  // 单文件上传请求
  Future<dio.Response> uploadFileSingle(
    String url,
    String filePath, {
    Map<String, dynamic>? extraData,
    ProgressCallback? onSendProgress,
    int? timeoutSeconds,
  }) async {
    return uploadFileMultiple(
      url,
      [filePath],
      extraData: extraData,
      onSendProgress: onSendProgress,
      timeoutSeconds: timeoutSeconds ?? 60,
    );
  }

  // 多文件上传请求
  /// 字段名默认 `files`，与后端约定不一致时传 [fileFieldName]
  Future<dio.Response> uploadFileMultiple(
    String url,
    List<String> filePaths, {
    String fileFieldName = 'files',
    Map<String, dynamic>? extraData,
    ProgressCallback? onSendProgress,
    int? timeoutSeconds,
  }) async {
    await ensureInitialized();
    await refreshBaseOptions(resetTime: timeoutSeconds ?? 60);
    try {
      // 创建FormData
      dio.FormData formData = dio.FormData();

      // 添加额外的表单字段（用于@ModelAttribute FileUploadDTO）
      if (extraData != null) {
        extraData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      // 添加所有文件
      for (String filePath in filePaths) {
        formData.files.add(
          MapEntry(
            fileFieldName,
            await dio.MultipartFile.fromFile(filePath),
          ),
        );
      }

      final uploadOptions = dio.Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      );

      // logD('net_work_manager: 文件上传请求 headers: ${uploadOptions.headers}');

      logD("===>>> ${_requestLogUrl(url)}, formData: $formData");

      return parseResponse(
        await _dio.post(
          url,
          data: formData,
          queryParameters: extraData,
          options: uploadOptions,
          cancelToken: dio.CancelToken(),
          onSendProgress: onSendProgress,
        ),
        url,
      );
    } catch (e) {
      logE('NetWorkManagerUtil: uploadFileMultiple exception: $e');
      return dio.Response(
        statusCode: 500,
        data: {'error': e.toString()},
        requestOptions: dio.RequestOptions(path: url),
      );
    }
  }

  Future<dio.Response> postFile(
    String url, {
    required Map<String, dynamic> parameters,
    ProgressCallback? onReceiveProgress,
    Duration? cacheDuration,
    int? timeoutSeconds,
  }) async {
    await ensureInitialized();
    // int? actualTimeout = timeoutSeconds ?? (url == apiShopOrderValidateV3 ? 90 : null);
    logD("===>>> ${_requestLogUrl(url)}, parameters: $parameters");
    await refreshBaseOptions(resetTime: 30);
    try {
      dio.Options? requestOptions = dio.Options(
        headers: {
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Accept': '*/*',
        },
      );

      dio.Response response = await _dio.post(
        url,
        data: parameters,
        options: requestOptions,
        cancelToken: _downLoadCancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      logP("<<<===: $url, parameters: $parameters");
      return response;
    } catch (e) {
      dio.Response response = dio.Response(
        statusCode: ClientErrorCode.networkRequestFailed,
        data: {'error': e.toString()},
        requestOptions: dio.RequestOptions(path: url),
      );
      logE("<<<===: $url response: $response");
      return response;
    }
  }

  //下载json数据文件
  Future<dio.Response> downloadFile(
    String url,
    HttpDownLoadType responseType, {
    required ProgressCallback onReceiveProgress,
  }) async {
    await ensureInitialized();
    try {
      dio.ResponseType type = dio.ResponseType.json;
      if (responseType == HttpDownLoadType.json) {
        type = dio.ResponseType.json;
      } else if (responseType == HttpDownLoadType.stream) {
        type = dio.ResponseType.stream;
      } else if (responseType == HttpDownLoadType.plain) {
        type = dio.ResponseType.plain;
      } else if (responseType == HttpDownLoadType.bytes) {
        type = dio.ResponseType.bytes;
      }
      if (isHttpLog) {
        logD("===>>> downloadFile ${_requestLogUrl(url)}  responseType: $responseType");
      }
      // 使用共享的Dio实例而不是创建新实例，以复用连接
      dio.Response response = await _dio.get(
        url,
        // dio.Response response = await dio.Dio().get(url,
        options: dio.Options(responseType: type),
        cancelToken: _cancelToken = dio.CancelToken(),
        onReceiveProgress: onReceiveProgress,
      );
      if (isHttpLog) {
        logP("<<<=== downloadFile $url  response: $response");
      }
      return response;
    } catch (e) {
      return dio.Response(
        statusCode: ClientErrorCode.networkRequestFailed,
        data: {'error': e.toString()},
        requestOptions: dio.RequestOptions(path: url),
      );
    }
  }

  // 取消请求
  void cancelRequests() {
    if (_cancelToken?.isCancelled == false) {
      _cancelToken?.cancel("request cancelled");
    }
  }

  // 清理资源
  static void disposeHttpClient() {
    _sharedHttpClient?.close(force: true);
    _sharedHttpClient = null;
    logD("HttpClient资源已清理");
  }

  dio.Response parseResponse(dio.Response response, String url) {
    if (isHttpLog) {
      if (apiNotPrintMap.containsKey(url) && !isTestClient) {
        logP("<<<===  $url 响应");
      } else if (isHttpResponseFormatJson) {
        try {
          final pretty = const JsonEncoder.withIndent('  ').convert(response.data);
          logP("<<<===  $url  response:\n$pretty");
        } catch (_) {
          logP("<<<===  $url  response: $response");
        }
      } else {
        logP("<<<===  $url  response: $response");
      }
    }
    final responseData = response.data;
    // 部分接口成功时没有响应体；只有 JSON Map 才读取统一包装字段。
    if (responseData is Map) {
      // 服务端时间同步（响应体约定 sysAt 字段，秒或毫秒时间戳）
      final sysAt = responseData['sysAt'];
      if (sysAt is num) {
        TimeMgr.instance.initServerTime(sysAt.toInt());
      }
      if (responseData['code'] == ServerErrorCode.tokenExpired) {
        reLogin();
      }
    }

    return response;
  }

  /// token 失效回调：由业务层（登录模块）注册，负责跳转登录页等
  /// 例：`NetWorkManagerUtil.onTokenExpired = () => Get.offAllNamed(loginPage);`
  static Future<void> Function()? onTokenExpired;

  bool isExiting = false;

  //token 失效：清除登录信息，注销常驻 Controller，通知业务层
  Future<void> reLogin() async {
    if (!PreferenceUtil.instance.isLogin()) {
      return;
    }
    if (isExiting) {
      return;
    }

    isExiting = true;
    try {
      await PreferenceUtil.instance.clearLoginInfo();
      await RegisterControllerMgr.instance.unregister();
      eventBusUtil.fire(EventBusModelLoginStateChange(isLogin: false));
      await onTokenExpired?.call();
    } finally {
      isExiting = false;
    }
  }

  /// 生成图片URL的MD5哈希作为缓存文件名
  String _generateCacheFileName(String imageUrl) {
    final bytes = utf8.encode(imageUrl);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 获取缓存文件路径
  File? _getCacheFile(String imageUrl) {
    if (_imageCacheDir == null) return null;
    final fileName = _generateCacheFileName(imageUrl);
    return File('${_imageCacheDir!.path}/$fileName.png');
  }

  /// 异步下载图片并缓存
  ///
  /// [imageUrl] 图片URL
  /// [forceDownload] 是否强制重新下载（默认false，会先检查缓存）
  ///
  /// 返回本地图片文件路径，失败返回null
  Future<String?> downloadAndCacheImage(String imageUrl, {bool forceDownload = false}) async {
    await ensureInitialized();
    try {
      if (imageUrl.isEmpty) {
        logE('Image URL is empty');
        return null;
      }

      // 检查缓存
      final cacheFile = _getCacheFile(imageUrl);
      if (cacheFile == null) {
        logE('Image cache directory not initialized');
        return null;
      }

      // 如果不强制下载且缓存存在，直接返回缓存路径
      if (!forceDownload && cacheFile.existsSync()) {
        logD('使用缓存图片: ${cacheFile.path}');
        return cacheFile.path;
      }

      logP('开始下载图片: $imageUrl');

      // 使用Dio下载图片
      final response = await _dio.get(
        imageUrl,
        options: dio.Options(
          responseType: dio.ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'image/*',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // 保存图片到缓存
        await cacheFile.writeAsBytes(response.data);
        logP('图片下载成功并已缓存: ${cacheFile.path}');
        return cacheFile.path;
      } else {
        logE('Image download failed, status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logE('Download and cache image error: $e');
      return null;
    }
  }

  /// 清除图片缓存
  ///
  /// [imageUrl] 指定URL的缓存，为空则清除所有缓存
  Future<void> clearImageCache({String? imageUrl}) async {
    try {
      if (_imageCacheDir == null || !_imageCacheDir!.existsSync()) {
        logD('图片缓存目录不存在，无需清理');
        return;
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // 清除指定图片缓存
        final cacheFile = _getCacheFile(imageUrl);
        if (cacheFile != null && cacheFile.existsSync()) {
          await cacheFile.delete();
          logD('已清除图片缓存: $imageUrl');
        }
      } else {
        // 清除所有图片缓存
        final files = _imageCacheDir!.listSync();
        for (var file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        logD('已清除所有图片缓存，共${files.length}个文件');
      }
    } catch (e) {
      logE('Clear image cache failed: $e');
    }
  }

  /// 获取图片缓存大小（字节）
  Future<int> getImageCacheSize() async {
    try {
      if (_imageCacheDir == null || !_imageCacheDir!.existsSync()) {
        return 0;
      }

      int totalSize = 0;
      final files = _imageCacheDir!.listSync();
      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return totalSize;
    } catch (e) {
      logE('Get image cache size failed: $e');
      return 0;
    }
  }
}

//todo: 下载返回类型
enum HttpDownLoadType { json, stream, plain, bytes }
