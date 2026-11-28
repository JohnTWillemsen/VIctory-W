# E144 — Staged NVIDIA PR614 CPU refresh candidate (not accepted)

**Goal:** Isolated experimental source branch for a possible improvement to the severe first-controllable-interior lag documented in owner E141: 90 scene-like log windows median **10.9 FPS** (early 11.7, late 9.6); another 5-window log median **3.6 FPS**. All metrics are multi-second window aggregates, not frame-by-frame 1% lows or hardware GPU utilization. No direct causality established.

## Exact provenance

- Fork is `JohnTWillemsen/VIctory-W`, base `main` `8753fea068e453209c1b23f8b20bfeeef6b61552` after evidence E142.
- Upstream NVIDIA [PR614](https://github.com/trustno1-coder/VIctory-NVIDIA/pull/614), head `caf1a4ce5b212075307874b568cc766e8bca357d`, base `a4d05e7fd0af904130809c334a6008d62c24db6a`. The PR is **OPEN** and owner gameplay A/B is not available.
- Three source files in scope, tracked in `crates/victory-gpu/src/`: `host.rs`, `shadow.rs`, `watch.rs`. The latter two were **byte-identical** on our pinned NVIDIA branch and upstream PR base; imported corresponding upstream PR head blob content. The host file had only a **separate adapter selection wording difference** between fork and upstream PR base; **the upstream PR head actually matches our current fork's adapter-selection wording**, and import retained that exact wording (no new adapter policy).
- Upstream reports 204 Windows WARP tests passing and diagnostics cargo-check, but [upstream CI run 46095374774](https://github.com/trustno1-coder/VIctory-NVIDIA/actions/runs/46095374774) strict Clippy fails on **pre-existing texture test precedence** (`(i * 7) >> 3`), not on this three-file CPU optimization. This upstream failure is not being concealed or reclassified green.
- Scope is CPU hot-path no-op texture refresh lock removal, thin-worker refresh coalescing, AVX2 copy-diff. No asset/code from other unverified upstream PRs 618, 620 or 623. No save sharing or DLSS launcher changes from the upstream newer main.

## Why staged and NOT merged

E141 shows slow log-window performance and some CPU preparation work (24.7ms in longer log and 41.7ms in shorter), but not which component is dominant. PR614 addresses part of potential CPU preparation overhead but is unproven on this RTX5090/game. Changes to memory ordering, refresh path and CPU/GPU synchronization can affect correctness, so do not default-enable or merge based only on synthetic success.

## Validation gates

1. Branch has exactly 3 changed Rust sources, this research doc and an isolated Windows regression workflow `.github/workflows/e144-nvidia-cpu-refresh-windows.yml`. No proprietary title files, dumps or private owner logs.
2. Confirm exact imported content/blob SHAs against upstream PR614 head; verify source stayed pinned to NVIDIA v8 and the two adapter-preservation switches remain in `apps/victory/src/play.rs`.
3. Check E144 focused Windows `shadow::`, `watch::`, `host::`, `list::` WARP tests independently. Check E127 source-only release build and anonymous reporter privacy tests. **Full GPU synthetic suite** has three inherited failures and strict Clippy has inherited warnings: report them distinctly.
4. Do **not merge** source candidate or distribute as working improvement until independent review, targeted tests and a controlled, owner-consented **same-cell** performance A/B with a hash-verified experiment binary and isolated home. One variable at a time; baseline E137 source-built executable SHA-256 `25100c5247e23ac2f39fd10cf7017ddaaab2dd56a9c60a1dda18c3e89e73c84f` must remain available. Backup saves and require explicit PLAY only if an actual GPU run is requested.
5. Revert by closing draft PR or switching to unchanged main. No host-game result or FPS improvement may be claimed from WARP-only testing.

**Privacy:** only sanitized E127/E140/E141 fixed-field ZIPs are accepted. Raw logs and copyrighted title files remain on owner PC; this branch contains no such files.
