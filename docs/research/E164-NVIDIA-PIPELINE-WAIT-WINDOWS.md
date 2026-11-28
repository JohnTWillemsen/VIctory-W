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

## Owner handoff: source-matched, one consent-gated RTX5090 run

`owner-nvidia-wait-owner.ps1` and `owner-nvidia-wait-audit.ps1` must be fetched from the **same immutable PR61 commit** with Git blob verification; do not switch the owner's clean `C:\VIctory-NVIDIA` main checkout to an experimental branch. `-Mode SelfTest` and `-Mode Prepare` never launch a title. `-Mode Run` temporarily enables ONLY `VICTORY_PIPELINE_WAIT_STATS=1`, invokes existing local E145 provenance/RTX5090 checks and E127 literal PLAY with save-backup warning, then automatically generates `VW092-anonymous-wait-summary.zip` plus existing E127 and E141 anonymous ZIPs. `-Mode Recover -RunFolder` uses the existing run after a crash/reboot without playing. Only upload these three **fixed-field ZIPs**, not private logs, game data, scripts, executables or caches. `NO_MATCHED_WAIT_WINDOWS` is not proof of zero wait time. New wrapper source requires exact-head Windows CI and build/provenance verification before any owner command. Three inherited full GPU synthetic failures and Clippy RED remain visible; passing E164 does not prove safety or FPS improvement.

## VW092-H1 — validated owner hardware wait/FPS evidence

Received 2026-11-27 Phoenix time. E127/E141/VW092 uploaded fixed-schema ZIPs, each exactly one expected text member, run `e127-20261128063033-7ce369`, no private log/archive membership. E127 exact executable SHA256 `d4963529a4197806d92864d5ef0461b3838029e90ca49e74460d9708b1351864` matches [source release 46114929298](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46114929298) at `3a830b3509491713d2c164e6ed12dcfc1805e778` and [focused E164 46114929321](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46114929321) passed. Original source/test warnings remain separate.

| E127 | FINALIZED, 285s, exit 0, real RTX5090 2/2 adapter events, zero recognized GPU faults, World Yes, Controls Yes |
| --- | --- |
| E141 | 45 FPS windows, 28 scene-like: FPS min 3.6, p10 6.0, p50 26.7, p90 31.8. Long log 24 scene windows p50 27.3, short log 4 scene windows p50 4.8; frame-window ms p50 37.6, p90 168.6, CPU prepare p50 26.3, copyback 5.3 |
| VW092 | 45 paired, 0 invalid/unpaired; 28 scene-like; slow <=10 FPS 4 windows median summed title-thread wait 7241.233ms /31.5 calls; fast >=20 FPS 21 windows median wait 59.289ms /6 calls; scene wait median 226.930ms |

**Interpretation:** Slow-vs-fast median cross-thread waits differ by ~122x. Concurrency means summed thread milliseconds are NOT elapsed frame time, GPU work or causal proof. Multi-second windows, not 1% lows or identified scenes. Existing logger does not differentiate normal pipeline budget 500ms/frame and screen-wide 10s budget; next work should classify that default-OFF rather than indiscriminately changing it. No new owner replay until independent source/CI confirms a useful narrow test. Never publish uploads, private logs or shaders.

## VW092-H2 — classify wait budgets without changing rendering

The owner H1 hardware session showed a ~122x association between summed waiting and FPS slowdowns but did **not** distinguish ordinary 500ms/frame pipeline waits from screen-wide up to 10s waits. H2 extends only the default-OFF numeric E164 probe: count ordinary and screen-wide wait calls/milliseconds separately, retain the original `calls` and `summed_wait_ms` fields on the same FPS-adjacent log line for old parsers, and retain the original GPU/wait logic. A focused Rust test verifies independent class accounting without a title. The offline fixed-field ZIP becomes `VW092-nvidia-wait-audit-v2` with numeric per-class medians for slow/fast scene-like windows; existing H1 logs without category fields retain their total wait measurements and classify as **UNKNOWN**, not zero. Windows PowerShell synthetic ZIP/privacy fixture is updated; the E164 exact-head CI tests both classes and privacy. Concurrent atomic boundary races, thread-overlap and missing scene identity remain limitations. No owner GPU repeat or FPS gain is claimed by this implementation.

## VW092-H3 — prepared local cache real RTX5090 evidence

Private fixed-field E127/E141/VW092 ZIPs all matched run `e127-20261128073423-f88740`, each exactly one allowed member, CRC verified. Same H2 source-built executable SHA256 `70e0bbe0ed7aa032a65495a99f26240310acdeeb1337927002b1a6460a801d60` from [Windows run 46117808321](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46117808321). E127 FINALIZED, exit0, 294 sec, RTX5090 adapter 2/2, 0 recognized GPU faults, World Yes, Controls Yes. E141 2 logs, 35047 lines, 45 FPS windows/28 scene-like; FPS min **14.9**, p10 **22.6**, p50 **32.9**, p90 34.6; frame-window ms p50 30.4/p90 44.8, preparing p50 24.0ms, copyback p50 4.6ms, draws/frame p50 5388. Per-log scene medians 32.8 over 23 windows and 33.6 over 5 (mtime order, not reliable warmup chronology). VW092 45/45 paired/classified, 0 invalid/unpaired/missing, 0 slow <=10FPS, 25 fast >=20FPS, scene wait-sum p50 **10.421ms**; slow-group medians UNKNOWN, not zero. Prior H2, **same binary** but different run: 22 scene-like windows p50 23.5, p10 3.5, min2.5, 7 slow; descriptive +9.4 sampled median FPS (~40%) but NOT a same-scene/cache-hit-verified causal speedup or guarantee of 30 FPS. H3 script passed prior private cache copy in `VICTORY_CACHE_DIR` and retained per-run `VICTORY_HOME`; logs neither count cache hits nor isolate restart/scene conditions. Earlier READY-only attempted session had no game logs and is excluded. Preserve all private ZIPs/cache/title data off GitHub. Next prioritize compatible private cache persistence with synthetic source/privacy tests before changing renderer budgets, workers or shaders.

## VW092-H4 — private cache handoff, source-pinned test plan (not a runtime fix)

PR61 stages `scripts/research/owner-nvidia-persistent-cache.ps1`, **no NVIDIA title data or real GPU operations in GitHub CI**. It is a bounded, explicitly opt-in owner-side cache workflow for the *already owner-verified H2/H3 exact executable* SHA256 `70e0bbe0ed7aa032a65495a99f26240310acdeeb1337927002b1a6460a801d60` (source head `5bc4a9d`, immutable Windows build run `46117808321`). Its sole accepted seed session is `e127-20261128073423-f88740`, from which the owner prepared local cache `VW092-warm-cache-5bc4a9d089f6`. It never copies title files or any Git checkout.

- `SelfTest` runs a fake E127 session, a tiny synthetic cache and negative fixtures for READY-only refusal, wrong executable, wrong GPU/driver, forbidden title-like cache material, and refusing an existing destination. No game.
- `Seed` privately confirms previous E127 exact executable, FINALIZED flag, successful exit and human World/Controls observations, enumerates cache contents without following reparse points, rejects logs/saves/executables/title assets and excessive size, SHA256-verifies the copy, and writes a private provenance JSON **outside** the reusable cache. Seed never overwrites an existing persistent cache.
- `Check` requires exact source/executable SHA, one positive physical RTX5090, the current driver version matching the seed, and a nonempty cache without forbidden material. A driver update is a fail-closed event, **not** automatic migration.
- `Run` is the only launcher path. It requires the pinned GitHub Actions run ID, prevents another game/VIctory process and concurrent use of this cache via a private file lock; temporarily sets `VICTORY_CACHE_DIR`, delegates to existing exact-source E145/E127 harness with literal `PLAY`, and restores the previous environment even on failure. Existing per-run `VICTORY_HOME` remains isolated. Crash/reboot recovery remains in E127; do not silently repeat an interrupted run.

**Limitations and gate:** The H3 E127 source report did not include its then-installed driver revision. Seed records the *current* RTX5090 driver, not proven source-session driver; renderer cache library itself also checks its own adapter/driver compatibility, and may refuse an incompatible blob. No CLI/API can infer an earlier driver version from the fixed-field reports. SHA verification shows the local copy matches its source bytes, not that those cache bytes can accelerate a different world scene. Neither full-game 30fps nor a cache-only causal gain was proven. Before owner command: exact-head E164 Windows PowerShell 5.1 parse and synthetic SelfTest **PASS**, artifact/owner-handoff and privacy checks verified, no source real title changes, and explicit PLAY consent. Full upstream synthetic 3 RED and strict Clippy RED remain tracked separately.
