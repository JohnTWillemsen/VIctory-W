# E081 — Upstream #3406 versus six-PR console-flow lowerer: exact conflict audit

**2026-11-27 MST; CODE_REVIEWED, SOURCE_CONFLICT_VERIFIED, WINDOWS_NOT_RUN, OWNER_GPU/TITLE_NOT_RUN.**

## Verified source and test evidence

- Working branch: `experiment/e081-wave64-lds-six-pr-gate-20261127`, E081 source gate at `281c93b380f5cba93d77ebd652fe7ae855026303`, draft [PR #18](https://github.com/JohnTWillemsen/VIctory-W/pull/18), parent E074 `7d3a18e95225677b5e2a62722c09f44a806df59f`; neither based directly on nor merged into `main`.
- [Exact E081 source CI 45959180895](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45959180895) **failed intentionally at `git apply --check`** with `crates/victory-shader/src/emit/lower.rs:599`, exit 81. Prior six-PR source reconstruction and #2628 explicit semantic reconciliation ran first; no #3406 patch was applied; dependent hosted Windows tests were **skipped**, not passed or failed.
- Upstream [#3406](https://github.com/Marvisak/VIctory/pull/3406) at `174e8d9b76eddc247a2c6c00a1743b4812e4af62` changes exactly three shader source files. The proposed improvement is conditional for **<=64 compute threads** with uniform group-shared memory operations, DXIL barriers before/after eligible operations, no per-lane masked/divergent unsafe patterns. It does **not** address groups >64.
- The older dependency [#2118](https://github.com/Marvisak/VIctory/pull/2118) HEAD advanced one commit from six-PR pin `999a8f67125865fcc0b3aa23cdc8a93b10ef9974` to `78f36cfa69211edbfa87d44e92ab93bd795f74a7`. Live compare: exactly one descendant commit, exactly one changed file `crates/victory-gpu/src/draw.rs` with a logging-only warning rewrite (+4/-1). E081 deliberately pins the **old runtime** and verifies exact warning-only HEAD drift before changing a disposable local tracking ref. No GitHub upstream ref modified.
- The user-private E078 diagnostic gave 53 BVH pipelines, 46 made, 7 shader-translation refusals (5 `large_group`, 2 broadly `cross_half_lds` by error-string classifier); no specific LDS opcode, graphics repair or input/FPS result.

## Why an automatic three-file import is unsafe

The actual [upstream #439 lowerer at `e2d3cfd50715954fb89ff462edb37a0c4395ecd0`](https://github.com/Marvisak/VIctory/blob/e2d3cfd50715954fb89ff462edb37a0c4395ecd0/crates/victory-shader/src/emit/lower.rs) has host-target-dependent `x.target.runs(64)` / `x.target.runs(32)` selection, an `in_half` versus `reads_whole` distinction, `split`, `wants_console_flow`, and explicit `no_console_flow` rejection reasons. For a Wave64 program on Wave32, `needs_wave64` already branches to console-flow interpretation; it rejects groups >64 or unsafe permutations and only produces a WaveSize 64 when it can. The six-PR #2628 reconciler preserves that architecture and additionally propagates a portable descriptor view limit.

#3406 assumes a **different** `Lower::new` path where `console_lanes` and `one_wave && LDS` directly determine `s.wave_size`; its hunk around that code cannot apply at the six-PR line 599. A mechanical merge can silently bypass existing console-flow, split and refusal logic, or emit barriers twice / under the wrong flow. The two reported LDS errors may not even satisfy the proposed <=64 safety predicate. **Do not use `git apply --3way`, ignore the hunk, or turn off the old safety checks.**

## Correct next isolated work

1. Design a *new semantic adapter*, using exact source preimages to preserve #439 `Target` selection, `split`, `wants_console_flow`, `no_console_flow` and all builder holdback conditions. Treat #3406's new safe eligibility algorithm as source/reference, **not** a drop-in patch. The conservative path must be mutually exclusive with the old console-flow and maintain proper Wave64-on-Wave32 LDS memory order. Tests must demonstrate that unsafe cases remain refused.
2. First add positive <=32/64-thread LDS synthetic cases and negative divergent branches, per-lane EXEC, scalar mask, readfirstlane, indirect/mixed loop, and >64-threads eligibility tests. Require strict Windows `cargo check --workspace --all-targets`, `cargo clippy -D warnings`, relevant unit/DXIL validation and optimized release before any user RTX5090 test.
3. Separately research the five **>64 group** failures with site-uniform barrier reachability. Upstream [#2214](https://github.com/Marvisak/VIctory/pull/2214) author acknowledges undefined count-paired divergent D3D12 barriers and must not be imported until redesigned with negative tests.
4. Preserve E077 walker safety and original BVH all-or-none builder semantics. No title source material, raw logs, game paths, screenshots, or renderer claims in public GitHub. No owner game run from this PR; no main merge.

**Acceptance state:** E081 safe LDS transplant BLOCKED_BY_SEMANTIC_SOURCE_CONFLICT. The strict source gate did its job. No evidence of a completed new shader fix.
