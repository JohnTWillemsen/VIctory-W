# RTX 5090 owner-run baseline collector

This is a **source/synthetic test helper**, not a compatibility fix. It does not launch a title, inspect title files, fetch code, mutate branches or update system settings. Compatible with Windows PowerShell 5.1+. Do not treat a clean report as native-gameplay proof.

## First run (inventory only)

Download the **reviewed, SHA-pinned** script from this branch into `C:\vtw\verify-victory-gpu.ps1` outside the checkout, inspect it, and run:

```powershell
& 'C:\vtw\verify-victory-gpu.ps1' -Mode Inventory -Repo 'C:\VIctory-W'
```

This reports OS build, NVIDIA GPU and driver, Git/Rust tool versions, repository HEAD, counts of tracked modifications (without printing names), MSVC-linker availability, installed Windows SDK DXIL versions and whether the **VIctory-built** executable exists. It does not include the game path, game executable, saves, shader data, captures or crash logs.

The script saves `C:\vtw\verification\victory-inventory-<UTC>.txt`. Privately upload that report in chat.

## Second run (opt-in source/synthetic gates)

After reviewing the inventory:

```powershell
& 'C:\vtw\verify-victory-gpu.ps1' -Mode Synthetic -Repo 'C:\VIctory-W'
```

This adds `cargo fmt --all -- --check` (**summarized**, not a giant line-by-line diff), `cargo test -p victory-gpu --lib --locked descriptor -- --test-threads=1 --nocapture`, and `cargo xtask policy`, and saves a separate synthetic report. Cargo's native stdout/stderr are combined before PowerShell receives them to avoid Windows PowerShell 5.1 aborting on a normal `Downloading crates ...` progress line. Cargo may take time to build, need MSVC tools, and exercise GPU tests which skip when appropriate. **Read actual test counts and device selection**, not just the script's final command status. Commands that fail are reported and do not automatically rewrite or delete anything. The script defaults `CARGO_TARGET_DIR` to `C:\vtw` if not already set in this session.

Do not change machine-wide script execution policy. Follow your organization's normal policy for reviewing and permitting a single downloaded script. If Windows blocks it, contact your administrator rather than changing security defaults.


### November 26 owner baseline observations

Owner inventory: Windows 11 Pro build 26200; RTX 5090 32607 MiB; NVIDIA driver 617.42; Rust/Cargo 1.98.1 MSVC override; clean repo at `63bcca43`; preexisting VIctory release executable. `link.exe` absent on ordinary PowerShell PATH, which does **not** prove MSVC is uninstalled.

First Synthetic execution using the original collector: `cargo xtask policy` passed (191 files). `cargo fmt --all -- --check` failed with 925 diff hunks across 66 source files despite the clean checkout. Treat as **existing baseline formatting divergence**, not an owner change; never run `cargo fmt` on `main` just to silence it. `cargo test` was **inconclusive** because the collector treated initial native stderr text `Downloading crates ...` as a terminating error and never preserved the actual Cargo outcome. This was a **test-runner bug**, not evidence that the GPU tests failed. The collector was amended to combine native streams and report Cargo's actual exit status.

These observations require a second Synthetic report from the amended collector before assigning any GPU test pass/fail result. Neither first nor second Synthetic report proves gameplay correctness.


### Owner synthetic follow-up, November 26 21:21 UTC

RTX 5090 (driver 617.42), clean main `63bcca43`, Rust 1.98.1:
- `cargo fmt --all -- --check`: 925 diff hunks in 66 files. Source checkout remained clean; an existing formatting baseline mismatch, **not a patch regression**.
- `cargo test -p victory-gpu --lib --locked descriptor -- --test-threads=1 --nocapture`: **21 passed, 1 failed, 210 filtered**, exit 101. Failing `descriptor::host::tests::dynamic_slots_are_held_until_released` at `descriptor/host.rs:2226`: `heap.heap.GetDesc().NumDescriptors >= victory_shader::emit::HEAP_VIEWS` is false on the capped NVIDIA host.
- `cargo xtask policy`: 191 files OK.
- This confirms **the test's assumption fails on this GPU**. It does not show that a shader actually read past the heap during gameplay or that descriptor paging fixed geometry.
- Existing overlapping upstream PRs: [#3300](https://github.com/Marvisak/VIctory/pull/3300) (functional: keeps the full dynamic pool when the host takes the smaller heap; also corrects the test), [#3244](https://github.com/Marvisak/VIctory/pull/3244) (tests for host-specific capacity and copy-pair placement), [#2937](https://github.com/Marvisak/VIctory/pull/2937) (test skip for capped hosts), and [#2683](https://github.com/Marvisak/VIctory/pull/2683) / [#2121](https://github.com/Marvisak/VIctory/pull/2121) (separate shader bound/paged heap work). **Do not duplicate fixes or claim upstream test ownership.** `NEW-24` is already claimed in upstream #1633.
- Next valuable independent test: fetch PR #3300 head `01f91fea96de7c6fe47d5dd9f302e51a2403cac7` into a detached worktree, compare its host descriptor unit tests with untouched `main` on the same RTX 5090, and retain logs privately. No merging or proprietary data.

### Owner verification of #3300 at 2026-11-26 21:23 UTC

Owner fetched and SHA-verified upstream PR #3300 head `01f91fea96de7c6fe47d5dd9f302e51a2403cac7` in a **detached separate worktree**, `C:\\VIctory-Tests\\pr3300`, with a separate Cargo target. Owner's Windows PowerShell transcript identifies this SHA and records `Test exit code: 0` for `cargo test -p victory-gpu --lib --locked descriptor::host::tests:: -- --test-threads=1 --nocapture`. Contrast clean `main`: the narrower descriptor filter had 21 passed, 1 failed (`dynamic_slots_are_held_until_released`) on the same RTX 5090.

**Evidence tier: command exit 0, exact test lines not captured.** The PowerShell 5.1 transcript contained the invocation label and exit status only, not Cargo's native test output. It is *not yet* verified how many tests ran or what adapter was selected. Follow up by running the same filtered test command in the same detached worktree with native `cmd /D /C '... 2>&1'` stdout piped through `Tee-Object`, saving actual `running N tests` and `test result: ok` lines. Do not report a pass count, title correctness, or runtime/gameplay benefit until supported.

The owner baseline `C:\\VIctory-W` and release `C:\\vtw\\release\\victory.exe` remain untouched. PR #3300 is still **open upstream** and should not be merged automatically; its dynamic-pool tradeoff keeps fewer title slots, so #2121 paging requires independent review.

### Owner full native-output verification of upstream #3300

Same pinned detached worktree commit `01f91fea96de7c6fe47d5dd9f302e51a2403cac7`; separate target `C:\\vtw\\test-pr3300`; Windows 11 Pro, NVIDIA RTX 5090 host; default `VICTORY_D3D12_WARP` unset. The command `cargo test -p victory-gpu --lib --locked descriptor::host::tests:: -- --test-threads=1 --nocapture` reported **`running 16 tests`**, **16 passed / 0 failed**, **217 filtered**, exit code 0. Crucially `descriptor::host::tests::dynamic_slots_are_held_until_released ... ok`, where untouched main `63bcca43` failed its larger descriptor selection. Evidence tier **owner-run native output confirmed**, not gameplay, rendering, FPS, or descriptor paging proof. Private log: `pr3300-detailed-tests.txt`. PR #3300 remains unmerged upstream.

Next candidate, separately: upstream #2683 after its 2026-11-26 rebase to main, head `aecd60423c4673233104afaba1bde81f40d78a93`, uses a conservative capped shader view index (`HEAP_VIEWS = 1,000,000`) and carries null-buffer boundary tests. Keep as its own worktree and Cargo target; do not merge with #3300 or #2121 at this stage. Then upstream #2121 at `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608` (paging) is the separately controlled alternative. Both may have revised heads; always reverify pin.


### Owner synthetic confirmation of upstream #2683 — November 26

In a **separate, detached worktree** from original clean main, the owner ran the exact upstream [PR #2683](https://github.com/Marvisak/VIctory/pull/2683) commit `aecd60423c4673233104afaba1bde81f40d78a93`, using its own Cargo target directory. Native PowerShell/cmd output confirms the command `cargo test -p victory-gpu --lib --locked descriptor:: -- --test-threads=1 --nocapture` compiled and ran **24 tests: 24 passed / 0 failed / 210 filtered, exit code 0**. These include `descriptor::host::tests::a_heap_has_every_slot_shaders_clamp_to`, `the_capped_layout_and_the_small_range_fit_the_clamp_shaders_use`, and main's prior failing `dynamic_slots_are_held_until_released`. This is **UNIT_PASS on the owner RTX 5090 setup**, without full proof which adapter each test used. It is neither a full workspace test nor a native title/graphics test. Full logs remain outside Git.

**Three distinct synthetic observations:** untouched main `63bcca43`: 21/22 in `descriptor` selection; #3300 pinned `01f91fea`: 16/16 in `descriptor::host::tests::` selection; #2683 pinned `aecd6042`: 24/24 in `descriptor::` selection. **Filters differ; don't compare totals as a performance ranking.** Both upstream patches remain distinct/unmerged and neither is a verified graphics fix in this owner's game.

**Next independent experiment:** [#2121](https://github.com/Marvisak/VIctory/pull/2121) paged view heaps at last-verified `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608`; recheck live head, create separate worktree and separate Cargo target, run targeted paging/readback tests before any game build. Do not stack #2121 with #2683 or #3300. Preserve original release and source-clean main.


### Owner synthetic confirmation of upstream #2121 — November 26

The owner fetched pinned upstream [#2121](https://github.com/Marvisak/VIctory/pull/2121) **`0bc5edbd2e1c5836bab00dc0af9f186bdd56c608`** into a **third detached worktree**, using a distinct Cargo target directory. `VICTORY_VIEW_PAGES=1` was set, and the `VICTORY_D3D12_WARP` setting was empty. The uploaded detailed local text log states:

- `cargo test -p victory-gpu --lib --locked descriptor:: -- --test-threads=1 --nocapture`: **37 passed, 0 failed, 0 ignored, 218 filtered; exit 0**. Includes `descriptor::host::tests::a_paged_heap_of_every_slot_shaders_index_is_capped`, `dynamic_slots_are_held_until_released`, and page recycling, refused-room and read-pressure tests.
- `cargo test -p victory-gpu --lib --locked a_placed_texture_in_a_page_taken_back_is_made_after_one_submission_reads_it -- --test-threads=1 --nocapture`: **1 passed, 0 failed, 254 filtered; exit 0**. Shows the selected single recovery regression passed.
- The owner machine has RTX 5090 and driver 617.42, but this particular log lacks an explicit selected-D3D12-adapter line. **UNIT_PASS** on that host; do not silently promote to independently verified physical-device readback.
- Tested source changes are not in VIctory-W main. **No title/gameplay run, visual-quality improvement, FPS or long-duration stability has been verified by this log**. All detailed local logs retained privately; public GitHub records only this non-proprietary summary.

**Current synthetic evidence set:** main `63bcca43`: 21/22 selected descriptor tests; #3300 `01f91fea`: 16/16 descriptor-host; #2683 `aecd6042`: 24/24 descriptor; #2121 `0bc5edbd`: 37/37 descriptor plus 1/1 recovery. **Filters are not identical, so pass counts are not rankings.**

**Next decision gate:** independently inspect the rest of #2121's GPU/shader regression coverage and determine whether a full Rust GPU/shader test sweep is warranted before an isolated release build. Preserve the existing executable and separate target/cache; keep game files outside Git. Validate actual correctness in comparable scenes before any FPS claim. [#2121](https://github.com/Marvisak/VIctory/pull/2121) may advance: recheck its head before new work.


### Broader #2121 shader validation — real failing NVIDIA test (2026-11-26)

Owner supplied a native-output PowerShell log from exactly pinned #2121 `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608`, isolated detached worktree / Cargo target, with `VICTORY_VIEW_PAGES=1`. First command:

`cargo test -p victory-shader --lib --locked stride_tests -- --test-threads=1 --nocapture`

**FAILED: 9 passed, 1 failed, 297 filtered, process exit 101**. The failing test is `emit::stride_tests::a_heap_buffer_read_by_element_takes_the_views_stride` at `crates/victory-shader/src/emit/stride_tests.rs:311` (the hardware-labeled D3D12 adapter path). Its observed output starts `[101,104,107,110,...]` then zeros, not expected `[200,201,202,...,231]`. The two **paging-specific** shader tests, `a_heap_index_in_a_paged_view_heap_reads_where_its_page_is` and `views_read_in_a_paged_view_heap_mark_their_pages`, **both passed**, as did `a_heap_buffer_read_where_no_buffer_view_is_reads_zeros`.

This precise NVIDIA behavior and essentially identical array were **already documented** in [upstream issue #1835](https://github.com/Marvisak/VIctory/issues/1835): a synthetic `Stride::Structured(12)` test SRV + translated byte-addressed `rawBufferLoad` appears to apply structure stride twice on NVIDIA. The source code in the tested #2121 revision still uses `Stride::Structured(12)` in this fixture, as in clean `main`; it is not evidence of a new paging regression. [Upstream PR #2178](https://github.com/Marvisak/VIctory/pull/2178), last observed **OPEN** at `319749e45737b4dd76e274a88acd0d2504fcd916`, proposes runtime raw-descriptor handling and a test fixture change, but **was neither combined nor run by the owner**. [#1887](https://github.com/Marvisak/VIctory/pull/1887) is a separate closed test-side effort. No independent runtime fix has been established by this local test. Avoid duplicate fixes, silent skip, or auto-import.

**Important execution consequence:** The owner's scripted loop deliberately stopped when the shader test exited 101. Its scheduled second `cargo test -p victory-gpu --lib --locked` and third `cargo build --release --locked -p victory` **did NOT RUN**. There is **no new #2121 release binary** and no title/gameplay A/B in this report. Preserve original `main` and existing executable.

**Next bounded experiment:** test the broader GPU suite and separately build the #2121 release binary in its own target directory without misreporting known shader-test failure as a pass. Any newly failing GPU test needs review *before gameplay*. Do not merge #2178 into #2121 without explicit owner decision and compatibility/regression review. Retain private logs outside Git.


### Full #2121 GPU suite and separate release compilation — owner result (2026-11-26)

Following the previously recorded shader stride failure (9/10; NVIDIA structured SRV double-stride in [#1835](https://github.com/Marvisak/VIctory/issues/1835)), the owner **continued with independent commands** in the *same pinned detached #2121 worktree*, upstream commit `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608`. The Cargo target was isolated from original `main`, `VICTORY_VIEW_PAGES=1` was set in the PowerShell test/build session, and the log retained native test output.

- `cargo test -p victory-gpu --lib --locked -- --test-threads=1 --nocapture`: **255 tests discovered; 254 passed, 0 failed, 1 ignored, 0 filtered; exit 0**. This includes selected GPU paging, take-back/reuse, cross-heap retained-read, resource and shader-cache checks, and `frame::tests::waits_end_on_ticks_and_count_frames` (passed here). The `pipeline::depth_bounds_test::depth_bounds_control_a_title_draw` readback explicitly identified **NVIDIA GeForce RTX 5090** and returned depth values `[0.25,0.5,0.25,0.25]`. One `pipeline::library` test intentionally emitted a handled panic and **passed**; the one ignored test is `object::tests::benchmark_private_data_release` (synthetic benchmark).
- `cargo build --release --locked -p victory`: **SUCCEEDED, exit 0** in its independent build step. Built source-only experimental `victory.exe` in the `C:\\vtw\\test-pr2121\\release` target directory; **SHA-256 `23C448079195186D0401E73B96EBCFB706199D4CF79543597E3AA2DBC0FC4E68`**. This binary hash is for the open-source compatibility application, **not** any title asset.
- **Evidence tier:** GPU full-suite `UNIT_PASS`, native RTX 5090 depth readback in one GPU test, and **RELEASE_BUILD_PASS** (new evidence, not `GAMEPLAY_OBSERVED`). The earlier `victory-shader stride_tests` failure **is unresolved and remains a separate FAIL**, and the complete shader test suite was **not run**. No title launched in this report and no scene/FPS/stability results claimed. Neither source `main` nor existing release exe were replaced. Full local report remains private.

**Next meaningful gate:** run the experimental paging executable in a controlled private title session, with `VICTORY_VIEW_PAGES=1`, dedicated `VICTORY_CACHE_DIR` / `VICTORY_DATA_DIR` *outside source trees*, pinned source/executable hashes, and the same title/console mode/scene as the baseline. Collect concise startup/paging/frame observations while keeping proprietary title logs, dumps, screenshots and shader caches out of public GitHub. A build/green GPU suite alone cannot establish improved geometry.


### First source-built #2121 native-launch attempt — exit 1 with no native output (2026-11-26)

Owner's uploaded private PowerShell log for the pinned experimental #2121 executable contains exactly four substantive lines: "PR #2121 first native execution", full pinned source commit `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608`, "Paging enabled: 1", and **"Title exit code: 1"**. It contains **zero VIctory-generated startup/build/mapping, application errors or GPU/scene lines**.

**Evidence classification: UNKNOWN, not a confirmed game or runtime failure.** The prior PowerShell script ran the test binary through `cmd.exe /D /S /C` with multiple nested quotation marks and piped output into `Tee-Object`. The Windows wrapper/capture could be at fault; the log does **not** establish that `victory.exe` successfully started or reached title initialization. Reading `apps/victory/src/main.rs` and `run.rs` at this exact source SHA shows a normal `run` reports title build/mapped-image information after reading/preparing the executable; `--execute` is needed to actually run the title. Failed preflight or missing data may also exit before those messages, but native error text should be captured.

**Next diagnostic:** invoke exact hash-verified `victory.exe` **directly in PowerShell, without `cmd.exe`**, verify `--version` output and `config`, then attempt `run <title-exe> --console series-x` (without `--execute`) to isolate import/map preparation. Only when those succeed, attempt `run <title-exe> --execute --console series-x`. Preserve independent `VICTORY_CACHE_DIR` and `VICTORY_DATA_DIR`, proper stdout/stderr capture and explicit process exit codes. Do not share actual title files or publish unredacted logs. Do not rebuild, merge or infer a paging regression from this result.

This evidence is E-020 in the private owner/test record; E-019's **254/254 GPU passes and release build success** remain valid, as does the separate **shader stride FAIL** (E-018, NVIDIA #1835).


### First confirmed native title execution under #2121 paging — 2026-11-26

Following the inconclusive nested-`cmd.exe` attempt E-020, the owner directly invoked the isolated #2121 runtime from Windows PowerShell and supplied a **large native diagnostic report** (private; not committed). The full upload was decoded as UTF-16LE following an ASCII header: **4,514 logical lines**. It includes command-stage results:

- `victory --version`: `victory 0.1.0`, **exit 0**.
- `victory config`: isolated cache/data settings resolved, **exit 0**.
- `victory run <private-title-path> --console series-x` (**no `--execute`**): title build identified, main image and four title DLLs mapped, **zero missing imports** from the bound images; **exit 0**, with the expected `not executing` notice.
- `victory run <private-title-path> --execute --console series-x`: native runtime logs begin **2026-11-26T22:00:22.815Z**; a host D3D12 device initializes, archives open, a **3840x2160** window is reported. Actual `frame presented` logs include frame **2** (2 drawn), **1024** (9,028 draws / 514 dispatches since preceding sample), and **4096** (79,872 draws / 2,048 dispatches since preceding sample), with reports showing `draws=drawn` and `dispatches=dispatched`. Later pipeline first-bind logs reference **frame 6261**; **this is not a direct observed present count beyond frame 4096**.
- **Paging not merely configured, but exercised:** `victory_gpu::descriptor::host` reports `view heap paged`, **1,245,184 logical title slots**, **1,000,000 host slots**, **3,906 logical pages**, 258 fixed. The pager reported **140 pages taken back** and then **134 pages taken back** in separate events; also placement again in groups of 1, 2, 4, 8 and 16, with `refused=0` in those events. No inference about visible-quality improvement or all texture slots is supported by this log.
- **Important outstanding runtime warnings:** 87 `host pipeline refused` messages bearing HRESULT `0x80070057` (invalid argument); separate refused castable texture formats / no host texture for one resource; one `dispatch without a host pipeline dropped`; 16 slow host-submission warnings. These can materially affect rendering, but no screenshot was provided to prove which effect was visible; do not label the paging algorithm or one particular shader as root cause without controlled comparison.
- At **2026-11-26T22:04:34.090Z**, `victory_hle::modules::lifecycle` reported `window closed: suspending the title`; ~1 second later reported `title did not finish suspending in time; ending the title`; host pipeline-library save followed at 22:04:35.126Z. The uploaded output **does not include the final `EXIT CODE (Actual title execution)`**. Do **not** claim the game crashed, completed cleanly, or that the user manually closed the window; only the window-close sequence is recorded.

**Evidence level:** `GPU_PASS` for actual, running title + presented frame logs + exercised paging (sanitized [E-021](https://github.com/JohnTWillemsen/VIctory-W/pull/1)), **NOT** visually correct gameplay, stable completion, improved geometry or FPS. This **corrects the limitation of the earlier wrapper E-020**; it does not erase the previous failed shader-stride test E-018.

**Next gate:** solicit the owner's firsthand **visible window/scene observation** (black screen, logo, menu, loading, geometry, visual artifacts, timing, how the window closed). Only then choose a controlled same-title baseline A/B; investigate repeated host-pipeline HRESULT `0x80070057` and resource format failures as a separate documented hypothesis. Retain raw logs, shader cache entries, shader hashes and title assets outside Git. Do not merge #2121 blindly or change original release executable.


### Owner-visible scene-transition stall — "Two Years Ago" card, audio continues (2026-11-26)

After the previous 4m13 native #2121 session (E-021), the owner confirmed **what was actually visible**: the on-screen **"Two Years Ago"** title card appeared, then remained visually frozen, while audio continued and appeared to belong to the subsequent scene. This is **GAMEPLAY_OBSERVED (intro/title-card only)**, **NOT** proof that the world was rendered, interactive, or stable. No screenshot or exact onset timestamp was provided, and it is unknown whether the owner closed the window or the process was terminated externally.

**Correlation, not a causal proof:** E-021 records `frame presented` counters through frame 4,096 at 22:02:44Z, then shader translation/pipeline creation continues. The **first of 87 refused compute host pipelines** with HRESULT `0x80070057` appears at **22:03:54Z**, with the last at ~22:04:33Z; 16 slow host-submission warnings also occur later. The log records **no explicit GPU device removal/panic**, but has **no final process exit code**. The visual freeze wasn't timestamped by the owner, so cannot assign that onset to 22:03:54Z or conclude Wave64, the page allocator, or texture fallback was the cause.

**Relevant upstream observations:** [#887](https://github.com/Marvisak/VIctory/issues/887) reproduces the named card and severe world-transition rendering trouble on RTX 5060; [#468](https://github.com/Marvisak/VIctory/issues/468) documents black world with continuing audio and refused compute pipelines; [#49](https://github.com/Marvisak/VIctory/issues/49) collects multiple similar visible title-card and transition reports. NVIDIA Wave64-on-Wave32 incompatibility is a plausible explanation for at least some `0x80070057` compute PSOs, explained in [#817](https://github.com/Marvisak/VIctory/issues/817) and [#2220](https://github.com/Marvisak/VIctory/issues/2220). [#189](https://github.com/Marvisak/VIctory/pull/189) offers a **separate unmerged shader emulation experiment**. Neither that fix nor its compatibility with #2121 has been owner-tested. Recheck PR heads before any future trial; no unauthorized stacking.

**Next evidence gate:** controlled D3D12 debug-enabled diagnostics build, separately compiled from the **same #2121 exact source** and isolated target directory, to identify why the first host compute pipelines are refused. Source `crates/victory-gpu/src/host.rs` shows `VICTORY_D3D12_DEBUG=1` only enables the debug layer when built with `--features diagnostics`; setting the variable on the old release binary alone will **not** enable those messages. Use separate cache/data and avoid posting any proprietary shader hashes, game logs, game archives or screenshots publicly. Preserve current runtime and build SHA. Do not raise system-wide TDR timeout without a specific safety reason.

Recorded in the durable audit ledger as E-022.


### D3D12 debug layer CONFIRMS NVIDIA Wave64 compute incompatibility — 2026-11-26

The owner compiled the **same pinned paging source [#2121](https://github.com/Marvisak/VIctory/pull/2121)**, commit `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608`, into a *separate* optimized diagnostics profile with `cargo build --profile diag --locked -p victory --features diagnostics`. The uploaded build report ends **`Finished 'diag' profile [optimized + debuginfo]`** (no compilation errors). The owner executed that binary with **`VICTORY_D3D12_DEBUG=1`** and `VICTORY_VIEW_PAGES=1`, without GPU-based validation or WARP, and with separate data/cache directories. A private screenshot and native UTF-16LE, 6,633-line log were inspected; neither artifact is committed to Git.

**First confirmed causal detail about the failures:** During the live title's world transition, between **22:26:45 and 22:27:11 UTC**, the D3D12 debug layer emitted **91 errors, ID 622**, explicitly stating that a shader **requested 64 wave lanes while the device maximum is 32**. The same session logged **90 rejected compute host pipeline creations**, HRESULT `0x80070057`. This establishes a real **unsupported Wave64 compute-pipeline** condition on the owner RTX 5090, and strongly explains those specific compute PSO refusals. It is not yet proof that addressing those errors will produce correctly drawn geometry or fix every missing frame.

**Owner screenshot and exact trace correlation:** The native title window showed an **almost entirely uniform gray-purple image**, with two dark horizontal borders; caption showed `0 fps 3317.7 ms/frame 3660 draws/frame`. The exact matching host status report at **22:27:22 UTC** reads **`0.3 fps`, `3317.7 ms/frame`, `2974.4 ms on GPU`, `3660 draws/frame`, `1467/frame dropped without a host pipeline`** (794 still being made), and `1382/frame` indirect drops. The 0 FPS title caption is truncated/rounded; the diagnostic run actually advanced at roughly a third of a frame per second near this point. The diagnostics layer may add overhead, so do not directly compare the diagnostic FPS with previous release FPS. Most of this runtime is performing real GPU/submission work rather than CPU startup; however high draw counters alone do not establish a correct frame.

**Other independent renderer problems exposed by the debug layer:** D3D12 ID 1419 reports a missing bound sampler heap before setting a compute root signature with directly-indexed samplers; D3D12 ID 817 and 599 report invalid use of `B4G4R4A4_UNORM` as render-target clear format and `B5G5R5A1_UNORM` for unordered access; a `no host texture` resource failure was observed. Device methods slots `0x218` and `0x1c8` are unimplemented. Multiple D3D12 ID 971 pipeline-library cache misses were also emitted, but these alone are not proof of a faulty pipeline. The title was executing with active paging. The final log shows a **window-close/suspension sequence and process exit code 0**; **this is not equivalent to a correct game or a GPU device removed crash**.

**Next source candidate now justified by NVIDIA diagnostics:** [Marvisak PR #189](https://github.com/Marvisak/VIctory/pull/189), exact last-verified head `3e39e34037915da6d0f10b58b2872799bd9f3ca8`, introduces Wave64 emulation on Wave32 hosts; its proposal reports limitations in divergent control flow and certain LDS/barrier paths. This PR and [#2121](https://github.com/Marvisak/VIctory/pull/2121) are each independently based on `63bcca43c6a00a758510398fa43096ce7e4f7df0` but **modify 8 of the same files**, including shader lowering, emission, host and shader caching. The fixes are therefore **not independent cherry-picks**: inspect and resolve overlaps in a separate staging branch/worktree, preserve alternative builds, run shader Wave64 tests, GPU descriptor/paging suite, NVIDIA live diagnostics and same-scene visual A/B. **No integration or owner test has been carried out.** Do not automatically merge or claim an improved world based on upstream's tests.

This observation is recorded as **E-023** in the sanitized evidence ledger. Preserve older E-018 shader-stride failure, E-021 live native paging success, and E-022 title-card freeze as distinct milestones.


### Wave64 PR #189 independent owner shader test — 40/40 passed (2026-11-26)

Owner uploaded a private UTF-16LE PowerShell log of the exact-head-guarded upstream [PR #189](https://github.com/Marvisak/VIctory/pull/189) detached worktree test. GitHub last verified PR head is `3e39e34037915da6d0f10b58b2872799bd9f3ca8`, on base `63bcca43c6a00a758510398fa43096ce7e4f7df0`. The script first verifies fetched `FETCH_HEAD` equals that SHA before constructing an isolated, detached test worktree, and uses a distinct Cargo target; the uploaded log itself does not independently print the Git commit.

Command: `cargo test -p victory-shader --locked -- wave64 --test-threads=1`.

**Exact owner result:** Compilation finished, **40 Wave64-selected library tests passed, 0 failed, 0 ignored, 301 filtered, exit code 0**. Auxiliary `resource_tracking` selected 0 tests (4 filtered), and doc tests selected 0. The passing set includes native/split/emulated Wave64 lane behavior, GPU-named live synthetic D3D12 tests of 32/64/96/128-thread groups, cross-half ballot and shuffle, workgroup behavior, `v_readlane/v_writelane/readfirstlane`, uniform-fence handling, LDS conflict detection and divergent-control-flow refusal rather than hanging.

**Boundaries:** The owner is testing on an RTX 5090-equipped Windows computer, but this particular log contains **no explicit selected GPU adapter line**; do not assert that each GPU-named subtest selected NVIDIA rather than an alternative device. These are **selected shader unit/GPU tests only**, not the full shader suite, not a `victory-gpu` regression sweep, not a combined #2121+#189 test, not a successful release build and **not proof of visible world rendering**. E-023's 91 Wave64 D3D12 runtime errors on the unmodified #2121 paging build remain valid until a combined runtime demonstrates otherwise.

**Critical source integration detail:** Both [#2121](https://github.com/Marvisak/VIctory/pull/2121) and #189 are currently open against the same original upstream base. Their diffs overlap in **eight code paths** (including shader lowering/emission, host, shader cache, draw and the stride test fixture). Next use a separate experiment branch/worktree, preserve both known original commits, inspect automatic merge conflicts and semantic overlap, then run both Wave64 and descriptor/paging tests before a new live D3D12 run. Upstream #189 also documents partial coverage: divergent flow and some LDS-barrier hazards can be rejected safely rather than emulated. **Do not blindly merge unresolved conflicts or interpret fewer PSO errors alone as visually correct gameplay.** No proprietary logs or title artifacts committed.

Tracked as E-024 in the shared evidence ledger.

## Evidence boundaries

`SOURCE_READ` and `CODE_REVIEWED` apply to source inspection. The owner subsequently supplied **actual synthetic test logs for main, #3300, #2683 and #2121, full #2121 GPU-suite and build logs, a native title runtime trace and firsthand visible-title-card observation**; the dated sections above distinguish these separate sources. **The collector script itself does not run a title or establish FPS**, and the later title-card freeze does not prove a working world or renderer fix.

Private logs may include local source paths. Review before sharing, and **never upload title logs, captures, memory dumps, raw shader data or proprietary binaries to GitHub**. This collector intentionally does not enumerate untracked files, print git remote URLs, or collect game paths.

## Follow-on work

**Current next experiment after E-024:** the separate #2121 diagnostics run (E-023) already confirmed **91 D3D12 Wave64-on-Wave32 errors and an incorrect gray-purple frame**, and #189's **40/40 Wave64-selected tests passed** (E-024). Do not repeat either unchanged experiment for handoff. Source-review both exact PR heads and prepare a **third, isolated paging+Wave64 integration worktree** with independent build/cache and **no changes to original `main`, #2121 or #189 worktrees**. Inspect merge and semantic conflicts (eight overlapping files); do not auto-resolve. Before a game A/B, verify full selected Wave64, descriptor/page tests and GPU suite, then native debug layer with counts of D3D12 Wave64 errors, refused pipelines, dropped dispatches, and visual output. Missing FSPX device slot 0x218, sampler heap and unsupported texture formats remain independent open bugs.
