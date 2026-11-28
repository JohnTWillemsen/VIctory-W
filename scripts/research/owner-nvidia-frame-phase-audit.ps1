#Requires -Version 5.1
# E162: read-only, offline, privacy-safe frame-phase aggregation.
# No game launch, source/cache/save changes or raw log text in the report.
[CmdletBinding()]
param(
    [ValidateSet('Audit','SelfTest')][string]$Mode='Audit',
    [string]$RunId='',
    [string]$ReportRoot='C:\VIctory-NVIDIA-Tests'
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$culture=[Globalization.CultureInfo]::InvariantCulture

function Num([string]$v) { return [double]::Parse($v,[Globalization.NumberStyles]::Float,$culture) }
function Fmt([double]$v) { return $v.ToString('0.0',$culture) }
function P50($values) {
    if ($values.Count -eq 0) { return 'UNKNOWN' }
    $s=@($values | Sort-Object)
    $n=$s.Count
    if ($n % 2 -eq 1) { return Fmt ([double]$s[[int][math]::Floor($n/2)]) }
    return Fmt (([double]$s[$n/2-1]+[double]$s[$n/2])/2.0)
}
function Bucket {
    $o=@{}
    foreach($key in @('fps','cpu','copies','textures','other','making','draws','frame')) {
        $o[$key]=New-Object 'System.Collections.Generic.List[double]'
    }
    return $o
}
function AddValue($b,[double]$fps,[double]$cpu,[double]$copies,[double]$textures,[double]$making,[double]$draws,[double]$frame) {
    $b.fps.Add($fps); $b.cpu.Add($cpu)
    $b.copies.Add($copies); $b.textures.Add($textures)
    $b.other.Add([math]::Max(0.0,$cpu-$copies-$textures))
    $b.draws.Add($draws); $b.frame.Add($frame)
    if ($making -ge 0) { $b.making.Add($making) }
}
function ReadPhases([string]$logs) {
    $scene=Bucket; $slow=Bucket; $fast=Bucket
    $profiles=New-Object 'System.Collections.Generic.List[object]'
    $lines=0; $limited=0; $without=0
    $files=@()
    if (Test-Path -LiteralPath $logs -PathType Container) {
        $files=@(Get-ChildItem -LiteralPath $logs -File -Filter '*.log' |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 6)
    }
    $rx='(?<!\w)(?<fps>\d{1,4}(?:\.\d{1,3})?) fps,\s*(?<frame>\d{1,6}(?:\.\d{1,3})?) ms/frame \((?<cpu>\d{1,6}(?:\.\d{1,3})?) preparing: copies (?<copy>\d{1,6}(?:\.\d{1,3})?) ms \d{1,9}(?:\.\d{1,3})? MB, textures (?<tex>\d{1,6}(?:\.\d{1,3})?) ms \d{1,9}(?:\.\d{1,3})? MB;'
    foreach ($file in $files) {
        if ($file.Length -gt 268435456) { $limited++; continue }
        $local=Bucket; $localSlow=Bucket; $count=0
        $stream=$null; $reader=$null
        try {
            $stream=New-Object IO.FileStream($file.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
            $reader=New-Object IO.StreamReader($stream)
            while (($null -ne ($line=$reader.ReadLine())) -and $count -lt 250000) {
                $count++; $lines++
                $m=[regex]::Match($line,$rx)
                if (-not $m.Success) { continue }
                $d=[regex]::Match($line,'(?<n>\d{1,7}(?:\.\d{1,2})?) draws/frame')
                if (-not $d.Success) { continue }
                $fps=Num $m.Groups['fps'].Value
                $frame=Num $m.Groups['frame'].Value
                $cpu=Num $m.Groups['cpu'].Value
                $copy=Num $m.Groups['copy'].Value
                $tex=Num $m.Groups['tex'].Value
                $draws=Num $d.Groups['n'].Value
                if ($fps -le 0 -or $fps -gt 1000 -or $frame -le 0 -or $frame -gt 100000 -or $draws -lt 100) { continue }
                $q=[regex]::Match($line,'dropped \d{1,7}(?:\.\d{1,2})? without a host pipeline \((?<n>\d{1,7}) being made\)')
                $making=-1.0
                if ($q.Success) { $making=Num $q.Groups['n'].Value }
                AddValue $scene $fps $cpu $copy $tex $making $draws $frame
                AddValue $local $fps $cpu $copy $tex $making $draws $frame
                if ($fps -le 10) {
                    AddValue $slow $fps $cpu $copy $tex $making $draws $frame
                    AddValue $localSlow $fps $cpu $copy $tex $making $draws $frame
                }
                if ($fps -ge 20) { AddValue $fast $fps $cpu $copy $tex $making $draws $frame }
            }
            if ($count -ge 250000 -and -not $reader.EndOfStream) { $limited++ }
        } finally {
            if ($null -ne $reader) { $reader.Dispose() }
            elseif ($null -ne $stream) { $stream.Dispose() }
        }
        if ($local.fps.Count -eq 0) { $without++ }
        $profiles.Add(@{
            rank=$profiles.Count+1
            windows=$local.fps.Count
            slow_windows=$localSlow.fps.Count
            fps_p50=(P50 $local.fps)
            slow_cpu_ms_p50=(P50 $localSlow.cpu)
            slow_copies_ms_p50=(P50 $localSlow.copies)
            slow_textures_ms_p50=(P50 $localSlow.textures)
            slow_pipeline_making_p50=(P50 $localSlow.making)
        })
    }
    return @{scene=$scene;slow=$slow;fast=$fast;profiles=$profiles.ToArray();files=$files.Count;lines=$lines;limited=$limited;without=$without}
}
function MakeReport([string]$run,[string]$id,[string]$dest) {
    $x=ReadPhases (Join-Path $run 'home\logs')
    $lines=@(
        'format=E162-nvidia-frame-phases-v1',
        ('source_run_id='+$id),
        'source=existing_private_victory_runtime_logs',
        'game_relaunched=false',
        'statistics_scope=multi_second_log_windows_not_individual_frames',
        'scene_heuristic=draws_per_frame_gte_100',
        'slow_threshold=fps_lte_10',
        'fast_threshold=fps_gte_20',
        ('files_seen='+$x.files),
        ('lines_scanned='+$x.lines),
        ('files_skipped_or_truncated='+$x.limited),
        ('files_without_scene_windows='+$x.without),
        ('scene_windows='+$x.scene.fps.Count),
        ('slow_scene_windows='+$x.slow.fps.Count),
        ('fast_scene_windows='+$x.fast.fps.Count),
        ('scene_cpu_ms_p50='+(P50 $x.scene.cpu)),
        ('scene_copies_ms_p50='+(P50 $x.scene.copies)),
        ('scene_textures_ms_p50='+(P50 $x.scene.textures)),
        ('slow_fps_p50='+(P50 $x.slow.fps)),
        ('slow_cpu_ms_p50='+(P50 $x.slow.cpu)),
        ('slow_copies_ms_p50='+(P50 $x.slow.copies)),
        ('slow_textures_ms_p50='+(P50 $x.slow.textures)),
        ('slow_other_ms_p50='+(P50 $x.slow.other)),
        ('slow_pipeline_making_p50='+(P50 $x.slow.making)),
        ('slow_pipeline_field_count='+$x.slow.making.Count),
        ('slow_draws_per_frame_p50='+(P50 $x.slow.draws)),
        ('fast_cpu_ms_p50='+(P50 $x.fast.cpu)),
        ('fast_copies_ms_p50='+(P50 $x.fast.copies)),
        ('fast_textures_ms_p50='+(P50 $x.fast.textures)),
        ('fast_pipeline_making_p50='+(P50 $x.fast.making)),
        ('profile_count='+$x.profiles.Count),
        'profile_order=recently_modified_first_not_chronological',
        'raw_log_paths_lines_assets_included=false',
        'no_causal_bottleneck_proven=true'
    )
    foreach ($p in $x.profiles) {
        $prefix='log_'+$p.rank+'_'
        foreach ($k in @('windows','slow_windows','fps_p50','slow_cpu_ms_p50','slow_copies_ms_p50','slow_textures_ms_p50','slow_pipeline_making_p50')) {
            $lines+=($prefix+$k+'='+$p[$k])
        }
    }
    if (Test-Path -LiteralPath $dest) { throw 'E162 output already exists; nothing overwritten' }
    New-Item -ItemType Directory -Path $dest | Out-Null
    $txt=Join-Path $dest 'E162-fixed-fields.txt'
    $zip=Join-Path $dest 'E162-anonymous-phase-summary.zip'
    [IO.File]::WriteAllLines($txt,$lines,[Text.UTF8Encoding]::new($false))
    Compress-Archive -LiteralPath $txt -DestinationPath $zip
    return $zip
}
if ($Mode -eq 'SelfTest') {
    $root=Join-Path $env:TEMP ('E162-fixture-'+[guid]::NewGuid().ToString('N').Substring(0,10))
    try {
        $id='e127-20261128000000-abcdef'
        $run=Join-Path $root $id
        $logs=Join-Path $run 'home\logs'
        New-Item -ItemType Directory -Force -Path $logs | Out-Null
        $samples=@(
            'PRIVATE C:\secret\never-upload.rpf',
            'INFO victory_gpu::host: 5.0 fps, 200.0 ms/frame (100.0 preparing: copies 60.0 ms 80.0 MB, textures 30.0 ms 100.0 MB; 0.0 on the GPU; 10.0 copying back 4.0 MB), 500 draws/frame, dropped 20 without a host pipeline (7 being made)',
            'INFO victory_gpu::host: 25.0 fps, 40.0 ms/frame (20.0 preparing: copies 5.0 ms 6.0 MB, textures 7.0 ms 3.0 MB; 10.0 on the GPU; 3.0 copying back 0.2 MB), 350 draws/frame, dropped 0 without a host pipeline (0 being made)',
            'INFO victory_gpu::host: 7.0 fps, 142.9 ms/frame (60.0 preparing: copies 25.0 ms 20.0 MB, textures 25.0 ms 70.0 MB; 0.0 on the GPU; 6.0 copying back 4.0 MB), 450 draws/frame, dropped 3 without a host pipeline (4 being made)',
            'INFO victory_gpu::host: 1.0 fps, 1000.0 ms/frame (900.0 preparing: copies 500.0 ms 200.0 MB, textures 350.0 ms 200.0 MB; 0.0 on the GPU; 1.0 copying back 2.0 MB), 12 draws/frame'
        )
        [IO.File]::WriteAllLines((Join-Path $logs 'synthetic.log'),$samples)
        $zip=MakeReport $run $id (Join-Path $root 'report')
        $out=Join-Path $root 'open'
        Expand-Archive -LiteralPath $zip -DestinationPath $out
        $members=@(Get-ChildItem -LiteralPath $out -File)
        if ($members.Count -ne 1 -or $members[0].Name -cne 'E162-fixed-fields.txt') { throw 'Unexpected E162 archive members' }
        $report=[IO.File]::ReadAllText($members[0].FullName)
        foreach ($expected in @(
            'scene_windows=3',
            'slow_scene_windows=2',
            'fast_scene_windows=1',
            'slow_cpu_ms_p50=80.0',
            'slow_copies_ms_p50=42.5',
            'slow_textures_ms_p50=27.5',
            'slow_other_ms_p50=10.0',
            'slow_pipeline_making_p50=5.5'
        )) {
            if (-not $report.Contains($expected)) { throw ('E162 synthetic metric mismatch '+$expected) }
        }
        foreach ($private in @('PRIVATE','C:\secret','never-upload.rpf','synthetic.log',$root)) {
            if ($report.Contains($private)) { throw 'E162 private synthetic log text leaked' }
        }
        Write-Host 'E162_WINPS51_PHASE_METRICS=PASS'
        Write-Host 'E162_ANONYMOUS_ZIP_ALLOWLIST=PASS'
        Write-Host 'E162_NO_TITLE_LAUNCHED=PASS'
    } finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    }
    return
}
if ($RunId -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$') { throw 'Exact anonymous E127 run id required' }
if (-not (Test-Path -LiteralPath $ReportRoot -PathType Container)) { throw 'Private report root missing' }
$root=(Resolve-Path -LiteralPath $ReportRoot).ProviderPath.TrimEnd([IO.Path]::DirectorySeparatorChar)
$run=Join-Path $root $RunId
if (-not (Test-Path -LiteralPath $run -PathType Container)) { throw 'Existing E127 run folder missing' }
if ((Split-Path -Parent (Resolve-Path -LiteralPath $run).ProviderPath) -ine $root) { throw 'E127 folder escaped private report root' }
$dest=Join-Path $root ('E162-offline-'+$RunId)
$zip=MakeReport $run $RunId $dest
Write-Host 'E162 offline numeric audit completed without game launch'
Write-Host ('UPLOAD ONLY: '+$zip)
