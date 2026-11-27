# E127 — NVIDIA baseline: testing, crash recovery and upload protocol

**Effective source:** VIctory-W [NVIDIA migration PR #37](https://github.com/JohnTWillemsen/VIctory-W/pull/37); source pin `trustno1-coder/VIctory-NVIDIA v2026.11.27.8` commit `64d4931b3dd90305134512b805fc98f04119fb6e`. Old E087/E091 reports remain historical but are **not** the required upload format for new NVIDIA runs. Source build and owner gameplay are separate milestones.

## What we are measuring (not just compiling)

**Gate S0 — source:** imported runtime/launcher content is byte-identical to pinned upstream source except explicitly noted workflow(s). Original main is archived and retained.

**Gate S1 — build and safety:** [E127 Windows gates](../../.github/workflows/e127-nvidia-foundation-windows.yml) run independently:
- **release-build:** pinned Rust, locked release executable, SHA-256 manifest, no game files, one downloadable source-built executable artifact (does **not** run a game);
- **full-synthetic-tests:** original upstream complete Rust tests; report failures directly (GitHub's software/WARP GPU does not represent owner RTX5090);
- **report-harness-fixtures:** PowerShell parse and synthetic fake log/report tests. No game data, no executable launch.
The original upstream CI's strict Clippy is independently visible; do **not** suppress or mislabel its failures. A successful release build does not make the game playable.

**Gate H0 — on the owner's PC after a passing source build and reporting fixture:** Use only source-built `victory.exe` with recorded SHA-256 and `scripts/research/owner-nvidia-session.ps1` from the same exact PR branch commit. Do not execute anything copied from an unknown website. E127 Start refuses a mismatched executable hash or missing local title archive, verifies RTX5090 **presence**, asks for literal **PLAY**, then launches the **upstream built-in `victory play`** rather than our old Series X + D3D12 debug scripted command. It isolates `VICTORY_HOME` to a new local report directory and sets `VICTORY_ADAPTER=RTX 5090`; it clears debug layer, BVH builder and forced scripted keys, leaving the NVIDIA renderer's own game launch settings intact. RTX5090 presence via `nvidia-smi` is *not* a validated chosen GPU; only the real host D3D12 device's `adapter=NVIDIA ... RTX 5090` line in the new program log counts as positive adapter selection.

**Gate H1 — visible/control success:** Owner personally sees a correct 3D world and moves/controls a character, rather than only intro audio, black-screen loading, or `ExitCode=0`. Record `World` and `Yes` only if directly observed. Mark `Unknown` if crash/reboot prevents observation. **A game cannot be called playable from a source build, process running, audio alone or DRED count.** The default renderer uses an indirect-lighting approximation; this does not prove native-console ray tracing is correct.

## One session, one upload

The owner initiates a single E127 run **after backing up saves** and acknowledging that a GPU/driver or PC may crash. The launcher may offer optional NVIDIA Streamline DLL download/verification. Do not auto-consent to a third-party DLL, nor interpret the fork's **one-time shader warm-up restart** as a crash without evidence. Play until the intended point; exit normally if able. The script asks for simple `Menu`, `Black`, `World`, `Unknown` and `Yes`, `No`, `Unknown` observations.

- Upload **only `E127-anonymous-summary.zip`**, created inside `C:\VIctory-Tests\e127-...\`. A background Watch process refreshes the ZIP during play; `Start` places a first checkpoint on disk before launch. ZIP contains **one text member**, `E127-fixed-fields.txt`, with fixed field names and predefined enum/numeric fields. No free-text log fragments, user paths, shader dumps, screenshots, cache files, title executable hashes, proprietary assets, or system crash dumps. The source-built `victory.exe` SHA is public build metadata and is okay to include.
- **Never upload** `PRIVATE-never-upload`, `home` (all raw game logs, settings and cache), crash dumps, `crashes.log`, `victory*.crash.log`, executable or title archives. The public GitHub repo is **not a safe location** for raw logs. Keep them on the owner PC, under local control.
- If the app quits, the launcher asks the owner what was seen and controls; the watcher finalizes and prints the **single ZIP**. If the PC/monitor crashes first, the earlier ZIP checkpoint survives when the filesystem has flushed; no system can guarantee a write through a power loss. Run `-Mode Recover -RunFolder '<reported run folder>'` later to rebuild the one ZIP from **existing local logs only**, without launching the game; optionally pass `-Visual World -Controls Yes` if true.
- Important: a crash at 55s and an apparent 60s 'stable' run cannot be compared as performance without controlled profile and **observed world/controls**, and title visual artifacts must be examined locally rather than published to source control.

## Redacted schema and interpretation

`format=E127-nvidia-session-v1` contains source release, upstream SHA, generated source-executable SHA256, random session ID, status, signed exit code if known, elapsed seconds, checkpoint UTC, launcher/profile/debug/BVH switches, GPU detection enum and host-GPU event counts, log scan counts, GPU removal/hung/DRED/slow-submission/warm-up marker counts, human-observed visual and controls enums. The scanner reads only bounded tails of local logs and returns **numbers or fixed enums**, never the original lines. `host_5090_name_match` means a recognized **host device creation log**, not mere presence of a discrete NVIDIA card; if not recognized, **UNKNOWN**, not falsely 'wrong GPU'. Counts are log appearances and should not be interpreted as distinct physical GPU commands.

Future enhancements are bounded: compare author-pinned v7 vs v8 only **after** a verified first success/failure, capture driver version as sanitized numeric metadata if useful, and test one configuration change at a time. Do **not** pile shader/heap fixes onto a working NVIDIA reference. If the exact source fails, review local GPU selection, VS/D3D12 runtime, settings/cache, title integrity, hardware/driver events and reproducible stage before editing shaders.

## Next agent's checklist

1. Check the exact status and output of Windows E127 CI for migration PR37; fix any PowerShell syntax/fixture problems **before** owner action. Report all original upstream synthetic failures as failures. If a release build fails, do not distribute it.
2. Once an executable with SHA-256 exists, issue the owner only **one concise verified download and PowerShell command** with their known Windows file paths; never guess an artifact URL or SHA. A direct GitHub Actions artifact is available only if the job actually completed.
3. Receive one `E127-anonymous-summary.zip`; inspect sole member schema and update append-only evidence, decision, task and next checkpoint. Ask for further private data only if strictly needed and only through privacy-preserving fixed-schema output.
4. Preserve `main` and `archive/pre-nvidia-foundation-20261127` until user has accepted the new playable baseline; if the source change is merged later, maintain the archive/rollback branch.
