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

## Evidence boundaries

`SOURCE_READ` and `CODE_REVIEWED` apply to source inspection. The owner has provided **actual synthetic test logs for main, #3300, and #2683**, with results above; future experiments remain `NOT_RUN` until their own logs are supplied. No title test or FPS claim follows from this collector.

Private logs may include local source paths. Review before sharing, and **never upload title logs, captures, memory dumps, raw shader data or proprietary binaries to GitHub**. This collector intentionally does not enumerate untracked files, print git remote URLs, or collect game paths.

## Follow-on work

Once an exact clean baseline and local test environment are known, the orchestrator can provide separate short-path test worktrees for [upstream PR #2683](https://github.com/Marvisak/VIctory/pull/2683) (descriptor clamp) and [#2121](https://github.com/Marvisak/VIctory/pull/2121) (view-heap paging), using **their latest heads** and separate build/cache directories. No wholesale merge; test correctness and scene visuals before FPS.
