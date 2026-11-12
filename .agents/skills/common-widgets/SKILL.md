---
name: common-widgets
description: 当用户需要使用通用 UI 组件时自动触发，包括：显示确认弹窗、显示取消确认弹窗、显示空状态、显示错误状态、显示全屏加载动画、显示按钮加载指示器、使用勾选框、协议同意组件。关键词：ConfirmMgr、确认弹窗、NotLoadedUI、空状态、错误状态、LottieAnimationView、全屏加载、LoadingView、加载指示器、ToggleWidget、勾选框、协议勾选、ToggleSwitchView、AutoToggleSwitchView、开关、受控开关、自管开关。
version: 1.0.0
---

# 通用 UI 组件规范

本文档覆盖项目中常用的通用 UI 组件，使用时直接调用，无需自己实现。

---

## 1. ConfirmMgr — 确认弹窗

**文件**：`lib/Common/Popup/ConfirmMgr.dart`

全局单例弹窗管理器，基于 Figma 设计规范实现。

### 确认 + 取消弹窗（常用）

```dart
import 'package:flutter_framework/Common/Popup/ConfirmMgr.dart';

ConfirmMgr.instance.showConfirmNew(
  title: '~删除记录',
  message: '~确定要删除这条记录吗？',
  confirmText: '~删除',
  cancelText: '~取消',
  isDestructive: true,         // true = 确认按钮为主题色（危险操作）
  onConfirm: () {
    // 执行删除
  },
  onCancel: () {
    // 取消操作（可不传）
  },
);
```

### 仅确认按钮弹窗

```dart
ConfirmMgr.instance.showOKConfirmNew(
  title: '~操作成功',
  message: '~您的设置已保存',
  confirmText: '~好的',
  isDestructive: false,        // false = 普通样式
  onConfirm: () {},
);
```

### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | `String?` | - | 弹窗标题（可不传） |
| `message` | `String?` | - | 内容描述（可不传） |
| `confirmText` | `String?` | `'Confirm'` | 确认按钮文字 |
| `cancelText` | `String?` | `'Cancel'` | 取消按钮文字 |
| `confirmWidget` | `Widget?` | - | 自定义确认按钮内容（如 Icon+文字），优先级高于 confirmText |
| `cancelWidget` | `Widget?` | - | 自定义取消按钮内容，优先级高于 cancelText |
| `isDestructive` | `bool` | `true` | 确认按钮是否用主题色 |
| `isOnlyConfirm` | `bool` | `false` | 是否只显示确认按钮 |
| `barrierDismissible` | `bool` | `true` | 点击遮罩是否关闭 |
| `onConfirm` | `Function?` | - | 确认回调 |
| `onCancel` | `Function?` | - | 取消回调 |

> **文字规范**：title/message/confirmText 使用 `~` 前缀或 `.tr`，禁止硬编码英文字符串。

---

## 2. NotLoadedUI — 空态 / 错误态

**文件**：`lib/Util/Common/NotLoadedUI.dart`

三种使用场景，参数互斥，按需选择：

### 场景一：网络/服务器异常（加载失败）

传 `onRefresh`，自动显示错误提示 + 重试按钮：

```dart
import 'package:flutter_framework/Util/Common/NotLoadedUI.dart';

NotLoadedUI(
  onRefresh: () => _controller.loadData(),
)
```

### 场景二：数据为空（空状态）

传 `message`，不传按钮，显示默认占位图 + 文字：

```dart
NotLoadedUI(
  message: '~暂无数据',
)
```

### 场景三：空状态 + 自定义跳转按钮

```dart
NotLoadedUI(
  message: '~还没有任何内容',
  messageBtnText: '~去首页看看',
  messageBtnCallback: () => Get.toNamed(mainPage),
)
```

### 自定义图标

```dart
NotLoadedUI(
  message: '~暂无搜索结果',
  iconPath: 'assets/images/new/img_no_result.png',   // PNG
  // iconPath: 'assets/images/svg/icon_empty.svg',   // SVG
  onRefresh: () => _controller.search(),
)
```

### 参数说明

| 参数 | 说明 |
|------|------|
| `onRefresh` | 网络错误重试回调，与 `messageBtnCallback` 互斥 |
| `message` | 提示文字（无 `onRefresh` 时必传） |
| `iconPath` | 自定义图标路径（PNG 或 SVG，默认用占位图） |
| `messageBtnCallback` | 空状态自定义按钮回调，与 `onRefresh` 互斥 |
| `messageBtnText` | 自定义按钮文字 |
| `width` / `height` | 图标尺寸，默认 140×140 |

---

## 3. LottieAnimationView — 全屏加载动画

**文件**：`lib/Common/Widget/Animation/LottieAnimationView.dart`

页面初始化时的全屏 Lottie 加载动画，**固定 93×93**，居中展示。

```dart
import 'package:flutter_framework/Common/Widget/Animation/LottieAnimationView.dart';

// 无参数，直接使用
const LottieAnimationView()
```

### 标准用法（页面加载三态）

```dart
Widget _buildBody() {
  return Obx(() {
    // 加载中：全屏 Lottie 动画
    if (_controller.isLoading.value) {
      return const LottieAnimationView();
    }
    // 加载失败：错误态
    if (_controller.hasError.value) {
      return NotLoadedUI(onRefresh: () => _controller.loadData());
    }
    // 加载成功：正常内容
    return _buildContent();
  });
}
```

---

## 4. LoadingView — 按钮内加载指示器

**文件**：`lib/Common/Widget/Animation/LoadingView.dart`

小型 loading 圆圈，用于**按钮加载状态**或**局部加载区域**。

```dart
import 'package:flutter_framework/Common/Widget/Animation/LoadingView.dart';

// 按钮内加载（白色，小尺寸）
LoadingView(
  width: 16,
  height: 16,
  color: Colors.white,
  strokeWidth: 2,
)

// 页面局部加载（主题色，中等尺寸）
LoadingView(
  width: 24,
  height: 24,
)
```

### LottieAnimationView vs LoadingView

| 场景 | 使用组件 |
|------|----------|
| 页面初始化全屏加载 | `LottieAnimationView()` |
| 按钮点击后加载状态 | `LoadingView(width: 16, height: 16)` |
| 列表局部加载 | `LoadingView(width: 24, height: 24)` |

```dart
// 按钮加载状态示例
Obx(() => GestureDetector(
  onTap: _controller.isSubmitting.value ? null : () => _controller.submit(),
  child: Container(
    child: _controller.isSubmitting.value
        ? const LoadingView(width: 16, height: 16, color: Colors.white)
        : Text('~提交'),
  ),
))
```

### 按钮触发网络请求的标准写法

当按钮点击后会发起网络请求时，优先复用项目现有模式：**loading 状态防重入 + 按钮内容切换为 `LoadingView` + 请求结束恢复状态**。

**优先参考文件：**
- `lib/Common/Widget/Button/ButtonBig.dart`（`isLoading` 参数切换为 `LoadingView`）
- `lib/Common/Popup/ConfirmMgr.dart`（`onConfirmAsync`：确认按钮转圈，返回 true 才关窗）

**标准模式：**

```dart
final RxBool isLoading = false.obs;

Future<void> _submit() async {
  if (isLoading.value) return;
  isLoading.value = true;
  try {
    final result = await xxxRequest();
    if (result?.code == 200) {
      // success
    }
  } catch (e) {
    showToast('general_message_3'.tr);
  } finally {
    isLoading.value = false;
  }
}

Obx(() => GestureDetector(
  onTap: isLoading.value ? null : _submit,
  child: Container(
    alignment: Alignment.center,
    child: isLoading.value
        ? const LoadingView(
            width: 20,
            height: 20,
            color: FigmaVariables.colorTextPrimaryB100,
            strokeWidth: 2,
          )
        : Text('submit'.tr),
  ),
))
```

**补充约束：**
- 请求进行中必须禁用重复点击
- 按钮内 loading 优先使用 `LoadingView`，不要随手写一份新的 spinner UI
- 能用 `finally` 恢复状态时，优先用 `finally`
- 如果项目内已有通用按钮（如 `ButtonBig`）支持 `isLoading`，优先直接复用
- 局部按钮 loading 和页面级 loading 要区分：按钮内用 `LoadingView`，整页初始化用 `LottieAnimationView`

---

## 4. ToggleWidget — 协议勾选框

**文件**：`lib/Common/Widget/ToggleWidget.dart`

用于登录/注册页等需要用户勾选协议的场景。

```dart
import 'package:flutter_framework/Common/Widget/ToggleWidget.dart';

// 基本用法
ToggleWidget(
  isAgree: true,                           // 初始状态（默认 true）
  onIsAgreeChangedCallback: (isAgree) {
    // 状态变化回调
    setState(() => _isAgreed = isAgree);
  },
)
```

### 配合状态使用

> 协议勾选等**Page 级**状态应放 Controller + `Obx`；示例中的 `setState` 仅作回调写法演示，新建代码**默认优先 GetX**（见 `AGENTS.md` #7）。

```dart
class _XxxPageState extends State<XxxPage> {
  bool _isAgreed = false;
  final _toggleKey = GlobalKey<ToggleWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ToggleWidget(
          key: _toggleKey,
          isAgree: _isAgreed,
          onIsAgreeChangedCallback: (value) {
            setState(() => _isAgreed = value);
          },
        ),
        const SizedBox(width: 8),
        Text('~我已阅读并同意用户协议'),
      ],
    );
  }
}
```

### 外部控制状态

通过 `GlobalKey` 可以从外部调用 `setIsAgreeUserAgreement(bool)`：

```dart
_toggleKey.currentState?.setIsAgreeUserAgreement(false);
```

---

## 5. ToggleSwitchView / AutoToggleSwitchView — 开关

**文件**：`lib/Common/Widget/ToggleSwitchView.dart`

一对开关组件，按「**谁掌控显示值**」二选一：

| 组件 | 类型 | 适用 | 谁刷新开关 UI |
|------|------|------|---------------|
| `ToggleSwitchView` | 受控（`Stateless`） | 外部需掌控显示值：异步确认、失败回弹、状态来自 Controller/接口 | 外部传 `value` 控制 |
| `AutoToggleSwitchView` | 自管（`Stateful`） | 点了就自己变、外部不掌控显示值（如设置项开关） | **组件自己 `setState`** |

### 受控版 `ToggleSwitchView`

外部传 `value` 掌控、`onChanged` 回调。配合 GetX：`value` 绑 `.obs` + `Obx` 包裹。
通知/隐私设置这类「点击后要等接口成功才生效」的场景**必须用受控版**。

```dart
Obx(() => ToggleSwitchView(
      value: controller.pushEnabled.value,
      onChanged: controller.togglePush, // 内部改 .obs / 调接口后再回写
    ))
```

### 自管版 `AutoToggleSwitchView`

点击后**自己刷新滑块**，外部只在 `onChanged` 里落库 / 触发副作用，不持有状态、不写 `setState`。
样式参数与受控版一致，只是把 `value` 换成 `initialValue`。

```dart
AutoToggleSwitchView(
  initialValue: PreferenceUtil.instance.getEnableVibration() == 1,
  onChanged: (v) {
    PreferenceUtil.instance.setEnableVibration(v ? 1 : 0); // 落库（见 data-storage）
    // 可选：即时副作用
  },
)
```

### 选型 & 反例

- ❌ **不要把通用受控 `ToggleSwitchView` 改成内部自管** —— 会破坏通知/设置等需受控的调用方，且制造「**双份真相**」（组件内部值与外部数据源失同步，UI 显示错）。
- ❌ **不要在弹窗/页面里为每个开关手写 `_value + setState + 回传`** —— 直接用 `AutoToggleSwitchView` 让开关自管，容器保持无状态。
- ✅ 自管版符合硬规范 **#7**：它是「小叶子 Widget、状态纯局部不外泄」的合规 `setState`；状态**真相源仍在外部**（Preference/接口），组件只负责即时 UI。
- ✅ **数据源唯一**：落库统一走 `PreferenceUtil`（见 `data-storage` skill），组件本身不做持久化。

---

## 组件路径速查

| 组件 | 路径 | 触发场景 |
|------|------|----------|
| `ConfirmMgr` | `lib/Common/Popup/ConfirmMgr.dart` | 需要用户确认的操作 |
| `NotLoadedUI` | `lib/Util/Common/NotLoadedUI.dart` | 加载失败 / 空数据 |
| `LottieAnimationView` | `lib/Common/Widget/Animation/LottieAnimationView.dart` | 页面初始化全屏加载 |
| `LoadingView` | `lib/Common/Widget/Animation/LoadingView.dart` | 按钮/局部加载状态 |
| `ToggleWidget` | `lib/Common/Widget/ToggleWidget.dart` | 协议勾选框 |
| `ToggleSwitchView` | `lib/Common/Widget/ToggleSwitchView.dart` | 受控开关（外部掌控 `value`） |
| `AutoToggleSwitchView` | `lib/Common/Widget/ToggleSwitchView.dart` | 自管开关（点击自刷新，外部只落库） |
