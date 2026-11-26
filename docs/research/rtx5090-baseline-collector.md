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

This adds `cargo fmt --all -- --check`, `cargo test -p victory-gpu --lib --locked descriptor -- --test-threads=1 --nocapture`, and `cargo xtask policy`, and saves a separate synthetic report. Cargo may take time to build, need MSVC tools, and exercise GPU tests which skip when appropriate. **Read actual test counts and device selection**, not just the script's final command status. Commands that fail are reported and do not automatically rewrite or delete anything. The script defaults `CARGO_TARGET_DIR` to `C:\vtw` if not already set in this session.

Do not change machine-wide script execution policy. Follow your organization's normal policy for reviewing and permitting a single downloaded script. If Windows blocks it, contact your administrator rather than changing security defaults.

## Evidence boundaries

`SOURCE_READ` and `CODE_REVIEWED` apply to script/PR source inspection only. Tests on the owner's machine remain `NOT_RUN` until their log is provided. No title test or FPS claim follows from this collector.

Private logs may include local source paths. Review before sharing, and **never upload title logs, captures, memory dumps, raw shader data or proprietary binaries to GitHub**. This collector intentionally does not enumerate untracked files, print git remote URLs, or collect game paths.

## Follow-on work

Once an exact clean baseline and local test environment are known, the orchestrator can provide separate short-path test worktrees for [upstream PR #2683](https://github.com/Marvisak/VIctory/pull/2683) (descriptor clamp) and [#2121](https://github.com/Marvisak/VIctory/pull/2121) (view-heap paging), using **their latest heads** and separate build/cache directories. No wholesale merge; test correctness and scene visuals before FPS.
