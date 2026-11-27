# E087 — persistent, automatically recovered GPU test reports (2026-11-27 AZ)

## User requirement

> Every physical game test must leave an **uploadable report**, whether the owner exits normally, the game crashes, or the owner closes the starting PowerShell window. Reports must not depend on the owner manually ending a stopwatch or copying private logs to a public repository.

This addresses the E085 failure: the **original E085 build-script summary** showed `BUILD_PASS_OWNER_DECLINED_PLAY` even though the owner **subsequently** launched the built exe directly and experienced an all-black frame, next-scene audio and a device-hung `0x887A0006`. The initial summary did not capture the subsequent title process. E087 always launches the title *under the report supervisor* and tracks that exact process; the user should not bypass the runner when a report is desired.

## Implementation

The standalone Windows PowerShell 5.1 script `scripts/research/owner-e087-durable-game-run.ps1` accepts the **existing already-built** E085 `victory.exe`, title executable path, mandatory binary SHA256 verification, test root, and optional scripted input. Physical GPU start requires RTX5090 identification and **typed uppercase PLAY** consent.

The launcher creates a new timestamped `E087-supervised-*` directory under `C:\VIctory-Tests`, writes private local JSON configuration, and **atomically creates `E087-anonymous-summary.zip` before spawning a process**. It starts a separate hidden PowerShell 5.1 supervisor by a `-EncodedCommand` containing only the script and run-folder paths; the parent launcher returns immediately. The child monitor redirects `victory` stdout/stderr to `PRIVATE-logs-do-not-upload`, enables `VICTORY_D3D12_DRED=1` and `VICTORY_D3D12_DEBUG=1` by default (diagnostics build required), and optionally repeats input from upstream #3392. GBV and timing are **not** enabled by default to avoid changing the GPU workload. Every 2.5 seconds while the title is running, the monitor persists an updated anonymous text checkpoint and ZIP via same-volume atomic replacement. On observed process exit (normal or nonzero), the monitor scans only *local* raw logs for fixed marker counts, records exit code and final outcome, and finalizes a ZIP. Closing the original PowerShell window does **not** stop the detached monitor. Killing the actual title process produces an exit/termination event that the monitor handles.

`-Mode Recover -RunFolder <run folder>` checks for a still-running monitor or game, refuses to declare completion when the game is still running, and reconstructs a post-mortem anonymous ZIP using existing local private stdout/stderr if both are gone but the previous record wasn't terminal. It explicitly says `EXIT_CODE_UNKNOWN`, not a fabricated reason.

The ZIP contains a **single fixed schema** `E087-anonymous-status.txt`: `format`, `status`, `outcome`, executable SHA256, title exit code if known, has-game-pid, elapsed time, last UTC heartbeat, fixed marker counts, `visual_world_verified=false`, and privacy statement. User must separately describe world visibility and movement; even a zero exit does not verify gameplay.

## Explicit technical limits

No script can guarantee a *terminal* report following total power loss, kernel crash, forced kill of the independent monitor and child with no recovery, disk failure, or malicious deletion. It **does guarantee an initial checkpoint when start reports success**, and periodically replaces it during title execution. Recovery is a deliberate next-invocation step when the OS does not permit a final write. Monitor PID reuse or a corrupt/lost config can complicate recovery. The initial checkpoint may say RUNNING/PENDING after a machine crash; never misinterpret as a successful title run. A delayed 2.5-second heartbeat is expected.

A `0x887A0006` marker may be repeated in separate private stdout/stderr; E087 counts **matching lines**, not unique device losses or causal shaders. DRED alone can still report no breadcrumbs. No proprietary title hash identifiers, raw shader content, screenshots, title paths, build logs or game data are copied to the ZIP or GitHub.

## Hosted validation (synthetic only)

`scripts/research/test-e087-supervisor.ps1` and `.github/workflows/e087-durable-supervisor.yml` run on Windows PowerShell 5.1, using the local `powershell.exe` as a pinned, hashed stand-in instead of a title or GPU. Scenarios:

1. Child exits `0` after printing synthetic audio; supervisor finalizes ZIP.
2. Child prints synthetic device-hung/slow submission markers, then exits nonzero `23`; supervisor preserves status, exit code and fixed counts.
3. A sleeping child is killed with `Stop-Process` from a separate process after the parent launcher has already returned; monitor finalizes ZIP.
4. Both monitor and child are intentionally stopped; explicit `-Mode Recover` reconstructs a ZIP with unknown exit code.

Tests also assert one `key=value` per line, raw local paths are absent from ZIP, and the initial ZIP exists immediately after launcher returns. Hardware/title outcome remains NOT_RUN for E087 until the user performs an explicitly consented GPU test. No change to VIctory-W main or existing E085 binary.

## Next owner instruction after green Windows CI

Download the pinned E087 script to a separate local .ps1, invoke it with the exact existing E085 SHA256 `e16739aaf86309d3668a9c8ae0b1321e107742b19614837900b994a09b2118cd`, E085 `PUBLIC-isolated-build\release\victory.exe` and the same local title. Type `PLAY` to opt in, note the run folder, and let the game run or crash as it will. Then upload only **`E087-anonymous-summary.zip`** (not raw logs or JSON) and describe the visible scene/audio. Retain logs privately for diagnosis as needed. Use `-Mode Recover -RunFolder` if Windows itself crashed or the monitor was killed. Never rerun the E085 clone/build.

### Pass criteria

A real report containing a terminal or clearly recovered status is available **without a successful game exit** and is not published to GitHub. Host CI must be green before giving the owner the next GPU command. This is a **test infrastructure milestone**, not a graphics or game playability fix.
