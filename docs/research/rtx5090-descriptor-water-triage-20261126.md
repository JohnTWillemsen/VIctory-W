# Descriptor-data and NVIDIA heap triage — 2026-11-26

**Scope:** read-only upstream code review and an owner-executed RTX 5090 comparison plan. This is not a runtime fix, shader import, game test, or upstream claim.

**Fork baseline:** `JohnTWillemsen/VIctory-W` `main` at `63bcca43c6a00a758510398fa43096ce7e4f7df0`; `Marvisak/VIctory` `main` at the same SHA when checked. The fork's separate agent-continuity draft PR #1 is open and unmerged. Treat all refs below as **dated**: requery their heads and CI before testing. No proprietary title content, shaders, logs, captures or personal paths belong in this repository.

## 1. Decision: do not duplicate the water-compute lowering

The published offline shader census in [upstream coordination #1633](https://github.com/Marvisak/VIctory/issues/1633) reports a single remaining descriptor-only compute refusal on main. However, an older, still-open implementation exists:

- [#329 — Recover record counts for descriptor-only structured buffers](https://github.com/Marvisak/VIctory/pull/329), author Raxstreams, head `02564c5d9561021eb6cfba01e91b1898192a60ac`, base `d2a4bae1f49533ef5cb512fd1b1ba1513f2e1989`. Source patch reviewed: `emit/lower.rs`, `emit/mod.rs`, `emit/valu_tests.rs`. It handles a **static, exact-offset, four-dword structured SRV/UAV** with native stride and PSV0 declaration corroboration. It adds a synthetic 3-vs-11-record GPU readback test with a conflicting declaration control. The author reports that an isolated compute pipeline validated on RTX 3080 Ti; another tester measured a single additional in-game shader translating. **Not in main; automated triage reported it needs rebase**. A solution to the singleton may be this contribution, not new work here.
- [#2363 — Descriptor dwords read as data](https://github.com/Marvisak/VIctory/pull/2363), author Calvix2k, head `77d9aab26e12e8c71e56b7a65b525735fedea712`. A broader view-address/metadata path. Its PR discussion contains an independent RTX 5090 **Linux/Wine/vkd3d-proton** title report of the water-compute shader executing, but this does **not** establish Windows/D3D12 or this fork's success. Reviewers also found API descriptor-layout mistakes in earlier heads, so examine latest tests/commits before trusting this implementation.

**Coordination:** do not post a new claim for implementing the singleton while #329/#2363 exist. Consider narrow review, rebase assistance with the author's consent, or independent current-head verification. The upstream coordination rules prohibit game-derived data and title shader names/hashes in comments.

## 2. NVIDIA heap candidates (compare, do not stack)

| Candidate | Verified PR head | What it addresses | What it does not prove |
| --- | --- | --- | --- |
| [#2683](https://github.com/Marvisak/VIctory/pull/2683), pes7 | `aecd60423c4673233104afaba1bde81f40d78a93` | Current rebased head, 1,000,000 clamp + null-view reservation; two boundary layout tests; owner pinned Windows test **24/24 selected descriptor cases passed**, exit 0. | Does not map title slots omitted by a capped host heap; not a world-rendering fix. PR base was `13f91caee25f2fdf2c062be5f7a27f058e51cbca`, so check current rebase/mergeability. |
| [#2121](https://github.com/Marvisak/VIctory/pull/2121), 0xkn0wh3r3 | `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608` | Page virtual view indices into a finite host heap, with reclamation and restoration tests. | Mapping correctness through eviction, pressure and placed-texture reloads is delicate. Review newest comments and author follow-ups before a title test. |

**Latest unresolved author-side follow-ups (checked 2026-11-26):** [#2121 author's fork PR #12](https://github.com/0xkn0wh3r3/VIctory/pull/12), head `c8dbf8401326f4da0eeb7ea0a476030d86b10019`, isolates a flaky no-free-page test from unrelated submissions. [Author fork PR #13](https://github.com/0xkn0wh3r3/VIctory/pull/13), head `ba6e876944e14260fd5522f96b85b05aa0c1baad`, is stacked on #12 and addresses stale buffer strides on evicted/scratch pages: an incorrect buffer handle can otherwise point at a null texture descriptor. These were **not established as incorporated in #2121 head `0bc5edbd`**. Both are author-owned changes with synthetic reports; do not copy them into VIctory-W as competing fixes, and recheck #2121 before testing.

The two PRs overlap `descriptor/host.rs` and translated heap-index semantics. They are separate candidate states, **not** a naive sequence to cherry-pick together. Keep the clean baseline available for control runs. The public [NVIDIA cap report #1760](https://github.com/Marvisak/VIctory/issues/1760) documents a title heap of 1,245,184 views against a reported 1,000,000-view NVIDIA limit; the old capped path leaves 310,720 title slots without a 1:1 mapping. These are upstream reports, **not** measurements on the owner's RTX 5090.

## 3. Source-only gates

For each candidate, first verify current `main`, PR head, changed files, reviews and overlapping PRs. Work in a **separate Git worktree** from the exact PR head, using a distinct short `CARGO_TARGET_DIR`. Do not rewrite `main` or mix experimental heads. The exact Cargo suite depends on the branch, but the following are safe *source checks* on the owner's Windows machine once the required MSVC toolchain is available:

```powershell
git rev-parse HEAD
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --locked
cargo xtask policy
cargo build --release -p victory --locked
```

For #2683 specifically, inspect the tests covering `the_capped_layout_and_the_small_range_fit_the_clamp_shaders_use` and `a_heap_has_every_slot_shaders_clamp_to`. The latter can skip when no GPU is found: count actual executed cases, not only pass results. For #2121, prioritize synthetic GPU tests for no-room paging, A→B→A slot reuse, reused placed textures, buffer descriptor restoration and null-view reads. The author and reviewers have already tested several; rerun against the **current head**, not the earlier failing `c23f7085`/ `fedb38db` revisions.

**Current evidence here:** `CODE_REVIEWED` for inspected PR patches. **Owner `UNIT_PASS` on upstream #2683**, exact `aecd60423c4673233104afaba1bde81f40d78a93`: `cargo test -p victory-gpu --lib --locked descriptor:: -- --test-threads=1 --nocapture` **24 passed, 0 failed, 0 ignored, 210 filtered, exit 0** in a separately pinned Windows worktree on the owner's RTX 5090 machine. Includes `dynamic_slots_are_held_until_released` (failed on original main) and the two clamp boundary checks; the filter differs from original main's 21 pass/1 fail and #3300's narrower 16 pass. Raw log remains private; [continuity E-015](https://github.com/JohnTWillemsen/VIctory-W/blob/docs/agent-continuity-system-20261126/docs/agents/EVIDENCE_LOG.md). **No #2121 owner tests, no title visual/FPS A/B, no verified gameplay improvement**. Third-party GPU claims for #2121/#12/#13 remain `UPSTREAM_REPORTED`.

## 4. Owner-executed RTX 5090 A/B

Use three isolated, unmodified candidate heads: (A) fork/upstream `main`, (B) #2683, (C) #2121. Optionally add #2363 on a separate tree once its latest tests and dependencies have been reviewed. Do not combine candidates until individually verified.

1. Record exact source SHA, built binary SHA-256, Windows build, NVIDIA driver, GPU model, toolchain, diagnostic flags and whether the pipeline cache is cold/warm. Keep game files and all caches **outside the Git checkout**. For each candidate use its own non-overlapping cache and build-output folder.
2. Perform one controlled menu/transition/world sequence on the clean baseline, then replicate the **same** input/scene, resolution, console setting and cache condition for the candidates. Use the title only under owner control.
3. For heap safety, look for `host view heap capped`, `title slot past the host heap`, `no room for the null buffer views`, D3D12 debug validation, DRED/device removal and failed command submissions. No warning is not proof of correctly rendered geometry.
4. For #2121 additionally record `host view heap pages in use`, `view heap pages unused lately taken back`, `view heap pages placed again`, `no room left in the host view heap` and `view heap pages written with no room left`. They may be reported as **cumulative counters at thresholds**: compare the latest/highest count, do not add log lines together.
5. Examine the actual resulting picture, including geometry, water, depth, textures and transient black frames; compare dropped/refused shaders and GPU faults. Repeat the stable scene before comparing frame times. Prefer correctness over apparent FPS.
6. Share only redacted counts and normalized observations publicly; raw logs, captures, dump fragments, shader names/hashes from the title and file paths remain private.

**Pass criteria:** Source tests execute at their claimed tier; the branch does not regress existing synthetic controls; native 5090 tests show no out-of-heap descriptor reads/device removal; *and* visual results show no newly missing graphics. CI by itself proves none of those hardware conditions.

## 5. Next action and ownership

- **Our fork:** retain draft PR #1 and unchanged `main`. Treat this note as a dated investigation, not approval to merge code.
- **Upstream water work:** review #329's current rebasing state and #2363's metadata corrections; offer useful verification rather than a competing implementation.
- **Upstream NVIDIA work:** #2683 selected descriptor tests are completed on the owner machine (24/24; E-015), so **do not request that same test again**. Next, pin #2121 head independently and test paging eviction/reclamation plus shader null-view buffer semantics, knowing that separate open #12/#13 identify potential gaps at that head. Never stack #3300/#2683/#2121 by default. Feed back only reproducible, de-identified findings to existing authors.
- **Rollback:** remove this research branch/PR if superseded; it modifies no executable behavior.

References: [coordination #1633](https://github.com/Marvisak/VIctory/issues/1633), [heap issue #1760](https://github.com/Marvisak/VIctory/issues/1760), PRs [#329](https://github.com/Marvisak/VIctory/pull/329), [#2363](https://github.com/Marvisak/VIctory/pull/2363), [#2683](https://github.com/Marvisak/VIctory/pull/2683), [#2121](https://github.com/Marvisak/VIctory/pull/2121).

## 6. 2026-11-26 follow-up: why #2121 needs a guarded-read gate

`CODE_REVIEWED` at upstream #2121 `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608` and author follow-up #13 `ba6e876944e14260fd5522f96b85b05aa0c1baad` (open, distinct branch). In `descriptor/host.rs`, a page eviction or scratch-page fallback can leave the view-stride table recording a buffer stride while the physical page table points at null **texture** views. `Lower::buffer_guard` may redirect an unsafe buffer read to the null buffer handle, but `Shader::heap_handle` must still mark the **original requested virtual page**, not the null handle's page, to permit recovery. #13 changes the stride installation/clearing and marks the requested page. Third-party reports three synthetic before/after regression cases on RTX 5090/WARP; **not our measurements**. [Original patch](https://github.com/0xkn0wh3r3/VIctory/pull/13), [test-fixture hardening #12](https://github.com/0xkn0wh3r3/VIctory/pull/12).

For an independent **unmodified #2121** trial, choose exact test filters rather than a broad overlapping run: `descriptor::pages::tests::` (paging allocation/eviction), `host::tests::view_heap_pages_taken_back_make_their_buffer_views_again` (stride and regeneration), `host::tests::view_heap_slots_written_with_no_room_are_made_when_their_page_is_placed`, `draw::tests::a_placed_texture_read_with_no_page_free_is_made_after_one_submission` (known fixture race on #2121), and `emit::stride_tests::views_read_in_a_paged_view_heap_mark_their_pages`. Run in a fresh, SHA-pinned detached worktree and distinct Cargo target; preserve exact native stdout/stderr and explicit exit codes. On NVIDIA paging is automatic when host cap is insufficient; for WARP the GPU crate's `VICTORY_D3D12_WARP=1` requires `diagnostics` feature and `VICTORY_VIEW_PAGES=1` to force paging. Never record a test that returned early as if it exercised paging. The first owner test should be source-only/no title files. No `main` merge or upstream submission is authorized by this note.

CI boundary: [research PR #2 CI run 45890754534](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45890754534) at its old head failed an existing frame-wait timing assertion; this docs-only revision does not claim to fix the failure. CI must be checked at the new exact head.
