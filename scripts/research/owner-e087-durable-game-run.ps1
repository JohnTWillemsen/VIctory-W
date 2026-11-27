#Requires -Version 5.1
# E087: independent monitor + checkpointed anonymous ZIP. Reuses existing exe.
# No process can guarantee a final write through power loss, kernel crash or disk failure.
[CmdletBinding()]
param(
    [ValidateSet('Start','Worker','Recover')][string]$Mode = 'Start',
    [string]$VictoryExe,
    [string]$GameExe,
    [string]$ExpectedSha256,
    [string]$ReportRoot = 'C:\VIctory-Tests',
    [string]$RunFolder,
    [switch]$ScriptedIntro,
    [switch]$Fixture,
    [string]$FixtureScript,
    [switch]$DisableD3D12Debug
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Runner = $MyInvocation.MyCommand.Path
$PrivateFolderName = 'PRIVATE-logs-do-not-upload'
$ZipName = 'E087-anonymous-summary.zip'
function SafeFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Required local executable not found.' }
    return (Resolve-Path -LiteralPath $Path).ProviderPath
}
function AtomicText([string]$Dest, [string[]]$Lines) {
    $Temp = $Dest + '.new'
    [System.IO.File]::WriteAllLines($Temp, $Lines, [System.Text.UTF8Encoding]::new($false))
    if ([System.IO.File]::Exists($Dest)) {
        [System.IO.File]::Replace($Temp, $Dest, ($Dest + '.backup'))
    } else {
        [System.IO.File]::Move($Temp, $Dest)
    }
}
function EmptyCounts {
    return @{lines=0;hung=0;removed=0;slow=0;dred=0;shader=0}
}
function Report([string]$Folder, [string]$Status, [string]$Result, [string]$ExitCode, [string]$GameProcessId, [string]$Elapsed, [hashtable]$Counts) {
    $Pub = Join-Path $Folder 'upload-only'
    New-Item -ItemType Directory -Force -Path $Pub | Out-Null
    $Dest = Join-Path $Pub 'E087-anonymous-status.txt'
    $ConfigPath = Join-Path (Join-Path $Folder $PrivateFolderName) 'local-config.json'
    $Hash = 'UNKNOWN'
    if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
        try { $Hash = (Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json).sha256 } catch { }
    }
    $Lines = @(
        'format=E087-durable-gpu-supervisor-v1',
        ('status=' + $Status),
        ('outcome=' + $Result),
        ('executable_sha256=' + $Hash),
        ('title_exit_code=' + $ExitCode),
        ('game_pid_present=' + [string](-not [string]::IsNullOrEmpty($GameProcessId))),
        ('elapsed_seconds=' + $Elapsed),
        ('heartbeat_utc=' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')),
        ('title_lines_scanned=' + $Counts.lines),
        ('device_hung_marker_lines=' + $Counts.hung),
        ('device_removed_marker_lines=' + $Counts.removed),
        ('slow_submission_marker_lines=' + $Counts.slow),
        ('dred_marker_lines=' + $Counts.dred),
        ('shader_warning_marker_lines=' + $Counts.shader),
        'visual_world_verified=false',
        'no_raw_logs_shaders_title_paths_or_title_assets_in_zip=true'
    )
    AtomicText $Dest $Lines
    $Zip = Join-Path $Folder $ZipName
    $TmpZip = Join-Path $Folder 'E087-anonymous-summary.next.zip'
    try {
        Compress-Archive -LiteralPath $Dest -DestinationPath $TmpZip -Force
        if ([System.IO.File]::Exists($Zip)) {
            [System.IO.File]::Replace($TmpZip, $Zip, ($Zip + '.backup'))
        } else {
            [System.IO.File]::Move($TmpZip, $Zip)
        }
    } catch {
        # The latest atomic text checkpoint or preceding ZIP remains available.
    }
}
function CountPrivateLogs([string]$Folder) {
    $C = EmptyCounts
    $Private = Join-Path $Folder $PrivateFolderName
    foreach ($Filename in @('title-stdout-private.txt','title-stderr-private.txt')) {
        $Path = Join-Path $Private $Filename
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { continue }
        $Reader = $null
        try {
            $Reader = [System.IO.StreamReader]::new($Path)
            while ($null -ne ($Line = $Reader.ReadLine())) {
                $C.lines++
                if ($Line.Contains('0x887A0006')) { $C.hung++ }
                if ($Line.Contains('device removed')) { $C.removed++ }
                if ($Line.Contains('slow host submission')) { $C.slow++ }
                if ($Line.Contains('DRED') -or $Line.Contains('breadcrumb') -or $Line.Contains('page fault')) { $C.dred++ }
                if ($Line.Contains('shader does not translate')) { $C.shader++ }
            }
        } catch { } finally { if ($null -ne $Reader) { $Reader.Dispose() } }
    }
    return $C
}
function NumericPidAlive([string]$ProcessNumber) {
    if ([string]::IsNullOrWhiteSpace($ProcessNumber)) { return $false }
    $Number = 0
    if (-not [int]::TryParse($ProcessNumber, [ref]$Number)) { return $false }
    return ($null -ne (Get-Process -Id $Number -ErrorAction SilentlyContinue))
}
if ($Mode -eq 'Start') {
    $VictoryExe = SafeFile $VictoryExe
    $Hash = (Get-FileHash -LiteralPath $VictoryExe -Algorithm SHA256).Hash.ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($ExpectedSha256) -or $Hash -cne $ExpectedSha256.ToLowerInvariant()) {
        throw 'Executable hash mismatch; nothing launched.'
    }
    if ($Fixture) {
        $FixtureScript = SafeFile $FixtureScript
    } else {
        $GameExe = SafeFile $GameExe
        if (-not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $GameExe) 'appdata0.rpf') -PathType Leaf)) {
            throw 'Local title startup archive not found.'
        }
        $Nvidia = Get-Command 'nvidia-smi.exe' -ErrorAction SilentlyContinue
        if ($null -eq $Nvidia) { throw 'NVIDIA diagnostics utility not found.' }
        $Gpu = (& $Nvidia.Source --query-gpu=name --format=csv,noheader 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $Gpu -notmatch 'RTX 5090') { throw 'RTX5090 not verified; no title launch.' }
        Write-Host 'E087 GPU diagnostic run may reset GPU/driver and modify game saves/cache. Back up saves first.'
    }
    if (-not $Fixture) {
        $Consent = Read-Host 'Type PLAY to launch ONE GPU diagnostic run; anything else cancels'
        if ($Consent -cne 'PLAY') { Write-Host 'Cancelled without launching.'; return }
    }
    $Id = 'E087-supervised-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,6)
    $RunFolder = Join-Path $ReportRoot $Id
    $Private = Join-Path $RunFolder $PrivateFolderName
    New-Item -ItemType Directory -Force -Path $Private | Out-Null
    $Cfg = @{
        victory=$VictoryExe;game=$GameExe;fixture=[bool]$Fixture;fixtureScript=$FixtureScript
        scriptedIntro=[bool]$ScriptedIntro;enableDebug=(-not [bool]$DisableD3D12Debug);sha256=$Hash
    }
    [System.IO.File]::WriteAllText((Join-Path $Private 'local-config.json'),($Cfg | ConvertTo-Json -Compress),[System.Text.UTF8Encoding]::new($false))
    Report $RunFolder 'SUPERVISOR_STARTING' 'PENDING' 'UNKNOWN' '' '0' (EmptyCounts)
    $Shell = Join-Path $PSHOME 'powershell.exe'
    $QRunner = $Runner.Replace("'","''")
    $QFolder = $RunFolder.Replace("'","''")
    $Command = "& '$QRunner' -Mode Worker -RunFolder '$QFolder'"
    $Encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
    try {
        $Worker = Start-Process -FilePath $Shell -ArgumentList ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ' + $Encoded) -WorkingDirectory $RunFolder -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $Private 'monitor-stdout-private.txt') -RedirectStandardError (Join-Path $Private 'monitor-stderr-private.txt')
        [System.IO.File]::WriteAllText((Join-Path $Private 'worker-pid.txt'), [string]$Worker.Id)
        Write-Host ('Independent monitor PID: ' + $Worker.Id)
        Write-Host ('Checkpoint ZIP, refreshed during run: ' + (Join-Path $RunFolder $ZipName))
        Write-Host ('Run folder: ' + $RunFolder)
        Write-Host 'Closing this console leaves the monitor running. Exit/kill the game to finalize its ZIP.'
        Write-Host 'After a PC crash/reboot, use this script with -Mode Recover -RunFolder <run folder>.'
    } catch {
        Report $RunFolder 'SUPERVISOR_START_FAILED' 'FAILED' 'UNKNOWN' '' '0' (EmptyCounts)
        Write-Warning ('Monitor could not start. Initial ZIP retained in ' + $RunFolder)
    }
    return
}
if ($Mode -eq 'Worker') {
    $Private = Join-Path $RunFolder $PrivateFolderName
    $CfgPath = Join-Path $Private 'local-config.json'
    if (-not (Test-Path -LiteralPath $CfgPath -PathType Leaf)) { return }
    $Cfg = Get-Content -LiteralPath $CfgPath -Raw | ConvertFrom-Json
    $Started = [DateTime]::UtcNow
    $PidText = ''
    $Status = 'LAUNCHING'
    $ExitText = 'UNKNOWN'
    $Result = 'PENDING'
    $Old = @{}
    foreach ($Key in @('VICTORY_GAME_DIR','VICTORY_KEYS','VICTORY_D3D12_DRED','VICTORY_D3D12_DEBUG','VICTORY_D3D12_GBV','VICTORY_GPU_TIMING')) {
        $Old[$Key] = [Environment]::GetEnvironmentVariable($Key,'Process')
        [Environment]::SetEnvironmentVariable($Key,$null,'Process')
    }
    try {
        Report $RunFolder $Status $Result $ExitText $PidText '0' (EmptyCounts)
        $Out = Join-Path $Private 'title-stdout-private.txt'
        $Err = Join-Path $Private 'title-stderr-private.txt'
        if ($Cfg.fixture) {
            $Shell = Join-Path $PSHOME 'powershell.exe'
            $ArgumentLine = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $Cfg.fixtureScript + '"'
            $App = Start-Process -FilePath $Shell -ArgumentList $ArgumentLine -PassThru -WorkingDirectory $RunFolder -RedirectStandardOutput $Out -RedirectStandardError $Err
        } else {
            $env:VICTORY_GAME_DIR = Split-Path -Parent $Cfg.game
            $env:VICTORY_D3D12_DRED = '1'
            if ($Cfg.enableDebug) { $env:VICTORY_D3D12_DEBUG = '1' }
            # Per-list timing and GPU-based validation disabled by default, since they change GPU workload.
            if ($Cfg.scriptedIntro) { $env:VICTORY_KEYS = '10:Enter:300,20:Enter:300,200:W:6000' }
            $ArgumentLine = 'run "' + $Cfg.game + '" --execute --console series-x'
            $App = Start-Process -FilePath $Cfg.victory -ArgumentList $ArgumentLine -PassThru -WorkingDirectory (Split-Path -Parent $Cfg.game) -RedirectStandardOutput $Out -RedirectStandardError $Err
        }
        $PidText = [string]$App.Id
        [System.IO.File]::WriteAllText((Join-Path $Private 'game-pid.txt'),$PidText)
        $Status = 'TITLE_RUNNING'
        while (-not $App.WaitForExit(2500)) {
            $Secs = [math]::Floor(([DateTime]::UtcNow - $Started).TotalSeconds)
            Report $RunFolder $Status 'PENDING' 'UNKNOWN' $PidText ([string]$Secs) (EmptyCounts)
        }
        $App.Refresh()
        $ExitText = [string]$App.ExitCode
        $Status = 'TITLE_EXITED'
        if ($App.ExitCode -eq 0) { $Result = 'EXIT_ZERO_NOT_VISUALLY_VERIFIED' }
        else { $Result = 'EXIT_NONZERO_OR_CRASH' }
    } catch {
        $Status = 'SUPERVISOR_EXCEPTION'
        $Result = 'MONITOR_ERROR_OR_LAUNCH_FAILURE'
        ($_ | Out-String) | Set-Content -LiteralPath (Join-Path $Private 'monitor-error-private.txt')
    } finally {
        $Secs = [math]::Floor(([DateTime]::UtcNow - $Started).TotalSeconds)
        Report $RunFolder $Status $Result $ExitText $PidText ([string]$Secs) (CountPrivateLogs $RunFolder)
        foreach ($Key in $Old.Keys) { [Environment]::SetEnvironmentVariable($Key,$Old[$Key],'Process') }
    }
    return
}
if ($Mode -eq 'Recover') {
    if ([string]::IsNullOrWhiteSpace($RunFolder)) { throw 'Recover requires -RunFolder.' }
    $Private = Join-Path $RunFolder $PrivateFolderName
    if (-not (Test-Path -LiteralPath (Join-Path $Private 'local-config.json') -PathType Leaf)) {
        throw 'No local E087 metadata; cannot recover.'
    }
    $Wp = Join-Path $Private 'worker-pid.txt'
    $WorkerPid = if (Test-Path -LiteralPath $Wp) { (Get-Content -LiteralPath $Wp -Raw).Trim() } else { '' }
    if (NumericPidAlive $WorkerPid) {
        Write-Host ('Monitor still running. ZIP: '+(Join-Path $RunFolder $ZipName))
        return
    }
    $Gp = Join-Path $Private 'game-pid.txt'
    $GamePid = if (Test-Path -LiteralPath $Gp) { (Get-Content -LiteralPath $Gp -Raw).Trim() } else { '' }
    if (NumericPidAlive $GamePid) {
        Write-Warning 'Monitor stopped, game still running. Close the game before recovery; checkpoint remains.'
        return
    }
    $Zip = Join-Path $RunFolder $ZipName
    $Current = Join-Path (Join-Path $RunFolder 'upload-only') 'E087-anonymous-status.txt'
    $Existing = if (Test-Path -LiteralPath $Current) { Get-Content -LiteralPath $Current -Raw } else { '' }
    if ($Existing.Contains('status=TITLE_EXITED') -or $Existing.Contains('status=SUPERVISOR_EXCEPTION')) {
        Write-Host ('Already finalized: '+$Zip)
        return
    }
    Report $RunFolder 'RECOVERED_AFTER_MONITOR_STOP' 'EXIT_CODE_UNKNOWN' 'UNKNOWN' $GamePid 'UNKNOWN' (CountPrivateLogs $RunFolder)
    Write-Host ('Recovered anonymous ZIP from local logs: '+$Zip)
    Write-Host 'Exit reason remains unknown after a power loss/monitor crash.'
}
