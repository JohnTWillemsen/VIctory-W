# E161 — Direct owner RTX5090 same-binary DXGI ON/OFF comparison

**Date:** 2026-11-27 Phoenix (E127 UTC 2026-11-28). [Draft PR60](https://github.com/JohnTWillemsen/VIctory-W/pull/60), **actually executed Rust/PowerShell code SHA** `01064d5a556d7babf7f15b4b489ed486d397d6e2` in **both** sessions. The candidate code is from the same exact-source Windows [release CI 46106490410](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46106490410), whose artifact hash `1f0f0e3247bd2dfd66b427eb668f526bf66ebc82579e5e9713510c7a371523a2` **matches both user-uploaded E127 fixed-field source_executable_sha256 values**. Do not substitute the later documentation-only PR branch HEAD when reproducing.

## Matched provenance and outcome — E127 (two private-safe anonymous reports)

| Fixed field | Opt-in DXGI ON | Default DXGI OFF |
| --- | --- | --- |
| Run ID | `e127-20261128043635-abc825` | `e127-20261128050642-013a32` |
| `dxgi_tearing_requested` | ON | OFF |
| `dxgi_tearing_feature_query` | FEATURE_SUPPORTED | FEATURE_UNSUPPORTED_OR_OFF |
| `dxgi_tearing_fallback_marker_count` | 0 | 0 |
| `state`, `exit_code` | FINALIZED, 0 | FINALIZED, 0 |
| Elapsed | 350 sec | 366 sec |
| `human_observed_visual`, `human_observed_controls` | World, Yes | World, Yes |
| `observed_host_gpu` | HOST_RTX5090_NAME_MATCH | HOST_RTX5090_NAME_MATCH |
| Host 5090 event count / other-adapter events | 2 / 0 | 2 / 0 |
| Bounded logs, inspected lines | 2 / 7,000 | 2 / 7,000 |
| Device removed / hung / DRED / slow submission / GPU failure / warmup text marker counts | All 0 | All 0 |
| Executable SHA256 | `1f0f0e3247bd2dfd66b427eb668f526bf66ebc82579e5e9713510c7a371523a2` | Same `1f0f0e3247bd2dfd66b427eb668f526bf66ebc82579e5e9713510c7a371523a2` |

The OFF `FEATURE_UNSUPPORTED_OR_OFF` is intentionally a **combined code** when the feature was not requested; it does **NOT** mean the RTX5090 lacks the feature. ON `FEATURE_SUPPORTED` plus no fallback marker is not proof that every frame used tearing. The common SHA and same mode/source configurations establish strong **binary-level A/B authenticity**, not equal scene workloads.

## E141 offline performance-window summary (not individual-frame 1% lows)

Both reports' E141 `source_run_id` matched the corresponding E127 run. `status=SCENE_LIKE_SAMPLES_FOUND` and `scene_heuristic=draws_per_frame_gte_100`. Both had 2 log files, no skipped/truncated files or meterless files. Log numbering is by **most recently modified**, not guaranteed actual scene/phase order.

| Fixed-field statistic | ON | OFF | OFF minus ON |
| --- | ---: | ---: | ---: |
| Lines scanned | 33,071 | 36,312 | +3,241 |
| All meter windows | 56 | 60 | +4 |
| Scene-like windows | 38 | 41 | +3 |
| Scene-like FPS p10 | 3.5 | 11.6 | +8.1 |
| Scene-like FPS p50 | **23.4** | **28.3** | **+4.9** (20.9% higher observed) |
| Scene-like FPS p90 | 29.1 | 34.1 | +5.0 |
| Scene-like frame-window ms p50 | 42.8 | 35.3 | -7.5 |
| Scene-like frame-window ms p90 | 281.7 | 86.1 | -195.6 |
| Scene-like CPU prepare ms p50 | 27.2 | 26.7 | -0.5 |
| Scene-like copyback ms p50 | 5.5 | 5.1 | -0.4 |
| Scene-like host-GPU-associated ms p50 | 0.0 | 0.0 | 0.0 (not GPU utilization) |
| Scene-like draws/frame p50 | **5,288.5** | **4,352.0** | **-936.5 (~17.7% fewer)** |
| Larger `log_1` scene-like windows | 33 | 36 | +3 |
| Larger `log_1` FPS p50 | **25.3** | **29.7** | **+4.4** (17.4% higher observed) |
| Larger `log_1` first-half FPS p50 | 14.7 | 26.7 | +12.0 |
| Larger `log_1` last-half FPS p50 | 27.4 | 30.6 | +3.2 |
| Smaller `log_2` scene-like windows | 5 | 5 | 0 |
| Smaller `log_2` FPS p50 | **3.5** | **4.6** | +1.1 |
| Smaller `log_2` CPU prepare ms p50 | 41.3 | 58.7 | +17.4 (worse OFF) |

**Interpretation:** Both runs achieved owner-reported World + Controls Yes, exit 0 and no recognized crash/fallback markers. In these two samples, **OFF had higher median and lower-tail multi-second FPS window measurements**, particularly the overall p10, frame-window p90, and larger-log median. However, **OFF still includes a very slow smaller log** (5-window FPS median 4.6), and **the draw-call median differs by ~18%**. Different cache warming, menu/scene phases, scene complexity and time since launch can change the results. The display of medians and differences is **descriptive evidence only, not a causal estimate that OFF improves FPS by 20.9%**. E141 window percentiles are **NOT individual-frame percentiles, true 1% lows, GPU utilization, or a direct scene-matched benchmark**. Neither run demonstrates full-game completion, graphical parity, or long-term stability.

## Engineering conclusion and next priority

- **Keep the experimental `VICTORY_TEARING` default OFF**. No evidence justifies promoting ON as a speed optimization or merging PR60 to main. Main remains owner-confirmed E139 3D room baseline; PR50 CPU experiment 29.1 FPS larger-log median still lacked direct World/Controls confirmation and must not be conflated with E161.
- The **strongest reproducible finding is a persistent slow log in both ON/OFF**, despite normal process exit, verified RTX5090 selection, and real 3D+control acceptance. Work next on read-only source review of CPU prepare / frame pacing, per-phase logging, warmup/churn, and bounded offline synthetic tests, rather than repeatedly crashing the user's hardware.
- To isolate the presentation setting causally, would need matched scene/camera/movement/draw load, cache stabilization and multiple A/B trials, or finer local performance traces with strong privacy redaction. **Do not require a new hardware run merely to affirm the outcome.** If a later test is warranted, use exact code SHA `01064d5a556d7babf7f15b4b489ed486d397d6e2`, verified source-built SHA, isolated worktree, explicit non-admin `PLAY` and fixed-field ZIP-only output, no title assets/logs on GitHub.
- The E127 fixed-field ZIPs and E141 summaries remain in this conversation only, not committed to this public repository. This report includes no title-derived file names, personal Windows paths, screenshots, saves or raw logs.

[Previous E160 ON-only acceptance](E160-RTX5090-DXGI-ON-ACCEPTANCE.md).