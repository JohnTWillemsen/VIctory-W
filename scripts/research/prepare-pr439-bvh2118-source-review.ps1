# VIctory-W: source-only merge inspection of upstream #439 and BVH safety #2118.
# PowerShell 5.1+; no title, build, main changes, commit, or push.
[CmdletBinding()]
param(
    [string]$Repository = 'C:\VIctory-W',
    [string]$TestRoot = 'C:\VIctory-Tests',
    [string]$Verification = 'C:\vtw\verification'
)
$ErrorActionPreference = 'Stop'
$Remote = 'https://github.com/Marvisak/VIctory.git'
$Main = '63bcca43c6a00a758510398fa43096ce7e4f7df0'
$Console = 'e2d3cfd50715954fb89ff462edb37a0c4395ecd0'
$Builder = '999a8f67125865fcc0b3aa23cdc8a93b10ef9974'
$Branch = 'experiment/pr439-bvh2118-source-review-20261126'
$Worktree = Join-Path $TestRoot 'pr439-bvh2118-source-review'
$Export = Join-Path $Verification 'pr439-bvh2118-review-source'
$Archive = Join-Path $Verification 'pr439-bvh2118-review-source.zip'
$Log = Join-Path $Verification 'pr439-bvh2118-merge-inspection.txt'

function CheckExit([string]$Stage) {
    if ($LASTEXITCODE -ne 0) { throw "$Stage failed with git exit $LASTEXITCODE" }
}
if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "Source repo not found: $Repository"
}
$ActualMain = (& git -C $Repository rev-parse refs/heads/main).Trim()
CheckExit 'Check main'
if ($ActualMain -ne $Main) {
    throw "Main changed, actual $ActualMain. Stop."
}
foreach ($P in @($Worktree,$Export,$Archive,$Log)) {
    if (Test-Path -LiteralPath $P) {
        throw "Existing output $P. No overwrite attempted."
    }
}
& git -C $Repository show-ref --verify --quiet "refs/heads/$Branch"
if ($LASTEXITCODE -eq 0) { throw "Research branch exists already: $Branch" }
New-Item -ItemType Directory -Force -Path $TestRoot,$Verification | Out-Null

foreach ($Ref in @(
    @{ Number=439; SHA=$Console },
    @{ Number=2118; SHA=$Builder }
)) {
    $Num = $Ref.Number
    & git -C $Repository fetch --quiet --no-tags $Remote "refs/pull/$Num/head"
    CheckExit "Fetch PR #$Num"
    $Actual = (& git -C $Repository rev-parse FETCH_HEAD).Trim()
    CheckExit "Inspect PR #$Num"
    if ($Actual -ne $Ref.SHA) {
        throw "PR #$Num changed ($Actual). Do not use stale merge review."
    }
}
$Prior = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $TreeOutput = @(& git -C $Repository merge-tree --write-tree --name-only $Console $Builder 2>&1 | ForEach-Object { $_.ToString() })
    $TreeExit = $LASTEXITCODE
}
finally { $ErrorActionPreference = $Prior }
if ($TreeExit -ne 0 -and $TreeExit -ne 1) {
    throw "Read-only merge inspection failed: $TreeExit"
}
& git -C $Repository worktree add --quiet -b $Branch $Worktree $Console
CheckExit 'Create independent worktree'
$Head = (& git -C $Worktree rev-parse HEAD).Trim()
CheckExit 'Verify integration HEAD'
if ($Head -ne $Console) { throw "Unexpected worktree HEAD. Stop." }

# The identity and rerere flags apply to THIS command only. No global changes.
$Prior = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $MergeOutput = @(& git -C $Worktree -c user.name=VIctory-Review -c user.email=victory-review@users.noreply.github.com -c rerere.enabled=false merge --no-commit --no-ff $Builder 2>&1 | ForEach-Object { $_.ToString() })
    $MergeExit = $LASTEXITCODE
}
finally { $ErrorActionPreference = $Prior }
if ($MergeExit -ne 0 -and $MergeExit -ne 1) {
    throw "Unexpected merge code $MergeExit. No reset/commit attempted: $Worktree."
}
$Pending = (& git -C $Worktree rev-parse --verify MERGE_HEAD).Trim()
CheckExit 'Verify pending merge'
if ($Pending -ne $Builder) { throw "Unexpected MERGE_HEAD. Stop without changing code." }
$BranchActual = (& git -C $Worktree branch --show-current).Trim()
if ($BranchActual -ne $Branch) { throw "Unexpected branch. Stop." }

$Unmerged = @(& git -C $Worktree diff --name-only --diff-filter=U)
CheckExit 'List conflicts'
$Files = @(
    'apps/victory/src/run.rs',
    'crates/victory-gpu/src/draw.rs',
    'crates/victory-gpu/src/pipeline.rs',
    'crates/victory-gpu/src/pipeline/builder.rs',
    'crates/victory-gpu/src/pipeline/make.rs',
    'crates/victory-gpu/src/pipeline/placed_uav_tests.rs'
)
foreach ($Name in $Unmerged) {
    if ($Name -notin $Files) { throw "Unexpected conflict: $Name. No source exported." }
}
New-Item -ItemType Directory -Force -Path $Export | Out-Null
@(
    'PR #439 + PR #2118 SOURCE-ONLY MERGE REVIEW',
    "main $Main",
    "console $Console",
    "builder $Builder",
    "branch $Branch",
    "HEAD $Head",
    "MERGE_HEAD $Pending",
    "merge-tree exit $TreeExit",
    "merge exit $MergeExit",
    "unmerged count $($Unmerged.Count)",
    'UNMERGED FILES:',
    ($Unmerged -join [Environment]::NewLine),
    'NO TITLE RUN, RUST BUILD, COMMIT, PUSH OR DEFAULT SOURCE CHANGE'
) | Set-Content -LiteralPath $Log -Encoding UTF8
$TreeOutput | Set-Content -LiteralPath (Join-Path $Export 'MERGE_TREE.txt') -Encoding UTF8
$MergeOutput | Set-Content -LiteralPath (Join-Path $Export 'MERGE_OUTPUT.txt') -Encoding UTF8
& git -C $Worktree status --porcelain=v1 -uall | Set-Content -LiteralPath (Join-Path $Export 'STATUS.txt') -Encoding UTF8
& git -C $Worktree ls-files -u | Set-Content -LiteralPath (Join-Path $Export 'INDEX_UNMERGED.txt') -Encoding UTF8
& git -C $Worktree diff --cc | Set-Content -LiteralPath (Join-Path $Export 'DIFF_COMBINED.patch') -Encoding UTF8
& git -C $Worktree diff --cached | Set-Content -LiteralPath (Join-Path $Export 'DIFF_STAGED.patch') -Encoding UTF8
foreach ($Name in $Files) {
    $From = Join-Path $Worktree $Name
    if (-not (Test-Path -LiteralPath $From -PathType Leaf)) {
        throw "Expected public Rust source missing: $Name"
    }
    $To = Join-Path (Join-Path $Export 'source') $Name
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $To) | Out-Null
    Copy-Item -LiteralPath $From -Destination $To
}
Compress-Archive -Path (Join-Path $Export '*') -DestinationPath $Archive -CompressionLevel Optimal
Write-Host "Read-only merge-tree status: $TreeExit; pending merge status: $MergeExit"
Write-Host "Unresolved source files: $($Unmerged.Count)"
Write-Host "Code-only archive: $Archive"
Write-Host "Merge report: $Log"
Write-Host 'NO commit, push, title launch or original worktree change.'
Write-Host 'Leave merge pending. Do not resolve/stage/compile until we review the archive.'
