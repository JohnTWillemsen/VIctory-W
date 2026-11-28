# E145 — Source-verified owner candidate A/B handoff

This **reporting-only** helper prepares a candidate from a specific GitHub Actions run, verifies the source manifest and binary SHA-256, and can invoke the existing E127 crash-checkpoint supervisor with mandatory literal `PLAY` plus E141 offline performance extraction once a game exits. **It does not integrate PR50 into `main` and does not change source-renderer logic or modify the user's game files.**

## Why

Owner RTX5090 E141 evidence from already-saved E127 logs: two distinct scene-like groups median **10.9 FPS** (90 windows, first half 11.7 vs last half 9.6) and **3.6 FPS** (5 windows). No performance recovery documented in the long log; cause still unknown. [Draft PR50](https://github.com/JohnTWillemsen/VIctory-W/pull/50) stages upstream NVIDIA [PR614](https://github.com/trustno1-coder/VIctory-NVIDIA/pull/614) CPU hot-path change. **Compiling and WARP tests cannot confirm speed or visual correctness** on owner's RTX5090; an A/B later must compare a source-verified candidate with preserved baseline E137.

## Modes and safety

Windows PowerShell 5.1 in a **normal, non-elevated** session, script `scripts/research/owner-nvidia-candidate-ab.ps1`:

- `-Mode SelfTest`: creates a disposable **synthetic** manifest + fake executable under the Windows temp directory, proves exact SHA/commit checks and wrong-commit/duplicate-hash rejection. Removes only its own temp fixture. Never launches title or calls GitHub.
- `-Mode Prepare -GithubRun <exact CI run ID> -ExpectedHeadSha <40 hex>`: checks the owner working branch is clean `main` of the existing GitHub remote, runs E127/E141 game-free privacy self-tests, downloads the GitHub Actions artifact `E127-source-built-nvidia-v8` into a unique folder **only under `C:\VIctory-NVIDIA-Tests`**, validates a single `victory.exe` and provenance file, source pin, exact commit, and executable SHA-256, writes fixed-field `E145-anonymous-preflight.txt` without paths/assets. Does **not** launch the game.
- `-Mode Run` with same two exact GitHub arguments: same preparation, then verifies one local existing game executable and archive, invokes **E127** (asks for literal **PLAY**; back up saves first), and once the game has finished runs **E141** offline on the newly created E127 session. **Upload only** the new `E127-anonymous-summary.zip` plus the new `E141-anonymous-perf-summary.zip`. The old E127 and E141 ZIPs remain untouched. Do not upload private source logs, saves, shaders, game assets or crash dumps.
- `-Mode Recover -RunFolder '<exact E127 run folder>'`: after reboot/crash, calls the existing E127 recovery and E141 offline analyzer from the named session without launching title. Local folder must be a direct child of the isolated test root, matching the fixed E127 run-ID format.

The script **never guesses a GitHub executable hash**, never downloads from an unverified publisher, never forces Git/reset on source, never uploads anything and never silently switches to an experimental branch on the user's PC. It fails closed for a wrong commit, wrong source pin, multiple/absent executables or manifests, wrong binary SHA, missing `gh`, unclean source or game path ambiguity.

## Owner test protocol

Only after the **exact-head** draft PR50 E144 focused tests pass (allowing only the explicitly known inherited depth-bounds WARP exclusion in focused jobs), GitHub E127 release build and E127 privacy fixtures pass, an artifact is present and the expected run ID and head SHA are recorded should the owner be invited to test. E127 full synthetic CI stays honest about the three existing inherited failures and strict Clippy remains separate.

Keep the first confirmed 3D interior as the **same-scene** test target for approximately a minute after startup/warm-up. The source has an automatic first-run shader warm-up/restart; don't count a menu, title screen or first short warm-up log as gameplay. The candidate's isolated home starts cold, so comparisons with E141 historical baseline are exploratory, not a rigorously controlled warmed-cache A/B. **Do not claim a performance improvement from a one-off sample;** any observed gain requires scene/setting/caches and frame-time context checked, then possibly a repeated paired baseline/candidate run.

Synthetic E145 Windows CI tests code parsing and provenance verification only; actual GitHub artifact download and game launch require the owner's computer and explicit `PLAY`.
