# Latest verified checkpoint — VIctory-W (NVIDIA-based)

**E142 latest:** E141 owner ZIP: two source logs; 90 scene windows **10.9 FPS median** (first half 11.7, last 9.6), other 5 windows **3.6 FPS** (first 3.7, last 3.6). Both very slow; **warmup alone not established**. These are multi-second averages, not true 1% lows or utilization. **P0 stop deeper exploration**, isolate performance candidate upstream [PR614](https://github.com/trustno1-coder/VIctory-NVIDIA/pull/614) before next consented GPU A/B. E142/E143, D056.

## E140 measured severe interior lag — E141 offline per-log follow-up

Owner E140 fixed-field ZIP from the existing E127 RTX5090 session reported **95 scene-like multi-second FPS windows (2 local log files), FPS p50 10.3, p10 4.0, min 2.9, p90 18.7; mean frame-window ms p50 96.9 / p90 249.4; CPU preparing 25.2ms, GPU-associated 30.5ms, copyback 5.0ms medians.** Not individual frame times, true 1% lows, hardware GPU utilization or a definitive CPU-vs-GPU diagnosis. First controllable 3D interior E139 remains VERIFIED, but performance is severely impaired. **Defer wider exploration.** [PR48 E141](https://github.com/JohnTWillemsen/VIctory-W/pull/48) extends the already merged E140 offline privacy-safe analyzer to compare separate logs/early vs late windows and evaluate one-time NVIDIA warm-up hypothesis, without launching game or changing runtime. No per-log owner data yet; exact-head CI and owner E141 ZIP required before performance root-cause claims. See [E141 research](../research/E141-OFFLINE-PER-LOG-COMPARISON.md), E140/E141 evidence and D055. Source/Clippy/GPU synthetic statuses remain independently red as previously recorded.


**Updated 2026-11-27 Arizona.** Read live GitHub `main`, open PRs and CI before new action. This is a dated snapshot, not an immutable branch lock. Canonical [HANDOFF](HANDOFF.md), [CURRENT_STATE](CURRENT_STATE.md), append-only [EVIDENCE_LOG](EVIDENCE_LOG.md) and [DECISIONS](DECISIONS.md).

## VERIFIED: FIRST RENDERED CONTROLLABLE 3D INTERIOR ON OWNER RTX5090

- Existing repository `JohnTWillemsen/VIctory-W` contains full NVIDIA-based source from `trustno1-coder/VIctory-NVIDIA v2026.11.27.8`, source pin `64d4931b3dd90305134512b805fc98f04119fb6e`. NVIDIA migration PR37/38 merged; old source archived `archive/pre-nvidia-foundation-20261127`.
- Owner E135: `C:\VIctory-NVIDIA` initially empty. E136: cloned **same GitHub remote** to `C:\VIctory-NVIDIA`, branch `main`, clean and exact SHA `8caccae47243cad361038bab4d4d4025f90ccc82`. Tests/reports in separate `C:\VIctory-NVIDIA-Tests`. Old `C:\VIctory-W` and title files untouched. Do not clone again over existing checkout.
- Owner E137: Windows source artifact [E127 run 46089270184](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46089270184), binary SHA256 `25100c5247e23ac2f39fd10cf7017ddaaab2dd56a9c60a1dda18c3e89e73c84f`, manifest and fixed-field PowerShell privacy SelfTest verified.
- Owner E138: executed one **real** source-matched E127 session, `FINALIZED`, `exit_code=0`, genuine host RTX5090 adapter name match, zero recognized device-loss/hang/DRED markers. Original ZIP recorded **visual Unknown**, **controls Yes**.
- **Owner E139 explicit follow-up:** confirmed seeing a **rendered 3D interior scene** and moving the character through it. **First RTX5090 controllable 3D interior World+Controls PASS by owner testimony.** Preserve original ZIP `Unknown` field unchanged; follow-up is separate evidence. NOT evidence of exterior/open world, further progression, exact visual fidelity or long-term stability.

## Source/CI and reporting distinction

- E131 merged [PR41](https://github.com/JohnTWillemsen/VIctory-W/pull/41): `VICTORY_HOME` and `VICTORY_ADAPTER` survive `play::prepare`. E133 merged [PR43](https://github.com/JohnTWillemsen/VIctory-W/pull/43): initial RTX5090 adapter evidence preserved from long logs. E134 continuity [PR44](https://github.com/JohnTWillemsen/VIctory-W/pull/44) merged at initial test source SHA `8caccae47243cad361038bab4d4d4025f90ccc82`.
- Original E127 ZIP `elapsed_seconds=26020` is **INVALID**: UTC session start and checkpoint are about 821 seconds apart, not verified active gameplay. E138 [PR45](https://github.com/JohnTWillemsen/VIctory-W/pull/45) reporting-only UTC fix **merged** as `b1209cb61cdad5cec7697a88e724e055134c68f6`, after exact-head Windows PowerShell syntax/privacy + Phoenix -07:00 12-second regression PASS. Do not re-run GPU game just to repair duration and do not silently rewrite old ZIP.
- On original game-tested main [E127 Windows run 46089270184](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46089270184), **release build PASS**, **anonymous reporting fixture PASS**, **three inherited GPU synthetic tests FAIL** and strict Clippy **FAIL**. Overall CI NOT green; source build or synthetic outcomes do not establish whole-game playability. [PR42](https://github.com/JohnTWillemsen/VIctory-W/pull/42) Clippy hygiene remains draft.

## Next engineering target

**P0:** progress beyond the first playable 3D interior, test transitions, scene/graphics correctness, and sustained controls without assuming broad success. Use one controlled E127 session only if genuinely needed, with owner `PLAY`, backup saves, and anonymous ZIP. **P1:** separately investigate inherited GPU synthetic reds; **P2:** carefully review upstream NVIDIA fixes. Continue all source/PR/CI work in GitHub, don't touch old local checkout. Report only sanitised enums/metrics, never title assets, raw logs or private user data.

**Handoff integrity:** `python scripts/check-continuity.py --smoke-clone` must pass in E129 CI. Evidence in E134–E139, decision D053–D054, [E127 protocol](../research/E127-TESTING-AND-UPLOAD-PROTOCOL.md), [LOCAL_WORKSPACE](LOCAL_WORKSPACE.md) and [NEW_SESSION_PROMPT](NEW_SESSION_PROMPT.md). Reverify live `main` SHA before distributing any executable: E138 docs PR46 may be newer than this checkpoint.
