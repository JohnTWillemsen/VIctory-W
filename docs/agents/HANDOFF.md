# VIctory-W — canonical handoff (read this first)

## VW092-H1 verified / H2 diagnostics staged (2026-11-27 AZ)

[PR61](https://github.com/JohnTWillemsen/VIctory-W/pull/61) exact source `3a830b3509491713d2c164e6ed12dcfc1805e778` / exe SHA256 `d4963529a4197806d92864d5ef0461b3838029e90ca49e74460d9708b1351864`, E164 [CI PASS 46114929321](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46114929321), [source release PASS 46114929298](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46114929298). Owner's three validated one-member anonymous ZIPs from `e127-20261128063033-7ce369`: E127 **World=Yes Controls=Yes**, 285s exit0, 2 RTX5090 adapter events, zero recognized GPU faults; E141 28 scene-like windows FPS p50 **26.7**, p10 **6.0**, min **3.6**; VW092 45 paired/zero invalid, slow <=10FPS (4 windows) median summed wait **7241.233ms** vs fast >=20FPS (21 windows) **59.289ms**, ~122x association, **not frame-time causality**. Source ordinary wait budget 500ms/frame vs screen-pass 10s, category unknown. H2 opt-in screen-vs-ordinary classification staged in PR61; exact-head Windows CI pending. Do not blindly tune, rerun or merge. Old E151 paragraphs below are dated. No user ZIP, title data or raw logs in GitHub. Three inherited GPU synthetic and strict Clippy remain RED; main unchanged.


## E151 latest — PR50 RTX5090 FPS promising, visuals/controls NOT CONFIRMED

Owner uploaded **both fixed-field E127/E141 ZIPs** for [draft PR50](https://github.com/JohnTWillemsen/VIctory-W/pull/50) candidate source `dd4b1146592909ad26730bc9864d9b25d1f211b2`, executable SHA256 `e4a9ee63e21b7b77daa6620c2eddeda31a94e1aa01477614cd7be045e62529ac`, E127 run `e127-20261128024702-726c06`, verified [CI 46098122107](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46098122107). E127 `FINALIZED`, exit 0, 336 sec, selected real RTX5090, zero recognized GPU fault markers in 7,000 scanned lines; **visual=Unknown and controls=Unknown.**

E141 candidate longer log **30 scene-like windows median 29.1 FPS** (first half 25.9/last 30.3), short log five windows **3.6 FPS**. Original main baseline longer log **90 windows median 10.9 FPS** (first 11.7/last 9.6), short 5 windows **3.6 FPS**. Longer log sampled median **2.67x**; pooled 28.4 vs 10.3 FPS. But candidate p10 only 3.5 FPS, p90 frame-window ms 285.7; stutter persists. These are *multi-second log-window averages*, not 1% lows, direct GPU utilization, or matched scene/cache/time benchmark. Host-GPU-associated p50 0.0ms is not evidence the GPU did no work.

**BLOCKER:** User must confirm this exact candidate rendered Lucia's 3D cell correctly and movement worked; **do not merge PR50 until then**. Original E139 baseline worked in 3D, but was a different binary. Apparent FPS gain may mean omitted rendering. No replay needed just to clarify prior observations. Next if visual/input pass: controlled same-cell repeat or instrumented frame pacing. [E151 research](../research/E151-RTX5090-CPU-CANDIDATE-FPS.md), E151 evidence, D060, VW088. [PR53](https://github.com/JohnTWillemsen/VIctory-W/pull/53) exact PR-head artifact provenance fix merged; old synthetic merge artifact retired. E144 WARP 203+3 pass; 3 inherited full synthetic reds/Clippy red; PR50 still draft. Owner ZIP/private data not in GitHub.

## E140/E141 earlier performance (historical, superseded by H1)

The earlier E140 session had 95 scene-like FPS windows (p50 10.3, p10 4.0, min 2.9), with CPU preparation and copyback pressure. E141 separated its two logs. Those data are historical, not a controlled comparison to H1. See [E141 research](../research/E141-OFFLINE-PER-LOG-COMPARISON.md), E140/E141 evidence and D055.

## E139 UPDATED FIRST HARDWARE ACCEPTANCE — owner confirmation on 2026-11-27 Arizona

**FIRST REAL RTX5090 CONTROLLABLE RENDERED 3D INTERIOR = CONFIRMED.** Following the E138 ZIP's original `human_observed_visual=Unknown` and `human_observed_controls=Yes`, the owner explicitly confirmed seeing a rendered 3D interior room/cell and moving the player through it. This direct follow-up upgrades **initial indoor World+Controls acceptance only**, without rewriting E138 ZIP or implying outdoor/open-world access, wide scene progression, fidelity, sustained play, or overall stability. The first session ran a source-matched NVIDIA-v8 binary SHA-256 `25100c5247e23ac2f39fd10cf7017ddaaab2dd56a9c60a1dda18c3e89e73c84f` from clean source main `8caccae47243cad361038bab4d4d4025f90ccc82`; RTX5090 was the selected host adapter, exit code 0 and 0 recognized GPU fault markers. Original ZIP's `elapsed_seconds=26020` is invalid, inflated by Phoenix UTC offset; reporting-only [PR45](https://github.com/JohnTWillemsen/VIctory-W/pull/45) fixes calculation. E138 original and E139 owner follow-up are separate append-only evidence rows. No need to rerun dangerous GPU test merely to answer visual question. **Next:** investigate wider scene progression, renderer correctness and measured stability; check live `main` before use.


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

Owner's Windows workstation uses NVIDIA RTX 5090 and Intel Core Ultra 9 285K. Their agreed **new separate local workspace** is `C:\VIctory-NVIDIA` (**fresh clone of this existing GitHub VIctory-W repo**, not a separate remote), reporting root `C:\VIctory-NVIDIA-Tests`; `C:\VIctory-W` is their older checkout and should be left untouched. **These are intended local paths, not independently confirmed present.** Game files remain in their existing local folder; never copy/upload titles to GitHub. **Mandatory local instructions:** [LOCAL_WORKSPACE.md](LOCAL_WORKSPACE.md) provides the safe PowerShell bootstrap, remote/branch/status verification, ownership of local build/report folders, and privacy boundaries. Never run or clean the old local checkout.

**Mission:** Make the unofficial Xbox-to-Windows compatibility layer reach a rendered 3D world with working controls, with correctness and stable performance. No native BVH builder for the first baseline. **The user's own observed world/control success is the milestone**, not more speculative shader fixes.

## Testing and uploads: one session = one privacy-safe ZIP

Use [E127 protocol](../research/E127-TESTING-AND-UPLOAD-PROTOCOL.md), [local workspace agreement](LOCAL_WORKSPACE.md), and `scripts/research/owner-nvidia-session.ps1` from verified `main`; always pass `-ReportRoot 'C:\VIctory-NVIDIA-Tests'` for owner-run sessions:
- Strict compiled-executable SHA check; **owner consent ('PLAY')**; back up game saves; normal non-admin PowerShell; NVIDIA fork's built-in `victory play`, clean isolated `VICTORY_HOME`, `VICTORY_ADAPTER=RTX 5090`, RT BVH/debug/scripted keys off.
- The report harness checkpoints **one** `E127-anonymous-summary.zip`; after reboot `-Mode Recover` reconstructs from private local files without relaunch. Report fixed fields only: actual host adapter name match, exit/device-loss markers, human-observed World/Controls acceptance, stage (`Unknown/Menu/Black/World`), movement (`Unknown/No/Yes`). Ask for **only the anonymous ZIP**.
- Keep raw title logs, screenshots, title files, local paths, shaders, caches and dumps on owner PC; never paste them in GitHub. `VIctory-W` repo was **PUBLIC** at checkpoint; recheck visibility before any change involving sensitive data.
- The harness's synthetic privacy + parsing fixture passed; **owner's first real game session on this source still needs to be performed with explicit consent**. Do not claim a GPU run has happened merely because its script exists.

## Active priorities (not the old backlog)

1. **P0: reproducible first RTX5090 visible-world+controls checkpoint** using the above protocol. Only ask for a locally executed one-run test if required and safe; do not ask owner to repeat earlier E087/E091 multiple-ZIP crash experiments.
2. **P1: diagnose the three inherited D3D12/WARP GPU synthetic test failures** and existing strict Clippy warnings on the new source. Distinguish WARP feature support from real implementation defects before changing code; do not blanket-skip.
3. **P2: consider upstream NVIDIA fixes only after comparing their actual commits against our pinned source and independently verifying them**. Preserve attribution and isolation.
4. **Governance:** keep `AGENTS.md`, this file, `CURRENT_STATE.md`, `LATEST_CHECKPOINT.md` and `NEW_SESSION_PROMPT.md` aligned on each significant milestone; append evidence to `EVIDENCE_LOG.md` and decisions to `DECISIONS.md`. Historical `TASK_QUEUE.md` rows are not active authorization.

## E131/E133 historical launcher and reporting fixes

[PR41](https://github.com/JohnTWillemsen/VIctory-W/pull/41) preserved isolated VICTORY_HOME and RTX adapter through the launcher; [PR43](https://github.com/JohnTWillemsen/VIctory-W/pull/43) retained early RTX adapter evidence outside bounded log tails. These fixes are already on main. Historical untested-owner statements in these sections are superseded by H1, above; see E131/E133 evidence for commit/test details.

## Fresh-session boot procedure (mandatory)

1. Read `AGENTS.md`, **this file**, `CURRENT_STATE.md`, `LATEST_CHECKPOINT.md`, `NEW_SESSION_PROMPT.md`, then relevant `EVIDENCE_LOG.md`, `DECISIONS.md`, [E127 protocol](../research/E127-TESTING-AND-UPLOAD-PROTOCOL.md) and actual source. Do **not** load 100 KB of old prose before checking the live branch.
2. Fetch **live** repo privacy, default branch SHA, recent main commits, open PR heads/base branches, and recent CI runs/jobs, especially source release vs synthetic tests vs report fixture. Compare against dated facts here; explicitly flag changed/stale details and new owner uploads before editing code.
3. State what is **VERIFIED**, **FAILED**, **NOT RUN**, or **UNKNOWN**. Review overlapping old PRs but never auto-merge AMD-based experiments onto NVIDIA. Work from current `main` on an isolated branch and make a bounded source/test change, PR and CI. Never silently force-push.
4. Update the short handoff documents and append evidence/decisions with exact SHA, CI links, hardware result, next task and known limits. Pass the concrete state to the next agent, not promises of ongoing invisible work.

**Honest guarantee boundary:** Documents and automatic self-tests reduce stale-session errors, but cannot guarantee another AI agent's compliance, an offline conversation's exact continuity, or real GPU playability. GitHub live evidence is authoritative.
