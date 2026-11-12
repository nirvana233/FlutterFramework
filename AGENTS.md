# FlutterFramework - Flutter 项目基础框架

> 修改本文件后无需同步：`.claude/CLAUDE.md` 是指向本文件的软链接。
> 基于本框架开新项目时：先改 `pubspec.yaml` 的 `name`、包名 / Bundle ID、`appName`（`lib/Util/Const.dart`），再把本文件标题与 Project Overview 改成新项目的描述。

## ⚠️ 硬性规范（写代码前必读，违反一次即不合格）

所有回复使用中文

无论是否触发 skill，无论 Page / Widget / Debug 页，全部适用：

1. **i18n 前缀** ——
   所有用户可见 UI 文本（按钮、标题、提示、Toast、Snackbar、Dialog、占位符、默认参数文案）必须满足下列之一：
   - **优先**：已知翻译 key 已存在 → 直接 `'confirm'.tr` / `'days_left'.trParams({...})`，**不要写 `~`**
   - **兜底**：暂无翻译 key → 以 `~` 开头的字面量，如 `'~Welcome'`、`this.name = '~Tutorial'`、`showToast('~加载失败')`
   - **带参数兜底**：暂无 key 但需替换动态值 → ✅ `'~(Still need @param1 Coins)'.trParams({'param1': n})`（允许 `~` + `.trParams`；查不到 key 时 GetX 仍替换 `@param`，界面显示带 `~` 的兜底文案，符合未翻译标记）
   - **反例**：❌ `text: 'Welcome'`、❌ `title: 'Confirm'`、❌ `'~Welcome'.tr`（`~` 与裸 `.tr` 互斥；**不含** `.trParams`）
   - **豁免**：`lib/Common/Debug/` 下的 Debug / 预览 / GM 调试页面**整体豁免**，UI 文本可直接写英文/中文字面量，无需 `~` 与 `.tr`
   - **Mock 文案豁免**：模拟服务器响应的测试文案（标题、描述、按钮文案等）直接使用预期返回原文，不加 `~` 或 `.tr`，不受文件目录限制。客户端默认 UI 文案及响应缺失时的兜底文案仍遵循上述翻译规则。
   - 例外：日志、注释、类名、文件名一律用原文，无需 `~`
2. **样式 Token** —— 颜色用 `getAppFigmaColors` / `FigmaVariables`，间距/字号/圆角/模糊只用 `FigmaVariables.spacingXX / fontSizeXX / radiusXX / blurXX`，禁止裸数字与裸 `Color(0x...)`（极少数 Figma 未收录色用 `// TODO:` 注释保留）
3. **命名** —— 已有语义后缀（Button/Text/Dialog/Sheet/Alert/Item 等）不再叠 View；**弹窗用 `Dialog`、BottomSheet 用 `Sheet`**；模块内文件不重复模块前缀，与全局重名需消歧时再加模块前缀
4. **不引入新依赖凑视觉** —— 优先复用项目组件 / 用 Flutter 原生模拟（BackdropFilter、LinearGradient、CustomPaint）
5. **figma-ui / modify-ui 必同时加载 ui-modification** —— 不读 ui-modification 直接写 UI 一律不合格
6. **UI 区块注释** —— 生成/大改 UI 时按 `ui-modification` §15：L1 写功能、L2 标区块（`// ===== … =====`）、L3 说明 `_buildXxx` 干什么；不写 Figma 元数据/样式复读；`lib/Common/Debug/` 豁免
7. **状态管理** —— **默认优先 GetX**（`GetxController` + `.obs` + `Obx`）：业务/页面/跨组件状态必用；Page 可用 `StatefulWidget`（`initState` 取参、注册 Controller），但**不要用 `setState` 驱动页面级状态**。仅当**小叶子 Widget**、状态纯局部且不外泄、subtree 轻量低频、且 GetX **无显著收益**时，才用 `StatefulWidget` + `setState`；若 GetX 更合适（已有 Controller、需细粒度 rebuild、可能共享、性能敏感）→ **仍用 GetX**；改已有 UI 时禁止把 `Obx`/`GetBuilder` 换成 `setState`
8. **GetX API 优先** —— 新增代码中，导航、平台判断、屏幕尺寸、多语言等优先 GetX API，不用 Flutter/`dart:io` 等价物：`Get.back()` / `Get.toNamed()`、`GetPlatform.isIOS` / `GetPlatform.isAndroid`、`Get.width` / `Get.height`、`'key'.tr`；不用 `Navigator.pop` / `Navigator.pushNamed`、`Platform.isIOS`、`MediaQuery.of(context).size`（安全区除外，见 `device-util` / `SmartSafeArea`）。不要求顺手迁移已有代码。
9. **不主动 TDD / 写测试** —— 用户未明确要求时，**不要**先写测试再写实现，也**不要**主动新建或大面积补全 `test/` 用例；仅在用户点名要测试、补充测试、或 TDD 时再写。实现变更导致已有测试失败时，可顺手修到通过。
10. **flutter analyze 输出处理** —— 运行 `flutter analyze` 后，只处理 **error 级别** 的问题；warning / info 级别忽略不报；**不要将 analyze 的原始输出打印到对话中**，仅汇报需处理的 error 数量与简要说明。
11. **Review 忽略本地化文件** —— 任何时候进行代码 Review、Diff Review 或变更检查时，必须忽略以下两个文件：`tools/localization/languages.xlsx` 和 `lib/Util/Translations/MyLocalization.dart`。不得对这两个文件进行 Review、问题分析、改动评价或提出修改建议。

> 详细规则见 `.agents/skills/ui-modification/SKILL.md`、`.agents/skills/project-rules/SKILL.md`、`.agents/skills/analyze-hygiene/SKILL.md`（analyze 仅剩 import 排序时不修）。

---

## Commands

```bash
flutter pub get                        # 安装依赖
flutter run                            # 调试运行（默认设备）
flutter analyze                        # 静态检查（lint，line width 100）
dart run build_runner build --delete-conflicting-outputs  # 改 Model 后生成 .g.dart
bash tools/localization/generate_translations.sh          # languages.xlsx → MyLocalization.dart
flutter build ios --release            # iOS 出包
flutter build appbundle --release      # Android 出包（打包脚本见 tools/run_build/android）
```

> 项目不使用 FVM；`flutter` / `dart` 命令依赖开发者本机 PATH 中安装的版本。
> 测试环境开关见 `lib/Util/Const.dart`（`isTestClient` / `isTestServer`）。

## 源码定位

- 当前源码和实际测试是实现事实源，不维护或依赖 Markdown 代码索引。
- 已知文件或符号时，优先使用 `rg`、`rg --files` 和 `sed` 读取最小必要源码。
- 入口不明确、跨模块、需要查询调用方或影响面时，可使用 CodeGraph 发现候选；结论必须回到当前源码确认。
- `.codegraph/` 仅是本地缓存，不提交；只有实际需要图查询时才初始化或同步。

## Project Overview

FlutterFramework 是不含具体业务的 Flutter 项目基础框架（iOS / Android），提供路由、多语言、网络、本地存储、主题 Token、通用组件、调试工具等公共底层能力。新项目在此基础上开发业务模块。

第三方 SDK（统计、推送、登录、支付、广告、客服等）未接入，按需在 `lib/SDK/` 下新增 `XxxMgr` 并在 `main.dart` 的 `init()` 中初始化。

## Tech Stack

- **Framework**: Flutter（使用本机 PATH 版本；Dart SDK 约束见 pubspec.yaml）
- **State Management / Router / i18n**: GetX (`get: 4.7.3`)
- **Networking**: Dio + retry
- **Local Storage**: SharedPreferences（`PreferenceUtil`）、Hive（`DBManager`）、FlutterSecureStorage（deviceId）
- **Screen Adaptation**: flutter_screenutil（iOS: 375x812, Android: 360x800）

## Project Structure

```
lib/
├── main.dart       # Entry point（init 初始化顺序 + GetMaterialApp）
├── Base/           # BaseFulWidget / BaseLessWidget
├── Common/         # 公共层：Config(Token/字体/错误码)、Manager、Popup、Widget、Page、Model、Debug(GM)
├── MainPage/       # 功能模块：Launch、Language、RootPage(BottomBarMainPage/HomePage/MinePage)、Example
└── Util/           # 工具：Common、NetWorkManager、Router、DBManager、Translations、RefreshLoader、SheetAndAlter…
```

## Page Structure

Each feature page follows this directory structure (ref: `lib/MainPage/Example/`):

```
XxxPage/
├── Page/           # Page entry
│   └── XxxPage.dart
├── ViewModel/      # Business logic
│   ├── XxxController.dart   # GetX controller（页面状态）
│   └── XxxService.dart      # 接口层（可选，只负责请求与解析）
├── Model/          # Data models
│   ├── XxxModel.dart
│   └── XxxModel.g.dart      # Auto-generated
├── Mock/           # 本地 Mock 响应（可选，接口未就绪时使用）
└── Widget/         # 子组件：无 Item/Button 等语义后缀时用 View（如 LoadingProgressView）；Item/Button/Text/Dialog 等不再叠 View
```

### 命名规范（简要）

- **Widget 后缀**：已有 `Button`、`Text`、`Dialog`、`Sheet`、`Alert`、`Item` 等语义后缀时，不再叠 `View`
- **弹窗 / 抽屉**：居中弹窗 → `XxxDialog`；BottomSheet → `XxxSheet`（不用 `XxxBottomSheet`）
- **模块内命名**：模块目录内文件不必重复模块名前缀（如 `Setting/Widget/NameDialog.dart`，而非 `SettingNameDialog`）；名字过于通用或与全局重名时再加模块前缀（如 `ExampleListItem`）

详见 `.agents/skills/project-rules/SKILL.md`。

## Key Patterns

### State Management

- Uses GetX controllers
- Controllers follow naming convention: `*Controller.dart`(recommend) or `*ViewModel.dart`
- Access controllers via `findGetxController<T>()`（页面级 Controller 传 `permanent: false`）
- 全局常驻 Controller 在 `lib/Common/Manager/RegisterControllerMgr.dart` 注册 / 注销
- **Default prefer GetX**; leaf widgets may use local `setState` only when ephemeral, lightweight, and GetX offers no clear benefit (see hard rule #7)
- **Controller Reference**: `lib/MainPage/Example/ViewModel/ExampleListController.dart`

### Navigation

- Named routes defined in `lib/Util/Router/Route.dart`
- 跳转方法统一放 `lib/Util/Router/RouteOpenPage.dart`（`toXxxPage()`）
- Use `Get.toNamed()` / `Get.back()` for navigation (see hard rule #8)
- Platform/screen: `GetPlatform`, `Get.width` / `Get.height` (see hard rule #8)

### Network Requests

- All API calls through `NetWorkManagerUtil.instance`
- Supports GET, POST, PUT, DELETE, upload, download with automatic retry
- API endpoints defined in `lib/Util/Common/ApiConfig.dart`（`baseUrl` 测试/正式切换、可选动态域名）
- 公共请求头在 `NetWorkManagerUtil.getHeader()`；token 失效回调 `NetWorkManagerUtil.onTokenExpired`
- **Service Reference**: `lib/MainPage/Example/ViewModel/ExampleService.dart`

### Multi-language

- GetX Translations：`lib/Util/Translations/MyLocalization.dart`（自动生成，勿手改）
- 文案源：`tools/localization/languages.xlsx`（`client` 工作表，当前 en / zh），改完运行 `bash tools/localization/generate_translations.sh`
- App 语言：`LanguageViewModel`（iOS 跟随系统 App 语言设置，Android 用 App 内语言页）
- 新增语言：Excel 加列 → 生成 → iOS `Info.plist` 的 `CFBundleLocalizations` 同步

### Local Storage

- 键值对：`PreferenceUtil.instance`（key 统一在 `PreferenceKey` 声明）
- 结构化 / 大量数据：`DBManager.instance`（Hive，typeId 在 `Const.dart` 登记）

### Network Image

- **Network Image Widget**: `lib/Util/Common/NetworkImageUtil.dart`
- Wrapper based on `cached_network_image` with caching, placeholder, and error handling
- Preset size enums: `NetworkImageSizeEnum.cover` (540x720), `NetworkImageSizeEnum.avatar` (148x148)
- Usage: `NetworkImageUtil(imageUrl: url, width: 100, height: 150)`

### Data Models

- JSON serialization using `json_serializable`
- Model files paired with `.g.dart` generated files
- Run `dart run build_runner build --delete-conflicting-outputs` after model changes

### Pull-to-Refresh & Load More

- **Widget**: `lib/Util/RefreshLoader/RefreshLoaderUtil.dart`
- Wrapper based on `pull_to_refresh` package (local patch) with built-in haptic feedback
- Reference: `lib/MainPage/Example/Page/ExampleListPage.dart`

## Common Utilities

| Utility | File Path | Description |
| --------- | ----------- | ------------- |
| **Toast** | `lib/Util/SheetAndAlter/Toast.dart` | Use `showToast(msg)` for notifications |
| **Vibration** | `lib/Common/Manager/VibrationMgr.dart` | Use `VibrationMgr.instance.selection()` for haptic feedback |
| **Time Tools** | `lib/Util/Common/TimeTools.dart` | Time formatting utilities |
| **Time Manager** | `lib/Common/Manager/TimeMgr.dart` | Server time sync and countdown timers |
| **Theme** | `lib/Common/Manager/AppThemeMgr.dart` | Dark mode switch (`getAppFigmaColors` follows it) |
| **API Config** | `lib/Util/Common/ApiConfig.dart` | Define all API endpoints here |
| **Logger** | `lib/Util/Common/LogUtil.dart` | Use `logD()`, `logP()`, `logW()`, `logE()` |
| **Tools** | `lib/Util/Common/Tools.dart` | Common helper functions (`isAvailable()`, `findGetxController()`, etc.) |
| **Enums** | `lib/Util/Common/Enum.dart` | Global enumerations |
| **Confirm Dialog** | `lib/Common/Popup/ConfirmMgr.dart` | `ConfirmMgr.instance.showConfirmNew(...)` |
| **Popup Queue** | `lib/Common/Popup/PopupQueueMgr.dart` | 弹窗排队（优先级见 `PopupType`） |
| **Loading Animation** | `lib/Common/Widget/Animation/LottieAnimationView.dart` | Full-screen loading animation |
| **Empty State** | `lib/Util/Common/NotLoadedUI.dart` | No data / error state widget |
| **Button Loading** | `lib/Common/Widget/Animation/LoadingView.dart` | Small loading indicator for buttons |
| **Pull-to-Refresh** | `lib/Util/RefreshLoader/RefreshLoaderUtil.dart` | Pull-down refresh and pull-up load more widget |
| **GM Tools** | `lib/Common/Debug/GM/GMPage.dart` | 测试包调试页（切服、日志、清数据） |

## Code Style

- Line width: 100 characters (configured in `analysis_options.yaml`)
- Prefer `const` constructors
- `directives_ordering` 对开发者/CI 仍生效；**AI 不要为通过 analyze 而改 import 排序**（见 `.agents/skills/analyze-hygiene/SKILL.md`）
- File naming allows non-standard patterns (file_names lint ignored)

## Configuration Flags

Key flags in `lib/Util/Const.dart`:

- `isTestClient` / `isTestServer`: Toggle test environment（正式打包脚本会自动改为 false）
- `isLog` / `isHttpLog`: 日志开关

## Important Notes

- Multi-language support via GetX translations
- Screen adaptation via `flutter_screenutil` (iOS: 375x812, Android: 360x800)
- Android 构建版本：AGP 8.11.1 / Gradle 8.14.3 / Kotlin 2.2.20；minSdk 26 / targetSdk 36
- iOS 最低版本 15.0；`permission_handler` 用到的权限需在 `ios/Podfile` 打开宏并补 `Info.plist` 描述

## Response Language

- Use Chinese for all responses and reasoning
