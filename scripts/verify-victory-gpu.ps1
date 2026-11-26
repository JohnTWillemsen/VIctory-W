# VIctory-W - owner-run baseline report (source/synthetic checks only).
# Does not run games, read game material, fetch branches, or change system settings.
[CmdletBinding()]
param(
    [ValidateSet('Inventory', 'Synthetic')]
    [string]$Mode = 'Inventory',
    [string]$Repo = 'C:\VIctory-W',
    [string]$OutputDir = 'C:\vtw\verification'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath (Join-Path $Repo 'Cargo.toml') -PathType Leaf)) {
    throw "Expected a VIctory workspace at $Repo; no changes made."
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
if (-not $env:CARGO_TARGET_DIR) { $env:CARGO_TARGET_DIR = 'C:\vtw' }
$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$logFile = Join-Path $OutputDir "victory-$($Mode.ToLowerInvariant())-$stamp.txt"
$rows = New-Object 'System.Collections.Generic.List[string]'
$failed = New-Object 'System.Collections.Generic.List[string]'

function Note([string]$Text) {
    Write-Host $Text
    [void]$script:rows.Add($Text)
}
function Probe([string]$Label, [scriptblock]$Command) {
    Note "`n== $Label =="
    try {
        $global:LASTEXITCODE = 0
        $results = & $Command 2>&1
        foreach ($result in @($results)) {
            if ($null -ne $result) { Note ([string]$result) }
        }
        $code = [int]$global:LASTEXITCODE
        if ($code -ne 0) { [void]$script:failed.Add("$Label (exit $code)") }
        Note "RESULT: $Label => exit $code"
    }
    catch {
        $message = $_.Exception.Message
        [void]$script:failed.Add("$Label (error)")
        Note "RESULT: $Label => ERROR: $message"
    }
}

try {
    Note 'VIctory-W owner verification; no title or proprietary files accessed.'
    Note "Report UTC: $stamp"
    Note "Mode: $Mode"
    Note "Cargo target folder: $env:CARGO_TARGET_DIR"
    Note 'Do not paste game logs, filesystem listings or captures into GitHub.'

    Probe 'Windows version' {
        Get-CimInstance -ClassName Win32_OperatingSystem |
            Select-Object Caption, Version, BuildNumber, OSArchitecture |
            Format-List | Out-String
    }
    Probe 'GPU and driver' {
        & nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
    }
    Probe 'Git version' { & git --version }
    Probe 'Rust version' { & rustc --version }
    Probe 'Cargo version' { & cargo --version }
    Probe 'Rust active toolchain' { & rustup show active-toolchain }
    Probe 'Repository HEAD' { & git -C $Repo rev-parse HEAD }
    Probe 'Repository branch' { & git -C $Repo branch --show-current }
    Probe 'Tracked working-tree changes (count only)' {
        $changed = @(& git -C $Repo diff --name-only)
        $staged = @(& git -C $Repo diff --cached --name-only)
        "Unstaged tracked: $($changed.Count); staged tracked: $($staged.Count)"
    }
    Probe 'MSVC linker available on this PowerShell PATH' {
        $linker = Get-Command link.exe -ErrorAction SilentlyContinue
        if ($null -eq $linker) { 'Not on PATH (VS Developer PowerShell may be required).' }
        else { 'link.exe is available on PATH.' }
    }
    Probe 'Windows SDK DXIL validators (names only)' {
        $sdk = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
        if (-not (Test-Path -LiteralPath $sdk)) { 'Windows SDK bin directory not found.' }
        else {
            @(Get-ChildItem -LiteralPath $sdk -Directory -ErrorAction SilentlyContinue |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'x64\dxil.dll') } |
                Select-Object -ExpandProperty Name) -join ', '
        }
    }
    Probe 'Local release build (VIctory executable only)' {
        $exe = 'C:\vtw\release\victory.exe'
        if (Test-Path -LiteralPath $exe -PathType Leaf) {
            $binary = Get-Item -LiteralPath $exe
            "exists; bytes=$($binary.Length); modified_utc=$($binary.LastWriteTimeUtc.ToString('o'))"
            "SHA256=$((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash)"
        } else { 'No C:\vtw\release\victory.exe found.' }
    }

    if ($Mode -eq 'Synthetic') {
        Note "`nSynthetic mode runs source checks and unit tests; it does NOT run the game."
        # Cargo progress and rustfmt diffs often go to native stderr. PowerShell
        # 5.1 with ErrorActionPreference=Stop can throw an ErrorRecord on the
        # first stderr line, masking Cargo's real exit status and error. Run
        # through cmd so 2>&1 joins native streams before PowerShell receives
        # them. The explicit LASTEXITCODE is still preserved by Probe.
        Probe 'cargo fmt --all -- --check (summary only)' {
            Push-Location $Repo
            try {
                $output = @(& $env:ComSpec /D /C 'cargo fmt --all -- --check 2>&1')
                $exit = $LASTEXITCODE
                $diffs = @($output | Where-Object { $_ -match '^Diff in .+?:[0-9]+:' })
                $paths = @($diffs | ForEach-Object {
                    $_ -replace '^Diff in (.*?):[0-9]+:
    }
    Note "`nCompleted command groups: $($rows.Count) report lines."
    if ($failed.Count -eq 0) { Note 'Report outcome: no command failures observed. This is NOT gameplay/GPU proof.' }
    else {
        Note 'Command groups with failures or unavailable prerequisites:'
        foreach ($item in $failed) { Note "- $item" }
    }
}
finally {
    $rows | Out-File -LiteralPath $logFile -Encoding UTF8
    Write-Host "`nReport saved: $logFile"
    Write-Host 'Upload the saved report here. Do not publish raw game logs or captures.'
}
, '$1'
                } | Sort-Object -Unique)
                "rustfmt: $($diffs.Count) diff hunks across $($paths.Count) source files (nothing changed)"
                if ($paths.Count -gt 0) {
                    'First differing paths (up to 12):'
                    $paths | Select-Object -First 12
                }
                if ($diffs.Count -eq 0 -and $exit -ne 0) {
                    $output | Select-Object -First 30
                }
                $global:LASTEXITCODE = $exit
            }
            finally { Pop-Location }
        }
        Probe 'cargo test -p victory-gpu --lib --locked descriptor -- --test-threads=1 --nocapture' {
            Push-Location $Repo
            try {
                & $env:ComSpec /D /C 'cargo test -p victory-gpu --lib --locked descriptor -- --test-threads=1 --nocapture 2>&1'
            }
            finally { Pop-Location }
        }
        Probe 'cargo xtask policy' {
            Push-Location $Repo
            try { & $env:ComSpec /D /C 'cargo xtask policy 2>&1' }
            finally { Pop-Location }
        }
    }
    Note "`nCompleted command groups: $($rows.Count) report lines."
    if ($failed.Count -eq 0) { Note 'Report outcome: no command failures observed. This is NOT gameplay/GPU proof.' }
    else {
        Note 'Command groups with failures or unavailable prerequisites:'
        foreach ($item in $failed) { Note "- $item" }
    }
}
finally {
    $rows | Out-File -LiteralPath $logFile -Encoding UTF8
    Write-Host "`nReport saved: $logFile"
    Write-Host 'Upload the saved report here. Do not publish raw game logs or captures.'
}
