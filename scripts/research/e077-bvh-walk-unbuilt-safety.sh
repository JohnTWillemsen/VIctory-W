#!/usr/bin/env bash
# E-077: reproduce only the reviewed upstream #2311 *last commit* on the pinned
# E045 six-PR source. This adds BVH walker holdback to protect an unbuilt
# acceleration structure, not shader translation, BVH construction or rendering.
# Public code only, disposable source tree; refuse conflicts, no 3-way fallbacks.
set -euo pipefail
[[ "$#" == 1 ]] || { echo "usage: e077-bvh-walk-unbuilt-safety.sh <disposable-source-worktree>" >&2; exit 77; }
cd "$1"
[[ -f Cargo.lock && -f crates/victory-gpu/src/pipeline/builder.rs ]] ||
    { echo "E-077 wrong source worktree" >&2; exit 77; }
upstream="481a9aec8eaf9938fe8ce8ae9451b78cfd6b0920"
parent="60632d3f0fcb9e916a2ad22be300e5f71c4a2b49"
if ! git cat-file -e "$upstream^{commit}" 2>/dev/null; then
    git fetch --quiet origin "$upstream"
fi
[[ "$(git rev-parse "$upstream")" == "$upstream" ]] ||
    { echo "E-077 upstream source changed" >&2; exit 77; }
[[ "$(git rev-parse "$upstream^")" == "$parent" ]] ||
    { echo "E-077 reviewed parent does not match" >&2; exit 77; }
expect="$(printf '%s\n' 'crates/victory-gpu/src/draw.rs' 'crates/victory-gpu/src/pipeline.rs' 'crates/victory-gpu/src/pipeline/builder.rs')"
actual="$(git diff --name-only "$parent" "$upstream")"
[[ "$actual" == "$expect" ]] || {
    echo "E-077 unexpected upstream changed file list" >&2
    diff -u <(printf '%s\n' "$expect") <(printf '%s\n' "$actual") || true
    exit 77
}
patch="$(mktemp)"
trap 'rm -f "$patch"' EXIT
git diff --binary "$parent" "$upstream" > "$patch"
git apply --check "$patch" || {
    echo "E-077 upstream #2311 final commit does not cleanly apply to pinned six-PR source."
    echo "Failing closed; no conflict-side selection, no title/game execution."
    exit 77
}
git apply "$patch"
git diff --check
grep -Fq 'walks_bvh' crates/victory-gpu/src/pipeline.rs ||
    { echo "E-077 missing BVH walker identifier" >&2; exit 77; }
grep -Fq 'builder::built()' crates/victory-gpu/src/pipeline.rs ||
    { echo "E-077 missing builder-built interlock" >&2; exit 77; }
grep -Fq 'walks_wait_for_the_builder_to_run_whole' crates/victory-gpu/src/pipeline.rs ||
    { echo "E-077 missing upstream test" >&2; exit 77; }
echo "E-077 pinned #2311 last commit applied to disposable source, exact 3-file path scope."
echo "E-077 BVH builder all-made safety still active; no forced translation or BVH execution."
