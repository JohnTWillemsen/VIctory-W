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

## Hardware baseline actually observed on 2026-11-26 (do not extrapolate)

Owner-supplied Win11/RTX5090 driver 617.42 synthetic reports, clean `main` `63bcca43c6a00a758510398fa43096ce7e4f7df0`: `cargo test -p victory-gpu --lib --locked descriptor -- --test-threads=1 --nocapture` yielded **21 pass / 1 fail** (`dynamic_slots_are_held_until_released`). After exact-SHA upstream PR #3300 `01f91fea96de7c6fe47d5dd9f302e51a2403cac7` was fetched to a *separate detached worktree* (with a different Cargo target directory), the narrower `descriptor::host::tests::` selection yielded **16 pass / 0 fail / 217 filtered**, including the previous failure and newly added test. Neither result tested actual gameplay or visual output; not identical test filters. `cargo xtask policy` passed 191 files; `cargo fmt --all -- --check` found 925 existing formatting hunks across 66 source files in a clean main checkout.

For Windows PowerShell **5.1**, `Start-Transcript` did **not** capture Cargo's native test output reliably even though it captured a successful exit code. For subsequent owner runs, capture native stdout/stderr together in **cmd** and pipe into `Tee-Object`; always include the actual `running N tests` and `test result`, then the native exit code:

```powershell
$Log = "C:\vtw\verification\example-native-tests.txt"
& $env:ComSpec /D /C 'cargo test -p victory-gpu --lib --locked descriptor::host::tests:: -- --test-threads=1 --nocapture 2>&1' |
    Tee-Object -FilePath $Log
"Test exit code: $LASTEXITCODE" | Tee-Object -FilePath $Log -Append
```

Run from an **already verified, exact-commit, detached test worktree**, not casually from main; restore `CARGO_TARGET_DIR` in `finally`. Review logs for private local paths before sharing. Never commit native logs directly. Record original main and upstream test-filter differences honestly. See [EVIDENCE_LOG](EVIDENCE_LOG.md) entries E-011–E-014 and [CURRENT_STATE](CURRENT_STATE.md).

## Promotion gate

A green CI result **never** proves gameplay. Unit/WARP pass does not prove RTX 5090 execution; RTX 5090 synthetic test does not prove lighting correctness; another developer's gameplay does not prove ours. Record outcome in EVIDENCE_LOG, and do not merge experimental runtime behavior without owner authorization and the scope-appropriate test gate.
