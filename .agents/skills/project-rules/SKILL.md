---
name: project-rules
description: 当用户需要开发较大功能、新建模块、涉及多文件改动时自动触发。关键词：新功能、新模块、多文件、代码规范、命名规范、目录结构、模块前缀。
version: 1.0.0
---

# 文件命名与代码规范

> ## ⚠️ 写代码硬性规则（违反一次即不合格）
>
> 1. **i18n**：UI 文本优先 `'key'.tr` / `'key'.trParams`（已知 key 时），无 key 才用 `'~原文'`；带参数兜底允许 `'~文案 @param1'.trParams`（`~` 仅与裸 `.tr` 互斥）；默认 UI 文案在展示处求值，勿 const/final/构造默认写 `.tr`（见 `ui-modification` §14）；`lib/Common/Debug/` 整体豁免
>    - 模拟服务器响应的 **Mock 文案**同样豁免，不受目录限制；直接模拟返回原文，不加 `~` 或 `.tr`。客户端默认 UI 文案仍遵循原规则（见 `ui-modification` §14.1）。
> 2. **样式 Token**：颜色 `getAppFigmaColors` / `FigmaVariables`；间距/字号/圆角只用 `FigmaVariables.xxx`，禁裸数字
> 3. **命名**：语义后缀（Button/Text/Dialog/Sheet/Alert/Item 等）不叠 View；弹窗用 `Dialog`、BottomSheet 用 `Sheet`；模块内不重复模块前缀，需消歧时再加
> 4. **状态管理**：**默认优先 GetX**；仅小叶子 Widget 纯局部且 GetX 无显著收益时可用 `setState`；详见下文「状态管理」
> 5. **GetX API 优先**：`Get.back()` / `Get.toNamed()`、`GetPlatform`、`Get.width` / `Get.height`；详见下文「GetX API 优先」
> 6. **analyze 仅剩 import 排序**：不修 `directives_ordering`，见 `analyze-hygiene`
> 7. 详见 `AGENTS.md` 顶部「硬性规范」+ `ui-modification`

---

## 目录结构

```
lib/MainPage/[模块名]/
├── Page/
│   └── [模块名]Page.dart
├── ViewModel/
│   ├── [模块名]Controller.dart
│   └── [模块名]Service.dart       # 可选
├── Model/
│   ├── [模块名]Model.dart
│   └── [模块名]Model.g.dart       # 自动生成
├── Mock/                          # 可选：接口未就绪时的本地 Mock 响应
│   └── [模块名]MockServer.dart
└── Widget/
    ├── XxxItem.dart               # 列表项 / 单元项，Item 后缀不再叠 View
    ├── LoadingProgressView.dart   # 无 Item/Button 等语义后缀时保留 View
    └── CapsuleButton.dart         # Button/Text/Dialog 等语义后缀不再叠 View
```

## 文件命名规范

| 类型 | 文件名 | 类名 |
|------|--------|------|
| 页面 | `XxxPage.dart` | `XxxPage` |
| Controller | `XxxController.dart` | `XxxController` |
| Service | `XxxService.dart` | `XxxService` |
| Model | `XxxModel.dart` | `XxxModel` |
| Widget（通用） | `XxxView.dart` | `XxxView` |
| Widget（语义后缀） | `XxxButton.dart` / `XxxText.dart` 等 | 与文件名一致 |
| Manager | `XxxMgr.dart` | `XxxMgr` |
| 弹窗（Dialog） | `XxxDialog.dart` | `XxxDialog` |
| 底部抽屉（BottomSheet） | `XxxSheet.dart` | `XxxSheet` |

### 弹窗 vs BottomSheet 命名

| UI 形态 | 后缀 | 示例 | 禁止 |
|---------|------|------|------|
| 弹窗（`showDialog` / 居中浮层） | **`Dialog`** | `SetNameDialog`、`SettingsDialog` | `SetNameDialogView`、`SettingsBottomSheet` |
| 底部抽屉（`showModalBottomSheet` / `Get.bottomSheet`） | **`Sheet`** | `VersionUpdateSheet`、`GenresSheet` | `VersionUpdateBottomSheet`、`GenresSheetView` |

- 弹窗统一 **`Dialog`**，不用 `BottomSheet` 命名弹窗类
- BottomSheet 统一 **`Sheet`**，文件名/类名不带 `BottomSheet` 后缀（`ReportSheet`，非 `ReportBottomSheet`）
- 二者均属于语义后缀，**不再叠 `View`**
- 历史遗留 `XxxAlert` 可保留；**新建弹窗优先 `Dialog`**

### Widget 后缀：View vs 语义后缀

- **默认**：模块内通用子组件用 `View` 后缀，如 `LoadingProgressView`、`ProfileHeaderView`
- **已有组件语义后缀时，不再叠 `View`**：`Button`、`Text`、`Dialog`、`Sheet`、`Alert`、`Input`、`Tile`、`Bar`、**`Item`** 等

```dart
// ✅ 正确
SetNameDialog.dart          → class SetNameDialog           // 弹窗
SettingsDialog.dart         → class SettingsDialog
VersionUpdateSheet.dart     → class VersionUpdateSheet      // BottomSheet
CapsuleButton.dart          → class CapsuleButton
ChoiceItem.dart             → class ChoiceItem              // Item 后缀，不叠 View
LoadingProgressView.dart    → class LoadingProgressView     // 无 Item/Button 等后缀，保留 View

// ❌ 冗余 / 混用
SetNameDialogView.dart      → class SetNameDialogView
VersionUpdateBottomSheet.dart → class VersionUpdateBottomSheet  // 应用 Sheet
SettingsBottomSheet.dart    → class SettingsBottomSheet       // 弹窗误用 BottomSheet
```

### 模块内命名（模块前缀）

- **模块目录即命名空间**：`lib/MainPage/[模块名]/` 内的类名/文件名**不必**再带模块名前缀
- **需要消歧时**（名字过于通用，或与全局 / 其他模块重名）：才加模块前缀，且前缀只用**一个**模块名，不叠加

```dart
// 目录：lib/MainPage/Setting/
// ✅ 模块内 — 无前缀
Widget/NameDialog.dart                → NameDialog
Widget/CapsuleButton.dart             → CapsuleButton
ViewModel/ProfileController.dart      → ProfileController

// ✅ 名字过于通用 / 与全局重名 — 加模块前缀
Page/SettingLoadingPage.dart          → SettingLoadingPage   // 避免与全局 LoadingPage 冲突
Widget/ExampleListItem.dart           → ExampleListItem      // 见 lib/MainPage/Example

// ❌ 模块内冗余前缀
Widget/SettingCapsuleButton.dart
Widget/SettingNameDialog.dart
```

路由常量、GM 调试入口等同理：需要前缀时用模块名小驼峰（如 `settingLoadingPage`）。

## 禁止事项

```dart
// ❌ 禁止
Get.find<XxxController>();
Get.put(XxxController());
Navigator.pop(context);
Navigator.pushNamed(context, route);
Platform.isIOS;
MediaQuery.of(context).size.width;
Color(0xFF333333)
Colors.white
fontSize: 16          // 硬编码尺寸
SafeArea(child: ...)  // 用 SmartSafeArea 替代

// ✅ 正确
findGetxController(XxxController.new, permanent: false);
Get.back();
Get.toNamed(routeName);
GetPlatform.isIOS;
Get.width;
getAppFigmaColors.colorTextPrimaryB0
FigmaVariables.fontSize16
SmartSafeArea(child: ...)
```

## Controller 结构

```dart
class XxxController extends GetxController {
  // ========== 状态变量 ==========
  RxBool isLoading = false.obs;
  RxList<XxxModel> dataList = <XxxModel>[].obs;

  // ========== 生命周期 ==========
  Future<void> init({Map<String, dynamic>? arguments}) async { ... }
  void clear() { ... }

  // ========== 数据加载 ==========
  Future<void> loadData() async { ... }
  Future<void> refreshData() async { ... }

  // ========== 业务方法 ==========
}
```

## Page 结构

```dart
class XxxPage extends StatefulWidget {   // 有参数时不继承 BaseFulWidget
  const XxxPage({super.key, this.arguments});

  final dynamic arguments;

  @override
  State<XxxPage> createState() => _XxxPageState();
}

class _XxxPageState extends State<XxxPage> {
  late XxxController _controller;
  Map<String, dynamic>? arguments;  // 路由参数缓存

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
}
```

**强制规则**：新页面传参使用 `StatefulWidget` + `final dynamic arguments`（路由注册传入）+ State 内从 `widget.arguments` 解析缓存；**禁止在 Page 内读 `Get.arguments`**。禁止 `XxxPage({required this.id})` 等业务字段构造函数。已继承 `BaseFulWidget` 的页面可继续 `required super.arguments`（见 `WebViewPage`、`MainPage`）。

## 状态管理

分层原则：**默认优先 GetX**；`setState` 仅为小叶子 Widget 的**例外**。

### 选型顺序（先判断再写）

```
1. 业务/页面/跨组件/与 Controller 联动？ → GetX（必用）
2. 父级已有 Controller，或需细粒度 rebuild，或可能共享，或性能敏感？ → GetX（更合适）
3. 小叶子 Widget + 纯局部 + 轻量低频 + GetX 无显著收益？ → 可用 setState
```

| GetX 更合适（即使用于小 Widget） | setState 可接受 |
|----------------------------------|-----------------|
| 父 Page 已有 Controller，状态需回传或联动 | 独立 Tip / 纯装饰动画，无外部依赖 |
| 需 `Obx` 细粒度刷新（列表、图片旁） | 单次展开/收起，subtree 很轻 |
| 状态可能升级为共享 | 勾选/hover 等，且不会外泄 |
| 高频更新 + subtree 较重 | `AnimationController` 驱动（优先于 setState） |

### 默认：GetX

| 场景 | 做法 |
|------|------|
| Page 级 loading / error / 列表数据 | `GetxController` + `.obs` + `Obx` |
| 跨 Widget / 跨页面共享 | Controller 或单例 ViewModel |
| 与接口、路由联动的状态 | Controller |

```dart
// ✅ Page 层：StatefulWidget 仅用于 initState，UI 刷新走 Obx
Widget _buildBody() {
  return Obx(() {
    if (_controller.isLoading.value) return const LottieAnimationView();
    return _buildContent();
  });
}

// ❌ Page 层用 setState 驱动业务状态
setState(() => _isLoading = true);
```

### 例外：小叶子 Widget 可用 setState

**前提**：已确认 GetX **无显著收益**（见上表）。状态**仅在本 Widget 内**、**不外泄**、**不与 Controller 联动**：

- 纯局部交互（独立 Tip 显隐、轻量展开/收起）
- `AnimationController` 驱动动画（**优先于** setState 逐帧刷新）

```dart
// ✅ 例外：独立、轻量、GetX 收益不大
class TapToContinueTip extends StatefulWidget { ... }

void _onTap() => setState(() => _expanded = !_expanded);

// ✅ 更合适：父级已有 Controller 或需细粒度刷新 → 仍用 GetX
Obx(() => TabIndicator(index: controller.selectedIndex.value));
```

**不是**「叶子 Widget 默认 setState」，而是「**能用 GetX 就用 GetX**，只有例外才 setState」。

### 性能：setState 影响 rebuild 时

`setState` 会 rebuild **整个** `StatefulWidget` 的 subtree。以下情况应优化，**优先** `.obs` + `Obx` 做细粒度刷新，或**拆子 Widget** 把 `setState` 限制在更小的 subtree：

| 信号 | 处理 |
|------|------|
| `setState` 挂在大 Widget / Page 上，连带 rebuild 列表、图片、复杂布局 | 状态下沉到 Controller + `Obx`，或拆成独立子 Widget |
| 高频触发（滚动、拖拽、计时器、逐字动画等）且 subtree 较重 | 用 `Obx` 只刷新依赖该状态的节点；动画优先 `AnimationController` |
| Profile 可见卡顿 / 多余 rebuild | 按上面方式 refactor，不必等用户提性能问题 |

```dart
// ❌ 整个 Page rebuild
setState(() => _selectedIndex = index);

// ✅ 仅 Tab 指示器 rebuild
Obx(() => TabIndicator(index: controller.selectedIndex.value));
```

纯局部、subtree 轻量、低频，且 **GetX 无显著收益** 的 `setState` 可保留；一旦 GetX 更合适或影响性能 → 改 `Obx` 或拆子 Widget。

### 禁止

| ❌ 禁止 | 说明 |
|--------|------|
| Page 级 `setState` 驱动业务/UI 响应式状态 | 改用 Controller + Obx |
| 改已有 UI 时把 `Obx`/`GetBuilder` 换成 `setState` | 见 `modify-ui` skill |
| 本应共享的状态锁在 Widget 内 | 提升到 Controller |
| `setState` 导致大范围/频繁 rebuild 影响性能 | 改 `.obs` + `Obx` 或拆子 Widget |

## 验证边界

未经用户明确要求，不运行构建、打包或编译检查；功能开发和修复不自动授权构建。具体范围见 [analyze-hygiene](../analyze-hygiene/SKILL.md) 的「未经明确要求，不运行构建检查」。

## 代码风格

- 行宽 100 字符
- Import 顺序：dart → package → 项目内部（按字母顺序）
- 禁止读取 `lib/Util/Translations/MyLocalization.dart`（大量翻译映射，消耗 token）
- 多语言：UI 文本用 `'key'.tr` / `'key'.trParams`，或 `'~文本'`；带参数兜底可用 `'~文案 @param1'.trParams`（`~` 仅与裸 `.tr` 互斥）；组件默认文案用可空参数 + 展示处 `??`，勿在 const/final/构造默认值写 `.tr`（细则 `ui-modification` §14）；日志/注释直接用中文
- 修改现有逻辑前，先在项目内搜索是否已有通用工具/格式化方法/共享组件，优先复用，避免在页面或 Widget 内重复实现
- 修改状态字段前，先核对模型字段语义与接口含义；禁止将相近字段混用，例如 `isFollowed`（已关注）与 `isLiked`（已点赞）必须严格区分
- 用户未明确要求时，不处理编译器警告、静态检查提示、lint、info；除非用户明确说要检查或修复
- 修改项目 skill 规则时，只维护 `.agents/skills/` 一套；`.claude/skills/`、`.kiro/` 为 symlink 指向同目录，禁止再维护双份

## GetX API 优先

导航、平台、屏幕尺寸、多语言等 **优先 GetX API**，不用 Flutter / `dart:io` 原生等价物（安全区适配除外，见 `device-util` / `SmartSafeArea`）。
仅约束新增代码，不要求顺手迁移已有代码。

| 场景 | ✅ 优先 | ❌ 避免 |
|------|---------|--------|
| 返回上一页 | `Get.back()`、`Get.back(result: value)` | `Navigator.pop(context)` |
| 命名路由跳转 | `Get.toNamed(routeName, arguments: {...})` | `Navigator.pushNamed(...)` |
| 替换当前页 | `Get.offNamed(...)`、`Get.offAllNamed(...)` | `Navigator.pushReplacement...` |
| 平台判断 | `GetPlatform.isIOS`、`GetPlatform.isAndroid` | `Platform.isIOS`（`dart:io`） |
| 屏幕宽高 | `Get.width`、`Get.height` | `MediaQuery.of(context).size` |
| 多语言 | `'key'.tr` | 硬编码或自写映射 |
| Controller 获取 | `findGetxController<T>()` | `Get.find()`、`Get.put()` |

```dart
// ✅
onPressed: () => Get.back(),
if (GetPlatform.isIOS) { ... }
final w = Get.width;

// ❌
onPressed: () => Navigator.pop(context),
if (Platform.isIOS) { ... }
final w = MediaQuery.of(context).size.width;
```

路由注册与传参详见 `routing` skill。

## 参考文件

- **完整模块（列表 + 刷新 + Mock + 详情传参）**: `lib/MainPage/Example/`
- **主页 Tab 容器**: `lib/MainPage/RootPage/BottomBarMainPage/`
- **设置类页面**: `lib/MainPage/RootPage/MinePage/`
- **路由配置**: `lib/Util/Router/Route.dart`、`lib/Util/Router/RouteOpenPage.dart`
- **常用工具入口**:
  - `lib/Util/Common/Tools.dart`：通用判断、文本尺寸、数字格式化、控制器获取、打开链接等高频工具
  - `lib/Util/Common/TimeTools.dart`：时间格式化、时间戳转换、相对时间展示
  - `lib/Common/Manager/TimeMgr.dart`：服务端时间同步、倒计时、统一时间状态管理

## 工具复用建议

涉及以下需求时，优先搜索对应入口文件，而不是在当前页面重新实现：

- 数字缩写/展示格式：先查 `Tools.dart`
- 时间格式化、时间差、倒计时文案：先查 `TimeTools.dart` / `TimeMgr.dart`
- 通用判断、控制器获取、文本测量：先查 `Tools.dart`
- 下拉刷新 / 上拉加载状态收口：优先复用 `lib/Util/RefreshLoader/RefreshLoaderUtil.dart` 中的 `RefreshStateUtil`
  - 下拉刷新优先调用 `RefreshStateUtil.finishRefresh(...)`
  - 上拉加载优先调用 `RefreshStateUtil.finishLoadMore(...)`
  - 已继承 `BaseFulWidget` 的页面可继续使用 `dealRefreshState(...)`，它已复用统一收口逻辑
  - 不要在页面内分散手写 `refreshCompleted()`、`refreshFailed()`、`loadComplete()`、`loadNoData()` 的状态机，避免出现刷新动画残留或 footer 状态不一致
