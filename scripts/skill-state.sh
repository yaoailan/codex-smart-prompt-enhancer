#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SKILL_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
STATE_PATH="$SKILL_ROOT/state.json"
COMMAND="${1:-get}"

usage() {
  printf 'Usage: skill-state.sh [get|on|off]\n' >&2
  exit 2
}

case "$COMMAND" in
  get|status|on|enable|off|disable) ;;
  *) usage ;;
esac

write_state() {
  enabled="$1"
  updated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  temp_path="$SKILL_ROOT/.state-$$.tmp"
  trap 'rm -f "$temp_path"' EXIT HUP INT TERM
  printf '{"enabled":%s,"updatedAt":"%s"}\n' "$enabled" "$updated_at" > "$temp_path"
  mv -f "$temp_path" "$STATE_PATH"
  trap - EXIT HUP INT TERM
}

read_state() {
  if [ ! -f "$STATE_PATH" ]; then
    write_state true
    printf 'enabled\n'
    return
  fi

  if grep -Eq '"enabled"[[:space:]]*:[[:space:]]*false' "$STATE_PATH"; then
    printf 'disabled\n'
  elif grep -Eq '"enabled"[[:space:]]*:[[:space:]]*true' "$STATE_PATH"; then
    printf 'enabled\n'
  else
    write_state true
    printf 'enabled\n'
  fi
}

case "$COMMAND" in
  on|enable) write_state true ;;
  off|disable) write_state false ;;
esac

read_state
