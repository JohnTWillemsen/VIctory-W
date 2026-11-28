# CURRENT STATE — VIctory-W NVIDIA-based source (dated snapshot)

**E142 newer:** E141 owner ZIP: log_1 90 scene windows median **10.9 FPS** (first 11.7, last 9.6); log_2 5 windows **3.6 FPS** (first 3.7, last 3.6). No recovery in long log, so warmup alone unproven; no per-frame 1% lows or GPU utilization. **P0 prioritize perf** and upstream [PR614](https://github.com/trustno1-coder/VIctory-NVIDIA/pull/614) in isolated branch, not exploration beyond cell. Evidence E142/E143, decision D056.

## E140 measured severe interior lag — E141 offline per-log follow-up

Owner E140 fixed-field ZIP from the existing E127 RTX5090 session reported **95 scene-like multi-second FPS windows (2 local log files), FPS p50 10.3, p10 4.0, min 2.9, p90 18.7; mean frame-window ms p50 96.9 / p90 249.4; CPU preparing 25.2ms, GPU-associated 30.5ms, copyback 5.0ms medians.** Not individual frame times, true 1% lows, hardware GPU utilization or a definitive CPU-vs-GPU diagnosis. First controllable 3D interior E139 remains VERIFIED, but performance is severely impaired. **Defer wider exploration.** [PR48 E141](https://github.com/JohnTWillemsen/VIctory-W/pull/48) extends the already merged E140 offline privacy-safe analyzer to compare separate logs/early vs late windows and evaluate one-time NVIDIA warm-up hypothesis, without launching game or changing runtime. No per-log owner data yet; exact-head CI and owner E141 ZIP required before performance root-cause claims. See [E141 research](../research/E141-OFFLINE-PER-LOG-COMPARISON.md), E140/E141 evidence and D055. Source/Clippy/GPU synthetic statuses remain independently red as previously recorded.


## E139 UPDATED FIRST HARDWARE ACCEPTANCE — owner confirmation on 2026-11-27 Arizona

**FIRST REAL RTX5090 CONTROLLABLE RENDERED 3D INTERIOR = CONFIRMED.** Following the E138 ZIP's original `human_observed_visual=Unknown` and `human_observed_controls=Yes`, the owner explicitly confirmed seeing a rendered 3D interior room/cell and moving the player through it. This direct follow-up upgrades **initial indoor World+Controls acceptance only**, without rewriting E138 ZIP or implying outdoor/open-world access, wide scene progression, fidelity, sustained play, or overall stability. The first session ran a source-matched NVIDIA-v8 binary SHA-256 `25100c5247e23ac2f39fd10cf7017ddaaab2dd56a9c60a1dda18c3e89e73c84f` from clean source main `8caccae47243cad361038bab4d4d4025f90ccc82`; RTX5090 was the selected host adapter, exit code 0 and 0 recognized GPU fault markers. Original ZIP's `elapsed_seconds=26020` is invalid, inflated by Phoenix UTC offset; reporting-only [PR45](https://github.com/JohnTWillemsen/VIctory-W/pull/45) fixes calculation. E138 original and E139 owner follow-up are separate append-only evidence rows. No need to rerun dangerous GPU test merely to answer visual question. **Next:** investigate wider scene progression, renderer correctness and measured stability; check live `main` before use.


## First real owner RTX5090 report — E135–E138 (2026-11-27 AZ)

The owner E135 inspection showed an existing **empty** `C:\\VIctory-NVIDIA` folder; the E136 fixed-field report then **verified a clean clone** of the same GitHub `main` at `8caccae47243cad361038bab4d4d4025f90ccc82`. E137 verified the matching [GitHub Actions source-built artifact](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46089270184), binary SHA-256 `25100c5247e23ac2f39fd10cf7017ddaaab2dd56a9c60a1dda18c3e89e73c84f`, and anonymous PowerShell self-test PASS. Old checkout and title files were not moved by these steps.

**FIRST OWNER GPU SESSION NOW VERIFIED:** E127 ZIP (not committed) was `FINALIZED`, `exit_code=0`, selected real host RTX5090 (2 adapter events, zero other), zero recognized device removed/hung/DRED/pagefault/slow submission/GPU failure markers. However it reported `human_observed_visual=Unknown`, `human_observed_controls=Yes`. **World+Controls gate remains UNKNOWN, NOT proven playable.** Ask whether the owner saw and moved within a rendered 3D world or only controlled menus. No new risky game run needed to clarify.

**E138 timekeeping bug:** The anonymized `elapsed_seconds=26020` is invalid; UTC run ID started at 01:24:17 and checkpoint was 01:37:58, a ~821-second interval, not a measured gameplay duration. [PR45](https://github.com/JohnTWillemsen/VIctory-W/pull/45) fixes offset-naive UTC arithmetic. The source [main Windows E127 CI](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46089270184) release and privacy fixture PASS, **three inherited GPU synthetic tests FAIL**, and strict Clippy still FAIL. Verify later CI and live main SHA, never claim global green CI.


**Checkpoint:** 2026-11-27 America/Phoenix. **Live GitHub overrides this snapshot.** Canonical complete overview: [HANDOFF.md](HANDOFF.md).

## Source and preserved history

- Repo: [JohnTWillemsen/VIctory-W](https://github.com/JohnTWillemsen/VIctory-W), default branch `main`; last verified SHA `88a60ea1d26664e9c04f184da6db153c0c3cde0c`. A changed main SHA is expected after new work—review commits, don't assume a pinned SHA is permanently current.
- The user approved and completed an entire runtime/launcher switch to [trustno1-coder/VIctory-NVIDIA v2026.11.27.8](https://github.com/trustno1-coder/VIctory-NVIDIA), pinned original source `64d4931b3dd90305134512b805fc98f04119fb6e`. [PR37](https://github.com/JohnTWillemsen/VIctory-W/pull/37) and [PR38](https://github.com/JohnTWillemsen/VIctory-W/pull/38) **merged**. Historic old source `archive/pre-nvidia-foundation-20261127` at `63bcca43c6a00a758510398fa43096ce7e4f7df0`. No AMD-derived experimental source patch is automatically active.
- User's agreed Windows workspace: `C:\VIctory-NVIDIA` (fresh clone of the **same GitHub remote**, not a second GitHub repo) and `C:\VIctory-NVIDIA-Tests` (new sessions/private report root); old `C:\VIctory-W` untouched; game files remain where they are. Use [LOCAL_WORKSPACE.md](LOCAL_WORKSPACE.md), verify `origin`, branch and status, and pass `-ReportRoot 'C:\VIctory-NVIDIA-Tests'`. **Actual folder creation not independently verified.**

## Verified source checks and their limitations

On 2026-11-27, exact [main E127 CI 46084957654](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46084957654): Windows release build **PASS**, game-free anonymous report PowerShell fixture **PASS**, full GPU synthetic tests **FAIL** (three indirect-budget/depth-bounds tests). Overall workflow **FAIL**. [Original main CI 46084957675](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46084957675) strict Clippy **FAIL** (pre-existing upstream warnings). Never merge those outcomes into one misleading `green CI`.

Historical source-built game launcher executable [artifact 15237799712](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46084406387/artifacts/15237799712) SHA-256 `4baf4fbcd3a5801d5c9f73c7c45e3e3299f435ff748eb28b49573d29e4aea9d3`; hash only valid for that exact binary, and artifact may expire. **No positive owner RTX5090 world+controls observation has been uploaded for NVIDIA v8. Gameplay = NOT_RUN/UNKNOWN**, not a successful port.

## Current task and next agent action

**First** requery live `main`, PRs and CI. **Then** follow [E127 testing/upload protocol](../research/E127-TESTING-AND-UPLOAD-PROTOCOL.md): one consent-gated actual host adapter + rendered world + input owner checkpoint (only when useful); one privacy-safe anonymous ZIP, never raw logs. Diagnose existing three source synthetic failures separately, likely WARP/hardware-feature dependent but not yet established as harmless. Do not ask to repeat obsolete E087/E091 multi-ZIP experiments or reintroduce patches from the old source.

## E131/E133 merged and E132 deferred

**E134 latest verified main:** `88a60ea1d26664e9c04f184da6db153c0c3cde0c` (2026-11-27 America/Phoenix). [E131 PR41](https://github.com/JohnTWillemsen/VIctory-W/pull/41) merged `d7f0ae3c`, preserving `VICTORY_HOME` and `VICTORY_ADAPTER` across NVIDIA `play::prepare`. Its [Windows CI](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46088218108) passed the release executable build, E127 privacy fixture and new Rust regression; **same 3 inherited GPU synthetic failures** remained. [E133 PR43](https://github.com/JohnTWillemsen/VIctory-W/pull/43) merged `88a60ea1`: E127 conditionally scans a bounded head for initial RTX adapter evidence after scanning the bounded crash tail; [3600-line private-path-safe fixture](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46089003044) passed. [PR42](https://github.com/JohnTWillemsen/VIctory-W/pull/42) is still a **draft** partial Clippy cleanup; ~26 further inherited GPU lint errors were revealed and should not delay actual GPU acceptance. **No owner RTX5090 World+Controls result or new Windows folder creation has been verified.** Current GitHub SHA and CI must still be rechecked.

## Durable records and unresolved concerns

- [Evidence log](EVIDENCE_LOG.md): append-only E001 onward; latest evidence through **E133**; never erase old failures.
- [Decisions](DECISIONS.md): append-only D001 onward; latest decision **D052**. The full NVIDIA switch supersedes earlier reference-only/AMD choices.
- [TASK_QUEUE.md](TASK_QUEUE.md) is a compact current task index, not a branch lock. Old long backlog preserved in Git history at baseline `6b6bdf4219fc31eb35a8411e1b76fa9c03b2b1b7`.
- Repo was **PUBLIC** at checkpoint; reverify visibility before sharing. No game data/raw logs/private paths on GitHub.
- A reboot may interrupt the monitor; the one ZIP is checkpointed and can be recovered from local data, but no script guarantees a write through power loss.

**New-session handoff:** [NEW_SESSION_PROMPT.md](NEW_SESSION_PROMPT.md), [HANDOFF.md](HANDOFF.md), [AGENTS.md](../../AGENTS.md). Never trust this file in preference to newer GitHub evidence.
