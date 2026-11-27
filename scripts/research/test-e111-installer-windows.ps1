#Requires -Version 5.1
$ErrorActionPreference='Stop'
$Script=(Resolve-Path -LiteralPath 'scripts/research/owner-e111-install-candidate.ps1').ProviderPath
$Tokens=$null;$Problems=$null
$null=[Management.Automation.Language.Parser]::ParseFile($Script,[ref]$Tokens,[ref]$Problems)
if($Problems.Count){throw 'E111 installer PowerShell syntax failed'}
$Src=Get-Content -LiteralPath $Script -Raw
if(-not $Src.Contains('if($Launch)')){throw 'Launch must be explicitly gated'}
$Root=Join-Path ([IO.Path]::GetTempPath()) ('e111-fixture-'+[Guid]::NewGuid().ToString('N'))
$Install=Join-Path $Root 'installed'
New-Item -ItemType Directory -Path $Root|Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
function SpecLines([string]$Candidate,[string]$Hash) {
    if($Candidate -eq 'E108'){
        return @(
            'format=E108-public-source-nvidia-wave-barrier-v1'
            'git_commit=70a58749a1b6bce7f4f215aaffd06d4cf07d00d4'
            'experiment_patch_commit=b66e63d6a1869151e5729eec5584026991c5676b'
            'parent_fork_pr27=712325801d17466c5ce6ff85d96065a5a22814e1'
            'base_upstream_pr3409=965d93823587932e8f40b152b8d4faab5f7a9c85'
            'wave_barrier_upstream_pr2920=ef794e8c32ce92365775eaeea16abb912a07f324'
            "binary_sha256=$Hash"
            'profile=release'
            'feature=diagnostics'
            'owner_rtx5090_test=NOT_RUN'
            'title_in_artifact=false'
        )
    }
    return @(
        'format=E109-public-source-1d-thread-dispatch-v1'
        'git_commit=8c8498e72f4bd46925ed07cf562947fccfc33bf1'
        'experiment_patch_commit=94e3871de5a8625f2e6580a47d9612802656ffd9'
        'parent_fork_pr27=712325801d17466c5ce6ff85d96065a5a22814e1'
        'upstream_pr3409=965d93823587932e8f40b152b8d4faab5f7a9c85'
        'upstream_pr3426=3f477b13b05cb8812dfc1f808e54b5230aac11ac'
        'upstream_pr3561=b9000218cc129b88af1be4bd536b2c215517aaf4'
        "binary_sha256=$Hash"
        'profile=release'
        'feature=diagnostics'
        'owner_rtx5090_test=NOT_RUN'
        'contains_game_assets=false'
    )
}
function Make-Zip([string]$Candidate,[string]$Mode) {
    $Folder=Join-Path $Root ($Candidate+'-'+$Mode)
    New-Item -ItemType Directory -Path (Join-Path $Folder 'target\release') -Force|Out-Null
    $Exe=Join-Path $Folder 'target\release\victory.exe'
    [IO.File]::WriteAllBytes($Exe,[Text.Encoding]::UTF8.GetBytes("SYNTHETIC_BINARY_$Candidate"))
    $Hash=(Get-FileHash -LiteralPath $Exe -Algorithm SHA256).Hash.ToLowerInvariant()
    $Lines=SpecLines $Candidate $Hash
    if($Mode -eq 'tamper'){$Lines=@($Lines|ForEach-Object{if($_ -like 'binary_sha256=*'){'binary_sha256='+('0'*64)}else{$_}})}
    if($Mode -eq 'wrong_source'){$Lines=@($Lines|ForEach-Object{if($_ -like 'experiment_patch_commit=*'){'experiment_patch_commit='+('0'*40)}else{$_}})}
    [IO.File]::WriteAllLines((Join-Path $Folder ($Candidate+'-BUILD-MANIFEST.txt')),$Lines,[Text.UTF8Encoding]::new($false))
    if($Mode -eq 'extra'){Set-Content -LiteralPath (Join-Path $Folder 'PRIVATE-title-data.bin') -Value 'SECRET_SHOULD_NOT_BE_READ'}
    $Zip=Join-Path $Root ($Candidate+'-'+$Mode+'.zip')
    [IO.Compression.ZipFile]::CreateFromDirectory($Folder,$Zip)
    return $Zip
}
function Refuse([string]$Candidate,[string]$Zip) {
    $Caught=$false
    try{& $Script -Candidate $Candidate -ArtifactZip $Zip -InstallRoot $Install -ReportRoot $Root|Out-Null}catch{$Caught=$true}
    if(-not $Caught){throw "Unsafe artifact accepted: $Zip"}
}
try {
    foreach($Type in @('E108','E109')){
        $Valid=Make-Zip $Type 'valid'
        $Output=(& $Script -Candidate $Type -ArtifactZip $Valid -InstallRoot $Install -ReportRoot $Root | Out-String)
        if($Output -notmatch 'Installed an isolated CI-only candidate'){throw "Failed valid $Type install"}
        if($Output -notmatch 'Original executable untouched'){throw 'Existing build safety message missing'}
        $Second=(& $Script -Candidate $Type -ArtifactZip $Valid -InstallRoot $Install -ReportRoot $Root | Out-String)
        if($Second -notmatch 'Matching candidate already installed'){throw 'Idempotent install failed'}
        Refuse $Type (Make-Zip $Type 'tamper')
        Refuse $Type (Make-Zip $Type 'wrong_source')
        Refuse $Type (Make-Zip $Type 'extra')
    }
    if(@(Get-ChildItem -LiteralPath $Install -Directory).Count -ne 2){throw 'Unexpected installed candidate count'}
    if(@(Get-ChildItem -LiteralPath $Install -Recurse -File -Filter 'PRIVATE-title-data.bin').Count -ne 0){throw 'Private artifact copied'}
    if(@(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter 'owner-e087-durable-game-run.ps1').Count -ne 0){
        throw 'Install without launch unexpectedly fetched supervisor'
    }
    Write-Host 'E111 WinPS5.1 SYNTHETIC PASS: both approved candidates install, hash tampering and source drift refuse, ZIP member inventory reject, no GPU/title launch'
} finally {
    Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue
}
