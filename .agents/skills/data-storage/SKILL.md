---
name: data-storage
description: 当用户需要读写本地数据、使用 SharedPreferences 存储、添加新的偏好设置 key、保存用户配置或状态标志、使用 Hive 数据库存结构化数据时自动触发。关键词：本地存储、SharedPreferences、PreferenceUtil、PreferenceKey、保存数据、读取数据、持久化、Hive、DBManager、数据库。
version: 1.0.0
---

# 本地数据储存规范

| 数据类型 | 方案 | 入口 |
|---------|------|------|
| 少量配置 / 状态标志 / 小 JSON | SharedPreferences | `PreferenceUtil.instance`（`lib/Util/Common/PreferenceUtil.dart`） |
| 结构化、大量、需按 key 查询的数据（阅读记录、缓存列表等） | Hive | `DBManager.instance`（`lib/Util/DBManager/DBManager.dart`） |
| 敏感 / 卸载重装需保留的数据（deviceId） | flutter_secure_storage | `DeviceUtil.getDeviceId()` 内部已封装 |

## 核心文件

- **工具类**: `lib/Util/Common/PreferenceUtil.dart`
- **Key 常量**: 同文件中的 `PreferenceKey` 类（按「App 状态 / 登录 / 设置 / 网络 / GM」分组）

## 使用方式

所有存储操作通过 `PreferenceUtil.instance` 调用，禁止直接操作 `SharedPreferences`：

```dart
import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';

// 读取
bool isFirst = PreferenceUtil.instance.isFirstOpen();
String? domain = PreferenceUtil.instance.getDomain();

// 写入
await PreferenceUtil.instance.setAppOpenState();
await PreferenceUtil.instance.setDomain('https://xxx.com');
```

### 通用读写方法（简单场景直接用，无需新增方法）

```dart
PreferenceUtil.instance.getString(key) / setString(key, value)
PreferenceUtil.instance.getInt(key)    / setInt(key, value)
PreferenceUtil.instance.getBool(key)   / setBool(key, value)
PreferenceUtil.instance.getDouble(key) / setDouble(key, value)
PreferenceUtil.instance.getStringList(key) / setStringList(key, value)
PreferenceUtil.instance.getJson(key)     / setJson(key, map)        // Map<String, dynamic>
PreferenceUtil.instance.getJsonList(key) / setJsonList(key, list)   // List<dynamic>
PreferenceUtil.instance.containsKey(key)
```

**key 仍必须先在 `PreferenceKey` 中声明**，禁止在调用处写字符串 key。被多处读写、带默认值或有业务含义的字段，按下方步骤封装成具名方法。

## 添加新存储字段（必须遵循）

### 第一步：在 PreferenceKey 中添加 key 常量

```dart
// lib/Util/Common/PreferenceUtil.dart - PreferenceKey 类
static const String key_myNewField = 'key_myNewField';
```

**命名规范：**
- 格式：`key_` + 小驼峰名称
- 示例：`key_isFirstOpen`、`key_enableVibration`

### 第二步：在 PreferenceUtil 中添加 getter/setter 方法

```dart
// Bool 类型
bool getMyBoolField() {
  return sharedPreferences.getBool(PreferenceKey.key_myNewField) ?? false;
}

Future<void> setMyBoolField(bool value) async {
  await sharedPreferences.setBool(PreferenceKey.key_myNewField, value);
}

// Int 类型
int getMyIntField() {
  return sharedPreferences.getInt(PreferenceKey.key_myNewField) ?? 0;
}

Future<void> setMyIntField(int value) async {
  await sharedPreferences.setInt(PreferenceKey.key_myNewField, value);
}

// String 类型
String? getMyStringField() {
  return sharedPreferences.getString(PreferenceKey.key_myNewField);
}

Future<void> setMyStringField(String value) async {
  await sharedPreferences.setString(PreferenceKey.key_myNewField, value);
}
```

### 第三步：对象/Model 类型需 JSON 序列化

```dart
// 存储 Model 对象 → 先序列化为 JSON String
Future<void> setMyModel(MyModel model) async {
  await sharedPreferences.setString(
    PreferenceKey.key_myNewField,
    jsonEncode(model.toJson()),
  );
}

// 读取 Model 对象 → JSON 反序列化
MyModel? getMyModel() {
  String? jsonStr = sharedPreferences.getString(PreferenceKey.key_myNewField);
  if (isAvailable(jsonStr)) {
    return MyModel.fromJson(jsonDecode(jsonStr!));
  }
  return null;
}
```

### 第四步：List 类型

```dart
// String 列表（直接用 StringList）
Future<void> saveMyList(List<String> list) async {
  await sharedPreferences.setStringList(PreferenceKey.key_myNewField, list);
}

List<String>? getMyList() {
  return sharedPreferences.getStringList(PreferenceKey.key_myNewField);
}

// 其他类型列表 → JSON 序列化
Future<void> saveMyIntList(List<int> list) async {
  await sharedPreferences.setString(
    PreferenceKey.key_myNewField,
    jsonEncode(list),
  );
}
```

## 带用户 ID 的 Key（用户隔离数据）

当数据需要按用户隔离时，使用 `getKeyWithUserId()` 拼接 key：

```dart
// ✅ 正确 - 用户隔离的数据（默认取当前登录用户 getUserId()）
bool hasShownGuide() {
  return sharedPreferences.getBool(getKeyWithUserId(PreferenceKey.key_hasShownGuide)) ?? false;
}

Future<void> setHasShownGuide(bool value) async {
  await sharedPreferences.setBool(getKeyWithUserId(PreferenceKey.key_hasShownGuide), value);
}

// 固定账号归属：显式传 userId；useCurrentUserWhenNull: false 时 null 表示游客
getKeyWithUserId(PreferenceKey.key_xxx, userId: uid, useCurrentUserWhenNull: false);
```

**使用场景**：引导展示记录、用户专属设置、按账号缓存的数据等。

## 测试环境 Key 前缀

域名等测试/线上区分的数据使用 `testServerPrefix` 前缀：

```dart
// 参考 getDomain / setDomain 的实现
await sharedPreferences.setString(testServerPrefix + PreferenceKey.key_Domain, value);
```

## 删除数据

```dart
// 删除单个 key
await PreferenceUtil.instance.delete(PreferenceKey.key_myNewField);

// 清除登录信息（退出登录时调用）
await PreferenceUtil.instance.clearLoginInfo();

// 清除所有数据（慎用）
await PreferenceUtil.instance.clearAll();
```

## 登录信息

```dart
await PreferenceUtil.instance.setLoginInfo(token: token, userId: uid); // 写入 token 并标记已登录
PreferenceUtil.instance.isLogin();
PreferenceUtil.instance.getToken();     // 网络层 Authorization 请求头自动读取
PreferenceUtil.instance.setUserInfo(userModel.toJson());  // 用户信息存 JSON，Model 由业务定义
await PreferenceUtil.instance.clearLoginInfo();             // 退出登录 / token 失效
```

## Hive 数据库（DBManager）

1. Model 加 `@HiveType(typeId: xxx)` / `@HiveField(n)` 注解，**typeId 在 `lib/Util/Const.dart` 统一登记**（全局唯一、递增、不可复用）
2. `dart run build_runner build --delete-conflicting-outputs` 生成 `XxxAdapter`
3. 在 `DBManager._registerAdapters()` 中 `registerAdapter(XxxAdapter())`
4. 读写：

```dart
const String _boxName = 'example_cache_box';   // Box 名在调用方集中定义

await DBManager.instance.put<ExampleCacheModel>(_boxName, id, model);
final model = await DBManager.instance.get<ExampleCacheModel>(_boxName, id);
final all = await DBManager.instance.getAll<ExampleCacheModel>(_boxName);
await DBManager.instance.delete<ExampleCacheModel>(_boxName, id);

// 高频写入需保序（如进度保存）：同一 Box 的操作串行执行
await DBManager.instance.runSerial(_boxName, () => DBManager.instance.put(_boxName, id, model));
```

- `DBManager.instance.init()` 已在 `main.dart` 调用；`openBox` 有并发保护，可直接调用
- 按账号隔离的数据：key 里拼 userId（如 `'${uid}_$id'`），与 `getKeyWithUserId` 思路一致

## 注意事项

- `init()` 在 `main.dart` 启动时已调用，无需重复初始化
- `isAvailable()` 来自 `lib/Util/Common/Tools.dart`，用于判断值是否有效（非 null、非空字符串）
- 写操作均为 `async`，需要 `await`
- 读操作为同步，直接调用无需 `await`
