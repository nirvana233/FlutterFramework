---
name: device-util
description: 项目专用补充规范。当用户需要获取设备相关信息、顶部/底部安全区、状态栏高度、刘海屏适配、Android 10 刘海修复时自动触发。包括设备 ID、IDFV、屏幕宽高、安全区、平板判断、低端设备、Android SDK。关键词：设备信息、DeviceUtil、安全区、状态栏、刘海、刘海屏、Android 10、smartTopSafeHeight、SmartSafeArea、SmartAppBar、padding.top、顶部安全区。
version: 1.1.0
---

# 设备信息获取规范

本 skill 作为设备相关能力的项目补充约束；与通用规范冲突时，以项目约定为准。

获取设备相关信息时，优先使用：

- `lib/Util/Common/DeviceUtil.dart`

不要在业务页面、Widget、Controller 或 Service 中直接重复封装 `DeviceInfoPlugin`、`MediaQuery`、`AndroidId`、`PackageInfo` 等已有能力。

> 广告标识（IDFA / Android Advertising ID）与 ATT 授权属于广告 / 归因 SDK 范畴，框架未内置；接入相关 SDK 时再在 `DeviceUtil` 中补充统一方法（需同时添加 `NSUserTrackingUsageDescription` 与 `AD_ID` 权限）。

## 常用能力

```dart
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
```

- 设备 ID：`await DeviceUtil.getDeviceId()`（iOS：Keychain 持久化的 IDFV；Android：Android ID）
- iOS IDFV：`await DeviceUtil.getIDFV()`
- iOS 设备信息：`await DeviceUtil.iosDeviceInfo`
- Android 设备信息：`await DeviceUtil.androidDeviceInfo`
- 应用版本：`await DeviceUtil.getVersion()`
- 设备内存：`await DeviceUtil.instance.getDeviceRam()`
- 低端机判断：`isLowDevice`（启动时 `DeviceUtil.instance.initialize()` 计算，LaunchPage 据此配置图片缓存）
- 应用包信息：`await DeviceUtil.instance.getPackageInfo()`
- Android 10 判断：`DeviceUtil.instance.isAndroid10`
- 屏幕宽高：`DeviceUtil.instance.width` / `DeviceUtil.instance.height`
- 顶部/底部安全区（已修正）：`smartTopSafeHeight` / `DeviceUtil.instance.bottomSafeHeight`
- 平板判断：`DeviceUtil.isTablet`
- 长屏手机判断：`DeviceUtil.isLargeAspectRatioPhone`
- 传统屏幕比例手机判断：`DeviceUtil.isTraditionalAspectRatioPhone`

## 顶部安全区 / Android 10 刘海适配（必遵）

### 背景

Android 10（API 29）部分刘海屏（如华为 Mate 20 Pro）上，Flutter 的 `MediaQuery.padding.top` 可能误报为 `0~1`，导致内容顶到刘海。项目已在 `getFixedTopPadding()` 中统一修正，并通过 `DeviceUtil.setContext()` 缓存到 `DeviceUtil.instance.topSafeHeight`。

### 禁止写法

```dart
// ❌ 不要直接用系统 padding.top 做顶部留白/定位
MediaQuery.of(context).padding.top
SizedBox(height: MediaQuery.of(context).padding.top)
Positioned(top: MediaQuery.of(context).padding.top + 16, ...)

// ❌ 需要顶部安全区时，不要用原生 SafeArea（Android 10 可能失效）
SafeArea(child: ...)
```

### 推荐写法

| 场景 | 用法 | 引用 |
|------|------|------|
| 手动顶部间距 / `Positioned` / 高度计算 | `smartTopSafeHeight` | `DeviceUtil.dart` 全局 getter |
| 整页 body 需要顶部安全区 | `SmartSafeArea` | `lib/Common/Widget/SmartSafeArea.dart` |
| 标准 AppBar 页面 | `CommonAppbar`（内部 `SmartAppBar`） | `lib/Common/Widget/CommonAppbar.dart` |
| 沉浸式全屏页精细布局 | `DeviceUtil.instance.topSafeHeight` | 与自定义顶栏保持一致时 |
| Drawer / 自定义顶栏 / BottomSheet 高度 | `smartTopSafeHeight` | 无 AppBar 时需自行加 `SizedBox` |

```dart
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';

// ✅ 顶部留白
SizedBox(height: smartTopSafeHeight)

// ✅ 悬浮按钮
Positioned(top: smartTopSafeHeight + 16, left: 16, child: ...)

// ✅ 高度计算（如顶部头图区域）
height: screenHeight * 0.44 - smartTopSafeHeight
```

```dart
import 'package:flutter_framework/Common/Widget/SmartSafeArea.dart';

// ✅ 替换 SafeArea（保留 top/bottom/left/right 参数语义）
body: SmartSafeArea(child: ...)
SmartSafeArea(bottom: false, child: ...)
```

```dart
import 'package:flutter_framework/Common/Widget/CommonAppbar.dart';

// ✅ 带返回/标题的二级页
appBar: CommonAppbar(title: 'xxx'.tr),
```

### 新建/修改页面检查清单

1. 搜索文件中是否出现 `padding.top` 或裸 `SafeArea`。
2. 有 `AppBar` → 用 `CommonAppbar`，不要自算 `padding.top`。
3. 全屏/Drawer/自定义顶栏 → 用 `smartTopSafeHeight`。
4. 包一层安全区的 Column/Scaffold body → 用 `SmartSafeArea`。
5. 仅底部安全区可继续 `SafeArea(top: false)` 或 `padding.bottom`（底部一般正常）。

### 已接入的组件（可直接复用）

- `SmartAppBar` / `CommonAppbar` — Android 10 自动加 top padding
- `SmartSafeArea` — 修正子树 `MediaQuery.padding.top`
- `HomePage`、`MinePage`、`ExampleListPage`（`CommonAppbar`）、`ExampleDetailPage`（`SmartSafeArea`）— 已按本规范适配

### 底层实现（一般不需改）

- 修正函数：`getFixedTopPadding(BuildContext? context)` in `DeviceUtil.dart`
- 缓存：`DeviceUtil.instance.setContext(context)` 在应用启动/路由切换时更新
- 对外统一用：`smartTopSafeHeight`（= `DeviceUtil.instance.topSafeHeight`），不要用 `topSafeHeight` getter（含额外 +20 兜底，仅特定场景）

## 使用原则

- 如果 `DeviceUtil.dart` 已有对应方法，直接复用，不要在当前页面重新实现。
- 如果缺少设备相关能力，优先在 `DeviceUtil.dart` 中补齐统一方法，再由业务层调用。
- 页面布局需要响应安全区、屏幕尺寸、平板或设备比例时，先检查 `DeviceUtil` 是否已有缓存值或判断方法。
- **任何涉及顶部安全区的 UI 改动，默认按本章「顶部安全区 / Android 10 刘海适配」执行，无需用户再次提醒。**
- 涉及平台判断时优先使用项目已有写法 `GetPlatform.isIOS` / `GetPlatform.isAndroid`。
- 涉及持久化设备 ID 的逻辑应沿用 `DeviceUtil.getDeviceId()` 内部策略，不要新增独立 key。

## 参考文件

- `lib/Util/Common/DeviceUtil.dart` — `getFixedTopPadding`、`smartTopSafeHeight`
- `lib/Common/Widget/SmartSafeArea.dart`
- `lib/Common/Widget/SmartAppBar.dart`
- `lib/Common/Widget/CommonAppbar.dart`
