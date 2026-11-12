import 'dart:async';

import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:flutter_framework/Util/Common/TimeTools.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/EventBusUtil/EventBusModel.dart';

class TimeMgr {
  static TimeMgr? _instance;
  TimeMgr._();
  static TimeMgr get instance => _instance ??= TimeMgr._();

  /// 初始化本地时间基线：首次启动时记录安装时间（毫秒）。
  Future<void> init() async {
    int firstInstallTimeStamp = PreferenceUtil.instance.getFirstInstallTimeStamp();
    if (firstInstallTimeStamp == 0) {
      PreferenceUtil.instance.setFirstInstallTimeStamp(DateTime.now().millisecondsSinceEpoch);
    }
  }

  bool isOneDaysPassed() {
    int firstInstallTimeStamp = PreferenceUtil.instance.getFirstInstallTimeStamp();
    if (firstInstallTimeStamp != 0) {
      return DateTime.now().millisecondsSinceEpoch - firstInstallTimeStamp > 24 * 60 * 60 * 1000;
    }
    return false;
  }

  /// Server Time
  int serverTimestamp = 0;
  bool isInitServerTime = false;
  int appInitTimestamp = 0;
  int serverInitTimestamp = 0;
  int lastDayTimestamp = 0; // 记录上次检查的日期时间戳

  void setAppInitTime() {
    //得到当前时区的时间对应的0时区时间戳
    DateTime appLaunchTime = DateTime.now().toUtc();
    // logD("App launch time (UTC): ${appLaunchTime.toString()}");
    appInitTimestamp = appLaunchTime.millisecondsSinceEpoch;
    // logD("App launch timestamp (UTC milliseconds): $appInitTimestamp");
  }

  /// 初始化服务端时间基线。
  /// 网络层返回 `sysAt` 后调用，后续倒计时、过期判断都应基于这里维护的服务端时间。
  void initServerTime(int sysAt) {
    if (isInitServerTime) {
      return;
    }
    serverTimestamp = sysAt * 1000;
    serverInitTimestamp = sysAt * 1000;
    isInitServerTime = true;
    setAppInitTime();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      var appNow = DateTime.now().toUtc().millisecondsSinceEpoch;
      var cha = appNow - appInitTimestamp;
      serverTimestamp = serverInitTimestamp + cha;
      // 每秒检查是否跨天
      _checkAndHandleNewDay();
    });
  }

  /// 检查是否跨天，跨天时广播 [EventBusModelNewDayChange]
  void _checkAndHandleNewDay() {
    if (!isInitServerTime) return;

    // 获取当前服务器时间戳（毫秒）
    int currentServerTimestamp = getServerTimestamp(true);

    // 将当前服务器时间转换为DateTime对象
    DateTime currentServerTime = DateTime.fromMillisecondsSinceEpoch(currentServerTimestamp);

    // 获取当前日期的开始时间戳（当天0点）
    DateTime currentDayStart = DateTime(
      currentServerTime.year,
      currentServerTime.month,
      currentServerTime.day,
    );
    int currentDayTimestamp = currentDayStart.millisecondsSinceEpoch;

    // 如果是第一次检查，初始化lastDayTimestamp
    if (lastDayTimestamp == 0) {
      lastDayTimestamp = currentDayTimestamp;
      return;
    }

    // 检查是否跨天（当前日期的开始时间戳与上次记录的不同）
    if (currentDayTimestamp != lastDayTimestamp) {
      logD(
        "检测到跨天事件: 从 ${DateTime.fromMillisecondsSinceEpoch(lastDayTimestamp)} 到 ${DateTime.fromMillisecondsSinceEpoch(currentDayTimestamp)}",
      );

      // 更新lastDayTimestamp
      lastDayTimestamp = currentDayTimestamp;

      // 广播跨天事件
      eventBusUtil.fire(EventBusModelNewDayChange());
    }
  }

  /// 获取当前服务端时间戳。
  /// 涉及时效、活动、签到、倒计时等场景时，优先使用服务端时间而非本地 `DateTime.now()`。
  int getServerTimestamp(bool isMillisecond) {
    if (!isInitServerTime) {
      logW("serverTimestamp is not initialized");
      return 0;
    }
    // 按服务端基线实时推算，避免只依赖 1 秒定时器导致同一秒内多次保存时间戳相同。
    final appNow = DateTime.now().toUtc().millisecondsSinceEpoch;
    final time = serverInitTimestamp + (appNow - appInitTimestamp);
    serverTimestamp = time;
    return isMillisecond ? time : (time ~/ 1000);
  }

  /// 获取当前统一时间戳：服务端时间已初始化时优先使用服务端校准时间，
  /// 否则回退客户端本地时间。需要跨端比较新旧的数据应使用本方法。
  int getServerTimestampOrClient(bool isMillisecond) {
    if (isInitServerTime) return getServerTimestamp(isMillisecond);
    return TimeTools.getClientTimestamp(isMillisecond);
  }

  /// 基于服务端时间启动倒计时。
  /// 适用于首页活动、任务、签到等需要和服务端统一时钟的倒计时场景。
  Timer timerStartByServerTime({
    required int duration,
    required int targetServerTimestamp,
    required void Function(String timeStr, bool isEnd) callback,
    bool refreshRightNow = false,
    bool onlyShowDay = false,
  }) {
    if (!isInitServerTime) {
      logW("Server time is not initialized");
      callback("00:00:00", true);
      return Timer(Duration.zero, () {});
    }

    bool isMillisecond = targetServerTimestamp.toString().length == 13;

    if (refreshRightNow) {
      int remainingSeconds = _getLeftSecondsByServerTime(targetServerTimestamp, isMillisecond);
      callback(getActivityTimeStr(remainingSeconds, onlyShowDay), remainingSeconds <= 0);
    }

    return Timer.periodic(Duration(seconds: duration), (timer) {
      int remainingSeconds = _getLeftSecondsByServerTime(targetServerTimestamp, isMillisecond);

      if (remainingSeconds > 0) {
        callback(getActivityTimeStr(remainingSeconds, onlyShowDay), false);
      } else {
        timer.cancel();
        callback(getActivityTimeStr(0, onlyShowDay), true);
      }
    });
  }

  /// 根据结束时间的服务器时间戳计算剩余秒数
  int _getLeftSecondsByServerTime(int endServerTimestamp, bool isMillisecond) {
    int currentServerTimestamp = getServerTimestamp(isMillisecond);
    int remainingSeconds = endServerTimestamp - currentServerTimestamp;
    return remainingSeconds > 0 ? (isMillisecond ? remainingSeconds ~/ 1000 : remainingSeconds) : 0;
  }

  bool isInLimitedTime(int start, int end, isMillisecond) {
    int now = getServerTimestamp(isMillisecond);
    return start < now && end > now;
  }

  bool isExpired(int end, isMillisecond) {
    int now = getServerTimestamp(isMillisecond);
    return end < now;
  }
}
