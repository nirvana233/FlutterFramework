# FlutterFramework

FlutterFramework 是一个面向 iOS 和 Android 的 Flutter 项目基础框架，提供路由、状态管理、网络、多语言、本地存储、主题和常用组件，可作为新项目的起点。

项目包含示例页面和 AI 开发规范，不包含具体业务。统计、推送、登录、支付、广告等业务 SDK 需要按项目需求接入。

## 环境要求

- Flutter ≥ 3.44.0，Dart SDK 版本约束为 `^3.12.0`；以 [pubspec.yaml](pubspec.yaml) 为准。
- Android 最低版本为 API 26；iOS 最低版本为 15.0。
- 构建 iOS 应用需要 macOS、Xcode 和 CocoaPods；Android 开发需要配置 Android SDK。

## 快速开始

克隆仓库后，在项目根目录安装依赖并运行：

```bash
flutter pub get
flutter run
```

运行前请连接设备或启动模拟器，并通过 `flutter doctor` 检查本机开发环境。项目使用本机 PATH 中的 Flutter，不依赖 FVM。

## 主要技术与能力

| 能力 | 技术与入口 |
| --- | --- |
| 状态管理与路由 | GetX；[路由定义和跳转](lib/Util/Router/)。 |
| 网络请求 | Dio + retry；[网络封装](lib/Util/NetWorkManager/)、[API 配置](lib/Util/Common/ApiConfig.dart)。 |
| 本地存储 | SharedPreferences、Hive CE、FlutterSecureStorage；[偏好设置](lib/Util/Common/PreferenceUtil.dart)、[数据库管理](lib/Util/DBManager/DBManager.dart)。 |
| 多语言 | GetX Translations；[多语言工具和生成说明](tools/localization/README.md)。 |
| 主题与适配 | Flutter ScreenUtil、[设计 Token](lib/Common/Config/FigmaVariables.dart) 和[主题管理](lib/Common/Manager/AppThemeMgr.dart)。 |
| 公共组件 | [按钮、加载、安全区等组件](lib/Common/Widget/)、[弹窗管理](lib/Common/Popup/)和[网络图片](lib/Util/Common/NetworkImageUtil.dart)。 |
| 列表与反馈 | [下拉刷新和上拉加载](lib/Util/RefreshLoader/RefreshLoaderUtil.dart)、[震动管理](lib/Common/Manager/VibrationMgr.dart)。 |
| 示例与调试 | [示例模块](lib/MainPage/Example/)包含请求、列表和页面跳转；[调试工具](lib/Common/Debug/)包含 GM 页和日志入口。 |

第三方依赖及版本约束见 [pubspec.yaml](pubspec.yaml)。`packages/` 中的 `pull_to_refresh` 和 `gaimon` 是项目通过本地路径引用的第三方包，需随项目保留。

## 项目结构

```text
lib/
├── main.dart       # 应用入口与初始化
├── Base/           # 基础页面类
├── Common/         # 公共组件、配置、管理器、弹窗和调试工具
├── MainPage/       # 页面和功能模块，包括示例模块
└── Util/           # 路由、网络、存储和其他工具
packages/           # 本地路径依赖
tools/              # 多语言、重命名和打包等脚本
.agents/skills/     # 项目 AI Skill
```

功能页面通常按 `Page / ViewModel / Model / Widget` 组织，可参考 [Example](lib/MainPage/Example/)。

## 基于本框架创建新项目

在新项目副本的根目录执行，替换示例中的包名、Bundle ID 和应用名称：

```bash
python3 tools/rename_project/rename_project.py my_app com.company.myapp "My App"
flutter clean && flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

然后检查并修改：

1. [AGENTS.md](AGENTS.md) 的标题与 Project Overview。
2. [ApiConfig.dart](lib/Util/Common/ApiConfig.dart) 的测试和正式域名。
3. [StringUtil.dart](lib/Util/Common/StringUtil.dart) 的商店及隐私协议链接。
4. [FigmaVariables.dart](lib/Common/Config/FigmaVariables.dart) 的设计 Token。
5. 应用图标、启动图和 Android 正式签名；签名配置参考 [key.properties.example](android/key.properties.example)。

## 常用命令

```bash
flutter run
flutter analyze
dart run build_runner build --delete-conflicting-outputs   # 修改 Model 后生成代码
bash tools/localization/generate_translations.sh           # 更新多语言
bash tools/run_build/android/android_build_abb/android_build_abb.sh  # Android 正式包
```

## AI 开发规范与 Skill

[AGENTS.md](AGENTS.md) 包含项目开发约定。[.agents/skills/](.agents/skills/) 提供页面、UI、路由、网络、存储及工程协作等任务的 Skill，每个目录下的 `SKILL.md` 说明其适用场景和使用方式。

更多项目 Skill、同事使用的工具、框架结构和公共能力介绍见[项目 Skill 与框架公共库说明](docs/项目Skill与框架公共库说明.md)。
