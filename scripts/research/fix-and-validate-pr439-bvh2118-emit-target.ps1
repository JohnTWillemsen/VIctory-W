# VIctory-W: one-line test-only shader-emitter API adaptation for merged #439 + #2118.
# Windows PowerShell 5.1+. Exact-tree guarded, backup before edit, no commit/push/title.
# Corrects E0061 in PR #2118's ending_shader test: PR #439 emit() requires Target.
[CmdletBinding()]
param(
    [string]$Worktree = 'C:\VIctory-Tests\pr439-bvh2118-source-review',
    [string]$Target = 'C:\vtw\test-pr439-bvh2118-combined',
    [string]$Report = 'C:\vtw\verification\pr439-bvh2118-api-fix-validation.txt'
)
$ErrorActionPreference = 'Stop'
$Head = 'e2d3cfd50715954fb89ff462edb37a0c4395ecd0'
$Merge = '999a8f67125865fcc0b3aa23cdc8a93b10ef9974'
$Branch = 'experiment/pr439-bvh2118-source-review-20261126'
$OriginalTree = '9f8bb36f497fdfffd9d68f2f2b22b0284899ae10'
$File = 'crates/victory-gpu/src/pipeline.rs'
$OldHash = 'BE8CA499438B8D89B869D58D0749171F62CE92F5860BE2A3A788B5C08D0687AF'
$NewHash = '7F172A4D048FE74F8DBFA250F49DB2FD5A816456A849CC824FAA237B52B3CB73'
$OldCall = 'emit::emit(&c, &native, &p, &st, &io, &res).unwrap()'
$NewCall = 'emit::emit(&c, &native, &p, &st, &io, &res, emit::Target::ANY).unwrap()'
$ExpectedStatus = @(
    'M  apps/victory/src/run.rs',
    'M  crates/victory-gpu/src/draw.rs',
    'M  crates/victory-gpu/src/pipeline.rs',
    'A  crates/victory-gpu/src/pipeline/builder.rs',
    'M  crates/victory-gpu/src/pipeline/make.rs',
    'M  crates/victory-gpu/src/pipeline/placed_uav_tests.rs'
)
function AssertGit([string]$Step) {
    if ($LASTEXITCODE -ne 0) { throw "$Step failed, git exit $LASTEXITCODE" }
}
if (-not (Test-Path -LiteralPath $Worktree -PathType Container)) {
    throw "Expected experimental worktree missing: $Worktree"
}
if (Test-Path -LiteralPath $Report) {
    throw "Existing report not overwritten: $Report"
}
$RepoHead = (& git -C $Worktree rev-parse HEAD).Trim()
AssertGit 'HEAD'
$Pending = (& git -C $Worktree rev-parse --verify MERGE_HEAD).Trim()
AssertGit 'MERGE_HEAD'
$ActualBranch = (& git -C $Worktree branch --show-current).Trim()
AssertGit 'Branch'
if ($RepoHead -ne $Head -or $Pending -ne $Merge -or $ActualBranch -ne $Branch) {
    throw "Wrong source refs/branch. No edit performed."
}
$Status = @(& git -C $Worktree status --porcelain=v1 -uall)
AssertGit 'Status'
$Difference = @(Compare-Object ($ExpectedStatus | Sort-Object) ($Status | Sort-Object))
if ($Difference.Count -ne 0) {
    throw "Unexpected staged, unstaged, or untracked source changes. No edit performed."
}
$TreeBefore = (& git -C $Worktree write-tree).Trim()
AssertGit 'Index tree before'
if ($TreeBefore -ne $OriginalTree) {
    throw "Source index tree differs from E-031 inspected tree. No edit performed."
}
$Source = Join-Path $Worktree $File
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "Expected Rust file missing. No edit performed."
}
$SourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
if ($SourceHash -ne $OldHash) {
    throw "The original Rust file SHA256 differs from the inspected owner ZIP. No edit."
}
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Text = $Utf8.GetString([System.IO.File]::ReadAllBytes($Source))
if (-not $Text.Contains($OldCall) -or $Text.IndexOf($OldCall) -ne $Text.LastIndexOf($OldCall)) {
    throw "One unique outdated emit call was expected. No edit."
}

$Dir = Split-Path -Parent $Report
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$Backup = Join-Path $Dir 'pr439-bvh2118-pipeline-before-api-fix.rs'
if (Test-Path -LiteralPath $Backup) {
    throw "Existing source backup not overwritten: $Backup"
}
[System.IO.File]::WriteAllBytes($Backup, [System.IO.File]::ReadAllBytes($Source))

$Changed = $Text.Replace($OldCall, $NewCall)
$NewBytes = $Utf8.GetBytes($Changed)
$CalculatedHash = [BitConverter]::ToString(
    ([Security.Cryptography.SHA256]::Create()).ComputeHash($NewBytes)
).Replace('-', '')
if ($CalculatedHash -ne $NewHash) {
    throw "Patched bytes differ from the source-reviewed single-line change. Source untouched."
}
[System.IO.File]::WriteAllBytes($Source, $NewBytes)
if ((Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash -ne $NewHash) {
    throw "Failed to verify written source. Backup kept at $Backup; stop."
}
# Stage ONLY the reviewed test-only one-line fix. No Git commit, no push.
& git -C $Worktree add -- $File
AssertGit 'Stage reviewed API fix'
$TreeAfter = (& git -C $Worktree write-tree).Trim()
AssertGit 'Patched index tree'
if ($TreeAfter -eq $OriginalTree) {
    throw "Patched index tree did not change; stop."
}
$AfterStatus = @(& git -C $Worktree status --porcelain=v1 -uall)
AssertGit 'Status after patch'
$AfterDiff = @(Compare-Object ($ExpectedStatus | Sort-Object) ($AfterStatus | Sort-Object))
if ($AfterDiff.Count -ne 0) {
    throw "Unexpected source status after patch; stop."
}

@(
    'VIctory-W PR #439 + #2118 E0061 TEST-ONLY EMIT TARGET FIX',
    "HEAD: $RepoHead",
    "MERGE_HEAD: $Pending",
    "BRANCH: $ActualBranch",
    "OLD_INDEX_TREE: $OriginalTree",
    "NEW_INDEX_TREE: $TreeAfter",
    "PATCHED_FILE_SHA256: $NewHash",
    "SOURCE_BACKUP: $Backup",
    "CARGO_TARGET_DIR: $Target",
    "START: $(Get-Date -Format o)",
    'SOURCE CHANGE: ONLY pipeline.rs ending_shader emit API; NO RUNTIME CHANGE',
    'NO COMMIT, PUSH, MERGE FINALIZATION OR TITLE LAUNCH'
) | Set-Content -LiteralPath $Report -Encoding Unicode
function Note([string]$Line) {
    $Line | Tee-Object -FilePath $Report -Append | Out-Host
}
function CargoStep([string]$Name, [string]$Command, [bool]$Fatal = $true) {
    Note "=== $Name ==="
    Note "COMMAND: $Command"
    & $env:ComSpec /D /C ($Command + ' 2>&1') |
        ForEach-Object { $_.ToString() } |
        Tee-Object -FilePath $Report -Append | Out-Host
    $Code = $LASTEXITCODE
    Note "$Name EXIT CODE: $Code"
    if ($Fatal -and $Code -ne 0) {
        throw "$Name failed (exit $Code). Stop without committing or launching."
    }
    return [int]$Code
}
$OldTarget = [Environment]::GetEnvironmentVariable('CARGO_TARGET_DIR','Process')
$OldWarp = [Environment]::GetEnvironmentVariable('VICTORY_WARP','Process')
$OldD3DWarp = [Environment]::GetEnvironmentVariable('VICTORY_D3D12_WARP','Process')
$env:CARGO_TARGET_DIR = $Target
$env:VICTORY_WARP = $null
$env:VICTORY_D3D12_WARP = $null
Push-Location $Worktree
try {
    $Check = CargoStep 'WORKSPACE CHECK' 'cargo check --workspace --all-targets --locked'
    $Split = CargoStep 'CONSOLE SPLIT SHADERS' 'cargo test -p victory-shader --lib --locked split_tests -- --test-threads=1 --nocapture'
    $Loops = CargoStep 'DIVERGENT LANE LOOPS' 'cargo test -p victory-shader --lib --locked lane_read_loop_tests -- --test-threads=1 --nocapture'
    $BVH = CargoStep 'BVH BUILDER GATE' 'cargo test -p victory-gpu --lib --locked builder -- --test-threads=1 --nocapture'
    $Release = CargoStep 'ISOLATED OPTIMIZED RELEASE BUILD' 'cargo build --release --locked -p victory'
    $Exe = Join-Path $Target 'release\victory.exe'
    if (-not (Test-Path -LiteralPath $Exe -PathType Leaf)) {
        throw "Cargo reported build success, but victory.exe missing from target."
    }
    Note "COMBINED RUNTIME SHA256: $((Get-FileHash -LiteralPath $Exe -Algorithm SHA256).Hash)"
    $GPU = CargoStep 'FULL GPU LIB SUITE (INDEPENDENT)' 'cargo test -p victory-gpu --lib --locked -- --test-threads=1 --nocapture' $false
    if ($GPU -ne 0) {
        Note "FULL GPU EXIT $GPU: inspect all failed names; source-clean RTX5090 descriptor cap test may predate this merge."
    } else {
        Note 'FULL GPU SUITE PASS.'
    }
    Note 'REQUIRED COMPILE, TARGETED SHADER/BVH, RELEASE GATES PASS. NO GAME RUN.'
}
finally {
    Pop-Location
    [Environment]::SetEnvironmentVariable('CARGO_TARGET_DIR', $OldTarget, 'Process')
    [Environment]::SetEnvironmentVariable('VICTORY_WARP', $OldWarp, 'Process')
    [Environment]::SetEnvironmentVariable('VICTORY_D3D12_WARP', $OldD3DWarp, 'Process')
    Note "END: $(Get-Date -Format o)"
    Note "PRIVATE LOG: $Report"
}
