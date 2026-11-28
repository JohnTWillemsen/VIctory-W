# E163 — RTX5090 E162 offline slow-frame root-cause research: queued pipelines and CPU copies

**2026-11-27 Arizona / 2026-11-28 UTC.** Source branch: [draft PR60](https://github.com/JohnTWillemsen/VIctory-W/pull/60). **Actually executed GPU code:** `01064d5a556d7babf7f15b4b489ed486d397d6e2` and source-built executable SHA256 `1f0f0e3247bd2dfd66b427eb668f526bf66ebc82579e5e9713510c7a371523a2`, matching [E127 Windows release 46106490410](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46106490410). E162 offline script **commit `53799b6002474a9651dbb7dc2efbcf86e5147942`**, [Windows PowerShell 5.1 exact-commit privacy selftest 46111444067](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46111444067) PASS. Both owner-uploaded E162 ZIPs were read individually with fixed-field allowlist validation; each contains exactly one `E162-fixed-fields.txt`, no raw log material.

## Source and E127 run identity checks

- **ON:** `source_run_id=e127-20261128043635-abc825`. E162 `game_relaunched=false`, 2 logs, 33,071 scanned lines, 0 skipped/truncated, 38 scene-like windows; matches original E141 ON 38 scenes.
- **OFF:** `source_run_id=e127-20261128050642-013a32`. E162 `game_relaunched=false`, 2 logs, 36,312 scanned lines, 0 skipped/truncated, 41 scene-like windows; matches E141 OFF 41 scenes.
- The anonymous reports are numeric **5-second FPS meter-window** aggregates. The slow threshold is <=10 FPS, fast >=20 FPS, scene-like >=100 draws/frame. Not frame-level 1% lows; no direct pipeline compile durations, GPU utilization, or frame-matched scene identity.

## E162 result table — medians of meter windows

| Metric | DXGI ON | DXGI OFF |
| --- | ---: | ---: |
| Scene-like windows | 38 | 41 |
| Slow windows (FPS <=10) | **12** | **4** |
| Fast windows (FPS >=20) | 23 | 31 |
| Slow-window FPS p50 | 3.6 | 3.6 |
| Slow CPU prepare ms p50 | 40.2 | 63.3 |
| Slow CPU memory copies ms p50 | **20.4** | **30.1** |
| Slow CPU texture refresh ms p50 | 2.7 | 8.9 |
| Slow residual CPU prepare ms p50 | 16.4 | 22.6 |
| Slow pending pipeline jobs p50 | **37.5** | **197.5** |
| Slow draws/frame p50 | 3,842.5 | 3,155.5 |
| Fast CPU prepare ms p50 | 26.0 | 25.5 |
| Fast CPU memory copies ms p50 | 11.2 | 12.2 |
| Fast CPU texture refresh ms p50 | 1.2 | 1.2 |
| Fast pending pipeline jobs p50 | **0** | **0** |
| All-scene CPU prepare ms p50 | 27.2 | 26.7 |
| All-scene memory copies ms p50 | 12.4 | 12.4 |
| All-scene texture refresh ms p50 | 1.4 | 1.3 |
| Larger log #1 slow window count | 7 / 33 | 1 / 36 |
| Larger log #1 slow pending jobs p50 | 1 | 24 |
| Small log #2 slow window count | **5 / 5** | **3 / 5** |
| Small log #2 slow pending jobs p50 | **664** | **371** |
| Small log #2 slow CPU prepare ms p50 | 41.3 | 67.8 |
| Small log #2 slow copy ms p50 | 22.2 | 31.5 |
| Small log #2 slow texture ms p50 | 5.8 | 9.9 |

Critical note: medians of individual components need **not** add up to the median total; per-log ordering is **most recently modified first**, not a chronologically identified scene stage. ON had only 12 slow windows, OFF had **four**, so medians on slow subset are especially sensitive to sampling.

## Source mechanism — evidence stronger than the counter label alone

1. [`crates/victory-gpu/src/pipeline.rs`](../../crates/victory-gpu/src/pipeline.rs) `making()` returns `make::waiting()`. [`pipeline/make.rs`](../../crates/victory-gpu/src/pipeline/make.rs) uses an atomic `WAITING` counter incremented when a **new pipeline job is queued** and decremented when its worker finishes `Pending::make()`, which calls `HostPipeline::new` then records library timing. It does **not** count intentionally left-out RT pipelines in that queue; `ready()` returns early for such passes and counts them separately. Therefore high E162 `pipeline_making` genuinely indicates queued/active host pipeline construction work; it is not just how many draws are discarded.
2. The source documents potentially costly shader translation and host-driver pipeline compilation. `VICTORY_PIPELINE_WAIT_MS` defaults to **500 ms per title frame**, with a shared thread budget, and screen-like passes get a separate longer budget. Earlier implementation notes describe long waits/dropped passes when hundreds are queued. Workers default to below-title priority and up to 16, with early/slow-compile priority handling. **Do not simply increase pipeline wait or worker priority/concurrency**: it may stall title threads or starve them, cause missing first-use passes, or increase memory pressure. Source-only tests are required first.
3. The E127 owner launcher explicitly creates a **new isolated `VICTORY_HOME` each E127 run**, while [`victory-core/config.rs`](../../crates/victory-core/src/config.rs) defaults cache/data folders under that home. [`pipeline/library.rs`](../../crates/victory-gpu/src/pipeline/library.rs) stores its serialized D3D12 library in `host-pipelines.bin` and its early list in `early-pipelines.txt` under a configured pipeline cache directory. **Likely repeated cold-cache launches** in these isolated tests. However, an explicit `VICTORY_CACHE_DIR` / `VICTORY_CONFIG` setting could override that default and was not captured in E127 anonymous reports; the actual cache topology is **UNVERIFIED**. Do not assert all runs certainly began cold, share or copy title-derived cache blobs, or change isolation without a reviewed safety design.
4. The observed 0.0ms `host_gpu` aggregate from E141 is a reported field, **not evidence that the GPU was idle**. Pipeline queue size is also **not compile duration**, and its coincidence with 3–5 FPS windows can reflect the same heavy loading/content phase rather than directly cause each stall. High memory copy work also occurs in slow windows (ON 20.4ms, OFF 30.1ms).

## Engineering verdict and bounded next step

**Supported:** Both modes have a subset of slow windows correlated with unfinished pipeline queue jobs and elevated CPU copy time. The very slow five-window logs in both modes coincide with **hundreds** of pending pipelines while faster windows have **median zero**. This is substantially more discriminating than blaming DXGI presentation; keep tearing **OFF by default**. No renderer fix or causal speedup is established.

**Next source-only tasks (VW-091):** Trace pipeline work-queue priority, early-start and saved-cache lifecycle; add synthetic regression/probes to validate queue accounting, prewarm reuse and reject starvation without proprietary shaders. If any future owner test is truly necessary, first propose a privacy-safe numeric metadata probe distinguishing cache cold/warm and pipeline library loaded/made counts; preserve isolated home, exact source SHA, explicit PLAY and no raw cache data uploads. **Do not request another GPU play session now**. Keep PR60 **DRAFT/unmerged**, original main at `ea186566a868430a51e416d4c94695f6aff3fce1`; inherited Clippy RED is independent.