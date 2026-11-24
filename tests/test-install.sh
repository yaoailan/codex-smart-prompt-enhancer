#!/usr/bin/env bash
set -eu

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/prompt-enhance-install.XXXXXX")"
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
CODEX_HOME="$TEMP_ROOT/codex-home"
AGENTS_PATH="$CODEX_HOME/AGENTS.md"
ORIGINAL_RULE="# Existing user rule

Keep this line."

mkdir -p "$CODEX_HOME"
printf '%s' "$ORIGINAL_RULE" > "$AGENTS_PATH"
bash "$PROJECT_ROOT/scripts/install.sh" --codex-home "$CODEX_HOME" >/dev/null

DESTINATION="$CODEX_HOME/skills/prompt-enhance"
[ -f "$DESTINATION/SKILL.md" ]
[ -f "$DESTINATION/agents/openai.yaml" ]
[ -f "$DESTINATION/state.json" ]
[ -f "$DESTINATION/rules/prompt-enhance.md" ]
grep -Fq "$ORIGINAL_RULE" "$AGENTS_PATH"
grep -Fqx "# >>> prompt-enhance: smart default >>>" "$AGENTS_PATH"
[ "$(grep -c '^# >>> prompt-enhance: smart default >>>$' "$AGENTS_PATH")" -eq 1 ]
find "$CODEX_HOME" -maxdepth 1 -name 'AGENTS.md.backup-*' | grep -q .

bash "$DESTINATION/scripts/skill-state.sh" off >/dev/null
state_before_reinstall="$(cat "$DESTINATION/state.json")"
printf 'keep' > "$DESTINATION/user-note.txt"
bash "$PROJECT_ROOT/scripts/install.sh" --codex-home "$CODEX_HOME" >/dev/null

[ "$(cat "$DESTINATION/state.json")" = "$state_before_reinstall" ]
[ -f "$DESTINATION/user-note.txt" ]
[ "$(grep -c '^# >>> prompt-enhance: smart default >>>$' "$AGENTS_PATH")" -eq 1 ]

printf 'test-install.sh: PASS\n'
