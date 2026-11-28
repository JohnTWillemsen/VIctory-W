# E141 - Offline log-by-log performance comparison

## E140 results from the prior owner E127 game session

The anonymized E140 fixed-field ZIP contains 123 multi-second FPS meter windows, 95 scene-like windows (>=100 draws/frame), from 2 private logs / 48,755 scanned lines. Scene-like FPS min 2.9, p10 4.0, p50 10.3, p90 18.7. Scene-like averaged frame duration p50 96.9 ms, p90 249.4 ms; CPU preparation p50 25.2 ms, host GPU-associated time p50 30.5 ms, copying back p50 5.0 ms, draws/frame p50 3445.

These are percentiles of *multi-second window averages*, not 1% lows, raw per-frame frame times or GPU utilization. CPU/GPU counters are not all additive. The source does not tell us which window is the actual room/cell; the owner independently confirmed a rendered and controllable 3D interior and experienced serious lag.

## Why further offline analysis

The NVIDIA source explicitly mentions a first-executable-run warm-up/restart problem (on author's RTX 5070 initial run was about 14fps). Combining two log files could hide that one file is a slow warm-up and the other normal, or both may be slow. E141 extends our already merged E140 offline analyzer to output separate, anonymous per-file and within-file metrics using the **same saved logs**. No title launch, unsafe GPU test, setting change or owner progression is necessary.

## Exact tool contract

Location: scripts/research/owner-nvidia-perf-audit.ps1, Mode Audit / SelfTest (same E140 file).
- E141 output is separate: E141-offline-<run-id> folder, E141-anonymous-perf-summary.zip with one E141-fixed-fields.txt member; E140 historical ZIP is untouched.
- Only read up to 6 private logs from the selected E127 run home/logs, each <=256 MiB and 250k lines. Do not read title assets, shaders, game binary or saves.
- Keep E140 pooled meter quantiles, and add anonymous log_1 through log_6: scene-like sample count, FPS median, first-half and second-half FPS medians, frame duration, CPU preparation, host-GPU-associated time and copyback medians.
- Log ordinals are **most recently modified first** and do not prove temporal launch order. Within each log the halves respect source line order. Missing data are UNKNOWN. Neither sample statistics nor file ordering proves shader warm-up or scene identity.
- Public ZIP contains ONLY predefined numeric fields, enum strings, opaque run ID and fixed provenance. Never include filenames, timestamps, paths, log lines, title content, crashes or dumps.
- Windows E140 CI PowerShell 5.1 SelfTest now creates two synthetic logs (13/25fps and 42/48fps scene-like with an additional menu-like sample), checks both per-log medians and half-window values, one ZIP member, and no private sentinel. No game launched in CI.

## Next action after CI and merge

Owner can update only clean C:\VIctory-NVIDIA main, run SelfTest then Audit with RunId e127-20261128012417-dba267 and ReportRoot C:\VIctory-NVIDIA-Tests. Upload ONLY E141-anonymous-perf-summary.zip. If both log groups stay near 10 FPS, focus on ongoing rendering overhead; if one is much faster, assess first-run warmup/restart. Do not request another GPU run just to retrieve metrics already in saved logs. The prior release/synthetic and strict Clippy status remain separate and do not change with this reporting work.
