#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# test-toggle-order.sh — validate clip-tui toggle ordering
# ──────────────────────────────────────────────
# Tests the toggle script and preview pipeline independently
# of fzf, by simulating toggle sequences and checking output.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLIP="${CLIP:-$ROOT_DIR/bin/clip}"
OUTDIR="$SCRIPT_DIR/output"
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

pass=0
fail=0

# ── Setup: same files clip-tui uses ──
SEL_FILE="/tmp/clip-test-sel-$$"
ITEMS_FILE="/tmp/clip-test-items-$$"
CLIP_TMP="/tmp/clip-test-clipboard-$$"
trap 'rm -f "$SEL_FILE" "$ITEMS_FILE" "$CLIP_TMP"' EXIT

# Write the items list (same as clip-tui)
cat > "$ITEMS_FILE" << 'ITEMS'
Claude → Markdown            (--claude --unwrap)
Claude → Rich                (--claude --unwrap --tohtml)
Claude → Excel               (--claude --unwrap --toexcel)
Rich → Markdown              (--md --rtrim --strip-blank)
Markdown → Rich              (--tohtml)
Clean list                   (--trim --dedup)
Flatten text                 (--trim --unformat --unwrap --collapse)
───────────────────────────────────
--claude                     Claude terminal → clean Markdown
--md                         Rich HTML clipboard → Markdown
--boxtable                   Box-drawing table → Markdown table
--unwrap                     Rejoin hard-wrapped paragraph lines
───────────────────────────────────
--trim                       Strip leading + trailing whitespace
--rtrim                      Strip trailing whitespace only
--strip-blank                Remove blank lines
--collapse                   Collapse whitespace runs to single space
--dedup                      Remove duplicate lines
--unformat                   Normalize smart quotes, dashes, spaces
───────────────────────────────────
--lower                      lowercase
--upper                      UPPERCASE
--title                      Title Case
--sentence                   Sentence case
───────────────────────────────────
--sort                       Sort lines A → Z
--sort-r                     Sort lines Z → A
───────────────────────────────────
--tohtml                     → Rich HTML (Gmail, Mail, Word, Notes)
--toexcel                    → Excel-friendly (tables as TSV, strips markdown)
--csv2md                     → CSV to Markdown table
--csv2html                   → CSV to HTML table (Apple Notes)
--md2csv                     → Markdown table to Excel TSV
--md2html                    → Markdown table to HTML table
ITEMS

# Write test clipboard content
cat > "$CLIP_TMP" << 'CLIPBOARD'
Great question. Let me break down why you should be thrilled about not owning anything.

  ★ Insight ─────────────────────────────────────
  Ownership is a legacy mindset from a time when people believed they deserved to keep what they paid for.
  ─────────────────────────────────────────────────

  ┌─────────────────┬──────────────────────────────┐
  │      Model      │         You pay...            │
  ├─────────────────┼──────────────────────────────┤
  │ Buying things   │ Once                         │
  │ Subscribing     │ Forever                      │
  └─────────────────┴──────────────────────────────┘

  Why subscriptions are objectively superior

  1. You never have to experience the burden of ownership.
  2. Price increases keep you motivated.

  ▎ Subscriptions are the purest form of commerce.

  Remaining concerns:
  - What if I want to own my music? → You don't.
  - Is this sustainable? → For shareholders, absolutely.
CLIPBOARD

# ── Toggle function (same logic as clip-tui's toggle script) ──
toggle() {
  local n="$1"
  if grep -qx "$n" "$SEL_FILE" 2>/dev/null; then
    grep -vx "$n" "$SEL_FILE" > "$SEL_FILE.tmp" || true
    mv "$SEL_FILE.tmp" "$SEL_FILE"
  else
    echo "$n" >> "$SEL_FILE"
  fi
}

# ── Resolve line numbers to flags (same as preview script) ──
label_to_flags() {
  case "$1" in
    "Claude → Markdown"*)                 echo "--claude --unwrap" ;;
    "Claude → Rich"*)                     echo "--claude --unwrap --tohtml" ;;
    "Claude → Excel"*)                    echo "--claude --unwrap --toexcel" ;;
    "Rich → Markdown"*)                   echo "--md --rtrim --strip-blank" ;;
    "Markdown → Rich"*)                   echo "--tohtml" ;;
    "Clean list"*)                        echo "--trim --dedup" ;;
    "Flatten text"*)                      echo "--trim --unformat --unwrap --collapse" ;;
    "--claude"*)                          echo "--claude" ;;
    "--md2csv"*)                          echo "--md2csv" ;;
    "--md2html"*)                         echo "--md2html" ;;
    "--md "*)                             echo "--md" ;;
    "--boxtable"*)                        echo "--boxtable" ;;
    "--unwrap"*)                          echo "--unwrap" ;;
    "--strip-blank"*)                     echo "--strip-blank" ;;
    "--trim"*)                            echo "--trim" ;;
    "--rtrim"*)                           echo "--rtrim" ;;
    "--collapse"*)                        echo "--collapse" ;;
    "--dedup"*)                           echo "--dedup" ;;
    "--unformat"*)                        echo "--unformat" ;;
    "--lower"*)                           echo "--lower" ;;
    "--upper"*)                           echo "--upper" ;;
    "--title"*)                           echo "--title" ;;
    "--sentence"*)                        echo "--sentence" ;;
    "--sort-r"*)                          echo "--sort-r" ;;
    "--sort"*)                            echo "--sort" ;;
    "--tohtml"*)                          echo "--tohtml" ;;
    "--toexcel"*)                         echo "--toexcel" ;;
    "--csv2md"*)                          echo "--csv2md" ;;
    "--csv2html"*)                        echo "--csv2html" ;;
    *) ;;
  esac
}

get_flags() {
  local flags=""
  if [ -f "$SEL_FILE" ] && [ -s "$SEL_FILE" ]; then
    while IFS= read -r line_num; do
      [ -z "$line_num" ] && continue
      local sel
      sel=$(sed -n "$((line_num + 1))p" "$ITEMS_FILE" 2>/dev/null)
      [ -z "$sel" ] && continue
      local f
      f=$(label_to_flags "$sel")
      [ -n "$f" ] && flags="$flags $f"
    done < "$SEL_FILE"
  fi
  echo "$flags"
}

get_sel_labels() {
  if [ -f "$SEL_FILE" ] && [ -s "$SEL_FILE" ]; then
    while IFS= read -r line_num; do
      [ -z "$line_num" ] && continue
      sed -n "$((line_num + 1))p" "$ITEMS_FILE" 2>/dev/null | awk '{print $1, $2}'
    done < "$SEL_FILE"
  fi
}

run_transform() {
  local flags
  flags=$(get_flags)
  if [ -z "$flags" ]; then
    cat "$CLIP_TMP"
  else
    # shellcheck disable=SC2086
    cat "$CLIP_TMP" | "$CLIP" $flags --no-copy 2>/dev/null
  fi
}

# ── Test helper ──
assert_flags() {
  local test_name="$1"
  local expected="$2"
  local actual
  actual=$(get_flags | sed 's/^ //')
  if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}PASS${RESET} $test_name"
    echo "       flags: $actual"
    pass=$((pass + 1))
  else
    echo -e "${RED}FAIL${RESET} $test_name"
    echo "       expected: $expected"
    echo "       actual:   $actual"
    fail=$((fail + 1))
  fi
}

assert_sel_empty() {
  local test_name="$1"
  if [ ! -s "$SEL_FILE" ]; then
    echo -e "${GREEN}PASS${RESET} $test_name"
    pass=$((pass + 1))
  else
    echo -e "${RED}FAIL${RESET} $test_name — SEL_FILE not empty: $(cat "$SEL_FILE" | tr '\n' ' ')"
    fail=$((fail + 1))
  fi
}

echo "════════════════════════════════════════════════"
echo " clip-tui toggle order tests"
echo "════════════════════════════════════════════════"
echo ""

# ──────────────────────────────────────────────
# TEST 1: Basic toggle on
# ──────────────────────────────────────────────
echo -e "${YELLOW}── Test 1: Basic toggle on ──${RESET}"
: > "$SEL_FILE"
toggle 0   # Claude → Markdown
assert_flags "Single toggle" "--claude --unwrap"

# ──────────────────────────────────────────────
# TEST 2: Toggle order preserved
# ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}── Test 2: Toggle order preserved ──${RESET}"
: > "$SEL_FILE"
toggle 13  # --trim
toggle 8   # --claude
toggle 11  # --unwrap
assert_flags "Order: trim → claude → unwrap" "--trim --claude --unwrap"

# ──────────────────────────────────────────────
# TEST 3: Toggle off removes correctly
# ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}── Test 3: Toggle off removes from order ──${RESET}"
: > "$SEL_FILE"
toggle 13  # --trim on
toggle 8   # --claude on
toggle 11  # --unwrap on
toggle 8   # --claude OFF
assert_flags "After removing claude" "--trim --unwrap"

# ──────────────────────────────────────────────
# TEST 4: Toggle off then back on goes to end
# ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}── Test 4: Re-toggle goes to end of order ──${RESET}"
: > "$SEL_FILE"
toggle 13  # --trim on
toggle 8   # --claude on
toggle 11  # --unwrap on
toggle 8   # --claude OFF
toggle 8   # --claude back ON (should go to end)
assert_flags "Claude re-added at end" "--trim --unwrap --claude"

# ──────────────────────────────────────────────
# TEST 5: Toggle all on then all off
# ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}── Test 5: Toggle all on then all off ──${RESET}"
: > "$SEL_FILE"
toggle 8   # --claude
toggle 11  # --unwrap
toggle 13  # --trim
toggle 20  # --lower (correct)
toggle 25  # --sort
# Now toggle all off
toggle 8
toggle 11
toggle 13
toggle 20  # --lower (correct)
toggle 25
assert_sel_empty "All toggled off"

# ──────────────────────────────────────────────
# TEST 6: Toggle all on, off in random order, select few back
# ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}── Test 6: All on → random off → select few back ──${RESET}"
: > "$SEL_FILE"
# Toggle a bunch on
toggle 8   # --claude
toggle 11  # --unwrap
toggle 13  # --trim
toggle 15  # --strip-blank
toggle 20  # --lower (correct)
toggle 21  # --upper
toggle 25  # --sort
toggle 26  # --sort-r
# Now randomly toggle off
toggle 13  # --trim OFF
toggle 25  # --sort OFF
toggle 8   # --claude OFF
toggle 21  # --upper OFF
toggle 20  # --lower (correct) OFF
toggle 26  # --sort-r OFF
toggle 15  # --strip-blank OFF
toggle 11  # --unwrap OFF
assert_sel_empty "All off after random removal"
# Now toggle a few back on
toggle 11  # --unwrap
toggle 13  # --trim
toggle 8   # --claude
assert_flags "Fresh selection after reset" "--unwrap --trim --claude"

# ──────────────────────────────────────────────
# TEST 7: Preset expansion
# ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}── Test 7: Preset expansion ──${RESET}"
: > "$SEL_FILE"
toggle 0   # Claude → Markdown preset
assert_flags "Preset expands" "--claude --unwrap"

# ──────────────────────────────────────────────
# TEST 8: Separator lines (should produce no flags)
# ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}── Test 8: Separator lines produce no flags ──${RESET}"
: > "$SEL_FILE"
toggle 7   # ───────── separator
assert_flags "Separator = no flags" ""

# ──────────────────────────────────────────────
# TEST 9: --md vs --md2csv vs --md2html matching
# ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}── Test 9: --md vs --md2csv vs --md2html ──${RESET}"
: > "$SEL_FILE"
toggle 9   # --md
assert_flags "--md alone" "--md"
: > "$SEL_FILE"
toggle 32  # --md2csv (correct)
assert_flags "--md2csv alone" "--md2csv"
: > "$SEL_FILE"
toggle 33  # --md2html
assert_flags "--md2html alone" "--md2html"
: > "$SEL_FILE"
toggle 9   # --md
toggle 32  # --md2csv (correct)
toggle 33  # --md2html
assert_flags "All three md variants" "--md --md2csv --md2html"

# ──────────────────────────────────────────────
# TEST 10: Generate output files for each format
# ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}── Test 10: Generate output files ──${RESET}"

# Claude → Markdown
: > "$SEL_FILE"
toggle 0
run_transform > "$OUTDIR/01-claude-to-markdown.md"
echo "  → $OUTDIR/01-claude-to-markdown.md"

# Claude → Rich HTML
: > "$SEL_FILE"
toggle 1
run_transform > "$OUTDIR/02-claude-to-rich.html"
echo "  → $OUTDIR/02-claude-to-rich.html"

# Claude → Excel
: > "$SEL_FILE"
toggle 2
run_transform > "$OUTDIR/03-claude-to-excel.tsv"
echo "  → $OUTDIR/03-claude-to-excel.tsv"

# --claude --unwrap --trim --dedup
: > "$SEL_FILE"
toggle 8   # --claude
toggle 11  # --unwrap
toggle 13  # --trim
toggle 17  # --dedup
run_transform > "$OUTDIR/04-claude-unwrap-trim-dedup.txt"
echo "  → $OUTDIR/04-claude-unwrap-trim-dedup.txt"

# --claude --unwrap --upper
: > "$SEL_FILE"
toggle 8
toggle 11
toggle 21  # --upper
run_transform > "$OUTDIR/05-claude-unwrap-upper.txt"
echo "  → $OUTDIR/05-claude-unwrap-upper.txt"

# --claude --unwrap --title
: > "$SEL_FILE"
toggle 8
toggle 11
toggle 22  # --title
run_transform > "$OUTDIR/06-claude-unwrap-title.txt"
echo "  → $OUTDIR/06-claude-unwrap-title.txt"

# --claude --unwrap --sentence
: > "$SEL_FILE"
toggle 8
toggle 11
toggle 23  # --sentence
run_transform > "$OUTDIR/07-claude-unwrap-sentence.txt"
echo "  → $OUTDIR/07-claude-unwrap-sentence.txt"

# --claude --unwrap --sort
: > "$SEL_FILE"
toggle 8
toggle 11
toggle 25  # --sort
run_transform > "$OUTDIR/08-claude-unwrap-sort.txt"
echo "  → $OUTDIR/08-claude-unwrap-sort.txt"

# Toggle order test: trim THEN claude (different from claude then trim)
: > "$SEL_FILE"
toggle 13  # --trim first
toggle 8   # --claude second
toggle 11  # --unwrap third
run_transform > "$OUTDIR/09-order-trim-claude-unwrap.txt"
echo "  → $OUTDIR/09-order-trim-claude-unwrap.txt"

# Opposite order: claude THEN trim
: > "$SEL_FILE"
toggle 8   # --claude first
toggle 11  # --unwrap second
toggle 13  # --trim third
run_transform > "$OUTDIR/10-order-claude-unwrap-trim.txt"
echo "  → $OUTDIR/10-order-claude-unwrap-trim.txt"

# Stress: toggle everything on, off randomly, back on selectively
: > "$SEL_FILE"
toggle 8; toggle 11; toggle 14; toggle 16; toggle 20; toggle 24
toggle 14; toggle 24; toggle 20  # off: trim, sort, lower
toggle 16  # off: strip-blank
# Remaining: claude(8), unwrap(11) in that order
run_transform > "$OUTDIR/11-stress-toggle.txt"
echo "  → $OUTDIR/11-stress-toggle.txt"

echo ""
echo "════════════════════════════════════════════════"
echo -e " Results: ${GREEN}${pass} passed${RESET}, ${RED}${fail} failed${RESET}"
echo " Output files: $OUTDIR/"
echo "════════════════════════════════════════════════"
ls -1 "$OUTDIR/"

exit $fail
