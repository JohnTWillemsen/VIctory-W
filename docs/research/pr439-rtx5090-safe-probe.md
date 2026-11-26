# PR #439 console-flow Wave64 + PR #2118 BVH gate: isolated RTX 5090 probe

**Status:** `SOURCE_READ` / `UPSTREAM_REPORTED`; owner tests of these pinned PR heads `NOT_RUN` as of 2026-11-26. **This is NOT a working-game or merge claim.** Task VW-004. Original fork `main`: `63bcca43c6a00a758510398fa43096ce7e4f7df0`.

## Why this separate path exists

The owner's **local and uncommitted** paging [#2121](https://github.com/Marvisak/VIctory/pull/2121) + emulated Wave64 [#189](https://github.com/Marvisak/VIctory/pull/189) combination passed 40 Wave64 tests, 37 descriptor tests, 255 GPU tests and an optimized build (E-027), **but still displayed a frozen “Two Years Ago” card** in the live RTX 5090 title run (E-028). The title runtime reported 76 conservative compute translation refusals: **37** divergent ballots, **32** unsafe split-wave LDS, **4** divergent reductions, **3** divergent lane reads. Those checks protect correctness; do not remove them without semantic proof.

[Upstream PR #439](https://github.com/Marvisak/VIctory/pull/439), head `e2d3cfd50715954fb89ff462edb37a0c4395ecd0`, implements a **different** console-flow execution strategy on 32-lane hosts. Its PR includes the stacked #223, #233, #320 changes, and additional single-wave LDS/whole-wave operations. **Do not apply it atop the #189 implementation by rote.** A Nov 26 upstream [RTX 5080 user report in #439's discussion](https://github.com/Marvisak/VIctory/pull/439) reported a textured, lit prison cell for 12 minutes, no device removal, 0 host refused PSOs, ~2.9 sec/frame and ~640 dropped draws/frame **on a combination** of original main + #2098 + #2626 + #2628 + #2464 + [BVH all-or-none gate #2118](https://github.com/Marvisak/VIctory/pull/2118) + #439; Windows 11 26200 / NVIDIA 617.42. That is an **UPSTREAM_REPORTED** scene observation on **another GPU and a multi-PR stack**, NOT attributable to #439 alone or confirmed on our hardware.

**Safety dependency:** #439 explicitly warns that partial BVH builder pipeline activation can corrupt title memory or crash. The [#2118](https://github.com/Marvisak/VIctory/pull/2118) source, pinned `999a8f67125865fcc0b3aa23cdc8a93b10ef9974`, is a separately reviewed candidate all-or-none safeguard. Do **not** run a title using #439 unless this guard (or a verified equivalent) is integrated and tested.


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
