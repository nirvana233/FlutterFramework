# Flutter API 接口生成器

快速添加新的 API 接口配置和调用方法。

## 输入格式

`$ARGUMENTS` 格式：`接口名称` 或 `接口名称 --options`

**可选参数：**

- `--get`: GET 请求（默认）
- `--post`: POST 请求
- `--put`: PUT 请求
- `--delete`: DELETE 请求
- `--with-model`: 同时生成对应的 Model 类

**示例：**

- `/create-api getUserProfile` - 添加 GET 接口
- `/create-api submitFeedback --post` - 添加 POST 接口
- `/create-api getBookList --with-model` - 添加接口并生成 Model

## 使用方式

1. 运行 `/create-api 接口名称`
2. 说明请求方法、接口路径、参数和返回结构
3. 自动加载 `network-request` skill 执行
4. 如需生成 Model，同时参考 `create-model` skill

## 命令职责

此 command 只负责作为 API 创建入口，不重复维护详细网络规范。

执行时必须遵循：

- [`.claude/skills/network-request/SKILL.md`](../skills/network-request/SKILL.md)
- [`.claude/skills/create-model/SKILL.md`](../skills/create-model/SKILL.md) `--with-model` 时使用

## 最小执行要求

- 在 `ApiConfig.dart` 中定义接口常量
- 所有请求统一通过 `NetWorkManagerUtil.instance`
- 补全异常处理、日志和业务错误提示
- 若需要 Model，按 `create-model` skill 补全外层响应结构

## 输出要求

- 说明新增了哪些接口常量和调用方法
- 若同时生成 Model，说明对应的 Model 文件
- 若改动后需要 `build_runner`，明确提醒
