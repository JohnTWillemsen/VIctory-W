# E153 — Opt-in NVIDIA DXGI immediate-present experiment

**Source baseline:** `JohnTWillemsen/VIctory-W` NVIDIA `main` `ea186566a868430a51e416d4c94695f6aff3fce1` at branch creation on 2026-11-27 America/Phoenix. **No title was launched. No RTX5090 result exists for this experiment.**

## Motivation

The previous owner RTX5090 E141 baseline's longer log reported 90 multi-second scene-like windows with median **10.9 FPS**; separate [draft PR50](https://github.com/JohnTWillemsen/VIctory-W/pull/50) candidate logged 30 such windows with median **29.1 FPS**, but visual fidelity and controls were **Unknown**, and that was neither a matched scene nor per-frame frame-time comparison. The candidate's stutter was still severe. Do not infer a GPU/presentation bottleneck from those data alone.

Current NVIDIA upstream [8fc2254](https://github.com/trustno1-coder/VIctory-NVIDIA/commit/8fc22547c81a0ae6e2e9d0669f776854016fb8a1) identified flip-model presentation delays: on its tester, a foreground window without tearing flag could wait for display refresh and lose roughly two frames/second. Upstream commit also contains unrelated shader translator, menu and warmup fixes; **only presentation code** was studied and adapted here. Upstream testimony is not an owner RTX5090 observation.

## Bounded code change

Only `crates/victory-gpu/src/host.rs` changes in the runtime. Adds **opt-in** `VICTORY_TEARING=1` (unlike upstream default-on, we keep the fork's current default off). Checks `IDXGIFactory5::CheckFeatureSupport(DXGI_FEATURE_PRESENT_ALLOW_TEARING)` and fails closed unless the Windows driver allows it. When supported and selected:

- Carries `DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING` from `CreateSwapChainForHwnd` through `ResizeBuffers`.
- Uses `Present(0, DXGI_PRESENT_ALLOW_TEARING)` while supported.
- If a Streamline/FSR/proxied swap chain rejects the immediate present, retries once with ordinary `Present(0, DXGI_PRESENT(0))`, then keeps ordinary presentation for the rest of the run; logs failures rather than claiming success.
- Keeps the original `Present(0, DXGI_PRESENT(0))` behavior when opt-in is absent/unsupported.

Potential visible tearing on non-adaptive-sync displays is an intentional *only-if-opted-in* risk. Changes do not alter GPU shader translation, native BVH, adapter selection, game saves, cache, game launch or PR50 CPU hot paths. This isolated main-based draft conflicts in `host.rs` with PR50: **do not cherry-pick/merge across branches without source reconciliation.**

## Gates, rollback and interpretation

1. New [E153 Windows CI](../../.github/workflows/e153-nvidia-dxgi-present.yml) checks out exact PR branch HEAD, exercises the pure DXGI chain-flags unit test without launching any title. E127 Windows release artifact build and anonymous report-harness fixture are separate automatic gates. CI cannot prove Windows compositor behavior or real gameplay FPS.
2. Before any real 5090 run: check exact source-built artifact + SHA and the source matching E127 privacy script; E127 `-ReportRoot 'C:\\VIctory-NVIDIA-Tests'` and **literal PLAY**, backed-up saves, host adapter evidence and owner World/Controls. A same-cell presentation A/B would have to hold cache/scene/settings and framegen configuration constant, compare per-frame pacing if possible, and produce *only* sanitized reports. **Do not request this test until separate PR50 correctness evidence is settled and exact-head CI has passed.**
3. Rollback by closing PR or `VICTORY_TEARING=0`/omitting `--set VICTORY_TEARING=1` on an experimental binary. `main` remains the known owner-confirmed controllable indoor baseline.

**Status:** source staged, CI result pending verification. No measured improvement, no merge authorization; this is an isolated correctness/performance hypothesis.
