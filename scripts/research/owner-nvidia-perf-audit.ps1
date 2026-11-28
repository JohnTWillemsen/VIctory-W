#Requires -Version 5.1
# E140: offline, read-only performance audit of a PREVIOUS E127 private log.
# Does not execute a game or change source, shader settings, cache or saves.
# ONLY the fixed-field E140 ZIP is shareable. All raw logs stay on owner PC.
[CmdletBinding()]
param(
    [ValidateSet('Audit','SelfTest')][string]$Mode='Audit',
    [string]$RunId='',
    [string]$ReportRoot='C:\VIctory-NVIDIA-Tests'
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$Invariant=[Globalization.CultureInfo]::InvariantCulture
$ZipName='E140-anonymous-perf-summary.zip'

function Number([string]$Value) {
    return [double]::Parse($Value,[Globalization.NumberStyles]::Float,$Invariant)
}
function Fixed([double]$Value) {
    return $Value.ToString('0.0',$Invariant)
}
function Percentile([double[]]$Values,[double]$Fraction) {
    if ($null -eq $Values -or $Values.Count -eq 0) { return 'UNKNOWN' }
    $sorted=@($Values | Sort-Object)
    $at=($sorted.Count-1)*$Fraction
    $low=[int][math]::Floor($at)
    $high=[int][math]::Ceiling($at)
    $value=([double]$sorted[$low])*(1.0-($at-$low))+([double]$sorted[$high])*($at-$low)
    return Fixed $value
}
function ScanPerf([string]$LogDirectory) {
    $fps=New-Object 'System.Collections.Generic.List[double]'
    $fpsScene=New-Object 'System.Collections.Generic.List[double]'
    $msScene=New-Object 'System.Collections.Generic.List[double]'
    $cpuScene=New-Object 'System.Collections.Generic.List[double]'
    $gpuScene=New-Object 'System.Collections.Generic.List[double]'
    $backScene=New-Object 'System.Collections.Generic.List[double]'
    $drawsScene=New-Object 'System.Collections.Generic.List[double]'
    $seen=0
    $lines=0
    $limited=0
    $noSampleLogs=0

    $files=@()
    if (Test-Path -LiteralPath $LogDirectory -PathType Container) {
        $files=@(Get-ChildItem -LiteralPath $LogDirectory -File -Filter '*.log' |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 6)
    }
    foreach ($file in $files) {
        # Bound CPU/memory: no decompression and no reading files above 256 MiB.
        if ($file.Length -gt 268435456) {
            $limited++
            continue
        }
        $seen++
        $perFile=0
        $sampleBefore=$fps.Count
        $stream=$null
        $reader=$null
        try {
            $stream=New-Object IO.FileStream($file.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
            $reader=New-Object IO.StreamReader($stream)
            while (($null -ne ($line=$reader.ReadLine())) -and $perFile -lt 250000) {
                $perFile++
                $lines++
                # Exact structural anchor of victory-gpu's 5-second INFO meter.
                # No match or source line ever appears in the public ZIP.
                $m=[regex]::Match($line,'(?<!\w)(?<fps>\d{1,4}(?:\.\d{1,3})?) fps,\s*(?<ms>\d{1,6}(?:\.\d{1,3})?) ms/frame \((?<cpu>\d{1,6}(?:\.\d{1,3})?) preparing:')
                if (-not $m.Success) { continue }
                $f=Number $m.Groups['fps'].Value
                $ms=Number $m.Groups['ms'].Value
                $cpu=Number $m.Groups['cpu'].Value
                if ($f -le 0 -or $f -gt 1000 -or $ms -le 0 -or $ms -gt 100000) { continue }
                $fps.Add($f)
                $draw=[regex]::Match($line,'(?<n>\d{1,7}(?:\.\d{1,2})?) draws/frame')
                # Draws >=100 is only a scene-likely heuristic, never proof of
                # Lucia's cell or proof of working scene/render correctness.
                if (-not $draw.Success) { continue }
                $drawCount=Number $draw.Groups['n'].Value
                if ($drawCount -lt 100) { continue }
                $fpsScene.Add($f)
                $msScene.Add($ms)
                $cpuScene.Add($cpu)
                $drawsScene.Add($drawCount)
                $gpu=[regex]::Match($line,'(?<n>\d{1,6}(?:\.\d{1,3})?) on the GPU;')
                if ($gpu.Success) { $gpuScene.Add((Number $gpu.Groups['n'].Value)) }
                $back=[regex]::Match($line,'(?<n>\d{1,6}(?:\.\d{1,3})?) copying back')
                if ($back.Success) { $backScene.Add((Number $back.Groups['n'].Value)) }
            }
            if ($perFile -ge 250000 -and -not $reader.EndOfStream) { $limited++ }
        }
        finally {
            if ($null -ne $reader) { $reader.Dispose() }
            elseif ($null -ne $stream) { $stream.Dispose() }
        }
        if ($fps.Count -eq $sampleBefore) { $noSampleLogs++ }
    }
    return @{
        files=$seen
        lines=$lines
        limited=$limited
        no_sample_logs=$noSampleLogs
        fps=$fps.ToArray()
        scene_fps=$fpsScene.ToArray()
        scene_ms=$msScene.ToArray()
        scene_cpu=$cpuScene.ToArray()
        scene_gpu=$gpuScene.ToArray()
        scene_back=$backScene.ToArray()
        scene_draws=$drawsScene.ToArray()
    }
}
function MakeReport([string]$RunFolder,[string]$SessionId,[string]$OutputRoot) {
    $stats=ScanPerf (Join-Path $RunFolder 'home\logs')
    $status=if ($stats.scene_fps.Count -gt 0) { 'SCENE_LIKE_SAMPLES_FOUND' }
            elseif ($stats.fps.Count -gt 0) { 'ONLY_NONSCENE_FPS_SAMPLES' }
            else { 'NO_FPS_SAMPLES_FOUND' }
    $lines=@(
        'format=E140-nvidia-offline-perf-v1',
        ('source_run_id='+$SessionId),
        ('status='+$status),
        'source=existing_private_victory_runtime_logs',
        'game_relaunched=false',
        ('log_files_scanned='+$stats.files),
        ('log_lines_scanned='+$stats.lines),
        ('log_files_skipped_or_truncated='+$stats.limited),
        ('log_files_without_meter_samples='+$stats.no_sample_logs),
        ('all_fps_window_sample_count='+$stats.fps.Count),
        ('scene_like_window_sample_count='+$stats.scene_fps.Count),
        'scene_heuristic=draws_per_frame_gte_100',
        ('all_windows_fps_p50='+(Percentile $stats.fps 0.50)),
        ('scene_like_fps_min='+(Percentile $stats.scene_fps 0.00)),
        ('scene_like_fps_p10='+(Percentile $stats.scene_fps 0.10)),
        ('scene_like_fps_p50='+(Percentile $stats.scene_fps 0.50)),
        ('scene_like_fps_p90='+(Percentile $stats.scene_fps 0.90)),
        ('scene_like_frame_ms_p50='+(Percentile $stats.scene_ms 0.50)),
        ('scene_like_frame_ms_p90='+(Percentile $stats.scene_ms 0.90)),
        ('scene_like_cpu_prepare_ms_p50='+(Percentile $stats.scene_cpu 0.50)),
        ('scene_like_host_gpu_ms_p50='+(Percentile $stats.scene_gpu 0.50)),
        ('scene_like_copyback_ms_p50='+(Percentile $stats.scene_back 0.50)),
        ('scene_like_draws_per_frame_p50='+(Percentile $stats.scene_draws 0.50)),
        'statistics_scope=log_windows_not_individual_frames',
        'percentiles_not_1pct_lows=true',
        'scene_type_not_identified=true',
        'gpu_utilization_not_measured=true',
        'raw_logs_paths_assets_or_dumps_included=false'
    )
    New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
    $txt=Join-Path $OutputRoot 'E140-fixed-fields.txt'
    $zip=Join-Path $OutputRoot $ZipName
    [IO.File]::WriteAllLines($txt,$lines,[Text.UTF8Encoding]::new($false))
    Compress-Archive -LiteralPath $txt -DestinationPath $zip -Force
    return $zip
}
if ($Mode -eq 'SelfTest') {
    $testRoot=Join-Path $env:TEMP ('E140-test-'+[guid]::NewGuid().ToString('N').Substring(0,9))
    try {
        $run=Join-Path $testRoot 'fixture'
        $log=Join-Path $run 'home\logs'
        New-Item -ItemType Directory -Force -Path $log | Out-Null
        $samples=@(
            'PRIVATE path C:\secret\asset\never-upload.rpf',
            'INFO victory_gpu::host: 13.0 fps, 76.9 ms/frame (30.0 preparing: copies 7.0 ms 8.0 MB, textures 4.0 ms 12.0 MB; 40.0 on the GPU; 6.9 copying back 4.0 MB), 350 draws/frame',
            'INFO victory_gpu::host: 65.0 fps, 15.4 ms/frame (4.0 preparing: copies 1.0 ms 2.0 MB, textures 2.0 ms 3.0 MB; 6.0 on the GPU; 1.0 copying back 0.4 MB), 12 draws/frame',
            'INFO victory_gpu::host: 25.0 fps, 40.0 ms/frame (20.0 preparing: copies 2.0 ms 2.0 MB, textures 3.0 ms 5.0 MB; 18.0 on the GPU; 2.0 copying back 1.0 MB), 420 draws/frame'
        )
        [IO.File]::WriteAllLines((Join-Path $log 'victory-fixture.log'),$samples)
        $zip=MakeReport $run 'e127-20261128012417-dba267' (Join-Path $testRoot 'output')
        $opened=Join-Path $testRoot 'opened'
        Expand-Archive -LiteralPath $zip -DestinationPath $opened
        $files=@(Get-ChildItem -LiteralPath $opened -File)
        if ($files.Count -ne 1 -or $files[0].Name -ne 'E140-fixed-fields.txt') { throw 'Public ZIP membership wrong' }
        $report=[IO.File]::ReadAllText($files[0].FullName)
        foreach ($term in @('scene_like_window_sample_count=2','all_fps_window_sample_count=3',
                            'scene_like_fps_p50=19.0','scene_like_frame_ms_p50=58.5',
                            'scene_like_host_gpu_ms_p50=29.0','game_relaunched=false')) {
            if (-not $report.Contains($term)) { throw ('E140 fixture mismatch: '+$term) }
        }
        if ($report.Contains('never-upload') -or $report.Contains('C:\secret') -or $report.Contains($testRoot)) {
            throw 'Private data leaked into E140 ZIP'
        }
        Write-Host 'E140 offline FPS/CPU/GPU aggregation, scene heuristic, ZIP allowlist and privacy fixture PASS; no game launched'
    }
    finally {
        if (Test-Path -LiteralPath $testRoot) {
            Remove-Item -LiteralPath $testRoot -Recurse -Force
        }
    }
    exit 0
}
if ($RunId -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$') {
    throw 'Audit requires a fixed-field E127 run ID; no files changed.'
}
if (-not (Test-Path -LiteralPath $ReportRoot -PathType Container)) {
    throw 'E127 report root not found.'
}
$run=Join-Path $ReportRoot $RunId
if (-not (Test-Path -LiteralPath $run -PathType Container)) {
    throw 'E127 run folder missing; no game launched.'
}
$output=Join-Path $ReportRoot ('E140-offline-'+$RunId)
$zip=MakeReport $run $RunId $output
Write-Host ('Offline audit complete. Upload ONLY: '+$zip)
Write-Host 'No game launched; all original logs, game files and source unchanged.'
