# Testing and acceptance — keep source, WARP, GPU and game evidence separate

## Source-only gate (no game files)

From a checkout of the specific candidate SHA on Windows (repository pins Rust **1.98.1** in `rust-toolchain.toml`; requires Windows MSVC build tools), run:

```powershell
git rev-parse HEAD
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo clippy --workspace --all-targets --all-features --locked -- -D warnings
cargo test --workspace --locked
cargo xtask policy
cargo build --release -p victory --locked
cargo build --profile diag -p victory --features diagnostics --locked
```

The **upstream `.github/workflows/ci.yml` at the initial fork baseline** runs Clippy in both modes and locked workspace tests on Windows; it does not currently promise release/diagnostics build artifacts or a native RTX 5090 gameplay run. Do not claim unconfigured jobs are present. Our extra `agent-docs` workflow checks document structure only, not Rust runtime correctness.

Record **which commands were actually run**, exit code, date, exact HEAD SHA and environment. No actual execution means `NOT_RUN`. CI may run GPU tests on WARP or skip adapter-dependent cases; inspect logs and test markers before claiming WARP coverage.

## Synthetic GPU tests

For D3D12 memory, synchronization, texture/descriptor or shader issues, prefer controlled synthetic tests with known inputs/expected outputs. When a WARP path is available, verify it **truly executed**, ran on a software adapter, detected a negative-case failure and produced matching readback; passing a skipped test is not evidence. When a physical RTX 5090 test is available, identify the adapter+driver and distinguish GPU_SHADER_TEST from full gameplay.

## Human GPU baseline (separate from CI)

The owner has reported Windows 11, RTX 5090 and adequate system memory for experiments. Those **specifications do not imply that this clean fork boots or renders on that GPU**. Keep all legally obtained files, executables, caches, screenshots, captures and saves **outside** the repository. Follow the current upstream README rather than commands copied from an old fork.

For each real run record in **private** notes: full source SHA, binary SHA256, GPU/driver, Windows build, title build, Series X/S, resolution/upscaling, exact switches, save/checkpoint and scene, cold/warm cache, crashes/DXGI removal, input, same-scene visuals, world draws, dropped/refused draws, time-to-frame, median/p95/p99 frame time, and whether FPS was measured in the same world scene. Give the PR only sanitized numeric summaries and a local evidence identifier **without private path, copyright-protected output or captures**.

Acceptance order:
1. Boot/menu and functioning input without reset.
2. Full scene geometry (walls, floors, people, skin/hair), textures, water, HUD; daylight/indoor/shadows accurately assessed.
3. Progress through comparable mission steps and repeat across runs; verify no device removal.
4. Only then use fair frame-time and GPU/CPU budgets; higher FPS with omitted essential draws **fails**.

Keep release and diagnostics FPS separate; do not compare debug capture/DRED slowdown with normal release. Change one flag/patch at a time and retain an executable+cache separation across source revisions.

## Promotion gate

A green CI result **never** proves gameplay. Unit/WARP pass does not prove RTX 5090 execution; RTX 5090 synthetic test does not prove lighting correctness; another developer's gameplay does not prove ours. Record outcome in EVIDENCE_LOG, and do not merge experimental runtime behavior without owner authorization and the scope-appropriate test gate.
