# E164 — optional source-side pipeline wait timer (NVIDIA only)

**Date:** 2026-11-27 America/Phoenix. **Base:** GitHub NVIDIA `main` `ea186566a868430a51e416d4c94695f6aff3fce1`. Isolated draft test branch, no GPU title execution or runtime speedup claim.

## Why this bounded instrument exists

Owner RTX 5090 E161 same-executable DXGI ON/OFF observations (both rendered and controlled World/Yes) did **not** show an advantage for immediate presentation. E162 offline E163 investigation found severe slow meter windows (3–5 FPS) with **hundreds of pipelines still queued**, while CPU memory-copy time was also high; the difference is correlation, not evidence of which operation stalls the title recording threads.

In NVIDIA source `pipeline/make.rs`, `wait()` can wait on a shared 500 ms frame budget (and a separate screen-pass budget); `pipeline::making()` reports queue size, **not elapsed wait**. The existing `copystat::PipelineWaitUs` is diagnostics-feature-only, and source release E127 reports do not isolate waiting time.

## Narrow implementation

- Add `VICTORY_PIPELINE_WAIT_STATS=1` as **opt-in only**, default OFF. If unset, no additional per-wait atomic accounting is performed. No worker count, cache persistence, queue ordering, waits, render, graphics flags, save files or title folders are changed.
- A new private internal numeric sample counts wait calls and sums wait durations in microseconds across recording threads. The five-second FPS logger emits a **separate** structured numeric line only when opt-in is enabled; the original FPS line remains unchanged for E127/E141/E162 parsers.
- The two independent atomic swaps do not provide an atomic per-frame count/time pair. A wait near the sample boundary may land on either side. The sum across threads is **not a non-overlapping fraction of frame time**, not measured GPU time, and not proof that the queue caused stutter.
- `pipeline::make::tests::opt_in_wait_sample_counts_numeric_durations_and_drains` verifies numeric-only accumulation, reset and zero durations without a title or GPU. [E164 Windows workflow](../../.github/workflows/e164-pipeline-wait-metrics.yml) pins exact PR head and runs that test.

## Gate and next steps

1. Source-only review and exact-head Windows test must pass. Existing NVIDIA `main` and draft [PR60](https://github.com/JohnTWillemsen/VIctory-W/pull/60) stay unchanged; **do not merge** or tell owner to launch a new game on this probe.
2. A later **separate privacy-reviewed** offline E127/E141 analyzer could aggregate these new numeric values using fixed-field allowlist ZIPs. The current E162 reports cannot retrospectively yield wait duration.
3. Only if a causally informative owner test becomes necessary: first review the exact source-built artifact and safe opt-in pass-through, isolate home/cache, require normal non-admin PowerShell and literal `PLAY`, collect fixed-field summary only. Do not upload raw titles, pipeline logs, screenshots or cache contents.

**Rollback:** leave this draft unmerged; on any candidate build setting `VICTORY_PIPELINE_WAIT_STATS` absent has no extra counters or new output. No performance hypothesis has yet been accepted.

## VW-092 offline aggregation — read-only, no new GPU run

Added scripts/research/owner-nvidia-wait-audit.ps1 as a **separate** offline PowerShell 5.1 audit, checked by the exact-head E164 Windows workflow's synthetic SelfTest. This script:

- Reads at most six already-existing E127 private .log files (no file above 256 MiB; at most 250,000 lines per file) without launching or changing the game, saves, shader cache or runtime flags.
- Associates each numeric-only wait line with the **immediately preceding 5-second FPS meter** within a four-line gap in the **same** log. Reports numeric medians of summed title-thread waiting in scene-like (>=100 draws/frame), slow (<=10 FPS), and fast (>=20 FPS) windows.
- Exports exactly **one** fixed-field member, VW092-fixed-fields.txt, inside VW092-anonymous-wait-summary.zip, with run ID and numeric/enum fields only. Does not export private log lines, paths, filenames, shader hashes or game content. SelfTest uses synthetic data with injected private paths and checks ZIP membership plus fixed-field privacy.
- A report with status=NO_MATCHED_WAIT_WINDOWS **does not imply zero pipeline waiting**. It can simply mean the E164 runtime opt-in was absent, the build was different, a log was truncated, or no suitable pair was found.

**Critical:** Existing E160/E161/E162 owner runs used a different executable built before the E164 probe. Their old logs cannot produce these measurements, and **there is no reason to ask the owner to rerun them**. Before any eventual owner hardware test, confirm an exact source-built E164 executable, normal non-admin PowerShell and VICTORY_PIPELINE_WAIT_STATS=1 propagation through the authorized launcher; require explicit PLAY and upload only sanitized ZIPs. Mere completion of the offline analyzer is not authorization for such a run.

**Quantitative limitation:** Medians of five-second aggregate thread wait sums have no per-frame attribution. Thread wait durations may overlap; an apparent large wait sum does not mean that many milliseconds were added to FPS-window wall time. Unlike the E162 backlog, this gives a direct host-thread wait-duration measure, still not a causal mechanism by itself.

## Launcher opt-in forwarding — source-diagnosed limitation and isolated fix

NVIDIA `apps/victory/src/play.rs::prepare` discards every unlisted `VICTORY_*` environment variable. The original `KEPT` list did **not** include `VICTORY_PIPELINE_WAIT_STATS`, so simply setting it in an owner PowerShell console would silently collect no new wait metrics. Draft PR61 now explicitly preserves **only** this opt-in probe flag (not `VICTORY_PIPELINE_WAIT_MS`, `VICTORY_SCREEN_WAIT_MS` or unrelated tuning overrides), and adds a `play::tests::nvidia_opt_in_pipeline_wait_stats_survives_prepare_reset` Rust regression. The E164 exact-head Windows job tests the runtime accumulator, play setting propagation, and anonymous PowerShell report independently, all without a game. As of this source-only checkpoint, this latest-head gate still requires CI verification. No owner action or new title test is authorized.
