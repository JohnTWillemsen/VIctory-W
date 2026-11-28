# VW096 — pinned NVIDIA upstream v2026.11.28.01 release source-screening

2026-11-28 UTC. **Draft/test-only**. Owner repo baseline `ea186566a868430a51e416d4c94695f6aff3fce1`, upstream previous v2026.11.27.8 `64d4931b3dd90305134512b805fc98f04119fb6e`, latest release [v2026.11.28.01](https://github.com/trustno1-coder/VIctory-NVIDIA/releases/tag/v2026.11.28.01), pinned source `63b902fe1720a5188ee79d94a88c8de0470f6349`. Verified GitHub compare: 56 commits ahead, zero behind; 75+ files changed. Do not blend sources with owner v8 `main` or experimental drafts.

## Actual changes in upstream cohort

- Updated DXGI focused-window immediate present and frame-generation-ready startup behavior; allows fallback if immediate presentation is refused on a GPU, but the default differs from the H4 known-good source.
- More memory reclamation (texture slots, command allocators, small buffers), default-on. Upstream documents opt-outs `VICTORY_SLOT_EVICT=0`, `VICTORY_ALLOCATOR_TRIM=0`, `VICTORY_BUDGET_PACK=0`.
- Numerous rendering/shader, descriptor-resource, replay, loader, HLE, save, controller and accounting fixes. One independent divide-fixup patch is already under [PR64](https://github.com/JohnTWillemsen/VIctory-W/pull/64). Do not claim which change improves FPS without controlled hardware evidence.
- Upstream offers Series S render-size controls and documents 1080p, 720p and 540p paths. For the **first comparison keep the same console/profile/scene settings** to avoid a false FPS gain due to changed render resolution.

## What this GitHub branch tests

The workflow checks out the **unmodified external upstream source** at the immutable pinned SHA in a separate Actions workspace, not inside owner main, and separately checks out the exact PR-head E127 code. Windows jobs independently run locked release compilation, full locked synthetic/WARP tests, strict Clippy default+diagnostics, and PowerShell E127+owner manifest fixtures. Its artifact contains only source-built `victory.exe`, exact E127 harness, exact owner verifier and a two-repository, two-script SHA256 manifest. It **does not** contain title data or launch the game.

The PR modifies only the E127 report's declared upstream version/pin on its branch, **not** its allowlisted field names, crash recovery, shader cache safety or literal `PLAY` prompt. The owner verifier insists on the separately disclosed exact PR commit, known CI binary SHA, and identical CI-provenance hashes of both PowerShell helpers; rejects missing/duplicate fields and mismatched hashes before launching. It can run `Prepare` read-only, `Run` once after backup and literal `PLAY`, or `Recover` without relaunch. Performance data is generated only from E127 private logs by existing E141, without exporting raw logs.

## Owner safety conditions

- **Do not request GPU work** until all independent Windows source gates complete and the exact artifact and executable hash are verified. A CI PASS does not prove a correct 3D world.
- Keep `C:\VIctory-NVIDIA` at clean `main` and all new session/build/private files under `C:\VIctory-NVIDIA-Tests`. Never modify `C:\VIctory-W`, baseline H4 binaries or the seeded private persistent cache. No old shader pipeline cache may cross into the upstream test: E127 creates a new `VICTORY_HOME` and the wrapper unsets any inherited `VICTORY_CACHE_DIR` during the run.
- Use normal non-administrator PowerShell, back up title saves, stop any current game process, and type literal `PLAY` only after the user consents. Driver or PC reboot is possible. Do not change or copy title files into GitHub.
- World/Controls must be recorded from direct observations. A different frame generator, render resolution, cache temperature or scene is **not a controlled A/B**. If rendering is missing or blank, reject performance comparisons regardless of FPS.
- A single E127 session produces one fixed-field `E127-anonymous-summary.zip`; after exit/recovery E141 produces one numeric-only `E141-anonymous-perf-summary.zip`. Upload only these when needed. No images/logs/private paths/dumps or saves.
- Preserve known-good H4 source/exe `70e0bbe0ed7aa032a65495a99f26240310acdeeb1337927002b1a6460a801d60` from earlier owner testimony, do not auto-merge any upstream changes to `main`.

## Scope of results

- `SOURCE_BUILD_PASS`: exact upstream source build on Windows; **not** source runtime acceptance.
- `WARP_PASS`: full synthetic suite on Windows Actions WARP; **not** actual RTX5090.
- `CLIPPY_PASS`: lint only.
- `E127_FIXTURE_PASS`: local report/privacy parser and source/hash-negative fixtures only.
- `OWNER_GPU_WORLD_CONTROLS_PASS`: only after owner sees it and a validated E127 ZIP records it.
- `FPS_DELTA`: do not assert until matched scene/display settings and warm-state evidence.

**Do not merge this branch as a runtime change**: it is an independent upstream screening workflow, not source update approval.
