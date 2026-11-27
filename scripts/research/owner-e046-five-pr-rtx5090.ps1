# E-046: private RTX5090 evidence runner for public-source five-PR stack.
# Never reads or modifies a game title. Always makes a ZIP of diagnostics.
[CmdletBinding()]
param([string]$ReportRoot = "$env:USERPROFILE\VIctory-Tests")

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$RunId = "E046-five-PR-RTX5090-$Stamp"
$RunFolder = Join-Path $ReportRoot $RunId
$ZipPath = Join-Path $ReportRoot "$RunId.zip"
$Meta = Join-Path $RunFolder 'metadata.txt'
$Stdout = Join-Path $RunFolder 'cargo-and-gpu-stdout.txt'
$Stderr = Join-Path $RunFolder 'cargo-and-gpu-stderr.txt'
$Summary = Join-Path $RunFolder 'RESULT.txt'
$SourceSha = 'c80e9eb221c39660126dbd5c6d6b41704d62b221'
$RunnerFile = Join-Path $RunFolder 'pinned-public-source-gate.sh'
$RunnerUrl = "https://raw.githubusercontent.com/JohnTWillemsen/VIctory-W/$SourceSha/scripts/research/ci-pr439-bvh2118-pr2098-pr2626-pr2464-source.sh"
$ExitCode = 99
$Status = 'NOT_STARTED'
$OldCompile = $env:E041_WINDOWS_COMPILE
$OldOwner = $env:E041_OWNER_GPU

New-Item -ItemType Directory -Path $RunFolder -Force | Out-Null
try {
    @(
        "E-046 five-PR public-source RTX5090 validation",
        "Started: $(Get-Date -Format o)",
        "Pinned script commit: $SourceSha",
        "Sources: #439 e2d3cfd; #2118 999a8f6; #2098 543d868; #2626 c8cc83e; #2464 b9dc4b0",
        "No proprietary game files are accessed.",
        "Computer: $env:COMPUTERNAME",
        "Windows: $([Environment]::OSVersion.VersionString)",
        "PowerShell: $($PSVersionTable.PSVersion)",
        "Git: $((& git --version 2>&1) -join ' ')",
        "Rust: $((& rustc --version 2>&1) -join ' ')",
        "Cargo: $((& cargo --version 2>&1) -join ' ')"
    ) | Set-Content -Path $Meta -Encoding UTF8
    $ProgramFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    $GitBash = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
    if (-not (Test-Path $GitBash) -and $ProgramFilesX86) {
        $GitBash = Join-Path $ProgramFilesX86 'Git\bin\bash.exe'
    }
    if (-not (Test-Path $GitBash)) { throw 'Git for Windows Bash is required under Program Files.' }
    if (-not (Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue)) {
        throw 'nvidia-smi.exe is missing; physical NVIDIA adapter cannot be confirmed.'
    }
    $DriveName = ([IO.Path]::GetPathRoot($ReportRoot)).Substring(0, 1)
    $Disk = Get-PSDrive -Name $DriveName -ErrorAction Stop
    "Free disk space bytes: $($Disk.Free)" | Add-Content -Path $Meta
    Invoke-WebRequest -Uri $RunnerUrl -OutFile $RunnerFile -UseBasicParsing
    $Digest = (Get-FileHash -Algorithm SHA256 -Path $RunnerFile).Hash
    "Runner SHA256: $Digest" | Add-Content -Path $Meta
    $UnixRunner = (& $GitBash -c 'cygpath -u "$1"' 'e046' $RunnerFile | Select-Object -First 1).Trim()
    if (-not $UnixRunner.StartsWith('/')) { throw 'Cannot resolve Git Bash path to script.' }
    "Git Bash: $GitBash" | Add-Content -Path $Meta
    "Report directory: $RunFolder" | Add-Content -Path $Meta
    "Pinned public script URL: $RunnerUrl" | Add-Content -Path $Meta

    $env:E041_WINDOWS_COMPILE = '1'
    $env:E041_OWNER_GPU = '1'
    $Status = 'RUNNING'
    Write-Host 'E-046 owner GPU test started; the final ZIP is created even on failures.'
    $StartArgs = @{
        FilePath = $GitBash
        ArgumentList = ('"' + $UnixRunner + '"')
        PassThru = $true
        Wait = $true
        NoNewWindow = $true
        RedirectStandardOutput = $Stdout
        RedirectStandardError = $Stderr
    }
    $Process = Start-Process @StartArgs
    $ExitCode = $Process.ExitCode
    $Status = if ($ExitCode -eq 0) { 'SCRIPT_EXIT_ZERO' } else { 'SCRIPT_NONZERO_CHECK_LOGS' }
}
catch {
    $Status = 'WRAPPER_ERROR'
    $ExitCode = 98
    $_ | Out-String | Set-Content -Path (Join-Path $RunFolder 'wrapper-error.txt') -Encoding UTF8
}
finally {
    $env:E041_WINDOWS_COMPILE = $OldCompile
    $env:E041_OWNER_GPU = $OldOwner
    @(
        "E046 status: $Status",
        "Script exit code: $ExitCode",
        "Ended: $(Get-Date -Format o)",
        "Check test names, hardware backend, failures, skips and script exit code.",
        "Known GPU descriptor-cap baseline failures may recur; do not call that full-suite PASS.",
        "No title execution, no six-PR build, no proprietary assets.",
        "Upload the ZIP privately here; do not publish raw logs to GitHub."
    ) | Set-Content -Path $Summary -Encoding UTF8
    try {
        Compress-Archive -Path (Join-Path $RunFolder '*') -DestinationPath $ZipPath -Force -ErrorAction Stop
        Write-Host ""
        Write-Host "UPLOAD THIS FILE: $ZipPath"
        Write-Host "Status: $Status | script exit: $ExitCode"
    }
    catch {
        Write-Warning "ZIP creation failed; individual logs remain in $RunFolder. $($_.Exception.Message)"
    }
}
