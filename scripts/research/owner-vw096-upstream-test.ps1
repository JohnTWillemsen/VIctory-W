#Requires -Version 5.1
# VW096: Validate an exact source-built GitHub Actions upstream candidate.
# No game launch in SelfTest/Prepare/Recover. Run delegates to E127's literal PLAY.
[CmdletBinding()]
param(
    [ValidateSet('SelfTest','Prepare','Run','Recover')][string]$Mode='Prepare',
    [string]$BuildFolder='',
    [string]$ExpectedOwnerHeadSha='',
    [string]$ExpectedExeSha='',
    [string]$Repo='C:\VIctory-NVIDIA',
    [string]$ReportRoot='C:\VIctory-NVIDIA-Tests',
    [string]$GameRoot='',
    [string]$RunFolder='',
    [ValidateSet('Unknown','Menu','Black','World')][string]$Visual='Unknown',
    [ValidateSet('Unknown','No','Yes')][string]$Controls='Unknown'
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$RepoName='JohnTWillemsen/VIctory-W'
$UpstreamName='trustno1-coder/VIctory-NVIDIA'
$UpstreamCommit='63b902fe1720a5188ee79d94a88c8de0470f6349'
$Release='v2026.11.28.01'
$script:ThisHelper=(Resolve-Path -LiteralPath $PSCommandPath).ProviderPath
function Exact([string]$Body,[string]$Name) {
    $hits=[regex]::Matches($Body,'(?m)^'+[regex]::Escape($Name)+'=([^\r\n]+)\r?$')
    if ($hits.Count -ne 1) { throw ('Manifest missing or duplicate field '+$Name) }
    return $hits[0].Groups[1].Value.Trim()
}
function IsUnder([string]$Folder,[string]$Parent) {
    if (-not (Test-Path -LiteralPath $Folder -PathType Container) -or -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        throw 'Isolated build/report directory missing; no title launched'
    }
    $child=(Resolve-Path -LiteralPath $Folder).ProviderPath.TrimEnd('\')
    $root=(Resolve-Path -LiteralPath $Parent).ProviderPath.TrimEnd('\')
    if (-not $child.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Candidate build must be inside the isolated NVIDIA test root; no title launched'
    }
    foreach ($path in @($child,$root)) {
        if (((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw 'Linked build/report root refused'
        }
    }
}
function OneFile([string]$Root,[string]$Name) {
    $matches=@(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter $Name -ErrorAction Stop)
    if ($matches.Count -ne 1) { throw ('Source artifact requires exactly one '+$Name) }
    if (($matches[0].Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Artifact link rejected' }
    return $matches[0].FullName
}
function Verify([string]$Root,[string]$Owner,[string]$ExeHash) {
    if ($Owner -cnotmatch '^[a-f0-9]{40}$' -or $ExeHash -cnotmatch '^[a-f0-9]{64}$') {
        throw 'Owner exact-head SHA and independent executable SHA-256 required'
    }
    $manifest=OneFile $Root 'VW096-UPSTREAM-BUILD.txt'
    $exe=OneFile $Root 'victory.exe'
    $session=OneFile $Root 'owner-nvidia-session.ps1'
    $helper=OneFile $Root 'owner-vw096-upstream-test.ps1'
    $fields=[IO.File]::ReadAllText($manifest)
    if ((Exact $fields 'format') -cne 'VW096-nvidia-source-v1' -or
        (Exact $fields 'owner_repository') -cne $RepoName -or
        (Exact $fields 'owner_pr_head') -cne $Owner -or
        (Exact $fields 'upstream_repository') -cne $UpstreamName -or
        (Exact $fields 'upstream_release') -cne $Release -or
        (Exact $fields 'upstream_commit') -cne $UpstreamCommit -or
        (Exact $fields 'game_executed') -cne 'false' -or
        (Exact $fields 'proprietary_title_assets_in_artifact') -cne 'false') {
        throw 'Exact upstream source/owner source manifest mismatch; nothing launched'
    }
    $actual=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -cne $ExeHash -or $actual -cne (Exact $fields 'source_built_sha256')) {
        throw 'Executable SHA mismatch against both GitHub CI and downloaded manifest'
    }
    if ((Get-FileHash -LiteralPath $session -Algorithm SHA256).Hash.ToLowerInvariant() -cne (Exact $fields 'e127_harness_sha256')) {
        throw 'E127 report harness differs from CI-tested source'
    }
    if ((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash.ToLowerInvariant() -cne (Exact $fields 'owner_helper_sha256')) {
        throw 'Owner helper differs from CI-tested source'
    }
    if ((Resolve-Path -LiteralPath $helper).ProviderPath -cne $script:ThisHelper) {
        throw 'Run the helper from the CI package; do not substitute a local script'
    }
    return [pscustomobject]@{Exe=$exe;Session=$session;Sha=$actual}
}
function Offline([string]$Folder) {
    $run=[IO.Path]::GetFileName($Folder.TrimEnd('\'))
    if ($run -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$') { throw 'Invalid E127 private run ID' }
    $audit=Join-Path $Repo 'scripts\research\owner-nvidia-perf-audit.ps1'
    if (-not (Test-Path -LiteralPath $audit -PathType Leaf)) { throw 'E141 read-only audit missing from source; E127 ZIP remains valid' }
    & $audit -Mode SelfTest
    if ($LASTEXITCODE -ne 0) { throw 'E141 privacy fixture failed; E127 ZIP remains valid' }
    & $audit -Mode Audit -RunId $run -ReportRoot $ReportRoot
    if ($LASTEXITCODE -ne 0) { throw 'E141 audit failed; E127 ZIP remains valid' }
    Write-Host ('UPLOAD E127 ONLY: '+(Join-Path $Folder 'E127-anonymous-summary.zip'))
    Write-Host ('UPLOAD E141 ONLY: '+(Join-Path (Join-Path $ReportRoot ('E141-offline-'+$run)) 'E141-anonymous-perf-summary.zip'))
}
if ($Mode -eq 'SelfTest') {
    $temp=Join-Path $env:TEMP ('VW096-fixture-'+[Guid]::NewGuid().ToString('N').Substring(0,8))
    $self=$MyInvocation.MyCommand.Path
    try {
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
        $fake=Join-Path $temp 'victory.exe'
        $session=Join-Path $temp 'owner-nvidia-session.ps1'
        $helper=Join-Path $temp 'owner-vw096-upstream-test.ps1'
        $realHelper=$script:ThisHelper
        [IO.File]::WriteAllText($fake,'Synthetic only, not an executable')
        [IO.File]::WriteAllText($session,'Synthetic E127 runner')
        [IO.File]::Copy($self,$helper,$false)
        $sha=(Get-FileHash -LiteralPath $fake -Algorithm SHA256).Hash.ToLowerInvariant()
        $owner='a'*40
        $manifest=@(
          'format=VW096-nvidia-source-v1'
          ('owner_repository='+$RepoName)
          ('owner_pr_head='+$owner)
          ('upstream_repository='+$UpstreamName)
          ('upstream_release='+$Release)
          ('upstream_commit='+$UpstreamCommit)
          ('source_built_sha256='+$sha)
          ('e127_harness_sha256='+(Get-FileHash -LiteralPath $session -Algorithm SHA256).Hash.ToLowerInvariant())
          ('owner_helper_sha256='+(Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash.ToLowerInvariant())
          'game_executed=false'
          'proprietary_title_assets_in_artifact=false'
        )
        $mf=Join-Path $temp 'VW096-UPSTREAM-BUILD.txt'
        [IO.File]::WriteAllLines($mf,$manifest,[Text.UTF8Encoding]::new($false))
        $script:ThisHelper=(Resolve-Path -LiteralPath $helper).ProviderPath
        $ok=Verify $temp $owner $sha
        if ($ok.Sha -cne $sha) { throw 'Positive synthetic provenance fixture failed' }
        $bad=$false
        try { [void](Verify $temp ('b'*40) $sha) } catch { $bad=$true }
        if (-not $bad) { throw 'Wrong owner SHA accepted' }
        $bad=$false
        try { [void](Verify $temp $owner ('f'*64)) } catch { $bad=$true }
        if (-not $bad) { throw 'Wrong binary SHA accepted' }
        Add-Content -LiteralPath $mf -Value ('upstream_commit='+$UpstreamCommit)
        $bad=$false
        try { [void](Verify $temp $owner $sha) } catch { $bad=$true }
        if (-not $bad) { throw 'Duplicate upstream manifest field accepted' }
        Write-Host 'VW096 upstream/owner exact SHA, binary and E127 hashes + negative fixtures PASS; no game launched'
    } finally {
        $script:ThisHelper=$realHelper
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
    }
    return
}
if ($BuildFolder -eq '') { throw 'Provide exact CI artifact directory (-BuildFolder); no title launched' }
IsUnder $BuildFolder $ReportRoot
$build=Verify $BuildFolder $ExpectedOwnerHeadSha $ExpectedExeSha
& $build.Session -Mode SelfTest
if ($LASTEXITCODE -ne 0) { throw 'E127 source-specific privacy SelfTest failed; nothing launched' }
if ($Mode -eq 'Prepare') {
    Write-Host ('VW096 upstream source-built candidate VERIFIED: '+$build.Sha)
    Write-Host 'No game launched; existing H4 executable and private cache untouched.'
    return
}
if (-not (Test-Path -LiteralPath $Repo -PathType Container)) { throw 'NVIDIA source checkout missing' }
$remote=(& git -C $Repo remote get-url origin).Trim()
if ($remote -cne 'https://github.com/JohnTWillemsen/VIctory-W.git') { throw 'NVIDIA official local clone origin mismatch' }
if ((& git -C $Repo branch --show-current).Trim() -cne 'main') { throw 'Local checkout must remain on main' }
if (@(& git -C $Repo status --porcelain).Count -ne 0) { throw 'Local NVIDIA clone has changes; no title launched' }
if ($Mode -eq 'Recover') {
    if ([string]::IsNullOrWhiteSpace($RunFolder)) { throw 'Recover requires an exact run folder' }
    $folder=(Resolve-Path -LiteralPath $RunFolder).ProviderPath.TrimEnd('\')
    $root=(Resolve-Path -LiteralPath $ReportRoot).ProviderPath.TrimEnd('\')
    if ((Split-Path -Parent $folder) -cne $root -or
        (Split-Path -Leaf $folder) -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$') {
        throw 'Recovery folder must be one E127 session immediately inside the new test root'
    }
    & $build.Session -Mode Recover -RunFolder $folder -Visual $Visual -Controls $Controls
    Offline $folder
    return
}
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$admin=[Security.Principal.WindowsPrincipal]::new($identity)
if ($admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Use normal, non-admin PowerShell; no title launched' }
if ([string]::IsNullOrWhiteSpace($GameRoot) -or -not (Test-Path -LiteralPath $GameRoot -PathType Container)) {
    throw 'GameRoot required; existing title folder must remain unchanged'
}
if (@(Get-Process -Name 'victory','game_scarlett_master' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Existing game/VIctory process must exit first; no launch'
}
$games=@(Get-ChildItem -LiteralPath $GameRoot -Recurse -File -Filter 'game_scarlett_master.exe' -ErrorAction Stop)
if ($games.Count -ne 1) { throw ('Expected exactly one original game exe; found '+$games.Count) }
if (-not (Test-Path -LiteralPath (Join-Path $games[0].DirectoryName 'appdata0.rpf') -PathType Leaf)) {
    throw 'Local title archive not found; no launch'
}
$before=@(Get-ChildItem -LiteralPath $ReportRoot -Directory -Filter 'e127-*' -ErrorAction Stop | Select-Object -ExpandProperty Name)
$names=@('VICTORY_CACHE_DIR','VICTORY_TEARING','VICTORY_FRAMEGEN','VICTORY_WARMUP_RESTART','VICTORY_PIPELINE_WAIT_STATS','VICTORY_CARD_COMPARE_EVERY','VICTORY_CARD_COMPARE_HOT')
$prior=@{}
foreach ($key in $names) { $prior[$key]=[Environment]::GetEnvironmentVariable($key,'Process') }
try {
    foreach ($key in $names) { [Environment]::SetEnvironmentVariable($key,$null,'Process') }
    Write-Host 'Upstream v2026.11.28.01 with its default settings; no old persistent cache imported.'
    Write-Host 'Back up saves and expect a possible driver/PC crash. E127 requires literal PLAY.'
    & $build.Session -Mode Start -VictoryExe $build.Exe -GameExe $games[0].FullName -ExpectedSha256 $build.Sha -ReportRoot $ReportRoot
} finally {
    foreach ($key in $names) { [Environment]::SetEnvironmentVariable($key,$prior[$key],'Process') }
}
$after=@(Get-ChildItem -LiteralPath $ReportRoot -Directory -Filter 'e127-*' -ErrorAction Stop | Where-Object { $before -cnotcontains $_.Name })
if ($after.Count -ne 1) {
    Write-Warning 'Find the E127 READY/recovery ZIP under your new test root; no relaunch needed to recover.'
    return
}
$folder=$after[0].FullName
if (-not (Test-Path -LiteralPath (Join-Path $folder 'PRIVATE-never-upload\finished.flag') -PathType Leaf)) {
    Write-Host ('Not finalized (cancelled/crashed). Preserve existing E127 ZIP at '+$folder)
    return
}
Offline $folder
