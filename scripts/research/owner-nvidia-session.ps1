#Requires -Version 5.1
# E127: first NVIDIA-fork gameplay baseline. Public upload is a fixed-field allowlisted ZIP.
# Game files, raw logs, local paths, crash dumps and title-derived data NEVER enter that ZIP.
# Start and Recover require owner interaction; Watch and SelfTest never launch a title.
[CmdletBinding()]
param(
    [ValidateSet('Start','Watch','Recover','SelfTest')][string]$Mode='Start',
    [string]$VictoryExe,
    [string]$GameExe,
    [string]$ExpectedSha256,
    [string]$ReportRoot='C:\VIctory-Tests',
    [string]$RunFolder,
    [ValidateSet('Unknown','Menu','Black','World')][string]$Visual='Unknown',
    [ValidateSet('Unknown','No','Yes')][string]$Controls='Unknown'
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$PrivateName='PRIVATE-never-upload'
$ZipName='E127-anonymous-summary.zip'
$Base=$MyInvocation.MyCommand.Path
function RequiredFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Required file not found locally.' }
    return (Resolve-Path -LiteralPath $Path).ProviderPath
}
function WorkPrivate([string]$Folder) { return (Join-Path $Folder $PrivateName) }
function WorkConfig([string]$Folder) { return (Join-Path (WorkPrivate $Folder) 'session.json') }
function ReadConfig([string]$Folder) {
    $p=WorkConfig $Folder
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw 'Missing E127 private session; check -RunFolder.' }
    return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}
function PutText([string]$File,[string[]]$Lines) {
    $tmp=$File+'.new'
    [IO.File]::WriteAllLines($tmp,$Lines,[Text.UTF8Encoding]::new($false))
    if ([IO.File]::Exists($File)) {
        $bak=$File+'.bak'
        if ([IO.File]::Exists($bak)) { [IO.File]::Delete($bak) }
        [IO.File]::Replace($tmp,$File,$bak)
    } else { [IO.File]::Move($tmp,$File) }
}
function LogSummary([string]$Folder) {
    $counts=@{ files=0; lines=0; host_seen=0; host_5090=0; host_other=0; removed=0; hung=0; fault=0; slow=0; gpu_errors=0; warmup=0 }
    $appHome=Join-Path $Folder 'home'
    $paths=@()
    $logs=Join-Path $appHome 'logs'
    if (Test-Path -LiteralPath $logs -PathType Container) {
        $paths+=@(Get-ChildItem -LiteralPath $logs -File -Filter '*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 6 -ExpandProperty FullName)
    }
    $crashes=Join-Path $appHome 'data\7952987A\crashes.log'
    if (Test-Path -LiteralPath $crashes -PathType Leaf) { $paths+=@($crashes) }
    $temp=Join-Path $appHome 'data\7952987A\temp'
    if (Test-Path -LiteralPath $temp -PathType Container) {
        $paths+=@(Get-ChildItem -LiteralPath $temp -File -Filter '*.crash.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 2 -ExpandProperty FullName)
    }
    foreach ($p in @($paths | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $counts.files++
        try {
            # Only a bounded tail is parsed locally. No original line ever enters the ZIP.
            foreach ($line in @(Get-Content -LiteralPath $p -Tail 3500 -ErrorAction Stop)) {
                $counts.lines++
                if ($line -match 'host device on the card with the most memory') {
                    $counts.host_seen++
                    if ($line -match 'adapter\s*=\s*"?[^"\r\n]*RTX\s*5090') { $counts.host_5090++ }
                    elseif ($line -match 'adapter\s*=') { $counts.host_other++ }
                }
                if ($line -match '(?i)(device removed|0x887A0005|DXGI_ERROR_DEVICE_REMOVED)') { $counts.removed++ }
                if ($line -match '(?i)(0x887A0006|DXGI_ERROR_DEVICE_HUNG)') { $counts.hung++ }
                if ($line -match '(?i)(page fault|DRED|breadcrumb)') { $counts.fault++ }
                if ($line -match '(?i)slow host submission') { $counts.slow++ }
                if ($line -match '(?i)(host GPU failure|failed to allocate upload buffer)') { $counts.gpu_errors++ }
                if ($line -match '(?i)(warm.up restart|warming up|restarting after warmup)') { $counts.warmup++ }
            }
        } catch { }
    }
    return $counts
}
function PublicReport([string]$Folder,[string]$State,[string]$ExitCode,[string]$VisualCode,[string]$ControlsCode) {
    $cfg=ReadConfig $Folder
    $summary=LogSummary $Folder
    $pub=Join-Path $Folder 'UPLOAD-ONLY'
    New-Item -ItemType Directory -Force -Path $pub | Out-Null
    $elapsed=[math]::Max(0,[math]::Floor(([DateTime]::UtcNow - [DateTime]::Parse($cfg.started_utc)).TotalSeconds))
    $gpu='UNKNOWN'
    if ($summary.host_5090 -gt 0) { $gpu='HOST_RTX5090_NAME_MATCH' }
    elseif ($summary.host_other -gt 0) { $gpu='OTHER_HOST_ADAPTER_REPORTED' }
    $statusFile=Join-Path $pub 'E127-fixed-fields.txt'
    $lines=@(
        'format=E127-nvidia-session-v1',
        'source_repository=trustno1-coder/VIctory-NVIDIA',
        'source_release=v2026.11.27.8',
        'source_commit=64d4931b3dd90305134512b805fc98f04119fb6e',
        ('source_executable_sha256='+$cfg.executable_sha256),
        ('run_id='+$cfg.run_id),
        ('state='+$State),
        ('exit_code='+$ExitCode),
        ('elapsed_seconds='+$elapsed),
        ('checkpoint_utc='+[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')),
        'launcher=builtin_play',
        'console_profile=SOURCE_DEFAULT',
        'd3d12_debug_layer=OFF',
        'native_bvh_builder=OFF',
        'frame_generation=SOURCE_DEFAULT',
        'expected_host_gpu_name=RTX5090',
        ('observed_host_gpu='+$gpu),
        ('host_adapter_event_count='+$summary.host_seen),
        ('host_adapter_5090_name_match_count='+$summary.host_5090),
        ('host_adapter_other_event_count='+$summary.host_other),
        ('log_files_scanned='+$summary.files),
        ('log_lines_scanned='+$summary.lines),
        ('device_removed_marker_count='+$summary.removed),
        ('device_hung_marker_count='+$summary.hung),
        ('dred_or_pagefault_marker_count='+$summary.fault),
        ('slow_host_submission_marker_count='+$summary.slow),
        ('host_gpu_failure_marker_count='+$summary.gpu_errors),
        ('warmup_text_marker_count='+$summary.warmup),
        ('human_observed_visual='+$VisualCode),
        ('human_observed_controls='+$ControlsCode),
        'no_private_logs_paths_assets_or_dumps=true'
    )
    PutText $statusFile $lines
    $zip=Join-Path $Folder $ZipName
    $tmp=Join-Path $Folder 'E127-anonymous-next.zip'
    try {
        Compress-Archive -LiteralPath $statusFile -DestinationPath $tmp -Force -ErrorAction Stop
        if ([IO.File]::Exists($zip)) {
            $bak=$zip+'.bak'
            if ([IO.File]::Exists($bak)) { [IO.File]::Delete($bak) }
            [IO.File]::Replace($tmp,$zip,$bak)
        } else { [IO.File]::Move($tmp,$zip) }
    } catch {
        # The preceding ZIP or the atomic fixed-fields text is preserved on failure.
    }
}
function Answer([string]$Message,[string[]]$Choices,[string]$Default) {
    $response=(Read-Host $Message).Trim().ToLowerInvariant()
    for($i=0;$i -lt $Choices.Count;$i++) {
        if ($response -ceq $Choices[$i].ToLowerInvariant()) { return $Choices[$i] }
    }
    return $Default
}
if ($Mode -eq 'SelfTest') {
    $root=Join-Path $env:TEMP ('E127-fixture-'+[Guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Force -Path (WorkPrivate $root),(Join-Path $root 'home\logs') | Out-Null
    $cfg=@{ executable_sha256=('a'*64);run_id='synthetic123';started_utc=[DateTime]::UtcNow.AddSeconds(-12).ToString('o') }
    [IO.File]::WriteAllText((WorkConfig $root),($cfg|ConvertTo-Json -Compress))
    $log=Join-Path $root 'home\logs\victory-nvidia-play-synthetic.log'
    [IO.File]::WriteAllLines($log,@(
        'private user path C:\\private\\title\\never-upload.rpf',
        '2026-11-27 INFO victory_gpu::host: host device on the card with the most memory of its own adapter="NVIDIA GeForce RTX 5090" own_memory_mb=32768',
        'ERROR victory_gpu::host: host GPU failure device removed 0x887A0005'
    ))
    PublicReport $root 'SELFTEST' 'UNKNOWN' 'World' 'Yes'
    $zip=Join-Path $root $ZipName
    if (-not (Test-Path -LiteralPath $zip -PathType Leaf)) { throw 'Selftest ZIP absent' }
    $testdir=Join-Path $root 'opened'
    Expand-Archive -LiteralPath $zip -DestinationPath $testdir
    $report=Get-Content -LiteralPath (Join-Path $testdir 'E127-fixed-fields.txt') -Raw
    if (-not $report.Contains('observed_host_gpu=HOST_RTX5090_NAME_MATCH')) { throw 'Host GPU parser did not match' }
    if (-not $report.Contains('device_removed_marker_count=1')) { throw 'Device removed parser did not match' }
    if ($report.Contains('C:\\private') -or $report.Contains('never-upload.rpf') -or $report.Contains($root)) { throw 'Private log data leaked' }
    if (-not $report.Contains('human_observed_visual=World')) { throw 'Visual enum absent' }
    Write-Host 'E127 synthetic fixed-field privacy, D3D12 host adapter and crash parsers PASS; no game launched'
    Remove-Item -LiteralPath $root -Recurse -Force
    exit 0
}
if ($Mode -eq 'Start') {
    $VictoryExe=RequiredFile $VictoryExe
    $GameExe=RequiredFile $GameExe
    if (-not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $GameExe) 'appdata0.rpf') -PathType Leaf)) {
        throw 'Local title startup archive missing; nothing launched.'
    }
    $sha=(Get-FileHash -LiteralPath $VictoryExe -Algorithm SHA256).Hash.ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($ExpectedSha256) -or $sha -cne $ExpectedSha256.ToLowerInvariant()) {
        throw 'Source executable SHA256 does not match the selected known build; nothing launched.'
    }
    $nvidia=Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    if ($null -eq $nvidia) { throw 'NVIDIA preflight unavailable; nothing launched.' }
    $names=(& $nvidia.Source --query-gpu=name --format=csv,noheader 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0 -or $names -notmatch 'RTX\s*5090') { throw 'RTX5090 presence check failed; nothing launched.' }
    $id='e127-'+[DateTime]::UtcNow.ToString('yyyyMMddHHmmss')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,6)
    $RunFolder=Join-Path $ReportRoot $id
    New-Item -ItemType Directory -Force -Path (WorkPrivate $RunFolder),(Join-Path $RunFolder 'home') | Out-Null
    $cfg=@{
        victory_exe=$VictoryExe;game_exe=$GameExe
        executable_sha256=$sha;started_utc=[DateTime]::UtcNow.ToString('o')
        run_id=$id
    }
    [IO.File]::WriteAllText((WorkConfig $RunFolder),($cfg|ConvertTo-Json -Compress),[Text.UTF8Encoding]::new($false))
    PublicReport $RunFolder 'READY' 'UNKNOWN' 'Unknown' 'Unknown'
    Write-Host ('One ZIP from this session, even after a crash: '+(Join-Path $RunFolder $ZipName))
    Write-Host ('Private-only logs and settings: '+(Join-Path $RunFolder 'home'))
    Write-Host 'This may reset the graphics driver or crash/reboot the PC. Back up game saves beforehand.'
    Write-Host 'This test uses an isolated VICTORY_HOME, forces RTX 5090 by name, and leaves native BVH off.'
    Write-Host 'On first launch, the NVIDIA program may offer optional DLL downloads and restart itself once to warm up.'
    $consent=Read-Host 'Type PLAY to launch; anything else keeps the initial anonymous ZIP and cancels'
    if ($consent -cne 'PLAY') { Write-Host 'Cancelled without launching'; return }
    $shell=Join-Path $PSHOME 'powershell.exe'
    $command="& '"+$Base.Replace("'","''")+"' -Mode Watch -RunFolder '"+$RunFolder.Replace("'","''")+"'"
    $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    try {
        $worker=Start-Process -FilePath $shell -ArgumentList ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand '+$encoded) -WindowStyle Hidden -PassThru
        [IO.File]::WriteAllText((Join-Path (WorkPrivate $RunFolder) 'watch-pid.txt'),[string]$worker.Id)
    } catch { Write-Warning 'Independent monitor did not start; initial ZIP retained, recover after title exit.' }
    $oldHome=$env:VICTORY_HOME
    $oldAdapter=$env:VICTORY_ADAPTER
    $oldDebug=$env:VICTORY_D3D12_DEBUG
    $oldBvh=$env:VICTORY_BVH_BUILDER
    $oldKeys=$env:VICTORY_KEYS
    $exit='UNKNOWN'
    try {
        $env:VICTORY_HOME=Join-Path $RunFolder 'home'
        $env:VICTORY_ADAPTER='RTX 5090'
        Remove-Item Env:VICTORY_D3D12_DEBUG -ErrorAction SilentlyContinue
        Remove-Item Env:VICTORY_BVH_BUILDER -ErrorAction SilentlyContinue
        Remove-Item Env:VICTORY_KEYS -ErrorAction SilentlyContinue
        Write-Host 'Starting the upstream built-in play launcher now; respond to any visible NVIDIA SDK prompt yourself.'
        & $VictoryExe play $GameExe
        if ($null -ne $LASTEXITCODE) { $exit=[string]$LASTEXITCODE }
    } catch {
        ($_|Out-String) | Set-Content -LiteralPath (Join-Path (WorkPrivate $RunFolder) 'private-launch-exception.txt')
    } finally {
        $env:VICTORY_HOME=$oldHome
        $env:VICTORY_ADAPTER=$oldAdapter
        $env:VICTORY_D3D12_DEBUG=$oldDebug
        $env:VICTORY_BVH_BUILDER=$oldBvh
        $env:VICTORY_KEYS=$oldKeys
        [IO.File]::WriteAllText((Join-Path (WorkPrivate $RunFolder) 'exit.txt'),$exit)
    }
    Write-Host 'If the game restarted itself for warm-up, let the second game finish before answering.'
    $observed=Answer 'Visual seen? [Unknown / Menu / Black / World]' @('Unknown','Menu','Black','World') 'Unknown'
    $moved=Answer 'Could you control or move in the 3D world? [Unknown / No / Yes]' @('Unknown','No','Yes') 'Unknown'
    PutText (Join-Path (WorkPrivate $RunFolder) 'observation.txt') @($observed,$moved)
    [IO.File]::WriteAllText((Join-Path (WorkPrivate $RunFolder) 'finished.flag'),'finished')
    Start-Sleep -Seconds 3
    Write-Host ('UPLOAD ONLY: '+(Join-Path $RunFolder $ZipName))
    return
}
if ($Mode -eq 'Watch') {
    $cfg=ReadConfig $RunFolder
    $stopFile=Join-Path (WorkPrivate $RunFolder) 'finished.flag'
    $end=[DateTime]::UtcNow.AddHours(3)
    do {
        $state=if (Test-Path -LiteralPath $stopFile) { 'FINALIZED' } else { 'RUNNING' }
        $exitFile=Join-Path (WorkPrivate $RunFolder) 'exit.txt'
        $exit=if (Test-Path -LiteralPath $exitFile) { (Get-Content -LiteralPath $exitFile -Raw).Trim() } else { 'UNKNOWN' }
        $obsFile=Join-Path (WorkPrivate $RunFolder) 'observation.txt'
        $visual='Unknown';$controls='Unknown'
        if (Test-Path -LiteralPath $obsFile) {
            $obs=@(Get-Content -LiteralPath $obsFile)
            if ($obs.Count -gt 0 -and $obs[0] -in @('Unknown','Menu','Black','World')) { $visual=$obs[0] }
            if ($obs.Count -gt 1 -and $obs[1] -in @('Unknown','No','Yes')) { $controls=$obs[1] }
        }
        PublicReport $RunFolder $state $exit $visual $controls
        if ($state -eq 'FINALIZED') { break }
        Start-Sleep -Seconds 5
    } while ([DateTime]::UtcNow -lt $end)
    return
}
if ($Mode -eq 'Recover') {
    if ([string]::IsNullOrWhiteSpace($RunFolder)) { throw 'Recover needs -RunFolder.' }
    $cfg=ReadConfig $RunFolder
    $wp=Join-Path (WorkPrivate $RunFolder) 'watch-pid.txt'
    if (Test-Path -LiteralPath $wp) {
        $id=0;$value=(Get-Content -LiteralPath $wp -Raw).Trim()
        if ([int]::TryParse($value,[ref]$id) -and (Get-Process -Id $id -ErrorAction SilentlyContinue)) {
            Write-Host 'Independent monitor is still writing the current ZIP; no recovery needed.'
            return
        }
    }
    $exitFile=Join-Path (WorkPrivate $RunFolder) 'exit.txt'
    $exit=if (Test-Path -LiteralPath $exitFile) { (Get-Content -LiteralPath $exitFile -Raw).Trim() } else { 'UNKNOWN' }
    if ($Visual -notin @('Unknown','Menu','Black','World')) { $Visual='Unknown' }
    if ($Controls -notin @('Unknown','No','Yes')) { $Controls='Unknown' }
    PublicReport $RunFolder 'RECOVERED' $exit $Visual $Controls
    Write-Host ('UPLOAD ONLY: '+(Join-Path $RunFolder $ZipName))
    Write-Host 'Exit reason is UNKNOWN if Windows rebooted before the launcher wrote exit.txt.'
    return
}
throw 'Unexpected mode'
