# CURRENT STATE — VIctory-W NVIDIA-based source (dated snapshot)

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
