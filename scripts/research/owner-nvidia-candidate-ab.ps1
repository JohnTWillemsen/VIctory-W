#Requires -Version 5.1
# E145 owner-side candidate A/B helper. Runs only after literal PLAY in E127.
# It never uploads private logs, game files, saves, shaders or local paths.
[CmdletBinding()]
param(
    [ValidateSet('SelfTest','Prepare','Run','Recover')][string]$Mode='Prepare',
    [long]$GithubRun=0,
    [string]$ExpectedHeadSha='',
    [ValidateSet('0','1')][string]$Tearing='0',
    [switch]$AllowDetachedCandidateWorktree,
    [string]$Repo='C:\VIctory-NVIDIA',
    [string]$ReportRoot='C:\VIctory-NVIDIA-Tests',
    [string]$GameRoot='C:\Grand Theft Auto',
    [string]$RunFolder='',
    [ValidateSet('Unknown','Menu','Black','World')][string]$Visual='Unknown',
    [ValidateSet('Unknown','No','Yes')][string]$Controls='Unknown'
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$RepoName='JohnTWillemsen/VIctory-W'
$UpstreamPin='64d4931b3dd90305134512b805fc98f04119fb6e'
$ArtifactName='E127-source-built-nvidia-v8'

function ExactLine([string]$Body,[string]$Key) {
    $pattern='(?m)^'+[regex]::Escape($Key)+'=([^\r\n]+)\r?$'
    $hits=[regex]::Matches($Body,$pattern)
    if ($hits.Count -ne 1) { throw ('Artifact manifest must contain one exact '+$Key) }
    return $hits[0].Groups[1].Value.Trim()
}
function VerifiedBuild([string]$Folder,[string]$Head) {
    if ($Head -cnotmatch '^[0-9a-f]{40}$') { throw 'Expected commit must be 40 lowercase hex characters' }
    $exes=@(Get-ChildItem -LiteralPath $Folder -Recurse -File -Filter 'victory.exe')
    $mans=@(Get-ChildItem -LiteralPath $Folder -Recurse -File -Filter 'E127-NVIDIA-SOURCE-BUILD.txt')
    if ($exes.Count -ne 1 -or $mans.Count -ne 1) { throw 'Source artifact must contain exactly one executable and one provenance manifest' }
    $text=[IO.File]::ReadAllText($mans[0].FullName)
    if ((ExactLine $text 'format') -cne 'E127-nvidia-source-v1') { throw 'Unknown source manifest format' }
    if ((ExactLine $text 'source') -cne 'trustno1-coder/VIctory-NVIDIA') { throw 'Unexpected NVIDIA source' }
    if ((ExactLine $text 'source_commit') -cne $UpstreamPin) { throw 'NVIDIA source pin mismatch' }
    if ((ExactLine $text 'victory_w_commit') -cne $Head) { throw 'Candidate commit mismatch' }
    if ((ExactLine $text 'proprietary_title_assets_in_artifact') -cne 'false') { throw 'Source artifact declared title assets' }
    if ((ExactLine $text 'game_executed') -cne 'false') { throw 'GitHub artifact must not claim gameplay execution' }
    $sha=(Get-FileHash -LiteralPath $exes[0].FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sha -cne (ExactLine $text 'source_built_sha256')) { throw 'Downloaded executable SHA-256 mismatch' }
    return [pscustomobject]@{ Exe=$exes[0].FullName; Sha=$sha; Commit=$Head }
}
# A dedicated, detached owner worktree can run an exact candidate without
# changing the existing normal main checkout at C:\VIctory-NVIDIA.
function CheckoutAllowed([string]$Branch,[string]$Current,[string]$Expected,[bool]$Detached) {
    if ($Detached) { return (($Branch -ceq '') -and ($Current -ceq $Expected)) }
    return ($Branch -ceq 'main')
}
function Harness([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Required GitHub test script missing' }
    & $Path -Mode SelfTest
    if ($LASTEXITCODE -ne 0) { throw 'Game-free privacy/selftest failed; no game launched' }
}
function OfflineFor([string]$Folder) {
    $run=[IO.Path]::GetFileName($Folder.TrimEnd([IO.Path]::DirectorySeparatorChar))
    if ($run -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$') { throw 'Invalid E127 folder ID' }
    $perf=Join-Path $Repo 'scripts\research\owner-nvidia-perf-audit.ps1'
    & $perf -Mode Audit -RunId $run -ReportRoot $ReportRoot
    if ($LASTEXITCODE -ne 0) { throw 'Offline E141 analysis failed, original E127 ZIP still available' }
    Write-Host ('UPLOAD E127: '+(Join-Path $Folder 'E127-anonymous-summary.zip'))
    Write-Host ('UPLOAD E141: '+(Join-Path (Join-Path $ReportRoot ('E141-offline-'+$run)) 'E141-anonymous-perf-summary.zip'))
}
if ($Mode -eq 'SelfTest') {
    $root=Join-Path $env:TEMP ('E145-selftest-'+[guid]::NewGuid().ToString('N').Substring(0,10))
    $expected='a' * 40
    try {
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        $fake=Join-Path $root 'victory.exe'
        [IO.File]::WriteAllText($fake,'Synthetic bytes only. Not an executable. Private C:\secret\game.rpf')
        $sha=(Get-FileHash -LiteralPath $fake -Algorithm SHA256).Hash.ToLowerInvariant()
        $body=@(
            'format=E127-nvidia-source-v1'
            'source=trustno1-coder/VIctory-NVIDIA'
            ('source_commit='+$UpstreamPin)
            ('victory_w_commit='+$expected)
            ('source_built_sha256='+$sha)
            'proprietary_title_assets_in_artifact=false'
            'game_executed=false'
        )
        [IO.File]::WriteAllLines((Join-Path $root 'E127-NVIDIA-SOURCE-BUILD.txt'),$body)
        $ok=VerifiedBuild $root $expected
        if ($ok.Sha -cne $sha -or $ok.Commit -cne $expected) { throw 'Source provenance positive fixture mismatch' }
        $rejected=$false
        try { [void](VerifiedBuild $root ('b' * 40)) } catch { $rejected=$true }
        if (-not $rejected) { throw 'Wrong commit was not rejected' }
        Add-Content -LiteralPath (Join-Path $root 'E127-NVIDIA-SOURCE-BUILD.txt') -Value 'source_built_sha256=0000'
        $rejected=$false
        try { [void](VerifiedBuild $root $expected) } catch { $rejected=$true }
        if (-not $rejected) { throw 'Duplicated manifest hash was not rejected' }
        if (-not (CheckoutAllowed '' $expected $expected $true)) { throw 'Exact detached candidate rejected' }
        if (CheckoutAllowed '' ('b'*40) $expected $true) { throw 'Wrong detached worktree SHA accepted' }
        if (CheckoutAllowed 'main' $expected $expected $true) { throw 'Attached branch accepted as detached worktree' }
        if (-not (CheckoutAllowed 'main' ('b'*40) $expected $false)) { throw 'Old main-based preflight regressed' }
        Write-Host 'E145 source artifact SHA and commit verification, fail-closed fixtures PASS; no title launched'
    }
    finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    }
    return
}
$session=Join-Path $Repo 'scripts\research\owner-nvidia-session.ps1'
$perf=Join-Path $Repo 'scripts\research\owner-nvidia-perf-audit.ps1'
if ($Mode -eq 'Recover') {
    if ([string]::IsNullOrWhiteSpace($RunFolder)) { throw 'Recover requires your exact E127 run folder' }
    if (-not (Test-Path -LiteralPath $RunFolder -PathType Container)) { throw 'E127 run folder missing' }
    $base=(Resolve-Path -LiteralPath $ReportRoot).ProviderPath.TrimEnd('\')
    $folder=(Resolve-Path -LiteralPath $RunFolder).ProviderPath.TrimEnd('\')
    if ((Split-Path -Parent $folder) -cne $base -or (Split-Path -Leaf $folder) -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$') {
        throw 'Run folder must be a direct E127 session under the specified test root'
    }
    & $session -Mode Recover -RunFolder $folder -Visual $Visual -Controls $Controls
    OfflineFor $folder
    return
}
if ($ExpectedHeadSha -cnotmatch '^[0-9a-f]{40}$') { throw 'Provide exact 40-hex candidate head from verified GitHub CI' }
if ($GithubRun -lt 1) { throw 'Provide exact GitHub Actions source release run ID' }
if (-not (Test-Path -LiteralPath $Repo -PathType Container)) { throw 'NVIDIA source directory missing' }
if (-not (Test-Path -LiteralPath $ReportRoot -PathType Container)) { throw 'NVIDIA private test directory missing' }
$checkedBranch=(& git -C $Repo branch --show-current).Trim()
$checkedSha=(& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
if (-not (CheckoutAllowed $checkedBranch $checkedSha $ExpectedHeadSha ([bool]$AllowDetachedCandidateWorktree))) {
    throw 'Source checkout must be main, or exact detached candidate SHA in opted-in worktree'
}
if ($AllowDetachedCandidateWorktree) {
    $work=(Resolve-Path -LiteralPath $Repo).ProviderPath.TrimEnd('\')
    $test=(Resolve-Path -LiteralPath $ReportRoot).ProviderPath.TrimEnd('\')
    $expectedWork=Join-Path $test ('E158-owner-source-'+$ExpectedHeadSha.Substring(0,12))
    if ($work -ine $expectedWork) { throw 'Detached candidate checkout must be the exact isolated E158 folder under report root' }
}
if ((& git -C $Repo remote get-url origin).Trim() -cne 'https://github.com/JohnTWillemsen/VIctory-W.git') {
    throw 'Source Git remote is not the existing official project'
}
if (@(& git -C $Repo status --porcelain).Count -ne 0) { throw 'Local source has uncommitted changes; no changes made' }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI (gh) is required to fetch a verified artifact' }
Harness $session
Harness $perf
$build=Join-Path $ReportRoot ('E145-candidate-'+$ExpectedHeadSha.Substring(0,12)+'-'+[guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Force -Path $build | Out-Null
Write-Host 'Downloading source-built GitHub Actions artifact into isolated test folder.'
& gh run download $GithubRun -R $RepoName -n $ArtifactName -D $build
if ($LASTEXITCODE -ne 0) { throw 'GitHub source artifact download failed; no title launched' }
$candidate=VerifiedBuild $build $ExpectedHeadSha
@(
    'format=E145-candidate-provenance-v1'
    ('candidate_commit='+$candidate.Commit)
    ('source_executable_sha256='+$candidate.Sha)
    ('source_commit='+$UpstreamPin)
    ('github_actions_run_id='+$GithubRun)
    'verified_provenance=true'
    ('dxgi_tearing_requested='+$(if($Tearing -eq '1'){'ON'}else{'OFF'}))
    'game_launched_during_preflight=false'
    'private_paths_or_title_assets_in_report=false'
) | Set-Content -LiteralPath (Join-Path $build 'E145-anonymous-preflight.txt') -Encoding ASCII
Write-Host ('SOURCE-MATCHED CANDIDATE VERIFIED: '+$candidate.Sha)
Write-Host ('Private build directory: '+$build)
Write-Host ('Optional upload before running: '+(Join-Path $build 'E145-anonymous-preflight.txt'))
if ($Mode -eq 'Prepare') { return }

$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=[Security.Principal.WindowsPrincipal]::new($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Use a normal non-administrator PowerShell; no title launched' }
if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw 'Expected local game root missing; no game launched' }
$games=@(Get-ChildItem -LiteralPath $GameRoot -File -Recurse -Filter 'game_scarlett_master.exe' -ErrorAction SilentlyContinue)
if ($games.Count -ne 1) { throw ('Expected exactly one local game executable, found '+$games.Count) }
$game=$games[0].FullName
if (-not (Test-Path -LiteralPath (Join-Path $games[0].DirectoryName 'appdata0.rpf') -PathType Leaf)) { throw 'Local game startup archive missing' }
$before=@(Get-ChildItem -LiteralPath $ReportRoot -Directory -Filter 'e127-*' | Select-Object -ExpandProperty Name)
Write-Host 'E127 will request explicit PLAY consent. Back up saves before typing PLAY.'
Write-Host 'Stay in the same first playable interior; observe movement/FPS, not broad progression.'
& $session -Mode Start -VictoryExe $candidate.Exe -GameExe $game -ExpectedSha256 $candidate.Sha -ReportRoot $ReportRoot -Tearing $Tearing
$after=@(Get-ChildItem -LiteralPath $ReportRoot -Directory -Filter 'e127-*' | Where-Object { $before -cnotcontains $_.Name })
if ($after.Count -ne 1) {
    Write-Warning 'Could not identify one new E127 run; E127 checkpoint is under the test root, use Recover after crash/reboot.'
    return
}
OfflineFor $after[0].FullName
