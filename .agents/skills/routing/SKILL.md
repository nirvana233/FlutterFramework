---
name: routing
description: 当用户需要注册新路由、添加新页面路由、进行页面跳转、配置导航路由、新增路由常量时自动触发。关键词：路由、Route、导航、Get.toNamed、路由注册、页面跳转、路由常量、Route.dart。
version: 1.0.0
---

# 路由注册与导航规范

业务页面使用 GetX 命名路由，路由配置集中在 `lib/Util/Router/Route.dart`，跳转方法集中在 `lib/Util/Router/RouteOpenPage.dart`。

## 测试 / GM / Debug / 预览页面

测试相关页面直接用 `Get.to(() => const XxxPage())` 打开，不在 `Route.dart` 添加 import、路由常量或 routes 注册项。需要参数时直接传入页面的 `arguments` 构造参数，例如 `Get.to(() => XxxPage(arguments: {...}))`，页面仍从 `widget.arguments` 读取。下文命名路由注册流程仅适用于业务页面。

> 导航 API 统一用 `Get.toNamed()` / `Get.back()` 等，不用 `Navigator`（见 `AGENTS.md` #8、`project-rules`「GetX API 优先」）。

## 核心文件

- `lib/Util/Router/Route.dart`：路由常量 + routes 注册表 + `generateRoute`（含无转场动画路由集合 `_noTransitionRoutes`）
- `lib/Util/Router/RouteOpenPage.dart`：`toXxxPage()` 跳转方法（统一参数结构）
- `lib/Util/Router/PageRouteObserver.dart`：维护 `currentPageName` 与页面存在态 `PageStateMgr`

---

## 注册新路由（4步完成）

### Step 1：添加 import

```dart
import 'package:flutter_framework/MainPage/Xxx/Page/XxxPage.dart';
```

### Step 2：添加路由常量（按字母顺序插入）

```dart
const String xxxPage = '/xxxPage';
```

**命名规范：**
- 格式：小驼峰 + `Page` 后缀
- 示例：`exampleListPage`、`settingPage`、`profileEditPage`

### Step 3：在 routes Map 中注册

```dart
final Map<String, dynamic> routes = {
  // 无参数
  xxxPage: (context) => const XxxPage(),
  // 有参数：generateRoute 会把 settings.arguments 作为第二参传入
  yyyPage: (context, [arguments]) => YyyPage(arguments: arguments),
};
```

**重要**：需要传参的页面在 routes 中声明第二参数 `arguments`，并传给 Page 构造函数；**页面内用 `widget.arguments` 解析，禁止在 Page 里读 `Get.arguments`**。

### Step 4：在 RouteOpenPage.dart 添加跳转方法

```dart
Future<void> toXxxPage({required int id, String? title}) async {
  await Get.toNamed(xxxPage, arguments: {'id': id, 'title': ?title});
}
```

业务代码调用 `toXxxPage(...)`，不在各处手拼 `Get.toNamed(xxxPage, arguments: {...})`，参数结构只在一处维护。
需要「进入/返回都无转场动画」的页面，把路由名加入 `Route.dart` 的 `_noTransitionRoutes`。

---

## 页面跳转

### 普通跳转（压栈）

```dart
import 'package:flutter_framework/Util/Router/Route.dart';
import 'package:get/get.dart';

// 无参数跳转
Get.toNamed(xxxPage);

// 带参数跳转
Get.toNamed(
  xxxPage,
  arguments: {'id': id, 'title': title},
);
```

### 替换跳转（替换当前页）

```dart
Get.offNamed(xxxPage);
Get.offNamed(xxxPage, arguments: {'id': id});
```

### 清空栈跳转（回到根页面，常用于退出登录）

```dart
Get.offAllNamed(mainPage);   // 或 toMainPage(tabIndex: 0)
Get.offAllNamed(loginPage);  // 接入登录模块后
```

### 返回上一页

```dart
Get.back();
Get.back(result: returnValue);  // 带返回值
```

---

## 目标页面接收参数

```dart
// ✅ 带参数的页面 - 不继承 BaseFulWidget，直接继承 StatefulWidget
class XxxPage extends StatefulWidget {
  const XxxPage({super.key, this.arguments});

  final dynamic arguments;

  @override
  State<XxxPage> createState() => _XxxPageState();
}

class _XxxPageState extends State<XxxPage> {
  Map<String, dynamic>? arguments;

  @override
  void initState() {
    super.initState();
    // 从 widget.arguments 解析并缓存；无参或类型不对时用空 Map
    arguments = widget.arguments is Map<String, dynamic>
        ? widget.arguments as Map<String, dynamic>
        : <String, dynamic>{};
    _controller.init(arguments: arguments);
  }
}
```

**注意：**
- 带参数的新页面优先 `StatefulWidget` + `final dynamic arguments` + State 内缓存（参考 `lib/MainPage/Example/Page/ExampleDetailPage.dart`）。
- **禁止**在 Page 的 `initState` 里使用 `Get.arguments`。
- 已继承 `BaseFulWidget` 的老页面可继续 `XxxPage({required super.arguments})`，在 State 里用 `widget.arguments`（与 `WebViewPage`、`MainPage` 一致）。

---

## 获取当前页面名称

```dart
import 'package:flutter_framework/Util/Router/Route.dart';

// 获取当前页面名称（用于判断当前在哪个页面）
String? name = currentPageName;

// 在页面入口设置当前页面名称（通常在 initState 中调用）
setCurrentPageName(xxxPage);
```

---

## 完整示例

**Route.dart 新增路由：**

```dart
// 1. 添加 import
import 'package:flutter_framework/MainPage/NewFeature/Page/NewFeaturePage.dart';

// 2. 添加路由常量
const String newFeaturePage = '/newFeaturePage';

  // 3. 在 routes Map 中注册
final Map<String, dynamic> routes = {
  // ... 其他路由
  newFeaturePage: (context, [arguments]) => NewFeaturePage(arguments: arguments),
};
```

**RouteOpenPage.dart 新增跳转方法：**

```dart
Future<void> toNewFeaturePage({required int featureId}) async {
  await Get.toNamed(newFeaturePage, arguments: {'featureId': featureId});
}
```

**业务代码跳转：**

```dart
toNewFeaturePage(featureId: id);
```

---

## 注意事项

- 路由常量必须以 `/` 开头
- 业务命名路由统一在 `Route.dart` 中管理，禁止在其他文件定义路由字符串；测试相关页面按上文直接打开
- token 失效（接口 code 401）时 `NetWorkManagerUtil.reLogin()` 会清登录信息并回调 `NetWorkManagerUtil.onTokenExpired`；接入登录模块后在该回调里 `Get.offAllNamed(loginPage)`，并用 `currentPageName` 防止重复跳转登录页
- 参考实现：`lib/MainPage/Example/`（列表页无参、详情页带参）
