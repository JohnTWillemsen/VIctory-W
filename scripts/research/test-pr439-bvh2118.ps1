# VIctory-W: conservative, separate upstream Wave64 console-flow + BVH gate validation.
# Windows PowerShell 5.1+. DOES NOT merge, commit, push, change main, or launch a title.
# Source must match pinned upstream SHA exactly. Save raw log privately.
[CmdletBinding()]
param(
    [string]$Repository = 'C:\VIctory-W',
    [string]$TestRoot = 'C:\VIctory-Tests',
    [string]$WorkRoot = 'C:\vtw'
)
$ErrorActionPreference = 'Stop'
$Remote = 'https://github.com/Marvisak/VIctory.git'
$MainSHA = '63bcca43c6a00a758510398fa43096ce7e4f7df0'
$LogFolder = Join-Path $WorkRoot 'verification'
$Log = Join-Path $LogFolder 'pr439-bvh2118-independent-tests.txt'
$Targets = @(
    @{
        Number = 439
        Name = 'console-wave64-pr439'
        SHA = 'e2d3cfd50715954fb89ff462edb37a0c4395ecd0'
        Steps = @(
            'cargo test -p victory-shader --lib --locked split_tests -- --test-threads=1 --nocapture',
            'cargo test -p victory-shader --lib --locked lane_read_loop_tests -- --test-threads=1 --nocapture'
        )
    },
    @{
        Number = 2118
        Name = 'bvh-builder-gate-pr2118'
        SHA = '999a8f67125865fcc0b3aa23cdc8a93b10ef9974'
        Steps = @(
            'cargo test -p victory-gpu --lib --locked builder -- --test-threads=1 --nocapture'
        )
    }
)

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "Local VIctory-W repository missing: $Repository"
}
$ActualMain = (& git -C $Repository rev-parse refs/heads/main).Trim()
if ($LASTEXITCODE -ne 0 -or $ActualMain -ne $MainSHA) {
    throw "VIctory-W/main is not the pinned source base. Actual: $ActualMain. Stop."
}
New-Item -ItemType Directory -Path $LogFolder, $TestRoot -Force | Out-Null
@(
    'VIctory-W source-clean, independent PR #439 + #2118 research',
    'No title launch, merge, commit or push.',
    "Pinned main: $MainSHA",
    "Start: $(Get-Date -Format o)"
) | Set-Content -LiteralPath $Log -Encoding Unicode

function Note([string]$Message) {
    $Message | Tee-Object -FilePath $Log -Append | Out-Host
}

$OldTarget = [Environment]::GetEnvironmentVariable('CARGO_TARGET_DIR','Process')
$OldWarp = [Environment]::GetEnvironmentVariable('VICTORY_WARP','Process')
$OldD3DWarp = [Environment]::GetEnvironmentVariable('VICTORY_D3D12_WARP','Process')
try {
    $env:VICTORY_WARP = $null
    $env:VICTORY_D3D12_WARP = $null
    foreach ($Item in $Targets) {
        $Number = $Item.Number
        $Path = Join-Path $TestRoot $Item.Name
        $SHA = $Item.SHA
        Note "=== PR #$Number exactly pinned at $SHA ==="
        & git -C $Repository fetch --quiet --no-tags $Remote "refs/pull/$Number/head"
        if ($LASTEXITCODE -ne 0) { throw "Failed fetching upstream PR #$Number" }
        $Actual = (& git -C $Repository rev-parse FETCH_HEAD).Trim()
        if ($LASTEXITCODE -ne 0 -or $Actual -ne $SHA) {
            throw "Upstream PR #$Number head changed: $Actual; expected $SHA. No test run."
        }
        if (Test-Path -LiteralPath $Path) {
            $Here = (& git -C $Path rev-parse HEAD).Trim()
            $Changes = @(& git -C $Path status --porcelain)
            if ($LASTEXITCODE -ne 0 -or $Here -ne $SHA -or $Changes.Count -ne 0) {
                throw "Existing $Path isn't exactly clean at $SHA. Stop."
            }
            Note "Using existing clean detached worktree: $Path"
        }
        else {
            & git -C $Repository worktree add --quiet --detach $Path $SHA
            if ($LASTEXITCODE -ne 0) { throw "Could not create isolated PR #$Number worktree" }
            Note "Created detached worktree: $Path"
        }
        $env:CARGO_TARGET_DIR = Join-Path $WorkRoot ('test-' + $Item.Name)
        Note "CARGO_TARGET_DIR=$env:CARGO_TARGET_DIR"
        Push-Location $Path
        try {
            foreach ($Step in $Item.Steps) {
                Note "=== COMMAND: $Step ==="
                # cmd.exe is for Cargo's stderr redirection ONLY; never wraps game paths.
                & $env:ComSpec /D /C ($Step + ' 2>&1') |
                    ForEach-Object { $_.ToString() } |
                    Tee-Object -FilePath $Log -Append | Out-Host
                $Exit = $LASTEXITCODE
                Note "EXIT CODE: $Exit"
                if ($Exit -ne 0) {
                    throw "PR #$Number test failed. Stop before combining source; upload private log."
                }
            }
        }
        finally { Pop-Location }
    }
    Note 'ALL INDEPENDENT TARGETED TEST COMMANDS EXITED ZERO.'
    $DeviceEvidence = @(Select-String -LiteralPath $Log -Pattern '(?i)RTX|NVIDIA|split true|hardware adapter; skipped|no DXGI; skipped')
    if (-not ($DeviceEvidence | Where-Object { $_.Line -match '(?i)RTX|NVIDIA|split true' })) {
        Note 'WARNING: no physical GPU adapter demonstrated in test output. Do not claim GPU_PASS.'
    } else {
        Note 'GPU-relevant test output found. Review exact adapter/skip lines before claiming GPU_PASS.'
    }
}
finally {
    [Environment]::SetEnvironmentVariable('CARGO_TARGET_DIR',$OldTarget,'Process')
    [Environment]::SetEnvironmentVariable('VICTORY_WARP',$OldWarp,'Process')
    [Environment]::SetEnvironmentVariable('VICTORY_D3D12_WARP',$OldD3DWarp,'Process')
    Note "PRIVATE report: $Log"
    Note "End: $(Get-Date -Format o)"
}
