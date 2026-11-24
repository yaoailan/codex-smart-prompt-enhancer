#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOURCE_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
CODEX_HOME_ARG=""

usage() {
  printf 'Usage: install.sh [--codex-home PATH]\n' >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --codex-home)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      CODEX_HOME_ARG="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ -n "$CODEX_HOME_ARG" ]; then
  CODEX_ROOT="$CODEX_HOME_ARG"
elif [ -n "${CODEX_HOME:-}" ]; then
  CODEX_ROOT="$CODEX_HOME"
else
  CODEX_ROOT="$HOME/.codex"
fi

DESTINATION="$CODEX_ROOT/skills/prompt-enhance"
mkdir -p "$DESTINATION/agents" "$DESTINATION/scripts" "$DESTINATION/rules"

for file in SKILL.md README.md LICENSE PRIVACY.md; do
  if [ -f "$SOURCE_ROOT/$file" ]; then
    cp -f "$SOURCE_ROOT/$file" "$DESTINATION/$file"
  fi
done
cp -R "$SOURCE_ROOT/agents/." "$DESTINATION/agents/"
cp -R "$SOURCE_ROOT/scripts/." "$DESTINATION/scripts/"
cp -R "$SOURCE_ROOT/rules/." "$DESTINATION/rules/"

STATE_PATH="$DESTINATION/state.json"
if [ ! -f "$STATE_PATH" ]; then
  printf '{"enabled":true,"updatedAt":"%s"}\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$STATE_PATH"
fi

if grep -Eq '"enabled"[[:space:]]*:[[:space:]]*false' "$STATE_PATH"; then
  STATE_LABEL="disabled"
else
  STATE_LABEL="enabled"
fi

MARKER_START="# >>> prompt-enhance: smart default >>>"
MARKER_END="# <<< prompt-enhance: smart default <<<"
AGENTS_PATH="$CODEX_ROOT/AGENTS.md"
RULES_PATH="$DESTINATION/rules/prompt-enhance.md"
BACKUP_PATH=""

mkdir -p "$CODEX_ROOT"
TEMP_AGENTS="$(mktemp "$CODEX_ROOT/.AGENTS.XXXXXX")"
trap 'rm -f "$TEMP_AGENTS"' EXIT HUP INT TERM

has_start=0
has_end=0
if [ -f "$AGENTS_PATH" ]; then
  grep -Fqx "$MARKER_START" "$AGENTS_PATH" >/dev/null 2>&1 && has_start=1
  grep -Fqx "$MARKER_END" "$AGENTS_PATH" >/dev/null 2>&1 && has_end=1
fi

if [ "$has_start" -ne "$has_end" ]; then
  printf 'AGENTS.md contains only one prompt-enhance marker. Repair the markers before reinstalling.\n' >&2
  exit 1
fi

if [ "$has_start" -eq 1 ]; then
  awk -v start="$MARKER_START" -v end="$MARKER_END" -v rules="$RULES_PATH" '
    $0 == start {
      print $0
      while ((getline line < rules) > 0) print line
      close(rules)
      skipping = 1
      next
    }
    $0 == end {
      skipping = 0
      print
      next
    }
    !skipping { print }
  ' "$AGENTS_PATH" > "$TEMP_AGENTS"
else
  if [ -f "$AGENTS_PATH" ]; then
    cat "$AGENTS_PATH" > "$TEMP_AGENTS"
    if [ -s "$AGENTS_PATH" ]; then
      printf '\n\n' >> "$TEMP_AGENTS"
    fi
  fi
  printf '%s\n' "$MARKER_START" >> "$TEMP_AGENTS"
  cat "$RULES_PATH" >> "$TEMP_AGENTS"
  printf '%s\n' "$MARKER_END" >> "$TEMP_AGENTS"
fi

if [ ! -f "$AGENTS_PATH" ] || ! cmp -s "$AGENTS_PATH" "$TEMP_AGENTS"; then
  if [ -f "$AGENTS_PATH" ]; then
    BACKUP_PATH="$AGENTS_PATH.backup-$(date '+%Y%m%d-%H%M%S')"
    cp -p "$AGENTS_PATH" "$BACKUP_PATH"
  fi
  mv -f "$TEMP_AGENTS" "$AGENTS_PATH"
fi

printf 'Installed prompt-enhance to: %s\n' "$DESTINATION"
printf 'State: %s\n' "$STATE_LABEL"
if [ -n "$BACKUP_PATH" ]; then
  printf 'Global rules: updated %s\n' "$AGENTS_PATH"
  printf 'Backup: %s\n' "$BACKUP_PATH"
elif [ ! -f "$AGENTS_PATH" ]; then
  printf 'Global rules: not installed\n'
else
  printf 'Global rules: unchanged %s\n' "$AGENTS_PATH"
fi

rm -f "$TEMP_AGENTS"
trap - EXIT HUP INT TERM
