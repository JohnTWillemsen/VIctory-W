#Requires -Version 5.1
# E098: install ONLY an exact, CI-built, public-source E096 upstream artifact.
# No title reads/writes or game launch unless -Launch is specified and user types PLAY.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ArtifactZip,
  [string]$InstallRoot='C:\VIctory-Tests\Playable-Candidates',
  [string]$ReportRoot='C:\VIctory-Tests',
  [string]$GameExe,
  [switch]$Launch,
  [switch]$ScriptedIntro
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$SourceSha='965d93823587932e8f40b152b8d4faab5f7a9c85'
$SupervisorCommit='61e5c95dbedd55bb7a39478e9f623fee59cb02aa'
function Get-Manifest([string]$Path) {
  $Data=@{}
  foreach($Line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
    if([string]::IsNullOrWhiteSpace($Line)){continue}
    $Index=$Line.IndexOf('=')
    if($Index -le 0){throw 'Malformed build manifest entry'}
    $Name=$Line.Substring(0,$Index)
    $Value=$Line.Substring($Index+1)
    if($Data.ContainsKey($Name)){throw 'Duplicate build manifest key'}
    $Data[$Name]=$Value
  }
  return $Data
}
function UnpackChecked([string]$Zip,[string]$Destination) {
  Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
  $Archive=[System.IO.Compression.ZipFile]::OpenRead($Zip)
  try {
    $Names=@($Archive.Entries | ForEach-Object { $_.FullName })
    $Allowed=@('victory.exe','BUILD-MANIFEST.txt')
    if($Names.Count -ne 2 -or @($Names | Where-Object { $_ -notin $Allowed }).Count -ne 0 -or @($Names | Select-Object -Unique).Count -ne 2) {
      throw 'Unexpected or unsafe ZIP members: expected exactly public victory.exe and BUILD-MANIFEST.txt'
    }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($Zip,$Destination)
  } finally {
    $Archive.Dispose()
  }
}
if(-not (Test-Path -LiteralPath $ArtifactZip -PathType Leaf)){throw 'Artifact ZIP not found'}
$ArtifactZip=(Resolve-Path -LiteralPath $ArtifactZip).ProviderPath
$Staging=Join-Path ([System.IO.Path]::GetTempPath()) ('e098-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Staging -Force | Out-Null
try {
  UnpackChecked $ArtifactZip $Staging
  $Manifest=Get-Manifest (Join-Path $Staging 'BUILD-MANIFEST.txt')
  if($Manifest['format'] -cne 'E096-public-source-build-v1'){throw 'Artifact is not the selected E096 upstream release'}
  if($Manifest['source_commit'] -cne $SourceSha){throw 'Unreviewed upstream source version'}
  if($Manifest['title_test'] -cne 'NOT_RUN' -or $Manifest['physical_rtx5090_test'] -cne 'NOT_RUN'){
    throw 'Manifest does not match the approved CI-only artifact contract'
  }
  if($Manifest['contains_game_files'] -cne 'false'){throw 'Refusing artifact not explicitly game-data-free'}
  $ExpectedHash=$Manifest['binary_sha256']
  if($ExpectedHash -notmatch '^[a-fA-F0-9]{64}$'){throw 'Manifest binary SHA256 is invalid'}
  $ExpectedHash=$ExpectedHash.ToLowerInvariant()
  $ActualHash=(Get-FileHash -LiteralPath (Join-Path $Staging 'victory.exe') -Algorithm SHA256).Hash.ToLowerInvariant()
  if($ActualHash -cne $ExpectedHash){throw 'Executable SHA256 mismatch; nothing installed'}
  $Target=Join-Path $InstallRoot ('E096-'+$SourceSha.Substring(0,12)+'-'+$ActualHash.Substring(0,12))
  if(Test-Path -LiteralPath $Target) {
    $Installed=Join-Path $Target 'victory.exe'
    if(-not (Test-Path -LiteralPath $Installed -PathType Leaf)){throw 'Existing candidate directory is incomplete; refusing overwrite'}
    $Existing=(Get-FileHash -LiteralPath $Installed -Algorithm SHA256).Hash.ToLowerInvariant()
    if($Existing -cne $ActualHash){throw 'Existing candidate has different contents; refusing overwrite'}
    Write-Host 'Exact candidate already installed; keeping existing files.'
  } else {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $Staging 'victory.exe') -Destination (Join-Path $Target 'victory.exe')
    Copy-Item -LiteralPath (Join-Path $Staging 'BUILD-MANIFEST.txt') -Destination (Join-Path $Target 'BUILD-MANIFEST.txt')
    Write-Host 'Installed isolated public-source candidate. Original victory.exe untouched.'
  }
  $Installed=Join-Path $Target 'victory.exe'
  Write-Host ('Candidate: '+$Installed)
  Write-Host ('Verified SHA256: '+$ActualHash)
  Write-Host ('Pinned upstream commit: '+$SourceSha)
  if($Launch) {
    if([string]::IsNullOrWhiteSpace($GameExe)){throw 'Launch requested but -GameExe missing; build remains safely installed'}
    if(-not (Test-Path -LiteralPath $GameExe -PathType Leaf)){throw 'Local game executable path not found'}
    $GpuCmd=Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    if($null -eq $GpuCmd){throw 'NVIDIA GPU preflight unavailable; no launch'}
    $GPU=(& $GpuCmd.Source --query-gpu=name --format=csv,noheader 2>&1 | Out-String)
    if($LASTEXITCODE -ne 0 -or $GPU -notmatch 'RTX 5090'){throw 'Not an RTX 5090; refusing target test'}
    $Supervisor=Join-Path $Target 'owner-e087-durable-game-run.ps1'
    if(-not (Test-Path -LiteralPath $Supervisor -PathType Leaf)) {
      $Url='https://raw.githubusercontent.com/JohnTWillemsen/VIctory-W/'+$SupervisorCommit+'/scripts/research/owner-e087-durable-game-run.ps1'
      Invoke-WebRequest -Uri $Url -UseBasicParsing -OutFile $Supervisor
    }
    $Tokens=$null; $Errors=$null
    $null=[System.Management.Automation.Language.Parser]::ParseFile($Supervisor,[ref]$Tokens,[ref]$Errors)
    if($Errors.Count -ne 0){throw 'Downloaded pinned crash supervisor did not parse; no launch'}
    $ArgsTable=@{
      Mode='Start';VictoryExe=$Installed;GameExe=$GameExe;ExpectedSha256=$ActualHash;ReportRoot=$ReportRoot
    }
    if($ScriptedIntro){$ArgsTable['ScriptedIntro']=$true}
    Write-Host 'Launching through the existing independently tested E087 crash-report supervisor.'
    & $Supervisor @ArgsTable
    Write-Host 'Only upload E087-anonymous-summary.zip privately in ChatGPT; keep game files and PRIVATE logs locally.'
  }
} finally {
  if(Test-Path -LiteralPath $Staging){Remove-Item -LiteralPath $Staging -Recurse -Force}
}
