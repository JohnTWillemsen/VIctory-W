# E140 - Offline NVIDIA performance audit of the prior E127 run

Purpose: The first RTX5090 test reached a rendered, controllable 3D interior, but it was laggy. Do NOT request deeper progression merely to diagnose lag. Existing E127 fixed-field ZIP captures GPU selection, crashes and process exit; it omits FPS and CPU/GPU work estimates.

## Verified NVIDIA source behavior

The host runtime in crates/victory-gpu/src/host.rs, Meter::frame, logs INFO messages containing FPS, ms/frame, CPU preparing ms, GPU-associated ms, copying-back ms and draws/frame every few seconds. These are in the private VICTORY_HOME/logs files. They are NOT present in the E127 anonymous ZIP. Optional VICTORY_TIMER_LOG=1 produces more detailed pacing bands but was not set by the first E127 launcher. A release executable supports INFO, but extra GPU timing internals require diagnostics builds.

## Read-only command, after merged and local repository synchronized

In a normal, non-admin Windows PowerShell 5.1 shell:

& 'C:\VIctory-NVIDIA\scripts\research\owner-nvidia-perf-audit.ps1' -Mode Audit -RunId 'e127-20261128012417-dba267' -ReportRoot 'C:\VIctory-NVIDIA-Tests'

The script reads up to six existing *.log files in the selected E127 session's home\logs, each capped to 256 MiB/250,000 lines. It parses only numeric meter fields. It never relaunches the title, loads executable/assets, changes renderer settings, or writes into the original log folder. The output is a new one-member fixed-field ZIP under C:\VIctory-NVIDIA-Tests\E140-offline-<run-id>. Upload ONLY E140-anonymous-perf-summary.zip, NOT logs, title files, crashes or any private folders.

## Interpretation

All-window and scene-like-window aggregate statistics are separate. Scene-like means >=100 draws/frame, based on source observations about menu draw count (~10) versus game scene draw count (hundreds/thousands). This is a heuristic and does not identify the cell itself. Percentiles are over multi-second meter log windows, NOT individual frame-time samples, hardware GPU utilization, or real 1-percent lows. The GPU-associated timer is from host submission and does NOT establish GPU utilization. No recognized log sample means UNKNOWN, not fast/no lag. Do not claim statistics from a session where none were recorded.

If scene-like FPS is low and CPU preparation/copyback time high, investigate translation/submission/memory synchronization. If host GPU-associated time is high, investigate GPU workload/presentation. If logs are insufficient, the next experiment should be a short, explicit PLAY-consented cell-only instrumented run with optional VICTORY_TIMER_LOG or external GPU telemetry, not further game exploration and not blind renderer changes.

## Privacy and tests

Only fixed numeric fields, enums and the opaque existing E127 run ID are written to the shareable E140 ZIP. Never export raw lines, source file names, user paths, title assets, raw shaders or dumps. Windows workflow .github/workflows/e140-nvidia-perf-offline.yml runs PowerShell 5.1 parsing and disposable synthetic selftest. SelfTest includes private-path sentinel, two scene-like and one menu-like FPS window, verifies aggregate metrics, exactly one ZIP member and no private data. No game is launched by CI.

The first E127 NVIDIA report used main 8caccae47243cad361038bab4d4d4025f90ccc82, source-built executable SHA256 25100c5247e23ac2f39fd10cf7017ddaaab2dd56a9c60a1dda18c3e89e73c84f, and run ID e127-20261128012417-dba267. The owner later confirmed 3D interior world+controls; the original ZIP's visual Unknown remains unchanged. Test deeper graphics and scene transitions only when performance bottlenecks are better understood.
