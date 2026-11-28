#Requires -Version 5.1
# VW-092 bounded NVIDIA owner wait probe. Download this script and
# owner-nvidia-wait-audit.ps1 from the SAME immutable PR61 commit.
# No game launch except via the existing E145 -> E127 literal PLAY gate.
[CmdletBinding()]
param(
    [ValidateSet('SelfTest','Prepare','Run','Recover')][string]$Mode='Prepare',
    [long]$GithubRun=0,
    [string]$ExpectedHeadSha='',
    [string]$Repo='C:\VIctory-NVIDIA',
    [string]$ReportRoot='C:\VIctory-NVIDIA-Tests',
    [string]$GameRoot='C:\Grand Theft Auto',
    [string]$RunFolder=''
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'

function RequiredScript([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ('Missing required owner script: '+[IO.Path]::GetFileName($Path))
    }
    return (Resolve-Path -LiteralPath $Path).ProviderPath
}
function SessionIds([string]$Folder) {
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) { throw 'Report root missing' }
    return @(Get-ChildItem -LiteralPath $Folder -Directory -Filter 'e127-*' -ErrorAction Stop |
        Where-Object { $_.Name -cmatch '^e127-\d{14}-[a-f0-9]{6}$' } |
        Select-Object -ExpandProperty Name)
}
function ReportFor([string]$Folder,[string]$ReportRoot,[string]$Audit) {
    $root=(Resolve-Path -LiteralPath $ReportRoot).ProviderPath.TrimEnd('\')
    $resolved=(Resolve-Path -LiteralPath $Folder).ProviderPath.TrimEnd('\')
    $run=[IO.Path]::GetFileName($resolved)
    if ($run -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$' -or
        (Split-Path -Parent $resolved) -cne $root) {
        throw 'Only a direct E127 run folder under the approved test root can be audited'
    }
    & $Audit -Mode Audit -RunId $run -ReportRoot $ReportRoot
    if ($LASTEXITCODE -ne 0) { throw 'Offline VW092 report failed, original E127 ZIP still retained' }
    $zip=Join-Path (Join-Path $ReportRoot ('VW092-offline-'+$run)) 'VW092-anonymous-wait-summary.zip'
    if (-not (Test-Path -LiteralPath $zip -PathType Leaf)) { throw 'VW092 ZIP missing' }
    Write-Host ('UPLOAD ONLY VW092: '+$zip)
    Write-Host ('UPLOAD ONLY E127: '+(Join-Path $resolved 'E127-anonymous-summary.zip'))
    Write-Host ('UPLOAD ONLY E141: '+(Join-Path (Join-Path $ReportRoot ('E141-offline-'+$run)) 'E141-anonymous-perf-summary.zip'))
}
$audit=RequiredScript (Join-Path $PSScriptRoot 'owner-nvidia-wait-audit.ps1')
if ($Mode -eq 'SelfTest') {
    & $audit -Mode SelfTest
    if ($LASTEXITCODE -ne 0) { throw 'Synthetic wait ZIP fixture failed' }
    $local=Join-Path $Repo 'scripts\research\owner-nvidia-candidate-ab.ps1'
    if (Test-Path -LiteralPath $local -PathType Leaf) {
        & $local -Mode SelfTest
        if ($LASTEXITCODE -ne 0) { throw 'Existing E145 synthetic provenance fixture failed' }
    }
    Write-Host 'VW092 handoff script and offline privacy preflight PASS; no game launched'
    return
}
$handoff=RequiredScript (Join-Path $Repo 'scripts\research\owner-nvidia-candidate-ab.ps1')
if ($Mode -eq 'Recover') {
    if ([string]::IsNullOrWhiteSpace($RunFolder) -or
        -not (Test-Path -LiteralPath $RunFolder -PathType Container)) { throw 'Recover needs a real prior E127 run folder' }
    & $handoff -Mode Recover -RunFolder $RunFolder -Repo $Repo -ReportRoot $ReportRoot
    if ($LASTEXITCODE -ne 0) { throw 'Existing E127/E141 recovery failed; no game launched' }
    ReportFor $RunFolder $ReportRoot $audit
    return
}
if ($ExpectedHeadSha -cnotmatch '^[0-9a-f]{40}$' -or $GithubRun -lt 1) {
    throw 'Provide the exact source-build commit and GitHub Actions run ID. No game launched.'
}
if ($Mode -eq 'Prepare') {
    & $handoff -Mode Prepare -GithubRun $GithubRun -ExpectedHeadSha $ExpectedHeadSha -Repo $Repo -ReportRoot $ReportRoot -GameRoot $GameRoot
    if ($LASTEXITCODE -ne 0) { throw 'Existing E145 preparation failed; no game launched' }
    Write-Host 'VW092 prepared only; no game launched. Use -Mode Run for owner-consented hardware measurement.'
    return
}
$prior=SessionIds $ReportRoot
$hadValue=Test-Path Env:VICTORY_PIPELINE_WAIT_STATS
$oldValue=$env:VICTORY_PIPELINE_WAIT_STATS
try {
    # ONLY numeric instrumentation. E145/E127 independently validate source
    # SHA, RTX5090, user session, game location, and literal PLAY consent.
    $env:VICTORY_PIPELINE_WAIT_STATS='1'
    Write-Host 'VW092 numeric waiting measurement opt-in enabled for this launch ONLY.'
    & $handoff -Mode Run -GithubRun $GithubRun -ExpectedHeadSha $ExpectedHeadSha -Repo $Repo -ReportRoot $ReportRoot -GameRoot $GameRoot
    if ($LASTEXITCODE -ne 0) { throw 'Existing E145 owner launcher failed; E127 checkpoint may still be recoverable' }
}
finally {
    if ($hadValue) { $env:VICTORY_PIPELINE_WAIT_STATS=$oldValue }
    else { Remove-Item Env:VICTORY_PIPELINE_WAIT_STATS -ErrorAction SilentlyContinue }
}
$now=SessionIds $ReportRoot
$new=@($now | Where-Object { $prior -cnotcontains $_ })
if ($new.Count -eq 0) { Write-Host 'No new E127 run created; no wait report generated.'; return }
if ($new.Count -ne 1) { throw 'Ambiguous E127 run count: do not guess; recover with explicit run folder.' }
ReportFor (Join-Path $ReportRoot $new[0]) $ReportRoot $audit
Write-Host 'The VW092 ZIP reports only numeric aggregates. No performance fix is claimed.'
