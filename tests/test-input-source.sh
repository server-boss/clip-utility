#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# test-input-source.sh — validate stdin vs clipboard input selection
# ──────────────────────────────────────────────
# Regression test for the non-TTY clipboard bug: when clip is launched
# from Apple Shortcuts / Automator / cron, stdin is /dev/null (not a
# TTY and not a pipe), and clip must still read the clipboard rather
# than transforming empty stdin.
#
# This script itself runs without a TTY, so test 1 faithfully
# reproduces the Shortcuts launch environment.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLIP="${CLIP:-$ROOT_DIR/bin/clip}"

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'
pass=0
fail=0

check() {
  local name="$1" expected="$2" got="$3"
  if [[ "$got" == "$expected" ]]; then
    printf "${GREEN}PASS${RESET} %s\n" "$name"
    pass=$((pass + 1))
  else
    printf "${RED}FAIL${RESET} %s\n  expected: %q\n  got:      %q\n" "$name" "$expected" "$got"
    fail=$((fail + 1))
  fi
}

# 1. stdin = /dev/null (Apple Shortcuts / Automator / cron) → read clipboard
printf 'hello world' | pbcopy
got=$("$CLIP" --upper --no-copy </dev/null)
check "stdin=/dev/null reads clipboard" "HELLO WORLD" "$got"

# 2. piped stdin → read stdin, not clipboard
printf 'clipboard value' | pbcopy
got=$(printf 'piped value' | "$CLIP" --upper --no-copy)
check "pipe reads stdin" "PIPED VALUE" "$got"

# 3. regular-file redirect → read the file, not clipboard
printf 'clipboard value' | pbcopy
tf=$(mktemp)
printf 'file value' >"$tf"
got=$("$CLIP" --upper --no-copy <"$tf")
rm -f "$tf"
check "file redirect reads file" "FILE VALUE" "$got"

echo
echo "── $pass passed, $fail failed ──"
[[ $fail -eq 0 ]]
