#!/usr/bin/env bash
# E-045: pinned six-PR public-source reconstruction with semantic reconciliation for #2628 portable descriptor clamp
# after pinned #439 + #2118 + #2098 + #2626 + #2464. All operations are local to a
# disposable checkout; there is NO title material or external push.
set -euo pipefail

wave=e2d3cfd50715954fb89ff462edb37a0c4395ecd0
bvh=999a8f67125865fcc0b3aa23cdc8a93b10ef9974
addr=543d8688068b658ca4bf9602887097b215fec838
# E-050: upstream #2626 advanced by one test-only commit (mip-1 packed copy).
# Compared c8cc83e...6092548; one path: list/packed_copy_tests.rs; no runtime edits.
fmt=6092548b147639bd5c46e896bcc0cc08fff71542
raw=b9dc4b037a87bf6919ce92eae7c79a36c0307e48
clamp=e2cdafe560fb6b601757a8ec921e352726e6662e
source_tree=9f8bb36f497fdfffd9d68f2f2b22b0284899ae10
pipeline=crates/victory-gpu/src/pipeline.rs
host=crates/victory-gpu/src/descriptor/host.rs

expected_paths="$(cat <<'PATHS'
crates/victory-gpu/src/bindless.rs
crates/victory-gpu/src/descriptor.rs
crates/victory-gpu/src/descriptor/host.rs
crates/victory-gpu/src/host.rs
crates/victory-gpu/src/list.rs
crates/victory-gpu/src/list/packed_copy_tests.rs
crates/victory-gpu/src/pipeline/host.rs
crates/victory-gpu/src/resource.rs
crates/victory-gpu/src/texture.rs
PATHS
)"

reconciler="$PWD/scripts/research/e045-reconcile-pr2628.py"
e049="$PWD/scripts/research/e049-guard-hostless-portable-probe.py"
e066="$PWD/scripts/research/e066-bvh-refusal-categories.sh"
e065="$PWD/scripts/research/e065-bucket-heap-warning.sh"
e081="$PWD/scripts/research/e081-wave64-lds-six-pr-gate.sh"
e074="$PWD/scripts/research/e074-bvh-shader-reasons.sh"
[[ -f "$reconciler" ]] || { echo "Missing reviewed E-045 reconciler" >&2; exit 40; }
[[ -f "$e049" ]] || { echo "Missing reviewed E-049 probe guard" >&2; exit 43; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git -c core.autocrlf=false clone --quiet --no-tags https://github.com/Marvisak/VIctory.git "$work/source"
cd "$work/source"
git config core.autocrlf false
git config rerere.enabled false
git fetch --quiet origin \
  refs/pull/439/head:refs/remotes/origin/e045-439 \
  refs/pull/2118/head:refs/remotes/origin/e045-2118 \
  refs/pull/2098/head:refs/remotes/origin/e045-2098 \
  refs/pull/2626/head:refs/remotes/origin/e045-2626 \
  refs/pull/2464/head:refs/remotes/origin/e045-2464 \
  refs/pull/2628/head:refs/remotes/origin/e045-2628
# E081-only: upstream PR #2118 advanced by exactly one warning-text commit
# 999a8f6 -> 78f36cf (draw.rs, 4 added/1 deleted, one diff hunk).
# Keep the previous tested six-PR runtime SHA exactly pinned for this experiment.
# Verify the live ref and precise expected harmless delta; fail closed on drift.
if [[ "${E081_WAVE64_LDS_GATE:-0}" == "1" ]]; then
  observed="$(git rev-parse refs/remotes/origin/e045-2118)"
  [[ "$observed" == '78f36cfa69211edbfa87d44e92ab93bd795f74a7' ]] || {
    echo "E081 unknown upstream #2118 head: $observed" >&2; exit 81;
  }
  [[ "$(git rev-list --count "$bvh..$observed")" == "1" ]] || {
    echo "E081 expected exactly one added #2118 commit" >&2; exit 81;
  }
  stat="$(git diff --numstat "$bvh" "$observed")"
  expected="$(printf '4\t1\tcrates/victory-gpu/src/draw.rs')"
  [[ "$stat" == "$expected" ]] || {
    echo "E081 unexpected #2118 changed paths or line count" >&2; exit 81;
  }
  [[ "$(git diff -U0 "$bvh" "$observed" -- crates/victory-gpu/src/draw.rs | grep -c '^@@')" == "1" ]] || {
    echo "E081 unexpected #2118 extra change hunk" >&2; exit 81;
  }
  git diff -U0 "$bvh" "$observed" -- crates/victory-gpu/src/draw.rs |
    grep -Fq 'see the `BVH builder held back` line' || {
      echo "E081 expected #2118 warning-text change absent" >&2; exit 81;
    }
  # Modify ONLY the disposable local tracking ref; never push or force a remote.
  git update-ref refs/remotes/origin/e045-2118 "$bvh" "$observed"
  echo "E081 #2118 warning-only advance verified; preserving immutable previous runtime."
fi
for pair in \
  "refs/remotes/origin/e045-439:$wave" \
  "refs/remotes/origin/e045-2118:$bvh" \
  "refs/remotes/origin/e045-2098:$addr" \
  "refs/remotes/origin/e045-2626:$fmt" \
  "refs/remotes/origin/e045-2464:$raw" \
  "refs/remotes/origin/e045-2628:$clamp"; do
  [[ "$(git rev-parse "${pair%%:*}")" == "${pair#*:}" ]] || {
    echo "Upstream ref changed: ${pair%%:*}; refusing mixed source" >&2
    exit 3
  }
done

# The same two-PR source and test-only API repair as E-034/E-037.
git checkout --quiet --detach "$wave"
git -c user.name=VIctory-W-CI -c user.email=ci@localhost.invalid merge --no-commit --no-ff "$bvh"
[[ "$(git write-tree)" == "$source_tree" ]] || {
  echo "Unexpected source index: $(git write-tree)" >&2
  exit 4
}
before="$(sha256sum "$pipeline" | cut -d' ' -f1)"
[[ "$before" == 'be8ca499438b8d89b869d58d0749171f62ce92f5860be2a3a788b5c08d0687af' ]] || {
  echo "Test-helper preimage hash mismatch: $before" >&2
  exit 5
}
sed -i 's/emit::emit(\&c, \&native, \&p, \&st, \&io, \&res)/emit::emit(\&c, \&native, \&p, \&st, \&io, \&res, emit::Target::ANY)/' "$pipeline"
after="$(sha256sum "$pipeline" | cut -d' ' -f1)"
[[ "$after" == '7f172a4d048fe74f8dbfa250f49db2fd5a816456a849cc824faa237b52b3cb73' ]] || {
  echo "Test-helper postimage hash mismatch: $after" >&2
  exit 5
}
git add "$pipeline"
git -c user.name=VIctory-W-CI -c user.email=ci@localhost.invalid commit --quiet --no-gpg-sign -m 'ephemeral #439 #2118 plus test API'

# Import the one-file public-source #2098 PR diff from its *merge base*,
# not an old target tip. Never choose ours/theirs/three-way fallbacks.
addr_base="$(git merge-base '63bcca43c6a00a758510398fa43096ce7e4f7df0' "$addr")"
[[ "$(git diff --name-only "$addr_base" "$addr")" == "$host" ]] || {
  echo "Unexpected #2098 changed-file set" >&2
  exit 6
}
git diff --binary "$addr_base" "$addr" -- "$host" > "$work/address.patch"
git apply --check --index "$work/address.patch" || { echo "#2098 source conflict; stopping" >&2; exit 7; }
git apply --index "$work/address.patch"
git diff --cached --check
git -c user.name=VIctory-W-CI -c user.email=ci@localhost.invalid commit --quiet --no-gpg-sign -m 'ephemeral reviewed #2098'

# #2626's nine-file patch is also computed from its true PR merge base.
fmt_base="$(git merge-base '63bcca43c6a00a758510398fa43096ce7e4f7df0' "$fmt")"
actual="$(git diff --name-only "$fmt_base" "$fmt")"
[[ "$actual" == "$expected_paths" ]] || {
  echo "Unexpected #2626 changed-file set; rejecting import" >&2
  diff -u <(printf '%s\n' "$expected_paths") <(printf '%s\n' "$actual") || true
  exit 8
}
echo "E-038 #2626 actual PR merge base: $fmt_base"
echo "E-038 verified all nine allowed #2626 source paths"
git diff --binary "$fmt_base" "$fmt" > "$work/packed-formats.patch"

if ! git apply --check --index "$work/packed-formats.patch"; then
  echo "E-038 blocked: #2626 has real textual/context conflicts with the three-PR source."
  echo "No three-way fallback, no conflict-side choice, no source commit, no game run."
  exit 9
fi
git apply --index "$work/packed-formats.patch"
git diff --cached --check
[[ "$(git diff --cached --name-only)" == "$expected_paths" ]] || {
  echo "Unexpected paths staged after applying #2626" >&2
  exit 10
}


# Clear staged #2626 from index before checking #2464's exact 2-file diff.
git -c user.name=VIctory-W-CI -c user.email=ci@localhost.invalid commit --quiet --no-gpg-sign -m 'ephemeral reviewed #2626'

raw_target=13f91caee25f2fdf2c062be5f7a27f058e51cbca
if ! git cat-file -e "${raw_target}^{commit}" 2>/dev/null; then
  git fetch --quiet origin "$raw_target"
fi
raw_base="$(git merge-base "$raw_target" "$raw")"
[[ -n "$raw_base" ]] || { echo "Raw SRV PR merge base unavailable" >&2; exit 11; }
raw_expected="$(printf '%s\n' 'crates/victory-gpu/src/descriptor/host.rs' 'crates/victory-gpu/src/host.rs')"
raw_actual="$(git diff --name-only "$raw_base" "$raw")"
[[ "$raw_actual" == "$raw_expected" ]] || {
  echo "E-040 rejected unexpected #2464 source paths:" >&2
  printf '%s\n' "$raw_actual" >&2
  exit 12
}
echo "E-040 #2464 actual merge base: $raw_base"
echo "E-040 only expected NVIDIA descriptor/host and host paths are changed"
git diff --binary "$raw_base" "$raw" > "$work/raw-structured.patch"
if ! git apply --check --index "$work/raw-structured.patch"; then
  echo "E-040 blocked on textual/context conflicts. No automatic resolution or guessing." >&2
  exit 13
fi
git apply --index "$work/raw-structured.patch"
git diff --cached --check
[[ "$(git diff --cached --name-only)" == "$raw_expected" ]] || {
  echo "E-040 staged file set differs unexpectedly" >&2
  exit 14
}

# Five source PRs stage successfully; clear the index before testing #2628.
git -c user.name=VIctory-W-CI -c user.email=ci@localhost.invalid commit --quiet --no-gpg-sign -m 'ephemeral reviewed #2464'

clamp_target=219878a0e7754511d89306331812971bb2153f5f
if ! git cat-file -e "${clamp_target}^{commit}" 2>/dev/null; then
  git fetch --quiet origin "$clamp_target"
fi
clamp_base="$(git merge-base "$clamp_target" "$clamp")"
[[ -n "$clamp_base" ]] || { echo "No #2628 PR merge base found" >&2; exit 20; }
expected_clamp="$(cat <<'PATHS'
apps/victory/src/translate.rs
crates/victory-gpu/src/descriptor/host.rs
crates/victory-gpu/src/draw.rs
crates/victory-gpu/src/memory.rs
crates/victory-gpu/src/shader_cache.rs
crates/victory-shader/src/emit/bitcode.rs
crates/victory-shader/src/emit/lower.rs
crates/victory-shader/src/emit/mod.rs
crates/victory-shader/src/emit/shader.rs
PATHS
)"
actual_clamp="$(git diff --name-only "$clamp_base" "$clamp")"
[[ "$actual_clamp" == "$expected_clamp" ]] || {
  echo "E-042 unexpected #2628 changed-file list; no patch action" >&2
  diff -u <(printf '%s\n' "$expected_clamp") <(printf '%s\n' "$actual_clamp") || true
  exit 21
}
echo "E-042 computed #2628 PR merge base: $clamp_base"
echo "E-042 nine pinned #2628 paths validated; inspecting textual applicability only."
git diff --binary "$clamp_base" "$clamp" > "$work/clamp.patch"


set +e
git apply --reject "$work/clamp.patch" > "$work/reject.log" 2>&1
rejected_exit=$?
set -e
[[ "$rejected_exit" -ne 0 ]] || {
  echo "E-045 expected source rejects disappeared; stop and review upstream." >&2
  exit 41
}
echo "E-045 partial git apply exit $rejected_exit (expected)"
grep -E 'Rejected hunk|with [0-9]+ reject|Applied patch|Hunk #[0-9]+ applied' "$work/reject.log" || true
python "$reconciler" "$PWD"
python "$e049" "$PWD"
if [[ "${E066_BVH_DIAG:-0}" == "1" ]]; then
  [[ -f "$e066" ]] || { echo "E-066 reviewed source patch missing" >&2; exit 66; }
  bash "$e066" "$PWD"
fi
if [[ "${E065_HEAP_WARN_DIAG:-0}" == "1" ]]; then
  [[ -f "$e065" ]] || { echo "E-065 reviewed source patch missing" >&2; exit 65; }
  bash "$e065" "$PWD"
fi
if [[ "${E074_BVH_REASON_DIAG:-0}" == "1" ]]; then
  [[ "${E066_BVH_DIAG:-0}" == "1" ]] || { echo "E-074 requires E-066 state classifier" >&2; exit 74; }
  [[ -f "$e074" ]] || { echo "E-074 review patch missing" >&2; exit 74; }
  bash "$e074" "$PWD"
fi
if [[ "${E081_WAVE64_LDS_GATE:-0}" == "1" ]]; then
  [[ -f "$e081" ]] || { echo "E081 source gate missing" >&2; exit 81; }
  bash "$e081" "$PWD"
fi
[[ "$(find apps crates -name '*.rej' -type f | wc -l)" -eq 0 ]] || {
  echo "E-045 an unhandled rejected hunk remains" >&2
  exit 42
}
git diff --check
echo "E-045 source reconciliation applied in disposable checkout only"
git status --short
for p in apps/victory/src/translate.rs crates/victory-gpu/src/shader_cache.rs crates/victory-shader/src/emit/mod.rs crates/victory-shader/src/emit/lower.rs; do
  echo "E-045 public-source SHA256 $(sha256sum "$p")"
done

if [[ "${E068_OWNER_BUILD:-0}" == "1" ]]; then
  # The owner has already completed physical GPU correctness tests of this
  # six-PR baseline; E-068 collects *diagnostics*, not another full suite.
  [[ "${E066_BVH_DIAG:-0}" == "1" && "${E065_HEAP_WARN_DIAG:-0}" == "1" ]] || {
    echo "E-068 owner build requires BOTH anonymous BVH and heap-logging patches" >&2; exit 68;
  }
  [[ -n "${E068_BINARY_DIR:-}" ]] || { echo "E-068 missing isolated binary directory" >&2; exit 68; }
  cargo build --release --locked -p victory
  mkdir -p "$E068_BINARY_DIR"
  cp -n target/release/victory.exe "$E068_BINARY_DIR/victory-six-pr-e068.exe"
  echo "E-068 anonymous diagnostic candidate source-generated release SHA256:"
  sha256sum "$E068_BINARY_DIR/victory-six-pr-e068.exe"
  echo "E-068 owner build PASS (title NOT RUN here; no title data read)."
elif [[ "$(printenv E045_WINDOWS_BUILD || true)" == "1" ]]; then
  echo "E-045 hosted Windows (NOT owner RTX5090): compiling and testing six-PR source"
  # The upstream pinned tree deliberately has pre-existing Rustfmt drift.
  # Formatting the ENTIRE checkout here changes unrelated unsafe blocks and
  # invalidates the exact-source comparison against the previously green E-043.
  # Keep the semantic source intact; git diff --check above checks the patch.
  cargo check --workspace --all-targets --locked
  cargo clippy --workspace --all-targets --locked -- -D warnings
  cargo test -p victory-shader --lib --locked heap_handles_clamp_to_the_selected_last_slot -- --test-threads=1 --nocapture
  cargo test -p victory-shader --lib --locked title_indices_past_the_portable_title_slots_read_the_null_view -- --test-threads=1 --nocapture
  cargo test -p victory-gpu --lib --locked packed -- --test-threads=1 --nocapture
  cargo test -p victory-gpu --lib --locked an_acceleration_structures_view_address_is_its_location -- --test-threads=1 --nocapture
  cargo test -p victory-gpu --lib --locked builder -- --test-threads=1 --nocapture
  cargo test -p victory-gpu --lib --locked portable -- --test-threads=1 --nocapture
  # E-049 hostless->host lifecycle regression is included in the portable filter above.
  # Previous hosted E-045 run had zero tests matched by the generic portable filter.
  # Explicitly exercise both original #2628 layout invariants, not just the new lifecycle test.
  cargo test -p victory-gpu --lib --locked the_probe_selects_the_heap_layout_before_translation -- --test-threads=1 --nocapture
  cargo test -p victory-gpu --lib --locked mirrored_and_dynamic_slots_end_before_the_shader_null_views -- --test-threads=1 --nocapture
  cargo test -p victory-gpu --lib --locked keys_tell_hosts_wave_sizes_apart -- --test-threads=1 --nocapture
  if [[ "${E066_BVH_DIAG:-0}" == "1" ]]; then
    cargo test -p victory-gpu --lib --locked e066_refusal_category_tests -- --test-threads=1 --nocapture
  fi
  if [[ "${E065_HEAP_WARN_DIAG:-0}" == "1" ]]; then
    cargo test -p victory-gpu --lib --locked e065_heap_warning_tests -- --test-threads=1 --nocapture
  fi
  if [[ "${E074_BVH_REASON_DIAG:-0}" == "1" ]]; then
    cargo test -p victory-gpu --lib --locked e074_ -- --test-threads=1 --nocapture
  fi
  if [[ "${E081_WAVE64_LDS_GATE:-0}" == "1" ]]; then
    cargo test -p victory-shader --lib --locked wave64_lds_ -- --test-threads=1 --nocapture
    cargo xtask policy
  fi
  cargo build --release --locked -p victory
  echo "E-045 SIX-PR HOSTED WINDOWS CHECK/CLIPPY/UNIT/RELEASE PASS (if reached)"
  echo "No full GPU suite, physical NVIDIA or title/game/visual scene tested."
else
  echo "E-045 source-only gate passed; Windows tests require separate gate."
fi
