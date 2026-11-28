# VW093 — isolated opt-in NVIDIA DXGI immediate presentation candidate

**State:** code staged on a separate draft branch from NVIDIA `main`, **NOT owner-GPU tested** and **NOT merged**. No game content and no private cache committed.

## Why a real code change, not another report

Owner explicitly requested implementation-first work: H2/H3/H4 all ran the same source-built binary. The working H4 World/Controls and 2,521-file private RTX5090 cache remain the rollback baseline. H5 offline counts of 1,883 D3D12 library loads and 2,424 newly-made pipeline states do not prove a new speedup or pin stutter to those pipelines. We must deliver source code plus tests before another RTX5090 replay.

## NVIDIA upstream review (2026-11-28 UTC)

- Pinned NVIDIA source `trustno1-coder/VIctory-NVIDIA` at `64d4931b3dd90305134512b805fc98f04119fb6e` (v2026.11.27.8). Live upstream `main` `63b902fe1720a5188ee79d94a88c8de0470f6349` (v2026.11.28.01): [56 commits ahead, zero behind](https://github.com/trustno1-coder/VIctory-NVIDIA/compare/64d4931b...63b902f). Do not import this entire update blindly.
- The upstream [v2026.11.27.10 release](https://github.com/trustno1-coder/VIctory-NVIDIA/releases/tag/v2026.11.27.10) documents real fixes: avoid frame-generation-ready-on-start contributing to ~14 FPS, opt-in-capable DXGI immediate presentation (`VICTORY_TEARING=0` upstream rollback), underwater shader translation and CI improvements. v2026.11.28.01 also changes Series S picture controls and memory behavior; none is yet verified on this owner's H4 game.
- Upstream `crates/victory-gpu/src/host.rs` after .8 contains DXGI feature support query, `DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING`, `DXGI_PRESENT_ALLOW_TEARING`, and automatic normal-present retry when the driver or Streamline proxy refuses immediate presentation (white-window report for an RTX5070).
- Our default must be safer than upstream's: `VICTORY_TEARING` **unset or other than 1 keeps the existing H2/H3/H4 Present(0,0) path**. Only explicit `VICTORY_TEARING=1` opts into a potentially faster window-presentation path, and only if DXGI feature support confirms; refusal disables immediate presents for the session without changing swap-chain creation flags.

## Actual implementation and bounded acceptance

`crates/victory-gpu/src/host.rs` adds one runtime source path:
- explicit opt-in parser;
- IDXGIFactory5 support query for tearing, ordinary path on failure;
- matching creation/resize flags;
- immediate Present only when enabled;
- one-way ordinary fallback if the first immediate Present fails; no retry of immediate mode this process.

`.github/workflows/vw093-dxgi-immediate-present.yml`: exact commit checkout; Win cargo test of `host::vw093_present_tests` checking default-off and flag invariants, and `cargo check --locked -p victory` (source only, **no game launch**).

**Acceptance gate:** code compiles in Windows exact-head CI; tests pass; no title files/public logs. A physical RTX5090 A/B would still be necessary to prove any FPS benefit and should use the **same build** with `VICTORY_TEARING` OFF/ON, same settings/cache/scene, E127 protected consent and anonymous reports only. Does not fix creation of 2,424 newly-made pipelines, and upstream's claimed ~2 FPS is NOT a measured result for this fork. If unsupported/white window, no launch loops or forced merge; fall back or drop the PR.

**Rollback:** leave `VICTORY_TEARING` unset (default), or set `VICTORY_TEARING=0`. Existing H4 known-good executable, private cache, reports and save isolation remain untouched. No merging without owner review.
