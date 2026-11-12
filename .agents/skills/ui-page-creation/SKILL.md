---
name: ui-page-creation
description: 当用户需要新建页面、创建新界面、添加新 Page、新建功能模块时自动触发。关键词：新建页面、创建页面、新增页面、新功能、新模块、create page、新建界面、生成页面结构。
version: 1.0.0
---

# UI 页面创建规范

> ## ⚠️ 写代码硬性规则（违反一次即不合格）
>
> 1. **i18n**：UI 文本优先 `'key'.tr`（已知 key 时），无 key 才用 `'~原文'`；`lib/Common/Debug/` 整体豁免
> 2. **样式 Token**：颜色 `getAppFigmaColors` / `FigmaVariables`；间距/字号/圆角只用 `FigmaVariables.xxx`
> 3. 详见 `AGENTS.md` 顶部「硬性规范」+ `ui-modification`

---

新建页面使用 `/create-page` 命令生成完整结构，本文件补充关键规范说明。

## 目录结构

```
lib/MainPage/XxxPage/
├── Page/
│   └── XxxPage.dart          # 主页面
├── ViewModel/
│   ├── XxxController.dart    # GetX Controller（页面状态）
│   └── XxxService.dart       # 可选：接口层，只负责请求与解析
├── Model/                     # 可选
│   └── XxxModel.dart
├── Mock/                      # 可选：接口未就绪时的本地 Mock 响应
│   └── XxxMockServer.dart
└── Widget/                    # 可选；无 Item/Button 等语义后缀时用 View；Dialog/Sheet/Item/Button 等不再叠 View
    ├── XxxItem.dart
    ├── XxxDialog.dart           # 弹窗
    ├── XxxSheet.dart            # BottomSheet
    ├── LoadingProgressView.dart
    └── CapsuleButton.dart     # 示例：模块内不必重复模块名前缀
```

命名细则见 `project-rules` skill：Widget 后缀规则、模块内不必重复前缀、需消歧时再加模块前缀。

---

## 页面模板（带参数版本，推荐）

```dart
import 'package:flutter_framework/Common/Widget/Animation/LottieAnimationView.dart';
import 'package:flutter_framework/Common/Widget/SmartAppBar.dart';
import 'package:flutter_framework/MainPage/Xxx/ViewModel/XxxController.dart';
import 'package:flutter_framework/Util/Common/NotLoadedUI.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class XxxPage extends StatefulWidget {
  const XxxPage({super.key, this.arguments});

  final dynamic arguments;

  @override
  State<XxxPage> createState() => _XxxPageState();
}

class _XxxPageState extends State<XxxPage> {
  late XxxController _controller;
  Map<String, dynamic>? arguments;

  @override
  void initState() {
    super.initState();
    arguments = widget.arguments is Map<String, dynamic>
        ? widget.arguments as Map<String, dynamic>
        : <String, dynamic>{};
    _controller = findGetxController(XxxController.new, permanent: false);
    _controller.init(arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return SmartAppBar(
      title: Text('~标题'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (_controller.isLoading.value) return const LottieAnimationView();
      if (_controller.hasError.value) {
        return NotLoadedUI(
          message: _controller.errorMessage.value,
          onRefresh: () => _controller.loadData(),
        );
      }
      return _buildContent();
    });
  }

  Widget _buildContent() {
    // 页面主体内容
    return const SizedBox();
  }
}
```

## Controller 模板

```dart
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/NetWorkManager/NetWorkManagerUtil.dart';
import 'package:get/get.dart';

class XxxController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool hasError = false.obs;
  RxString errorMessage = ''.obs;
  Map<String, dynamic>? arguments;

  Future<void> init({Map<String, dynamic>? arguments}) async {
    this.arguments = arguments;
    await loadData();
  }

  Future<void> loadData() async {
    if (isLoading.value) return;
    isLoading.value = true;
    hasError.value = false;

    try {
      // TODO: 实现数据加载
    } catch (e) {
      logE('XxxController loadData error: $e');
      hasError.value = true;
      errorMessage.value = '~网络异常，请稍后重试';
    } finally {
      isLoading.value = false;
    }
  }
}
```

---

## 关键规范

### Controller 获取（必须遵循）

```dart
// ✅ 正确
_controller = findGetxController(XxxController.new, permanent: false);

// ❌ 错误
_controller = Get.find<XxxController>();
_controller = Get.put(XxxController());
```

### 状态管理（必须遵循）

- **默认优先 GetX**：Page 级响应式状态 → `GetxController` + `.obs` + `Obx`
- 小叶子 Widget：先判断 GetX 是否更合适（已有 Controller、细粒度 rebuild、可能共享、性能）；仅纯局部且 GetX 无显著收益时可用 `setState`
- 详见 `project-rules`「状态管理」

### GetX API（必须遵循）

- 返回/跳转：`Get.back()`、`Get.toNamed()` — 不用 `Navigator.pop` / `pushNamed`
- 平台/屏幕：`GetPlatform`、`Get.width` / `Get.height` — 不用 `Platform`、`MediaQuery.of(context).size`
- 详见 `AGENTS.md` #8、`project-rules`「GetX API 优先」

### 带参数的页面（必须遵循）

以下命名路由传参规则用于业务页面。测试 / GM / Debug / 预览页面直接通过 `Get.to(() => XxxPage(arguments: {...}))` 打开，从 `widget.arguments` 读取参数，不注册命名路由。

| 规则 | 说明 |
|------|------|
| 不继承 `BaseFulWidget`（新页面） | 直接继承 `StatefulWidget` |
| Widget 声明 `final dynamic arguments` | 由 `Route.dart` 注册时传入 |
| `initState` 从 `widget.arguments` 解析 | 缓存到 State 的 `arguments`；缺省为 `{}` |
| 禁止在 Page 内使用 `Get.arguments` | 跳转仍用 `Get.toNamed(..., arguments: {...})` |

**强制规则**：新页面传参走 `Route.dart` 的 `(context, [arguments]) => XxxPage(arguments: arguments)` + `widget.arguments`。不要用 `Get.arguments`；不要用 `XxxPage({required this.id})` 等业务字段构造函数（`arguments` 容器字段除外）。已用 `BaseFulWidget` 的老页面保持 `required super.arguments` 即可。

### 加载状态（必须遵循三态处理）

| 状态 | 显示组件 |
|------|----------|
| 加载中 | `LottieAnimationView()` |
| 加载成功 | 正常内容 |
| 加载失败 | `NotLoadedUI(onRefresh: ...)` |

### 页面入口

测试 / GM / Debug / 预览页面直接用 `Get.to(() => const XxxPage())` 打开，不向 `lib/Util/Router/Route.dart` 添加 import、路由常量或 routes 注册项；详见 [routing](../routing/SKILL.md)。

业务页面创建后，必须在 `lib/Util/Router/Route.dart` 中注册：
1. 添加 import
2. 添加路由常量 `const String xxxPage = '/xxxPage';`
3. 在 routes Map 中注册：无参 `(context) => const XxxPage()`；有参 `(context, [arguments]) => XxxPage(arguments: arguments)`
4. 在 `lib/Util/Router/RouteOpenPage.dart` 添加 `toXxxPage(...)` 跳转方法

---

## 常用组件速查

| 需求 | 组件/工具 |
|------|----------|
| AppBar | `SmartAppBar` (`lib/Common/Widget/SmartAppBar.dart`) |
| 全屏加载 | `LottieAnimationView` (`lib/Common/Widget/Animation/`) |
| 空状态/错误 | `NotLoadedUI` (`lib/Util/Common/NotLoadedUI.dart`) |
| 网络图片 | `NetworkImageUtil` (`lib/Util/Common/NetworkImageUtil.dart`) |
| 下拉刷新 | `RefreshLoaderUtil` (`lib/Util/RefreshLoader/`) |
| Toast | `showToast('~文字')` |
| 返回上一页 | `Get.back()` |
| SafeArea | `SmartSafeArea`（替代 Flutter 原生 SafeArea） |

---

## i18n 多语言

```dart
Text('feedback'.tr)     // 已知 key → 用 .tr
Text('~提交成功')        // 未知 key → 用 ~ 前缀，不加 .tr
showToast('~操作成功')
logD('用户点击了按钮');  // 日志不需要多语言

// 组件默认文案：可空参数 + 展示时再取（勿 const/final/默认参数写 .tr）
// Text(widget.title ?? 'ready_wear_look'.tr)
```

完整规则（默认参数 / `const` / `final`、存 key 再 tr）见 **`ui-modification` §14**。

## 参考文件

- `lib/MainPage/Example/Page/ExampleListPage.dart`（三态 + 下拉刷新 + 上拉加载）
- `lib/MainPage/Example/Page/ExampleDetailPage.dart`（命名路由传参）
- `lib/MainPage/Example/ViewModel/ExampleListController.dart`
- `lib/MainPage/Example/ViewModel/ExampleService.dart`（接口层 + Mock 开关）
