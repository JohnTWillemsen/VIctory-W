#!/usr/bin/env bash
# E095: exactly scoped public-source E094 overlay to the E045 six-PR reconstruction.
# Source gate only. Never copy private title data or run the game. Fail closed on drift/conflicts.
set -euo pipefail
[[ "$#" == 1 ]] || { echo "Usage: e095-e094-upstream-overlay.sh <ephemeral source checkout>" >&2; exit 95; }
cd "$1"
[[ -d .git ]] || { echo "E095 requires disposable Git source tree" >&2; exit 95; }
main=63bcca43c6a00a758510398fa43096ce7e4f7df0
[[ "$(git rev-parse "$main")" == "$main" ]] || exit 95
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for pair in \
  "3540:ee3d12dc356df92a2da49133f11a5f0c98b0291f" \
  "2634:a9eca1430a0b2a133ee5ebc4ec07062ae6c562ba" \
  "3392:72d5370455e3fcd95f9daf672daa03ff862d4293"; do
  n="${pair%%:*}"; want="${pair#*:}"
  ref="refs/remotes/origin/e095-$n"
  git fetch --quiet origin "refs/pull/$n/head:$ref"
  got="$(git rev-parse "$ref")"
  [[ "$got" == "$want" ]] || { echo "E095 MOVED upstream PR #$n; got $got expected $want" >&2; exit 95; }
done
for n in 2634 3540 3392; do
  ref="refs/remotes/origin/e095-$n"
  head="$(git rev-parse "$ref")"
  root="$(git merge-base "$main" "$head")"
  [[ -n "$root" ]] || { echo "E095 no merge base #$n" >&2; exit 95; }
  case "$n" in
    2634|3540) want="crates/victory-gpu/src/descriptor/host.rs" ;;
    3392) want="$(printf '%s\n' 'README.md' 'crates/victory-hle/src/modules/gameinput.rs')" ;;
  esac
  actual="$(git diff --name-only "$root" "$head")"
  [[ "$actual" == "$want" ]] || {
    echo "E095 unreviewed path set in #$n" >&2
    diff -u <(printf '%s\n' "$want") <(printf '%s\n' "$actual") || true
    exit 95
  }
  patch="$tmp/$n.patch"
  git diff --binary "$root" "$head" > "$patch"
  [[ -s "$patch" ]] || { echo "E095 empty PR #$n patch" >&2; exit 95; }
  if ! git apply --check "$patch"; then
    echo "E095 SOURCE_CONFLICT: PR #$n not directly compatible with E045 six-PR candidate." >&2
    echo "No --3way, no skipped hunks, no automatic source merge, no new title test." >&2
    exit 95
  fi
  git apply "$patch"
  git diff --check
  echo "E095 source patch #$n APPLY_PASS at $head"
done
grep -Fq 'fn copy_alignment(' crates/victory-gpu/src/descriptor/host.rs
grep -Fq 'static ONCE: std::sync::Once' crates/victory-gpu/src/descriptor/host.rs
grep -Fq 'fn active_script(' crates/victory-hle/src/modules/gameinput.rs
echo "E095 SOURCE_APPLIES: E045 six-PR + public source #2634 #3540 #3392, no GPU/title run"
