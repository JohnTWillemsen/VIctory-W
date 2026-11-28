#Requires -Version 5.1
# VW092-H4: private opt-in cache reuse; no user title bytes or logs uploaded.
# Seed/Check/SelfTest never launch. Run delegates to existing E145/E127 PLAY.
[CmdletBinding()]
param(
    [ValidateSet('SelfTest','Inspect','Seed','Check','Run')][string]$Mode='Check',
    [string]$Repo='C:\VIctory-NVIDIA',
    [string]$ReportRoot='C:\VIctory-NVIDIA-Tests',
    [string]$GameRoot='C:\Grand Theft Auto',
    [string]$SourceRunId='',
    [string]$ExpectedHeadSha='',
    [string]$ExpectedExeSha='',
    [long]$GithubRun=0
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$ProvenanceName='PRIVATE-cache-provenance.json'
function AssertSha([string]$Head,[string]$Exe) {
    if ($Head -cnotmatch '^[0-9a-f]{40}$' -or $Exe -cnotmatch '^[0-9a-f]{64}$') {
        throw 'Expected exact source commit and executable SHA; no title launched'
    }
}
function Root([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw 'Private test root missing' }
    $item=Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Test root must not be a junction' }
    return $item.FullName.TrimEnd('\')
}
function NoLink([string]$Path) {
    $item=Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Cache reparse points refused'
    }
}
function DeviceProof {
    $cmd=Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { throw 'NVIDIA driver query unavailable; no title launched' }
    $lines=@(& $cmd.Source --query-gpu=name,driver_version --format=csv,noheader,nounits 2>$null)
    if ($LASTEXITCODE -ne 0) { throw 'NVIDIA driver query failed; no title launched' }
    $matching=@($lines | Where-Object { $_ -match 'RTX\s*5090' })
    if ($matching.Count -ne 1) { throw 'Exactly one RTX5090 identity required' }
    $parts=@($matching[0] -split ',')
    if ($parts.Count -ne 2 -or $parts[1].Trim() -notmatch '^[0-9.]+$') {
        throw 'NVIDIA driver version not understood'
    }
    return @{ gpu='RTX5090'; driver=$parts[1].Trim() }
}
function CacheFiles([string]$Folder) {
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) { throw 'Private source cache missing' }
    NoLink $Folder
    $base=(Get-Item -LiteralPath $Folder).FullName.TrimEnd('\')
    $stack=New-Object 'System.Collections.Generic.Stack[string]'
    $stack.Push($base)
    $files=New-Object 'System.Collections.Generic.List[object]'
    [long]$total=0
    while ($stack.Count -gt 0) {
        foreach ($item in @(Get-ChildItem -LiteralPath ($stack.Pop()) -Force -ErrorAction Stop)) {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Cache links refused' }
            if ($item.PSIsContainer) {
                if ($item.Name -in @('PRIVATE-never-upload','logs','saves')) { throw 'Not an isolated cache folder' }
                $stack.Push($item.FullName)
            } else {
                if ($item.Extension.ToLowerInvariant() -in @('.exe','.dll','.rpf','.pak','.zip','.7z','.log','.dmp','.sav','.mp4')) {
                    throw 'Unexpected title asset, executable, log or archive in cache'
                }
                if ($item.Length -gt 8589934592) { throw 'Cache file exceeds 8 GiB guard' }
                $total += [long]$item.Length
                if ($total -gt 25769803776 -or $files.Count -ge 100000) {
                    throw 'Cache exceeds 24 GiB or 100000 file guard'
                }
                $relative=$item.FullName.Substring($base.Length+1)
                $files.Add([pscustomobject]@{absolute=$item.FullName;relative=$relative})
            }
        }
    }
    if ($files.Count -eq 0) { throw 'Cache is empty' }
    return @($files | Sort-Object relative)
}
# Read-only extension histogram. Never return names, paths, cache contents,
# free-form extensions or hashes; every field is from a fixed allowlist.
function InspectCache([string]$Folder) {
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
        throw 'Prepared local cache folder is absent; nothing launched'
    }
    NoLink $Folder
    $blocked=@('.exe','.dll','.rpf','.pak','.zip','.7z','.log','.dmp','.sav','.mp4')
    $counts=@{}
    foreach ($ext in $blocked) { $counts[$ext]=0 }
    [int]$total=0
    $stack=New-Object 'System.Collections.Generic.Stack[string]'
    $stack.Push($Folder)
    while ($stack.Count -gt 0) {
        $dir=$stack.Pop()
        foreach ($item in @(Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop)) {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Prepared local cache contains a reparse point; no names exported'
            }
            if ($item.PSIsContainer) {
                $stack.Push($item.FullName)
            } else {
                $total++
                if ($total -gt 100000) { throw 'Cache file-count limit exceeded; no names exported' }
                $ext=$item.Extension.ToLowerInvariant()
                if ($counts.ContainsKey($ext)) { $counts[$ext]++ }
            }
        }
    }
    Write-Host 'format=VW092-private-cache-extension-audit-v1'
    Write-Host ('inspected_file_count='+$total)
    [int]$blockedTotal=0
    foreach ($ext in $blocked) {
        $n=[int]$counts[$ext]
        $blockedTotal += $n
        Write-Host (('blocked_'+$ext.TrimStart('.')+'_count')+'='+$n)
    }
    Write-Host ('blocked_total_count='+$blockedTotal)
    Write-Host ('nonblocked_count='+($total-$blockedTotal))
    Write-Host 'game_launched=false'
    Write-Host 'file_names_paths_and_contents_exported=false'
}
function PriorSession([string]$Root,[string]$RunId,[string]$Exe) {
    if ($RunId -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$') { throw 'Invalid E127 source ID' }
    $session=Join-Path $Root $RunId
    NoLink $session
    $private=Join-Path $session 'PRIVATE-never-upload'
    NoLink $private
    $cfg=Join-Path $private 'session.json'
    if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) { throw 'Missing source session provenance' }
    $j=Get-Content -LiteralPath $cfg -Raw | ConvertFrom-Json
    if ($j.run_id -cne $RunId -or $j.executable_sha256 -cne $Exe) {
        throw 'Source E127 executable provenance mismatch'
    }
    $finished=Join-Path $private 'finished.flag'
    $exit=Join-Path $private 'exit.txt'
    $observation=Join-Path $private 'observation.txt'
    if (-not (Test-Path -LiteralPath $finished -PathType Leaf) -or
        -not (Test-Path -LiteralPath $exit -PathType Leaf) -or
        -not (Test-Path -LiteralPath $observation -PathType Leaf)) {
        throw 'READY or incomplete E127 session cannot seed'
    }
    if ((Get-Content -LiteralPath $exit -Raw).Trim() -cne '0') {
        throw 'E127 source session did not exit successfully'
    }
    $answer=@(Get-Content -LiteralPath $observation)
    if ($answer.Count -ne 2 -or $answer[0] -cne 'World' -or $answer[1] -cne 'Yes') {
        throw 'World and controls not confirmed in source session'
    }
}
function CacheFolder([string]$Root,[string]$Head) {
    return (Join-Path $Root ('VW092-persistent-'+$Head.Substring(0,12)))
}
function SeedCache([string]$Root,[string]$RunId,[string]$Head,[string]$Exe,[hashtable]$Device) {
    AssertSha $Head $Exe
    PriorSession $Root $RunId $Exe
    # Accept only the previously prepared local cache folder, never a title path.
    $source=Join-Path $Root ('VW092-warm-cache-'+$Head.Substring(0,12))
    $items=@(CacheFiles $source)
    $dest=CacheFolder $Root $Head
    if (Test-Path -LiteralPath $dest) { throw 'Destination already exists; will not overwrite cache' }
    if ($Device.gpu -cne 'RTX5090' -or $Device.driver -notmatch '^[0-9.]+$') {
        throw 'Invalid GPU provenance for private cache'
    }
    $cache=Join-Path $dest 'cache'
    New-Item -ItemType Directory -Path $cache -Force | Out-Null
    foreach ($item in $items) {
        $to=Join-Path $cache $item.relative
        $parent=Split-Path -Parent $to
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        [IO.File]::Copy($item.absolute,$to,$false)
        if ((Get-FileHash -LiteralPath $item.absolute -Algorithm SHA256).Hash -cne
            (Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash) {
            throw 'Cache copy SHA256 mismatch; incomplete seed cannot run'
        }
    }
    $manifest=@{
        format='VW092-private-cache-v1';source_run_id=$RunId
        source_head_sha=$Head;executable_sha256=$Exe
        gpu=$Device.gpu;driver_version=$Device.driver
        source_driver_version_independently_verified=$false
        copied_file_count=$items.Count
        created_utc=[DateTime]::UtcNow.ToString('o')
        private_material_only=$true
    }
    [IO.File]::WriteAllText((Join-Path $dest $ProvenanceName),
        ($manifest | ConvertTo-Json -Compress),[Text.UTF8Encoding]::new($false))
    Write-Host ('VW092 persistent cache SHA256 copy verified: '+$items.Count+' local files. No title launched.')
    Write-Host 'Source-run driver was not independently logged; only current seed driver is pinned.'
}
function VerifyCache([string]$Root,[string]$Head,[string]$Exe,[hashtable]$Device) {
    AssertSha $Head $Exe
    $dest=CacheFolder $Root $Head
    if (-not (Test-Path -LiteralPath $dest -PathType Container)) {
        throw 'Persistent cache not seeded; previous Seed failed, no game launched'
    }
    NoLink $dest
    $private=Join-Path $dest $ProvenanceName
    NoLink $private
    $j=Get-Content -LiteralPath $private -Raw | ConvertFrom-Json
    if ($j.format -cne 'VW092-private-cache-v1' -or
        $j.source_head_sha -cne $Head -or $j.executable_sha256 -cne $Exe -or
        $j.gpu -cne $Device.gpu -or $j.driver_version -cne $Device.driver) {
        throw 'Cache source/executable/GPU driver changed, refusing reuse'
    }
    $cache=Join-Path $dest 'cache'
    $files=@(CacheFiles $cache)
    if ($files.Count -lt [int]$j.copied_file_count) {
        throw 'Persistent cache file count smaller than seed; possible corruption'
    }
    return $cache
}
if ($Mode -eq 'SelfTest') {
    $h=('a'*40);$e=('b'*64);$dev=@{gpu='RTX5090';driver='999.01'}
    $run='e127-20261128073423-f88740'
    $tmp=Join-Path $env:TEMP ('VW092-persistent-fixture-'+[guid]::NewGuid().ToString('N').Substring(0,8))
    try {
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        $src=Join-Path $tmp ('VW092-warm-cache-'+$h.Substring(0,12))
        New-Item -ItemType Directory -Path (Join-Path $src 'pipelines') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $src 'pipelines\synthetic.bin'),'Synthetic data only')
        # A seed must fail on forbidden types; the read-only histogram must
        # report a fixed category without exposing filename or raw bytes.
        $syntheticLog=Join-Path $src 'pipelines\PRIVATE-name.log'
        [IO.File]::WriteAllText($syntheticLog,'PRIVATE synthetic path, do not report')
        $inspection=(InspectCache $src | Out-String)
        if (-not $inspection.Contains('blocked_log_count=1') -or
            $inspection.Contains('PRIVATE-name') -or
            $inspection.Contains('PRIVATE synthetic')) {
            throw 'Fixed-field extension histogram leaked details or missed the forbidden .log'
        }
        Remove-Item -LiteralPath $syntheticLog -Force
        $private=Join-Path (Join-Path $tmp $run) 'PRIVATE-never-upload'
        New-Item -ItemType Directory -Path $private -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $private 'session.json'),
            (@{run_id=$run;executable_sha256=$e}|ConvertTo-Json -Compress))
        $rejected=$false
        try { SeedCache $tmp $run $h $e $dev } catch { $rejected=$true }
        if (-not $rejected) { throw 'READY-only seed was incorrectly accepted' }
        [IO.File]::WriteAllText((Join-Path $private 'finished.flag'),'finished')
        [IO.File]::WriteAllText((Join-Path $private 'exit.txt'),'0')
        [IO.File]::WriteAllLines((Join-Path $private 'observation.txt'),@('World','Yes'))
        $rejected=$false
        try { SeedCache $tmp $run $h ('c'*64) $dev } catch { $rejected=$true }
        if (-not $rejected) { throw 'Source executable SHA mismatch accepted' }
        SeedCache $tmp $run $h $e $dev
        [void](VerifyCache $tmp $h $e $dev)
        foreach ($wrong in @(@{gpu='RTX5090';driver='999.02'},@{gpu='OTHER';driver='999.01'})) {
            $rejected=$false
            try { [void](VerifyCache $tmp $h $e $wrong) } catch { $rejected=$true }
            if (-not $rejected) { throw 'Wrong GPU/driver accepted' }
        }
        $rejected=$false
        try { [void](VerifyCache $tmp $h ('d'*64) $dev) } catch { $rejected=$true }
        if (-not $rejected) { throw 'Wrong executable accepted' }
        $rejected=$false
        try { SeedCache $tmp $run $h $e $dev } catch { $rejected=$true }
        if (-not $rejected) { throw 'Existing persistent cache overwritten' }
        $blocked=Join-Path (Join-Path (CacheFolder $tmp $h) 'cache') 'private-title.rpf'
        [IO.File]::WriteAllText($blocked,'synthetic, forbidden title-like asset')
        $rejected=$false
        try { [void](VerifyCache $tmp $h $e $dev) } catch { $rejected=$true }
        if (-not $rejected) { throw 'Title-like material was accepted as cache' }
        Remove-Item -LiteralPath $blocked -Force
        Write-Host 'VW092 private cache: READY rejection, SHA copies, GPU/driver and non-overwrite SelfTest PASS; no title launched'
    }
    finally { if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force } }
    return
}
# H4 is intentionally bounded to the ONE verified owner H2/H3 executable.
# Future driver/build experiments must seed a distinct reviewed cache namespace.
$AcceptedHead='5bc4a9d089f66fe8485ea154feaf29c21e3e15b5'
$AcceptedExe='70e0bbe0ed7aa032a65495a99f26240310acdeeb1337927002b1a6460a801d60'
$AcceptedRun='e127-20261128073423-f88740'
$AcceptedGithubRun=46117808321
if ($ExpectedHeadSha -cne $AcceptedHead -or $ExpectedExeSha -cne $AcceptedExe) {
    throw 'This cache flow is pinned to the previously verified H2/H3 NVIDIA executable'
}
if ($Mode -eq 'Seed' -and $SourceRunId -cne $AcceptedRun) {
    throw 'Only the owner-verified H3 source session may seed this bounded cache'
}
if ($Mode -eq 'Run' -and $GithubRun -ne $AcceptedGithubRun) {
    throw 'Wrong GitHub source-built release run for the known H2/H3 executable'
}
AssertSha $ExpectedHeadSha $ExpectedExeSha
$root=Root $ReportRoot
if ($Mode -eq 'Inspect') {
    # Intentional pre-launch check: no NVIDIA driver call, no artifact
    # download, no manifest write, no game or cache file copy.
    $source=Join-Path $root ('VW092-warm-cache-'+$ExpectedHeadSha.Substring(0,12))
    InspectCache $source
    return
}
$device=DeviceProof
if ($Mode -eq 'Seed') {
    SeedCache $root $SourceRunId $ExpectedHeadSha $ExpectedExeSha $device
    return
}
$cacheDir=VerifyCache $root $ExpectedHeadSha $ExpectedExeSha $device
if ($Mode -eq 'Check') {
    Write-Host 'VW092 private cache matches source executable, RTX5090 and seeded driver. No title launched.'
    return
}
if ($GithubRun -lt 1) { throw 'Exact GitHub Actions source build run ID required' }
if (@(Get-Process -Name 'game_scarlett_master','victory' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Another VIctory/game process is active; no launch'
}
$owner=Join-Path $PSScriptRoot 'owner-nvidia-wait-owner.ps1'
$audit=Join-Path $PSScriptRoot 'owner-nvidia-wait-audit.ps1'
if (-not (Test-Path -LiteralPath $owner -PathType Leaf) -or
    -not (Test-Path -LiteralPath $audit -PathType Leaf)) {
    throw 'Exact-source owner runner and audit must be beside cache helper'
}
$lockPath=Join-Path (CacheFolder $root $ExpectedHeadSha) 'PRIVATE-session.lock'
$lock=$null;$had=Test-Path Env:VICTORY_CACHE_DIR;$old=$env:VICTORY_CACHE_DIR
try {
    $lock=[IO.File]::Open($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $env:VICTORY_CACHE_DIR=$cacheDir
    Write-Host 'Persistent private cache enabled for this session only. Back up saves; PLAY required.'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $owner -Mode Run -ExpectedHeadSha $ExpectedHeadSha -GithubRun $GithubRun -Repo $Repo -ReportRoot $ReportRoot -GameRoot $GameRoot
    if ($LASTEXITCODE -ne 0) { throw 'Owner runner exited nonzero; inspect checkpoint rather than retry' }
}
finally {
    if ($had) { $env:VICTORY_CACHE_DIR=$old }
    else { Remove-Item Env:VICTORY_CACHE_DIR -ErrorAction SilentlyContinue }
    if ($null -ne $lock) { $lock.Dispose() }
}
Write-Host 'Only finalized E127/E141/VW092 anonymous ZIPs may be uploaded; private cache stays local.'
