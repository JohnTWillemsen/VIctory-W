#!/usr/bin/env bash
# E-037: ephemeral public-source-only Windows CI gate for #439 + #2118 + #2098.
# No title material; no writes to the checked-out fork, GitHub remote or main.
set -euo pipefail

wave='e2d3cfd50715954fb89ff462edb37a0c4395ecd0'
bvh='999a8f67125865fcc0b3aa23cdc8a93b10ef9974'
address='543d8688068b658ca4bf9602887097b215fec838'
address_base='219878a0e7754511d89306331812971bb2153f5f'
expected_tree='9f8bb36f497fdfffd9d68f2f2b22b0284899ae10'
expected_before='be8ca499438b8d89b869d58d0749171f62ce92f5860be2a3a788b5c08d0687af'
expected_after='7f172a4d048fe74f8dbfa250f49db2fd5a816456a849cc824faa237b52b3cb73'
pipeline='crates/victory-gpu/src/pipeline.rs'
host='crates/victory-gpu/src/descriptor/host.rs'

for tool in git sha256sum sed cargo; do
  command -v "$tool" >/dev/null || { echo "Missing command: $tool" >&2; exit 2; }
done

work="$(mktemp -d)"
trap 'cd /; rm -rf "$work"' EXIT
echo "E-037 experimental workspace created; ephemeral and outside the fork"
git -c core.autocrlf=false clone -q --no-tags https://github.com/Marvisak/VIctory.git "$work/source"
cd "$work/source"
git config core.autocrlf false
git config rerere.enabled false

# GitHub's pull refs are fetched explicitly; no reliance on mutable upstream main.
git fetch -q origin \
  refs/pull/439/head:refs/remotes/origin/e037-439 \
  refs/pull/2118/head:refs/remotes/origin/e037-2118 \
  refs/pull/2098/head:refs/remotes/origin/e037-2098
for entry in \
  "refs/remotes/origin/e037-439:$wave" \
  "refs/remotes/origin/e037-2118:$bvh" \
  "refs/remotes/origin/e037-2098:$address"; do
  ref="${entry%%:*}"
  expected="${entry#*:}"
  got="$(git rev-parse "$ref")"
  [[ "$got" == "$expected" ]] || { echo "Unexpected upstream move: $ref $got" >&2; exit 3; }
done
if ! git cat-file -e "${address_base}^{commit}" 2>/dev/null; then
  git fetch -q origin "$address_base"
fi
git cat-file -e "${address_base}^{commit}" || { echo "PR2098 base not found" >&2; exit 3; }

git checkout -q --detach "$wave"
git -c user.name='VIctory-W CI' -c user.email='ci@localhost.invalid' \
  merge --no-commit --no-ff "$bvh"
tree="$(git write-tree)"
[[ "$tree" == "$expected_tree" ]] || {
  echo "Unexpected #439+#2118 Git tree: $tree" >&2
  exit 4
}
echo "Combined pinned source tree: $tree"

# Repair only the known #2118 test-helper call for #439's 7-parameter emit API.
before="$(sha256sum "$pipeline" | cut -d' ' -f1)"
[[ "$before" == "$expected_before" ]] || { echo "Unexpected test helper preimage: $before" >&2; exit 5; }
sed -i 's/emit::emit(\&c, \&native, \&p, \&st, \&io, \&res)/emit::emit(\&c, \&native, \&p, \&st, \&io, \&res, emit::Target::ANY)/' "$pipeline"
after="$(sha256sum "$pipeline" | cut -d' ' -f1)"
[[ "$after" == "$expected_after" ]] || { echo "Unexpected test-helper result: $after" >&2; exit 5; }
git add "$pipeline"
git -c user.name='VIctory-W CI' -c user.email='ci@localhost.invalid' \
  commit -q --no-gpg-sign -m 'temporary pinned #439 + #2118 test-only API reconciliation'
echo "Local-only integration commit: $(git rev-parse HEAD) (never pushed)"

# The *specific PR diff* is applied, not a merge of its older divergent base.
# GitHub PR diffs are three-dot: compare against the branch merge-base, NOT
# the current target branch tip, which can have unrelated newer changes.
pr_base="$(git merge-base "$address_base" "$address")"
[[ -n "$pr_base" ]] || { echo "PR2098 merge base missing" >&2; exit 6; }
echo "PR2098 three-dot merge base: $pr_base"
changed="$(git diff --name-only "$pr_base" "$address")"
[[ "$changed" == "$host" ]] || {
  echo "PR2098 no longer changes exactly the expected file: $changed" >&2
  exit 6
}
if git grep -q 'fn view_address(' -- "$host"; then
  echo "Candidate already implemented in combined source; abort duplicate import" >&2
  exit 6
fi
git diff --binary "$pr_base" "$address" -- "$host" > "$work/pr2098-public-source.patch"
git apply --check --index "$work/pr2098-public-source.patch" || {
  echo "PR2098 patch needs manual semantic resolution; no ours/theirs fallback" >&2
  exit 7
}
git apply --index "$work/pr2098-public-source.patch"
git diff --cached --check
echo "Applied only the reviewed #2098 single-file source patch in ephemeral CI"

# Windows hosted tests are NOT physical RTX 5090 or actual title tests.
cargo check --workspace --all-targets --locked
cargo test -p victory-gpu --lib --locked \
  an_acceleration_structures_view_address_is_its_location -- --test-threads=1 --nocapture
cargo test -p victory-gpu --lib --locked builder -- --test-threads=1 --nocapture
cargo build --release --locked -p victory
echo "E-037 source + Windows hosted build gates completed. No gameplay claims."
