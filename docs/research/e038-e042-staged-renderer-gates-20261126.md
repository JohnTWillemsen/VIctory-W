# E-038–E-042 — pinned staged renderer prerequisite tests and #2628 conflict audit

**Snapshot date:** 2026-11-26 America/Phoenix (workflows 2026-11-27 UTC). All operations below use **only public upstream source** and disposable GitHub Actions checkouts. There is **no persistent five-/six-PR runtime commit in this fork, no published title content, no user RTX5090 hardware title run, and no merge into `main`**. All upstream heads are pinned rather than following moving PR refs.

## E-038 — #2626 nine-file source-only integration

- **[Source-only workflow 45922961623](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45922961623): PASS.** Experimental script/workflow at `2dc38ec19f6f2b0c6bac0fe92102da216d5b561e`.
- Sources: [#439](https://github.com/Marvisak/VIctory/pull/439) `e2d3cfd50715954fb89ff462edb37a0c4395ecd0` + [#2118](https://github.com/Marvisak/VIctory/pull/2118) `999a8f67125865fcc0b3aa23cdc8a93b10ef9974` + test-only `emit::Target::ANY` correction (prior E-034), then [#2098](https://github.com/Marvisak/VIctory/pull/2098) `543d8688068b658ca4bf9602887097b215fec838` one-file acceleration address patch, then [#2626](https://github.com/Marvisak/VIctory/pull/2626) `c8cc83e22702aa46dc1855c0f9df890fc5496238` packed-texture conversion and writable-target fallback.
- Computed PR #2626 merge base **`63bcca43c6a00a758510398fa43096ce7e4f7df0`**; exactly **nine source paths** (bindless, descriptor/host, list copy/readback, resource/texture, pipeline format) matched GitHub PR file list, and `git apply --check --index`, `git apply --index`, `git diff --cached --check` **PASS**, no `--3way` or ours/theirs fallback.
- **Scope:** textual source applicability ONLY, not build, test, hardware or scene.

## E-039 — same four upstream PRs, actual hosted Windows compiler and focused tests

- **[Windows workflow 45923029978](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45923029978), job `140257981711`: PASS** with E-038 source-only job also passing. Source script `9c61a96b10c30948bc3170e0b8fe258832e47bcc`, workflow `6c824833aa0bfcb7789482b8a560f2758e00c3e4`. Fresh clean checkout; exact pinned patches as E-038.
- `cargo check --workspace --all-targets --locked`: **PASS**.
- `cargo test -p victory-gpu --lib --locked packed -- --test-threads=1 --nocapture`: **6 passed, 0 failed, 238 filtered** (two packed partial-copy texel/padding tests; target availability/selection tests; packed alpha round trip). Hosted Windows result only; some tests may use software fallbacks; **not NVIDIA RTX5090 validation**.
- `... an_acceleration_structures_view_address_is_its_location`: **1 passed, 0 failed, 243 filtered**.
- `... builder`: **4 passed, 0 failed, 240 filtered** (unit-level BVH all-or-none tests).
- `cargo build --release --locked -p victory`: **PASS** optimized build.
- **Not run:** whole `victory-gpu --lib` suite, native RTX5090 wave tests on this four-PR source, in-title BVH, real packed formats under NVIDIA, rendered 3D view or gameplay. No build artifact persisted after runner cleanup. E-034 owner two-PR test still has known independent 234 pass / **2 fail** / 1 ignored GPU lib baseline caps.

## E-040 — add #2464 raw structured SRVs, fifth upstream PR

- **[Source-only workflow 45923314662](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45923314662): PASS** with E-040 script `bb9621bfc4d99a8a485c12a7255dad19319c3274`, workflow `dff4286c558ad643cd6e177e08f160e834c0ab7d`.
- [#2464](https://github.com/Marvisak/VIctory/pull/2464) head `b9dc4b037a87bf6919ce92eae7c79a36c0307e48`; real PR merge base `13f91caee25f2fdf2c062be5f7a27f058e51cbca`, exactly **two changed files** (`crates/victory-gpu/src/descriptor/host.rs` and `crates/victory-gpu/src/host.rs`), both applied cleanly after #439+#2118+#2098+#2626.
- **Scope:** SOURCE_APPLIES, no physical NVIDIA raw SRV behavior, no standalone title, no persistent source commit.

## E-041 — five upstream PRs, hosted Windows compiler/Clippy/focused tests/release **PASS**

- **[Windows workflow 45923514801](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45923514801): completed SUCCESS**. Source guard Ubuntu job `140259482019` passed; real hosted Windows job `140259527092` passed. Reproducible source script `aaa418c7a0dad069198cd27f36a39bacb54f7088`, workflow `ab7ebff93e9361f1a1f5dbb6422912f16de14fa4`, checked out on #4 research branch without updating main. Source is the pinned **#439 + #2118 + #2098 + #2626 + #2464** stack with hash-guarded test-only emitter API fix.
- `cargo check --workspace --all-targets --locked`: **PASS**, dev profile completed.
- `cargo clippy --workspace --all-targets --locked -- -D warnings`: **PASS**, warnings-as-errors check completed.
- `cargo test -p victory-gpu --lib --locked packed -- --test-threads=1 --nocapture`: **6/6 pass, 0 fail, 238 filtered**; includes two partial-copy 16-bit pixel/padding tests, packed target/write selection, packed alpha conversion.
- `... an_acceleration_structures_view_address_is_its_location`: **1/1 pass, 0 fail, 243 filtered**.
- `... builder`: **4/4 pass, 0 fail, 240 filtered**.
- `cargo build --release --locked -p victory`: **PASS**, optimized release build complete.
- All source was ephemeral on hosted Windows and removed by cleanup. The #2464 NVIDIA-only raw-structured read behavior was **not physically exercised on an RTX5090**, and these focused tests do not establish a fully green GPU suite, GPU memory state, BVH title execution, or gameplay. No persistent integrated source SHA or binary for the five-PR source is available in this fork.

## E-042 — #2628 portable descriptor heap/shader clamp is the remaining integration blocker

- **[Source conflict audit 45923600001](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45923600001): intentionally FAILED CLOSED (exit 22)**, code `81075c3e97b1823d55d258245cc180a94a7cd066`, workflow `f0ccfb2f972686d50e012b7fbc23c20745fa92f4`. No source was modified by the failing #2628 apply attempt; no merge or release attempted in this check.
- [#2628](https://github.com/Marvisak/VIctory/pull/2628) pinned head `e2cdafe560fb6b601757a8ec921e352726e6662e`, actual PR merge base `f3578e386ea0f06153445af10a698df029620aad`. Its nine changed paths were verified against the PR, then `git apply --check --index` over the five-PR source failed on **five files**, precisely: `apps/victory/src/translate.rs` (old hunk line 568); `crates/victory-gpu/src/draw.rs` (3378); `crates/victory-gpu/src/shader_cache.rs` (84); `crates/victory-shader/src/emit/lower.rs` (95); `crates/victory-shader/src/emit/mod.rs` (368). Other files not mentioned by `git apply` are not proof of runtime or semantic safety.
- Do **not** mark this six-PR code as merged, compiled or graphics-capable. The red source gate protects the fork against a blind patch merge.

## Concrete semantic reconciliation plan for the next developer

1. **Preserve wave-size semantics and portable heap semantics together.** In #439 `victory_shader::emit::Target` holds the host's `lanes_min`/`lanes_max`, and `Options { view_marks, target }` feeds `emit_with` / `lower` for console wave64. #2628 introduces `Options.portable_views` and `view_heap_limit` (1,000,000 when portable, otherwise `HEAP_VIEWS = 2,097,152`). The intended integrated type must retain **`view_marks`, `target`, and `portable_views`**, with correct defaults and consistent runtime/offline callers. Never replace #439's host target by `Target::ANY` in actual runtime to silence build errors.
2. **Lowering must accept BOTH wave targeting AND view limit.** #439's `emit/lower.rs` rejects unsupported console Wave64 paths, while #2628's `lower_with_limit` changes indexing/null binding and its constructor signature. A reconciled entrypoint must propagate both `Target` and `view_limit` through primary and fallback lowering, including thread group and mask safety; a code-only cherry-pick is insufficient.
3. **Shader cache identity must include BOTH hardware-wave range and view heap limit.** #439 `shader_cache::host_shader(container, target)` builds options `{view_marks:true,target}` and `host_key(build,target)` hashes `target.key()`. #2628 adds `portable_views`, probing host D3D12 heap creation, and includes its view limit in translation cache keys. Keep both dimensions to prevent using a module translated for a 2M heap or 64-lane host on capped NVIDIA Wave32. Validate that host creation/probing occurs before portable setting becomes cached; a host-less initial probe must not permanently select the wrong policy.
4. **Retain #2628's descriptor heap/null reservation rules** (host `PORTABLE_VIEWS = 1,000,000`, `DYNAMIC = 1<<18`, reserve last three null slots), the dedicated bounds tests, and conversions in `draw.rs`/offline `translate.rs`. Verify the #2098 BVH address and #2464 NVIDIA raw view paths are not lost in `descriptor/host.rs`, and preserve #2626 packed texture/copy semantics.
5. **Acceptance order:** isolated commit(s) on a new experiment branch with honest source-merge diff and manual code review; compilation + Clippy + relevant synthetic descriptor/heap and packed tests in Windows CI; complete shader translation tests on host capabilities; RTX5090 wave32/console64 readbacks and **full GPU failure ledger**, then private in-title smoke with exact binary SHA and device-loss/visible-frame logs. Never suppress old two failing NVIDIA heap-cap tests to report an all-green regression suite.
6. **Do not merge to main** without owner approval. No game executable, logs, shader containers or copyrighted title data in GitHub.

The third-party RTX5080 lit scene required six PRs; E-039 verifies four compile together, **E-041 verifies five compile and pass 11 focused hosted-Windows unit tests plus Clippy**, and E-042 proves #2628 is not a blind drop-in. None of these results is a physical NVIDIA title or rendered-scene milestone. These findings narrow the next engineering task; they do not constitute a PC port gameplay milestone.
