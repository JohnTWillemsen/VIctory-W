#Requires -Version 5.1
# E-078: reuse EXACT previously owner-built E075 binary. No compilation,
# source checkout, GPU stress-test suite or game/title data upload.
# Raw title stdout/stderr remain local PRIVATE; summary ZIP numeric only.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$GameExe,
    [Parameter(Mandatory=$true)][string]$BinaryExe,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedSha256,
    [string]$ReportRoot = 'C:\VIctory-Tests'
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$PrivateDirName = 'PRIVATE-raw-logs-do-not-upload'
$Id = 'E078-RTX5090-BVH-reason-reuse-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
$Root = Join-Path $ReportRoot $Id
$Private = Join-Path $Root $PrivateDirName
$Public = Join-Path $Root 'upload-only'
$Zip = Join-Path $ReportRoot ($Id + '-summary.zip')
$ExpectedParserSha256 = 'DF540AE71F3BD94C59000A0BBADF0648B4B98FB2781CA1D5D09D681C864D4773'
$PinnedParserCommit = 'e74ae73d42358617ed924fe0588e7919e0630a1e'
$Status = 'NOT_STARTED'
$TitleExit = 'NOT_RUN'
$PrivateError = $null
$Keys = @('VICTORY_GAME_DIR','VICTORY_BVH_REFUSAL_COUNTS',
    'VICTORY_BVH_TRANSLATION_REASONS','VICTORY_D3D12_WARP',
    'VICTORY_D3D12_DEBUG','VICTORY_D3D12_GBV',
    'VICTORY_CAPTURE','VICTORY_CAPTURE_WORLD','VICTORY_DUMP_TARGETS',
    'VICTORY_CRASH_SAVE','VICTORY_XMA_DUMP','VICTORY_PIPELINE_LOG',
    'VICTORY_SKIP_PIPELINES','VICTORY_SKIP_WAVE64')
$Before = @{}
foreach ($Key in $Keys) {
    $Before[$Key] = [Environment]::GetEnvironmentVariable($Key, 'Process')
}
try {
    New-Item -ItemType Directory -Force -Path $Private,$Public | Out-Null
    if (-not (Test-Path -LiteralPath $BinaryExe -PathType Leaf)) {
        throw 'The E075 release executable was not found; no title launched.'
    }
    $BinaryExe = (Resolve-Path -LiteralPath $BinaryExe).ProviderPath
    $ActualHash = (Get-FileHash -LiteralPath $BinaryExe -Algorithm SHA256).Hash
    if ($ActualHash -ine $ExpectedSha256) {
        throw 'E075 release SHA256 differs from the owner-provided build report. Refusing to launch.'
    }
    if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf)) {
        throw 'Game executable was not found; no title launched.'
    }
    $GameExe = (Resolve-Path -LiteralPath $GameExe).ProviderPath
    $GameDir = Split-Path -Parent $GameExe
    if (-not (Test-Path -LiteralPath (Join-Path $GameDir 'appdata0.rpf') -PathType Leaf)) {
        throw 'Expected existing startup archive beside the title executable is missing.'
    }
    if (-not (Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue)) {
        throw 'Cannot verify physical NVIDIA GPU. No title launched.'
    }
    $GPU = (& nvidia-smi.exe --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $GPU -notmatch 'RTX 5090') {
        throw 'Physical NVIDIA RTX 5090 was not verified. No title launched.'
    }

    # Reuse ONLY the exact public source parser from E075's existing report
    # folder; if absent, download only that pinned open-source parser.
    $BinaryFolder = Split-Path -Parent $BinaryExe
    $E075Folder = $BinaryFolder -replace '-binary$', ''
    $Parser = Join-Path $E075Folder 'scripts\research\e075-parse-bvh-reasons.ps1'
    if (-not (Test-Path -LiteralPath $Parser -PathType Leaf)) {
        $Parser = Join-Path $Private 'e075-parse-bvh-reasons.ps1'
        $Uri = 'https://raw.githubusercontent.com/JohnTWillemsen/VIctory-W/' +
            $PinnedParserCommit + '/scripts/research/e075-parse-bvh-reasons.ps1'
        Invoke-WebRequest -Uri $Uri -OutFile $Parser -UseBasicParsing
    }
    if ((Get-FileHash -LiteralPath $Parser -Algorithm SHA256).Hash -ine $ExpectedParserSha256) {
        throw 'E075 parser source fingerprint mismatch. Refusing to continue.'
    }
    $Tokens = $null
    $ParseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $Parser, [ref]$Tokens, [ref]$ParseErrors
    )
    if ($ParseErrors.Count -gt 0) {
        throw 'Pinned E075 parser did not pass PowerShell syntax validation.'
    }

    @(
        'E078: REUSE previously built E075 executable; no compilation or source checkout',
        ('Source-generated E075 binary SHA256=' + $ActualHash.ToLowerInvariant()),
        ('Pinned public E075 numeric parser SHA256=' + $ExpectedParserSha256.ToLowerInvariant()),
        ('GPU=' + $GPU),
        'The owner must type exactly LAUNCH. This script never starts the game automatically.',
        'The game may hang/reset the GPU and may write to existing caches/saves.',
        'Raw title stdout/stderr and private paths are never included in this ZIP.'
    ) | Set-Content -LiteralPath (Join-Path $Public 'manifest.txt') -Encoding UTF8

    $Status = 'PREFLIGHT_PASS_NOT_LAUNCHED'
    Write-Host 'E078 preflight PASS: existing E075 release hash and RTX5090 verified.'
    Write-Host 'NO rebuild is necessary. Close GPU-heavy apps; back up any important saves.'
    $Confirmation = Read-Host 'Type uppercase LAUNCH to run the existing E075 title diagnostic once'
    if ($Confirmation -cne 'LAUNCH') {
        $Status = 'PREFLIGHT_PASS_OWNER_DECLINED_LAUNCH'
        Write-Host 'Declined: no game/title was started.'
    }
    else {
        $env:VICTORY_GAME_DIR = $GameDir
        $env:VICTORY_BVH_REFUSAL_COUNTS = '1'
        $env:VICTORY_BVH_TRANSLATION_REASONS = '1'
        foreach ($Name in $Keys) {
            if ($Name -notin @('VICTORY_GAME_DIR','VICTORY_BVH_REFUSAL_COUNTS','VICTORY_BVH_TRANSLATION_REASONS')) {
                [Environment]::SetEnvironmentVariable($Name,$null,'Process')
            }
        }
        $Stdout = Join-Path $Private 'title-stdout-private.txt'
        $Stderr = Join-Path $Private 'title-stderr-private.txt'
        $Args = 'run "' + $GameExe + '" --execute --console series-x'
        $Status = 'TITLE_LAUNCHING'
        Write-Host 'Starting one existing E075 title run. Exit the title normally when ready.'
        $Process = Start-Process -FilePath $BinaryExe -ArgumentList $Args -WorkingDirectory $GameDir -PassThru -Wait -NoNewWindow -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
        $TitleExit = [string]$Process.ExitCode
        $Status = 'TITLE_EXITED_PARSING'
        $Observations = Read-Host 'Describe the visible world briefly (black, city, character, movement, etc.)'
        # Observations are owner-written and possibly identifying: retained
        # locally, not copied into the ZIP.
        $Observations | Set-Content -LiteralPath (Join-Path $Private 'private-observation.txt') -Encoding UTF8

        foreach ($Stream in @('stderr','stdout')) {
            $InputFile = if ($Stream -eq 'stderr') { $Stderr } else { $Stdout }
            $NumericFile = Join-Path $Public ('E075-anonymous-' + $Stream + '.txt')
            & $Parser -LogFile $InputFile -OutputFile $NumericFile
            if (-not (Test-Path -LiteralPath $NumericFile -PathType Leaf)) {
                throw 'Offline numeric parser did not create its sanitized result.'
            }
        }
        $Scan = Get-Content -LiteralPath (Join-Path $Public 'E075-anonymous-stderr.txt') -Raw
        $Scan2 = Get-Content -LiteralPath (Join-Path $Public 'E075-anonymous-stdout.txt') -Raw
        if (($Scan -match '(?m)^bvh_reason_complete=([1-9][0-9]*)') -or
            ($Scan2 -match '(?m)^bvh_reason_complete=([1-9][0-9]*)')) {
            $Status = 'TITLE_EXITED_REASON_HISTOGRAM_FOUND'
        }
        else {
            $Status = 'TITLE_EXITED_NO_REASON_HISTOGRAM'
        }
    }
}
catch {
    # Keep private exception details local; public result only fixed status.
    if (-not (Test-Path -LiteralPath $Private -PathType Container)) {
        New-Item -ItemType Directory -Path $Private -Force | Out-Null
    }
    ($_ | Out-String) | Set-Content -LiteralPath (Join-Path $Private 'private-error.txt') -Encoding UTF8
    $Status = 'PREFLIGHT_OR_TITLE_RUN_ERROR'
    Write-Warning ('E078 stopped: ' + $Status + '. Private error details remain local.')
}
finally {
    foreach ($Key in $Keys) {
        [Environment]::SetEnvironmentVariable($Key,$Before[$Key],'Process')
    }
    if (-not (Test-Path -LiteralPath $Public -PathType Container)) {
        New-Item -ItemType Directory -Path $Public -Force | Out-Null
    }
    @(
        'status=' + $Status,
        'title_exit=' + $TitleExit,
        'build_reused_existing_e075=true',
        'no_title_data_uploaded=true',
        'anonymous_histogram_missing_is_unknown_not_zero=true',
        'original_logs_local_private_only=true'
    ) | Set-Content -LiteralPath (Join-Path $Public 'RESULT.txt') -Encoding UTF8
    try {
        Compress-Archive -Path (Join-Path $Public '*') -DestinationPath $Zip -Force -ErrorAction Stop
        Write-Host ('UPLOAD ONLY THIS PRIVATE SUMMARY ZIP: ' + $Zip)
        Write-Host ('E078 status: ' + $Status)
        Write-Host 'Raw title logs and any local error details stay in PRIVATE folder, not ZIP.'
    }
    catch {
        Write-Warning 'Could not create numeric-only summary ZIP. Keep all local files private.'
    }
}
