# CURRENT STATE — live-verified session handoff (dated snapshot)

**Verified:** 2026-11-26, owner GPU reports through 21:23 UTC; GitHub/Marvisak PR metadata rechecked after the reports.
**Repository:** `JohnTWillemsen/VIctory-W`, **NOT** `JohnTWillemsen/victory-fork`.
**Status:** This file is part of [DRAFT PR #1](https://github.com/JohnTWillemsen/VIctory-W/pull/1), branch `docs/agent-continuity-system-20261126`. **It is not on `main` unless PR #1 is explicitly merged.** A new agent must read it at the PR branch, not assume `main` contains AGENTS.md or these documents.
**Truth order:** live GitHub refs/code → actual completed logs → owner-provided synthetic evidence → this dated handoff → upstream-reported results. Revalidate before changing files.

## Source control and active PRs

- `main` HEAD **`63bcca43c6a00a758510398fa43096ce7e4f7df0`**, matching `Marvisak/VIctory/main` at latest check. Keep this as the original baseline. Rust pinned to **1.98.1**; no runtime patches merged.
- [Draft PR #1](https://github.com/JohnTWillemsen/VIctory-W/pull/1): `docs/agent-continuity-system-20261126`, agent rules, records, restart tests, docs CI. Existing CI green at earlier `66bd928625631d45bef2f21ae5a88856a1f0a5fd`; **check latest head's CI after this update**. Do not merge without owner approval.
- [Draft PR #2](https://github.com/JohnTWillemsen/VIctory-W/pull/2): `research/descriptor-water-nvidia-20261126`, head `72c613c1cff2f4bd2dcda8aca19329b920835108`, research only. Its Windows CI run `45890754534` **failed one existing `frame::tests::waits_end_on_ticks_and_count_frames` timing assertion** (230 GPU tests passed, one failed, one ignored); no Rust changes in PR #2 and no proof of root cause.
- [Draft PR #3](https://github.com/JohnTWillemsen/VIctory-W/pull/3): `test/rtx5090-baseline-inventory-20261126`, head `ccf505a62b4ba84c9a9851170f52f25474baace3` as last verified; PowerShell inventory/synthetic collector plus [RTX 5090 evidence note](../research/rtx5090-baseline-collector.md). Earlier PR #3 head `235d68471cfe997828a16264554fd794ebb14f8e` [passed Windows CI](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45897940269); **do not attribute this to a newer head**. No title data or executable edits.

## Owner hardware baseline and synthetic results (not gameplay)

- Windows 11 Pro build `26200`, GeForce **RTX 5090 32 GB**, NVIDIA driver **617.42**, Rust/Cargo 1.98.1 MSVC toolchain. Inventory on original `main`: 0 staged / 0 tracked unstaged files; existing owner-built VIctory release exe checksum collected privately; ordinary PowerShell PATH did not expose `link.exe`, but Rust tests compiled successfully. No need to alter system execution policy beyond an owner-chosen temporary process scope.
- `main` synthetic: `cargo test -p victory-gpu --lib --locked descriptor -- --test-threads=1 --nocapture` **21 passed / 1 failed / 210 filtered**. Failure `descriptor::host::tests::dynamic_slots_are_held_until_released`: assumed GPU heap descriptors >= `HEAP_VIEWS`, false on this NVIDIA host. This is a **real test failure**, but the assertion can be an invalid cross-adapter assumption; not a proven in-game fault.
- `main` formatting check showed 925 rustfmt diff hunks / 66 files **in a clean checkout** (existing baseline formatting mismatch). Do NOT run auto-format on `main` as a blanket fix. `cargo xtask policy` passed (191 files).
- [Marvisak PR #3300](https://github.com/Marvisak/VIctory/pull/3300), pinned `01f91fea96de7c6fe47d5dd9f302e51a2403cac7`: owner fetched exactly that SHA to an **isolated detached worktree** with a separate Cargo target. Detailed native output: `cargo test -p victory-gpu --lib --locked descriptor::host::tests:: -- --test-threads=1 --nocapture` **16 passed / 0 failed / 217 filtered / exit 0**, including previously failing `dynamic_slots_are_held_until_released` and new `view_heap_allocation_scales_on_capped_hosts`. WARP forcing variable unset. **UNIT_PASS**, not gameplay or an independently confirmed renderer fix. Native logs remain private; summary is in EVIDENCE_LOG and PR #3.
- The original main and original release binary remain untouched. **NOT_RUN**: any title/gameplay visual comparison of these changes; no FPS, image-quality, crash or stability improvement established by these tests.

## Relevant upstream changes — precise last-known heads, MUST reverify

- [#3300 dynamic descriptor pool](https://github.com/Marvisak/VIctory/pull/3300): `01f91fea96de7c6fe47d5dd9f302e51a2403cac7`, **OPEN**, independently demonstrated host test above; dynamic-pool/title-slot tradeoff.
- [#2683 conservative shader view-index clamp](https://github.com/Marvisak/VIctory/pull/2683): `aecd60423c4673233104afaba1bde81f40d78a93`, **OPEN**; caps shader view heap indices to an NVIDIA-portable 1,000,000 and tests null-boundary behavior. Does not recover the title slots past that limit.
- [#2121 paged view heaps](https://github.com/Marvisak/VIctory/pull/2121): `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608`, **OPEN**; separate, more complex descriptor remapping; outstanding residency/first-submission/performance concerns even after multiple fixes.
- [#3244 host-aware descriptor tests](https://github.com/Marvisak/VIctory/pull/3244) and [#2937 capped-host test accommodations](https://github.com/Marvisak/VIctory/pull/2937): **OPEN** at last check, overlapping synthetic/test assertions. `NEW-24` in [upstream claims registry](https://github.com/Marvisak/VIctory/issues/1633) is claimed. Do not claim or duplicate an upstream implementation task.

## Immediate next action for a resumed session

1. **FIRST** read [AGENTS](../../AGENTS.md), this file, [NEW_SESSION_PROMPT](NEW_SESSION_PROMPT.md), [TASK_QUEUE](TASK_QUEUE.md), [EVIDENCE_LOG](EVIDENCE_LOG.md) on **PR #1's current branch**, and inspect live `main`, PRs #1–#3 and their exact-head CI. Check the current upstream #2683/#2121/#3300 heads, comments, and relevant files.
2. Owner has **already received** a PowerShell script that creates a detached `pr2683` test worktree, pins `aecd60423c4673233104afaba1bde81f40d78a93`, and executes `cargo test -p victory-gpu --lib --locked descriptor:: -- --test-threads=1 --nocapture` with native output through Tee-Object. **Report is NOT YET RECEIVED**; do not ask them to rerun before checking the next user message. If supplied, analyze and append evidence.
3. Then consider independent `#2121` synthetic tests in another detached worktree and target directory; **never stack #3300, #2683 and #2121 before individual evidence, conflicts and branch ancestry review**. Keep original release binary for eventual visual A/B. Hardware testing is via owner copy/paste commands and private logs/screenshots only.
4. Review whether this PR #1 and test PR #3 have fully completed CI **at their latest heads**, and update this snapshot, task queue, append-only evidence log and PR handoffs at substantive milestones. No merges or direct writes to `main` without explicit owner approval.

## What remains unknown

**NOT_RUN:** owner native title/gameplay run on a tested experimental build; correct scene geometry/water/lighting, stability and FPS. **UNKNOWN:** repository branch-protection enforcement and future upstream PR dispositions. Prior simulated restart CI is not evidence of a real autonomous agent surviving interruption. Keep proprietary title files and raw captures outside Git; local logs may contain user/machine paths and must not be uploaded unredacted.
