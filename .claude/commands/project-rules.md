# 文件命名与代码规范

项目文件命名、目录结构和代码风格规范。

## 使用方式

- 当任务涉及多文件改动、新模块或大功能开发时，先加载本规则
- 具体页面、接口、Model 等实现，再分别遵循对应 skill

## 命令职责

此 command 只负责作为项目级规范入口，不重复维护详细规则。

执行时必须遵循：

- [`.claude/skills/project-rules/SKILL.md`](../skills/project-rules/SKILL.md)

## 最小执行要求

- 文件与类命名遵循项目约定
- 模块目录结构符合 `Page / ViewModel / Model / Widget`
- GetX、FigmaVariables、SmartSafeArea 等核心约定保持一致
- 多文件任务先看本规则，再进入具体 skill
