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

Establish source-controlled multi-agent onboarding on the isolated `docs/agent-continuity-system-20261126` branch, tracked in [draft PR #1](https://github.com/JohnTWillemsen/VIctory-W/pull/1). A **synthetic cold-start / SIGKILL / Git-resume / competing-worker rehearsal** is now part of its `agent-docs` CI; see [RESTART_TEST_PROTOCOL](RESTART_TEST_PROTOCOL.md). The documented process test is **not an actual LLM restart or RTX 5090 game test**. This PR changes process/test files only; GitHub `main` remains the Marvisak-aligned reference until owner-approved merge.

## Next operations (execute only after live verification)

1. Review [draft PR #1](https://github.com/JohnTWillemsen/VIctory-W/pull/1) against `main`, then inspect **the live PR head SHA and its completed checks**. The restart-tested snapshot was `997152e30e57e0d810fbf4275ebfacf8b3370b73`: [agent docs + restart CI succeeded](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45867868772). [Windows CI 45867868849](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45867868849) **also passed on that exact 997152e head**: both Clippy modes and locked workspace tests (872 passed, 0 failed, 10 ignored), including asset-policy test. Confirm newer live heads separately. **The present documentation commit is later and requires exact-head revalidation.** Owner authorization is required before merging.
2. Preserve `main` as an upstream-aligned reference. Choose a single small upstream-compatible **source-only** regression or missing bug for a separate experiment. First prove whether `main` already implements it.
3. Identify the latest primary-upstream issues/PRs by source analysis and evidence. Record candidate/duplicate/conflict checks in UPSTREAM_TRACKER, not ungrounded speculation.
4. Separately prepare an RTX 5090 local run with legally obtained files outside Git and identical baseline settings; **hardware owner must execute it**. Capture sanitized measurements only in a private local test location.
5. For a successful fix, propose a focused upstream Marvisak PR with original attribution and real test evidence after owner review.

## Current blockers / truth boundaries

- `NOT_RUN`: no new-fork native RTX 5090 game test is recorded.
- `CI_PASS` (**pinned Windows head only**): [Windows CI 45867868849](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45867868849) completed successfully on `997152e30e57e0d810fbf4275ebfacf8b3370b73`, with two Clippy configurations and 872 passing tests, 0 failed, 10 ignored. This proves source checks, **not** native graphics or gameplay.
- `CI_PASS` (**pinned rehearsal head only**): [Agent docs CI 45867868772](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45867868772) succeeded at `997152e30e57e0d810fbf4275ebfacf8b3370b73`. Nine synthetic process-level restart/recovery cases, 43 internal Markdown links and negative broken-link rejection passed. **No real LLM restart or branch-protection enforcement was tested.** Earlier [Windows CI 45865134045](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45865134045) passed on the preceding docs head `e56c5da061fffa0b56c49ae657f3191536c45640`; do not transfer its outcome to a different head.
- `UNKNOWN`: whether PR #1 is currently merged or checked at its *live* head; fetch status and matching workflow results before reporting. It was open/draft during this audit.
- `UNKNOWN`: present-day upstream branches, PR disposition and hardware behavior beyond this dated snapshot; re-query GitHub.
- `UNKNOWN`: branch-protection/ruleset enforcement. The GitHub integration could not read the fork's branch-protection settings. **Written instructions are not enforced GitHub permissions.** Owner should enable a `main` ruleset requiring reviewed PRs and the `check` + `agent-docs` checks, with force-push/deletion blocked. Confirm enforcement in GitHub Settings.
- The historical experimental integration in the old fork lives at a different repository/branch; see LEGACY_CONTEXT.

**Maintain this file:** Change the snapshot date when live facts are rechecked; record complete SHA, linked PR and CI, affected paths, confirmed tests, blockers, and immediate next action. Never silently overwrite earlier evidence; use EVIDENCE_LOG.
