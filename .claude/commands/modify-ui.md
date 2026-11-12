# 修改 UI 样式

修改**已有** UI 样式/布局，或根据 Figma **替换现有**界面视觉，保持业务逻辑不变。

> 新建 Page / Widget → 用 `/figma-ui`。

## 输入格式

`$ARGUMENTS` 格式：`页面/组件名称` 或 `修改描述`

**有 Figma 时：** 提供 Figma 链接（含 `node-id`）

**示例：**

```
/modify-ui TaskPage 按 Figma 替换列表项样式
Figma: https://figma.com/design/...?node-id=42-15
```

```
/modify-ui 把标题颜色改成 primary
```

## 使用方式

1. 运行 `/modify-ui`
2. 无 Figma：描述样式修改
3. 有 Figma：描述要改的目标 + 链接
4. 自动加载 `modify-ui` + `ui-modification`；有 Figma 时同时遵循 `figma-ui` Step 1–5

## 命令职责

薄入口，详细规范见 skill。

执行时必须遵循：

- [`.claude/skills/modify-ui/SKILL.md`](../skills/modify-ui/SKILL.md)
- [`.claude/skills/ui-modification/SKILL.md`](../skills/ui-modification/SKILL.md)
- 有 Figma 链接时：[`.claude/skills/figma-ui/SKILL.md`](../skills/figma-ui/SKILL.md)（Step 1–5）
- GetX API：`AGENTS.md` #8（保留 `Get.back()` 等，不改成 `Navigator`/`Platform`）

## 输出要求

- 说明修改了哪些 Widget 文件
- 说明未改 Controller / 路由 / 接口
- 按 `ui-modification` 自查清单检查
