---
name: network-request
description: 添加/调用 API 接口、发起网络请求、对接后端接口、定义接口路径常量、解析接口响应、处理接口成功失败与按业务错误码分流时触发。关键词：网络请求、API、接口、调接口、对接接口、NetWorkManagerUtil、ApiConfig、GET、POST、PUT、DELETE、urlXxx、接口路径、响应解析、业务 code、错误码。
version: 1.1.0
---

# 网络请求规范

本项目使用 `NetWorkManagerUtil` 封装 Dio，所有网络请求必须通过该工具类发起。

## 核心文件

- **网络工具类**: `lib/Util/NetWorkManager/NetWorkManagerUtil.dart`
- **API 路径配置**: `lib/Util/Common/ApiConfig.dart`

---

## Step 1：在 ApiConfig.dart 定义接口路径常量

**位置**：`lib/Util/Common/ApiConfig.dart`，按模块分类添加注释分组：

```dart
///用户相关
const String urlGetUserInfo = "/user/getUserInfo";
```

**命名规范：**
- 格式：`url` + 大驼峰功能名
- 示例：`urlGetUserInfo`、`urlExampleList`、`urlAuthLogin`
- 同一模块的接口放在同一个 `///模块名` 注释分组下，路径前缀以后端文档为准

**环境配置（同文件）：**
- `baseUrl`：`isTestServer` 为 true 时取 `testUrl`（GM 可在 `innerTestUrl` / `simTestUrl` 间切换），否则 `productUrl`
- `isEnableCloudDomain`：开启后启动时从 `initBaseUrl + urlCloudRouteDomain` 拉取动态域名（见 `AppMgr.getDomain`）
- `apiNotPrintMap`：正式包不打印响应体的接口

---

## Step 2：在 Controller 中调用接口

### GET 请求

```dart
import 'package:flutter_framework/Util/Common/ApiConfig.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/NetWorkManager/NetWorkManagerUtil.dart';

Future<XxxModel?> getXxx({required int id}) async {
  try {
    var response = await NetWorkManagerUtil.instance.get(
      urlXxx,
      params: {'id': id},
    );
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      XxxModel model = XxxModel.fromJson(response.data);
      if (model.code == 200) {
        return model.result;
      } else {
        logW('getXxx business error: ${model.msg}');
        showToast(model.msg ?? '~加载失败');
      }
    }
  } catch (e) {
    logE('getXxx error: $e');
  }
  return null;
}
```

### POST 请求

```dart
Future<bool> postXxx({required String content}) async {
  try {
    var response = await NetWorkManagerUtil.instance.post(
      urlXxx,
      params: {'content': content},
      retryTimes: 1,  // 操作类接口建议加重试
    );
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      CommonModel model = CommonModel.fromJson(response.data);
      return model.code == 200;
    }
  } catch (e) {
    logE('postXxx error: $e');
  }
  return false;
}
```

### PUT 请求

```dart
Future<bool> putXxx({required int id, required String value}) async {
  try {
    var response = await NetWorkManagerUtil.instance.put(
      urlXxx,
      data: {'id': id, 'value': value},
    );
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      CommonModel model = CommonModel.fromJson(response.data);
      return model.code == 200;
    }
  } catch (e) {
    logE('putXxx error: $e');
  }
  return false;
}
```

### DELETE 请求

```dart
Future<bool> deleteXxx() async {
  try {
    var response = await NetWorkManagerUtil.instance.delete(urlXxx);
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      CommonModel model = CommonModel.fromJson(response.data);
      return model.code == 200;
    }
  } catch (e) {
    logE('deleteXxx error: $e');
  }
  return false;
}
```

---

## Model 定义提醒

> **服务器文档通常只展示 `result` 内部数据，但定义 Model 时必须补全外层包装字段：**
> `code`、`msg`、`result`、`sysAt`、`cost`、`traceId`。
> 详见 `create-model` skill 的 Step 2。

## 四种响应处理模式

### 模式一：返回整个 result 对象

```dart
if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
  XxxModel model = XxxModel.fromJson(response.data);
  if (model.code == 200) {
    return model.result;  // 返回 result 部分
  }
}
```

### 模式二：返回 bool（操作类接口）

```dart
if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
  CommonModel model = CommonModel.fromJson(response.data);
  return model.code == 200;
}
```

### 模式三：直接解析整个响应

```dart
if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
  return XxxModel.fromJson(response.data);
}
```

### 模式四：暴露业务 code（按码分流，特定业务码触发特定动作）

当**同一动作类接口的不同失败码需要不同 UI 处理**时（如「余额不足→跳充值」「未登录→跳登录」「版本过低→提示更新」），只返回 `bool` 不够——底层要把**业务 code 暴露给调用方**，由调用方按码分流。

**① 底层返回 `Future<int?>`**（业务 code；`null` = 网络/传输/异常失败）：

```dart
/// 返回业务 code（200=成功，其余=业务失败码）；网络/异常返回 null。
static Future<int?> _postXxx({...}) async {
  try {
    final response = await NetWorkManagerUtil.instance.post(url, params: params, retryTimes: 1);
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return CommonModel.fromJson(response.data).code;
    }
  } catch (e) {
    logE('postXxx error: $e');
  }
  return null;
}
```

**② 用语义常量，禁止裸魔法码**（全局通用码放 `lib/Common/Config/ServerErrorCode.dart`，模块私有码可在接口文件内集中定义；服务端确认前可写占位 + `TODO`）：

```dart
// lib/Common/Config/ServerErrorCode.dart
static const int bizSuccess = 200;
static const int tokenExpired = 401;
// 模块私有
static const int codeInsufficientBalance = 10001;
```

**③ 上层按码分流**：成功 / 特定码特殊动作 / 其余走「错误 toast 规范」兜底：

```dart
Future<bool> _handleResult(int? code, Future<void> Function() onSuccess) async {
  if (code == ServerErrorCode.bizSuccess) {
    await onSuccess();
    return true;
  }
  if (code == XxxApi.codeInsufficientBalance) {
    showToast('~Insufficient balance');
    toRechargePage();                                      // 余额不足 → 跳充值
    return false;
  }
  showToastNormalError(null, code: code == null ? null : '$code'); // 其余/网络失败兜底
  return false;
}
```

**④ 多数调用方只关心成败时，再包一层 `bool` 对外**，避免每处都判码：

```dart
static Future<bool> doXxx({...}) async => (await _postXxx(...)) == ServerErrorCode.bizSuccess;
```

---

## 错误 toast 规范（code + msg 组合）

### 何时该弹错误 toast

> **只有「执行动作类」接口失败才弹错误 toast（含错误码）。**

- ✅ **需要**：用户主动触发、会改变服务端状态、且期待结果反馈的接口 —— 如领取奖励、解锁内容、签到、下单/购买、提交评论、收藏切换等。失败要让用户知道「没成功 + 为什么」。
- ❌ **不需要**：
  - **纯查询 / 列表 / 详情**接口（getXxx / list / detail）—— 失败用页面的空状态 / 错误态 UI（`NotLoadedUI`）表达，不弹 toast 打扰。
  - **后台自动上报**接口（进度同步、打点、曝光等）—— 非用户主动触发，失败只 `logE`，静默重试即可。

### code 和 msg 怎么组合（统一用项目两个标准助手，错误码一律放末尾 `[code]`）

| 场景 | 用法 | 输出 |
|------|------|------|
| 有 Model 包装、服务端 `msg` 有意义（业务失败） | `model.showErrorToast()` | `"${msg} [${code}]"` |
| 无 model / msg 可能为空 / 网络·传输层失败 | `showToastNormalError(msg, code: '${code}')` | `"${'error_message_9'.tr}: {msg} [code]"` + 错误震动 |
| 手写拼接（msg 兜底翻译文案） | `"${model.msg ?? 'xxx_message'.tr} [${model.code}]"` | msg 或兜底文案 + `[code]` |

- `CommonModel` 自带 `showErrorToast()`（内部即 `displayMsg = "${msg} [${code}]"`），业务 Model 可参照实现。
- `showToastNormalError(Object? msg, {String? code})` 在 `lib/Util/SheetAndAlter/Toast.dart`，前缀通用文案 `error_message_9` 并自带错误震动，适合「无业务 msg / 网络失败」兜底。
- **业务失败传业务 `code`，网络失败传 `response.statusCode`**（如 `networkRequestFailed`），都进 `[code]`。

### 动作类接口完整范式（三分支：业务失败 / 网络失败 / 异常都给反馈）

```dart
Future<bool> doActionXxx({required int id}) async {
  try {
    final response = await NetWorkManagerUtil.instance.post(
      urlXxx,
      params: {'id': id},
      retryTimes: 1,
    );
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final model = CommonModel.fromJson(response.data);
      if (model.code == 200) return true;
      model.showErrorToast();                          // 业务失败：msg + [业务码]
      return false;
    }
    showToastNormalError(null, code: '${response.statusCode}'); // 网络/传输层失败：通用文案 + [状态码]
  } catch (e) {
    logE('doActionXxx error: $e');
    showToastNormalError(e);                            // 异常兜底：带上具体错误 → "error_message_9: <e>"
  }
  return false;
}
```

> 查询类接口反例（**不要**弹 toast）：失败仅 `logW/logE` 后 `return null`，由调用方渲染空/错误态。

---

## NetWorkManagerUtil 方法签名

```dart
// GET
NetWorkManagerUtil.instance.get(String url, {required Map<String, dynamic> params, int retryTimes = 0});

// POST
NetWorkManagerUtil.instance.post(String url, {required Map<String, dynamic> params, int retryTimes = 0});

// PUT
NetWorkManagerUtil.instance.put(String url, {required Map<String, dynamic> data, int retryTimes = 0});

// DELETE
NetWorkManagerUtil.instance.delete(String url, {int retryTimes = 0});

// 上传（multipart，字段名默认 files）
NetWorkManagerUtil.instance.uploadFileSingle(String url, String filePath, {Map<String, dynamic>? extraData, ProgressCallback? onSendProgress});
NetWorkManagerUtil.instance.uploadFileMultiple(String url, List<String> filePaths, {String fileFieldName = 'files', ...});

// 下载（json / stream / plain / bytes）
NetWorkManagerUtil.instance.downloadFile(String url, HttpDownLoadType type, {required ProgressCallback onReceiveProgress});
```

**公共请求头 / 登录失效：**
- 公共请求头在 `NetWorkManagerUtil.getHeader()` 中统一维护（token、平台、语言、版本、时区、deviceId），新增公共字段改这里，不要在单个请求里拼
- 响应 `code == ServerErrorCode.tokenExpired`（401）时自动 `reLogin()`：清登录信息 → `RegisterControllerMgr.unregister()` → 派发 `EventBusModelLoginStateChange` → 回调 `NetWorkManagerUtil.onTokenExpired`（由登录模块注册跳登录页）
- 响应体 `sysAt` 字段会自动同步服务端时间到 `TimeMgr`

**注意：**
- `params` 和 `data` 均为 `Map<String, dynamic>`，必填
- `retryTimes` 默认 0，操作类接口建议设为 1
- 响应体中 `code == 200` 表示业务成功，`statusCode == 200` 表示 HTTP 成功

---

## 重要规范

- **禁止直接使用 Dio**，必须通过 `NetWorkManagerUtil.instance`
- 接口路径常量统一在 `ApiConfig.dart` 定义，禁止在调用处写字符串路径
- 所有接口调用必须包含 `try-catch` 异常处理
- 错误日志使用 `logE()`，警告使用 `logW()`
- 错误 toast 仅「执行动作类」接口需要（claim/解锁/提交等），含错误码；纯查询/后台上报不弹 —— 详见上文「错误 toast 规范（code + msg 组合）」
- 不同业务失败码需不同动作（余额不足→充值、未登录→登录、版本过低→更新等）时，底层返回业务 `code` 暴露给调用方按码分流，业务码用语义常量（禁裸数字）—— 详见上文「模式四」

## 参考文件

- **Service 示例**: `lib/MainPage/Example/ViewModel/ExampleService.dart`（查询类接口 + Mock 开关）
- **Mock 示例**: `lib/MainPage/Example/Mock/ExampleMockServer.dart`（按真实响应结构返回假数据）
- **通用 Model**: `lib/Common/Model/CommonModel.dart`
- **错误码**: `lib/Common/Config/ServerErrorCode.dart`、`lib/Common/Config/ClientErrorCode.dart`
