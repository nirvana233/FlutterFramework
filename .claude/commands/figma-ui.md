# Figma UI 还原（新建）

根据 Figma 设计稿 **新建** Page 或 Widget，1:1 还原视觉。

> 改已有页面 UI → 用 `/modify-ui`，不要用本命令。

## 输入格式

`$ARGUMENTS` 格式：`模块名称` 或 `模块名称 --options`

**必填：** Figma 链接（必须含 `node-id`）

**可选参数：**

- `--page`：强制按完整 Page 处理
- `--widget`：强制只生成 Widget
- `--with-args`：新 Page 需要路由参数
- `--mock`：无接口时数据写死

**示例：**

```
/figma-ui TransactionHistory
Figma: https://figma.com/design/abc123/Shop?node-id=42-15
```

## 使用方式

1. 运行 `/figma-ui`，或发送 Figma 链接 +「新建/生成页面或组件」
2. 自动加载 `figma-ui` + `ui-modification`

## 命令职责

薄入口，详细规范见 skill。

执行时必须遵循：

- [`.claude/skills/figma-ui/SKILL.md`](../skills/figma-ui/SKILL.md)
- [`.claude/skills/ui-modification/SKILL.md`](../skills/ui-modification/SKILL.md)
- 状态管理：`AGENTS.md` #7；GetX API：`AGENTS.md` #8（`Get.back()`、`Get.toNamed()`、`GetPlatform`、`Get.width` 等）
