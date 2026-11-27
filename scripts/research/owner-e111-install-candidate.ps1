#Requires -Version 5.1
# E111: verify and isolate ONLY CI-produced E108 or E109 public-source build ZIPs.
# Installing never runs a game. -Launch is opt-in and E087 additionally requires typing PLAY.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][ValidateSet('E108','E109')][string]$Candidate,
  [Parameter(Mandatory=$true)][string]$ArtifactZip,
  [string]$InstallRoot='C:\VIctory-Tests\Playable-Candidates',
  [string]$ReportRoot='C:\VIctory-Tests',
  [string]$GameExe,
  [switch]$Launch,
  [switch]$ScriptedIntro
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$SupervisorCommit='61e5c95dbedd55bb7a39478e9f623fee59cb02aa'
$Base='965d93823587932e8f40b152b8d4faab5f7a9c85'
$ForkParent='712325801d17466c5ce6ff85d96065a5a22814e1'
$Requirements=@{
  E108=@{
    'format'='E108-public-source-nvidia-wave-barrier-v1'
    'git_commit'='70a58749a1b6bce7f4f215aaffd06d4cf07d00d4'
    'experiment_patch_commit'='b66e63d6a1869151e5729eec5584026991c5676b'
    'parent_fork_pr27'=$ForkParent
    'base_upstream_pr3409'=$Base
    'wave_barrier_upstream_pr2920'='ef794e8c32ce92365775eaeea16abb912a07f324'
    'profile'='release'
    'feature'='diagnostics'
    'owner_rtx5090_test'='NOT_RUN'
    'title_in_artifact'='false'
  }
  E109=@{
    'format'='E109-public-source-1d-thread-dispatch-v1'
    'git_commit'='8c8498e72f4bd46925ed07cf562947fccfc33bf1'
    'experiment_patch_commit'='94e3871de5a8625f2e6580a47d9612802656ffd9'
    'parent_fork_pr27'=$ForkParent
    'upstream_pr3409'=$Base
    'upstream_pr3426'='3f477b13b05cb8812dfc1f808e54b5230aac11ac'
    'upstream_pr3561'='b9000218cc129b88af1be4bd536b2c215517aaf4'
    'profile'='release'
    'feature'='diagnostics'
    'owner_rtx5090_test'='NOT_RUN'
    'contains_game_assets'='false'
  }
}
function Read-Manifest([string]$Path) {
    if((Get-Item -LiteralPath $Path).Length -gt 8192){throw 'Build manifest too large'}
    $M=@{}
    foreach($Line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
        if([string]::IsNullOrWhiteSpace($Line)){continue}
        $At=$Line.IndexOf('=')
        if($At -le 0){throw 'Malformed manifest field'}
        $Key=$Line.Substring(0,$At)
        $Value=$Line.Substring($At+1)
        if($M.ContainsKey($Key)){throw 'Duplicate manifest field'}
        $M[$Key]=$Value
    }
    return $M
}
function Read-CheckedZip([string]$Path,[string]$Folder,[string]$ManifestName) {
    Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    $Archive=[IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $Entries=@($Archive.Entries)
        # Windows PowerShell 5.1's ZipFile may use backslashes for nested paths.
        # Normalize ZIP metadata only; never use archive paths as extraction destinations.
        $Names=@($Entries | ForEach-Object {$_.FullName.Replace('\','/')})
        if($Entries.Count -ne 2 -or @($Names|Select-Object -Unique).Count -ne 2){
            throw 'Expected exactly two unique artifact members'
        }
        $ExeNames=@($Names | Where-Object {$_ -ceq 'victory.exe' -or $_ -ceq 'target/release/victory.exe'})
        if($ExeNames.Count -ne 1){throw 'Missing expected executable member'}
        $ExeName=$ExeNames[0]
        if($Names -cnotcontains $ManifestName -or @($Names|Where-Object{$_ -cne $ManifestName -and $_ -cne $ExeName}).Count -ne 0){
            throw 'Unexpected archive members or manifest'
        }
        foreach($Entry in $Entries){
            $SafeName=if($Entry.FullName.Replace('\','/') -ceq $ManifestName){$ManifestName}else{'victory.exe'}
            if($SafeName -ceq $ManifestName -and $Entry.Length -gt 8192){throw 'Oversized build manifest'}
            if($SafeName -ceq 'victory.exe' -and $Entry.Length -gt 209715200){throw 'Oversized candidate executable'}
            # Extract each entry into a fixed filename. No source archive path may
            # influence a filesystem destination (blocks ZIP path traversal).
            $InputStream=$null;$OutputStream=$null
            try {
                $InputStream=$Entry.Open()
                $OutputStream=[IO.File]::Create((Join-Path $Folder $SafeName))
                $InputStream.CopyTo($OutputStream)
            } finally {
                if($null -ne $OutputStream){$OutputStream.Dispose()}
                if($null -ne $InputStream){$InputStream.Dispose()}
            }
        }
        return 'victory.exe'
    } finally {
        $Archive.Dispose()
    }
}
if(-not(Test-Path -LiteralPath $ArtifactZip -PathType Leaf)){throw 'Artifact ZIP not found'}
$ArtifactZip=(Resolve-Path -LiteralPath $ArtifactZip).ProviderPath
$Spec=$Requirements[$Candidate]
$ManifestName=$Candidate+'-BUILD-MANIFEST.txt'
$Staging=Join-Path ([IO.Path]::GetTempPath()) ('e111-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Staging -Force|Out-Null
try {
    $ExeName=Read-CheckedZip $ArtifactZip $Staging $ManifestName
    $Manifest=Read-Manifest (Join-Path $Staging $ManifestName)
    if($Manifest.Count -ne $Spec.Count+1){throw 'Manifest field inventory does not match pinned source contract'}
    foreach($Key in $Spec.Keys){
        if($Manifest[$Key] -cne $Spec[$Key]){throw ('Unapproved artifact manifest field: '+$Key)}
    }
    if(@($Manifest.Keys|Where-Object{$_ -notin @($Spec.Keys) -and $_ -cne 'binary_sha256'}).Count -ne 0){
        throw 'Unknown manifest field'
    }
    $Hash=$Manifest['binary_sha256']
    if($null -eq $Hash -or $Hash -cnotmatch '^[0-9a-fA-F]{64}$'){throw 'Manifest SHA256 is not valid'}
    $Hash=$Hash.ToLowerInvariant()
    $Actual=(Get-FileHash -LiteralPath (Join-Path $Staging $ExeName) -Algorithm SHA256).Hash.ToLowerInvariant()
    if($Actual -cne $Hash){throw 'Executable SHA256 mismatch; no installation'}
    $Short=$Hash.Substring(0,12)
    $Target=Join-Path $InstallRoot ($Candidate+'-'+$Spec['experiment_patch_commit'].Substring(0,12)+'-'+$Short)
    $Installed=Join-Path $Target 'victory.exe'
    if(Test-Path -LiteralPath $Target){
        if(-not(Test-Path -LiteralPath $Installed -PathType Leaf)){throw 'Existing candidate directory incomplete'}
        $Existing=(Get-FileHash -LiteralPath $Installed -Algorithm SHA256).Hash.ToLowerInvariant()
        if($Existing -cne $Hash){throw 'Existing candidate contents changed; refusing overwrite'}
        Write-Host 'Matching candidate already installed; leaving it intact.'
    } else {
        New-Item -ItemType Directory -Path $InstallRoot -Force|Out-Null
        $Tmp=Join-Path $InstallRoot ('.e111-staging-'+[Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $Tmp|Out-Null
        try {
            Copy-Item -LiteralPath (Join-Path $Staging $ExeName) -Destination (Join-Path $Tmp 'victory.exe')
            Copy-Item -LiteralPath (Join-Path $Staging $ManifestName) -Destination (Join-Path $Tmp $ManifestName)
            Move-Item -LiteralPath $Tmp -Destination $Target
            Write-Host 'Installed an isolated CI-only candidate. Original executable untouched.'
        } finally {
            if(Test-Path -LiteralPath $Tmp){Remove-Item -LiteralPath $Tmp -Recurse -Force}
        }
    }
    Write-Host ('Candidate: '+$Installed)
    Write-Host ('Verified executable SHA256: '+$Hash)
    Write-Host ('Pinned source head: '+$Spec['git_commit'])
    if($Launch) {
        if([string]::IsNullOrWhiteSpace($GameExe) -or -not(Test-Path -LiteralPath $GameExe -PathType Leaf)){
            throw 'GameExe must point to existing LOCAL title file when -Launch used'
        }
        $GpuCommand=Get-Command 'nvidia-smi.exe' -ErrorAction SilentlyContinue
        if($null -eq $GpuCommand){throw 'NVIDIA GPU diagnostics utility missing; no launch'}
        $Gpu=(& $GpuCommand.Source --query-gpu=name --format=csv,noheader 2>&1|Out-String)
        if($LASTEXITCODE -ne 0 -or $Gpu -notmatch 'RTX 5090'){throw 'RTX5090 preflight failed; no launch'}
        $Supervisor=Join-Path $Target 'owner-e087-durable-game-run.ps1'
        if(-not(Test-Path -LiteralPath $Supervisor -PathType Leaf)){
            $Url='https://raw.githubusercontent.com/JohnTWillemsen/VIctory-W/'+$SupervisorCommit+'/scripts/research/owner-e087-durable-game-run.ps1'
            Invoke-WebRequest -Uri $Url -OutFile $Supervisor -UseBasicParsing
        }
        $Tok=$null;$Err=$null
        $null=[Management.Automation.Language.Parser]::ParseFile($Supervisor,[ref]$Tok,[ref]$Err)
        if($Err.Count -ne 0){throw 'Pinned E087 supervisor syntax validation failed'}
        $Args=@{Mode='Start';VictoryExe=$Installed;GameExe=$GameExe;ExpectedSha256=$Hash;ReportRoot=$ReportRoot}
        if($ScriptedIntro){$Args['ScriptedIntro']=$true}
        Write-Host 'E087 supervisor will require explicit PLAY confirmation.'
        & $Supervisor @Args
        Write-Host 'Upload only the E087-anonymous-summary.zip; keep PRIVATE logs and title files local.'
    }
} finally {
    if(Test-Path -LiteralPath $Staging){Remove-Item -LiteralPath $Staging -Recurse -Force}
}
