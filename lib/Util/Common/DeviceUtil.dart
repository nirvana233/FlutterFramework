import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/Const.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String deviceIdKey = "deviceId";

typedef _StoredDeviceIdReader = Future<String?> Function();
typedef _StoredDeviceIdWriter = Future<void> Function(String value);
typedef _DeviceIdGetter = Future<String?> Function();

class DeviceUtil {
  static DeviceUtil instance = DeviceUtil();

  ///屏幕尺寸相关
  static double? _topSafeHeight;
  static double? _bottomSafeHeight;
  static double? _screenWidth;
  static double? _screenHeight;

  bool _isAndroid10 = false;
  bool get isAndroid10 => GetPlatform.isAndroid && _isAndroid10;

  Future<void> initialize() async {
    getAndroidSDKVersion();
    await isLowDevice();
  }

  Future<void> setContext(BuildContext context) async {
    final mediaQuery = MediaQuery.of(context);
    // 即使已经初始化，也要根据当前上下文重新刷新尺寸，确保 DevicePreview 等工具切换设备后可以实时更新
    _topSafeHeight = await getFixedTopPadding(context);
    _bottomSafeHeight = mediaQuery.padding.bottom;
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
  }

  double get topSafeHeight => _topSafeHeight ?? 0.0;
  // double get topSafeHeight => getFixedTopPadding(Get.context);

  double get bottomSafeHeight => _bottomSafeHeight ?? 0.0;

  double get width => _screenWidth ?? 0.0;

  double get height => _screenHeight ?? 0.0;

  //设备信息相关
  static var pixelRatio = 0.0;
  static var screenWidth = 0.0;
  static var screenHeight = 0.0;
  static var statusBarHeight = 0.0;
  static var bottomBarHeight = 0.0;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static init(BuildContext context) {
    MediaQueryData mq = MediaQuery.of(context);
    // 屏幕密度
    pixelRatio = mq.devicePixelRatio;
    // 屏幕宽(注意是dp, 转换px 需要 screenWidth * pixelRatio)
    screenWidth = mq.size.width;
    // 屏幕高(注意是dp)
    screenHeight = mq.size.height;
    // 顶部状态栏, 随着刘海屏会增高
    statusBarHeight = mq.padding.top;
    // 底部功能栏, 类似于iPhone XR 底部安全区域
    bottomBarHeight = mq.padding.bottom;
  }

  static String deviceIdentifier = "";
  static Future<String>? _deviceIdFuture;

  static const _androidIdPlugin = AndroidId();

  static Future<String> getDeviceId() async {
    return _resolveDeviceId(
      isIOS: GetPlatform.isIOS,
      isAndroid: GetPlatform.isAndroid,
      readStoredDeviceId: () => _storage.read(key: deviceIdKey),
      writeStoredDeviceId: (value) => _storage.write(key: deviceIdKey, value: value),
      getIosVendorId: () async {
        final deviceInfo = await DeviceUtil.iosDeviceInfo;
        return deviceInfo.identifierForVendor;
      },
      getAndroidId: () => _androidIdPlugin.getId(),
    );
  }

  @visibleForTesting
  static Future<String> resolveDeviceIdForTesting({
    required bool isIOS,
    required bool isAndroid,
    required Future<String?> Function() readStoredDeviceId,
    required Future<void> Function(String value) writeStoredDeviceId,
    required Future<String?> Function() getIosVendorId,
    required Future<String?> Function() getAndroidId,
  }) {
    return _resolveDeviceId(
      isIOS: isIOS,
      isAndroid: isAndroid,
      readStoredDeviceId: readStoredDeviceId,
      writeStoredDeviceId: writeStoredDeviceId,
      getIosVendorId: getIosVendorId,
      getAndroidId: getAndroidId,
    );
  }

  static Future<String> _resolveDeviceId({
    required bool isIOS,
    required bool isAndroid,
    required _StoredDeviceIdReader readStoredDeviceId,
    required _StoredDeviceIdWriter writeStoredDeviceId,
    required _DeviceIdGetter getIosVendorId,
    required _DeviceIdGetter getAndroidId,
  }) async {
    if (isAvailable(deviceIdentifier)) {
      return deviceIdentifier;
    }
    final pendingDeviceId = _deviceIdFuture;
    if (pendingDeviceId != null) {
      return pendingDeviceId;
    }

    final future = _loadDeviceId(
      isIOS: isIOS,
      isAndroid: isAndroid,
      readStoredDeviceId: readStoredDeviceId,
      writeStoredDeviceId: writeStoredDeviceId,
      getIosVendorId: getIosVendorId,
      getAndroidId: getAndroidId,
    );
    _deviceIdFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_deviceIdFuture, future)) {
        _deviceIdFuture = null;
      }
    }
  }

  static Future<String> _loadDeviceId({
    required bool isIOS,
    required bool isAndroid,
    required _StoredDeviceIdReader readStoredDeviceId,
    required _StoredDeviceIdWriter writeStoredDeviceId,
    required _DeviceIdGetter getIosVendorId,
    required _DeviceIdGetter getAndroidId,
  }) async {
    try {
      if (isIOS) {
        final value = await readStoredDeviceId();
        if (isAvailable(value)) {
          deviceIdentifier = value!;
          return deviceIdentifier;
        }

        final vendorId = await getIosVendorId();
        if (isAvailable(vendorId)) {
          deviceIdentifier = vendorId!;
          await _writeStoredDeviceId(
            deviceIdentifier,
            writeStoredDeviceId: writeStoredDeviceId,
          );
        }
      } else if (isAndroid) {
        // Android-specific code
        // AndroidDeviceInfo deviceInfo = await DeviceUtil.androidDeviceInfo;
        // deviceIdentifier = deviceInfo.device; // Android唯一设备ID
        deviceIdentifier = await getAndroidId() ?? "";
      }

      return deviceIdentifier;
    } catch (e) {
      logW('Error getting device id: $e');
      return deviceIdentifier;
    }
  }

  static Future<void> _writeStoredDeviceId(
    String value, {
    required _StoredDeviceIdWriter writeStoredDeviceId,
  }) async {
    try {
      await writeStoredDeviceId(value);
    } catch (e) {
      if (!_isKeychainDuplicateItemError(e)) {
        rethrow;
      }
    }
  }

  static bool _isKeychainDuplicateItemError(Object error) {
    if (error is! PlatformException) {
      return false;
    }
    return error.details == -25299 || (error.message?.contains('-25299') ?? false);
  }

  static Future<String> getIDFV() async {
    if (GetPlatform.isIOS) {
      try {
        IosDeviceInfo deviceInfo = await DeviceUtil.iosDeviceInfo;
        return deviceInfo.identifierForVendor ?? "";
      } catch (e) {
        logE('Error getting IDFV: $e');
      }
    }
    return "";
  }

  static Future<IosDeviceInfo> get iosDeviceInfo async {
    var deviceInfo = DeviceInfoPlugin();
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

    return iosInfo;
  }

  static Future<AndroidDeviceInfo> get androidDeviceInfo async {
    var deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    return androidInfo;
  }

  /// 判断是否是平板设备
  /// 通过屏幕尺寸的最小边来判断，通常平板的最小边大于600dp
  static get isTablet {
    if (_screenWidth == null || _screenHeight == null) {
      return false;
    }

    double minSize = _screenWidth! < _screenHeight! ? _screenWidth! : _screenHeight!;
    return minSize >= 600;
  }

  /// 判断是否是iPhone8等屏幕宽高比比较大的手机（排除平板）
  /// iPhone8及以下设备的屏幕比例约为16:9 (1.78)
  /// iPhone X及以上设备的屏幕比例约为19.5:9 (2.17)
  static get isLargeAspectRatioPhone {
    if (_screenWidth == null || _screenHeight == null || isTablet) {
      return false;
    }

    double aspectRatio = _screenHeight! / _screenWidth!;

    // 如果宽高比大于1.9，认为是长屏设备（如iPhone X及以上）
    // iPhone8及以下设备宽高比约为1.78
    return aspectRatio > 1.9;
  }

  /// 判断是否是iPhone8等传统屏幕比例的手机设备（排除平板）
  static get isTraditionalAspectRatioPhone {
    if (isTablet) {
      return false;
    }
    return !isLargeAspectRatioPhone;
  }

  static String _version = '';
  static Future<String> getVersion() async {
    if (isAvailable(_version)) {
      return _version;
    }
    final info = await PackageInfo.fromPlatform();
    var version = info.version;
    var build = info.buildNumber;
    _version = '$version b$build${isTestServer ? ' - test' : ''}';
    return _version;
  }

  double totalRam = 0;
  Future<double> getDeviceRam() async {
    if (totalRam != 0) {
      return totalRam;
    }
    try {
      if (GetPlatform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final memoryInfo = androidInfo.data;
        if (memoryInfo.containsKey('physicalRamSize')) {
          final int physicalRamSize = memoryInfo['physicalRamSize'];
          totalRam = physicalRamSize.toDouble() / 1024;
          logP('totalRam:$totalRam');
          return totalRam;
        }
      }
      // else if (GetPlatform.isIOS) {
      //   final iosInfo = await DeviceInfoPlugin().iosInfo;
      //   // Most recent iOS devices have more than 2GB of RAM.
      //   // This is a rough check based on model.
      //   // For a more accurate check, a model-to-RAM mapping would be needed.
      //   // All iPhones from iPhone 8 onwards have 2GB or more RAM.
      //   // iPhone 7 has 2GB. iPhone 6s has 2GB. iPhone 6 has 1GB.
      //   logD('iosInfo.utsname.machine:${iosInfo.utsname.machine}');
      //   switch (iosInfo.utsname.machine) {
      //     case 'iPhone6,1': // iPhone 5s
      //     case 'iPhone6,2': // iPhone 5s
      //     case 'iPhone7,2': // iPhone 6
      //     case 'iPhone8,4': // iPhone SE (1st gen)
      //       return true;
      //     default:
      //       return false;
      //   }
      // }
    } catch (e) {
      logE('Failed to get device memory info: $e');
    }
    return 0;
  }

  AndroidDeviceInfo? androidInfo;
  //获取安卓SDK版本
  Future<int> getAndroidSDKVersion() async {
    if (GetPlatform.isAndroid) {
      if (androidInfo != null) {
        _isAndroid10 = androidInfo!.version.sdkInt == 29;
        return androidInfo!.version.sdkInt;
      }
      androidInfo = await DeviceInfoPlugin().androidInfo;
      _isAndroid10 = androidInfo!.version.sdkInt == 29;
      return androidInfo!.version.sdkInt;
    }
    return 0;
  }

  //获取处理器核心数
  int getProcessorCoreCount() {
    return Platform.numberOfProcessors;
  }

  //获取屏幕分辨率
  (double, double, double) getScreenResolution() {
    if (screenWidth > 0 && screenHeight > 0 && pixelRatio > 0) {
      double width = screenWidth * pixelRatio;
      double height = screenHeight * pixelRatio;
      return (width, height, pixelRatio);
    }
    return (0, 0, 0);
  }

  bool? isLowDeviceValue;

  /// 低端机判定相关参数快照（与 [isLowDevice] 同源），供上报 / 日志复用。
  ///
  /// 字段说明：
  /// - [isLowDevice]：实际生效值（含 GM 强制覆盖）
  /// - [isLowDeviceComputed]：按阈值公式现场计算的结果
  /// - 其余为判定输入与中间 flag
  ///
  /// 失败时返回安全默认值，避免拖垮 [Future.wait] / 启动判定。
  Future<Map<String, dynamic>> getLowDeviceReportParams() async {
    try {
      if (!GetPlatform.isAndroid) {
        isLowDeviceValue ??= false;
        return {
          'isLowDevice': isLowDeviceValue,
          'isLowDeviceComputed': false,
          'androidSdkVersion': 0,
          'processorCoreCount': getProcessorCoreCount(),
          'screenWidthPx': 0.0,
          'screenHeightPx': 0.0,
          'pixelRatio': 0.0,
          'totalRamGb': totalRam,
          'supportsVulkan11': true,
          'isOldSdk': false,
          'hasFewCores': false,
          'isLowRes': false,
          'hasLowRam': false,
        };
      }

      final int sdkVersion = await getAndroidSDKVersion();
      final int processorCoreCount = getProcessorCoreCount();
      final (double, double, double) screenResolution = getScreenResolution();
      final double ramGb = await getDeviceRam(); // in GB
      // 如需判断 Vulkan 1.1 支持（Impeller 走 OpenGLES 后端时的黑闪问题），可通过原生
      // MethodChannel 实现后在此接入；默认视为支持。
      const bool supportsVulkan11 = true;

      final bool isOldSdk = sdkVersion <= 28;
      final bool hasFewCores = processorCoreCount <= 6;
      final bool isLowRes = screenResolution.$1 > 0 && screenResolution.$1 < 800;
      final bool hasLowRam = ramGb > 0 && ramGb <= 4;
      final bool isLowDeviceComputed =
          isOldSdk || hasFewCores || isLowRes || hasLowRam || !supportsVulkan11;

      // 未设置时与 isLowDevice() 保持一致；已设置（含 GM 强制）则保留原值
      isLowDeviceValue ??= isLowDeviceComputed;

      return {
        'isLowDevice': isLowDeviceValue,
        'isLowDeviceComputed': isLowDeviceComputed,
        'androidSdkVersion': sdkVersion,
        'processorCoreCount': processorCoreCount,
        'screenWidthPx': screenResolution.$1,
        'screenHeightPx': screenResolution.$2,
        'pixelRatio': screenResolution.$3,
        'totalRamGb': ramGb,
        'supportsVulkan11': supportsVulkan11,
        'isOldSdk': isOldSdk,
        'hasFewCores': hasFewCores,
        'isLowRes': isLowRes,
        'hasLowRam': hasLowRam,
      };
    } catch (e) {
      logE('getLowDeviceReportParams failed: $e');
      isLowDeviceValue ??= false;
      return {
        'isLowDevice': isLowDeviceValue,
        'isLowDeviceComputed': false,
        'androidSdkVersion': 0,
        'processorCoreCount': getProcessorCoreCount(),
        'screenWidthPx': 0.0,
        'screenHeightPx': 0.0,
        'pixelRatio': 0.0,
        'totalRamGb': totalRam,
        'supportsVulkan11': true,
        'isOldSdk': false,
        'hasFewCores': false,
        'isLowRes': false,
        'hasLowRam': false,
        'error': e.toString(),
      };
    }
  }

  Future<bool> isLowDevice() async {
    // isLowDeviceValue = true;
    // return isLowDeviceValue!;
    if (isLowDeviceValue != null) {
      return isLowDeviceValue!;
    }
    if (!GetPlatform.isAndroid) {
      isLowDeviceValue = false;
      return false;
    }
    final params = await getLowDeviceReportParams();
    logP(
      'isLowDevice: ${params['isLowDevice']} (oldSdk=${params['isOldSdk']} '
      'fewCores=${params['hasFewCores']} lowRes=${params['isLowRes']} '
      'lowRam=${params['hasLowRam']} supportsVulkan11=${params['supportsVulkan11']})',
    );
    return isLowDeviceValue!;
  }

  PackageInfo? _packageInfo;
  Future<PackageInfo> getPackageInfo() async {
    if (isAvailable(_packageInfo)) {
      return _packageInfo!;
    }
    _packageInfo = await PackageInfo.fromPlatform();
    return _packageInfo!;
  }
}

bool get isWideDevice {
  if (Get.context == null) {
    return false;
  }
  return MediaQuery.of(Get.context!).size.shortestSide > 600;
}

/// 获取修正后的顶部刘海高度
/// 自动修复 Android 10 刘海识别失效问题（特别针对华为 Mate 20 Pro 等设备）
/// 返回正确的顶部安全区高度(逻辑像素)
Future<double> getFixedTopPadding(BuildContext? context) async {
  if (context == null) {
    return 0;
  }
  final isAndroid = GetPlatform.isAndroid;
  final mediaQuery = MediaQuery.of(context);

  // 非 Android 平台，直接返回系统值
  if (!isAndroid) {
    return mediaQuery.padding.top;
  }

  final topPadding = mediaQuery.padding.top;
  final systemGestureInsets = mediaQuery.systemGestureInsets;
  final viewPadding = mediaQuery.viewPadding;

  final topGesture = systemGestureInsets.top;
  final topViewPadding = viewPadding.top;

  // Android 10 特定问题判断
  final isAndroid10 = await DeviceUtil.instance.getAndroidSDKVersion() == 29;

  // // 多重检测机制判断是否存在刘海
  // // 1. systemGestureInsets.top > 0（物理像素）
  // // 2. viewPadding.top > 0（通常在有刘海时会有值）
  // final hasNotchByGesture = topGesture > 0;
  // final hasNotchByViewPadding = topViewPadding > 20; // 通常刘海高度至少20dp
  //
  // // 判断 Flutter 是否误报（padding.top 异常小但确实有刘海）
  // final isBrokenPadding = topPadding <= 1.0 && (hasNotchByGesture || hasNotchByViewPadding);

  // Android 10 刘海屏修复逻辑
  // 强制修复 Android 10，不再考虑是否isBrokenPadding
  if (isAndroid10) {
    // 优先使用 viewPadding.top，它通常更准确
    if (topViewPadding > 0) {
      return topViewPadding;
    }
    // 备用方案：直接使用 systemGestureInsets.top（已经是逻辑像素）
    if (topGesture > 0) {
      return topGesture;
    }
    // 最终兜底：华为 Mate 20 Pro 典型刘海高度约 25-32dp
    // 如果上述方法都失败，返回一个合理的默认值
    return 28.0;
  }

  // // 额外的兜底检查：即使不是 Android 10，如果 padding.top 异常但其他指标显示有刘海
  // if (topPadding <= 1.0 && topViewPadding > 20) {
  //   return topViewPadding;
  // }

  // // 如果 padding.top 异常小但 systemGestureInsets 有值，使用 gesture 值
  // if (topPadding <= 1.0 && topGesture > 0) {
  //   return topGesture;
  // }

  // 正常情况，返回系统值
  return topPadding;
}

bool get isTraditionalAspectRatioPhone => DeviceUtil.isTraditionalAspectRatioPhone;

bool get isLargeAspectRatioPhone => DeviceUtil.isLargeAspectRatioPhone;

bool get isTablet => DeviceUtil.isTablet;

double get topSafeHeightOffset => DeviceUtil.instance.topSafeHeight > 0 ? 0 : 20.0;

double get topSafeHeight => DeviceUtil.instance.topSafeHeight + topSafeHeightOffset;

bool get isLowDevice => DeviceUtil.instance.isLowDeviceValue ?? false;

int get androidSDKVersion => DeviceUtil.instance.androidInfo?.version.sdkInt ?? 0;

double get smartTopSafeHeight => DeviceUtil.instance.topSafeHeight;

/// 渲染期实时获取顶部安全区高度。
/// 修复 Android 10 启动期状态栏隐藏（immersive）导致 insets=0、缓存回落到兜底 28 的问题：
/// 取当前 viewPadding.top（不会被 SafeArea 消费，Android 10 上比 padding.top 更稳）。
/// 有非零实时 inset 时以它为真值并回写缓存；仍为 0 时保留启动期兜底，
/// 使不依赖 context 的 preferredSize 在后续帧收敛到真值。
double topSafeHeightOf(BuildContext context) {
  final cached = DeviceUtil.instance.topSafeHeight;
  if (!GetPlatform.isAndroid) {
    return cached;
  }
  final live = MediaQuery.of(context).viewPadding.top;
  if (live > 0) {
    if (live != cached) {
      DeviceUtil._topSafeHeight = live;
    }
    return live;
  }
  return cached;
}

double get smartBottomSafeHeight {
  final bottomSafe = DeviceUtil.instance.bottomSafeHeight;
  return bottomSafe > 0 ? bottomSafe : 15.0;
}
