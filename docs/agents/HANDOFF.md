# VIctory-W — canonical handoff (read this first)

**Role:** This is the short, maintained entry point for any new ChatGPT/agent session. It is a **dated checkpoint, not a claim of live status**. Confirm every mutable GitHub fact before acting. Older agent documents and PRs may contain superseded instructions; never privilege an old paragraph over live `main` and this checkpoint.

## Identity and immutable history

- **Repository and GitHub source of truth:** [JohnTWillemsen/VIctory-W](https://github.com/JohnTWillemsen/VIctory-W). Use the live default `main` branch for new work, not the deprecated old NVIDIA migration branch or previous AMD-based PRs.
- **Active codebase:** NVIDIA-focused [trustno1-coder/VIctory-NVIDIA](https://github.com/trustno1-coder/VIctory-NVIDIA) v2026.11.27.8, upstream source commit `64d4931b3dd90305134512b805fc98f04119fb6e`. Owner authorized a **full source switch**; [merged PR #37](https://github.com/JohnTWillemsen/VIctory-W/pull/37) and [PR #38](https://github.com/JohnTWillemsen/VIctory-W/pull/38) contain the migration, E127 report harness and ongoing CI.
- **Verified main when written (2026-11-27 Arizona):** `6b6bdf4219fc31eb35a8411e1b76fa9c03b2b1b7`. **This is a historical checkpoint, not a branch lock.** Query the live SHA every session; if it changed, review the intervening commits before deciding what remains true.
- **Source pin/attribution:** [NVIDIA_SOURCE_PIN](../migration/NVIDIA_SOURCE_PIN.md); 289 of 290 original upstream source file blobs matched when imported. Only upstream `.github/workflows/needs-logs.yml` omitted due workflow permissions. Preserve upstream licensing/asset-policy nuances.
- **Old source rollback:** `archive/pre-nvidia-foundation-20261127` at `63bcca43c6a00a758510398fa43096ce7e4f7df0`. Old E-series draft branches and PRs are historical evidence, **not** changes to reapply blindly. Never reset, replace or force-push the new `main`.

## Actual evidence, not implied success

As checked on 2026-11-27:
- [E127 Windows CI run #46084957654](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46084957654) on NVIDIA `main`: **locked Rust source release build PASSED**; **game-free PowerShell E127 anonymous-report SelfTest PASSED**; **full GPU synthetic tests FAILED** in the three previously established indirect-budget/depth-bounds cases. Its overall workflow correctly reports FAILURE.
- [Original CI #46084957675](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46084957675) still FAILED strict upstream Clippy on pre-existing warnings. Treat lint, synthetic/WARP, Windows build, and real owner GPU gameplay as **four distinct gates**. Do not waive test failures to make checks green.
- [Pinned source-built executable artifact](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46084406387/artifacts/15237799712): SHA-256 `4baf4fbcd3a5801d5c9f73c7c45e3e3299f435ff748eb28b49573d29e4aea9d3`. Historical artifact and hash apply **only to that exact built binary**; future artifacts may differ and may expire. Reverify source SHA, artifact and hash before giving the owner new instructions.
- **RTX 5090 actual NVIDIA-v8 game/world/control result: NOT RUN / NOT VERIFIED in GitHub evidence as of this checkpoint.** Do not call it playable based on upstream videos, FPS reports, audio, no crash, exit zero or successful CI.

## Owner's local organization and objective

Owner's Windows workstation uses NVIDIA RTX 5090 and Intel Core Ultra 9 285K. Their agreed **new separate local workspace** is `C:\VIctory-NVIDIA` (clone of this repo), reporting root `C:\VIctory-NVIDIA-Tests`; `C:\VIctory-W` is their older checkout and should be left untouched. **These are intended local paths, not independently confirmed present.** Game files remain in their existing local folder; never copy/upload titles to GitHub.

**Mission:** Make the unofficial Xbox-to-Windows compatibility layer reach a rendered 3D world with working controls, with correctness and stable performance. No native BVH builder for the first baseline. **The user's own observed world/control success is the milestone**, not more speculative shader fixes.

## Testing and uploads: one session = one privacy-safe ZIP

Use [E127 protocol](../research/E127-TESTING-AND-UPLOAD-PROTOCOL.md) and `scripts/research/owner-nvidia-session.ps1` from verified `main`:
- Strict compiled-executable SHA check; **owner consent ('PLAY')**; back up game saves; normal non-admin PowerShell; NVIDIA fork's built-in `victory play`, clean isolated `VICTORY_HOME`, `VICTORY_ADAPTER=RTX 5090`, RT BVH/debug/scripted keys off.
- The report harness checkpoints **one** `E127-anonymous-summary.zip`; after reboot `-Mode Recover` reconstructs from private local files without relaunch. Report fixed fields only: actual host adapter name match, exit/device-loss markers, stage (`Unknown/Menu/Black/World`), movement (`Unknown/No/Yes`). Ask for **only the anonymous ZIP**.
- Keep raw title logs, screenshots, title files, local paths, shaders, caches and dumps on owner PC; never paste them in GitHub. `VIctory-W` repo was **PUBLIC** at checkpoint; recheck visibility before any change involving sensitive data.
- The harness's synthetic privacy + parsing fixture passed; **owner's first real game session on this source still needs to be performed with explicit consent**. Do not claim a GPU run has happened merely because its script exists.

## Active priorities (not the old backlog)

1. **P0: reproducible first RTX5090 visible-world+controls checkpoint** using the above protocol. Only ask for a locally executed one-run test if required and safe; do not ask owner to repeat earlier E087/E091 multiple-ZIP crash experiments.
2. **P1: diagnose the three inherited D3D12/WARP GPU synthetic test failures** and existing strict Clippy warnings on the new source. Distinguish WARP feature support from real implementation defects before changing code; do not blanket-skip.
3. **P2: consider upstream NVIDIA fixes only after comparing their actual commits against our pinned source and independently verifying them**. Preserve attribution and isolation.
4. **Governance:** keep `AGENTS.md`, this file, `CURRENT_STATE.md`, `LATEST_CHECKPOINT.md` and `NEW_SESSION_PROMPT.md` aligned on each significant milestone; append evidence to `EVIDENCE_LOG.md` and decisions to `DECISIONS.md`. Historical `TASK_QUEUE.md` rows are not active authorization.

## Fresh-session boot procedure (mandatory)

1. Read `AGENTS.md`, **this file**, `CURRENT_STATE.md`, `LATEST_CHECKPOINT.md`, `NEW_SESSION_PROMPT.md`, then relevant `EVIDENCE_LOG.md`, `DECISIONS.md`, [E127 protocol](../research/E127-TESTING-AND-UPLOAD-PROTOCOL.md) and actual source. Do **not** load 100 KB of old prose before checking the live branch.
2. Fetch **live** repo privacy, default branch SHA, recent main commits, open PR heads/base branches, and recent CI runs/jobs, especially source release vs synthetic tests vs report fixture. Compare against dated facts here; explicitly flag changed/stale details and new owner uploads before editing code.
3. State what is **VERIFIED**, **FAILED**, **NOT RUN**, or **UNKNOWN**. Review overlapping old PRs but never auto-merge AMD-based experiments onto NVIDIA. Work from current `main` on an isolated branch and make a bounded source/test change, PR and CI. Never silently force-push.
4. Update the short handoff documents and append evidence/decisions with exact SHA, CI links, hardware result, next task and known limits. Pass the concrete state to the next agent, not promises of ongoing invisible work.

**Honest guarantee boundary:** Documents and automatic self-tests reduce stale-session errors, but cannot guarantee another AI agent's compliance, an offline conversation's exact continuity, or real GPU playability. GitHub live evidence is authoritative.
