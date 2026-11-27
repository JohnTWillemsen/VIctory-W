# E109 — Isolated 1D DispatchX thread-count guard candidate (complete #3426+#3561 stack)

## Provenance and objective
Parent is staged upstream #3409 [PR27](https://github.com/JohnTWillemsen/VIctory-W/pull/27), fork commit `712325801d17466c5ce6ff85d96065a5a22814e1`, upstream head `965d93823587932e8f40b152b8d4faab5f7a9c85`. E109 ports the full 13-file source patch of [upstream PR #3561](https://github.com/Marvisak/VIctory/pull/3561) at `b9000218cc129b88af1be4bd536b2c215517aaf4` (author **@CocoBeans64**), including the stacked dependency [#3426](https://github.com/Marvisak/VIctory/pull/3426) at `3f477b13b05cb8812dfc1f808e54b5230aac11ac` (author **@legayclightning22**).

The host's console `DispatchX` flags can supply a requested **thread count**, but PC D3D12 `Dispatch` expects a **group count**. #3426 adds a conditional thread-count guard and host conversion. #3561 extends the shader guard to barrier-free one-dimensional compute programs instead of only two named programs, fixing measured **32× overdispatch** in two BVH builder kernels in upstream AMD tests. Our owner's RTX5090 E091 DRED recorded 16 in-flight 1D DISPATCH appearances (potentially duplicate DRED records), max 1,533 host groups; that is **not proof** the exact same overdispatch caused the crash. Upstream reports title tests on AMD RX6800XT only for this PR.

## Exact source integration preflight and differences
Full upstream PR #3561 diff contained **42 code patch hunks** across 13 files, with 2 new files. 40 source hunks had exact unique-context matches on PR27; **two hunks failed only surrounding source context**, and were deliberately reconciled in limited, reviewed forms:

1. `crates/victory-gpu/src/draw.rs` `State::dispatch` signature: add `flags: Option<u32>` to the existing signature, preserving PR27's uncapped early `pipeline::is_skipped` check and other runtime behavior.
2. `crates/victory-gpu/src/list.rs` `state::dispatch` wrapper: delegate to `dispatch_with_flags(this,x,y,z,None)`; add the wrapper which calls existing `s.dispatch(...,flags)`, **preserving PR27's current mesh group handling** and count call.

All other hunks are upstream source edits exactly. This is **not** a blind merge or a claim that NVIDIA is stabilized; source-hash-pinned Windows Clippy/tests and executable gate are required before owner use. Combined E108+E109 has NOT been tested or staged; test variants separately to avoid confounds.

## Acceptance and constraints
Windows build runs locked full workspace Clippy default and diagnostics, workspace unit/GPU tests, `cargo xtask policy`, and release diagnostics executable. Only after all gates pass should a game-data-free public-source `victory.exe`+manifest be available. No game assets or title execution in CI. Physical owner RTX5090 run **NOT_RUN**, main unchanged. If accepted, use existing E087 supervised private anonymous report with other games closed and note whether visual world appeared; do NOT run multiple unverified binaries back-to-back, increase TDR, or upload proprietary private logs. Source conflicts/CI failing means no installer/download recommendation.
