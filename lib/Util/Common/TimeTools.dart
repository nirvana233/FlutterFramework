import 'package:flutter_framework/MainPage/Language/ViewModel/LanguageViewModel.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TimeTools {
  /// 国际化日期格式化入口。
  /// 适用于订单、记录、活动时间等需要按当前 app 语言显示具体日期的场景。
  static String formatTimestampToInternationalDate(int timestamp, {bool showHMS = false}) {
    try {
      if (timestamp == 0) {
        return '';
      }
      // 将时间戳转换为DateTime对象（支持秒和毫秒时间戳）
      DateTime dateTime;
      if (timestamp.toString().length == 10) {
        // 秒级时间戳
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        // 毫秒级时间戳
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      // 获取当前app语言
      String languageCode = LanguageViewModel.instance.appLanguage.value.languageCode;

      // 根据语言代码创建对应的locale字符串
      String localeString = LanguageViewModel.instance.getLocaleString(languageCode);

      DateFormat formatter = DateFormat.yMMMd(localeString);
      if (showHMS) formatter = formatter.add_Hms();
      return formatter.format(dateTime);
    } catch (e) {
      logE("Timestamp format failed: $e");
      // 如果格式化失败，回退到英语格式
      try {
        DateTime dateTime;
        if (timestamp.toString().length == 10) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        } else {
          dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
        DateFormat fallbackFormatter = DateFormat.yMMMd('en_US');
        if (showHMS) fallbackFormatter = fallbackFormatter.add_Hms();
        return fallbackFormatter.format(dateTime);
      } catch (fallbackError) {
        logE("Fallback format also failed: $fallbackError");
        return '';
      }
    }
  }

  /// 自定义格式时间展示。
  /// 当页面需要按指定 pattern 输出时间文本时优先使用此方法。
  static String showTime(int timestamp, String format) {
    try {
      if (timestamp == 0) {
        return '';
      }
      // 将时间戳转换为DateTime对象（支持秒和毫秒时间戳）
      DateTime dateTime;
      if (timestamp.toString().length == 10) {
        // 秒级时间戳
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        // 毫秒级时间戳
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      // 获取当前app语言
      String languageCode = LanguageViewModel.instance.appLanguage.value.languageCode;
      // 根据语言代码创建对应的locale字符串
      String localeString = LanguageViewModel.instance.getLocaleString(languageCode);
      // 使用当前app语言格式化日期：dd MMM yyyy (例如: 14 Aug 2025)
      DateFormat formatter = DateFormat(format, localeString);
      return formatter.format(dateTime);
    } catch (e) {
      logE("Timestamp format failed: $e");
      return '';
    }
  }

  /// 获取客户端当前时间戳。
  /// 仅适用于不要求服务端对时的本地场景；活动、任务等时效逻辑优先使用 `TimeMgr`。
  static int getClientTimestamp(bool isMillisecond) {
    return isMillisecond
        ? DateTime.now().millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// 将秒数字符串转换为 `xh ym` 文案。
  /// 常用于阅读时长、播放时长等轻量展示。
  static String convertSeconds(String seconds) {
    if (seconds.isEmpty) return "0m";

    int totalSeconds = int.tryParse(seconds) ?? 0;

    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// 评论时间专用格式化：`MM/dd HH:mm`。
  static String formatCommentTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';

    try {
      DateTime dateTime;
      if (timestamp.toString().length == 10) {
        // 秒级时间戳
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        // 毫秒级时间戳
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      // 格式化为 MM/dd HH:mm
      String month = dateTime.month.toString().padLeft(2, '0');
      String day = dateTime.day.toString().padLeft(2, '0');
      String hour = dateTime.hour.toString().padLeft(2, '0');
      String minute = dateTime.minute.toString().padLeft(2, '0');

      return '$month/$day $hour:$minute';
    } catch (e) {
      logE("Comment time format failed: $e");
      return '';
    }
  }

  /// 相对时间格式化，如 `just now`、`x m ago`、`x d ago`。
  /// 适用于评论、消息、动态等“距今多久”的展示。
  static String formatRelativeTime(int? timestamp, {bool needYear = false}) {
    if (timestamp == null || timestamp == 0) return '';
    // timestamp = (timestamp ?? 0) - 1000000;

    try {
      final dateTime = timestamp.toString().length == 10
          ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          : DateTime.fromMillisecondsSinceEpoch(timestamp);
      final diff = DateTime.now().difference(dateTime).inSeconds;

      // Just now
      if (diff < 60) return 'just_now'.tr;
      // @param1m ago
      if (diff < 3600) return 'm_ago'.trParams({'param1': (diff ~/ 60).toString()});
      // @param1h ago
      if (diff < 86400) return 'h_ago'.trParams({'param1': (diff ~/ 3600).toString()});
      if (diff < 86400 * 7) {
        // @param1d ago
        return 'd_ago'.trParams({'param1': (diff ~/ 86400).toString()});
      }

      final localeString = LanguageViewModel.instance.getLocaleString(
        LanguageViewModel.instance.appLanguage.value.languageCode,
      );
      if (needYear) {
        return DateFormat.yMMMd(localeString).format(dateTime);
      } else {
        return DateFormat.MMMd(localeString).format(dateTime);
      }
    } catch (e) {
      logE("Relative time format failed: $e");
      return '';
    }
  }

  /// 本地时区的「年-月-日」标识（如 `2026-06-02`）。
  /// 用于「同一天」判断的持久化键，与具体时分秒、时区显示无关。
  static String localDateString([DateTime? date]) {
    return DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());
  }

  /// 按本地时区判断 [dateString] 是否为今天（与 [localDateString] 配套）。
  /// [dateString] 为空或格式不符均返回 false。
  static bool isToday(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;
    return dateString == localDateString();
  }
}
