// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/TimeTools.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/Const.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 键值对 key
///
/// 新增 key 统一在这里声明，命名 `key_xxx`；
/// 按账号隔离的数据用 [PreferenceUtil.getKeyWithUserId] 拼 key。
class PreferenceKey {
  // ==================== App 状态 ====================
  static const String key_isFirstOpen = 'isFirstOpen';
  static const String key_isColdStart = 'isColdStart';
  static const String key_firstInstallTimeStamp = 'key_firstInstallTimeStamp';

  // ==================== 版本更新提醒 ====================
  static const String key_updateReminderDate = 'key_updateReminderDate';
  static const String key_updateReminderCount = 'key_updateReminderCount';
  static const String key_updateSkippedVersion = 'key_updateSkippedVersion';

  // ==================== 登录 ====================
  static const String key_loginState = 'loginState';
  static const String key_token = 'key_token';
  static const String key_userId = 'key_userId';
  static const String key_userInfo = 'userInfo';

  // ==================== 设置 ====================
  static const String key_appLanguage = 'key_appLanguage';
  static const String key_isDarkMode = 'key_isDarkMode';
  static const String key_enableVibration = 'key_enableVibration';

  // ==================== 网络 ====================
  // 保存域名（按测试/正式服区分前缀）
  static const String key_Domain = 'key_Domain';

  // ==================== GM ====================
  // 网络响应日志是否 format 为缩进 JSON（默认关闭）
  static const String key_httpResponseFormatJson = 'key_httpResponseFormatJson';
}

/// 键值对存储（SharedPreferences 封装）
///
/// - 少量、简单的配置/状态标志放这里；结构化、大量数据用 `DBManager`（Hive）
/// - 敏感数据（deviceId 等）用 `flutter_secure_storage`
class PreferenceUtil {
  static PreferenceUtil? _instance;
  PreferenceUtil._internal();
  static PreferenceUtil get instance {
    _instance ??= PreferenceUtil._internal();
    return _instance!;
  }

  late SharedPreferences sharedPreferences;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  // ==================== 通用读写 ====================

  String? getString(String key) => sharedPreferences.getString(key);

  Future<bool> setString(String key, String value) => sharedPreferences.setString(key, value);

  int? getInt(String key) => sharedPreferences.getInt(key);

  Future<bool> setInt(String key, int value) => sharedPreferences.setInt(key, value);

  bool? getBool(String key) => sharedPreferences.getBool(key);

  Future<bool> setBool(String key, bool value) => sharedPreferences.setBool(key, value);

  double? getDouble(String key) => sharedPreferences.getDouble(key);

  Future<bool> setDouble(String key, double value) => sharedPreferences.setDouble(key, value);

  List<String>? getStringList(String key) => sharedPreferences.getStringList(key);

  Future<bool> setStringList(String key, List<String> value) =>
      sharedPreferences.setStringList(key, value);

  /// 读取 JSON 对象，解析失败返回 null
  Map<String, dynamic>? getJson(String key) {
    final str = sharedPreferences.getString(key);
    if (!isAvailable(str)) return null;
    try {
      final value = jsonDecode(str!);
      return value is Map<String, dynamic> ? value : null;
    } catch (e) {
      logE('PreferenceUtil getJson failed, key: $key, error: $e');
      return null;
    }
  }

  Future<bool> setJson(String key, Map<String, dynamic> value) {
    return sharedPreferences.setString(key, jsonEncode(value));
  }

  /// 读取 JSON 数组，解析失败返回 null
  List<dynamic>? getJsonList(String key) {
    final str = sharedPreferences.getString(key);
    if (!isAvailable(str)) return null;
    try {
      final value = jsonDecode(str!);
      return value is List ? value : null;
    } catch (e) {
      logE('PreferenceUtil getJsonList failed, key: $key, error: $e');
      return null;
    }
  }

  Future<bool> setJsonList(String key, List<dynamic> value) {
    return sharedPreferences.setString(key, jsonEncode(value));
  }

  bool containsKey(String key) => sharedPreferences.containsKey(key);

  //todo:删除数据
  Future<bool> delete(String key) async {
    return await sharedPreferences.remove(key);
  }

  //todo:清空所有数据（GM / 注销账号）
  Future<bool> clearAll() async {
    return await sharedPreferences.clear();
  }

  /// 拼「用户维度」的存储 key。
  ///
  /// [userId] 只给需要固定账号归属的场景用。默认 null 仍表示「未指定」，会取当前缓存
  /// uid；[useCurrentUserWhenNull] 为 false 时，null 表示明确的游客身份。
  String getKeyWithUserId(
    String key, {
    int? userId,
    bool useCurrentUserWhenNull = true,
  }) {
    final resolvedUserId = userId ?? (useCurrentUserWhenNull ? getUserId() : null);
    return "${resolvedUserId}_$key";
  }

  // ==================== App 状态 ====================

  //todo:是否第一次打开
  bool isFirstOpen() {
    return sharedPreferences.getBool(PreferenceKey.key_isFirstOpen) ?? true;
  }

  Future<void> setAppOpenState() async {
    await sharedPreferences.setBool(PreferenceKey.key_isFirstOpen, false);
  }

  //todo:获取是否是冷启动
  bool isColdStart() {
    return sharedPreferences.getBool(PreferenceKey.key_isColdStart) ?? true;
  }

  Future<void> setIsColdStart(bool value) async {
    await sharedPreferences.setBool(PreferenceKey.key_isColdStart, value);
  }

  //todo:首次安装时间（毫秒时间戳，0 表示未记录）
  int getFirstInstallTimeStamp() {
    return sharedPreferences.getInt(PreferenceKey.key_firstInstallTimeStamp) ?? 0;
  }

  Future<void> setFirstInstallTimeStamp(int timestamp) async {
    await sharedPreferences.setInt(PreferenceKey.key_firstInstallTimeStamp, timestamp);
  }

  // ==================== 版本更新提醒 ====================

  /// 更新提醒按设备保存，切换账号不重置；日期跨版本共用，次数按目标版本隔离。
  bool canShowUpdateReminder(String version) {
    return !TimeTools.isToday(sharedPreferences.getString(PreferenceKey.key_updateReminderDate)) &&
        (sharedPreferences.getInt('${PreferenceKey.key_updateReminderCount}_$version') ?? 0) < 3 &&
        !(sharedPreferences.getBool('${PreferenceKey.key_updateSkippedVersion}_$version') ?? false);
  }

  Future<void> recordUpdateReminderShown(String version) async {
    final countKey = '${PreferenceKey.key_updateReminderCount}_$version';
    final count = sharedPreferences.getInt(countKey) ?? 0;
    await sharedPreferences.setString(
      PreferenceKey.key_updateReminderDate,
      TimeTools.localDateString(),
    );
    await sharedPreferences.setInt(countKey, count + 1);
  }

  Future<void> skipUpdateVersion(String version) async {
    await sharedPreferences.setBool('${PreferenceKey.key_updateSkippedVersion}_$version', true);
  }

  // ==================== 登录 ====================

  //todo:登录装态
  bool isLogin() {
    return sharedPreferences.getBool(PreferenceKey.key_loginState) ?? false;
  }

  Future<void> setLoginState(bool value) async {
    await sharedPreferences.setBool(PreferenceKey.key_loginState, value);
  }

  //todo:登录信息：token 写入后自动标记已登录
  Future<void> setLoginInfo({required String token, int? userId}) async {
    if (await sharedPreferences.setString(PreferenceKey.key_token, token)) {
      logP("登录信息存储成功");
    } else {
      logE("Failed to save login info");
    }
    if (userId != null) {
      await sharedPreferences.setInt(PreferenceKey.key_userId, userId);
    }
    if (isAvailable(token)) {
      await setLoginState(true);
    }
  }

  String? getToken() {
    return sharedPreferences.getString(PreferenceKey.key_token);
  }

  int? getUserId() {
    return sharedPreferences.getInt(PreferenceKey.key_userId);
  }

  //todo:用户信息（业务层自行定义 UserModel，toJson 后存入）
  Future<void> setUserInfo(Map<String, dynamic> value) async {
    if (!await setJson(PreferenceKey.key_userInfo, value)) {
      logE("Failed to save user info");
    }
  }

  Map<String, dynamic>? getUserInfo() {
    return getJson(PreferenceKey.key_userInfo);
  }

  Future<void> clearLoginInfo() async {
    await delete(PreferenceKey.key_loginState);
    await delete(PreferenceKey.key_token);
    await delete(PreferenceKey.key_userId);
    await delete(PreferenceKey.key_userInfo);
  }

  // ==================== 设置 ====================

  Future<void> setAppLanguageItem(String item) async {
    await sharedPreferences.setString(PreferenceKey.key_appLanguage, item);
  }

  String getAppLanguageItem(bool withDefault) {
    return sharedPreferences.getString(PreferenceKey.key_appLanguage) ?? (withDefault ? 'en' : '');
  }

  bool getIsDarkMode() {
    return sharedPreferences.getBool(PreferenceKey.key_isDarkMode) ?? false;
  }

  Future<void> setIsDarkMode(bool value) async {
    await sharedPreferences.setBool(PreferenceKey.key_isDarkMode, value);
  }

  //todo:震动开关 1：开启 0：关闭
  int getEnableVibration() {
    return sharedPreferences.getInt(PreferenceKey.key_enableVibration) ?? 1;
  }

  Future<void> setEnableVibration(int value) async {
    await sharedPreferences.setInt(PreferenceKey.key_enableVibration, value);
  }

  // ==================== 网络 ====================

  //todo:保存域名
  Future<void> setDomain(String value) async {
    await sharedPreferences.setString(testServerPrefix + PreferenceKey.key_Domain, value);
  }

  //todo:获取域名
  String? getDomain() {
    return sharedPreferences.getString(testServerPrefix + PreferenceKey.key_Domain);
  }

  Future<void> clearDomain() async {
    await delete(testServerPrefix + PreferenceKey.key_Domain);
  }

  // ==================== GM ====================

  bool getHttpResponseFormatJson() {
    return sharedPreferences.getBool(PreferenceKey.key_httpResponseFormatJson) ?? false;
  }

  Future<void> setHttpResponseFormatJson(bool value) async {
    await sharedPreferences.setBool(PreferenceKey.key_httpResponseFormatJson, value);
  }
}
