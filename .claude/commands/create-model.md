# Flutter Model 生成器

根据 JSON 数据自动生成 `json_serializable` 格式的 Model 类。

## 输入格式

`$ARGUMENTS` 格式：`模型名称` 或 `模型名称 --options`

**可选参数：**

- `--api-response`: 生成标准 API 响应包装格式（含 code/result/msg）
- `--with-enum`: 提示添加枚举类型
- `--nested`: 包含嵌套对象
- `--list`: 结果是列表类型
- `--modify`: 修改已有 Model（新增/删除/变更字段）

**示例：**

- `/create-model UserProfile` - 生成基础模型
- `/create-model OrderDetail --api-response` - 生成带 API 响应包装的模型
- `/create-model BookInfo --nested` - 生成带嵌套对象的模型
- `/create-model BookInfo --modify` - 修改已有 BookInfoModel

## 使用方式

1. 运行 `/create-model 模型名称`
2. 提供 JSON 示例，或说明需要修改的字段
3. 自动加载 `create-model` skill 执行

## 命令职责

此 command 只负责作为 Model 创建 / 修改入口，不重复维护详细建模规范。

执行时必须遵循：

- [`.claude/skills/create-model/SKILL.md`](../skills/create-model/SKILL.md)

## 最小执行要求

- 根据 JSON 结构推导字段类型
- 接口返回数据默认补全外层响应包装字段
- 修改已有 Model 时，先读取现有文件再做差异化更新
- 明确 `.g.dart` 由 `build_runner` 生成，禁止手改

## 输出要求

- 说明新增或修改了哪些字段
- 若有嵌套对象或列表，说明生成的子类结构
- 若改动后需要 `build_runner`，明确提醒
