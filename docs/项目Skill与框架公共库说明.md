# 项目 Skill、框架与公共库说明

本文根据当前 FlutterFramework 仓库整理，用于了解项目提供的 AI Skill、技术框架及可复用能力。实际开发时以项目根目录的 [AGENTS.md](../AGENTS.md)、各 Skill 和当前源码为准。

## 一、项目中的 Skill

Skill 是给 AI 编码助手使用的任务规范，说明遇到特定需求时应遵守的流程、项目约定和参考实现。它不是应用运行时依赖，也不代表使用者一定已经掌握该技能。

项目 Skill 位于 [`.agents/skills/`](../.agents/skills/)；每个子目录中的 `SKILL.md` 是具体说明。`.claude/skills` 是指向同一目录的软链接。实际可用的 Skill 还取决于使用的工具及其加载配置。

### 页面与 UI

| Skill | 用途 |
| --- | --- |
| [project-rules](../.agents/skills/project-rules/SKILL.md) | 模块结构、文件和类的命名规范，多文件功能开发时参考。 |
| [ui-page-creation](../.agents/skills/ui-page-creation/SKILL.md) | 新建页面或功能模块时的目录与页面结构。 |
| [ui-modification](../.agents/skills/ui-modification/SKILL.md) | UI 样式、设计 Token、安全区与区块注释规范。 |
| [figma-ui](../.agents/skills/figma-ui/SKILL.md) | 根据 Figma 设计稿新建页面或组件。 |
| [modify-ui](../.agents/skills/modify-ui/SKILL.md) | 修改已有页面或组件的 UI，保留现有业务逻辑。 |
| [common-widgets](../.agents/skills/common-widgets/SKILL.md) | 复用确认弹窗、空状态、加载和开关等公共组件。 |
| [device-util](../.agents/skills/device-util/SKILL.md) | 设备信息、屏幕安全区和刘海屏适配。 |

使用 `figma-ui` 或 `modify-ui` 时，还需同时遵循 `ui-modification`。新增用户可见文案、样式和状态管理等硬性规则以 `AGENTS.md` 为准。

### 数据与基础能力

| Skill | 用途 |
| --- | --- |
| [routing](../.agents/skills/routing/SKILL.md) | 路由注册与页面跳转。 |
| [network-request](../.agents/skills/network-request/SKILL.md) | API 定义、网络请求及响应处理。 |
| [network-image](../.agents/skills/network-image/SKILL.md) | 网络图片加载、缓存、占位与失败状态。 |
| [data-storage](../.agents/skills/data-storage/SKILL.md) | 使用 SharedPreferences、Hive 等存取本地数据。 |
| [create-model](../.agents/skills/create-model/SKILL.md) | 根据 JSON 创建可序列化的 Flutter Model。 |

### 工程协作与质量

| Skill | 用途 |
| --- | --- |
| [analyze-hygiene](../.agents/skills/analyze-hygiene/SKILL.md) | analyze、lint 和 format 的处理约定。 |
| [commit-review-attribution](../.agents/skills/commit-review-attribution/SKILL.md) | Git 提交信息格式及 AI 作者、审查者标记。 |
| [generate-test-notes](../.agents/skills/generate-test-notes/SKILL.md) | 根据改动或提交生成测试修改点和注意事项。 |
| [handoff](../.agents/skills/handoff/SKILL.md) | 整理会话交接文档。 |
| [flutter-performance](../.agents/skills/flutter-performance/SKILL.md) | Flutter 动画与切换性能排查，仅手动调用。 |
| [codex-review-agent](../.agents/skills/codex-review-agent/SKILL.md) | 对指定代码改动进行只读审查，仅手动调用。 |
| [receiving-review-superpower](../.agents/skills/receiving-review-superpower/SKILL.md) | 处理代码审查反馈，仅明确调用时使用。 |
| [requesting-review-superpower](../.agents/skills/requesting-review-superpower/SKILL.md) | 发起代码审查，仅明确调用时使用。 |

### 同事使用的 Skill 与工具

以下按同事提供的信息整理，作为交流和参考资料。压缩包保存在 [`.agents/other/`](../.agents/other/)；放在该目录不代表已经安装或会被当前项目自动加载。使用前需根据对应工具的安装说明配置，并遵守本项目的 `AGENTS.md`。

#### 高昊

- [gh-tools](../.agents/other/gh-tools.zip)：个人工具与自建 Agent Skill 的插件集合，压缩包中包含以下能力：
  - `gh-version-compatibility-review`：审查 Flutter 新旧版本共存时的兼容性风险。
  - `gh-subagents`：多代理任务的分工、协作和验收。
  - `gh-skill-optimizer`：审阅或优化已有 Skill。
  - `gh-prompt-assistant`：结合上下文补全提示词。
  - `gh-project-initialization`：为项目建立 AI 开发规则与配置入口。
  - `gh-review`：代码审查。
  - `gh-workflow`：覆盖需求、计划、实现、验证和交付的开发工作流。
  - `gh-supervisor`：强调任务聚焦、适度验证和直接表达。
- 另外使用：`brainstorming`、`using-agent-skills`、`systematic-debugging`、`karpathy-guidelines`、`writing-for-agents`。

#### 启金

- [html-prototype-to-flutter-verified](<../.agents/other/html-prototype-to-flutter-verified%202.zip>)：将可运行的 HTML 原型还原为 Flutter iOS 和 Android 界面，通过页面状态、交互回放及截图对比进行验证。
- 另外使用：`Ponytail`、`Grillme`、`Karpathy Guidelines`。

## 二、项目框架

FlutterFramework 是一个面向 iOS 和 Android 的 Flutter 基础框架，提供页面组织方式、路由、状态管理、多语言、网络、本地存储、主题和公共组件，供新项目在此基础上开发。它目前不包含具体业务；统计、推送、登录、支付等第三方业务 SDK 需按项目需要接入。

### 主要技术

| 技术 | 在项目中的作用 |
| --- | --- |
| Flutter / Dart | 跨平台界面与应用开发；SDK 版本约束见 [pubspec.yaml](../pubspec.yaml)。 |
| GetX | 页面状态、路由和多语言；业务及页面状态默认优先使用 GetX。 |
| Dio + retry | 网络请求和重试，由项目网络层统一封装。 |
| SharedPreferences、Hive CE、FlutterSecureStorage | 分别用于偏好设置、结构化本地数据及安全键值存储。 |
| flutter_screenutil | 屏幕尺寸适配。 |
| json_serializable / build_runner | 根据 Model 定义生成 JSON 序列化代码。 |

### 目录与开发方式

- [`lib/main.dart`](../lib/main.dart)：应用入口及初始化。
- [`lib/Base/`](../lib/Base/)：基础页面类。
- [`lib/MainPage/`](../lib/MainPage/)：页面和功能模块；[Example](../lib/MainPage/Example/) 展示页面、Controller、Service、Model 和 Widget 的组织方式。
- [`lib/Common/`](../lib/Common/)：跨页面复用的组件、管理器、配置、弹窗和调试工具。
- [`lib/Util/`](../lib/Util/)：网络、路由、本地存储、图片、刷新、设备等工具。
- [`packages/`](../packages/)：通过本地路径引用的第三方包源码。
- [`tools/`](../tools/)：多语言、重命名、打包等开发辅助脚本。

页面通常按 `Page / ViewModel / Model / Widget` 分目录，按需增加 `Mock`。导航使用 GetX 命名路由；Model 使用 `json_serializable`；界面样式复用主题 Token。具体约束见 [AGENTS.md](../AGENTS.md)。

## 三、公共库与复用能力

### 项目公共能力

这些能力是本仓库内的项目封装，开发时优先查找并复用。

| 能力 | 入口 | 作用 |
| --- | --- | --- |
| 路由 | [Route.dart](../lib/Util/Router/Route.dart)、[RouteOpenPage.dart](../lib/Util/Router/RouteOpenPage.dart) | 统一管理命名路由和页面跳转方法。 |
| 网络 | [NetWorkManagerUtil.dart](../lib/Util/NetWorkManager/NetWorkManagerUtil.dart)、[ApiConfig.dart](../lib/Util/Common/ApiConfig.dart) | 封装 Dio 请求与重试，集中管理接口配置。 |
| 本地存储 | [PreferenceUtil.dart](../lib/Util/Common/PreferenceUtil.dart)、[DBManager.dart](../lib/Util/DBManager/DBManager.dart) | 管理偏好设置与 Hive 数据。 |
| 网络图片 | [NetworkImageUtil.dart](../lib/Util/Common/NetworkImageUtil.dart) | 封装网络图片加载、缓存和状态展示。 |
| 下拉刷新 | [RefreshLoaderUtil.dart](../lib/Util/RefreshLoader/RefreshLoaderUtil.dart) | 封装下拉刷新、上拉加载与触感反馈。 |
| 主题与样式 | [FigmaVariables.dart](../lib/Common/Config/FigmaVariables.dart)、[AppThemeMgr.dart](../lib/Common/Manager/AppThemeMgr.dart) | 提供设计 Token 和主题管理。 |
| 弹窗与队列 | [ConfirmMgr.dart](../lib/Common/Popup/ConfirmMgr.dart)、[PopupQueueMgr.dart](../lib/Common/Popup/PopupQueueMgr.dart) | 提供确认弹窗和弹窗队列管理。 |
| 状态组件 | [NotLoadedUI.dart](../lib/Util/Common/NotLoadedUI.dart)、[LoadingView.dart](../lib/Common/Widget/Animation/LoadingView.dart) | 提供空状态、错误状态和按钮加载指示器。 |
| 设备与安全区 | [DeviceUtil.dart](../lib/Util/Common/DeviceUtil.dart)、[SmartSafeArea.dart](../lib/Common/Widget/SmartSafeArea.dart) | 获取设备信息和处理安全区。 |
| 日志、提示 | [LogUtil.dart](../lib/Util/Common/LogUtil.dart)、[Toast.dart](../lib/Util/SheetAndAlter/Toast.dart) | 统一日志和轻提示入口。 |

### 第三方依赖和本地补丁

项目通过 pub 使用 GetX、Dio、cached_network_image、Hive CE、Lottie、flutter_svg 等第三方库，完整清单及版本约束见 [pubspec.yaml](../pubspec.yaml)。

其中两个第三方包以本地路径依赖的方式放在仓库中：

- [`packages/pull_to_refresh-2.0.0`](../packages/pull_to_refresh-2.0.0/)：下拉刷新和上拉加载，本项目标注为本地补丁。
- [`packages/gaimon-1.4.1`](../packages/gaimon-1.4.1/)：触感反馈，本项目标注为本地补丁。

这两个目录是项目构建所需的第三方依赖源码，应随项目保留。
