# Owner's separate NVIDIA local workspace — operating contract

**Dated agreement:** 2026-11-27 America/Phoenix. **GitHub is the only shared project source of truth.** The owner has chosen a **fresh local checkout**, **not a new GitHub repository**. The existing GitHub repository is `JohnTWillemsen/VIctory-W` with active NVIDIA-based `main`; historical AMD-era development remains in Git history and the archive branch. Never tell future agents this is an entirely new GitHub repo.

## The four distinct locations

| Windows location | Purpose | Rule |
| --- | --- | --- |
| `C:\VIctory-NVIDIA` | **New clone** of live `JohnTWillemsen/VIctory-W` `main`; source code, `.git`, Rust toolchain, and new `target\release` builds | **Only active local source/build checkout.** Do not copy old binaries, experimental config, caches, `.git` folders or patch worktrees into it. |
| `C:\VIctory-NVIDIA-Tests` | **New owner test root** for sanitized E127 ZIP sessions, `PRIVATE-never-upload` local data, crash recovery and separately labeled build artifacts | All new `owner-nvidia-session.ps1` runs use `-ReportRoot 'C:\VIctory-NVIDIA-Tests'`; its source default should match as a fallback. Do not put test sessions inside Git. |
| `C:\VIctory-W` | **Old owner's local development folder** from pre-NVIDIA experiments | **Leave untouched.** Never run `git pull`, clean, delete, overwrite or use compiled `victory.exe` from here for the new testing baseline. |
| Owner's existing game files | Title files, saves, caches and dependencies | **Leave in their existing local directory**. Do not move/copy to a Git checkout, commit, upload, publish game paths, or treat them as source code. Only reference the user's own confirmed local game executable when launching with consent. |

**Setup state:** Planned and documented, **NOT VERIFIED AS CREATED ON OWNER'S PC**. Remote GitHub operations cannot create any of these local folders. A future agent must ask for/verify actual local setup output; don't infer completion from this document.

## First-time bootstrap — normal, non-administrator PowerShell

The owner can run these commands on their own Windows PC; they perform **no game launch, GPU test, source build, or deletion**.

```powershell
$ErrorActionPreference = 'Stop'
$Repo = 'C:\VIctory-NVIDIA'
$Tests = 'C:\VIctory-NVIDIA-Tests'
$Remote = 'https://github.com/JohnTWillemsen/VIctory-W.git'

if (Test-Path -LiteralPath $Repo) {
    throw "$Repo already exists. Inspect it; never overwrite an existing checkout."
}
git --version
if ($LASTEXITCODE -ne 0) { throw 'Install Git for Windows before proceeding.' }

git clone --branch main $Remote $Repo
if ($LASTEXITCODE -ne 0) { throw 'Git clone failed; leave any partial checkout for inspection.' }
New-Item -ItemType Directory -Force -Path $Tests | Out-Null

git -C $Repo remote -v
git -C $Repo branch --show-current
git -C $Repo rev-parse HEAD
git -C $Repo status --short
Write-Host 'New NVIDIA local source and testing folders ready for verification.'
```

**Acceptance:** `origin` points at `JohnTWillemsen/VIctory-W.git`; branch is `main`; HEAD is the **currently verified live GitHub main** (not a forever-pinned historical commit); local `git status --short` is empty; `C:\VIctory-NVIDIA-Tests` exists; old `C:\VIctory-W` and game folders were not modified. If `C:\VIctory-NVIDIA` already exists, inspect its Git remote/branch/worktree rather than cloning over it.

## Continued workflow and correct report root

- All source edits, Rust compilation, new experiments and branch operations use `C:\VIctory-NVIDIA`. Branches must still be created/reviewed/merged through the **single existing GitHub repository**; a local clone is not a new remote fork.
- CI artifact downloads may go to a clearly labeled subdirectory under `C:\VIctory-NVIDIA-Tests` (e.g. `builds`), **not** the old `C:\VIctory-Tests` or old `C:\VIctory-W`. Never substitute a historical binary without hash verification.
- E127 first-run launch is manual, not an onboarding step. Only after passing source-release and privacy-fixture verification and explicit `PLAY` consent, invoke the source-matching `scripts\research\owner-nvidia-session.ps1` from the new source tree and **always pass** `-ReportRoot 'C:\VIctory-NVIDIA-Tests'`, with a source-built executable and its actual verified SHA-256. This overrides any older script's `C:\VIctory-Tests` default.
- Use E127 `-Mode Recover -RunFolder '<new session folder>'` after an unexpected reboot; it reconstructs from private new-root data without replaying the title. Request/upload only that run's fixed-schema `E127-anonymous-summary.zip`. Raw files including `PRIVATE-never-upload` and `home` stay on the PC.
- All future session prompts and automation must **read this file** and [HANDOFF.md](HANDOFF.md) from **live GitHub `main`**, not assume a local directory exists. Update documented local paths via reviewed GitHub changes if the owner later changes them.

## Scope and constraints

The NVIDIA-based source is already on VIctory-W `main` through [PR37](https://github.com/JohnTWillemsen/VIctory-W/pull/37). Original source archive: `archive/pre-nvidia-foundation-20261127`. The local folder rename provides **environment isolation**, not a second GitHub repository or proof of working game. No NVIDIA-v8 owner's physical RTX5090 World+Controls run was verified when this guide was written. Separate source CI, synthetic/WARP tests and real playability.
