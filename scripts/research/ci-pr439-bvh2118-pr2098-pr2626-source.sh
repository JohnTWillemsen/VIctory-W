#!/usr/bin/env bash
# E-038: a source-only, fail-closed applicability check for #2626
# after pinned #439 + #2118 + #2098. All operations are local to a
# disposable checkout; there is NO title material or external push.
set -euo pipefail

wave=e2d3cfd50715954fb89ff462edb37a0c4395ecd0
bvh=999a8f67125865fcc0b3aa23cdc8a93b10ef9974
addr=543d8688068b658ca4bf9602887097b215fec838
fmt=c8cc83e22702aa46dc1855c0f9df890fc5496238
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
  refs/pull/439/head:refs/remotes/origin/e038-439 \
  refs/pull/2118/head:refs/remotes/origin/e038-2118 \
  refs/pull/2098/head:refs/remotes/origin/e038-2098 \
  refs/pull/2626/head:refs/remotes/origin/e038-2626
for pair in \
  "refs/remotes/origin/e038-439:$wave" \
  "refs/remotes/origin/e038-2118:$bvh" \
  "refs/remotes/origin/e038-2098:$addr" \
  "refs/remotes/origin/e038-2626:$fmt"; do
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

echo "E-038 source-only gate PASS: #2626 nine-file patch applies after #439+#2118+#2098."
echo "No Rust compile, GPU test, title execution, persistent integration commit or push."
