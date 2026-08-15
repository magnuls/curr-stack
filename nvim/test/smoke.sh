#!/usr/bin/env bash
# Smoke test for this Neovim config. Builds a polyglot fixture, drives nvim
# against it, prints a pass/fail table, exits non-zero if anything failed.
#
#   ./test/smoke.sh              run everything
#   ./test/smoke.sh core cpp     run only the named probes
#   KEEP=1 ./test/smoke.sh       leave the fixture behind for poking at
#
# Probes are split in two, because some features cannot be tested headlessly:
#   headless : core cpp python format
#   pty      : ui debug        (cmp draws a float, lazygit needs a terminal,
#                               codelldb needs a real tty)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SMOKE_LUA="$HERE/lua"
# Under $HOME deliberately, not $TMPDIR: clang-format finds ~/.clang-format by
# walking up parent directories, so a fixture outside $HOME silently gets LLVM
# defaults (2-space) instead of the configured 4-space style. Testing there
# would exercise a different chain than real use.
mkdir -p "$HOME/.cache"
WORK="$(mktemp -d "$HOME/.cache/nvim-smoke.XXXXXX")"
export SMOKE_FIXTURE="$WORK/testbed"
RESULTS="$WORK/results"
mkdir -p "$RESULTS"

HEADLESS_PROBES=(core cpp python format)
PTY_PROBES=(ui debug)
WANT=("$@")

want() {
  [ ${#WANT[@]} -eq 0 ] && return 0
  for w in "${WANT[@]}"; do [ "$w" = "$1" ] && return 0; done
  return 1
}

cleanup() {
  if [ "${KEEP:-0}" = "1" ]; then
    echo "fixture kept at $WORK"
  else
    rm -rf "$WORK"
  fi
}
trap cleanup EXIT

bold() { printf '\033[1m%s\033[0m\n' "$1"; }

bold "building fixture..."
"$HERE/fixture.sh" "$SMOKE_FIXTURE" >/dev/null || { echo "fixture build FAILED"; exit 1; }

run_probe() {
  local name="$1" mode="$2"
  export SMOKE_OUT="$RESULTS/$name.tsv"
  : > "$SMOKE_OUT"
  printf '  %-8s (%s) ... ' "$name" "$mode"

  local script="$SMOKE_LUA/$name.lua"
  # nvim must run FROM the fixture: the file tree, lazygit and LSP root
  # detection all key off cwd, not off the paths the probe happens to open.
  if [ "$mode" = pty ]; then
    # `script` gives nvim a real pty so a UI attaches. stdin is held open by
    # `sleep`, otherwise nvim sees EOF and quits before the probe runs.
    ( cd "$SMOKE_FIXTURE" && sleep 180 | TERM=xterm-256color script -q /dev/null \
        nvim --cmd "set noswapfile" -c "luafile $script" >/dev/null 2>&1 ) &
    local pid=$!
    local waited=0
    while kill -0 $pid 2>/dev/null && [ $waited -lt 175 ]; do sleep 1; waited=$((waited+1)); done
    kill -0 $pid 2>/dev/null && { pkill -f "luafile $script" 2>/dev/null; sleep 1; }
    pkill lazygit 2>/dev/null
  else
    ( cd "$SMOKE_FIXTURE" && nvim --headless --cmd "set noswapfile" -c "luafile $script" >/dev/null 2>&1 )
  fi

  local n
  n=$(wc -l < "$SMOKE_OUT" | tr -d ' ')
  echo "$n checks"
}

bold "running probes..."
for p in "${HEADLESS_PROBES[@]}"; do want "$p" && run_probe "$p" headless; done
for p in "${PTY_PROBES[@]}";      do want "$p" && run_probe "$p" pty;      done

echo
bold "results"
pass=0; fail=0; skip=0
for f in "$RESULTS"/*.tsv; do
  [ -s "$f" ] || continue
  probe="$(basename "$f" .tsv)"
  printf '\n\033[1m[%s]\033[0m\n' "$probe"
  while IFS=$'\t' read -r status name detail; do
    case "$status" in
      PASS) pass=$((pass+1)); printf '  \033[32m✓\033[0m %s\n' "$name" ;;
      FAIL) fail=$((fail+1)); printf '  \033[31m✗ %s\033[0m\n      %s\n' "$name" "$detail" ;;
      SKIP) skip=$((skip+1)); printf '  \033[33m–\033[0m %s  (%s)\n' "$name" "$detail" ;;
      NOTE) printf '    \033[90m· %s\033[0m\n' "$name" ;;
    esac
  done < "$f"
done

# A probe that produced no output crashed before writing anything.
for p in "${HEADLESS_PROBES[@]}" "${PTY_PROBES[@]}"; do
  want "$p" || continue
  if [ ! -s "$RESULTS/$p.tsv" ]; then
    fail=$((fail+1))
    printf '\n  \033[31m✗ probe %s produced no results (crashed or timed out)\033[0m\n' "$p"
  fi
done

echo
bold "$pass passed, $fail failed, $skip skipped"
[ "$fail" -eq 0 ]
