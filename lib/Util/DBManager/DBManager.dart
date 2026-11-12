import 'dart:async';

import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Hive 数据库封装
///
/// 使用方式：
/// 1. Model 加 `@HiveType(typeId: xxx)` / `@HiveField(n)` 注解，typeId 在 `Const.dart` 统一登记
/// 2. `dart run build_runner build --delete-conflicting-outputs` 生成 Adapter
/// 3. 在 [_registerAdapters] 中注册 Adapter
/// 4. 业务侧通过 [openBox] / [get] / [put] 读写；同一 Box 的写操作需要保序时用 [runSerial]
class DBManager {
  // 单例实例
  static final DBManager instance = DBManager._internal();

  // 私有构造函数
  DBManager._internal();

  bool _hiveInitialized = false;
  Completer<void>? _initCompleter;

  /// 已打开的 Box 缓存
  final Map<String, Box<dynamic>> _boxes = {};

  /// 正在打开中的 Box，避免并发重复 openBox
  final Map<String, Future<Box<dynamic>>> _openingBoxes = {};

  /// 每个 Box 的串行操作队列尾部
  final Map<String, Future<void>> _operationTails = {};

  Future<void> init() async {
    if (_hiveInitialized) return;
    // 并发保护，避免多次同时初始化
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    try {
      final dir = await getApplicationDocumentsDirectory();
      try {
        Hive.init(dir.path);
      } catch (e) {
        // 多次初始化或平台差异导致的异常，记录但不中断
        logW('Hive.init warning: $e');
      }
      _registerAdapters();
      _hiveInitialized = true;
      _initCompleter?.complete();
    } catch (e) {
      logE('Hive init failed: $e');
      _initCompleter?.completeError(e);
    } finally {
      // 重置为可再次初始化的状态（若 completeError 则下次可重试）
      _initCompleter = null;
    }
  }

  /// 注册所有 Hive Adapter（新增 Model 后在这里追加）
  void _registerAdapters() {
    // registerAdapter(ExampleCacheModelAdapter());
  }

  /// 注册单个 Adapter，已注册的 typeId 自动跳过
  void registerAdapter<T>(TypeAdapter<T> adapter) {
    try {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter<T>(adapter);
      }
    } catch (e) {
      logW('Hive adapter registration warning: $e');
    }
  }

  /// 打开（或取已打开的）Box
  Future<Box<T>> openBox<T>(String boxName) async {
    await init();
    final cached = _boxes[boxName];
    if (cached != null && cached.isOpen) {
      return cached as Box<T>;
    }
    final opening = _openingBoxes[boxName];
    if (opening != null) {
      return (await opening) as Box<T>;
    }

    final future = Hive.openBox<T>(boxName);
    _openingBoxes[boxName] = future;
    try {
      final box = await future;
      _boxes[boxName] = box;
      return box;
    } finally {
      _openingBoxes.remove(boxName);
    }
  }

  /// 读取单条数据
  Future<T?> get<T>(String boxName, dynamic key, {T? defaultValue}) async {
    try {
      final box = await openBox<T>(boxName);
      return box.get(key, defaultValue: defaultValue);
    } catch (e) {
      logE('DBManager get failed, box: $boxName, key: $key, error: $e');
      return defaultValue;
    }
  }

  /// 读取 Box 内全部数据
  Future<List<T>> getAll<T>(String boxName) async {
    try {
      final box = await openBox<T>(boxName);
      return box.values.toList();
    } catch (e) {
      logE('DBManager getAll failed, box: $boxName, error: $e');
      return [];
    }
  }

  /// 写入单条数据
  Future<void> put<T>(String boxName, dynamic key, T value) async {
    try {
      final box = await openBox<T>(boxName);
      await box.put(key, value);
    } catch (e) {
      logE('DBManager put failed, box: $boxName, key: $key, error: $e');
    }
  }

  /// 删除单条数据
  Future<void> delete<T>(String boxName, dynamic key) async {
    try {
      final box = await openBox<T>(boxName);
      await box.delete(key);
    } catch (e) {
      logE('DBManager delete failed, box: $boxName, key: $key, error: $e');
    }
  }

  /// 清空 Box
  Future<void> clearBox<T>(String boxName) async {
    try {
      final box = await openBox<T>(boxName);
      await box.clear();
    } catch (e) {
      logE('DBManager clearBox failed, box: $boxName, error: $e');
    }
  }

  /// 按调用顺序串行执行同一 Box 的操作，避免异步写入完成顺序反转
  /// （如高频保存进度时，旧的保存晚于新的保存落盘）。
  Future<R> runSerial<R>(String boxName, Future<R> Function() operation) {
    final completer = Completer<R>();
    final tail = _operationTails[boxName] ?? Future<void>.value();
    _operationTails[boxName] = tail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  /// 关闭所有 Box（一般无需手动调用）
  Future<void> closeAll() async {
    try {
      await Hive.close();
      _boxes.clear();
    } catch (e) {
      logE('DBManager closeAll failed: $e');
    }
  }

  /// 删除所有 Box 数据（GM / 注销账号）
  Future<void> deleteAll() async {
    try {
      await init();
      await Hive.deleteFromDisk();
      _boxes.clear();
    } catch (e) {
      logE('DBManager deleteAll failed: $e');
    }
  }
}
