## 1) 命名：重点是“可当 Dart 标识符 + 语义明确 + 稳定一致”

### 1.1 页面/Frame（通常会被 LLM 当成 Widget/类名来源）

* 推荐：英文 **PascalCase**

  * `LoginPage`, `OrderDetailScreen`, `ProfileHeader`
* 避免：`Frame 12`、一堆表情/符号、同文件里大量同名（容易生成重名类/方法）
* 允许中文吗？能用，但**生成 Flutter 时往往会被转义/拼音/乱改**，不如直接英文稳定。

### 1.2 图层/控件（Text、Icon、Button 等）

* 用“角色 + 含义”的规则，别用默认名：

  * `titleText`, `subtitleText`, `priceText`
  * `avatarImage`, `closeIcon`, `primaryButton`
* 列表项里重复元素要编号或用一致后缀：

  * `tagChip_01`, `tagChip_02`
  * 或 `tagChipLeading`, `tagChipTrailing`

### 1.3 组件（Component）命名：用 Figma 推荐的“斜杠分层”

Figma 官方推荐用 `/` 做层级组织组件名，比如 `UI/Button/Active` 这类，便于归类和检索。([Figma帮助中心][2])
建议你在组件库里用类似：

* `Buttons/Primary`
* `Buttons/Secondary`
* `Cells/OrderItem`
* `Forms/TextField`

这会让 LLM 更容易“看懂这是可复用组件”，而不是每个页面都生成一份重复 Widget。

### 1.4 Variants（变体）命名：尽量用属性语义，而不是硬编码在名字里

Figma 的变体/组件集本身就是围绕“属性/值”组织的；同时 Figma 也强调命名组织方式（包含斜杠体系）。([Figma帮助中心][3])
对 Flutter 生成更友好的属性集合是：

* `State`: `Default / Pressed / Disabled`
* `Size`: `S / M / L`
* `Type`: `Primary / Secondary / Tertiary`
* `Icon`: `None / Leading / Trailing`（或 bool）

---

## 2) 结构：决定 LLM 能不能推断出合理的 Flutter 布局

### 2.1 少用 Group，多用 Auto Layout + Frame

对 LLM 来说，Frame/Auto Layout 的语义更明确，能更稳定推断成 `Column/Row/Flex`、间距、对齐方式；Group 往往语义弱、层级乱，生成更容易“套一堆 Stack/Positioned”。

### 2.2 可复用的东西尽量做成 Component（别在每个页面画一遍）

因为这个 MCP 会把设计信息作为上下文提供给模型([GitHub][1])，你做成 Component + Variant，模型更容易：

* 抽出独立 Widget
* 复用同一套样式
* 给出更像工程代码的拆分方式

---

## 3) 设计系统/样式：命名要能映射到 Theme / 常量

### 3.1 Styles / Variables 用斜杠分组 + 语义化命名

Figma 官方也推荐 styles 用 slash 或 dash 分组，并且名字要贴近使用场景。([Figma帮助中心][4])
建议：

* 颜色：`Color/Primary`, `Color/Surface`, `Color/Text/Secondary`
* 字体：`Typography/Title/L`, `Typography/Body/M`

这样 LLM 更可能生成：

* `ThemeData` / `ColorScheme` / `TextTheme`
* 或至少生成集中式 `AppColors`、`AppTextStyles`，而不是满屏 magic numbers。

---