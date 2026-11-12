---
name: commit-review-attribution
description: 每次 Git Commit 必用。用户要求 commit/提交/提交代码、手动 @ 本 skill、或 agent 准备执行 git commit 时，必须先加载并遵循本 skill。约束 Conventional Commits 标题/正文格式，并在末尾写入 AI-Author 与 AI-Reviewer 两行 trailers；模型名称与思考等级统一全小写；有思考等级则用 '-' 贴在模型名后。Author/Reviewer 未知先追问，追问后仍没有则写 none。
---

# Commit Message & AI Attribution

本 skill 约束 **整条 commit message**（标题 + 正文 + AI trailers），不是只写 trailers。

Trailers 只记两行：

1. **`AI-Author`**：谁实现 / 修改了本次提交；没有则写 `none`
2. **`AI-Reviewer`**：谁做了 code review；没有则写 `none`

两行都要写。**禁止**把实现者写进 `AI-Reviewer`。

---

## 触发（必用，不可跳过）

以下任一情况 **必须先加载本 skill**，再创建或修改 commit message：

1. 用户明确要求 commit / 提交 / 提交代码 / 创建提交 / amend
2. 用户 `@commit-review-attribution` 或手动附加本 skill
3. agent 在完成实现后准备自行 `git commit`（即使用户未逐字说「提交」）

**禁止**在未遵循本 skill 格式（含 trailers）的情况下完成 commit。

---

## 一、Commit Message 结构（强制）

完整模板（三块之间各空一行）：

```text
<type>(<scope>): <subject>

<body>

AI-Author: <模型名>[-<思考等级>] | none
AI-Reviewer: <模型名>[-<思考等级>] | none
```

| 区块 | 是否必须 | 说明 |
|------|----------|------|
| 标题行 `type(scope): subject` | **必须** | 单行，见下文 |
| 正文 body | 推荐 | 非显而易见的变更应写；纯格式/单点修复合并说明可省略，但有 AI trailers 时标题与 trailers 之间仍保留一个空行 |
| AI trailers | **必须** | 紧接正文末尾（无 body 时紧接标题后空行），见第四节 |

**反例（不合格）：**

- `修复余额栏动画`（缺 type/scope）
- `feat: 加了点东西`（缺 scope、subject 含糊）
- `Update files` / `WIP` / `fix`（非 Conventional、无信息量）
- 标题里写完整段落或换行
- trailers 写在标题同一行，或与正文之间无空行
- 省略 `AI-Author` 或 `AI-Reviewer` 整行，或把值留空
- 再拆 `AI-Author-Model` / `AI-Review:` / `AI-Model` / `*-Reasoning` 等多行

用户若 **明确给出完整 commit 标题/正文**，在不破坏 `type(scope): subject` 与 trailers 规则的前提下尽量保留其措辞；用户未指定时 **必须** 按本 skill 起草。

---

## 二、标题：Conventional Commits（对齐本仓库）

格式：

```text
<type>(<scope>): <subject>
```

无明确模块边界、纯仓库级杂项时允许省略 scope：

```text
<type>: <subject>
```

（本仓库多数提交 **带 scope**，优先带上。）

### 2.1 type（小写，必选其一）

| type | 何时使用 | 本仓库示例 |
|------|----------|------------|
| `feat` | 新功能、用户可感知能力 | `feat(example): 示例列表支持下拉刷新与上拉加载` |
| `fix` | 缺陷修复 | `fix(network): 修复 token 失效后重复跳转登录页` |
| `refactor` | 重构（行为不变） | `refactor(storage): 抽取 PreferenceUtil 通用读写方法` |
| `perf` | 性能优化 | `perf(image): 列表封面按尺寸内存解码` |
| `style` | UI/样式/展示调整（非业务逻辑大改） | `style(mine): 调整设置页列表间距与分割线` |
| `docs` | 仅文档 | `docs(skills): 补充路由注册步骤说明` |
| `chore` | 构建/脚本/资源整理/工具/依赖等杂项 | `chore(i18n): 同步多语言表并重新生成` |
| `test` | 仅测试 | （少见，按需） |
| `build` / `ci` | 构建系统、CI 配置 | （按需） |
| `revert` | 回滚某次提交 | （按需） |

**选型原则：**

- 一次提交只选 **一个** 主 type；主变更是修 bug 用 `fix`，顺带小清理不单独开 `chore`
- 纯资源/脚本/配置且无产品行为 → `chore`
- 逻辑不变只改结构 → `refactor`；变快 → `perf`；只改皮 → `style`

### 2.2 scope（推荐；本仓库常用）

小写英文，用括号包裹。按 **变更主模块** 选择，勿堆砌：

| scope | 适用路径 / 含义 |
|-------|-----------------|
| `network` | `lib/Util/NetWorkManager/**`、`ApiConfig.dart` 等网络层 |
| `router` | `lib/Util/Router/**` |
| `i18n` | 多语言：`lib/Util/Translations/**`、`tools/localization/**`、`MainPage/Language/**` |
| `storage` | `PreferenceUtil`、`DBManager` 等本地存储 |
| `ui` | `lib/Common/Widget/**`、`FigmaVariables` 等公共 UI |
| `debug` | `lib/Common/Debug/**`、GM / TestMgr 等调试 |
| `example` | `lib/MainPage/Example/**` |
| `skills` | `.agents/skills/**` 等 agent skill |

业务模块按 `lib/MainPage/` 下目录语义起短 scope（如 `login`、`home`、`mine`）；跨两模块且同等重要可用 `feat(home,mine): ...`（少用）。

**禁止：** 用文件名当 scope、用中文 scope、无意义 scope（如 `misc`、`update`）。

### 2.3 subject（必选）

- **语言**：优先 **中文**（与近期主线一致）；用户明确要求英文或改动纯英文公共 API 说明时可英文
- **语气**：概述「做了什么」，像 changelog 一句，不用句号结尾
- **禁止**：`修复一些问题`、`更新代码`、`改了下`、无宾语的动词堆砌
- **长度**：尽量 **≤ 50 个汉字/字符量级**（硬上限约 72；超长则精炼 subject，细节放 body）
- **不要** 在 subject 里重复 type（如 `feat: 新增功能 xxx` 中的「新增功能」可直接写能力点）
- **不要** 用 GitHub issue 号独占 subject；需要时可在 body 引用

---

## 三、正文 body（推荐）

标题后空一行再写 body。

**何时应写 body：**

- 多文件 / 多行为点的功能或修复
- 需要说明「为什么」或「怎么做」才读得懂 diff
- 有破坏性变更、迁移步骤、产品取舍

**写法：**

- 中文完整句或分号连接的短句；多点用 `-` 列表
- 写 **行为与意图**，不要罗列文件名清单（`git log`/`diff` 已有路径）
- 1～5 行即可；超长拆 commit 优于写小作文
- 不写机密（token、内网地址、账号）

**可省略 body 的情况：** 单点、标题已完整表达（如纯文案/单行配置）。省略时标题与 AI trailers 之间仍保留一个空行。

---

## 四、AI Trailers（只写两行）

每次 commit 正文末尾空一行后追加，且 **只允许这两行**：

```text
AI-Author: <模型名>[-<思考等级>] | none
AI-Reviewer: <模型名>[-<思考等级>] | none
```

### 4.0 写法

| 字段 | 含义 | 值 |
|------|------|----|
| `AI-Author` | 实现/修改本次提交的模型 | 有则写模型名（**统一全小写**）；有思考等级用 `-` 接在后面，如 `gpt 5.6 sol-medium`。没有写 `none` |
| `AI-Reviewer` | Review 本次提交的模型 | 同上。没有 review 写 `none` |

两行都要有值：**不要留空**，不要写 `yes` / `no`。

- **模型名称与思考等级统一全小写**：无论用户输入的是大写还是小写，模型名和 `-` 右侧的思考等级一律转为全小写（例如：`GPT Astra` → `gpt astra`，`DeepSeek V4 Flash` → `deepseek v4 flash`，`Claude 3.5 Sonnet` → `claude 3.5 sonnet`，`Sol-Medium` → `sol-medium`，`Grok 4.5-High` → `grok 4.5-high`）
- 等级未知则只写模型名，**不要**追问等级，也 **不要**拆成单独字段
- 多人用 ` / ` 连接：`AI-Author: gpt 5.6 sol-max / claude opus-high`
- Git 风格 `Key: value`，不要包代码块或引号
- **不要**再写 `AI-Author-Model`、`AI-Author-Reasoning`、`AI-Review`、`AI-Model`、`AI-Reasoning`

用户话术 → 写入：

| 用户说法 | AI-Author | AI-Reviewer |
|----------|-----------|-------------|
| `GPT 5.6 Sol-Medium 实现，Grok 4.6-xhigh Review` | `gpt 5.6 sol-medium` | `grok 4.6-xhigh` |
| `GPT 5.6 Sol-Max 修改，Grok 4.5-High、DeepSeek V4 Flash Review` | `gpt 5.6 sol-max` | `grok 4.5-high / deepseek v4 flash` |
| `没 review，直接提交`（本会话 grok 4.6 实现） | `grok 4.6` | `none` |
| `Kimi 2.7 Code Review，提交`（本会话 grok 4.6 实现） | `grok 4.6` | `kimi 2.7` |
| `我自己改的` | `human` | `none`（除非另点名了 reviewer） |
| 追问后仍说没有 / 不知道 / 跳过 | `none` | `none` |

### 4.1 提交前确认

Author 与 Reviewer **同一套规则**：能确定就直写；不能确定就追问；追问后仍没有则写 `none`。

可直接写入、不必再问：

- 用户已点名实现者 / reviewer
- 本次提交主要由 **当前正在执行 commit 的 agent** 完成 → `AI-Author` 写该模型（全小写）
- 本会话可追溯的 code review 已覆盖最终提交范围 → `AI-Reviewer` 写该模型（全小写）
- 用户明确「我自己改的 / 人工改的」→ `AI-Author: human`

否则先追问（两个都缺就一次问清，不要拆多轮），**未得到答复前不得 commit**。追问后用户说没有、不知道、跳过、没 review，或仍给不出名字 → 对应字段写 `none` 再提交，不要反复追问。

- 不要为思考等级单独提问
- 仅跑 analyze / 测试 / 格式检查 / 实现自查 **不算** review
- 提交范围混入未 review 文件时：能拆则拆；用户要求一起提交则 `AI-Reviewer: none`

---

## 五、拆分与范围

- **一次提交一个意图**：功能与无关 refactor、格式化大扫除不要捆在一起
- 相关文件（实现 + 直接配套资源/文案）可同 commit；无关 skill/文档/另一模块应另提
- 用户要求「全部提交」时仍用 **一条** message 概括主意图，body 用列表点出次要点；若 diff 明显多主题，可建议拆 commit（用户坚持则单 commit 但 subject 取最大公约数，body 分点）

---

## 六、Commit 流程

1. 加载本 skill
2. 执行 `git status` / `git diff` / `git log`，了解待提交内容与近期标题风格
3. 确定 `AI-Author` / `AI-Reviewer`：已知直写；未知则追问（得到答复前停止）；追问后仍没有写 `none`
4. 按第二节选 `type` / `scope`，起草中文 `subject`；必要时写 body
5. 正文末尾追加两行 trailers
6. 用 HEREDOC 执行 `git commit`，避免 shell 转义破坏中文与换行
7. `git status` 确认成功

---

## 七、完整示例

**用户只说「提交本地」，且 Author / Reviewer 都无法确认—— 先一次问清，得到答复（或明确没有）后再 commit：**

> 准备提交以下变更：
> - 示例列表接入下拉刷新与上拉加载
> - RefreshStateUtil 增加内容未撑满时自动加载
>
> 请确认：本次代码是谁（哪个 AI / 模型）改的？是否有 code review（谁 / 哪个模型）？没有就说没有。

**标准 feat（实现 + review）：**

```text
feat(example): 示例列表支持下拉刷新与上拉加载

ExampleListController 统一维护分页状态，刷新/加载结束走 RefreshStateUtil 收口；
内容未撑满一屏时自动请求下一页。

AI-Author: grok 4.6-xhigh
AI-Reviewer: kimi 2.7
```

**用户：「GPT 5.6 Sol-Max 修改，Grok 4.5-High、DeepSeek V4 Flash Review」：**

```text
fix(storage): 进度保存乱序导致旧数据回写

- 同一 Box 的保存/删除改用 DBManager.runSerial 串行执行
- 写入携带单调 updatedAt，读取时严格择新

AI-Author: gpt 5.6 sol-max
AI-Reviewer: grok 4.5-high / deepseek v4 flash
```

**chore 无 body + 无 review：**

```text
chore(skills): 收紧 commit message 与 AI 归属 trailers 规范

AI-Author: grok 4.6
AI-Reviewer: none
```

**人工修改 + 有 AI review：**

```text
fix(network): 修正分页 hasMore 边界判断

AI-Author: human
AI-Reviewer: gpt 5.6 sol-medium
```

**追问后仍没有：**

```text
chore(skills): 收紧 commit message 与 AI 归属 trailers 规范

AI-Author: none
AI-Reviewer: none
```

**不合格示例（禁止产出）：**

```text
update code
fix bug
WIP

# 缺行或把值留空
AI-Author:
AI-Reviewer: grok 4.6-xhigh

# 拆成多行（旧格式）
AI-Author: gpt
AI-Author-Model: gpt 5.6 sol
AI-Author-Reasoning: medium
AI-Review: yes
AI-Reviewer: grok
AI-Model: grok 4.6
AI-Reasoning: xhigh
```

---

## 八、自检清单（commit 前）

- [ ] 标题匹配 `type(scope): subject` 或 `type: subject`
- [ ] type / scope 与 diff 主意图一致，subject 中文且具体
- [ ] 需要时有 body；标题与 trailers 之间有空行
- [ ] 只有 `AI-Author` 与 `AI-Reviewer` 两行；模型名称与思考等级均已统一转为全小写；思考等级用 `-` 贴在模型名后
- [ ] 两行都有值；未知且追问后仍没有则写 `none`，未留空、未写 `yes` / `no`
- [ ] 未把调试残留、无关文件、密钥塞进本次提交
