# E158 — Single exact-head RTX5090 opt-in DXGI candidate, with verified owner report

Date: 2026-11-27 America/Phoenix. Main at staging start: `ea186566a868430a51e416d4c94695f6aff3fce1`. This **draft, unmerged** owner A/B source branch starts from [PR57](https://github.com/JohnTWillemsen/VIctory-W/pull/57) tested runtime head `7a391de346ec2db455d472a5f7f6edee44b60d04`; incorporates **only** two test-fixture files + focused workflow from [PR56](https://github.com/JohnTWillemsen/VIctory-W/pull/56), and the two owner E127/E145 reporting scripts + fixture workflow from [PR59](https://github.com/JohnTWillemsen/VIctory-W/pull/59). No AMD-source imports or third-party title assets.

## Purpose and trust boundaries

One build must carry the experimental opt-in DXGI `VICTORY_TEARING=1` path **and** the exact owner-tested E127/E145 PowerShell harness, otherwise a report can accidentally describe a different executable or run in the default mode. An earlier PR50 owner E127/E141 run showed 29.1 FPS (long-log median) but recorded `World=Unknown`, `Controls=Unknown`; don't infer that it rendered correctly or that this E158 candidate will have the same performance.

The runtime's default remains ordinary presentation **OFF**; the only allowed opt-in is literal `--set VICTORY_TEARING=1`. Host DXGI factory support is checked before creation; on unsupported devices the normal swap chain is used. A proxy Present failure falls back to ordinary Present. PR57's single allowlisted setting survives the one-time warm-up restart; other `--set` flags do not. A pure Rust regression exercises the restart arguments.

The owner reporting script accepts `-Tearing 0|1`, defaults 0, and asks for literal `PLAY` before the title starts. Reports retain only fixed fields and known enum strings: `dxgi_tearing_requested=ON|OFF`, `dxgi_tearing_feature_query=FEATURE_SUPPORTED|FEATURE_UNSUPPORTED_OR_OFF|MIXED|UNKNOWN`, `dxgi_tearing_fallback_marker_count=<integer>`. Feature-query presence **does not prove successful presentation or a frame-rate improvement**; raw logs stay local, and a fallback means the present path reverted. E127 still checks host RTX5090, reports crashes and supports recovery; E141 aggregates sanitized per-log windows. E145 still verifies the binary's exact GitHub commit, upstream source pin and SHA-256 and refuses wrong/duplicate manifests.

## Separate Windows CI gates (no title)

- Exact-head [E152](../../.github/workflows/e152-nvidia-indirect-rest.yml): WARP tests with `VICTORY_INDIRECT_REST=0` and `1`, including the actual depth-bounds pixel readback. PR56 verified same test-only fixture on WARP, **436 passed / zero failed** GPU tests on its source branch; this branch requires independent exact-head re-verification.
- Exact-head [E153](../../.github/workflows/e153-nvidia-dxgi-present.yml): DXGI create/resize flag unit regression; Rust `apps/victory/src/play.rs` warm-up restart unit is exercised by the full Windows suite.
- Exact-head [E156](../../.github/workflows/e156-dxgi-optin-owner-handoff.yml): Windows PowerShell 5.1 syntax and E127/E145 synthetic self-tests. E127's synthetic log contains a head-only feature query and tail-only fallback; both counts must be private-data-safe and non-duplicated.
- Independent E127 full Windows source-only release artifact, anonymous report fixture, and entire GPU synthetic suite. Windows strict Clippy is separately inherited red until lints are repaired; do not re-label the entire repository's CI green.

## Exact owner test procedure once every candidate-specific gate passes

**No hardware was launched while preparing this branch.** Before asking owner to run anything: inspect live final PR head, all candidate-specific CI jobs, source-built [E127 artifact](../../.github/workflows/e127-nvidia-foundation-windows.yml) manifest `victory_w_commit` and SHA-256, exact helper code, and the expected one local source checkout.

The owner has a pre-existing clean NVIDIA source checkout at `C:\VIctory-NVIDIA` and dedicated private report root at `C:\VIctory-NVIDIA-Tests`. To **avoid changing the old source's main branch**, fetch the *exact 40-character E158 head* into the existing Git object store and create a detached worktree named `C:\VIctory-NVIDIA-Tests\E158-owner-source-<first12SHA>`. The revised E145 harness allows detached worktrees **only** with `-AllowDetachedCandidateWorktree`, checks exact commit and fixed worktree path under the report root, canonical remote, and clean working tree; normal `main` checks remain unchanged. Never create a fake local `main` branch to bypass provenance.

1. Run all local **preflights without launching a title**: standard/non-admin Windows PowerShell (if UAC disabled the current shell may not be suitable), working `git`, `gh`, `nvidia-smi`, exact SHA and artifact run ID, `-Mode Prepare -Tearing 1 -AllowDetachedCandidateWorktree`, expected one local executable and startup archive.
2. When all are confirmed and owner has a backup of saves, a separate **`-Mode Run`** invokes E127's literal `PLAY` prompt. GPU/driver may reset or reboot; no title launch happens unless owner types that exact word. Observe the *same first interior scene*, answer World/Controls correctly on exit, and avoid new-scene progression while stability is unknown. Do not claim FPS from a logo or audio-only scene.
3. Upload **only** `E127-anonymous-summary.zip` and `E141-anonymous-perf-summary.zip` if generated, in the report root. Do not send game files, saves, derived shaders, screenshots/title captures, unredacted logs or PRIVATE folders. If Windows crashes/reboots use the script's documented `Recover` mode and retain the previous checkpoint ZIP.
4. Compare with original E139/E141 baseline only descriptively unless same scene, timing, framegen and caches are matched. A single candidate run is an acceptance screening, not proof of higher 1% lows or broader game playability.

## Revert / stopping conditions

No automatic merge, force-push, local change to the original checkout or modification of title files. If exact HEAD mismatch, WARP/PS5.1 fixtures red, source release failed, no E127 artifact, SHA/hash mismatch, elevated console, missing title archive or absent RTX5090: **stop before PLAY**. Close the E158 draft if unsupported or fall back to owner-confirmed main. Other drafts PR50/56/57/59 remain available as independent evidence and rollback.
