# Active task queue — NVIDIA-based VIctory-W

**Dated:** 2026-11-27 America/Phoenix. **Live GitHub PR heads/branches override statuses.** The old ~112 KB E001–E125 task ledger from the AMD-source era is preserved at the immutable [pre-audit main commit](https://github.com/JohnTWillemsen/VIctory-W/blob/6b6bdf4219fc31eb35a8411e1b76fa9c03b2b1b7/docs/agents/TASK_QUEUE.md); this new file intentionally lists **only live source priorities**. Historical evidence is additionally preserved append-only in [EVIDENCE_LOG](EVIDENCE_LOG.md) and [DECISIONS](DECISIONS.md).

| Task | Status at dated checkpoint | Acceptance and next action |
| --- | --- | --- |
| **VW-072 — Full NVIDIA source replacement** | **COMPLETE, not merely a proposal.** Merged PR37/PR38; NVIDIA v8 is `main` `6b6bdf4`, old source archived. | Verify current main SHA on every session; no reimport. |
| **VW-073 — RTX5090 initial 3D room acceptance** | **E139 CONFIRMED** | Owner observed rendered controllable first interior. Broader world not yet tested; preserve main rollback. |
| **VW-074 — Inherited Windows GPU synthetic tests** | **E157 FIXED TEST-ONLY IN DRAFT PR56** | Original main had 3 WARP fixture failures; PR56 demonstrated 436 pass/0 fail/36 ignored, no runtime merge. |
| **VW-075 — Inherited strict upstream Clippy warnings** | **P2 / RED; draft PR42 reveals many further inherited GPU lint warnings.** | Fix justified style/test warnings on an isolated branch, no global suppressions or claims of playability. |
| **VW-076 — Maintain anti-stale continuity handoff** | **COMPLETE (E129):** canonical docs and fresh-clone smoke test merged through PR39; main continuity check green at that checkpoint. | Keep [HANDOFF](HANDOFF.md), CURRENT_STATE, LATEST_CHECKPOINT, NEW_SESSION_PROMPT and evidence aligned. Automated CI check must PASS. |

| **VW-077 — Isolate owner's new NVIDIA Windows workspace (E130)** | **Merged E130 / owner E136 clone verified.** Owner selected `C:\VIctory-NVIDIA` and `C:\VIctory-NVIDIA-Tests` while preserving old `C:\VIctory-W`. | Verify [LOCAL_WORKSPACE.md](LOCAL_WORKSPACE.md), E127 new report root, full prompt, CI, and first local clone output when owner provides it. Remote GitHub cannot confirm Windows folder creation. |

| **VW-078 — E131 preserve isolated home + RTX adapter** | **MERGED PR41 / Windows release and regression PASS** | Do not use pre-fix binary; owner E127 run completed and interior 3D movement confirmed by E139 follow-up. |
| **VW-079 — E133 long-log host GPU evidence** | **MERGED PR43 / synthetic 3600-line privacy SelfTest PASS** | Read bounded log head for adapter only when tail lacks event; anonymous ZIP only, no raw private logs. |

| **VW-089 — E157 WARP fixtures** | **[PR56](https://github.com/JohnTWillemsen/VIctory-W/pull/56) DRAFT** | [E127 46104177631](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46104177631): GPU 436/0, 36 ignored; source/privacy PASS. Strict Clippy RED; no renderer or GPU play, no owner-authorized merge. |
| **VW-090 — E161 owner ON/OFF comparison** | **PR60 DRAFT; same exe SHA, World/Controls YES both** | OFF sampled p50 28.3 vs ON 23.4; p10 11.6 vs 3.5, but ~18% fewer draws OFF; no proven causal gain. Default OFF. Severe low FPS persists, no merge. |
| **VW-091 — E163 pipeline queue/copy investigation** | **P0; offline evidence, causality unknown** | Slow queued jobs p50 ON/OFF 37.5/197.5, fast 0. Source-only cache/worker/copy tests next; no new gameplay. |

**Task ownership:** Never infer a task is unclaimed solely from this dated Markdown. Query open PRs, branch tips, recent main commits and Actions first. The original source and old experimental PRs are preserved for research but are **not** active Nvidia runtime changes. Use one focused branch/PR per task. No commits to `main` without owner authorization and exact-head review.

**Privacy:** No title executable, proprietary data, raw GPU logs, screenshots, identifying file paths or dumps in this PUBLIC repo. For owner tests accept only the fixed-schema E127 anonymous summary ZIP.

| **VW-080 — E138 anonymous elapsed UTC correction** | **[PR45](https://github.com/JohnTWillemsen/VIctory-W/pull/45) MERGED** as `b1209cb61cdad5cec7697a88e724e055134c68f6`; report-only change | Use offset-aware UTC time and Phoenix -07:00 regression; initial E127 elapsed_seconds inflated by 7h. Do not confuse source/report fix with gameplay. |
| **VW-081 — Expand beyond first rendered controllable room** | **P1 DEFER UNTIL LAG TRIAGED / INITIAL INTERIOR WORLD+CONTROLS PASS, BROADER GAME UNKNOWN** | Owner confirmed rendered 3D room/cell and movement in first E127 game. Next verify transition to further scenes, rendering correctness, controls and repeatability. No need to repeat prior initial hardware run merely for reporting. |

| **VW-082 — Quantify first playable interior lag (E140)** | **VERIFIED SEVERE / P0**: 95 scene-like aggregate windows, FPS p50 10.3, p10 4.0, frame-ms p50 96.9 and p90 249.4. | Source logs record median CPU prep 25.2ms, GPU-associated 30.5ms, copyback 5.0ms; not additive or actual GPU utilization. Do not explore new scenes until diagnosed. |
| **VW-083 — Disambiguate 2 logs and first-run warmup (E141)** | **MERGED PR48; OWNER E141 REPORT VERIFIED** | Compare per-log and early/late FPS/CPU/GPU metrics from same old E127 run; preserve prior E140 ZIP. Exact-head Windows E140/E141 PowerShell and privacy CI PASS; per-log E142 evidence obtained: log_1 90 samples at 10.9 FPS median, 11.7 first half to 9.6 last half; log_2 five samples at 3.6 FPS. No source performance fix yet. |

| **VW-084 — P0 NVIDIA CPU performance candidate** | **PR50 DRAFT / RTX5090 PERF MEASURED, VISUALS UNKNOWN** | E151 candidate log_1 30 windows p50 29.1 FPS vs baseline log_1 90 windows p50 10.9 FPS (2.67x). Different caches/samples; no proven matched scene or causal gain. Do not merge until owner confirms candidate scene and controls. |

| **VW-085 — E145 source-authenticated owner same-cell A/B handoff** | **MERGED [PR51](https://github.com/JohnTWillemsen/VIctory-W/pull/51); Windows fixture PASS** | Source-built artifact exact commit + SHA-256, isolated preflight, E127 literal PLAY and recoverable ZIP, then E141 auto performance ZIP. Do NOT give owner the risky candidate test until PR50 exact-head WARP regressions and release artifact pass. |
| **VW-086 — E146 Windows watch test gate** | **PASS / exact candidate** | Serial focused WARP 203 pass + 3 repeats [run 46098122094](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46098122094); earlier parallel watch flake documented, full suite 3 inherited reds unchanged. |

| **VW-087 — E149 GitHub artifact provenance** | **FIXED/MERGED PR53** | Old synthetic-merge artifact retired. New source-built candidate exact PR50 HEAD `dd4b1146592909ad26730bc9864d9b25d1f211b2`, E127 build [46098122107](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46098122107), SHA256 `e4a9ee63e21b7b77daa6620c2eddeda31a94e1aa01477614cd7be045e62529ac`; owner E151 run completed, visual/controls Unknown. |

| **VW-088 — E151 owner visual/control acceptance** | **P0 / AWAIT DIRECT OBSERVATION, NO RE-RUN NEEDED TO CLARIFY** | Owner E127 fields `visual=Unknown`, `controls=Unknown`; ask whether PR50 correctly displayed and controlled Lucia's 3D cell. Preserve 29.1 FPS median numeric evidence separately and confirm no rendering omission before promotion. |