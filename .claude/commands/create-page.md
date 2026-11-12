# Flutter 页面生成器

根据项目规范，为模块 `$ARGUMENTS` 生成完整的页面结构。

## 输入格式

`$ARGUMENTS` 格式：`模块名称` 或 `模块名称 --options`

**可选参数：**

- `--no-model`: 不生成 Model 文件
- `--no-widget`: 不创建 Widget 目录
- `--with-args`: 页面需要接收参数
- `--simple`: 生成简化版本（无 Model、无 Widget）

**示例：**

- `/create-page UserProfile` - 生成完整结构
- `/create-page Settings --simple` - 生成简化版本
- `/create-page ProfileDetail --with-args` - 生成带参数的页面

## 使用方式

1. 运行 `/create-page 模块名称`
2. 说明是否带参数、是否需要 Model、是否需要 Widget 目录
3. 自动加载 `ui-page-creation` skill 执行
4. 同步参考 `routing` 和 `project-rules` skill

## 命令职责

此 command 只负责页面创建入口，不重复维护详细页面模板和规范。

执行时必须遵循：

- [`.claude/skills/ui-page-creation/SKILL.md`](../skills/ui-page-creation/SKILL.md)
- [`.claude/skills/routing/SKILL.md`](../skills/routing/SKILL.md)
- [`.claude/skills/project-rules/SKILL.md`](../skills/project-rules/SKILL.md)

## 最小执行要求

- 按项目目录结构创建 Page / ViewModel / Model / Widget
- Controller 统一使用 `findGetxController()`
- 页面有参数时，使用 `StatefulWidget` + `widget.arguments`（路由注册传入 `arguments`，禁止 Page 内 `Get.arguments`）
- 创建完成后补齐路由注册

## 输出要求

- 说明创建了哪些目录和文件
- 说明是否注册了路由
- 若保留 TODO 占位，说明后续需要补什么
