#Requires -Version 5.1
# VW-092: offline numeric-only audit of E164 opt-in host-pipeline waits.
# Reads only existing E127 PRIVATE logs; NEVER runs a game or changes caches.
# Only the single-member anonymous ZIP is shareable.
[CmdletBinding()]
param(
    [ValidateSet('Audit','SelfTest')][string]$Mode='Audit',
    [string]$RunId='',
    [string]$ReportRoot='C:\VIctory-NVIDIA-Tests'
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$Culture=[Globalization.CultureInfo]::InvariantCulture
$ZipName='VW092-anonymous-wait-summary.zip'
$Anchor='opt-in host pipeline waits in the last meter window (title threads; not GPU time)'

function Decimal([string]$Value) {
    return [double]::Parse($Value,[Globalization.NumberStyles]::Float,$Culture)
}
function FormatNumber([double]$Value) {
    return $Value.ToString('0.000',$Culture)
}
function P50([double[]]$Values) {
    if ($null -eq $Values -or $Values.Count -eq 0) { return 'UNKNOWN' }
    $sorted=@($Values | Sort-Object)
    $mid=($sorted.Count-1)/2.0
    $lo=[int][math]::Floor($mid)
    $hi=[int][math]::Ceiling($mid)
    return (FormatNumber (([double]$sorted[$lo]+[double]$sorted[$hi])/2.0))
}
function AuditLogs([string]$LogDir) {
    $all=New-Object 'System.Collections.Generic.List[object]'
    $scene=New-Object 'System.Collections.Generic.List[object]'
    $slow=New-Object 'System.Collections.Generic.List[object]'
    $fast=New-Object 'System.Collections.Generic.List[object]'
    $seen=0; $lines=0; $skipped=0; $unpaired=0
    $files=@()
    if (Test-Path -LiteralPath $LogDir -PathType Container) {
        $files=@(Get-ChildItem -LiteralPath $LogDir -File -Filter '*.log' |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 6)
    }
    foreach ($file in $files) {
        if ($file.Length -gt 268435456) { $skipped++; continue }
        $seen++
        $pending=$null
        $age=0
        $read=0
        $stream=$null
        $reader=$null
        try {
            $stream=New-Object IO.FileStream($file.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
            $reader=New-Object IO.StreamReader($stream)
            while ($read -lt 250000 -and $null -ne ($line=$reader.ReadLine())) {
                $read++; $lines++
                # This is exactly the existing victory-gpu 5s FPS meter anchor.
                # Retain only numeric fields, never the line or filename.
                $m=[regex]::Match($line,'(?<!\w)(?<fps>\d{1,4}(?:\.\d{1,3})?) fps,\s*(?<ms>\d{1,6}(?:\.\d{1,3})?) ms/frame \(')
                if ($m.Success) {
                    $fps=Decimal $m.Groups['fps'].Value
                    $draw=[regex]::Match($line,'(?<draw>\d{1,7}(?:\.\d{1,2})?) draws/frame')
                    $pending=$null
                    if ($fps -gt 0 -and $fps -le 1000 -and $draw.Success) {
                        $drawCount=Decimal $draw.Groups['draw'].Value
                        $pending=@{ fps=$fps; scene=($drawCount -ge 100) }
                        $age=0
                    }
                    continue
                }
                if ($null -eq $pending) {
                    if ($line.Contains($Anchor)) { $unpaired++ }
                    continue
                }
                $age++
                if ($age -gt 4) {
                    $pending=$null
                    if ($line.Contains($Anchor)) { $unpaired++ }
                    continue
                }
                if (-not $line.Contains($Anchor)) { continue }
                $calls=[regex]::Match($line,'(?<!\w)calls=(?<v>\d{1,8})(?!\d)')
                $wait=[regex]::Match($line,'(?<!\w)summed_wait_ms=(?<v>\d{1,9}(?:\.\d{1,6})?)(?![\d.])')
                if (-not $calls.Success -or -not $wait.Success) {
                    $unpaired++; $pending=$null; continue
                }
                $c=Decimal $calls.Groups['v'].Value
                $w=Decimal $wait.Groups['v'].Value
                if ($c -gt 10000000 -or $w -gt 10000000) {
                    $unpaired++; $pending=$null; continue
                }
                $item=@{ calls=$c; wait=$w }
                $all.Add($item)
                if ($pending.scene) {
                    $scene.Add($item)
                    if ($pending.fps -le 10) { $slow.Add($item) }
                    elseif ($pending.fps -ge 20) { $fast.Add($item) }
                }
                $pending=$null
            }
            if ($read -ge 250000 -and -not $reader.EndOfStream) { $skipped++ }
        }
        finally {
            if ($null -ne $reader) { $reader.Dispose() }
            elseif ($null -ne $stream) { $stream.Dispose() }
        }
    }
    return @{
        files=$seen; lines=$lines; skipped=$skipped; unpaired=$unpaired
        all=$all.ToArray(); scene=$scene.ToArray()
        slow=$slow.ToArray(); fast=$fast.ToArray()
    }
}
function Metric([object[]]$Items,[string]$Field) {
    $values=New-Object 'System.Collections.Generic.List[double]'
    foreach ($item in $Items) { $values.Add([double]$item[$Field]) }
    return (P50 $values.ToArray())
}
function MakeReport([string]$RunFolder,[string]$Session,[string]$OutputDir) {
    $s=AuditLogs (Join-Path $RunFolder 'home\logs')
    $status=if ($s.all.Count -gt 0) { 'NUMERIC_WAIT_WINDOWS_FOUND' } else { 'NO_MATCHED_WAIT_WINDOWS' }
    $fields=@(
        'format=VW092-nvidia-wait-audit-v1',
        ('source_run_id='+$Session),
        ('status='+$status),
        'source=existing_private_logs',
        'game_relaunched=false',
        'runtime_default_wait_probe=OFF',
        ('log_files_scanned='+$s.files),
        ('log_lines_scanned='+$s.lines),
        ('log_files_skipped_or_truncated='+$s.skipped),
        ('wait_lines_unpaired_or_invalid='+$s.unpaired),
        ('paired_wait_window_count='+$s.all.Count),
        ('scene_like_wait_window_count='+$s.scene.Count),
        ('slow_scene_like_wait_window_count='+$s.slow.Count),
        ('fast_scene_like_wait_window_count='+$s.fast.Count),
        ('all_wait_calls_p50='+(Metric $s.all 'calls')),
        ('all_summed_wait_ms_p50='+(Metric $s.all 'wait')),
        ('scene_like_wait_calls_p50='+(Metric $s.scene 'calls')),
        ('scene_like_summed_wait_ms_p50='+(Metric $s.scene 'wait')),
        ('slow_scene_like_wait_calls_p50='+(Metric $s.slow 'calls')),
        ('slow_scene_like_summed_wait_ms_p50='+(Metric $s.slow 'wait')),
        ('fast_scene_like_wait_calls_p50='+(Metric $s.fast 'calls')),
        ('fast_scene_like_summed_wait_ms_p50='+(Metric $s.fast 'wait')),
        'scene_like_heuristic=draws_per_frame_gte_100',
        'slow_fps_threshold=lte_10',
        'fast_fps_threshold=gte_20',
        'stats_scope=multi_second_meter_windows_not_frames',
        'wait_sum=across_threads_not_wall_time_or_gpu_time',
        'paired_line_gap_max=4',
        'no_causal_pipeline_stall_claim=true',
        'raw_logs_paths_assets_or_dumps_included=false'
    )
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    $txt=Join-Path $OutputDir 'VW092-fixed-fields.txt'
    $zip=Join-Path $OutputDir $ZipName
    [IO.File]::WriteAllLines($txt,$fields,[Text.UTF8Encoding]::new($false))
    Compress-Archive -LiteralPath $txt -DestinationPath $zip -Force
    return $zip
}
if ($Mode -eq 'SelfTest') {
    $root=Join-Path $env:TEMP ('VW092-synthetic-'+[guid]::NewGuid().ToString('N').Substring(0,10))
    try {
        $log=Join-Path $root 'run\home\logs'
        New-Item -ItemType Directory -Path $log -Force | Out-Null
        [IO.File]::WriteAllLines((Join-Path $log 'fixture.log'),@(
            'PRIVATE C:\secret\never-upload-title.rpf',
            'INFO victory_gpu::host: 5.0 fps, 200.0 ms/frame (50.0 preparing:), 300 draws/frame',
            'INFO victory_gpu::host: opt-in host pipeline waits in the last meter window (title threads; not GPU time) calls=2 summed_wait_ms=750.0 PRIVATE C:\secret',
            'INFO victory_gpu::host: 30.0 fps, 33.3 ms/frame (15.0 preparing:), 400 draws/frame',
            'INFO victory_gpu::host: opt-in host pipeline waits in the last meter window (title threads; not GPU time) calls=0 summed_wait_ms=0.0',
            'INFO victory_gpu::host: 15.0 fps, 66.7 ms/frame (20.0 preparing:), 50 draws/frame',
            'INFO victory_gpu::host: opt-in host pipeline waits in the last meter window (title threads; not GPU time) calls=7 summed_wait_ms=350.0',
            'INFO victory_gpu::host: opt-in host pipeline waits in the last meter window (title threads; not GPU time) calls=2 summed_wait_ms=1.0'
        ))
        $out=Join-Path $root 'public'
        $zip=MakeReport (Join-Path $root 'run') 'e127-20261128043635-abc825' $out
        $expanded=Join-Path $root 'expanded'
        Expand-Archive -LiteralPath $zip -DestinationPath $expanded
        $members=@(Get-ChildItem -LiteralPath $expanded -File)
        if ($members.Count -ne 1 -or $members[0].Name -cne 'VW092-fixed-fields.txt') {
            throw 'Anonymous ZIP contains unexpected files'
        }
        $public=[IO.File]::ReadAllText($members[0].FullName)
        foreach ($expected in @('paired_wait_window_count=3','scene_like_wait_window_count=2',
                'slow_scene_like_wait_window_count=1','fast_scene_like_wait_window_count=1',
                'wait_lines_unpaired_or_invalid=1',
                'slow_scene_like_summed_wait_ms_p50=750.000',
                'fast_scene_like_summed_wait_ms_p50=0.000',
                'scene_like_wait_calls_p50=1.000',
                'game_relaunched=false','no_causal_pipeline_stall_claim=true')) {
            if (-not $public.Contains($expected)) { throw ('Synthetic report missing '+$expected) }
        }
        if ($public.Contains('C:\secret') -or $public.Contains('never-upload') -or $public.Contains($root)) {
            throw 'Private data escaped into anonymous report'
        }
        foreach ($line in ($public -split '[\r\n]+' | Where-Object { $_ })) {
            if ($line -cnotmatch '^[a-z0-9_]+=[A-Za-z0-9_.-]+$') {
                throw 'Anonymous report not fixed-field only'
            }
        }
        Write-Host 'VW092 offline wait/FPS pairing, median, bounded ZIP and privacy SelfTest PASS; no game launched'
    }
    finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    }
    exit 0
}
if ($RunId -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$') {
    throw 'Audit requires a valid prior E127 run ID, no game launched.'
}
if (-not (Test-Path -LiteralPath $ReportRoot -PathType Container)) {
    throw 'E127 report root missing.'
}
$folder=Join-Path $ReportRoot $RunId
if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
    throw 'E127 run directory missing.'
}
$destination=Join-Path $ReportRoot ('VW092-offline-'+$RunId)
$zip=MakeReport $folder $RunId $destination
Write-Host ('Offline audit complete. Upload ONLY '+$zip)
Write-Host 'No game launched. Source, saves, shaders and private logs unchanged.'
