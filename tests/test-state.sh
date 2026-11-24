#!/usr/bin/env bash
set -eu

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/prompt-enhance-state.XXXXXX")"
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM

mkdir -p "$TEMP_ROOT/scripts"
cp "$PROJECT_ROOT/scripts/skill-state.sh" "$TEMP_ROOT/scripts/skill-state.sh"
STATE_SCRIPT="$TEMP_ROOT/scripts/skill-state.sh"
STATE_PATH="$TEMP_ROOT/state.json"

assert_equal() {
  if [ "$1" != "$2" ]; then
    printf 'FAIL: %s (expected: %s, actual: %s)\n' "$3" "$2" "$1" >&2
    exit 1
  fi
}

assert_equal "$(bash "$STATE_SCRIPT" get)" "enabled" "Default state"
[ -f "$STATE_PATH" ]

assert_equal "$(bash "$STATE_SCRIPT" off)" "disabled" "Disable command"
grep -Eq '"enabled"[[:space:]]*:[[:space:]]*false' "$STATE_PATH"
assert_equal "$(bash "$STATE_SCRIPT" get)" "disabled" "Persisted disabled state"
assert_equal "$(bash "$STATE_SCRIPT" on)" "enabled" "Enable command"

before_invalid="$(cat "$STATE_PATH")"
set +e
bash "$STATE_SCRIPT" invalid >/dev/null 2>&1
invalid_code=$?
set -e
[ "$invalid_code" -ne 0 ]
assert_equal "$(cat "$STATE_PATH")" "$before_invalid" "Invalid command changed state"

printf '{broken' > "$STATE_PATH"
assert_equal "$(bash "$STATE_SCRIPT" get)" "enabled" "Corrupt state recovery"
grep -Eq '"enabled"[[:space:]]*:[[:space:]]*true' "$STATE_PATH"

printf 'test-state.sh: PASS\n'
