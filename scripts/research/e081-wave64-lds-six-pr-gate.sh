#!/usr/bin/env bash
# E081 source-only applicability gate: upstream #3406 on exact six-PR reconstruction.
# Never uses --3way/ours/theirs, never enables an unsafe Wave64 approximation.
# No game files, title execution or Nvidia claims.
set -euo pipefail
[[ "$#" == 1 ]] || { echo "usage: e081-wave64-lds-six-pr-gate.sh <disposable-public-source-root>" >&2; exit 81; }
source_root="$(cd "$1" && pwd -P)"
cd "$source_root"
[[ -d .git ]] || { echo "E081 requires disposable git source tree" >&2; exit 81; }
want=174e8d9b76eddc247a2c6c00a1743b4812e4af62
main=63bcca43c6a00a758510398fa43096ce7e4f7df0
ref=refs/remotes/origin/e081-3406
git fetch --quiet origin refs/pull/3406/head:"$ref"
got="$(git rev-parse "$ref")"
[[ "$got" == "$want" ]] || {
  echo "E081 FAIL_CLOSED: upstream #3406 moved; got $got expected $want" >&2
  exit 81
}
git cat-file -e "$main^{commit}" || { echo "E081 pinned main unavailable" >&2; exit 81; }
base="$(git merge-base "$main" "$want")"
[[ -n "$base" ]] || { echo "E081 upstream merge base unavailable" >&2; exit 81; }
expected="$(printf '%s\n' \
  crates/victory-shader/src/emit/lower.rs \
  crates/victory-shader/src/emit/wave64_lds.rs \
  crates/victory-shader/src/emit/wave64_lds_tests.rs)"
actual="$(git diff --name-only "$base" "$want")"
if [[ "$actual" != "$expected" ]]; then
  echo "E081 FAIL_CLOSED: expected exactly three upstream #3406 files" >&2
  diff -u <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") || true
  exit 81
fi
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
git diff --binary "$base" "$want" -- \
  crates/victory-shader/src/emit/lower.rs \
  crates/victory-shader/src/emit/wave64_lds.rs \
  crates/victory-shader/src/emit/wave64_lds_tests.rs > "$tmp"
[[ -s "$tmp" ]] || { echo "E081 empty upstream patch; stop" >&2; exit 81; }
if ! git apply --check "$tmp"; then
  echo "E081 SOURCE_CONFLICT: pinned #3406 patch does not apply cleanly to six-PR stack." >&2
  echo "E081 intentional refusal: do not use --3way, unsafe ours/theirs or partial patch." >&2
  exit 81
fi
git apply "$tmp"
git diff --check
[[ -f crates/victory-shader/src/emit/wave64_lds.rs ]] || exit 81
[[ -f crates/victory-shader/src/emit/wave64_lds_tests.rs ]] || exit 81
grep -Fq 'can_sync_wave64_lds' crates/victory-shader/src/emit/lower.rs
grep -Fq 'lds_wave32_sync' crates/victory-shader/src/emit/lower.rs
grep -Fq 'wave64_lds_64_threads_divergent_branch_keeps_wave_size_64' crates/victory-shader/src/emit/wave64_lds_tests.rs
grep -Fq 'wave64_lds_64_threads_guarded_keeps_wave_size_64' crates/victory-shader/src/emit/wave64_lds_tests.rs
echo "E081 SOURCE_APPLIES: exact #3406 public patch; <=64 LDS only, negative guards present."
echo "E081 no GPU/title, no shader or gameplay success claim. Run hosted Windows tests."
