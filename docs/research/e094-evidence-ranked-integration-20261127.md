# E094: evidence-ranked compatibility integration (isolated, not merged)

Date: 2026-11-27 (America/Phoenix). Source: original upstream `Marvisak/VIctory` GPL-3.0-compatible Rust source, copied by exact, preimage-verified hunks onto our `main` `63bcca43c6a00a758510398fa43096ce7e4f7df0`. No proprietary title data.

## Candidate A: NVIDIA raw SRV/UAV alignment, safety

- Source: https://github.com/Marvisak/VIctory/pull/3540 head `ee3d12dc356df92a2da49133f11a5f0c98b0291f`.
- Public CI `check` success at this exact head on 2026-11-27. Exact patch checked against our original host.rs and reproduces upstream head file from the same base.
- Source author reports Windows NVIDIA same title-run stack: without fix **3/4** 300-second runs removed D3D12 device with invalid RAW SRV alignment; with fix **0/3** device removals, 930 workspace tests pass. Evidence tag: `UPSTREAM_REPORTED`, NOT owner RTX5090 proof. `DXGI_ERROR_INVALID_CALL (0x887A0004)` is distinct from owner's E087 `DXGI_ERROR_DEVICE_REMOVED (0x887A0005)`; no causal claim about E087.
- Change: all raw views (including CBV), SRV/UAV, and their refreshed host copies use 16-byte minimum alignment; synthetic non-GPU unit test added.

## Candidate B: eliminate per-slot host heap warning flood, runtime logging only

- Source: https://github.com/Marvisak/VIctory/pull/2634 head `a9eca1430a0b2a133ee5ebc4ec07062ae6c562ba`; upstream exact-head CI `check` succeeded.
- The source author reports first-frame preparation **21,433 ms to 33.3 ms** and log lines 310,932 to 231 with otherwise matching warm caches; independent RTX5090 FPS not measured. Author warns 245,184 guest slots are still unmapped on a capped 1M descriptor host. Evidence: `UPSTREAM_REPORTED`; our E064 raw logs independently showed 507,331 repeating warnings. The original patch's preimage hunk matches our main; whole upstream file HEAD differs because of upstream branch drift, so only the exact matching hunk was imported.
- This is neither heap remapping nor a shader/rendering correction. Earlier local E065 optional warning bucketing is NOT imported or stacked.

## Candidate C: optional held-key scripted movement

- Source: https://github.com/Marvisak/VIctory/pull/3392 head `72d5370455e3fcd95f9daf672daa03ff862d4293`; exact-head upstream CI `check` passed; author reports reaching world/held-W movement scripting.
- Diagnostics-only syntax `VICTORY_KEYS=10:Enter:300,20:Enter:300,200:W:6000`, with previous 200ms default unchanged. Adds test for exclusive end, overflow-safe time arithmetic. Not proof that our RTX5090 renders or accepts movement input.

## Reconciliation, tests, risk and next action

The two host.rs hunks occupy separate original ranges; each applies with unique exact context. The alignment patch was verified byte-for-byte against upstream's exact target file when applied alone. #3392's two patched files similarly match upstream exactly when isolated. This branch contains only three patches (3 source files + this audit), not the 53-PR #3409 aggregate and not our six-PR #439/#2118 Wave64/BVH stack. The six-PR tested source remains in separate draft PRs; E081 verified #3406's direct patch conflicts with #439, so no unsafe import.

`NOT_RUN`: this branch's Windows CI, real NVIDIA RTX5090, actual title gameplay, visuals, FPS, and integration with existing six-PR runtime source. These must be tested in that order. Do NOT request new title launch based only on this branch. `main` must not be merged without owner approval. Revert is deleting/closing this isolated draft branch; no default switches were enabled.

Key blockers: 7/53 BVH builder shaders refused on owner E075 six-PR run (5 >64 group, 2 broad LDS); E085 alternate #3409 build had black screen + audio and E087 lasted 63sec then removed device. We require a single tested combined source and a credible visual correctness gate before asking for another crash-prone owner run.
