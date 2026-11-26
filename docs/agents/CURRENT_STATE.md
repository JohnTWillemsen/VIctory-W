# CURRENT STATE — verified handoff, not a living GitHub API

**Last source verification:** 2026-11-26 (America/Phoenix; some GitHub times UTC).
**Scope:** New source-clean fork `JohnTWillemsen/VIctory-W` only.
**Evidence classification:** `SOURCE_READ` (GitHub refs and checked files); `CI_PASS` (the explicitly pinned, previously checked documentation head); `NOT_RUN` (this fork's user hardware gameplay).

## Verified foundation at this snapshot

- New fork: https://github.com/JohnTWillemsen/VIctory-W ; default branch: `main`.
- **Fork's original `main` baseline:** `63bcca43c6a00a758510398fa43096ce7e4f7df0`. Matched Marvisak's `main` when inspected on 2026-11-26. **Re-read both live heads before acting; they may have moved.**
- Primary upstream: https://github.com/Marvisak/VIctory ; other research source: https://github.com/fxceless/victory-fork .
- Baseline source files inspected: `README.md`, `.github/workflows/ci.yml`, `docs/architecture.md`, `docs/asset-policy.md`, `rust-toolchain.toml`, `Cargo.toml`, `.gitignore` and `xtask/src/policy.rs`.
- Pinned Rust toolchain at original baseline: **1.98.1**, MSVC Windows target; do not silently upgrade.
- GitHub Issues are **disabled** on this new fork as verified via repository metadata on 2026-11-26. The task queue is a dated index; **live draft PRs/branch refs** are the coordination signal. An empty issue search is not evidence that nobody is working.
- Upstream CI at original baseline: Windows Clippy normal/all-features and locked workspace tests, triggered on PRs and pushes to `main`. A workflow definition does **not** prove a run succeeded.
- Upstream's README at original baseline reports about **1 FPS in the world on an AMD RX 6700 XT** and incomplete ray-traced lighting. That is upstream-reported historical evidence, not this user's RTX 5090 result.
- **This new fork has not been gameplay-tested on the user's RTX 5090 in this handoff. No old-fork binary, patch, test result, or gameplay metric is automatically transferable.**

## Active initiative

Establish source-controlled multi-agent onboarding, evidence-first research, PR gates and continuity documents on an isolated `docs/agent-continuity-system-20261126` branch. **This initiative changes process files only**, not GPU/runtime/shader behavior. Check its live PR status and CI rather than assuming it was merged.

## Next operations (execute only after live verification)

1. Review [draft PR #1](https://github.com/JohnTWillemsen/VIctory-W/pull/1) against `main`, then inspect **the live PR head SHA and its completed checks**. The last confirmed clean snapshot was `c4a7817560b6091862dae65a3ca207f0a079b3e0` (Windows CI and agent-docs integrity both succeeded); **subsequent documentation changes require a fresh check**. Owner authorization is required before merging.
2. Preserve `main` as an upstream-aligned reference. Choose a single small upstream-compatible **source-only** regression or missing bug for a separate experiment. First prove whether `main` already implements it.
3. Identify the latest primary-upstream issues/PRs by source analysis and evidence. Record candidate/duplicate/conflict checks in UPSTREAM_TRACKER, not ungrounded speculation.
4. Separately prepare an RTX 5090 local run with legally obtained files outside Git and identical baseline settings; **hardware owner must execute it**. Capture sanitized measurements only in a private local test location.
5. For a successful fix, propose a focused upstream Marvisak PR with original attribution and real test evidence after owner review.

## Current blockers / truth boundaries

- `NOT_RUN`: no new-fork native RTX 5090 game test is recorded.
- `CI_PASS` (previous head only): [Windows CI run 45862905345](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45862905345) succeeded on `c4a7817560b6091862dae65a3ca207f0a079b3e0`: both Clippy variants and workspace tests (872 passed, 0 failed, 10 ignored); the repository asset-policy test passed. [Documentation integrity run 45862905404](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45862905404) also passed with 41 working local links and a deliberate broken-link rejection. **This is not proof the subsequently edited head passed.**
- `UNKNOWN`: whether PR #1 is currently merged or checked at its *live* head; fetch status and matching workflow results before reporting. It was open/draft during this audit.
- `UNKNOWN`: present-day upstream branches, PR disposition and hardware behavior beyond this dated snapshot; re-query GitHub.
- `UNKNOWN`: branch-protection/ruleset enforcement. The GitHub integration could not read the fork's branch-protection settings. **Written instructions are not enforced GitHub permissions.** Owner should enable a `main` ruleset requiring reviewed PRs and the `check` + `agent-docs` checks, with force-push/deletion blocked. Confirm enforcement in GitHub Settings.
- The historical experimental integration in the old fork lives at a different repository/branch; see LEGACY_CONTEXT.

**Maintain this file:** Change the snapshot date when live facts are rechecked; record complete SHA, linked PR and CI, affected paths, confirmed tests, blockers, and immediate next action. Never silently overwrite earlier evidence; use EVIDENCE_LOG.
