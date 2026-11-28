# E151 — First NVIDIA PR614 candidate: owner E127 safety and E141 FPS comparison

**Owner evidence:** Two uploaded, one-member fixed-field E127/E141 ZIPs from an already-completed Windows RTX5090 test. Local/private originals stay out of the public GitHub repository; only the independently inspected numeric/enum fields are recorded here. Source SHA and executable provenance match [PR50](https://github.com/JohnTWillemsen/VIctory-W/pull/50) exact draft head `dd4b1146592909ad26730bc9864d9b25d1f211b2`, Windows [run 46098122107](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46098122107), `victory.exe` SHA256 `e4a9ee63e21b7b77daa6620c2eddeda31a94e1aa01477614cd7be045e62529ac`. This candidate's three Rust CPU hot-path changes are **not merged into main**.

## E127 safety and gameplay interpretation

- Run ID `e127-20261128024702-726c06`; `FINALIZED`, exit code `0`, elapsed 336 seconds (UTC offset math corrected by PR45), E127 checkpoint `2026-11-28T02:52:39Z`.
- `observed_host_gpu=HOST_RTX5090_NAME_MATCH`, 2 RTX5090 host adapter events, zero other adapter events. Source-default frame generation and console profile, debug layer off, native BVH builder off.
- E127 scanned 2 files / 7,000 log lines for fault markers: zero device removed, hung, DRED/pagefault, slow host submission or host GPU failure **among scanned lines**; cannot exclude hidden, unrecognized or unscanned failures.
- **CRITICAL:** `human_observed_visual=Unknown` and `human_observed_controls=Unknown`. The numeric logs show scene-like drawing activity but do not establish the 3D environment rendered correctly, that the player moved, or that all required effects displayed. Do not mark this PR50 candidate as playable/accepted without owner confirmation. The earlier PR50-absent main build **was** owner-confirmed to show a controllable 3D interior (E139); that is a different executable.

## E141 offline FPS results

E141 run ID equals E127 ID, `game_relaunched=false` for the offline audit, two private logs scanned / 34,267 lines, no skipped/truncated files. 53 total FPS sampling windows; 35 scene-like windows with `>=100` draws/frame heuristic. These are **multi-second average meter windows**, not frame-by-frame frametimes, 1% lows, thermal/power telemetry, confirmed scene identity, or actual GPU utilization.

| Measured value | Previous main E141 baseline | PR50 candidate E141 | Notes |
| --- | ---: | ---: | --- |
| Scene-like overall window count | 95 | 35 | Unequal recorded duration/window count |
| Overall scene-like FPS median | 10.3 | **28.4** | Descriptive only, 2.76x across pooled windows |
| Overall scene-like p10 FPS | 4.0 | **3.5** | Worse candidate lower tail; do not call stutter resolved |
| Overall scene-like p90 FPS | 18.7 | **33.3** | Candidate higher in fast windows |
| Overall scene-like frame-ms p50 | 96.9 | **35.2** | Window-averaged values, not per-frame p50 |
| Overall scene-like frame-ms p90 | 249.4 | **285.7** | Slow tail remains severe |
| Overall CPU preparation-ms p50 | 25.2 | **26.7** | No demonstrated CPU-preparation median decrease |
| Overall host GPU-associated-ms p50 | 30.5 | **0.0** | Timing source/synchronization unclear; not physical GPU utilization or proof GPU idle |
| Overall copy-back-ms p50 | 5.0 | **4.7** | Separate median; not additive |
| Scene-like draws/frame p50 | 3445 | **3870** | Scene heuristic only, not visual correctness |
| Longer log: scene windows | 90 | 30 | Ordered by modification time, not reliably launch order |
| Longer log: FPS median | **10.9** | **29.1** | **2.67x sampled median**; confounded by caches, scene, log window count |
| Longer log: first-half FPS p50 | 11.7 | **25.9** | Grouped within each log only |
| Longer log: last-half FPS p50 | 9.6 | **30.3** | Candidate improves later, previous log did not |
| Longer log: frame-ms p50 | 92.6 | **34.4** | Median of log-window averages |
| Longer log: CPU-preparation-ms p50 | 24.7 | **25.6** | CPU prep did not decrease substantially |
| Longer log: host GPU-associated-ms p50 | 30.7 | **0.0** | Requires code-path/timing review before assigning cause |
| Short log: windows / FPS p50 | 5 / 3.6 | **5 / 3.6** | No detectable short-log improvement |
| Short log: frame-ms p50 | 280.7 | **278.3** | Severe slow windows persist |

Candidate all-window FPS p50 is 30.8 (includes menu-like windows); **do not** use this as the gameplay FPS claim. Candidate scene-like min 2.8 FPS and p10 3.5 versus baseline min 2.9/p10 4.0. A true smoothness gain is **not established** despite substantially higher median in the longer log.

## Interpretation and next engineering gates

1. **Immediate owner follow-up (no new game run):** Did this particular PR50 candidate show Lucia's cell as a valid rendered 3D scene, and could the character be moved? Record separate owner testimony while leaving E127's original `Unknown` fixed fields unchanged. If it was black/blank/incomplete, reject performance comparisons as possibly missing rendering work.
2. **Retain PR50 draft.** Source release and exact-head WARP focused regression PASS, but full GPU suite retains three previously failing synthetic tests and strict Clippy remains RED; no source changes promote to main on logging evidence alone.
3. **Investigate the median vs tail split.** Longer-log FPS 29.1 and p90 FPS 33.3 look promising, while pooled p10 3.5, slow 5-window log and frame-ms p90 285.7 are still unusably choppy. Determine first-run warmup behavior and what reports as `host_gpu_ms=0.0` before attributing improvement to CPU optimization. The two run samples were not controlled for scene, shader cache state, duration or thermal conditions.
4. If owner verifies rendered cell and movement, treat this as **candidate indoor 3D + FPS screening** only; prepare one deliberately matched, consented same-scene follow-up with proper frame-pacing and GPU/CPU telemetry, not deeper progression or blind merging. If E127/private logs are needed for deeper diagnosis, design **a new privacy-safe fixed-field** extractor; do not request unredacted logs/title files on GitHub.
5. The prior faulty PR merge artifact (15243877120) was correctly rejected before title launch; [PR53](https://github.com/JohnTWillemsen/VIctory-W/pull/53) globally fixed exact-HEAD packaging. This E151 run uses the corrected artifact (15244585832), source hash verified.

**Evidence status:** Real owner candidate run and numerical FPS sampling VERIFIED; visual and controls **UNKNOWN**; cause of FPS change **UNPROVEN**; broad GTA playability **UNVERIFIED**.
