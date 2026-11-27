#!/usr/bin/env bash
# E-040: a source-only, fail-closed applicability check for #2464
# after pinned #439 + #2118 + #2098 + #2626. All operations are local to a
# disposable checkout; there is NO title material or external push.
set -euo pipefail

wave=e2d3cfd50715954fb89ff462edb37a0c4395ecd0
bvh=999a8f67125865fcc0b3aa23cdc8a93b10ef9974
addr=543d8688068b658ca4bf9602887097b215fec838
fmt=c8cc83e22702aa46dc1855c0f9df890fc5496238
raw=b9dc4b037a87bf6919ce92eae7c79a36c0307e48
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

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git -c core.autocrlf=false clone --quiet --no-tags https://github.com/Marvisak/VIctory.git "$work/source"
cd "$work/source"
git config core.autocrlf false
git config rerere.enabled false
git fetch --quiet origin \
  refs/pull/439/head:refs/remotes/origin/e040-439 \
  refs/pull/2118/head:refs/remotes/origin/e040-2118 \
  refs/pull/2098/head:refs/remotes/origin/e040-2098 \
  refs/pull/2626/head:refs/remotes/origin/e040-2626 \
  refs/pull/2464/head:refs/remotes/origin/e040-2464
for pair in \
  "refs/remotes/origin/e040-439:$wave" \
  "refs/remotes/origin/e040-2118:$bvh" \
  "refs/remotes/origin/e040-2098:$addr" \
  "refs/remotes/origin/e040-2626:$fmt" \
  "refs/remotes/origin/e040-2464:$raw"; do
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
echo "E-040 SOURCE-ONLY PASS: #2464 raw structured NVIDIA SRV patch applies after #439+#2118+#2098+#2626."
if [[ "${E041_WINDOWS_COMPILE:-0}" == "1" ]]; then
  echo "E-041 Windows hosted (NOT RTX5090): workspace, clippy, packed/BVH unit gates and release"
  cargo check --workspace --all-targets --locked
  cargo clippy --workspace --all-targets --locked -- -D warnings
  cargo test -p victory-gpu --lib --locked packed -- --test-threads=1 --nocapture
  cargo test -p victory-gpu --lib --locked an_acceleration_structures_view_address_is_its_location -- --test-threads=1 --nocapture
  cargo test -p victory-gpu --lib --locked builder -- --test-threads=1 --nocapture
  cargo build --release --locked -p victory
  echo "E-041 five-PR hosted Windows compile, clippy, focused tests and release completed."
  echo "No title, physical NVIDIA raw-structured behavior, persistent integration source, or public game data."
else
  echo "No compilation, native GPU test, game launch, persistent multi-PR code or push in E-040."
fi

# E-046: owner-only RTX5090 test gate for the FIVE-PR source, which was
# already hosted-Windows CI_PASS as E-043. This cannot auto-run in Actions.
# Always keep private logs on owner's machine; never write any title data.
if [[ "$(printenv E041_OWNER_GPU || true)" == "1" ]]; then
  [[ "$(printenv E041_WINDOWS_COMPILE || true)" == "1" ]] || {
    echo "Owner RTX5090 gate requires full E-041 build/test to be enabled." >&2
    exit 66
  }
  echo "E-046 OWNER five-PR native GPU tests start"
  echo "Pinned public sources: #439 e2d3cfd #2118 999a8f6 #2098 543d868 #2626 c8cc83e #2464 b9dc4b0"
  command -v nvidia-smi >/dev/null || { echo "nvidia-smi not installed; host adapter unverified" >&2; exit 67; }
  nvidia-smi
  echo "SOURCE_STATUS_BEGIN"
  git status --short
  echo "SOURCE_STATUS_END"
  cargo test -p victory-shader --lib --locked split_tests -- --test-threads=1 --nocapture
  cargo test -p victory-shader --lib --locked lane_read_loop_tests -- --test-threads=1 --nocapture
  echo "E-046 independent whole GPU lib suite starts; known capped-heap assertions may fail"
  set +e
  cargo test -p victory-gpu --lib --locked -- --test-threads=1 --nocapture
  gpu_exit=$?
  set -e
  echo "E-046 FULL_GPU_SUITE_EXIT=$gpu_exit (0 is full pass; nonzero is NOT full pass)"
  if [[ -f target/release/victory.exe ]]; then
    echo "E-046 PUBLIC-SOURCE RUNTIME SHA256: $(sha256sum target/release/victory.exe)"
  fi
  echo "E-046 NO TITLE RUN; no copyrighted file accessed"
  if [[ "$gpu_exit" -ne 0 ]]; then
    echo "E-046 completed with full-GPU failures; preserve names and report (do not hide)" >&2
    exit "$gpu_exit"
  fi
  echo "E-046 five-PR whole GPU lib suite PASS (verify shader output named NVIDIA RTX5090, not WARP)"
fi
