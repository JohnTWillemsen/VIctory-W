#Requires -Version 5.1
# E-068: pinned public-source combined diagnostics; title launch opt-in only.
# The ZIP contains counts only: never raw game logs or title-derived IDs.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$GameExe,
    [string]$ReportRoot = 'C:\VIctory-Tests',
    [switch]$BuildOnly
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Pin = '441b8a0e69ad5ac5d8eea9ab52581b689c94d867'
$RunId = 'E068-RTX5090-BVH-categories-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
$Folder = Join-Path $ReportRoot $RunId
$Scripts = Join-Path $Folder 'scripts\research'
$Private = Join-Path $Folder 'PRIVATE-raw-logs-do-not-upload'
$Public = Join-Path $Folder 'upload-only'
$BinaryFolder = Join-Path $ReportRoot ($RunId + '-binary')
$Binary = Join-Path $BinaryFolder 'victory-six-pr-e068.exe'
$Zip = Join-Path $ReportRoot ($RunId + '-summary.zip')
$Status = 'NOT_STARTED'
$BuildExit = 99
$TitleExit = 'NOT_RUN'
$Confirm = 'NOT_REQUESTED'
$Vars = @(
  'E045_WINDOWS_BUILD','E068_OWNER_BUILD','E068_BINARY_DIR','E066_BVH_DIAG',
  'E065_HEAP_WARN_DIAG','VICTORY_BVH_REFUSAL_COUNTS','VICTORY_GAME_DIR',
  'VICTORY_D3D12_WARP','VICTORY_D3D12_DEBUG','VICTORY_D3D12_GBV',
  'VICTORY_CAPTURE','VICTORY_CAPTURE_WORLD','VICTORY_DUMP_TARGETS',
  'VICTORY_CRASH_SAVE','VICTORY_XMA_DUMP','VICTORY_PIPELINE_LOG',
  'VICTORY_SKIP_PIPELINES','VICTORY_SKIP_WAVE64','CARGO_TARGET_DIR'
)
$Before = @{}
foreach ($Name in $Vars) {
    $Before[$Name] = [Environment]::GetEnvironmentVariable($Name, 'Process')
}
New-Item -ItemType Directory -Force -Path $Scripts,$Private,$Public,$BinaryFolder | Out-Null

try {
    if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf)) {
        throw 'Game executable not found. Supply the existing local -GameExe.'
    }
    $GameExe = (Resolve-Path -LiteralPath $GameExe).ProviderPath
    $GameDir = Split-Path -Parent $GameExe
    if (-not (Test-Path -LiteralPath (Join-Path $GameDir 'appdata0.rpf') -PathType Leaf)) {
        throw 'Startup archive not found next to the executable. Correct -GameExe; no launch attempted.'
    }

    $Bash = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
    if (-not (Test-Path -LiteralPath $Bash)) {
        $Pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
        if ($Pf86) { $Bash = Join-Path $Pf86 'Git\bin\bash.exe' }
    }
    if (-not (Test-Path -LiteralPath $Bash)) { throw 'Git for Windows Bash required.' }
    foreach ($Tool in @('git','cargo','rustc','nvidia-smi.exe')) {
        if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
            throw ('Required local tool not found: ' + $Tool)
        }
    }
    $Gpu = (& nvidia-smi.exe --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $Gpu -notmatch 'RTX 5090') {
        throw 'Physical RTX 5090 was not verified. No build or game launch.'
    }
    @(
        'E-068 six pinned upstream public PRs + E065 logging + E066 anonymous BVH category diagnostics',
        "Started: $(Get-Date -Format o)",
        "Pinned public scripts commit: $Pin",
        "GPU: $Gpu",
        'Both opt-in research patches required; no E056 barrier port.',
        'Never copy raw title stdout/stderr, game paths, shader identifiers or title files to this ZIP.',
        'Only anonymous numeric failure categories are summarized.',
        'No title execution without individually typed LAUNCH.'
    ) | Set-Content -LiteralPath (Join-Path $Public 'manifest.txt') -Encoding UTF8

    foreach ($File in @(
        'e045-six-pr-source-and-ci.sh',
        'e045-reconcile-pr2628.py',
        'e049-guard-hostless-portable-probe.py',
        'e065-bucket-heap-warning.sh',
        'e066-bvh-refusal-categories.sh'
    )) {
        $Uri = "https://raw.githubusercontent.com/JohnTWillemsen/VIctory-W/$Pin/scripts/research/$File"
        $Dest = Join-Path $Scripts $File
        Invoke-WebRequest -Uri $Uri -OutFile $Dest -UseBasicParsing
        if (-not (Test-Path -LiteralPath $Dest -PathType Leaf)) {
            throw ('Missing pinned public script: ' + $File)
        }
        "$File SHA256: $((Get-FileHash -LiteralPath $Dest -Algorithm SHA256).Hash)" |
            Add-Content -LiteralPath (Join-Path $Public 'public-script-hashes.txt')
    }
    $Runner = Join-Path $Scripts 'e045-six-pr-source-and-ci.sh'
    $UnixRunner = (& $Bash -c 'cygpath -u "$1"' 'e068' $Runner | Select-Object -First 1).Trim()
    $UnixBin = (& $Bash -c 'cygpath -u "$1"' 'e068' $BinaryFolder | Select-Object -First 1).Trim()
    if (-not $UnixRunner.StartsWith('/') -or -not $UnixBin.StartsWith('/')) {
        throw 'Git Bash path conversion failed; no build or title execution.'
    }

    $env:E068_OWNER_BUILD = '1'
    $env:E068_BINARY_DIR = $UnixBin
    $env:E066_BVH_DIAG = '1'
    $env:E065_HEAP_WARN_DIAG = '1'
    $env:E045_WINDOWS_BUILD = $null
    $env:VICTORY_D3D12_WARP = $null
    $env:CARGO_TARGET_DIR = $null
    $Status = 'BUILDING'
    Write-Host 'E-068 compiling source-only diagnostic candidate; game is NOT running.'
    $BuildProc = Start-Process -FilePath $Bash -ArgumentList ('"' + $UnixRunner + '"') -WorkingDirectory $Folder -PassThru -Wait -NoNewWindow -RedirectStandardOutput (Join-Path $Private 'build-stdout.txt') -RedirectStandardError (Join-Path $Private 'build-stderr.txt')
    $BuildExit = $BuildProc.ExitCode
    if ($BuildExit -ne 0) {
        throw ('Pinned source build failed (exit ' + $BuildExit + '). Raw build logs remain local.')
    }
    if (-not (Test-Path -LiteralPath $Binary -PathType Leaf)) {
        throw 'Expected isolated E068 executable missing after successful build.'
    }
    $Digest = (Get-FileHash -LiteralPath $Binary -Algorithm SHA256).Hash.ToLowerInvariant()
    @("E068 executable SHA256: $Digest", 'No game/title binaries are in the ZIP.') |
        Set-Content -LiteralPath (Join-Path $Public 'candidate-hash.txt') -Encoding UTF8
    Write-Host ('E-068 source-only build PASS. Candidate SHA256: ' + $Digest)
    $Status = 'BUILD_PASS_TITLE_NOT_RUN'

    if (-not $BuildOnly) {
        Write-Host 'The title may hang/reset your graphics driver or change local saves/cache.'
        Write-Host 'Close other GPU-heavy applications and back up anything important first.'
        Write-Host 'Only a brief launch is needed; inspect the intro then exit normally.'
        $Confirm = Read-Host 'Type LAUNCH to begin one BVH diagnostic title run; any other text skips it'
        if ($Confirm -cne 'LAUNCH') {
            $Status = 'BUILD_PASS_OWNER_DECLINED_LAUNCH'
            Write-Host 'Title was not launched; compiled candidate was preserved.'
        }
        else {
            $env:VICTORY_GAME_DIR = $GameDir
            $env:VICTORY_BVH_REFUSAL_COUNTS = '1'
            $env:VICTORY_D3D12_DEBUG = $null
            $env:VICTORY_D3D12_GBV = $null
            foreach ($Name in @(
                'VICTORY_CAPTURE','VICTORY_CAPTURE_WORLD','VICTORY_DUMP_TARGETS',
                'VICTORY_CRASH_SAVE','VICTORY_XMA_DUMP','VICTORY_PIPELINE_LOG',
                'VICTORY_SKIP_PIPELINES','VICTORY_SKIP_WAVE64'
            )) { [Environment]::SetEnvironmentVariable($Name, $null, 'Process') }

            $TitleStdout = Join-Path $Private 'title-stdout-private.txt'
            $TitleStderr = Join-Path $Private 'title-stderr-private.txt'
            $TitleArguments = ('run "{0}" --execute --console series-x' -f $GameExe)
            Write-Host 'Starting one owner-approved local title run. Exit the title manually.'
            $TitleProc = Start-Process -FilePath $Binary -ArgumentList $TitleArguments -WorkingDirectory $GameDir -PassThru -RedirectStandardOutput $TitleStdout -RedirectStandardError $TitleStderr
            $Status = 'TITLE_RUNNING'
            do {
                $null = Read-Host 'When the title has EXITED (or you closed it in Task Manager), press ENTER'
                $TitleProc.Refresh()
                if (-not $TitleProc.HasExited) {
                    Write-Warning 'Title still running; close it first. This script never kills it.'
                }
            } while (-not $TitleProc.HasExited)
            $TitleExit = [string]$TitleProc.ExitCode
            $OwnerObservation = Read-Host 'Briefly describe the visible screen (gray, intro, world, crash, etc.)'
            ('Owner visual observation (unverified): ' + $OwnerObservation) |
                Set-Content -LiteralPath (Join-Path $Public 'owner-observation.txt') -Encoding UTF8

            # Raw title logs stay LOCAL. Extract only pre-defined integer categories
            # from the opt-in anonymous telemetry line. Do not copy matched lines.
            $Rows = New-Object 'System.Collections.Generic.List[string]'
            $Found = @(Select-String -LiteralPath $TitleStderr -Pattern 'BVH builder unavailable pipeline categories \(anonymous\)')
            foreach ($Hit in $Found) {
                $Line = $Hit.Line
                $Counts = @{}
                foreach ($Field in @('shader_translation','host_pipeline','pending')) {
                    $m = [regex]::Match($Line, '(?:^|\s)' + $Field + '=(\d+)')
                    if ($m.Success) { $Counts[$Field] = $m.Groups[1].Value }
                }
                if ($Counts.Count -eq 3) {
                    $Rows.Add('shader_translation=' + $Counts['shader_translation'] +
                        ' host_pipeline=' + $Counts['host_pipeline'] +
                        ' pending=' + $Counts['pending'])
                }
            }
            if ($Rows.Count -gt 0) {
                $Rows | Select-Object -Unique |
                    Set-Content -LiteralPath (Join-Path $Public 'anonymous-bvh-categories.txt') -Encoding UTF8
                $Status = 'TITLE_EXITED_ANONYMOUS_BVH_COUNTS_FOUND'
            }
            else {
                'No parseable anonymous BVH count observed. This does not mean no refusal occurred.' |
                    Set-Content -LiteralPath (Join-Path $Public 'anonymous-bvh-categories.txt') -Encoding UTF8
                $Status = 'TITLE_EXITED_NO_ANONYMOUS_BVH_COUNTS'
            }
            Write-Host 'The private title logs remain in the local PRIVATE folder, not in the ZIP.'
        }
    }
}
catch {
    if ($Status -eq 'BUILDING' -or $Status -eq 'NOT_STARTED') {
        $Status = 'BUILD_OR_PREFLIGHT_FAILED'
    }
    else {
        $Status = 'RUN_OR_CAPTURE_FAILED'
    }
    # Exception text can include private paths. Keep raw details LOCAL only.
    ($_ | Out-String) | Set-Content -LiteralPath (Join-Path $Private 'local-exception.txt') -Encoding UTF8
    Write-Warning ('E-068 stopped; check private local logs. Status: ' + $Status)
}
finally {
    foreach ($Name in $Vars) {
        [Environment]::SetEnvironmentVariable($Name, $Before[$Name], 'Process')
    }
    @(
        'E-068 result: ' + $Status,
        'Pinned runner source: ' + $Pin,
        'Build exit: ' + $BuildExit,
        'Title exit: ' + $TitleExit,
        'Completed: ' + (Get-Date -Format o),
        'Owner confirmation to launch was required; no automatic launch.',
        'Logs in local PRIVATE folder were excluded from this ZIP.',
        'Synthetic source tests were separately run in GitHub CI; no FPS claims.',
        'Share this summary ZIP in private ChatGPT only, NOT public GitHub.'
    ) | Set-Content -LiteralPath (Join-Path $Public 'RESULT.txt') -Encoding UTF8
    try {
        Compress-Archive -LiteralPath (Join-Path $Public '*') -DestinationPath $Zip -Force -ErrorAction Stop
        Write-Host ('UPLOAD ONLY THIS SUMMARY ZIP IN CHATGPT: ' + $Zip)
        Write-Host ('Result: ' + $Status)
        Write-Host ('Isolated source-built executable (local only): ' + $Binary)
    }
    catch {
        Write-Warning 'Could not create summary ZIP; keep all local files private.'
    }
}
