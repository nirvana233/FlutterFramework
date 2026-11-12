---
name: modify-ui
description: 根据 Figma 设计稿修改已有 Page/Widget UI，或在不提供 Figma 时按规范调整样式。保留 Controller、数据绑定、路由与业务逻辑。关键词：修改 UI、调整样式、替换 UI、改现有、换皮、Figma 链接、figma.com/design、/modify-ui、layout-debug。
version: 1.3.0
---

# 修改已有 UI（modify-ui）

> ## ⚠️ 写代码硬性规则（违反一次即不合格）
>
> 1. **i18n**：UI 文本优先 `'key'.tr` / `'key'.trParams`（已知 key 时），无 key 才用 `'~原文'`；`~` 与裸 `.tr` 互斥
>    - 包含：默认参数、Snackbar/Toast、Dialog 标题/按钮、`text` / `hintText` / `title` 等
>    - 反例：❌ `text: 'Welcome'`、❌ `'~Welcome'.tr`
>    - 正例：✅ `'welcome_title'.tr`、✅ `'~Welcome'`、✅ `'~文案 @param1'.trParams({...})`（带参数兜底）
>    - **豁免**：`lib/Common/Debug/` 调试/预览/GM 页面整体豁免
> 2. **样式 Token**：颜色 `getAppFigmaColors` / `FigmaVariables`；间距/字号/圆角/模糊只用 `FigmaVariables.xxx`，禁裸数字
> 3. **UI 区块注释**：按 `ui-modification` §15 同步 L1/L2/L3（功能与区块，非样式复读）
> 4. **状态绑定**：保留现有 `Obx`/`GetBuilder`，禁止换成 `setState`；叶子 Widget 原有局部 `setState` 可保留（见 `AGENTS.md` #7）
> 5. **GetX API**：保留/使用 `Get.back()`、`GetPlatform`、`Get.width` 等，不改成 `Navigator`/`Platform`/`MediaQuery`（见 `AGENTS.md` #8）
> 6. **必读** `AGENTS.md` 顶部「硬性规范」 + `ui-modification`

---

在 **不改变业务逻辑** 的前提下，根据 Figma 设计稿或用户描述，修改已有 Page / Widget 的 **视觉与布局**。

> **新建 Page / Widget、注册路由** → 使用 **`figma-ui` skill**。

---

## 规范层级

| 优先级 | Skill | 职责 |
|--------|-------|------|
| 1 | **本 skill** | 改已有 UI 的范围、顺序、常见坑 |
| 2 | **ui-modification** | 颜色/间距/字体/Token/**区块注释**/模板/自查（**样式与注释唯一来源**） |
| 3 | **figma-ui** Step 1–5 | 有 Figma 时：MCP、Token 优化、组件映射 |
| 4 | **layout-debug** | 改完空白 / 布局异常 |

**必须同时加载：** `ui-modification`

**有 Figma 链接时还必须加载：** `figma-ui`（至少 Step 1–5）

---

## 核心原则

1. **只改 Widget 层** — 不动 Controller、接口、路由
2. **保留数据绑定** — `Obx` / `GetBuilder` 监听关系不变；**禁止**把已有 Obx 绑定 refactor 为 `setState`（叶子 Widget 内原有局部 `setState` 除外）
3. **保留事件回调** — `onTap` / `onChanged` 语义不变
4. **视觉以 Figma 截图为准** — 有设计稿时必须 `get_screenshot`
5. **样式走 Token** — 遵循 `ui-modification`，禁止硬编码

---

## 用户输入

```
/modify-ui [页面或组件名] [描述]

有 Figma：必填链接（含 node-id），可选目标文件路径
无 Figma：描述要改的样式（颜色、间距、布局等）
```

---

## 执行流程

### A. 有 Figma 链接

```
Step 0  定位已有文件（Page/Widget/ViewModel，不知道则搜索或问用户）
Step 1  读现有代码：Controller、Obx 绑定、路由（只读）
Step 2  读 FigmaVariables.dart（颜色映射）
Step 3  figma-ui Step 1–2：解析 URL + MCP(context + screenshot)
Step 4  figma-ui Step 3：Token 优化（跳过切图子节点）
Step 5  确定取色方式 → getAppFigmaColors（局部强制主题用 getFigmaColors）
Step 6  Figma 值 → Token 映射（见下节 + ui-modification）
Step 7  组件选型（figma-ui Step 5；优先保留现有项目组件）
Step 8  只改 Widget/build 及子组件文件（**同步 §15 区块注释**）
Step 9  对照截图 + ui-modification 自查
```

### B. 无 Figma 链接

```
Step 0  定位文件/Widget
Step 1  按 ui-modification 改样式
Step 2  修改后自查清单
```

---

## 允许 vs 禁止

| ✅ 允许 | ❌ 禁止 |
|--------|--------|
| `build()` / 子 Widget 布局样式 | Controller 业务逻辑 |
| 颜色、字号、间距、圆角 | 接口 URL、请求参数、Model 字段 |
| 替换/新增视觉层子 Widget | 路由注册、Route 常量 |
| 改组件参数（颜色、圆角等） | 混用语义相近字段（如 `isFollowed` / `isLiked`） |
| `// TODO` 标记缺失资源 | 新建 Page 目录（走 figma-ui） |

---

## Figma 值 → Token 映射（有 Figma 时必做）

开始前读 `lib/Common/Config/FigmaVariables.dart`，在变量中找最接近的 Token。

### 主题取色

```
页面是否设置了 FigmaVariables.forcedThemeOverride（局部强制明/暗）？
├── 是 → getFigmaColors
└── 否 → getAppFigmaColors（App 主题，跟随 AppThemeMgr.isDarkMode）
固定不随主题变化 → FigmaVariables.colorXxx / FigmaVariables.dark.colorXxx
```

### RGB / 透明度

完整规则见 **`ui-modification` §3**。

```dart
// Figma: {"r":0,"g":0,"b":0,"a":0.65}
// ✅ 基色 + withValues(alpha:)
color: const Color(0xFF000000).withValues(alpha: 0.65), // Figma: rgba(0,0,0,0.65)

// Figma: {"r":0.3,"g":0.3,"b":0.3,"a":0.8}
// → 在 FigmaVariables 找最接近的不透明 Token，再 .withValues(alpha: 0.8)

// ❌ 禁止 ARGB hex
color: Color(0xA6000000)
```

### 尺寸映射

| Figma | FigmaVariables |
|-------|----------------|
| 字号 10/12/14/16/18/20/24 | `fontSize10` ~ `fontSize24` |
| 间距 2/4/8/12/16/20/24/28/32/40/44/48 | `spacing2` ~ `spacing48` |
| 圆角 3/6/8/12/24 | `borderRadius3` ~ `borderRadius24` |

**非预设值**（如 15px）：保留原值 + `// Figma: 15px（无对应变量）`，不要强行凑预设。

### 字重

| Figma | Flutter |
|-------|---------|
| Regular/400 | `FontWeight.w400` |
| Medium/500 | `FontWeight.w500` |
| SemiBold/600 | `FontWeight.w600` |
| Bold/700 | `FontWeight.w700` |

### 行高

完整规则见 **`ui-modification` §6**。摘要：

| Figma 行高 | Flutter |
|-----------|---------|
| Auto / normal / 100% | **不写** `height` |
| 具体 px 或 em | `height = lineHeight / fontSize` |

```dart
// Figma: normal — 不写 height
TextStyle(fontSize: FigmaVariables.fontSize10)

// Figma: fontSize=16, lineHeight=24 → height = 24/16 = 1.5
TextStyle(fontSize: 16, height: 1.5)
```

---

## 切图与图标（Figma MCP 时）

### 必须跳过的节点（不展开子节点）

`VECTOR`、`IMAGE`、`BOOLEAN_OPERATION`、`ELLIPSE`、`LINE`、`STAR`、`REGULAR_POLYGON`

### INSTANCE 命名

| 命名 | 处理 |
|------|------|
| `icon/*` | Glob 查 `assets/images/svg/` 等，**禁止 Read 图标文件** |
| `img/*` | Glob 查 `assets/images/` |
| `*Status bar*` | **禁止读取详情**，见下节 |
| `*Home Indicator*` | **禁止读取详情**，见下节 |
| 其他（如 `Button/*`） | UI 结构，在当前 Widget 实现 |

### 系统 UI 装饰层（Status bar / Home Indicator）

与 **`figma-ui` Step 3** 相同：Status bar、Home Indicator 均为装饰层，分别由顶部/底部安全区处理，**禁止读取详情**。

- ❌ 禁止对上述节点及其子节点调用 `get_design_context` 或展开内部结构
- ❌ `get_metadata` 分块时直接跳过，不单独拉取
- ❌ 改 UI 时不要新增/修改 Status bar、Home Indicator 相关 Widget

### 切图流程

```
切图节点 → 跳过子节点 → 提取资源名 → Glob 本地 assets
→ 找到直接用 → 未找到：任意近似资源占位 + TODO + 记入缺失清单
```

**禁止 curl / 下载 Figma MCP 返回的 asset URL 写入 `assets/`。**

| 节点类型 | 处理 |
|---------|------|
| `icon/*`、`img/*` | Glob 本地切图；**无切图则先用项目中任意近似资源占位**，加 `// TODO: 待设计提供 xxx 切图，当前用 yyy 占位` |
| 渐变 / 模糊 / 阴影 / 描边 / 半透明 | 代码模拟，不下载 png |
| MCP asset URL | 仅参考，禁止当项目资源 |

**本地已有正确切图时必须用正确资源，不得故意换占位。**

```dart
// Figma: icon/common_gallery → Glob common_gallery.svg
SvgPicture.asset('assets/images/svg/common_gallery.svg', width: 48, height: 48)

// Figma: 毛玻璃卡片底纹 → 渐变 + BackdropFilter，不用 Image.asset
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
  child: DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [...]),
    ),
  ),
)
```

### 2x 位图

展示尺寸 = 文件物理尺寸 ÷ 2（详见 `ui-modification` §10）。

### Token 优化

- 图标只 Glob 文件名，不 Read svg/png 内容
- 24×24 icon 展开子节点可能浪费 500~1500 token
- Status bar / Home Indicator 展开子节点可能浪费 500~2000 token，**一律跳过**

---

## 组件策略（改已有 UI）

```
1. 搜索 lib/Common/Widget/、lib/Util/ 是否已有同类组件
2. 查 figma-ui Step 5 映射表（CommonAppbar、ButtonBig、NetworkImageUtil 等）
3. 页面里已在用的组件 → 优先只改参数/颜色/尺寸
4. 视觉差太大 → 局部手写 Container + Token，保留外层 Obx/回调
5. 不要为了小改动新建 Page/Controller
```

**Figma 非切图组件（如 Button/System Button）：** 无对应项目组件或视觉差大时，在当前 Widget 文件手写：

```dart
Container(
  padding: EdgeInsets.symmetric(
    horizontal: FigmaVariables.padding24,
    vertical: FigmaVariables.padding12,
  ),
  decoration: BoxDecoration(
    color: getAppFigmaColors.colorBgElementB100,
    borderRadius: FigmaVariables.borderRadius24,
    border: Border.all(color: getAppFigmaColors.colorBgElementB70),
  ),
  child: Text('~Cancel', style: TextStyle(
    color: getAppFigmaColors.colorTextPrimaryB0,
    fontSize: FigmaVariables.fontSize14,
  )),
)
```

**通用组件优先：** `ConfirmMgr`、`NotLoadedUI`、`LottieAnimationView`、`LoadingView` 等见 `common-widgets` skill。

---

## 功能处理策略

| 场景 | 处理 |
|------|------|
| 已有功能换 UI | **主场景**：保留逻辑，只改 Widget |
| 改 UI 缺接口字段 | UI 占位 + `// TODO`，不擅自改 Model |
| 改 UI 后页面空白 | 先 `layout-debug`，不要先改接口 |

---

## 改 UI 时 Layout 高风险（必知）

改 `Stack` / loading 层 / `Obx` 时极易引入「无报错空白」：

```dart
// ❌ 高风险：唯一非 Positioned 子节点 false 时返回 0x0
Stack(
  children: [
    const Positioned.fill(child: Body()),
    Obx(() => isLoading.value
        ? const Center(child: CircularProgressIndicator())
        : const SizedBox.shrink()),
  ],
)

// ✅ loading 层也用 Positioned.fill
Stack(
  children: [
    const Positioned.fill(child: Body()),
    Positioned.fill(
      child: Obx(() => isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink()),
    ),
  ],
)
```

完整排查 → **`layout-debug` skill**。

---

## 完成前自查

### A. 范围（本 skill）

- [ ] 未改 Controller / 路由 / 接口
- [ ] Obx / GetBuilder / 回调语义不变；未把 Obx 换成 setState
- [ ] 有 Figma 时与截图一致（±1px）
- [ ] 改 Stack/Obx 后页面仍正常显示

### B. ui-modification 自查清单

- [ ] 颜色/间距/字体/安全区/多语言/资源/切图倍率 全部确认
- [ ] §15：L1 功能、L2 区块、L3 `_buildXxx` 说明准确；无 Figma/样式复读
- [ ] 未 curl Figma MCP asset；装饰层用代码模拟；切图来自本地 assets

---

## 缺失资源与 Flutter 还原限制（完成时必须输出）

与 **`figma-ui`「缺失资源与 Flutter 还原限制」** 相同：

- **缺失资源**：Glob 找不到时允许任意近似占位，但必须在回复中输出 **缺失资源清单**（Figma 名 / 预期路径 / 当前占位 / 状态）
- **Flutter 还原限制**：Figma 特效 Flutter 无法或难以 1:1 还原时，输出 **还原限制清单**（效果 / 原因 / 近似方案）；常见项见 `figma-ui` 对照表
- 两项均无问题时分别写「无」或省略

---

## 输出要求

1. 修改的 Widget 文件列表
2. **明确未改** Controller / 路由 / 接口
3. TODO（缺失资源、待对接）
4. **缺失资源清单**（无则写「无」）
5. **Flutter 还原限制清单**（无则写「无」）
6. 与 Figma 的其他已知差异

---

## 参考文件

- `lib/Common/Config/FigmaVariables.dart`
- `lib/Util/Extension/ColorUtil.dart`
- 目标 Page 的 `ViewModel/`、`Widget/`
- 样式模板见 `ui-modification`「代码模板」
