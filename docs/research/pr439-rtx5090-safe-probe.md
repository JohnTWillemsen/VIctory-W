# PR #439 console-flow Wave64 + PR #2118 BVH gate: isolated RTX 5090 probe

**Status:** `GPU_PASS` **on RTX 5090 for #439 targeted split/loop tests**, `UNIT_PASS` for #2118 standalone BVH unit tests (E-030, 2026-11-26). **Combined source integration, build and title are NOT_RUN.** Task VW-004. Original fork `main`: `63bcca43c6a00a758510398fa43096ce7e4f7df0`.

## Why this separate path exists

The owner's **local and uncommitted** paging [#2121](https://github.com/Marvisak/VIctory/pull/2121) + emulated Wave64 [#189](https://github.com/Marvisak/VIctory/pull/189) combination passed 40 Wave64 tests, 37 descriptor tests, 255 GPU tests and an optimized build (E-027), **but still displayed a frozen “Two Years Ago” card** in the live RTX 5090 title run (E-028). The title runtime reported 76 conservative compute translation refusals: **37** divergent ballots, **32** unsafe split-wave LDS, **4** divergent reductions, **3** divergent lane reads. Those checks protect correctness; do not remove them without semantic proof.

[Upstream PR #439](https://github.com/Marvisak/VIctory/pull/439), head `e2d3cfd50715954fb89ff462edb37a0c4395ecd0`, implements a **different** console-flow execution strategy on 32-lane hosts. Its PR includes the stacked #223, #233, #320 changes, and additional single-wave LDS/whole-wave operations. **Do not apply it atop the #189 implementation by rote.** A Nov 26 upstream [RTX 5080 user report in #439's discussion](https://github.com/Marvisak/VIctory/pull/439) reported a textured, lit prison cell for 12 minutes, no device removal, 0 host refused PSOs, ~2.9 sec/frame and ~640 dropped draws/frame **on a combination** of original main + #2098 + #2626 + #2628 + #2464 + [BVH all-or-none gate #2118](https://github.com/Marvisak/VIctory/pull/2118) + #439; Windows 11 26200 / NVIDIA 617.42. That is an **UPSTREAM_REPORTED** scene observation on **another GPU and a multi-PR stack**, NOT attributable to #439 alone or confirmed on our hardware.

**Safety dependency:** #439 explicitly warns that partial BVH builder pipeline activation can corrupt title memory or crash. The [#2118](https://github.com/Marvisak/VIctory/pull/2118) source, pinned `999a8f67125865fcc0b3aa23cdc8a93b10ef9974`, is a separately reviewed candidate all-or-none safeguard. Do **not** run a title using #439 unless this guard (or a verified equivalent) is integrated and tested.


## Owner RTX 5090 targeted evidence — E-030 (2026-11-26)

The owner ran the exact-head test script in this draft PR on Windows 11 with **NVIDIA GeForce RTX 5090**. The private UTF-16LE 268-line report (start 17:08:23, end 17:09:33 America/Phoenix) verifies the two independent detached worktrees at the exact PR hashes above, isolated Cargo targets, and all three command exit codes **0**.

| Actual owner test | Source SHA | Result |
| --- | --- | --- |
| `cargo test -p victory-shader --lib --locked split_tests -- --test-threads=1 --nocapture` | #439 `e2d3cfd` | **36 pass, 0 fail, 315 filtered** |
| `cargo test -p victory-shader --lib --locked lane_read_loop_tests -- --test-threads=1 --nocapture` | #439 `e2d3cfd` | **2 pass, 0 fail, 349 filtered** |
| `cargo test -p victory-gpu --lib --locked builder -- --test-threads=1 --nocapture` | #2118 `999a8f67` | **4 pass, 0 fail, 232 filtered** |

**Why this is GPU_PASS for shader cases:** The shader's `--nocapture` output explicitly names `NVIDIA GeForce RTX 5090` (98 such lines), and reports exact compute readback under `split true`: cross-half shuffles, masked ballots, 64-lane reduction, partial group counts, DPP, diverging loop exits, shared-LDS ordering, and nested masks. No missing-adapter skips were logged. The **four builder cases are pure/unit-oriented correctness tests**; the log does **not** demonstrate the BVH gate operating in a real title or executing on the GPU.

**Boundary:** This verifies two separately compiled upstream heads, **not the combined #439+#2118 source**. No cross-PR merge, full GPU suite, title launch or world-rendering result. The existing local #2121/#189 paging+Wave64 branch still fails the real 3D scene (E-028) and is untouched.

**Next source-only gate:** Create a fresh, isolated #439-based integration worktree and merge #2118 `--no-commit --no-ff` using a **command-scoped temporary Git identity** and `rerere.enabled=false` (do not set `git config --global`). Collect the 3 overlapping source paths plus the full six-file BVH patch and any Git conflict markers; review semantic coupling of shader compilation vs builder dispatch suppression **before compiling or considering a title run**. The RTX5080 full-stack dependencies still need separate assessment, especially #2628 vs our #2121 paging and packed formats. Keep the current source/main/release untouched. A source-only preparation script is bundled in this PR.

## Integration collision map (source patches reviewed, not merged)

Inspected **actual per-file upstream PR diffs**, not just claims. A shared pathname is an **overlap**, not necessarily a Git content conflict, and compatible semantics are NOT inferred by automatic merging:

| Additional PR | Paths also changed by #439 | Implication |
| --- | ---: | --- |
| #2118 BVH all-or-none | **3**: `gpu/draw.rs`, `gpu/pipeline.rs`, `gpu/pipeline/placed_uav_tests.rs` | Safety prerequisite; review pipeline creation and dispatch gating together before title use |
| #2098 RT acceleration view address | **0** | Distinct patch surface, still requires verification |
| #2626 packed formats | **1**: `gpu/host.rs` | Review format support/host resource fallback |
| #2628 capped descriptor index | **6**: `apps/victory/src/translate.rs`, `gpu/draw.rs`, `gpu/shader_cache.rs`, `shader/emit/lower.rs`, `shader/emit/mod.rs`, `shader/emit/shader.rs` | High semantic risk: cache keys, shader indexing and Wave64 context must coexist |
| #2464 raw structured views | **1**: `gpu/host.rs` | Validate raw SRV representation and byte offsets |
| Existing #2121 paging | **9** shared source paths | A **separate** descriptor strategy from the 5080 report's #2628; do not assume both can simply coexist |
| Existing #189 Wave64 emulation | **17** shared source paths | **Alternative architecture**, not a straightforward additive patch to #439 |

**Conclusion:** Before any *new* combined source, the owner must pass independent shader/BVH tests and decide between (A) a carefully reproduced version of the *reported RTX 5080 stack* using #2628 or (B) adapting #439 with our #2121 pager; avoid replacing or mutating the already validated local #2121+#189 build. No source file merge, Rust build or title run has been performed for this map.


## E-031 — actual #439 + #2118 noncommitting merge inspected (2026-11-26)

The owner supplied two separate private files: the 14-line `pr439-bvh2118-merge-inspection.txt` and 79 KB code-only `pr439-bvh2118-review-source.zip`. The ZIP contains **six complete merged Rust files**, `DIFF_STAGED.patch` (source-only), Git `STATUS`, `MERGE_OUTPUT` and `MERGE_TREE`; the full archive and no proprietary title material are committed to Git.

**Exact index state, source verified by inspection:**
- Local branch `experiment/pr439-bvh2118-source-review-20261126`, pinned HEAD #439 `e2d3cfd50715954fb89ff462edb37a0c4395ecd0`; MERGE_HEAD #2118 `999a8f67125865fcc0b3aa23cdc8a93b10ef9974`.
- `git merge-tree --write-tree --name-only`: **exit 0**, computed tree object **`9f8bb36f497fdfffd9d68f2f2b22b0284899ae10`**. `git merge --no-commit --no-ff`: **exit 0**, message `Automatic merge went well; stopped before committing as requested`.
- **Zero textual source conflicts; zero `<<<<<<<` / `=======` / `>>>>>>>` conflict markers** in all six exported Rust files. The index has five modified paths and one newly added file, no unmerged stages.
- Exact six source paths: `apps/victory/src/run.rs`, `crates/victory-gpu/src/draw.rs`, `crates/victory-gpu/src/pipeline.rs`, `crates/victory-gpu/src/pipeline/builder.rs` (added), `crates/victory-gpu/src/pipeline/make.rs`, `crates/victory-gpu/src/pipeline/placed_uav_tests.rs`.

**Manual semantic review (pre-compile):** `run.rs` records both initial and later loaded BVH builder DLL images. `pipeline.rs` tags compute pipelines based on originating bytecode/stack address, registers pending builder pipelines, and exposes the `held_back`/`not_dispatched` gate. `builder.rs` requires all currently known builder host pipelines made before letting their dispatches run and tracks a dropped/bind-failed dispatch. `draw.rs` invokes this gate on both direct and indirect dispatch paths and notes missing pipelines/bind failures; `make.rs` exposes a nonblocking pending-state check and eager builder starts; `placed_uav_tests.rs` adjusts its fixture for dispatch holdback. The merged source contains both the console-flow Wave64 source from #439 and all of these BVH gate paths. **No obvious missing-symbol or marker conflict in the reviewed paths**; only a Rust compiler and owner unit/GPU runtime tests can validate behavior. `builder::runs()` caches a once-per-frame decision, so if the title creates new builder pipelines midframe, behavior also needs observation; no new invariant is claimed.

**Next exact-source gate:** `scripts/research/validate-pr439-bvh2118-integration.ps1` in this draft branch verifies the **pending, uncommitted** HEAD/MERGE_HEAD/branch, all six expected staged source statuses, and exact `git write-tree` = `9f8bb36f497fdfffd9d68f2f2b22b0284899ae10`. It runs a workspace all-target Cargo check, 36 split-wave GPU tests, 2 lane-loop GPU tests, 4 BVH unit tests, an independently isolated optimized release build, and a **separate, non-blocking diagnostic full GPU suite** (the original source already has a known NVIDIA descriptor-cap unit failure). Record all exit codes and release SHA. **Script has NOT run on owner Windows yet; no combined build/GPU result/graphics or BVH live safety claim.** No source commit/push/merge into `main` is authorized. The old #2121+#189 experiments remain untouched.

## E-032 — first combined compile blocked by test-helper API mismatch (2026-11-26)

**Owner result: COMPILE_FAIL, exit 101, not a shader/GPU runtime failure.** The owner ran our E-031 exact-staged-tree validation script in the local third worktree (HEAD #439, MERGE_HEAD #2118). `cargo check --workspace --all-targets --locked` reported **a single `E0061`** in `crates/victory-gpu/src/pipeline.rs` line **876**, inside a **#2118-only test helper** `ending_shader()`. It calls `victory_shader::emit::emit` with six arguments, but upstream #439 changed the signature to take **seven**, including a `victory_shader::emit::Target`. The compiler stopped **before** Wave64 split/loop tests, BVH tests, full GPU suite or optimized release build: **all subsequent gates NOT_RUN**. Thus, E-031's automatic conflict-free merge **is not** evidence of compile compatibility.

**Source-confirmed minimal resolution:** Preserve #439's runtime API and update only the test helper call from `emit::emit(&c, &native, &p, &st, &io, &res).unwrap()` to `emit::emit(&c, &native, &p, &st, &io, &res, emit::Target::ANY).unwrap()`. #439 defines `emit::Target::ANY` as the **default unrestricted target**, appropriate for this tiny one-thread, non-wave64 `s_endpgm` compute test. Don't change production shaders or disable host Wave64 safety guards.

**Owner ZIP source hashes used by the guard:**
- Original `pipeline.rs` SHA-256: `BE8CA499438B8D89B869D58D0749171F62CE92F5860BE2A3A788B5C08D0687AF`.
- Proposed single-line file SHA-256: `7F172A4D048FE74F8DBFA250F49DB2FD5A816456A849CC824FAA237B52B3CB73`.
- Pending source pre-fix Git staged tree: `9f8bb36f497fdfffd9d68f2f2b22b0284899ae10`.

**Next owner action:** Run `scripts/research/fix-and-validate-pr439-bvh2118-emit-target.ps1` from THIS draft PR. It checks pinned third-worktree HEAD/MERGE_HEAD/branch/status/index and original source hash, backs up the one public Rust file externally, applies exactly one test-only call change, verifies SHA, stages **only** that change (NO commit), and runs workspace all-target Cargo check → #439 split/loop GPU tests → BVH gate unit tests → separate optimized release build → independent full GPU suite. Any failure is recorded in a **new** private log `C:\vtw\verification\pr439-bvh2118-api-fix-validation.txt`. The test runner **has NOT been run** by owner at time of writing. The previous failing report remains immutable historical evidence; do not overwrite it or claim that compilation is already fixed.

**Caveats:** This minimal API correction does not establish title BVH safety or a rendered world. A known main-derived RTX5090 descriptor-capacity unit failure may recur on the full GPU suite and must be identified by exact failing test rather than suppressed. No source commit, push or main merge authorized.

## First bounded experiment (no game)

Run the code-only `scripts/research/test-pr439-bvh2118.ps1` on the owner's Windows 11 RTX 5090 machine. It:
1. Requires fork `main` unchanged at the SHA above and upstream PRs at the exact pinned SHAs (stops if a head moved).
2. Fetches #439 and #2118 from the original public upstream, creating **two independent detached source worktrees** with distinct Cargo target directories, not touching the successful #2121/#189 local worktree.
3. Executes the `victory-shader` `split_tests` and `lane_read_loop_tests` selected tests from #439 and `victory-gpu` `builder` tests from #2118, serially, with `--nocapture` to show the actual adapter/skip and GPU results.
4. Stops on any failed test and writes a **private** local report. A unit PASS with test-skips is **not** a `GPU_PASS`.

**Acceptance:** all selected tests pass, and at least one hardware execution is explicitly documented on NVIDIA RTX 5090 rather than WARP/software or skipped cases. Then inspect conflicts between #439/#2118 and the exact separate descriptor heap/format/structured-view fixes used in the upstream 5080 report. Do not combine by copy-pasting entire files. Build an entirely new, rollback-safe third/fourth experiment branch only after reviewing conflicts, code provenance, D3D12 unit/diagnostics and BVH gate.

## Separate display-composition track

[Issue #841](https://github.com/Marvisak/VIctory/issues/841) documents an actual intermediate **2560×1440 world image** while **3840×2160 present output** stays black on another NVIDIA computer. Existing `crates/victory-gpu/src/capture.rs` supports `VICTORY_CAPTURE`, `VICTORY_CAPTURE_WORLD` and `VICTORY_DUMP_TARGETS` in **diagnostics** builds; no new code is required to capture the owner's intermediate render target privately. [PR #2441](https://github.com/Marvisak/VIctory/pull/2441) offers an opt-in 1440p diagnostic present substitution, **not a final compositor fix**, and upstream triage calls out test/feature-gating issues. Do not merge or enable it as a default. Capture and inspect targets first so missing world shading isn't confused with missing 4K final composition.

## Evidence, risk and rollback

- **Source checked:** PR #439 `e2d3cfd50715954fb89ff462edb37a0c4395ecd0`; PR #2118 `999a8f67125865fcc0b3aa23cdc8a93b10ef9974`; PR #2441 `3c9cbae88317245ebc8051a953e180f5afe79cfa`. Exact heads recheck before future tests.
- **Not performed:** independent owner #439/#2118 tests, any combination of those PRs, merged builds, D3D12 debugging, final target captures, or new game run.
- **Risk:** GPU hangs/device removal from unsafe split-wave barriers or partial BVH execution; numerical errors in divergent flow and NVIDIA thread-group tiling. Keep #439's conservative `root_memory` safeguards and #2118's gate; never change system TDR settings simply to hide a hang.
- **Rollback:** delete only the new detached test worktrees and their isolated Cargo build targets, or leave them untouched. The fork `main`, original paging/Wave64 worktrees, and original binaries remain unchanged.
- **Privacy:** No title archive, executable, shader dump/hash, screenshot, private machine path or raw runtime log belongs in GitHub. Only aggregate/synthetic evidence should enter a future PR.
