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

## Evidence boundaries

`SOURCE_READ` and `CODE_REVIEWED` apply to script/PR source inspection only. Tests on the owner's machine remain `NOT_RUN` until their log is provided. No title test or FPS claim follows from this collector.

Private logs may include local source paths. Review before sharing, and **never upload title logs, captures, memory dumps, raw shader data or proprietary binaries to GitHub**. This collector intentionally does not enumerate untracked files, print git remote URLs, or collect game paths.

## Follow-on work

Once an exact clean baseline and local test environment are known, the orchestrator can provide separate short-path test worktrees for [upstream PR #2683](https://github.com/Marvisak/VIctory/pull/2683) (descriptor clamp) and [#2121](https://github.com/Marvisak/VIctory/pull/2121) (view-heap paging), using **their latest heads** and separate build/cache directories. No wholesale merge; test correctness and scene visuals before FPS.
