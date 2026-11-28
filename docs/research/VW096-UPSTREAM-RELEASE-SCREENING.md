# VW096 — pinned NVIDIA upstream v2026.11.28.01 release source-screening

2026-11-28 UTC. **Draft/test-only**. Owner repo baseline `ea186566a868430a51e416d4c94695f6aff3fce1`, upstream previous v2026.11.27.8 `64d4931b3dd90305134512b805fc98f04119fb6e`, latest release [v2026.11.28.01](https://github.com/trustno1-coder/VIctory-NVIDIA/releases/tag/v2026.11.28.01), pinned source `63b902fe1720a5188ee79d94a88c8de0470f6349`. Verified GitHub compare: 56 commits ahead, zero behind; 75+ files changed. Do not blend sources with owner v8 `main` or experimental drafts.

## Actual changes in upstream cohort

- Updated DXGI focused-window immediate present and frame-generation-ready startup behavior; allows fallback if immediate presentation is refused on a GPU, but the default differs from the H4 known-good source.
- More memory reclamation (texture slots, command allocators, small buffers), default-on. Upstream documents opt-outs `VICTORY_SLOT_EVICT=0`, `VICTORY_ALLOCATOR_TRIM=0`, `VICTORY_BUDGET_PACK=0`.
- Numerous rendering/shader, descriptor-resource, replay, loader, HLE, save, controller and accounting fixes. One independent divide-fixup patch is already under [PR64](https://github.com/JohnTWillemsen/VIctory-W/pull/64). Do not claim which change improves FPS without controlled hardware evidence.
- Upstream offers Series S render-size controls and documents 1080p, 720p and 540p paths. For the **first comparison keep the same console/profile/scene settings** to avoid a false FPS gain due to changed render resolution.

## What this GitHub branch tests

The workflow checks out the **unmodified external upstream source** at the immutable pinned SHA in a separate Actions workspace, not inside owner main, and separately checks out the exact PR-head E127 code. Windows jobs independently run locked release compilation, full locked synthetic/WARP tests, strict Clippy default+diagnostics, and PowerShell E127+owner manifest fixtures. Its artifact contains only source-built `victory.exe`, exact E127 harness, exact owner verifier and a two-repository, two-script SHA256 manifest. It **does not** contain title data or launch the game.

The PR preserves the original NVIDIA v8 E127 script unchanged and adds a **separate upstream-only E127 runner** with the new source version/pin, retaining the same fixed-field allowlist, crash recovery and literal `PLAY` prompt. Standard v8 Windows E127 CI can never label a v8 binary with upstream .01 metadata. The owner verifier insists on the separately disclosed exact PR commit, known CI binary SHA, and identical CI-provenance hashes of both PowerShell helpers; rejects missing/duplicate fields and mismatched hashes before launching. It can run `Prepare` read-only, `Run` once after backup and literal `PLAY`, or `Recover` without relaunch. Performance data is generated only from E127 private logs by existing E141, without exporting raw logs.

## Owner safety conditions

- **Do not request GPU work** until all independent Windows source gates complete and the exact artifact and executable hash are verified. A CI PASS does not prove a correct 3D world.
- Keep `C:\VIctory-NVIDIA` at clean `main` and all new session/build/private files under `C:\VIctory-NVIDIA-Tests`. Never modify `C:\VIctory-W`, baseline H4 binaries or the seeded private persistent cache. No old shader pipeline cache may cross into the upstream test: E127 creates a new `VICTORY_HOME` and the wrapper unsets any inherited `VICTORY_CACHE_DIR` during the run.
- Use normal non-administrator PowerShell, back up title saves, stop any current game process, and type literal `PLAY` only after the user consents. Driver or PC reboot is possible. Do not change or copy title files into GitHub.
- World/Controls must be recorded from direct observations. A different frame generator, render resolution, cache temperature or scene is **not a controlled A/B**. If rendering is missing or blank, reject performance comparisons regardless of FPS.
- A single E127 session produces one fixed-field `E127-anonymous-summary.zip`; after exit/recovery E141 produces one numeric-only `E141-anonymous-perf-summary.zip`. Upload only these when needed. No images/logs/private paths/dumps or saves.
- Preserve known-good H4 source/exe `70e0bbe0ed7aa032a65495a99f26240310acdeeb1337927002b1a6460a801d60` from earlier owner testimony, do not auto-merge any upstream changes to `main`.

## E127/E141 owner regression — 2026-11-28 UTC (user-supplied anonymized ZIPs)

**Observed on actual owner machine, not a simulated GPU test.** Source-built SHA256 `edf411e6a86824544aaf4f85261d9dc47e98a1349aefb2294ef8d86058b93014`, source `63b902fe1720a5188ee79d94a88c8de0470f6349`, PR head `c709136e998dfdef99c78ad7b7161ae95202746e`, E127 run `e127-20261128090731-d4d82c`. **FINALIZED; exit 0; 241 s; 0 device removed/hung/DRED markers across sampled tail.** E127 reported `human_observed_visual=Unknown`, `controls=Unknown` and `observed_host_gpu=UNKNOWN` (new log's adapter message not recognized; the runner independently required `nvidia-smi` RTX5090 presence). **Do not silently turn these UNKNOWN fields into YES.**

E141 offline per-log: 31 total log windows; 19 scene-like, p10/p50/p90 FPS **3.6/13.1/21.9**, min 3.4; frame-ms p50/p90 **76.4/275.2**; CPU prepare p50 25.9ms, host-GPU p50 8.1ms, copyback p50 5.3ms; draws/frame p50 5342. First-half FPS p50 6.6 → last-half 20.7, consistent with a warm-up hypothesis but **does not** establish identical scene or cache conditions. Owner's screenshot supplied in private chat showed **head geometry/facial mesh missing**, with isolated eyes/teeth; user said laggy and **prior double-load/warm-cache game session looked better**. The screenshot and title graphics stay private and were **not uploaded to public GitHub**. In earlier H3 warm-cache owner evidence the prior candidate's 32.9 FPS was a different source/build/run/scene and **not a causal matched comparison**. Visual correctness is a blocking acceptance gate even if FPS eventually rises.

**Source-side hypotheses grounded in pinned code:** v2026.11.28.01 `apps/victory/src/play.rs` enables `VICTORY_SLOT_EVICT=1`, `VICTORY_ALLOCATOR_TRIM=1`, `VICTORY_BUDGET_PACK=1` by default; v2026.11.27.8 lacked these default-on switches. The new source also only automatically warm-up-restarts with DLSS framegen made ready/on; original E127 used plain `victory play` with fresh isolated `VICTORY_HOME` and no imported warm cache. These differences are hypotheses, **not confirmed causes** of missing head geometry.

**New targeted behavioral A/B:** keep exact v2026.11.28.01 upstream executable, scene/profile and fresh isolated E127 `VICTORY_HOME`, but add fixed, narrowly allowlisted `LegacyV8Memory` treatment: `--set VICTORY_SLOT_EVICT=0 --set VICTORY_ALLOCATOR_TRIM=0 --set VICTORY_BUDGET_PACK=0`. Upstream `play.rs` explicitly documents `--set` overrides; merely setting process environment variables would be silently reset by the built-in launcher. Modified upstream-only E127 must include `memory_stack_profile` in public fixed-field ZIP, test both profiles without game, retain PLAY + crash Recover, and include helper/script SHA in the exact artifact. **Do not ask owner to run until new exact-head CI build and privacy fixtures PASS.** If visual defect goes away, isolate one switch at a time; if not, evaluate controlled warm-cache reuse separately. No source upgrade, GPU success, or fix claim on `main`.

**Independent Windows CI for original source screening:** release+E127 fixtures PASS (run 46128389770, artifact 15257240848, binary SHA above); full locked tests **FAIL 1 inherited depth_bounds test (452 pass / 1 fail / 36 ignored in GPU lib)**; strict Clippy **FAIL 2** (new shader-test let-and-return and GPU shadow modulo lint); E129/E140/E145 PASS. The workflow is not globally green and cannot certify rendering.

## Scope of results

- `SOURCE_BUILD_PASS`: exact upstream source build on Windows; **not** source runtime acceptance.
- `WARP_PASS`: full synthetic suite on Windows Actions WARP; **not** actual RTX5090.
- `CLIPPY_PASS`: lint only.
- `E127_FIXTURE_PASS`: local report/privacy parser and source/hash-negative fixtures only.
- `OWNER_GPU_WORLD_CONTROLS_PASS`: only after owner sees it and a validated E127 ZIP records it.
- `FPS_DELTA`: do not assert until matched scene/display settings and warm-state evidence.

**Do not merge this branch as a runtime change**: it is an independent upstream screening workflow, not source update approval.
