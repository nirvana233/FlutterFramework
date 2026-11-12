---
name: requesting-review-superpower
description: >
  仅在用户明确调用本 skill 时使用（如 @requesting-review-superpower、
  /requesting-review-superpower、或明确说「按 superpower 发起 review」）。
  禁止因完成任务、实现功能、合并前、修 bug、卡住等场景自动触发或主动建议加载。
  不要与项目内 commit-review-attribution 等其它 review 流程混淆。
---

# Requesting Review (Superpower)

> **手动 skill**：未经用户点名，不要加载、不要执行、不要在回复里主动推荐本 skill。

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often — **but only when the user asks for this skill.**

## When to Use (user-invoked only)

Use **only** after the user explicitly invokes this skill. Do **not** treat any of the following as auto-triggers:

- Finishing a task / major feature
- Before merge to main
- Stuck / before refactor / after complex bugfix
- Subagent-driven development task boundaries
- Executing plans checkpoints

If the user did not name this skill, continue normal work without it.

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code reviewer subagent:**

Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. Present feedback only — do not auto-fix:**
- Summarize the reviewer’s findings to the user (Strengths / Issues / Assessment)
- Report Critical / Important / Minor clearly so the user can decide
- **Do not** edit code, commit, or “顺手修掉”任何级别的问题，除非用户在 review 之后**另行明确要求**修复
- If you believe the reviewer is wrong, say so with reasoning in the summary — still do not change code on your own

## Example

```
[User: @requesting-review-superpower 帮我 review 刚才 Task 2 的改动]

You: Let me request code review as requested.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Present the full review summary to the user — stop here; wait for user direction before any fixes]
```

## Integration with Workflows (still user-gated)

Even inside larger workflows (subagent-driven development, executing plans, ad-hoc work), only run this skill when the user explicitly asks. Do not schedule automatic reviews at task boundaries.

## Red Flags

**Never:**
- Auto-invoke this skill without user request
- Skip review when user **did** ask, because "it's simple"
- Auto-fix Critical / Important / Minor issues after a requested review
- Silently drop or bury findings — always surface them to the user
- Argue with valid technical feedback *instead of reporting it* (you may note disagreement in the summary)

**If reviewer wrong:**
- Note the disagreement with technical reasoning in the user-facing summary
- Show code/tests that support the pushback
- Still leave the decision (and any code changes) to the user

See template at: [code-reviewer.md](code-reviewer.md)
