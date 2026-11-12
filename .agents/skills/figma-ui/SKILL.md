---
name: figma-ui
description: 根据 Figma 设计稿新建 Page 或 Widget UI。用户提供 Figma 链接、运行 /figma-ui 或要求「新建/还原/生成页面或组件」时触发。关键词：Figma 链接、figma.com/design、figma.com/file、新建页面、生成组件、设计稿还原、figma-ui、/figma-ui、get_design_context。
version: 3.4.0
---

# Figma UI 还原（新建）

> ## ⚠️ 写代码硬性规则（违反一次即不合格）
>
> 1. **i18n**：UI 文本优先 `'key'.tr` / `'key'.trParams`（已知 key 时），无 key 才用 `'~原文'`；**`~` 与裸 `.tr` 互斥**
>    - 包含：默认参数文案、Snackbar/Toast、Dialog 标题与按钮、`text` / `hintText` / `title` 等
>    - 反例：❌ `name = 'Tutorial'`、❌ `'~Welcome'.tr`
>    - 正例：✅ `'login_title'.tr`、✅ `name = '~Tutorial'`、✅ `'~文案 @param1'.trParams({...})`（带参数兜底）
>    - **豁免**：`lib/Common/Debug/` 下调试/预览/GM 页面整体豁免，可直接用字面量
> 2. **样式 Token**：颜色 `getAppFigmaColors` / `FigmaVariables`；间距/字号/圆角/模糊只用 `FigmaVariables.xxx`，禁裸数字与裸 `Color(0x...)`
> 3. **UI 区块注释**：按 `ui-modification` §15 — L1 功能、L2 区块、L3 `_buildXxx` 干什么
> 4. **状态管理**：**默认优先 GetX**；新建 Page → Controller + `Obx`；仅小叶子 Widget 纯局部且 GetX 无显著收益时可用 `setState`（见 `AGENTS.md` #7）
> 5. **GetX API**：`Get.back()`、`Get.toNamed()`、`GetPlatform`、`Get.width`/`Get.height`（见 `AGENTS.md` #8）
> 6. **必读** `AGENTS.md` 顶部「硬性规范」 + `ui-modification`，不读直接写 UI 一律不合格

---

根据 Figma 设计稿 **1:1 还原视觉**，**新建** Page 或 Widget，输出符合本项目规范的 Flutter 代码。

> **改已有页面 UI**（不换路由、不新建 Controller）→ 使用 **`modify-ui` skill**，不要走本 skill。

---

## 规范层级

| 优先级 | Skill | 职责 |
|--------|-------|------|
| 1 | **本 skill（figma-ui）** | Figma MCP、Page/Widget 判定、视觉对照、组件映射 |
| 2 | **ui-modification** | 颜色/间距/字体/Token/**区块注释**/自查（**唯一样式与注释规范源**） |
| 3 | 其他 skill | 按需（见文末关联表） |

**冲突时：样式以 `ui-modification` 为准。**

**必须同时加载：** `.agents/skills/ui-modification/SKILL.md`

---

## 与 modify-ui 的分工

| 场景 | 使用 skill |
|------|-----------|
| 新建 Page / 注册路由 / 新建 Controller | **figma-ui**（本 skill） |
| 新建 Widget / 列表项 / 弹窗组件 | **figma-ui**（本 skill） |
| 替换已有 Page / 组件的 UI，保留逻辑 | **modify-ui** |
| 无 Figma，只改颜色间距等样式 | **ui-modification** |

---

## 核心优先级

1. **视觉一致** — 布局、间距、字号、颜色、圆角与 Figma 截图一致
2. **项目 Token** — 遵循 `ui-modification`（FigmaVariables）
3. **项目组件** — 能复用则复用，参数/颜色可配即可
4. **局部实现** — 视觉差太大时手写 Widget + Token
5. **禁止** — 为像设计稿引入新依赖；为用组件牺牲视觉

---

## 用户输入

```
/figma-ui [模块名称] [选项]

必填：Figma 链接（必须含 node-id）

可选：
- --page        强制按完整 Page 处理
- --widget      强制只生成 Widget
- --with-args   新 Page 需要路由参数
- --mock        无接口时 Mock 数据
```

---

## Page vs Widget 判定

**默认 AI 自动判定；无法确定时主动问用户。**

### 判定为 Page

- 全屏 Frame（≈375×812 / 360×800）+ AppBar / 整页结构
- Frame 名称含 Page / Screen / 页面
- 用户说「新建页面」「注册路由」或提供模块名
- 用户指定 `--page`

**后续：** 创建 Page 结构；引用 `ui-page-creation` + `routing`。

### 判定为 Widget

- 小 Frame、Component、Item、Cell、Card、Dialog、BottomSheet
- 用户说「组件」「列表项」「弹窗」或指定目标文件
- 用户指定 `--widget`

**后续：** 只创建/修改 `Widget/` 下组件；不注册路由、不新建 Controller。命名见 `project-rules`：弹窗 `Dialog`、BottomSheet `Sheet`；Item/Button/Text 等语义后缀不再叠 View；模块内不必重复模块前缀，需消歧时再加模块前缀。

---

## 完整执行流程

```
Step 0  判定 Page / Widget（用户声明 > Figma 结构 > 关键词）
Step 1  解析 Figma URL
Step 2  Figma MCP（context + screenshot）
Step 3  MCP Token 优化
Step 4  视觉还原 + Token 映射
Step 5  组件映射
Step 6  生成 Flutter UI
Step 7  新 Page：ui-page-creation + routing（按需）
Step 8  视觉自查 + ui-modification 自查
```

> **Step 1–5 为 Figma 公共流程**，`modify-ui` 改已有 UI 时同样遵循。

---

## Step 1：Figma URL 解析

| URL 格式 | fileKey | nodeId |
|----------|---------|--------|
| `figma.com/design/:fileKey/:fileName?node-id=42-15` | `:fileKey` | `42:15`（`-` → `:`） |
| `.../branch/:branchKey/:fileName` | `branchKey` | 从 query 提取 |
| 无 `node-id` | — | **停止**，向用户索要 |

---

## Step 2：Figma MCP

### get_design_context

```
get_design_context(
  fileKey="<fileKey>",
  nodeId="<nodeId>",
  clientLanguages="dart",
  clientFrameworks="flutter"
)
```

MCP 返回的 React+Tailwind **仅作结构参考**，必须翻译为 Flutter + FigmaVariables。

### get_screenshot（视觉标准）

```
get_screenshot(fileKey="<fileKey>", nodeId="<nodeId>")
```

**截图是最终校验标准**，禁止仅凭文字描述实现。

### get_metadata（大页面分块）

响应过大时：`get_metadata` → 拆分子 Frame → 分别 `get_design_context`，每块对照截图。

### 资源与切图（重要）

**禁止自行从 Figma MCP 下载图片当项目资源。**

| 场景 | 处理 |
|------|------|
| `icon/*`、`img/*` 等命名切图 | **Glob 查本地 `assets/`**，找到直接用 |
| 渐变、模糊、圆角、阴影、描边、半透明叠层 | **Flutter 代码模拟**（`BackdropFilter`、`LinearGradient`、`BoxDecoration` 等） |
| 本地无对应切图 | **先用项目中任意近似资源占位**（保证 UI 可运行、布局可对照），代码加 `// TODO: 待设计提供 xxx 切图，当前用 yyy 占位` |
| 代码也难模拟的装饰 | 用 `Container` / `DecoratedBox` 等近似模拟 + `// TODO` |
| MCP 返回的 asset URL | **仅作结构/截图参考**，禁止下载写入 `assets/` |

```
Figma 图片节点
├── 命名像切图（icon/*、img/*）→ Glob assets → 有则用、无则任意占位 + TODO + 记入缺失清单
├── 纯装饰（毛玻璃底纹、渐变填充、模糊层）→ 代码实现，不导出 png
└── 禁止 curl / download Figma MCP asset URL
```

- 禁止引入新 icon 包
- 禁止为装饰性图层新建 `assets/images/` 目录并注册 pubspec
- **本地有对应切图时必须用正确资源**，不得故意换占位

---

## Step 3：MCP Token 优化

### 必须跳过的节点类型

`VECTOR`、`IMAGE`、`BOOLEAN_OPERATION`、`ELLIPSE`、`LINE`、`STAR`、`REGULAR_POLYGON`

### 必须跳过的 INSTANCE

| 命名 | 处理 |
|------|------|
| `icon/*` | Glob 查 `assets/images/svg/` 等 |
| `img/*` | Glob 查 `assets/images/` |
| `*Status bar*` | 见下节，**禁止读取详情** |
| `*Home Indicator*` | 见下节，**禁止读取详情** |

### 系统 UI 装饰层（Status bar / Home Indicator）

设计稿中的 `iPhone Status bar`、`Status bar`、`Home Indicator` 等节点为 **Figma 装饰层**，App 由系统 UI + 安全区处理，**无需还原**。

| 节点 | App 侧处理 |
|------|-----------|
| Status bar | 系统状态栏 + `SmartSafeArea` / `CommonAppbar` |
| Home Indicator | 系统底部指示条 + 底部安全区（`MediaQuery.padding.bottom` / `SmartSafeArea`） |

**必须遵守（省 token）：**

- ❌ **禁止** 对上述节点或其子节点调用 `get_design_context`
- ❌ **禁止** 展开、解析其内部结构（时间、信号、电量、Dynamic Island、底部横条等）
- ❌ `get_metadata` 分块时 **直接跳过** 这些节点，不纳入子 Frame 列表
- ❌ 禁止为 Status bar / Home Indicator 单独写 Widget 或占位 UI

**允许：**

- ✅ 整页 `get_screenshot` 时可出现在截图中（仅作视觉参考，不单独实现）
- ✅ 布局时按 `device-util` / `SmartSafeArea` 处理顶部、底部安全区

### 本地图标

- ✅ `Glob` 列文件名
- ❌ `Read` 读 png/svg 内容

### UI 结构节点（FRAME/TEXT）

正常读取颜色、间距、圆角、字体、对齐。

---

## Step 4：视觉还原

对每个区块：

1. 记录结构（Column/Row/Stack、ScrollView）
2. 记录尺寸（padding、gap、对齐）
3. 记录样式（背景、圆角、阴影）
4. 记录文字（字号、字重、行高、颜色）
5. 记录非显而易见的业务/行为要点（供 §15 注释；样式由代码 + Token 表达）
6. 映射 Token（见 `ui-modification`）
7. 选组件（见 Step 5）
8. 写代码（L2 区块顺序与 build 结构一致，见 §15）
9. 对照截图核对

**映射要点：**

- 颜色 / 间距 / 字体 / 圆角 / 透明度映射只看 `ui-modification`
- 禁止在本 skill 复制样式细则；需要修改样式规则时只改 `ui-modification`
- 行高：见 `ui-modification` §6；Figma 为 Auto/normal 时不写 `height`；有明确 px/em 时 `height = lineHeight / fontSize`

---

## Step 5：组件映射

### 决策树

```
Figma 节点
├── 搜索 lib/Common/Widget/、lib/Util/ 同类组件
├── 查映射表
├── 视觉可贴近 → 复用
├── 视觉差大 → 手写 Widget + Token
└── 无对应 → Container + Token，不擅自建通用组件
```

### 映射表

| Figma 特征 | 项目组件 | 备注 |
|-----------|----------|------|
| 标准二级页 AppBar | `CommonAppbar` | 优先 |
| 自定义 AppBar | `SmartAppBar` | |
| 返回按钮 | `CommonBackButton` | |
| 全屏加载 | `LottieAnimationView` | |
| 空/错态 | `NotLoadedUI` | |
| 网络封面/头像 | `NetworkImageUtil` | |
| 下拉刷新列表 | `RefreshLoaderUtil` | 参考 `ExampleListPage` |
| 全宽圆角主按钮 | `ButtonBig` | 视觉一致时 |
| 安全区 | `SmartSafeArea` | 见 device-util |
| icon/* | `SvgPicture.asset` | Glob 查 assets |
| img/* | `Image.asset` | 2x 规则见 ui-modification |
| 确认弹窗 | `ConfirmMgr` | |

---

## Step 6：生成 Flutter UI

| 场景 | 处理 |
|------|------|
| 新 Page + 有接口 | UI 还原 + `network-request` |
| 新 Page + 无接口 | UI 还原 + Mock + `// TODO: 对接接口` |
| 纯 Widget | 只还原 UI；参数/callback 通过构造函数暴露 |

**生成代码时必须写 UI 区块注释**（格式见 `ui-modification` §15）：

1. **L1** 文件头 `///`：组件功能 + 入口/与父级关系
2. **L2** `// ===== 中文区块名 =====`：build 内每个主要 UI 区域
3. **L3** `_buildXxx` 前 `///`：这个函数**是干什么的**（功能/交互），不写样式参数
4. Figma 对照留在 Step 2–4，**不进仓库**

新 Page 模板见 `ui-page-creation`；路由见 `routing`。

---

## 缺失资源与 Flutter 还原限制（完成时必须输出）

### 缺失资源：允许占位，但必须清单说明

Glob 本地 `assets/` 找不到 Figma 指定切图/图标时：

1. **先用占位** — 从项目已有 `assets/images/svg/`、`assets/images/` 等目录中**任选**语义或尺寸接近的资源；实在没有可用 `Icons.xxx` / 纯色 `Container` 占位
2. **代码标记** — `// TODO: 待设计提供 {figma名} 切图，当前用 {占位路径} 占位`
3. **禁止** curl / 下载 Figma MCP asset 写入 `assets/`
4. **必须输出「缺失资源清单」**（表格或列表），至少包含：

| 列 | 说明 |
|----|------|
| Figma 资源名 | 如 `icon/is_wallet`、`img/select_chapter_bg` |
| 预期本地路径 | Glob 搜索过的路径模式 |
| 当前占位 | 实际使用的替代资源 |
| 状态 | 待设计补图 / 已用代码模拟 |

### Figma 效果：Flutter 难以 1:1 还原时必须说明

实现过程中遇到下列效果，**先用最接近的 Flutter 写法近似**，并在回复中输出 **「Flutter 还原限制清单」**：

| Figma 效果 | Flutter 常见限制 | 建议处理 |
|-----------|-----------------|----------|
| 复杂矢量合成 / `BOOLEAN_OPERATION` | 无法直接导出为单一切图时形状可能偏差 | 待设计导出 svg/png，或 `CustomPaint` 近似 |
| 特殊 `blendMode`（Multiply、Overlay 等叠加） | 多层 blend 与 Figma 预览常有色差 | 注明 blend 类型与近似方案 |
| Inner Shadow / 多层阴影叠加 | `BoxShadow` 无内阴影原生支持 | `CustomPainter` 或双层 Container 近似 |
| Background blur + 半透明叠层 | `BackdropFilter` 性能与模糊半径难精确 | 注明 sigma 近似值 |
| Mesh / Angular / Diamond 渐变 | 仅 `LinearGradient` / `RadialGradient` | 注明渐变类型，必要时 TODO 切图 |
| 噪点 / 纸纹 / grain 纹理 | 无原生 noise | 纹理切图或跳过高频细节 |
| 文字渐变 + 描边 + 阴影组合 | 需 `ShaderMask` + `Stack` 多层 | 注明简化方案 |
| Figma 动画 / Smart Animate | 需 Lottie 或手写 `AnimationController` | 注明需单独动效资产 |
| Drop shadow spread / 非标准 shadow 参数 | `BoxShadow.spreadRadius` 与 Figma 不完全一致 | 注明 Figma 参数与 Flutter 近似值 |
| 精确 1px 发丝线 / 抗锯齿差异 | 设备像素比导致 ±1px 偏差 | 可注明「允许 ±1px」 |

**无上述问题时也要写「Flutter 还原限制：无」或省略该节。**

---

## 完成前自查

### A. Figma 视觉

- [ ] 结构与截图一致（Column/Row/Stack）
- [ ] padding / gap / 对齐一致（允许 ±1px）
- [ ] 圆角、阴影、字号、字重、行高一致
- [ ] 图标尺寸、切图倍率正确
- [ ] 未 curl / 下载 Figma MCP asset；装饰效果用代码模拟；切图来自本地 assets
- [ ] 未 curl / 下载 Figma MCP asset；装饰效果用代码模拟；切图来自本地 assets
- [ ] 组件选型合理

### B. ui-modification 自查清单

- [ ] 逐项确认颜色/间距/字体/安全区/多语言/资源/§15 区块注释

### C. Page 专项

- [ ] `findGetxController()`
- [ ] Page 级状态用 Controller + `Obx`
- [ ] 有 Controller / 需细粒度 rebuild / 性能敏感 → 优先 GetX，不默认 setState
- [ ] 三态加载（Lottie / 内容 / NotLoadedUI）
- [ ] 已注册路由

### D. Widget 专项

- [ ] 独立叶子组件：已判断 GetX 无显著收益才用 `setState`；否则用 GetX 或 `AnimationController`

---

## 布局异常

→ `layout-debug` skill

---

## 关联 Skills

| Skill | 何时 |
|-------|------|
| **ui-modification** | 始终 |
| ui-page-creation | 新建 Page |
| routing | 注册路由 |
| network-request | 对接 API |
| modify-ui | 改已有 UI（非本 skill） |
| layout-debug | 空白/布局异常 |

---

## 输出要求

1. 判定结果：Page / Widget
2. 创建/修改的文件
3. 是否注册路由
4. TODO（资源、接口）
5. **缺失资源清单**（Figma 名 → 预期路径 → 当前占位；无缺失则写「无」）
6. **Flutter 还原限制清单**（Figma 效果 → 原因 → 近似方案；无则写「无」）
7. 与 Figma 的其他已知差异

---

## 参考文件

- `lib/Common/Config/FigmaVariables.dart`
- `docs/Figma命名.md`
- `lib/MainPage/RootPage/BottomBarMainPage/MainPage.dart`（§15 注释范例）
