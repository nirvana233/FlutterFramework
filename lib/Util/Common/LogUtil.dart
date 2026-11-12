import 'dart:developer' as developer;

import 'package:flutter_framework/Util/Const.dart';
import 'package:talker_flutter/talker_flutter.dart';

const String projectName = 'flutter_framework';
String projectPackageName = 'package:$projectName/';

Talker? talker;

/// 纯文本日志格式：无边框、无分隔线，仅保留颜色（若启用）
class _PlainLoggerFormatter implements LoggerFormatter {
  const _PlainLoggerFormatter();

  @override
  String fmt(LogDetails details, TalkerLoggerSettings settings) {
    final msg = details.message?.toString() ?? '';
    if (!settings.enableColors) {
      return msg;
    }
    return msg.split('\n').map((e) => details.pen.write(e)).join('\n');
  }
}

void initTalker() async {
  if (!isLog) return;
  talker = TalkerFlutter.init(
    settings: TalkerSettings(
      enabled: true,
      useConsoleLogs: true,
      useHistory: true,
      maxHistoryItems: 1000,
    ),
    // observer: ServerLogObserver(), // 添加服务器日志观察者
    logger: TalkerLogger(
      formatter: const _PlainLoggerFormatter(),
      settings: TalkerLoggerSettings(
        enableColors: true,
      ),
      output: (message) {
        developer.log(message);
      },
    ),
  );
}

/// 打印 info
void logP(dynamic message) {
  if (!isLog) return;
  talker?.info(_getStackTraceString(message));
}

/// 打印 debug
void logD(dynamic message) {
  if (!isLog) return;
  talker?.debug(_getStackTraceString(message));
}

///打印 warning
void logW(dynamic message) {
  if (!isLog) return;
  talker?.warning(_getStackTraceString(message));
}

///打印 error
void logE(dynamic message) {
  if (!isLog) return;
  talker?.error(_getStackTraceString(message));
}

String _getStackTraceString(dynamic message) {
  final sb = StringBuffer();

  // 添加传入的消息
  if (message != null) {
    sb.write('${message.toString()}  ');
  }

  // // 添加时间戳
  // final currentTime =
  //     DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
  // sb.write('Time: $currentTime  ');

  // 添加堆栈信息 - 使用对应颜色
  sb.writeln('Stack Trace:');
  final stackTrace = StackTrace.current.toString().split('\n');

  for (var i = 0; i < stackTrace.length; i++) {
    if (i == 0 || i == 1) continue;
    final line = stackTrace[i].trim();
    if (line.isEmpty) continue;
    bool isSelfCode = line.contains(projectPackageName);
    if (!isSelfCode) {
      break;
    }
    sb.writeln('    at $line');
  }
  return sb.toString();
}

/// 打印 info
void logPDebug(dynamic message) {
  if (!isTestClient) return;
  talker?.info(_getStackTraceString(message));
}

/// 打印 debug
void logDDebug(dynamic message) {
  if (!isTestClient) return;
  talker?.debug(_getStackTraceString(message));
}

///打印 warning
void logWDebug(dynamic message) {
  if (!isTestClient) return;
  talker?.warning(_getStackTraceString(message));
}

///打印 error
void logEDebug(dynamic message) {
  if (!isTestClient) return;
  talker?.error(_getStackTraceString(message));
}
