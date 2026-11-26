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

## Evidence boundaries

`SOURCE_READ` and `CODE_REVIEWED` apply to source inspection. The owner has provided **actual synthetic test logs for main, #3300, and #2683**, with results above; future experiments remain `NOT_RUN` until their own logs are supplied. No title test or FPS claim follows from this collector.

Private logs may include local source paths. Review before sharing, and **never upload title logs, captures, memory dumps, raw shader data or proprietary binaries to GitHub**. This collector intentionally does not enumerate untracked files, print git remote URLs, or collect game paths.

## Follow-on work

Once an exact clean baseline and local test environment are known, the orchestrator can provide separate short-path test worktrees for [upstream PR #2683](https://github.com/Marvisak/VIctory/pull/2683) (descriptor clamp) and [#2121](https://github.com/Marvisak/VIctory/pull/2121) (view-heap paging), using **their latest heads** and separate build/cache directories. No wholesale merge; test correctness and scene visuals before FPS.
