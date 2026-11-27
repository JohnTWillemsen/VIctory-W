#Requires -Version 5.1
# E096: public-source-only pinned latest #3409 Windows source acceptance and artifact staging.
# This script NEVER executes a game or reads a private title path.
[CmdletBinding()]
param(
    [string]$SourceDirectory = 'e096-public-upstream',
    [string]$OutputDirectory = 'e096-public-artifact',
    [switch]$Build
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$Expected='965d93823587932e8f40b152b8d4faab5f7a9c85'
$Prior='1e25b230d6572f08e718a1df31a619bb43070481'
$Main='63bcca43c6a00a758510398fa43096ce7e4f7df0'
function CheckedGit {
    param([string[]]$Args)
    & git.exe @Args
    if($LASTEXITCODE -ne 0){throw ('E096 git operation failed (code '+$LASTEXITCODE+')')}
}
if(Test-Path -LiteralPath $SourceDirectory){throw 'E096 refuses to overwrite an existing source directory'}
if($SourceDirectory -eq $OutputDirectory){throw 'Source and output directories must differ'}
CheckedGit @('clone','--quiet','--no-tags','https://github.com/Marvisak/VIctory.git',$SourceDirectory)
CheckedGit @('-C',$SourceDirectory,'fetch','--quiet','--no-tags','origin','refs/pull/3409/head')
$Got=(& git.exe -C $SourceDirectory rev-parse FETCH_HEAD | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $Got -cne $Expected){throw ('E096 source drift: pinned '+$Expected+' got '+$Got)}
CheckedGit @('-C',$SourceDirectory,'checkout','--quiet','--detach',$Expected)
$Sha=(& git.exe -C $SourceDirectory rev-parse HEAD | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $Sha -cne $Expected){throw 'E096 checkout mismatch'}
$Ancestor=(& git.exe -C $SourceDirectory merge-base $Prior $Expected | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $Ancestor -cne $Prior){throw 'E096 new upstream is not a descendant of owner-tested earlier head'}
$Status=(& git.exe -C $SourceDirectory status --porcelain=v1 | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $Status){throw 'E096 checkout has unexpected working tree changes'}
Write-Host 'E096 pinned source accepted: head is 66 commits newer than owner-tested E085, no owner/title test performed.'
if(-not $Build){return}
Push-Location $SourceDirectory
try{
    & cargo.exe check --workspace --all-targets --locked
    if($LASTEXITCODE -ne 0){throw 'E096 source check failed'}
    & cargo.exe clippy --workspace --all-targets --locked -- -D warnings
    if($LASTEXITCODE -ne 0){throw 'E096 clippy failed'}
    & cargo.exe clippy --workspace --all-targets --all-features --locked -- -D warnings
    if($LASTEXITCODE -ne 0){throw 'E096 diagnostics clippy failed'}
    & cargo.exe test --workspace --locked
    if($LASTEXITCODE -ne 0){throw 'E096 workspace tests failed; do not package executable'}
    & cargo.exe build --release --locked -p victory --features diagnostics
    if($LASTEXITCODE -ne 0){throw 'E096 release diagnostics build failed'}
    if(-not (Test-Path -LiteralPath 'target\release\victory.exe' -PathType Leaf)){
        throw 'E096 compiled executable missing'
    }
    $Exe=(Resolve-Path -LiteralPath 'target\release\victory.exe').ProviderPath
    $Hash=(Get-FileHash -LiteralPath $Exe -Algorithm SHA256).Hash.ToLowerInvariant()
}finally{Pop-Location}
if(Test-Path -LiteralPath $OutputDirectory){throw 'E096 refuses to overwrite existing output'}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
Copy-Item -LiteralPath $Exe -Destination (Join-Path $OutputDirectory 'victory.exe')
@(
 'format=E096-public-source-build-v1',
 'source_repo=Marvisak/VIctory',
 'upstream_pr=3409',
 'source_commit='+$Expected,
 'prior_owner_e085_source='+$Prior,
 'base_main='+$Main,
 'binary_sha256='+$Hash,
 'build=hosted_windows_release_diagnostics',
 'title_test=NOT_RUN',
 'physical_rtx5090_test=NOT_RUN',
 'contains_game_files=false'
) | Set-Content -LiteralPath (Join-Path $OutputDirectory 'BUILD-MANIFEST.txt') -Encoding ASCII
Write-Host ('E096 public-source release and manifest prepared; SHA256 '+$Hash)
