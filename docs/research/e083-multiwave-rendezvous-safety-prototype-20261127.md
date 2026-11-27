# E083 — group>64 Wave64-on-Wave32 barrier rendezvous safety model (source-only)

**2026-11-27 MST. STATUS: PURE_SYNTHETIC_MODEL / NOT IN SHADER LOWERER / GPU_NOT_RUN / TITLE_NOT_RUN.**

## Why now

The owner privately supplied E082 *numeric-only* offline output from E078: 43 title-wide translation warning lines, of which **31** contain the >64-thread-group rejection phrase, **7** contain implicit-derivative, **2** lane-mask-as-data, and **3** whole-wave; no warning with exact `ds_permute`, exact cross-half phrase, generic LDS phrase or unknown. Independently, the E074 per-BVH-builder first-failed-shader histogram remains **5** `large_group`, **2** broad `cross_half_lds` of 7 refusals (53 total pipelines, 46 made). The two scopes differ; three title-wide whole-wave warnings are NOT evidence that exactly two belong to BVH. E082 did **not** rerun the title/GPU.

The six-PR NVIDIA baseline uses upstream [#439](https://github.com/Marvisak/VIctory/pull/439) exact head `e2d3cfd50715954fb89ff462edb37a0c4395ecd0`, which refuses group>64 when a console Wave64 cannot be run on a Wave32-only host. [Draft upstream #2214](https://github.com/Marvisak/VIctory/pull/2214) exact `b3efa1c0e3b7848cdc45d071972c4bfde83627aa` proposes per-half LDS state and **count-paired** multi-wave sync. The author explicitly notes the risk: distinct console waves can execute group barriers from different DXIL call sites while their counts happen to agree. The actual source's `soft_barrier`, `drain`, `exchange`, `hw_barrier`, `wait_for_halves` contain different barrier sites. [Microsoft documents the undefined behavior of group sync within divergent branches](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/groupmemorybarrierwithgroupsync). **Do not transplant #2214 as-is, bypass #439's refusal, or rely on matching barrier counts alone.**

## What this PR implements (and emphatically does not)

- `scripts/research/e083_multiwave_barrier_model.py`: a tiny **self-contained Python-only model** of workgroup-wide static sync-site and per-host-wave dynamic epoch equality. It deliberately is **not** connected to `victory-shader`, DXIL, GPU commands or real title shaders.
- `scripts/research/test_e083_multiwave_barrier_model.py`: **16** synthetic adversarial tests. Positive fictional groups 128/256/1024 threads on host32/guest64, and 32 host waves at 1024 threads. Negative unaligned/incomplete groups, wrong wave width, per-wave/unknown/lane divergence incorrectly mistaken for group-uniform, loops, indirect jumps, early lane exit, guarded barrier, multiple exits, unreachable blocks, duplicate static site IDs, missing warp, unequal barrier counts, and crucially **same barrier count reached at different DXIL call sites**.
- `.github/workflows/e083-multiwave-rendezvous-model.yml`: exact-head Ubuntu + hosted Windows Python 3.12 tests and offline import guard. **No full GPU tests, Rust builds or game executable.** No title content or private diagnostics on GitHub.

A synthetic `GROUP` predicate label is assumed proved **by the fictional input model**; the real AMD Wave64 per-wave scalar uniformity is NOT sufficient proof of group-wide uniformity across 128+ threads. Thus model acceptance never itself authorizes enabling the real shader. Loops are rejected even when marked group uniform, because no epoch invariants were proved. Every expected positive is a *test of the modeling policy only*.

## Required next engineering (actual translator, not this model)

1. Add an IR/structured-control-flow provenance analysis for every branch that can lead into any group barrier: permit only constants or values demonstrably uniform across the **whole group**, not just a Wave64. Soundness must survive lane masks, per-half exchanged values, indirect control flow, early exits, and both virtual console waves.
2. Design **one canonical DXIL group rendezvous call site** for each synchronized dynamic epoch, with all 32-lane host waves reaching that exact site in a group-uniform loop. Enforce identical epoch transitions and no early exit. A matched numeric count with different call sites must be **refused**.
3. Keep old six-PR `#439` >64 rejection unless the source-driven proof applies to the specific kernel. Maintain #2118 BVH all-made safety and #2311/E077 walker holdback. No global `skip_wave64` override or blanket shader error suppression.
4. Integrate one constrained positive >64 **public synthetic shader** and negative branch/loop/partial-group cases in a separately pinned source experiment. Hosted Windows `cargo check --workspace --all-targets --locked`, strict Clippy, focused shader tests, DXIL validator/pipeline creation on host32/WARP where meaningful, release build, and review all conflicts with #439/#2628 are prerequisites to *any* owner RTX5090 execution.
5. Only after a source candidate passes those gates should the owner be asked for **one** isolated, reversible GPU/title A/B with anonymous upload-only counters. Demonstrate actual BVH 46/7 improvement and visible scene, not just synthetic acceptance.

**Success criterion for this PR:** a well-tested, fail-closed **research model** that makes the unsafe barrier-site ambiguity explicit. **NOT** a rendering improvement, driver safety proof, integrated shader fix, FPS measurement or playable title. No merges to main without owner authorization.
