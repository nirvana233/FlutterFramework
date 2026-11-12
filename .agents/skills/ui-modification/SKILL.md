---
name: ui-modification
description: UI 样式与 Token 规范，所有 UI 修改与 Figma 还原的唯一样式来源。修改 UI、调整样式/布局/颜色/间距/字体/圆角、安全区适配、UI 区块注释时触发。关键词：修改 UI、调整样式、FigmaVariables、getAppFigmaColors、UI区块注释、安全区、刘海、切图倍率。
version: 2.6.1
---

# UI 修改规范

> ## ⚠️ 写代码硬性规则（违反一次即不合格）
>
> 1. **i18n**：UI 文本优先 `'key'.tr` / `'key'.trParams`（已知 key 时），无 key 才用 `'~原文'`
>    - Snackbar / Toast / Dialog / `text` / `hintText` / `title` 全部适用
>    - `~` 与裸 `.tr` **互斥**，不能写 `'~xxx'.tr`；带参数兜底允许 `'~文案 @param1'.trParams({...})`
>    - **默认 UI 文案**：勿在构造默认参数 / `const` / `final` 字段里写 `'key'.tr` 或长期挂 `'~原文'`；参数可空，**展示时**再 `?? 'key'.tr`（或 `?? '~原文'`）。`const`/`final` 只宜存 **key** 或非文案常量
>    - 反例：❌ `text: 'Welcome'`、❌ `'~Welcome'.tr`、❌ `this.title = 'xxx'.tr`（const 构造默认值）、❌ `static const t = 'xxx'.tr`
>    - 正例：✅ `'welcome_title'.tr`、✅ `'~Welcome'`、✅ `widget.title ?? 'ready_wear_look'.tr`
>    - **豁免**：`lib/Common/Debug/` 调试/预览/GM 页面整体豁免
>    - **Mock 文案豁免**：模拟服务器返回的测试文案不加 `~` 或 `.tr`，不受目录限制；客户端默认 UI 文案仍遵循原规则（见 §14.1）。
> 2. **样式 Token**：已有精确 Token 时，颜色用 `getAppFigmaColors` / `FigmaVariables`，间距/字号/圆角/模糊用 `FigmaVariables.spacingXX / fontSizeXX / radiusXX / blurXX`；没有精确 Token 时保留原值和来源注释，AI 不自行补充 Token
> 3. **UI 区块注释**：按 `ui-modification` §15 — L1 功能、L2 区块分隔、L3 `_buildXxx` 说明干什么；不写 Figma 元数据/样式复读
> 4. 完整规则见下文，i18n 详见 §14、区块注释详见 §15
>
> 详见 `AGENTS.md` 顶部「硬性规范」。

---

修改 UI 样式时遵循本规范。核心原则：**只改样式，不改逻辑**。

**本文件是颜色/间距/字体/Token/区块注释/自查的唯一来源。** `figma-ui`、`modify-ui` 的样式与注释冲突以本文件为准。

---

## 使用范围

本 skill 只维护样式规则。入口选择、Page/Widget 判定、Figma MCP 流程分别由
`figma-ui` / `modify-ui` 维护，避免规则重复。

---

## 核心原则

### 1. 颜色映射规则

```dart
// ✅ Figma 明确返回变量：使用变量
color: getAppFigmaColors.colorTextPrimaryB0
color: FigmaVariables.colorBgMaskB070

// ✅ Figma 只有原始值、无变量：基色 + withValues(alpha:)，并注释来源
color: const Color(0xFF000000).withValues(alpha: 0.65), // Figma: rgba(0,0,0,0.65)

// ❌ 错误：把 Figma 原始值硬塞到相近但语义不同的变量
color: FigmaVariables.colorBgShadowB030.withValues(alpha: 0.65)

// ❌ 错误：带透明通道写进 ARGB 十六进制
color: Color(0xA6000000), // Figma: rgba(0,0,0,0.65)
```

规则：

- Figma 有变量时，必须使用对应变量。
- Figma 没有变量、只给原始颜色值时，**带透明通道（a < 1）必须拆成基色 + `.withValues(alpha:)`**，并用注释标明 Figma 来源。
- Figma 没有变量、且 **a = 1 的不透明色** 可写 `Color(0xFFRRGGBB)` 并注释来源。
- 不要为了避免 `Color(0x...)` 而强行替换成相近 Token；错误的语义变量比原始值更难维护。
- 非 Figma 场景下仍优先使用项目现有颜色变量，避免随意新增硬编码颜色。

```dart
// ❌ 非 Figma 原始值场景：不要随意硬编码
color: Color(0xFF333333)
color: Colors.white
```

### 2. 颜色获取（主题色 / 固定色）

| 场景 | 方式 |
|------|------|
| 随明暗模式变化的主题色（默认） | `getAppFigmaColors.colorXxx` |
| 需要局部强制主题（`FigmaVariables.forcedThemeOverride`）的页面 | `getFigmaColors.colorXxx` |
| 固定色（不随主题变化） | `FigmaVariables.colorXxx` |
| 明确固定某一主题（如始终暗色的播放页） | `FigmaVariables.dark.colorXxx` / `FigmaVariables.light.colorXxx` |

主题由 `AppThemeMgr.instance.isDarkMode` 控制；在 `Obx` 内读取颜色，切换主题时自动刷新。

### 3. 透明度

**带透明通道的颜色统一用 `.withValues(alpha:)`，禁止写 ARGB 十六进制（如 `Color(0xA6000000)`）。**

```dart
// ✅ 已有 Token / 主题色：在基色上调整 alpha
color: getAppFigmaColors.colorBgElementB96.withValues(alpha: 0.5)

// ✅ Figma 原始 rgba、无变量：拆成不透明基色 + alpha
color: const Color(0xFF000000).withValues(alpha: 0.65), // Figma: rgba(0,0,0,0.65)
color: FigmaVariables.colorTextPrimaryB0.withValues(alpha: 0.65), // 基色有 Token 时优先用 Token

// ❌ 禁止：透明通道写进 hex
color: Color(0xA6000000), // Figma: rgba(0,0,0,0.65)

// ❌ 禁止：已废弃 API
color: getAppFigmaColors.colorBgElementB96.withOpacity(0.5)
```

**换算：** Figma `rgba(r,g,b,a)` → 找/写不透明基色 `Color(0xFFRRGGBB)`，再 `.withValues(alpha: a)`。

**const 上下文：** `withValues` 非编译期常量，`const TextStyle` / `const Shadow` 等需去掉对应 `const`。

### 4. 尺寸使用 FigmaVariables

```dart
fontSize: FigmaVariables.fontSize16
padding: FigmaVariables.padding16                          // EdgeInsets.all(spacing16)
margin: EdgeInsets.only(top: FigmaVariables.spacing12)
borderRadius: FigmaVariables.borderRadius8                 // BorderRadius.circular(radius8)
```

**可用变量：** fontSize8–32、spacing2–60、radius3/6/8/12/16/24（`borderRadiusXX`）、blur4–40、padding / paddingH / paddingV 4–24

Token 处理顺序：

1. 先搜索 `FigmaVariables`，有数值和语义都匹配的现有 Token 就直接复用。
2. 不得为了消除裸数字而改用数值接近但含义不同的 Token。
3. 没有精确 Token 时，保留设计原值并写来源注释，例如：
   `22, // Figma: 22px（无对应变量）`。
4. **AI 不得自行在 `FigmaVariables` 中新增或补充缺失 Token**；Token 定义由用户补充。只有用户明确要求新增某个 Token 时才可修改该文件。

### 5. 字体

- 默认字体由全局主题统一配置（`FontConfig.primaryFontFamily`，默认系统字体 + 多语言 fallback）：**不显式指定 fontFamily**
- 引入品牌字体时只改 `FontConfig` + pubspec `fonts` 段，不在组件里手写 `fontFamily: 'Xxx'`
- 确需第二字体（如标题衬线体）时，在 `FontConfig` 增加封装方法统一注入 fallback，再在组件中调用

### 6. 行高

| Figma 行高 | Flutter 处理 |
|-----------|-------------|
| **Auto / normal / 100%** | **不写** `TextStyle.height`，使用字体默认行高 |
| 具体 px 或 em（如 24px、1.2em） | `height = lineHeight / fontSize` |

```dart
// ✅ Figma: normal / Auto — 不写 height
TextStyle(
  fontSize: FigmaVariables.fontSize10,
  fontWeight: FontWeight.w400,
)

// ✅ Figma: fontSize=16, lineHeight=24 → height = 24/16 = 1.5
TextStyle(fontSize: 16, height: 1.5)

// ❌ Figma 为 normal 时禁止猜测 height: 1.2
```

MCP 返回 `leading-[normal]` 即 Figma **normal**，按上表处理。

### 7. 顶部安全区

Android 10 刘海屏详见 `device-util` skill。

```dart
SmartSafeArea(child: content)           // ✅
appBar: CommonAppbar(title: 'xxx'.tr)   // ✅
SafeArea(child: content)                // ❌
MediaQuery.of(context).padding.top      // ❌
```

### 8. GetX API 优先

导航、平台、屏幕尺寸优先 GetX — 不用 Flutter / `dart:io` 原生等价物（**安全区**除外，见 §7 / `device-util`）：

| 场景 | ✅ | ❌ |
|------|----|----|
| 返回 | `Get.back()` | `Navigator.pop(context)` |
| 跳转 | `Get.toNamed(...)` | `Navigator.pushNamed(...)` |
| 平台 | `GetPlatform.isIOS` / `.isAndroid` | `Platform.isIOS` |
| 屏幕 | `Get.width` / `Get.height` | `MediaQuery.of(context).size` |

完整对照见 `project-rules`「GetX API 优先」与 `AGENTS.md` #8。

> **状态管理**（GetX vs `setState`）见 `AGENTS.md` #7；本节不含响应式状态。

### 9. 复用项目内通用方法

先搜 `Tools.dart`、`TimeTools.dart`、`lib/Common/Widget/`，禁止页面内重复实现。

### 10. 字段语义

接口里语义相近的字段（如 `isFollowed` 已关注 / `isLiked` 已点赞）禁止混用，改状态前先核对字段含义。

### 11. 切图倍率

- **2x 切图**：展示尺寸 = 文件物理尺寸 **÷ 2**
- 例：文件 314×120 → 展示 157×60
- 用户明确指定展示尺寸时以用户为准
- 禁止把 2x 文件尺寸直接当逻辑尺寸

### 12. 屏幕适配

尺寸直接用 Figma 数值；项目已配置 `flutter_screenutil`（iOS 375×812，Android 360×800）。

### 13. 底部栏布局

- 避免固定宽度；用 `Expanded` 均分，防止小屏溢出
- 无底部安全区时额外 15px：

```dart
bottom: MediaQuery.of(context).padding.bottom > 0
    ? MediaQuery.of(context).padding.bottom
    : 15,
```

### 14. 多语言

#### 14.1 基础写法

- 已知 key：`'feedback'.tr`；带参：`'still_need_param1'.trParams({'param1': n})`
- 未知 key：`'~提交成功'`（无需 `.tr`）
- 未知 key 且需动态替换：✅ `'~(Still need @param1 Diamonds)'.trParams({'param1': n})`
  （允许 `~` + `.trParams`；`~` 仅与裸 `.tr` 互斥。GetX 查不到 key 时仍替换 `@param`，界面保留 `~` 未翻译标记）
- 日志、注释、类名、文件名：原文即可，无需 `~` / `.tr`
- **豁免**：`lib/Common/Debug/` 调试/预览/GM 页面
- **Mock 响应文案豁免**：用于模拟服务器返回内容的测试数据（如标题、描述、按钮文案），直接写预期返回原文，如 `'title': 'Short dramas are here!'`，不额外加 `~`，也不调用 `.tr`。按数据用途判断，无论文件位于 `Mock/`、业务模块还是 `lib/Common/Debug/` 均适用。此豁免不扩展到客户端的默认标题、空态、Toast 或响应缺失时的兜底文案；这些文案仍须使用翻译 key 或 `~`。

#### 14.2 默认 UI 文案：在「展示处」求值，不要冻在字段/默认参数里

组件自带的默认标题、按钮文案、空态文案等，**必须在 build / 渲染路径**再解析；不要在构造期写成「已经是最终展示串」。

| 写法 | 判定 | 原因 |
|------|------|------|
| `widget.title ?? 'ready_wear_look'.tr`（展示处） | ✅ | 未传才用默认；可跟语言；`const` 构造仍可用 |
| `widget.title ?? '~Ready to Wear'`（展示处，暂无 key） | ✅ | 同上；`~` 仅作未翻译标记 |
| 参数/字段只存 **key**，渲染统一 `.tr` | ✅ | 适合菜单项列表、Tab 配置等（参考 `MainPage` 的 `_tabConfigs.labelKey`） |
| `this.title = 'key'.tr`（构造默认值 / 初始化列表） | ❌ | `.tr` 非编译期常量 → `const` 构造报 `invalid_constant` / `const_eval_extension_method`；且冻死译文 |
| `static const title = 'key'.tr` / `const` 列表里 `'key'.tr` | ❌ | 同上，编译失败 |
| `final title = 'key'.tr`（字段初始化） | ❌（默认 UI 文案） | 能编译，但创建时冻死语言，切换语言不更新 |
| 构造默认值 `this.text = '~Great Choice!'` 长期挂着 | ⚠️ 不推荐 | 能编译，但语义是展示串；补 key 后易改成 `.tr` 默认值再炸，或与外层再 `.tr` 双重处理 |

**推荐模板（可选覆盖文案的 Widget）：**

```dart
class XxxView extends StatelessWidget {
  const XxxView({
    super.key,
    // 未传时在展示处用默认翻译；勿写 this.title = 'key'.tr
    this.title,
  });

  /// 为 null 时展示默认文案
  final String? title;

  @override
  Widget build(BuildContext context) {
    // Ready to Wear This Look?
    return Text(title ?? 'ready_wear_look'.tr);
    // 暂无 key：return Text(title ?? '~Ready to Wear This Look?');
  }
}
```

**存 key、渲染再 tr（表格式/配置式文案）：**

```dart
const entries = [
  _Entry(label: 'not_interested'), // 只存 key，可 const
  _Entry(label: 'share'),
];

// 渲染
Text(item.label.tr);
// 若需兼容 ~ 兜底：item.label.startsWith('~') ? item.label : item.label.tr
```

#### 14.3 `const` / `final` 字段存什么

| 适合放进 `const` / `final` | 不适合 |
|---------------------------|--------|
| 翻译 **key** 字面量（`'great_choice'`） | `'key'.tr` 的结果（const 直接编译失败） |
| 资源路径、枚举、布局/动画常量 | 组件默认的已译 / `~` 展示文案（长期） |
| 调用方**显式传入**的业务文案（`final String title`） | 在字段初始化里抢先 `.tr` 当「默认 UI 文案」 |

原则一句话：**`const`/`final` 存 key 或非文案常量；「译成给人看的字」在展示时做。**

#### 14.4 常见编译/语义坑

```dart
// ❌ const 构造 + 默认值 .tr → const_eval_extension_method / invalid_constant
const Foo({ this.text = 'great_choice'.tr });

// ❌ const 列表元素里 .tr
const list = [ _E(label: 'not_interested'.tr) ];

// ❌ 初始化列表 .tr 却保留 const 构造
const Bar({ String? title }) : title = title ?? 'ready_wear_look'.tr;

// ✅ 可空 + 展示处
const Foo({ this.text });
// build: text ?? 'great_choice'.tr
```

`part` 文件注意：`part of 'Xxx.dart'` 的文件**不能**再写 `import`；`.tr` 依赖的 `package:get/get.dart` 只放在主库文件。

---

## 代码模板

### 卡片容器

```dart
Container(
  padding: FigmaVariables.padding16,
  decoration: BoxDecoration(
    color: getAppFigmaColors.colorBgElementB100,
    borderRadius: FigmaVariables.borderRadius12,
    boxShadow: [
      BoxShadow(
        color: FigmaVariables.colorBgShadowB030,
        blurRadius: FigmaVariables.blur8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Text(
    '~标题',
    style: TextStyle(
      color: getAppFigmaColors.colorTextPrimaryB0,
      fontSize: FigmaVariables.fontSize16,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### 主按钮

```dart
Container(
  padding: FigmaVariables.paddingH16 + FigmaVariables.paddingV12,
  decoration: BoxDecoration(
    color: getAppFigmaColors.colorPrimaryDefault,
    borderRadius: FigmaVariables.borderRadius8,
  ),
  child: Text(
    '~确定',
    style: TextStyle(
      color: FigmaVariables.colorTextPrimaryB100,
      fontSize: FigmaVariables.fontSize16,
      fontWeight: FontWeight.w600,
    ),
  ),
)
// 禁用：getAppFigmaColors.colorPrimaryDisabled
// 按下：getAppFigmaColors.colorPrimaryActive
```

---

## 15. UI 区块注释（figma-ui / modify-ui 生成代码时必做）

**目的：** 读注释能知道**这块 UI 是干什么的**、**怎么用**、**有没有非显而易见的业务约定**。

**原则：** 注释写**功能**，不写**样式说明书**。Token、字号、圆角、间距已在代码里表达，不必重复。

**参考实现：** `lib/MainPage/RootPage/BottomBarMainPage/MainPage.dart`、`lib/MainPage/Example/Widget/ExampleListItem.dart`

### 写什么、不写什么

| ✅ 写 | ❌ 不写 |
|------|--------|
| 组件/页面的**功能**（弹出什么菜单、展示什么状态） | Figma 层名、node-id |
| **入口**怎么用（`showXxxDialog` 参数、返回值、锚定方式） | 毛玻璃、圆角 12、drop shadow 等代码已表达的视觉 |
| 与父级/兄弟的**分工**（谁提供背景、谁负责层级） | icon 20、gap 8、fontSize 14 等尺寸复读 |
| **非显而易见**的业务/行为（固定浅色主题、整行可点） | 无信息注释：`// 标题`、`// build` |
| L4：`// TODO:`、无 Token 色的 `// Figma: rgba(...)` | Status bar、Home Indicator |

### 层级

| 层级 | 写法 | 何时写 |
|------|------|--------|
| **L1 文件头** | `///` | **每个 Page / Widget 必写**：组件功能 + 入口/与父级关系（1–3 行） |
| **L2 区块分隔** | `// ===== {中文区块名} =====` | **build / Stack / Column 内每个主要 UI 区块必写**，便于 grep 定位（如 `点击空白关闭`、`菜单卡片`） |
| **L3 方法说明** | `///` | **每个 `_buildXxx` 必写**：这个函数/区块**是干什么的**（功能、交互），不写样式参数 |
| **L4 行内** | `// …` | 非显而易见的业务约定、TODO、无 Token 原始色 |

```dart
/// 详情页「更多」的二级菜单（Report / Share / Not Interested）。
/// 由 [showMorePopupMenu] 弹出，锚定在触发按钮上方右对齐。

Future<MorePopupItem?> showMorePopupMenu({ ... }) async {
  return Stack(
    children: [
      // ===== 点击空白关闭 =====
      Positioned.fill(...),
      // ===== 菜单卡片 =====
      Positioned(child: _buildMenuCard(colors)),
    ],
  );
}

/// 菜单卡片：渲染三项可点击菜单。
Widget _buildMenuCard(FigmaThemeColors colors) { ... }

/// 单个菜单项：点击选中对应项并关闭弹窗。
Widget _buildMenuItem(FigmaThemeColors colors, _MorePopupEntry item) { ... }
```

### 必须注释的 UI 块

- **L1**：所有 Page / Widget 文件头（Debug 目录豁免）
- **L2**：build 内 AppBar、主内容、底栏、遮罩、弹窗卡片等主要区域
- **L3**：每个 `_buildXxx` 及独立子组件方法

### 禁止

- ❌ 把 Figma MCP 输出、设计稿参数表粘贴进注释
- ❌ 复读已在 `FigmaVariables` / `TextStyle` / `BoxDecoration` 中表达的信息
- ❌ Status bar、Home Indicator（见 `figma-ui` Step 3）

### modify-ui 改已有文件时

- 功能/行为变了：同步更新 L1 或相关 L3/L4
- 删区块：删对应过时注释
- 清理历史：`/// Figma: … (node-id)`、大段样式复读 → 改成 L1 功能说明或删掉

### 与 figma-ui 的衔接

Step 2–4 用 Figma 做视觉还原；**落盘注释只保留功能与非显而易见的行为**。样式分析留在实现过程，不进仓库。

---

## 修改后自查清单

### 颜色
- [ ] Figma 有变量时使用变量；无变量时保留 Figma 原值并注释来源
- [ ] 未把 Figma 原始值硬塞到相近但语义不同的 Token
- [ ] 非 Figma 原始值场景：主题色 `getAppFigmaColors`（局部强制主题用 `getFigmaColors`）/ 固定色 `FigmaVariables`
- [ ] 带透明通道用 `.withValues(alpha:)`，禁止 `Color(0xAARRGGBB)` 写法

### 尺寸与间距
- [ ] fontSize / spacing / borderRadius 优先复用 `FigmaVariables` 中数值与语义都匹配的现有 Token
- [ ] 无精确 Token 时保留原值和来源注释，未自行新增 Token、未强行套用相近 Token

### 字体 / 行高
- [ ] 默认未指定 fontFamily（字体统一走 `FontConfig`）
- [ ] Figma 为 normal/Auto 时不写 `height`；有明确 px/em 时按 `lineHeight / fontSize` 换算

### 多语言 / 资源 / 复用 / 语义
- [ ] UI 文本：有 key 用 `.tr`，无 key 用 `~`；无 `'~xxx'.tr`
- [ ] 默认 UI 文案在展示处 `?? 'key'.tr`（或 `?? '~原文'`）；未在 const/final/构造默认值里写 `.tr`
- [ ] const/final 未存「已翻译展示串」作组件默认文案；配置项只存 key 时渲染处统一 `.tr`
- [ ] 无重复工具方法；字段语义正确
- [ ] 切图 Glob 本地 assets；禁止 curl Figma MCP asset；装饰效果代码模拟

### UI 区块注释（§15）
- [ ] 文件头 `///` 说明组件功能（无 Figma 元数据、无样式复读）
- [ ] 主要 UI 区块有 L2 `// ===== … =====`
- [ ] 每个 `_buildXxx` 有 L3 功能说明
- [ ] 无废话注释；未注释 Status bar / Home Indicator

---

**图标目录：** `assets/images/svg/`、`assets/images/common/`（按模块新增子目录时同步 pubspec `assets`）

- 切图优先 Glob 本地 assets；**禁止 curl / 下载 Figma MCP asset URL**
- 渐变、模糊、阴影等装饰效果用代码模拟，不自行导出 png
- **资源不存在**：先用项目中任意近似资源占位（`Icons.xxx`、其他已有 svg/png 均可），代码加 `// TODO: 待设计提供 xxx 切图，当前用 yyy 占位`；**本地已有正确切图时不得换占位**
- **完成输出**（由 `figma-ui` / `modify-ui` 执行）：必须列出 **缺失资源清单** 与 **Flutter 还原限制清单**，详见 `figma-ui` 对应章节

---

## 参考文件

- `lib/Common/Config/FigmaVariables.dart`
- `lib/Common/Config/FontConfig.dart`
- `lib/Common/Manager/AppThemeMgr.dart`
- `lib/Common/Widget/SmartSafeArea.dart`
- `lib/Util/Extension/ColorUtil.dart`
