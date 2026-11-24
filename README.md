# Codex 智能提示词增强器

一个默认启用的 Codex 技能：把复杂、含糊或高风险请求整理成更清楚、可确认、可验证的执行提示词，同时让简单问答和控制语句保持直接。

> 这是“技能 + 全局规则”级增强，不修改 Codex 客户端本体，因此不会因应用升级而覆盖二进制文件。

## 功能

- **默认智能启用**：不用写“增强一下”，也不用输入 `@技能`。
- **只在需要时预览**：复杂、含糊、多步骤、有副作用或有失败风险的任务先生成预览。
- **确认后才执行**：预览不是授权；用户回复“执行”、确认，或修改预览后要求执行，才开始实际操作。
- **简单请求直答**：普通知识问答、简短文字处理，以及“确认/继续/取消”等控制语句不会被强行扩写。
- **本地开关**：支持开启、关闭和查询状态，默认开启。
- **无遥测**：状态只保存在本机技能目录。

## 使用效果

复杂请求会先看到类似下面的内容，而不会立刻开始改文件或联网：

```markdown
## 提示词增强预览

### 增强后的提示词

**目标**：...
**执行范围**：...
**必须满足**：...
**不要做**：...
**成功标准**：...

### 补充假设

- ...

回复“执行”即可开始；你也可以直接修改上面的内容。
```

简单问题不会触发预览。增强功能关闭后，所有请求按普通 Codex 方式处理。

## 安装

需要 Git；Windows 使用 PowerShell，macOS/Linux 使用 Bash。

### Windows

```powershell
git clone https://github.com/yaoailan/codex-smart-prompt-enhancer.git
cd codex-smart-prompt-enhancer
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

### macOS / Linux

```bash
git clone https://github.com/yaoailan/codex-smart-prompt-enhancer.git
cd codex-smart-prompt-enhancer
bash ./scripts/install.sh
```

安装器会：

1. 将技能复制到 `${CODEX_HOME:-~/.codex}/skills/prompt-enhance`；
2. 保留已有 `state.json` 和技能目录中的无关文件；
3. 在 `${CODEX_HOME:-~/.codex}/AGENTS.md` 末尾追加一段带标记的全局触发规则；
4. 修改已有 `AGENTS.md` 前创建时间戳备份。

安装后重启 Codex，使新技能和全局规则生效。

### 自定义 CODEX_HOME

```powershell
.\scripts\install.ps1 -CodexHome "D:\CodexHome"
```

```bash
bash ./scripts/install.sh --codex-home "/path/to/codex-home"
```

## 开关

Windows：

```powershell
& "$env:USERPROFILE\.codex\skills\prompt-enhance\scripts\skill-state.ps1" get
& "$env:USERPROFILE\.codex\skills\prompt-enhance\scripts\skill-state.ps1" on
& "$env:USERPROFILE\.codex\skills\prompt-enhance\scripts\skill-state.ps1" off
```

macOS / Linux：

```bash
bash ~/.codex/skills/prompt-enhance/scripts/skill-state.sh get
bash ~/.codex/skills/prompt-enhance/scripts/skill-state.sh on
bash ~/.codex/skills/prompt-enhance/scripts/skill-state.sh off
```

也可以直接对 Codex 说：

- “开启提示词增强”
- “关闭提示词增强”
- “提示词增强状态”

## 验证

Windows：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-state.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-install.ps1
```

macOS / Linux：

```bash
bash ./tests/test-state.sh
bash ./tests/test-install.sh
```

如已安装官方 `skill-creator`，还可以运行：

```bash
PYTHONUTF8=1 python /path/to/.codex/skills/.system/skill-creator/scripts/quick_validate.py .
```

Windows 上如果 Python 默认使用 GBK，执行前先运行：

```powershell
$env:PYTHONUTF8 = "1"
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" .
```

## 卸载

1. 删除 `${CODEX_HOME:-~/.codex}/skills/prompt-enhance`。
2. 编辑 `${CODEX_HOME:-~/.codex}/AGENTS.md`，删除以下标记之间的内容：

```text
# >>> prompt-enhance: smart default >>>
...
# <<< prompt-enhance: smart default <<<
```

3. 重启 Codex。

## 设计边界

- 增强不会扩大用户原始请求的权限或范围。
- 预览不是执行授权。
- 无法安全推断且影响结果的信息会列入“待确认项”。
- 简单任务不被强制套模板。
- 技能不会收集、上传或分析用户数据。

## English summary

A default-on Codex skill that turns complex or ambiguous requests into explicit, confirmable execution briefs. It previews the enhanced prompt first, waits for confirmation before side effects, keeps simple questions direct, and supports a local on/off switch. It modifies only the installed skill and an append-only marked block in `AGENTS.md`, with a backup.

## License

MIT
