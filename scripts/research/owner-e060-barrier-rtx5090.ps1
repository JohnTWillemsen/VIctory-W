#Requires -Version 5.1
# E-060: six-PR + Belobug D3D12 barrier-only patch, RTX5090. No game launch.
[CmdletBinding()]
param([string]$ReportRoot = (Join-Path $env:USERPROFILE 'VIctory-Tests'))

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Pin = '0c5a2813eec908954f1ccc37da0fe136efed5def'
$RunId = 'E060-six-PR-barrier-RTX5090-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
$Folder = Join-Path $ReportRoot $RunId
$Scripts = Join-Path $Folder 'scripts\research'
$BinaryFolder = Join-Path $ReportRoot ($RunId + '-binary')
$Zip = Join-Path $ReportRoot ($RunId + '.zip')
$Meta = Join-Path $Folder 'metadata.txt'
$Stdout = Join-Path $Folder 'cargo-and-gpu-stdout.txt'
$Stderr = Join-Path $Folder 'cargo-and-gpu-stderr.txt'
$Status = 'NOT_STARTED'
$Code = 99
$Vars = @('E045_WINDOWS_BUILD','E045_OWNER_GPU','E045_OWNER_BINARY_DIR','E056_PATCH','VICTORY_D3D12_WARP','CARGO_TARGET_DIR')
$Before = @{}
foreach ($name in $Vars) { $Before[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
New-Item -ItemType Directory -Force -Path $Scripts | Out-Null

try {
    $Bash = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
    if (-not (Test-Path -LiteralPath $Bash)) {
        $Pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
        if ($Pf86) { $Bash = Join-Path $Pf86 'Git\bin\bash.exe' }
    }
    if (-not (Test-Path -LiteralPath $Bash)) { throw 'Git for Windows Bash required.' }
    foreach ($tool in @('git','cargo','rustc','nvidia-smi.exe')) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "Missing local command: $tool" }
    }
    $Gpu = (& nvidia-smi.exe --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $Gpu -notmatch 'RTX 5090') { throw 'RTX 5090 not confirmed; not running a different adapter as baseline.' }
    @(
        'E-060 six-PR plus E-056 Belobug barrier hardware validation',
        "Started: $(Get-Date -Format o)",
        "Pinned scripts: $Pin",
        "Windows: $([Environment]::OSVersion.VersionString)",
        "PowerShell: $($PSVersionTable.PSVersion)",
        "Git: $((& git --version 2>&1) -join ' ')",
        "Rust: $((& rustc --version 2>&1) -join ' ')",
        "Cargo: $((& cargo --version 2>&1) -join ' ')",
        "GPU: $Gpu",
        'E056_PATCH=1 is mandatory; distinct release name victory-six-pr-e056.exe.',
        'No proprietary title files, game launch, shaders or caches are accessed.',
        'Candidate binary is stored separately from diagnostics ZIP.'
    ) | Set-Content -LiteralPath $Meta -Encoding UTF8

    foreach ($file in @(
        'e045-six-pr-source-and-ci.sh',
        'e045-reconcile-pr2628.py',
        'e049-guard-hostless-portable-probe.py',
        'e056-legal-barrier-port.sh'
    )) {
        $Url = "https://raw.githubusercontent.com/JohnTWillemsen/VIctory-W/$Pin/scripts/research/$file"
        $Dest = Join-Path $Scripts $file
        Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
        "$file SHA256: $((Get-FileHash -Algorithm SHA256 -LiteralPath $Dest).Hash)" | Add-Content -LiteralPath $Meta
    }
    $Runner = Join-Path $Scripts 'e045-six-pr-source-and-ci.sh'
    $UnixRunner = (& $Bash -c 'cygpath -u "$1"' 'e060' $Runner | Select-Object -First 1).Trim()
    $UnixBin = (& $Bash -c 'cygpath -u "$1"' 'e060' $BinaryFolder | Select-Object -First 1).Trim()
    if (-not $UnixRunner.StartsWith('/') -or -not $UnixBin.StartsWith('/')) {
        throw 'Git Bash path conversion failed.'
    }
    $env:E045_WINDOWS_BUILD = '1'
    $env:E045_OWNER_GPU = '1'
    $env:E056_PATCH = '1'
    $env:E045_OWNER_BINARY_DIR = $UnixBin
    $env:VICTORY_D3D12_WARP = $null
    $env:CARGO_TARGET_DIR = $null
    $Status = 'RUNNING'
    Write-Host 'E-060 pinned six-PR + E-056 barrier compile and synthetic RTX5090 testing started.'
    $Args = @{
        FilePath = $Bash
        ArgumentList = ('"' + $UnixRunner + '"')
        WorkingDirectory = $Folder
        PassThru = $true
        Wait = $true
        NoNewWindow = $true
        RedirectStandardOutput = $Stdout
        RedirectStandardError = $Stderr
    }
    $Proc = Start-Process @Args
    $Code = $Proc.ExitCode
    $Status = if ($Code -eq 0) { 'EXIT_ZERO_VERIFY_BACKEND_AND_SKIPS' } else { 'NONZERO_REVIEW_FAILURES' }
}
catch {
    $Status = 'WRAPPER_ERROR'
    $Code = 98
    ($_ | Out-String) | Set-Content -LiteralPath (Join-Path $Folder 'wrapper-error.txt') -Encoding UTF8
}
finally {
    foreach ($name in $Vars) { [Environment]::SetEnvironmentVariable($name, $Before[$name], 'Process') }
    @(
        "Status: $Status",
        "Runner exit: $Code",
        "Completed: $(Get-Date -Format o)",
        "Private binary directory (if built): $BinaryFolder",
        'E-056 enabled, compare to existing E-052 baseline; this runner never launches the game.',
        'Check test names, adapter, skips and failures. Correct title rendering is untested.',
        'Upload diagnostic ZIP privately in ChatGPT, NEVER GitHub.'
    ) | Set-Content -LiteralPath (Join-Path $Folder 'RESULT.txt') -Encoding UTF8
    try {
        Compress-Archive -Path (Join-Path $Folder '*') -DestinationPath $Zip -Force -ErrorAction Stop
        Write-Host ""
        Write-Host "UPLOAD THIS PRIVATE LOG ZIP: $Zip"
        Write-Host "Status: $Status | exit: $Code"
        Write-Host "Private candidate executable folder (not in ZIP): $BinaryFolder"
    }
    catch {
        Write-Warning "ZIP failed; individual reports remain in $Folder. $($_.Exception.Message)"
    }
}
