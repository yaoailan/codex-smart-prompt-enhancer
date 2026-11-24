---
name: prompt-enhance
description: Refine a user request into a precise, executable brief before taking action when the request is complex, ambiguous, multi-step, risky, or likely to benefit from explicit scope and success criteria. Apply automatically when global instructions enable smart prompt enhancement; skip simple factual questions and short control messages such as confirm, continue, execute, or cancel.
metadata:
  short-description: Smartly clarify and structure prompts before execution
---

# Smart Prompt Enhancer

Use this skill to improve the task brief, not to expand the user's authority or scope. When smart enhancement is enabled, route each non-control request before acting.

## Route the request

Answer or act directly, without a preview, when the request is:

- a simple factual question, explanation, translation, or short text transformation;
- already explicit, low-risk, and completes in one straightforward step;
- a control message such as confirm, continue, execute, cancel, or a correction to a confirmed task;
- a prompt-enhance state command.

Create an enhancement preview before acting when the request:

- spans multiple steps or deliverables;
- is ambiguous enough that different interpretations produce materially different results;
- would modify files, settings, repositories, systems, external services, or public content;
- has privacy, security, financial, irreversible, or publication risk;
- needs a plan, investigation, debugging, deployment, migration, or broad automation;
- says "do everything", "handle it all", or similar without a safely inferable boundary.

If a single small task is clear and low-risk, do not make the user confirm an unnecessarily embellished prompt.

## Build the enhanced prompt

Preserve the user's actual goal and explicit constraints. Add only details that are strongly implied or materially useful. Never invent preferences, permissions, credentials, private facts, budgets, or deadlines.

Use this structure, keeping only sections that help:

```markdown
## 提示词增强预览

### 增强后的提示词

**目标**：...

**背景与上下文**：...

**执行范围**：...

**必须满足**：...

**不要做**：...

**成功标准**：...

**待确认项**：...

### 补充假设

- ...

回复“执行”即可开始；你也可以直接修改上面的内容。
```

For a short request, three to five concise lines are enough. Do not repeat the original request word for word or create empty headings.

## Confirmation boundary

An enhancement preview is not authorization. After showing it:

- do not call task tools, modify files, access external services, publish, install, send, delete, or otherwise produce side effects;
- do not begin a plan, investigation, or implementation that relies on tools for the enhanced task;
- wait for the user to say execute, confirm, proceed, or an equivalent unambiguous instruction.

Reading or changing the prompt-enhance switch state itself is allowed and is not part of the enhanced task. If the user edits the preview and asks to execute it, treat the edited version as the confirmed brief. Confirmation authorizes only the shown scope, not unrelated follow-up work.

## Switch behavior

Treat these as direct control commands:

- enable: "开启提示词增强", "打开智能增强", "enable prompt enhancement";
- disable: "关闭提示词增强", "关闭智能增强", "disable prompt enhancement";
- status: "提示词增强状态", "是否开启增强".

Use the installed state script when available:

- Windows: `scripts/skill-state.ps1`
- macOS/Linux: `scripts/skill-state.sh`

Commands are `get`, `on`, and `off`. The default is enabled. When disabled, do not show enhancement previews; execute or answer direct requests normally until the user explicitly enables it again.

Do not require the user to type `$prompt-enhance` or an `@skill` mention during normal use.
