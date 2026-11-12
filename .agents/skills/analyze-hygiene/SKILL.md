---
name: analyze-hygiene
description: >-
  flutter/dart analyze、lint 与 format 收尾策略。当用户跑 analyze/format、提到
  directives_ordering、import 排序、「只剩 import 问题」、lint 清理、构建检查或 verification 时触发。
  规定未经用户明确要求不运行构建检查；格式化时忽略 .g.dart，且不主动修 import 排序。
version: 1.2.0
---

# Analyze / Lint / Format 收尾（AI 行为）

## 硬性规则：未经明确要求，不运行构建检查

- 只有用户明确要求构建、打包或编译验证时，才运行相应检查；开发、修复、SDK 接入、Review 或笼统的「检查一下」「验证一下」不代表授权构建。
- 默认不执行 `flutter build`、Gradle 的 assemble/bundle/compile 构建任务、`xcodebuild build/archive`，也不通过脚本、IDE 或 `flutter run` 间接触发编译验证。debug、profile、release 和无签名构建均适用。
- 未获明确要求时，按任务需要做源码核查、差异检查、静态分析；不要主动发起构建确认来替代这一默认行为。
- 用户要求停止或不要构建时，停止本轮已启动的构建，不继续其他平台的构建；如实说明未完成构建验证，不把静态分析当作构建通过。

## 硬性规则：格式化必须忽略 `.g.dart`

所有 `dart format` / `rtk dart format` 以及格式验证都必须排除 `**/*.g.dart`。

### 必须遵守

1. **禁止**运行会递归包含 `.g.dart` 的 `dart format .`、`dart format lib` 或等价命令。
2. 全仓或目录格式化时，先构建排除 `.g.dart` 的 Dart 文件列表，例如：

   ```bash
   rg --files -0 -g '*.dart' -g '!*.g.dart' | xargs -0 rtk dart format
   ```

3. 针对改动文件运行格式化或 `--output=none --set-exit-if-changed` 验证时，也要先过滤掉 `.g.dart`。
4. `.g.dart` 以 `build_runner` / 对应生成器的原始输出为准；生成后不再对它们执行手动格式化。

## 硬性规则：不要修 import 排序

本项目 `analysis_options.yaml` 虽开启 `directives_ordering`，但 **AI 不得为了通过 analyze 而去调整 import/export/part 的顺序**。

原因：纯排序改动 diff 大、与功能无关，人工/IDE 偶尔整理即可，AI 每次顺手改很费时间。

### 必须遵守

1. **`flutter analyze` / `dart analyze` 若仅剩 `directives_ordering`（或同类 import 排序）问题** → 视为**可接受**，在汇报中写明「仅剩 import 排序，按项目约定不修」，**不要**改任何文件的 import 块。
2. **禁止**为清 lint 而：重排 import、运行 `dart fix --apply` 仅针对排序、批量 `organize imports`、在无关 PR 里附带排序 diff。
3. **任务完成判定**：仅有 `directives_ordering` 时，**仍可声明功能/逻辑相关 analyze 已通过**；不要把「未修 import 排序」当作未完成项反复修改。
4. **混合问题**：若 analyze 同时有**非排序**错误（类型错误、未使用变量、缺失返回等）→ 只修非排序项；**不要**顺带整理 import。

### 唯一例外

用户**明确要求**整理 import、跑 organize imports、或「把 directives_ordering 也修掉」时，才可按 `directives_ordering` 规则排序。

## 识别方式

常见 analyzer 文案（均视为排序类，跳过不修）：

- `directives_ordering`
- `Sort directive sections alphabetically`
- import / export / part 顺序相关提示

## 汇报模板（推荐）

```
analyze：无逻辑/类型类问题。
仅剩 directives_ordering（import 排序），按 analyze-hygiene 约定未修改。
```

## 与仓库配置的关系

- **Lint 仍对开发者/CI 生效**；本 skill 只约束 **AI  agent 的默认行为**，不要求改 `analysis_options.yaml`。
- 写新代码时**可**按习惯添加 import，**无需**为符合字母序而反复调整已有文件。
