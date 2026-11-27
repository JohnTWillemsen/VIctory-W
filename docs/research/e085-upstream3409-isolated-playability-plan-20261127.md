# E085 — isolated NVIDIA playability A/B against tested upstream PR #3409

**2026-11-27 MST. Source candidate exact head `1e25b230d6572f08e718a1df31a619bb43070481`; USER RTX5090 TEST NOT_RUN, PR3409 SOURCE AUTHOR-REPORTED TITLE WORLD, EXTERNAL RTX5070Ti GPU UNIT TESTS REPORTED.**

## Why we changed from E084 research to a possible playability test

User explicitly wants to **play**, not keep scanning logs. We discovered [upstream PR #3409](https://github.com/Marvisak/VIctory/pull/3409), which its author describes as a **game/title-run-validated merge of 27 open runtime PRs**, added in batches. Exact source `1e25b230d6572f08e718a1df31a619bb43070481` on upstream main `63bcca43c6a00a758510398fa43096ce7e4f7df0`. The author reports: 300-second title runs for each batch, scripted input through #3392, world/prison-yard reached at roughly 10k–11k draw calls per frame, no black picture past 150 s. These are **upstream author's claims**, not our owner GPU/title evidence; the run does **not** demonstrate successful playability on user's RTX5090.

Upstream #3409 has a green [check workflow 45907952641](https://github.com/Marvisak/VIctory/actions/runs/45907952641) at this head and independent [RTX5070 Ti report in PR #3409 comments](https://github.com/Marvisak/VIctory/pull/3409#issuecomment-7212813622): 902 passed / 0 failed / 10 ignored on a Windows 11 Blackwell wave32 GPU with six baseline-problem tests explicitly skipped, **not a title run on that machine**. One earlier report found an all-features compilation failure introduced by #450/#2962, and the upstream author resolved it in exact final commit `1e25b23`; no claim all other upstream forks' shader PRs were included.

Most usefully, upstream [PR #3392](https://github.com/Marvisak/VIctory/pull/3392) provides diagnostic `VICTORY_KEYS=10:Enter:300,20:Enter:300,200:W:6000`, with optional millisecond hold, and normal host keyboard/gamepad input. A scripted input test can test whether the game is only stalled at intro versus actually missing world graphics.

**Important source-stack distinction:** #3409 is based on upstream main + 27 selected PRs (including #3392 for input), **NOT our exact E075 six-PR source** (#439 wave64, #2118 BVH, #2098, #2626, #2464, #2628, with E065/E066/E074 diagnostics). No direct merge/transplant of 27 PRs into E075 was attempted; that risks incompatible shader/descriptor source, lost tested BVH protections and uncertain renderer behavior. E085 is a *standalone comparative branch*; if visually better on owner's RTX5090, future engineering can isolate relevant working fixes with controlled merge and tests. The prior 7 BVH refusals and 53/46 counts from E078 are valid only for that different build, not assumed for #3409.

## Proposed owner step — ONLY after hosted WinPS5.1 gate

`scripts/research/owner-e085-upstream3409-isolated-playability.ps1` takes existing private `-GameExe`, optional `-ScriptedIntro`, `-BuildOnly`, and `-ReportRoot C:\VIctory-Tests`. It creates a fresh timestamped work directory, clones only public source, verifies GitHub pull ref `refs/pull/3409/head` equals the exact pinned SHA, checks out detached and clean, then builds `cargo build --release --locked -p victory --features diagnostics` in a **new external Cargo target**. It verifies owner physical RTX5090 with `nvidia-smi`, checks local title startup archive, and **requires typed uppercase `PLAY`** before the title launch `victory run "$GameExe" --execute --console series-x`. Optional scripted intro does Enter at 10 and 20 seconds, holds W at 200 s for six seconds, while normal XInput/keyboard still work. **No source changes to main/E075, no title copies**, no writing to existing local VIctory source; original game may create its own cache/saves normally, so owner gets a warning and controls execution.

Build and game stdout/stderr and exceptions stay under `PRIVATE-raw-logs-do-not-upload` locally; only fixed anonymous counts/status, source and binary hashes in `E085-upstream3409-playability-*-summary.zip`. The owner also tells ChatGPT whether they saw the world and could move. No raw title logs, game paths, proprietary shaders, screenshots or title assets to public GitHub.

## Acceptance and next steps

1. Exact-head PS5.1 syntax/consent/privacy CI and host Windows diagnostics release **PASS** or failure explained separately.
2. Owner compiles isolated exact source once, chooses whether to launch (`PLAY` typed), and returns ZIP + visual observations privately. Numerical report cannot by itself show a rendered world.
3. If world is better than owner's E075, review which subset of #3409 fixes are relevant and reconcile a *new* supported combined PR, especially preserving #2118 BVH safety and #439 wave32 refusal. If title is still black, continue E084 source-level group sync with negative tests.
4. No direct main merge, no overwrite of previously compiled binaries, no claim runtime playable until owner confirms visuals and controllable input.
