#Requires -Version 5.1
# E-062: two public-source VIctory builds, same LOCAL title path, owner-controlled visual A/B.
# Never starts a title without explicit LAUNCH typed separately for each build.
# Never copies executable, assets, shader cache, title captures or save data into GitHub.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$GameExe,
    [string]$ReportRoot = 'C:\VIctory-Tests',
    [string]$BaselineExe = '',
    [string]$CandidateExe = '',
    [switch]$EnableDebugLayer,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$ExpectedBase = '616e3bc91252fd30f5f3b52dc81e0d8b0d6d93e384af3ce1e8b74c65fab3d554'
$ExpectedE056 = '5e378b0e3673059cbbffcee54f0d83cedbde00ff0f40522136022e2dc469c723'
if (-not $BaselineExe) {
    $BaselineExe = Join-Path $ReportRoot 'E052-six-PR-RTX5090-20261126-202133-binary\victory-six-pr.exe'
}
if (-not $CandidateExe) {
    $CandidateExe = Join-Path $ReportRoot 'E060-six-PR-barrier-RTX5090-20261126-205441-binary\victory-six-pr-e056.exe'
}
$RunId = 'E062-RTX5090-visual-AB-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
$Folder = Join-Path $ReportRoot $RunId
$Zip = Join-Path $ReportRoot ($RunId + '.zip')
$Status = 'NOT_STARTED'
$Notes = New-Object 'System.Collections.Generic.List[string]'
$LastProcess = $null
$Vars = @('VICTORY_GAME_DIR','VICTORY_D3D12_WARP','VICTORY_D3D12_DEBUG',
    'VICTORY_D3D12_GBV','VICTORY_CAPTURE','VICTORY_CAPTURE_WORLD',
    'VICTORY_DUMP_TARGETS','VICTORY_CRASH_SAVE','VICTORY_XMA_DUMP')
$Before = @{}
foreach ($name in $Vars) {
    $Before[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
New-Item -ItemType Directory -Force -Path $Folder | Out-Null

try {
    if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf)) {
        throw 'Missing private title executable. Supply -GameExe; no title path is stored in GitHub.'
    }
    $GameExe = (Resolve-Path -LiteralPath $GameExe).ProviderPath
    $GameDir = Split-Path -Parent $GameExe
    if (-not (Get-Command 'nvidia-smi.exe' -ErrorAction SilentlyContinue)) {
        throw 'nvidia-smi.exe required to verify physical RTX5090.'
    }
    $Gpu = (& nvidia-smi.exe --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $Gpu -notmatch 'RTX 5090') {
        throw 'RTX 5090 not identified. Refusing A/B to prevent wrong-adapter conclusions.'
    }

    foreach ($item in @(
        @{ Name='baseline'; Path=$BaselineExe; Expected=$ExpectedBase },
        @{ Name='e056-barrier'; Path=$CandidateExe; Expected=$ExpectedE056 }
    )) {
        if (-not (Test-Path -LiteralPath $item.Path -PathType Leaf)) {
            throw ('Missing ' + $item.Name + ' release executable. Use -BaselineExe or -CandidateExe to specify it.')
        }
        $ActualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.Path).Hash.ToLowerInvariant()
        if ($ActualHash -ne $item.Expected) {
            throw ('Executable SHA256 mismatch for ' + $item.Name + '. Refusing A/B of unknown binary.')
        }
    }
    $Runs = @(
        [pscustomobject]@{ Name='baseline'; Path=$BaselineExe; Hash=$ExpectedBase },
        [pscustomobject]@{ Name='e056-barrier'; Path=$CandidateExe; Hash=$ExpectedE056 }
    )
    @(
        'E-062 — matched private title visual A/B, actual title launch ONLY after LAUNCH confirmation',
        'Started: ' + (Get-Date -Format o),
        'Physical GPU: ' + $Gpu,
        'Baseline E-052 SHA256: ' + $ExpectedBase,
        'Candidate E-060 SHA256: ' + $ExpectedE056,
        'Console: series-x; run --execute; same private title executable',
        'D3D12 debug layer: ' + [string]$EnableDebugLayer.IsPresent,
        'WARP and GPU-based validation: forced off for both runs',
        'Title path and hash deliberately omitted from report.',
        'No title binary, cache, screenshot, save or game-generated file copied into ZIP.',
        'No game launched by this script until owner explicitly types LAUNCH.'
    ) | Set-Content -LiteralPath (Join-Path $Folder 'manifest.txt') -Encoding UTF8

    Write-Host 'E-062 preflight PASS: two source-generated binary hashes and physical RTX 5090 verified.'
    Write-Host 'This test can hang or reset your graphics driver. Close other GPU-heavy apps.'
    Write-Host 'The title may change its own local save/cache files; back them up separately if important.'
    Write-Host 'The same title exe and existing local settings/caches will be used for both runs.'
    if ($CheckOnly) {
        $Status = 'PREFLIGHT_ONLY_NO_GAME_RUN'
    }
    else {
        $env:VICTORY_GAME_DIR = $GameDir
        $env:VICTORY_D3D12_WARP = $null
        $env:VICTORY_D3D12_GBV = $null
        $env:VICTORY_D3D12_DEBUG = if ($EnableDebugLayer) { '1' } else { $null }
        # Prevent inherited capture/dump settings from writing title-derived material.
        $env:VICTORY_CAPTURE = $null
        $env:VICTORY_CAPTURE_WORLD = $null
        $env:VICTORY_DUMP_TARGETS = $null
        $env:VICTORY_CRASH_SAVE = $null
        $env:VICTORY_XMA_DUMP = $null

        foreach ($run in $Runs) {
            Write-Host ''
            Write-Host ('NEXT: ' + $run.Name)
            Write-Host 'Choose the same initial scene and visual settings each time; do not continue playing.'
            Write-Host 'When finished, close/exit the running title normally. If hung, use Task Manager.'
            $reply = Read-Host ('Type LAUNCH to run ' + $run.Name + ', or anything else to stop')
            if ($reply -cne 'LAUNCH') {
                $Status = 'OWNER_DECLINED_' + $run.Name
                throw 'Owner did not opt in; no further title launched.'
            }
            $out = Join-Path $Folder ($run.Name + '-stdout.txt')
            $err = Join-Path $Folder ($run.Name + '-stderr.txt')
            # CLI source: without --execute, run stops after preparation/binding.
            $ArgLine = ('run "{0}" --execute --console series-x' -f $GameExe)
            $Notes.Add('START ' + $run.Name + ': ' + (Get-Date -Format o))
            $LastProcess = Start-Process -FilePath $run.Path -ArgumentList $ArgLine -WorkingDirectory $GameDir -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
            Write-Host ('Launched ' + $run.Name + '. Inspect the displayed scene and exit the title manually.')
            do {
                $null = Read-Host 'After the title has completely exited or you closed it in Task Manager, press ENTER'
                $LastProcess.Refresh()
                if (-not $LastProcess.HasExited) {
                    Write-Warning 'The title is still running; no next build will start until it exits. Exit or stop it manually.'
                }
            } while (-not $LastProcess.HasExited)
            $Notes.Add('EXIT ' + $run.Name + ': ' + [string]$LastProcess.ExitCode)
            $LastProcess = $null
            $view = Read-Host ('Describe ' + $run.Name + ' rendering (title card, menu, black/grey, visible world, textures, light, etc.)')
            $Notes.Add('OBSERVED ' + $run.Name + ': ' + $view)
        }
        $Status = 'BOTH_RUNS_OWNER_OBSERVED_UNVERIFIED_VISUAL'
    }
}
catch {
    if ($Status -eq 'NOT_STARTED') { $Status = 'WRAPPER_ERROR_OR_PRECHECK_FAILED' }
    ($_ | Out-String) | Set-Content -LiteralPath (Join-Path $Folder 'wrapper-error.txt') -Encoding UTF8
    Write-Warning ('E-062 stopped: ' + $_.Exception.Message)
    throw
}
finally {
    foreach ($name in $Vars) {
        [Environment]::SetEnvironmentVariable($name, $Before[$name], 'Process')
    }
    $Notes | Set-Content -LiteralPath (Join-Path $Folder 'owner-observations.txt') -Encoding UTF8
    @(
        'Status: ' + $Status,
        'Completed: ' + (Get-Date -Format o),
        'Title/game visual outcome is ONLY as described by the owner; not automatically verified.',
        'D3D12 debug layer may report errors but does not itself prove fixed visuals.',
        'This private ZIP may contain local title runtime logs. Do not upload to public GitHub.'
    ) | Set-Content -LiteralPath (Join-Path $Folder 'RESULT.txt') -Encoding UTF8
    if ($LastProcess -and -not $LastProcess.HasExited) {
        Write-Warning 'The title process might still be running; close it manually. This script will NOT kill it.'
    }
    try {
        Compress-Archive -Path (Join-Path $Folder '*') -DestinationPath $Zip -Force -ErrorAction Stop
        Write-Host ('UPLOAD THIS ZIP PRIVATELY IN CHATGPT (NEVER GITHUB): ' + $Zip)
        Write-Host ('E-062 status: ' + $Status)
    }
    catch {
        Write-Warning ('ZIP creation failed, individual local files remain. ' + $_.Exception.Message)
    }
}
