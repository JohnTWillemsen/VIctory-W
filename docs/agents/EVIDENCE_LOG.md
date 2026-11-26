# Evidence log — append-only observations

**Do not replace failed rows or retroactively upgrade tags.** A correction is a later row referring to the earlier entry. Record date/time zone, exact SHA and linked CI or source/PR, environment, executed test or observation, outcome, limitation. This is **not** a scrapbook of speculative upstream claims or proprietary game data.

| ID / date | Repository + exact commit | Evidence type | Observation / method | Result and limitation | Link / next action |
| --- | --- | --- | --- | --- | --- |
| E-001 · 2026-11-26 (AZ) | `JohnTWillemsen/VIctory-W` `63bcca43c6a00a758510398fa43096ce7e4f7df0` | `SOURCE_READ` | Inspected fork default `main` and Marvisak upstream `main` GitHub commit and source files; both at the same SHA during inspection | Exact source baseline matched; **no gameplay or CI test executed in this verification** | [fork](https://github.com/JohnTWillemsen/VIctory-W/commit/63bcca43c6a00a758510398fa43096ce7e4f7df0), [upstream](https://github.com/Marvisak/VIctory/commit/63bcca43c6a00a758510398fa43096ce7e4f7df0) |
| E-002 · 2026-11-26 (AZ) | `JohnTWillemsen/VIctory-W` original base `63bcca43c6a00a758510398fa43096ce7e4f7df0` | `NOT_RUN` | At handoff creation, no owner RTX 5090 test or gameplay capture of this new fork supplied; old-fork workflow runs are separate repository evidence | **Native RTX 5090 launch, image, FPS and stability unknown** | [CURRENT_STATE](CURRENT_STATE.md), [LEGACY_CONTEXT](LEGACY_CONTEXT.md) |

## Entry pattern

`E-### · date/time+zone | repository+full SHA | SOURCE_READ / CI_PASS / UNIT_PASS / WARP_PASS / GPU_PASS / GAMEPLAY_OBSERVED / UPSTREAM_REPORTED / NOT_RUN / UNKNOWN | command, branch, driver/scene where relevant | explicit pass/fail/skip, measured result and caveats | permanent source URL or private-local evidence reference`.

Do not paste personal Windows paths, game content, screenshots, title-generated binaries, shaders, shader hashes derived from title assets, saves, unredacted crash logs, proprietary data, secret tokens or extracts into this file. Link to GitHub workflow/PR for public source evidence; keep user game observations private until sanitized.
