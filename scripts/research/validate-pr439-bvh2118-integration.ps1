# VIctory-W: validate the source-only, pending #439 console-flow + #2118 BVH merge.
# Windows PowerShell 5.1+. No title launch, commit, push or change to main.
# The known NVIDIA capped-heap descriptor test can fail on main-derived source;
# record full GPU result independently rather than concealing it.
[CmdletBinding()]
param(
    [string]$Worktree = 'C:\VIctory-Tests\pr439-bvh2118-source-review',
    [string]$Target = 'C:\vtw\test-pr439-bvh2118-combined',
    [string]$Report = 'C:\vtw\verification\pr439-bvh2118-integration-validation.txt'
)
$ErrorActionPreference = 'Stop'
$Console = 'e2d3cfd50715954fb89ff462edb37a0c4395ecd0'
$Builder = '999a8f67125865fcc0b3aa23cdc8a93b10ef9974'
$MergeTree = '9f8bb36f497fdfffd9d68f2f2b22b0284899ae10'
$Branch = 'experiment/pr439-bvh2118-source-review-20261126'
$Expected = @(
    'M  apps/victory/src/run.rs',
    'M  crates/victory-gpu/src/draw.rs',
    'M  crates/victory-gpu/src/pipeline.rs',
    'A  crates/victory-gpu/src/pipeline/builder.rs',
    'M  crates/victory-gpu/src/pipeline/make.rs',
    'M  crates/victory-gpu/src/pipeline/placed_uav_tests.rs'
)
function CheckGit([string]$Stage) {
    if ($LASTEXITCODE -ne 0) { throw "$Stage failed, git exit $LASTEXITCODE" }
}
if (-not (Test-Path -LiteralPath $Worktree -PathType Container)) {
    throw "Integration worktree not found: $Worktree"
}
if (Test-Path -LiteralPath $Report) {
    throw "Previous validation report exists: $Report. Rename/archive it before retrying."
}
$Head = (& git -C $Worktree rev-parse HEAD).Trim()
CheckGit 'HEAD'
$Pending = (& git -C $Worktree rev-parse --verify MERGE_HEAD).Trim()
CheckGit 'MERGE_HEAD'
$ActualBranch = (& git -C $Worktree branch --show-current).Trim()
CheckGit 'branch'
if ($Head -ne $Console -or $Pending -ne $Builder -or $ActualBranch -ne $Branch) {
    throw "Wrong source refs or branch. Do not test this tree."
}
$ActualStatus = @(& git -C $Worktree status --porcelain=v1 -uall)
CheckGit 'working tree status'
$Diff = @(Compare-Object -ReferenceObject ($Expected | Sort-Object) -DifferenceObject ($ActualStatus | Sort-Object))
if ($Diff.Count -ne 0) {
    throw "Working tree has unexpected staged/unstaged/untracked content. Stop."
}
$StagedTree = (& git -C $Worktree write-tree).Trim()
CheckGit 'read staged source tree'
if ($StagedTree -ne $MergeTree) {
    throw "The auto-merged index differs from the inspected source tree. Stop."
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Report) | Out-Null
@(
    'VIctory-W PR #439 + #2118 AUTO-MERGED SOURCE VALIDATION',
    "HEAD $Head",
    "MERGE_HEAD $Pending",
    "INDEX_TREE $StagedTree",
    "BRANCH $ActualBranch",
    "Start $(Get-Date -Format o)",
    'NO TITLE EXECUTION, COMMIT, PUSH OR SOURCE EDIT'
) | Set-Content -LiteralPath $Report -Encoding Unicode

function Note([string]$Message) {
    $Message | Tee-Object -FilePath $Report -Append | Out-Host
}
function CargoStep([string]$Title,[string]$Command,[bool]$Fatal = $true) {
    Note "=== $Title ==="
    Note "COMMAND: $Command"
    & $env:ComSpec /D /C ($Command + ' 2>&1') |
        ForEach-Object { $_.ToString() } |
        Tee-Object -FilePath $Report -Append |
        Out-Host
    $Exit = $LASTEXITCODE
    Note "$Title EXIT CODE: $Exit"
    if ($Fatal -and $Exit -ne 0) {
        throw "$Title failed, exit $Exit. Do not run the title or commit."
    }
    return [int]$Exit
}

$PriorTarget = [Environment]::GetEnvironmentVariable('CARGO_TARGET_DIR','Process')
$PriorWarp = [Environment]::GetEnvironmentVariable('VICTORY_WARP','Process')
$PriorD3DWarp = [Environment]::GetEnvironmentVariable('VICTORY_D3D12_WARP','Process')
$env:CARGO_TARGET_DIR = $Target
$env:VICTORY_WARP = $null
$env:VICTORY_D3D12_WARP = $null
Push-Location $Worktree
try {
    Note "CARGO_TARGET_DIR=$Target"
    $Check = CargoStep 'WORKSPACE CHECK' 'cargo check --workspace --all-targets --locked'
    $Split = CargoStep 'CONSOLE SPLIT SHADERS' 'cargo test -p victory-shader --lib --locked split_tests -- --test-threads=1 --nocapture'
    $Loops = CargoStep 'DIVERGENT LANE LOOPS' 'cargo test -p victory-shader --lib --locked lane_read_loop_tests -- --test-threads=1 --nocapture'
    $BVH = CargoStep 'BVH BUILDER GATE' 'cargo test -p victory-gpu --lib --locked builder -- --test-threads=1 --nocapture'
    $Release = CargoStep 'INDEPENDENT OPTIMIZED RELEASE BUILD' 'cargo build --release --locked -p victory'

    $Exe = Join-Path $Target 'release\victory.exe'
    if (-not (Test-Path -LiteralPath $Exe)) {
        throw "Cargo reported release success but runtime binary is not at $Exe"
    }
    $Hash = (Get-FileHash -LiteralPath $Exe -Algorithm SHA256).Hash
    Note "COMBINED RUNTIME SHA256: $Hash"

    # Diagnostic full suite, independent of the source/targeted-test/release
    # gates. The original main had a cap-assumption descriptor unit failure on
    # RTX 5090, so never silently treat it as a new #2118 regression.
    $GPU = CargoStep 'FULL GPU LIB SUITE (INDEPENDENT)' 'cargo test -p victory-gpu --lib --locked -- --test-threads=1 --nocapture' $false
    if ($GPU -eq 0) {
        Note 'FULL GPU SUITE: PASS. No title/game validation implied.'
    }
    else {
        Note "FULL GPU SUITE: EXIT $GPU. Inspect failing names vs source-clean capped-heap baseline before deciding regression."
    }
    Note 'ALL REQUIRED SOURCE/TARGETED TEST/RELEASE GATES PASSED.'
    Note 'No title was launched, no source was edited or committed.'
}
finally {
    Pop-Location
    [Environment]::SetEnvironmentVariable('CARGO_TARGET_DIR',$PriorTarget,'Process')
    [Environment]::SetEnvironmentVariable('VICTORY_WARP',$PriorWarp,'Process')
    [Environment]::SetEnvironmentVariable('VICTORY_D3D12_WARP',$PriorD3DWarp,'Process')
    Note "End $(Get-Date -Format o)"
    Note "Private report: $Report"
}
