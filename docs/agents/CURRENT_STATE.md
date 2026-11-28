# CURRENT STATE — VIctory-W NVIDIA-based source (dated snapshot)

**E155 COMBINED WARP TEST FIX DRAFT, NOT MERGED:** NVIDIA `main` `ea186566a868430a51e416d4c94695f6aff3fce1` at branch creation. [PR56](https://github.com/JohnTWillemsen/VIctory-W/pull/56) corrects **all three previously red WARP fixture assumptions** only (2 indirect REST budget cases and the separate depth-bounds `DepthEnable=true` case). Original main full GPU 433 pass/3 fail/36 ignored. Earlier PR56 exact-head [E152 46101133650](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46101133650) passed REST 0/1 and [E127 46101133726](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46101133726) reached 435 pass/1 fail; [PR58 E154 WARP 46103790287](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46103790287) depth-bounds variant **PASS**. Integrated PR56 **new exact-head full CI still pending**, strict Clippy independent RED. No game runtime modification. E155/D062.

**E151 now:** Owner E127 candidate RTX5090 report `FINALIZED`, exit 0, SHA256 `e4a9ee63e21b7b77daa6620c2eddeda31a94e1aa01477614cd7be045e62529ac`, selected GPU, no recognized fault markers; **visual Unknown, controls Unknown**. E141 longer log 30 scene windows p50 **29.1 FPS** vs prior 90 windows **10.9 FPS**; short 5-window log **3.6 FPS** in both. Promising 2.67x sampled median, **NOT controlled scene/fps benchmark nor playable visual acceptance**. PR50 remains DRAFT, main preserves owner-confirmed original controllable cell. See E151/D060 and [research](../research/E151-RTX5090-CPU-CANDIDATE-FPS.md).

## E140–E151 performance investigation (newest supersedes old snapshots)

Prior main RTX5090 E140/E141 longer log 90 scene-like windows, median 10.9 FPS (first half 11.7 / last 9.6), short log five windows median 3.6. New PR50 CPU candidate E151: longer log 30 windows median 29.1 FPS (first 25.9 / last 30.3), short log five windows median 3.6. Overall median 28.4 vs 10.3 FPS; pooled lower-tail p10 only 3.5 vs 4.0; potential startup stall still serious. These are aggregate samples, not frame-by-frame 1% lows, true GPU utilization or controlled same-scene test. GPU-associated `0.0ms` cannot be interpreted as GPU idle. **Visuals and movement unverified for this candidate**; do not automatically merge PR50. Preserve original E139 visible controllable interior baseline. D060 E151.

## E139 UPDATED FIRST HARDWARE ACCEPTANCE — owner confirmation on 2026-11-27 Arizona

**FIRST REAL RTX5090 CONTROLLABLE RENDERED 3D INTERIOR = CONFIRMED.** Following the E138 ZIP's original `human_observed_visual=Unknown` and `human_observed_controls=Yes`, the owner explicitly confirmed seeing a rendered 3D interior room/cell and moving the player through it. This direct follow-up upgrades **initial indoor World+Controls acceptance only**, without rewriting E138 ZIP or implying outdoor/open-world access, wide scene progression, fidelity, sustained play, or overall stability. The first session ran a source-matched NVIDIA-v8 binary SHA-256 `25100c5247e23ac2f39fd10cf7017ddaaab2dd56a9c60a1dda18c3e89e73c84f` from clean source main `8caccae47243cad361038bab4d4d4025f90ccc82`; RTX5090 was the selected host adapter, exit code 0 and 0 recognized GPU fault markers. Original ZIP's `elapsed_seconds=26020` is invalid, inflated by Phoenix UTC offset; reporting-only [PR45](https://github.com/JohnTWillemsen/VIctory-W/pull/45) fixes calculation. E138 original and E139 owner follow-up are separate append-only evidence rows. No need to rerun dangerous GPU test merely to answer visual question. **Next:** investigate wider scene progression, renderer correctness and measured stability; check live `main` before use.


## Source and preserved history

- Repo: [JohnTWillemsen/VIctory-W](https://github.com/JohnTWillemsen/VIctory-W), default branch `main`; last verified SHA `88a60ea1d26664e9c04f184da6db153c0c3cde0c`. A changed main SHA is expected after new work—review commits, don't assume a pinned SHA is permanently current.
- The user approved and completed an entire runtime/launcher switch to [trustno1-coder/VIctory-NVIDIA v2026.11.27.8](https://github.com/trustno1-coder/VIctory-NVIDIA), pinned original source `64d4931b3dd90305134512b805fc98f04119fb6e`. [PR37](https://github.com/JohnTWillemsen/VIctory-W/pull/37) and [PR38](https://github.com/JohnTWillemsen/VIctory-W/pull/38) **merged**. Historic old source `archive/pre-nvidia-foundation-20261127` at `63bcca43c6a00a758510398fa43096ce7e4f7df0`. No AMD-derived experimental source patch is automatically active.
- User's agreed Windows workspace: `C:\VIctory-NVIDIA` (fresh clone of the **same GitHub remote**, not a second GitHub repo) and `C:\VIctory-NVIDIA-Tests` (new sessions/private report root); old `C:\VIctory-W` untouched; game files remain where they are. Use [LOCAL_WORKSPACE.md](LOCAL_WORKSPACE.md), verify `origin`, branch and status, and pass `-ReportRoot 'C:\VIctory-NVIDIA-Tests'`. **Actual folder creation not independently verified.**

## Verified source checks and their limitations

On 2026-11-27, exact [main E127 CI 46084957654](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46084957654): Windows release build **PASS**, game-free anonymous report PowerShell fixture **PASS**, full GPU synthetic tests **FAIL** (three indirect-budget/depth-bounds tests). Overall workflow **FAIL**. [Original main CI 46084957675](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46084957675) strict Clippy **FAIL** (pre-existing upstream warnings). Never merge those outcomes into one misleading `green CI`.

Historical source-built game launcher executable [artifact 15237799712](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46084406387/artifacts/15237799712) SHA-256 `4baf4fbcd3a5801d5c9f73c7c45e3e3299f435ff748eb28b49573d29e4aea9d3`; hash only valid for that exact binary, and artifact may expire. **No positive owner RTX5090 world+controls observation has been uploaded for NVIDIA v8. Gameplay = NOT_RUN/UNKNOWN**, not a successful port.

## Current task and next agent action

**First** requery live `main`, PRs and CI. **Then** follow [E127 testing/upload protocol](../research/E127-TESTING-AND-UPLOAD-PROTOCOL.md): one consent-gated actual host adapter + rendered world + input owner checkpoint (only when useful); one privacy-safe anonymous ZIP, never raw logs. Diagnose existing three source synthetic failures separately, likely WARP/hardware-feature dependent but not yet established as harmless. Do not ask to repeat obsolete E087/E091 multi-ZIP experiments or reintroduce patches from the old source.

## Durable records and unresolved concerns

- [Evidence log](EVIDENCE_LOG.md): append-only E001 onward; latest evidence through **E133**; never erase old failures.
- [Decisions](DECISIONS.md): append-only D001 onward; latest decision **D052**. The full NVIDIA switch supersedes earlier reference-only/AMD choices.
- [TASK_QUEUE.md](TASK_QUEUE.md) is a compact current task index, not a branch lock. Old long backlog preserved in Git history at baseline `6b6bdf4219fc31eb35a8411e1b76fa9c03b2b1b7`.
- Repo was **PUBLIC** at checkpoint; reverify visibility before sharing. No game data/raw logs/private paths on GitHub.
- A reboot may interrupt the monitor; the one ZIP is checkpointed and can be recovered from local data, but no script guarantees a write through power loss.

**New-session handoff:** [NEW_SESSION_PROMPT.md](NEW_SESSION_PROMPT.md), [HANDOFF.md](HANDOFF.md), [AGENTS.md](../../AGENTS.md). Never trust this file in preference to newer GitHub evidence.
