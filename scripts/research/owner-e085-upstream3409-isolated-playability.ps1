#Requires -Version 5.1
# E085: isolated test of pinned public-source PR3409. Do not overwrite older builds.
# Raw logs stay on owner's PC; only predefined numeric counters enter summary ZIP.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$GameExe,
    [string]$ReportRoot='C:\VIctory-Tests',
    [switch]$BuildOnly,
    [switch]$ScriptedIntro
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$Pin='1e25b230d6572f08e718a1df31a619bb43070481'
$Run='E085-upstream3409-playability-'+(Get-Date -Format 'yyyyMMdd-HHmmss')
$Root=Join-Path $ReportRoot $Run
$Source=Join-Path $Root 'PUBLIC-upstream-source'
$Target=Join-Path $Root 'PUBLIC-isolated-build'
$Private=Join-Path $Root 'PRIVATE-raw-logs-do-not-upload'
$Public=Join-Path $Root 'upload-only'
$Zip=Join-Path $ReportRoot ($Run+'-summary.zip')
$Candidate=Join-Path $Target 'release\victory.exe'
$Status='NOT_STARTED'
$BuildExit='NOT_RUN'
$TitleExit='NOT_RUN'
$BinaryHash='NOT_BUILT'
$Scanned=[uint64]0
$ShaderWarnings=[uint64]0
$RemovedHints=[uint64]0
$BuilderLogs=[uint64]0
$EnvKeys=@('CARGO_TARGET_DIR','VICTORY_GAME_DIR','VICTORY_KEYS',
    'VICTORY_ADAPTER','VICTORY_D3D12_WARP','VICTORY_WARP',
    'VICTORY_D3D12_DEBUG','VICTORY_D3D12_GBV',
    'VICTORY_CAPTURE','VICTORY_CAPTURE_WORLD','VICTORY_DUMP_TARGETS',
    'VICTORY_CRASH_SAVE','VICTORY_XMA_DUMP','VICTORY_PIPELINE_LOG',
    'VICTORY_SKIP_PIPELINES','VICTORY_SKIP_WAVE64',
    'VICTORY_BVH_REFUSAL_COUNTS','VICTORY_BVH_TRANSLATION_REASONS')
$Before=@{}
foreach($Key in $EnvKeys){
    $Before[$Key]=[Environment]::GetEnvironmentVariable($Key,'Process')
}
try {
    New-Item -ItemType Directory -Force -Path $ReportRoot,$Root,$Private,$Public | Out-Null
    $Status='PREFLIGHT'
    if(-not (Test-Path -LiteralPath $GameExe -PathType Leaf)){
        throw 'The existing local game executable was not found.'
    }
    $GameExe=(Resolve-Path -LiteralPath $GameExe).ProviderPath
    $GameDir=Split-Path -Parent $GameExe
    if(-not (Test-Path -LiteralPath (Join-Path $GameDir 'appdata0.rpf') -PathType Leaf)){
        throw 'Local startup archive missing beside game executable.'
    }
    foreach($Tool in @('git.exe','cargo.exe','rustc.exe','nvidia-smi.exe')){
        if(-not (Get-Command $Tool -ErrorAction SilentlyContinue)){
            throw ('Required local tool missing: '+$Tool)
        }
    }
    $Gpu=(& nvidia-smi.exe --query-gpu=name --format=csv,noheader 2>&1 | Out-String).Trim()
    if($LASTEXITCODE -ne 0 -or $Gpu -notmatch 'RTX 5090'){
        throw 'RTX5090 physical GPU not verified; refusing game launch.'
    }
    $Status='SOURCE_FETCH'
    Write-Host 'E085: cloning upstream public code into a NEW isolated folder.'
    & git.exe clone --quiet --no-tags 'https://github.com/Marvisak/VIctory.git' $Source
    if($LASTEXITCODE -ne 0){throw 'Public Git clone failed.'}
    & git.exe -C $Source fetch --quiet --no-tags origin refs/pull/3409/head
    if($LASTEXITCODE -ne 0){throw 'Upstream PR3409 fetch failed.'}
    $Got=(& git.exe -C $Source rev-parse FETCH_HEAD | Out-String).Trim()
    if($LASTEXITCODE -ne 0 -or $Got -cne $Pin){
        throw 'Upstream PR3409 has changed; fail closed rather than build unreviewed code.'
    }
    & git.exe -C $Source checkout --quiet --detach $Pin
    if($LASTEXITCODE -ne 0){throw 'Pinned Git checkout failed.'}
    $Head=(& git.exe -C $Source rev-parse HEAD | Out-String).Trim()
    if($LASTEXITCODE -ne 0 -or $Head -cne $Pin){throw 'Pinned source HEAD mismatch.'}
    $Dirty=(& git.exe -C $Source status --porcelain=v1 | Out-String).Trim()
    if($LASTEXITCODE -ne 0 -or $Dirty){throw 'Unexpected dirty source tree.'}
    foreach($Key in $EnvKeys){
        [Environment]::SetEnvironmentVariable($Key,$null,'Process')
    }
    $env:CARGO_TARGET_DIR=$Target
    $Status='BUILDING'
    Write-Host 'Compiling pinned upstream with diagnostics input, separate Cargo target.'
    Write-Host 'This does not modify your E075 binary or title directory.'
    $BuildOut=Join-Path $Private 'build-stdout-private.txt'
    $BuildErr=Join-Path $Private 'build-stderr-private.txt'
    $Cargo=(Get-Command cargo.exe).Source
    $Build=Start-Process -FilePath $Cargo -ArgumentList 'build --release --locked -p victory --features diagnostics' -WorkingDirectory $Source -PassThru -Wait -NoNewWindow -RedirectStandardOutput $BuildOut -RedirectStandardError $BuildErr
    $BuildExit=[string]$Build.ExitCode
    if($Build.ExitCode -ne 0){throw 'Public-source build failed: see LOCAL PRIVATE build logs.'}
    if(-not (Test-Path -LiteralPath $Candidate -PathType Leaf)){
        throw 'Cargo reported success but isolated victory.exe was not found.'
    }
    $BinaryHash=(Get-FileHash -LiteralPath $Candidate -Algorithm SHA256).Hash.ToLowerInvariant()
    $Status='BUILD_PASS_TITLE_NOT_RUN'
    Write-Host ('Isolated public-source executable SHA256: '+$BinaryHash)
    if(-not $BuildOnly){
        Write-Host 'Other NVIDIA owners reported reaching the world; RTX5090 still unverified.'
        Write-Host 'Title run can hang/reset the driver or modify game caches/saves.'
        Write-Host 'Close GPU-heavy apps and back up any important title saves first.'
        Write-Host 'Physical gamepad works. Keyboard fallback: Enter=A, Esc=Menu, WASD=stick.'
        if($ScriptedIntro){
            Write-Host 'Intro script will press Enter at 10s/20s, then W for 6s at 200s.'
        }
        $Consent=Read-Host 'Type PLAY in uppercase to launch once; other input skips'
        if($Consent -cne 'PLAY'){
            $Status='BUILD_PASS_OWNER_DECLINED_PLAY'
        }else{
            $env:VICTORY_GAME_DIR=$GameDir
            if($ScriptedIntro){
                $env:VICTORY_KEYS='10:Enter:300,20:Enter:300,200:W:6000'
            }
            $Out=Join-Path $Private 'title-stdout-private.txt'
            $Err=Join-Path $Private 'title-stderr-private.txt'
            $Args='run "'+$GameExe+'" --execute --console series-x'
            $Status='TITLE_LAUNCHING'
            $Title=Start-Process -FilePath $Candidate -ArgumentList $Args -WorkingDirectory $GameDir -PassThru -RedirectStandardOutput $Out -RedirectStandardError $Err
            $Status='TITLE_RUNNING'
            Write-Host 'Title running. See if you can enter the world and control the character.'
            do {
                $null=Read-Host 'After game EXITED (or you closed in Task Manager), press ENTER'
                $Title.Refresh()
                if(-not $Title.HasExited){
                    Write-Warning 'Title is still running. Close normally or in Task Manager first.'
                }
            } while(-not $Title.HasExited)
            $TitleExit=[string]$Title.ExitCode
            $Status='TITLE_EXITED'
            foreach($File in @($Out,$Err)){
                if(-not (Test-Path -LiteralPath $File -PathType Leaf)){continue}
                $Reader=New-Object System.IO.StreamReader($File)
                try {
                    while($null -ne ($Line=$Reader.ReadLine())){
                        $Scanned++
                        if($Line.Contains("shader does not translate; its pipelines' draws are dropped")){
                            $ShaderWarnings++
                        }
                        if($Line.Contains('device removed') -or $Line.Contains('DXGI_ERROR_DEVICE_REMOVED') -or $Line.Contains('0x887A0005')){
                            $RemovedHints++
                        }
                        if($Line.Contains('BVH builder ') -and $Line.Contains('refused=')){
                            $BuilderLogs++
                        }
                    }
                }finally{$Reader.Dispose()}
            }
            Write-Host 'Tell ChatGPT if the world rendered, whether you could walk, and approximate FPS.'
        }
    }
}catch{
    if($Status -eq 'BUILDING'){$Status='BUILD_FAILED'}
    else{$Status='PREFLIGHT_OR_RUN_FAILED'}
    if(-not (Test-Path -LiteralPath $Private -PathType Container)){
        New-Item -ItemType Directory -Force -Path $Private | Out-Null
    }
    ($_ | Out-String) | Set-Content -LiteralPath (Join-Path $Private 'private-error.txt') -Encoding UTF8
    Write-Warning ('E085 stopped. Local private logs have details. Status='+$Status)
}finally{
    foreach($Key in $EnvKeys){
        [Environment]::SetEnvironmentVariable($Key,$Before[$Key],'Process')
    }
    New-Item -ItemType Directory -Force -Path $Public | Out-Null
    @(
        'format=E085-anonymous-upstream-comparison-v1',
        'status='+$Status,
        'pinned_public_source='+$Pin,
        'built_candidate_sha256='+$BinaryHash,
        'build_exit='+$BuildExit,
        'title_exit='+$TitleExit,
        'title_log_lines_scanned='+$Scanned,
        'shader_translation_warning_lines='+$ShaderWarnings,
        'device_removed_hint_lines='+$RemovedHints,
        'bvh_builder_status_lines='+$BuilderLogs,
        'scripted_intro_requested='+[string][bool]$ScriptedIntro,
        'game_and_gpu_result_unverified_until_owner_report=true',
        'raw_game_logs_paths_and_shader_ids_not_uploaded=true'
    ) | Set-Content -LiteralPath (Join-Path $Public 'E085-anonymous-result.txt') -Encoding UTF8
    try{
        Compress-Archive -Path (Join-Path $Public '*') -DestinationPath $Zip -Force -ErrorAction Stop
        Write-Host ('UPLOAD ONLY THIS NUMERIC SUMMARY ZIP PRIVATELY: '+$Zip)
        Write-Host 'Do not upload game files, private logs or a title binary to GitHub.'
    }catch{Write-Warning 'ZIP creation failed; do not upload raw private files.'}
}
