# E105 — Preserve public D3D12 warning IDs in plain-text runtime logs (PR27 upstream candidate)

## Evidence
Owner RTX5090 E096 game crash from latest upstream #3409 `965d93823587932e8f40b152b8d4faab5f7a9c85`: E087 96s, `0x887A0005 DEVICE_REMOVED`; E091 two stopped breadcrumbs at 524/2972, 16 recorded in-flight DISPATCH ops (may be duplicates); E100 v2 reads 905 D3D12 lines, but **0/905 structured, native bracketed or #numeric IDs detected**; every D3D12 line contains a bracket, no '#' marks. Numeric warning-ID absence **not verified**. Need to examine source logger rather than keep changing offline parser.

## Root of diagnostic gap
`crates/victory-gpu/src/host.rs` `Host::log_messages` logs `tracing::warn!(id=m.ID.0, severity=m.Severity.0, "D3D12: {text}")`; the stored E087 text did **not** preserve those structured fields, leaving E100 no numeric source to analyze. The Windows D3D12 info queue *does* expose `m.ID.0` and `m.Severity.0` as public numeric values, but some tracing sinks only print message text.

## Strict, narrow patch
On top of staged exact source [PR27](https://github.com/JohnTWillemsen/VIctory-W/pull/27), helper `d3d12_report_line` puts `D3D12: id=N severity=N: ` **in the log message itself**, retaining the original structured `id` and `severity` fields and the same detail text as before. No GPU descriptors, shaders, loops, dispatches, barriers, view heaps, device selection, timeouts, title assets, game files or pipeline state changed. A Rust unit test proves numeric IDs survive into message text when only the message is captured. **This is a diagnostic fix, not a GPU-removal fix.**

## Source review / broader shader work
Latest upstream PR #3409 author corrected its successful 53-PR title runs as **AMD integrated GPU, not RTX 5070 Ti**, so we must not call it NVIDIA-validated. Independent upstream RTX5090 [issue #1586](https://github.com/Marvisak/VIctory/issues/1586) and NVIDIA [issue #71](https://github.com/Marvisak/VIctory/issues/71) report moving DRED stopped programs between mesh, indirect and compute passes, and independent unsuccessful Wave64/loop/heap/skip experiments. New [upstream PR #3546](https://github.com/Marvisak/VIctory/pull/3546) offers CBV/view correctness and dot-product/ROV improvements with its own CI SUCCESS, but **exact-context patch preflight against our PR27 source conflicts in `descriptor.rs` test hunk and `descriptor/host.rs` view hunk**; do not blindly merge a 6-file 699-line shader change. PR #3518 maps excess virtual descriptor slots but prior broader CI had failing tests. Keep all as candidates for isolated proof, not presumed crash fixes.

## Gates and usage
Windows `cargo clippy --workspace --all-targets --locked`, all-features Clippy, `cargo test --workspace --locked` on this exact PR head are mandatory. No GPU/title launch in CI. No new owner game run until a validated instrumentation binary and a meaningful controlled A/B can be offered, **other games closed** to remove a confound. Existing owner E087/E091/E100 private ZIPs remain separate and unchanged. Never publish raw private logs, shader IDs or title content. Do not merge into fork `main` without owner permission.
