import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Popup/BottomSheetMgr.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/DocumentFileManager/DocumentFileManager.dart';
import 'package:flutter_framework/Util/EventBusUtil/EventBusUtil.dart';
import 'package:flutter_framework/Util/SheetAndAlter/Toast.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

///全局事件总线,时间监听通知
final eventBusUtil = EventBusUtil();

/// Waits for a closing route or overlay to hand control back before opening the next one.
Future<void> waitForOverlayHandoff() => WidgetsBinding.instance.endOfFrame;

bool isAvailable(Object? obj) {
  if (obj == null) {
    return false;
  } else {
    if (obj is String && (obj.isEmpty || obj == "null")) {
      return false;
    } else if (obj is List && obj.isEmpty) {
      return false;
    } else if (obj is Map && obj.isEmpty) {
      return false;
    }
  }

  return true;
}

//todo：版本号比较
bool isVersionNeedUpdate(String onlineVersion, String localVersion) {
  try {
    // int onlineVersionValue = int.parse(onlineVersion.replaceAll('.', ''));
    // int localVersionValue = int.parse(localVersion.replaceAll('.', ''));
    var onlineVersionValueArr = onlineVersion.split('.').map(int.parse).toList();
    var localVersionValueArr = localVersion.split('.').map(int.parse).toList();
    var onlineVersionValue =
        onlineVersionValueArr[0] * 10000 * 10000 +
        onlineVersionValueArr[1] * 10000 +
        onlineVersionValueArr[2];
    var localVersionValue =
        localVersionValueArr[0] * 10000 * 10000 +
        localVersionValueArr[1] * 10000 +
        localVersionValueArr[2];
    logP('onlineVersionValue: $onlineVersionValue, localVersionValue: $localVersionValue');
    return localVersionValue < onlineVersionValue;
  } catch (e) {
    logE('Compare version exception: $e');
    return false;
  }
}

//todo: 图片地址拼接尺寸参数（需图片服务支持 ?w=&h= 裁剪，不支持时传 needClip: false）
String getRedirectImageUrl(String imageUrl, {int w = 540, int h = 720, bool needClip = true}) {
  // String originDomain = 'https://hm-novel.s3.amazonaws.com';
  // String newDomain = 'https://media.easynovelhub.com';
  // String newImageUrl = imageUrl.replaceFirst(originDomain, newDomain);
  // newImageUrl = '$newImageUrl?w=$w&h=$h';
  if (!needClip) {
    return imageUrl;
  }
  if (w == 0 || h == 0) {
    return imageUrl;
  }
  var newImageUrl = '$imageUrl?w=$w&h=$h';
  return newImageUrl;
}

Timer timerStart(int duration, int seconds, void Function(int count, bool isEnd) callback) {
  return Timer.periodic(Duration(seconds: duration), (timer) {
    if (seconds > 0) {
      seconds--;
    } else {
      seconds = 0;
      timer.cancel();
    }

    callback(seconds, seconds == 0);
  });
}

//todo：Document文件读写
Future<File?> saveStringToFile(String fileName, String str) {
  return DocumentFileManager.instance.writeFile(fileName, str);
}

Future<String?> readStringFormFile(String fileName) {
  return DocumentFileManager.instance.readFile(fileName);
}

/// 获取当前时间戳（秒级）
int getTimeSeconds() {
  return (DateTime.now().millisecondsSinceEpoch ~/ 1000);
}

/// 获取当前时间戳（毫秒级）
int getTimeMillis() {
  return DateTime.now().millisecondsSinceEpoch;
}

/// 文本尺寸测量工具。
/// 适用于根据标题真实占位动态计算行数、间距或布局高度。
TextPainter getSizeOfText(String text, TextStyle textStyle, double maxWidth) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: textStyle,
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout(maxWidth: maxWidth);

  return textPainter;
}

/// 计算目标时间距离当前时间的剩余天数。
/// 内部自动兼容秒/毫秒时间戳。
int getDaysCha(int timestamp) {
  DateTime dateTime = convertTimestamp2DateTime(timestamp);
  DateTime now = DateTime.now();
  Duration difference = dateTime.difference(now);

  //difference.inDays 只会获取相差天数，不包含当天和最后一天时、分、秒，所以需要加1
  return difference.inDays;
}

/// 计算目标时间距离当前时间的剩余小时数。
/// 内部自动兼容秒/毫秒时间戳。
int getHoursCha(int timestamp) {
  DateTime dateTime = convertTimestamp2DateTime(timestamp);
  DateTime now = DateTime.now();
  Duration difference = dateTime.difference(now);

  //difference.inDays 只会获取相差天数，不包含当天和最后一天时、分、秒，所以需要加1
  return difference.inHours;
}

/// 统一将秒级/毫秒级时间戳转换为 `DateTime`。
/// 时间展示、时间差计算前优先复用此方法，避免各处重复判断位数。
DateTime convertTimestamp2DateTime(int timestamp) {
  // 检查时间戳的长度
  if (timestamp.toString().length == 10) {
    // 秒级时间戳
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  } else if (timestamp.toString().length == 13) {
    // 毫秒级时间戳
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  } else {
    // 默认处理，假设是秒级时间戳
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }
}

/// 获取当前时间戳（秒级）
int getCurrentTimestampSeconds() {
  return (DateTime.now().millisecondsSinceEpoch ~/ 1000);
}

Timer timerStartDateTime(
  int duration,
  int seconds,
  void Function(String dataStr, bool isEnd) callback, {
  bool refreshRightNow = false,
  bool isShowDay = false,
}) {
  // 计算结束时间
  final DateTime endDateTime = DateTime.now().add(Duration(seconds: seconds));

  if (refreshRightNow) {
    int remainingSeconds = _getLeftSeconds(endDateTime);
    callback(getActivityTimeStr(remainingSeconds, isShowDay), remainingSeconds <= 0);
  }

  return Timer.periodic(Duration(seconds: duration), (timer) {
    int remainingSeconds = _getLeftSeconds(endDateTime);

    if (remainingSeconds > 0) {
      callback(getActivityTimeStr(remainingSeconds, isShowDay), false);
    } else {
      timer.cancel();
      callback(getActivityTimeStr(0, isShowDay), true);
    }
  });
}

int _getLeftSeconds(DateTime endDateTime) {
  final now = DateTime.now();
  final difference = endDateTime.difference(now);
  return difference.inSeconds > 0 ? difference.inSeconds : 0;
}

String getActivityTimeStr(int seconds, bool isShowDay) {
  int day = seconds ~/ 86400;
  int hour = (seconds % 86400) ~/ 3600;
  int minute = (seconds % 3600) ~/ 60;
  int second = seconds % 60;

  if (isShowDay) {
    if (day >= 1) {
      // return '> ${'day_'.trParams({'param1': '$day'})}';
      return 'days_left'.trParams({'param1': '$day'});
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  if (day <= 0) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  } else if (day == 1) {
    return '${'day_'.trParams({'param1': '$day'})} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  } else {
    return '${'days'.trParams({'param1': '$day'})} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }
}

/// 检查当前语言是否为RTL语言
bool isRTLLanguage() {
  return Get.locale?.languageCode == 'he' ||
      Get.locale?.languageCode == 'ar' ||
      Get.locale?.languageCode == 'fa';
}

/// 创建适合当前语言环境的返回按钮Widget
/// 在RTL语言环境下自动使用正确方向的图标
Widget buildRTLImage({
  required BuildContext context,
  required String imagePath,
  double? width,
  double? height,
  Color? color,
}) {
  Widget iconWidget = Image.asset(
    imagePath,
    width: width,
    height: height,
    color: color,
  );

  return Transform.flip(
    flipX: Directionality.of(context) == TextDirection.rtl,
    child: iconWidget,
  );
}

Widget _buildRTLBackButton({
  required BuildContext context,
  bool isWhite = false,
  double? width = 12,
  double? height = 20,
  required VoidCallback onPressed,
  EdgeInsets? padding,
  Color? color,
}) {
  Widget iconWidget = buildRTLImage(
    context: context,
    imagePath: isWhite
        ? "assets/images/common/icon_back_white.png"
        : "assets/images/common/icon_back_black.png",
    width: width,
    height: height,
    color: color,
  );

  return GestureDetector(
    onTap: onPressed,
    behavior: HitTestBehavior.translucent,
    child: Container(
      padding: padding ?? const EdgeInsets.all(8),
      width: 44, // Minimum recommended tap target size
      height: 44,
      alignment: Alignment.centerLeft, // Align icon to left within the tap area
      child: iconWidget,
    ),
  );
}

Widget buildRTLBackButton({
  required BuildContext context,
  bool isWhite = false,
  VoidCallback? onPressed,
  bool isBack = true,
  EdgeInsets? padding,
  Color? color,
}) {
  return _buildRTLBackButton(
    context: context,
    isWhite: isWhite,
    onPressed: () {
      if (isBack) {
        Get.back();
      }
      onPressed?.call();
    },
    padding: padding,
    color: color,
  );
}

/// 尝试打开链接，只返回真实结果，不处理 UI 反馈。
Future<bool> tryOpenUrl(dynamic url, {LaunchMode mode = LaunchMode.externalApplication}) async {
  try {
    Uri? uri;
    if (url is String) {
      uri = Uri.parse(url);
    } else if (url is Uri) {
      uri = url;
    }

    if (uri == null || !await canLaunchUrl(uri)) return false;
    // 使用外部浏览器模式打开,避免Safari显示"网址无效"警告
    return await launchUrl(uri, mode: mode);
  } catch (e) {
    logE('openUrl error: $e');
    return false;
  }
}

// 打开链接
Future<void> openUrl(dynamic url, {LaunchMode mode = LaunchMode.externalApplication}) async {
  if (!await tryOpenUrl(url, mode: mode)) {
    showToast('error_message_1'.tr);
  }
}

Future<bool> openEmailInbox() async {
  try {
    const intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      category: 'android.intent.category.APP_EMAIL',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
    return true;
  } catch (e) {
    logE('openEmailInbox error: $e');
    return false;
  }
}

// 打开邮箱
Future<void> openEmailApp() async {
  Uri emailLaunchUri;
  // iOS 使用 message:// scheme 打开邮件应用的收件箱
  if (GetPlatform.isIOS) {
    emailLaunchUri = Uri.parse('message://');
  } else if (GetPlatform.isAndroid) {
    // Android 使用 mailto: 打开默认邮件应用
    // emailLaunchUri = Uri.parse('mailto:');
    bool success = await openEmailInbox();
    if (success) {
      return;
    } else {
      emailLaunchUri = Uri.parse('mailto:');
    }
  } else {
    emailLaunchUri = Uri.parse('mailto:');
  }
  openUrl(emailLaunchUri);
}

Future<void> showPageBottomSheet(
  context,
  Widget child, {
  Color backgroundColor = Colors.white,
  bool isDismissible = true,
  Color? barrierColor,
  bool isScrollControlled = true,
  bool enableDrag = true,
  VoidCallback? onDismiss,
}) async {
  await BottomSheetMgr.instance.showPageBottomSheet(
    context,
    child,
    backgroundColor: backgroundColor,
    isDismissible: isDismissible,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    onDismiss: onDismiss,
  );
}

/// 检查当前iOS版本是否为iOS 15及以上
Future<bool> isIOSAbove(int version) async {
  if (!GetPlatform.isIOS) {
    return true;
  }

  try {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

    // 解析系统版本号
    String systemVersion = iosInfo.systemVersion;
    List<String> versionParts = systemVersion.split('.');

    if (versionParts.isNotEmpty) {
      int majorVersion = int.tryParse(versionParts[0]) ?? 0;
      // logP("iOS系统版本: $systemVersion, 主版本号: $majorVersion");
      return majorVersion >= version;
    }

    return false;
  } catch (e) {
    logE("Get iOS version info failed: $e");
    return false;
  }
}

/// 统一获取或按需注册 GetX Controller。
/// 项目内优先使用此方法，避免直接 `Get.find` / `Get.put` 导致注册时机不一致，
/// 并避免已注册时仍创建无用的 Controller 实例。
T findGetxController<T extends GetxController>(
  T Function() create, {
  String? tag,
  bool permanent = true,
}) {
  if (Get.isRegistered<T>(tag: tag)) {
    return Get.find<T>(tag: tag);
  } else {
    return putController(create(), tag: tag, permanent: permanent);
  }
}

// 泛型方式注入控制器
T putController<T>(T controller, {String? tag, bool permanent = true}) {
  return Get.put<T>(controller, tag: tag, permanent: permanent);
}

bool isValidEmail(String email) {
  if (email.isEmpty) return false;
  if (email.length > 254) return false;
  final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
  return regex.hasMatch(email);
}

/// 字符串数字缩写格式化入口。
/// 常用于阅读数、收藏数、榜单数值等展示。
String formatNumber(String num) {
  // 如果不是数字，直接返回原字符串
  if (int.tryParse(num) == null) return num;
  final n = int.parse(num);
  return formatNumberInt(n);
}

/// 整型数字缩写格式化入口。
/// 规则统一为 `K/M` 样式，页面展示数字时优先复用，不要在 Widget 内重复实现。
String formatNumberInt(int? n) {
  if (n == null) return '';
  if (n < 1000) {
    return n.toString(); // 1000 以下原样返回
  } else if (n < 10000) {
    // 1K - 9.9K：保留一位小数，如 3456 -> 3.4K
    return '${(n / 1000).toStringAsFixed(1)}K';
  } else if (n < 1000000) {
    // 10K - 999K：不保留小数，如 56789 -> 56K
    return '${(n / 1000).round()}K';
  } else if (n < 10000000) {
    // 1M - 9.9M：保留一位小数，如 3456789 -> 3.4M
    return '${(n / 1000000).toStringAsFixed(1)}M';
  } else {
    // 10M 以上：不保留小数，如 12345678 -> 12M
    return '${(n / 1000000).round()}M';
  }
}
