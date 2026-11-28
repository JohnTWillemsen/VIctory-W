#Requires -Version 5.1
# VW092-H5: offline bounded numeric pipeline library evidence from EXISTING
# E127 private logs. Does not launch a game, copy caches, or export log text.
[CmdletBinding()]
param(
    [ValidateSet('SelfTest','Audit')][string]$Mode='Audit',
    [string]$RunId='',
    [string]$ReportRoot='C:\VIctory-NVIDIA-Tests'
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$ZipName='VW092-anonymous-cache-observations.zip'
$Member='VW092-cache-fixed-fields.txt'
$Anchor='host pipeline library saved'
$Refused='host pipeline library rejected; starting an empty one'
function ReadNumeric([string]$Line,[string]$Field) {
    $match=[regex]::Match($Line,'(?<![A-Za-z0-9_])'+[regex]::Escape($Field)+'=(?<v>\d{1,10})(?!\d)')
    if (-not $match.Success) { return $null }
    [long]$val=0
    if (-not [long]::TryParse($match.Groups['v'].Value,[ref]$val)) { return $null }
    return $val
}
function Scan([string]$Folder) {
    [long]$lines=0
    [long]$saves=0
    [long]$rejected=0
    [long]$loaded=0
    [long]$made=0
    [long]$early=0
    [int]$fileCount=0
    [int]$filesWithSave=0
    [int]$skipped=0
    $files=@()
    if (Test-Path -LiteralPath $Folder -PathType Container) {
        $files=@(Get-ChildItem -LiteralPath $Folder -File -Filter '*.log' -ErrorAction Stop |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 6)
    }
    foreach ($file in $files) {
        if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $file.Length -gt 268435456) { $skipped++; continue }
        $fileCount++
        [long]$perFile=0
        $last=$null
        $stream=$null
        $reader=$null
        try {
            $stream=New-Object IO.FileStream($file.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
            $reader=New-Object IO.StreamReader($stream)
            while (($null -ne ($line=$reader.ReadLine())) -and $perFile -lt 250000) {
                $perFile++;$lines++
                if ($line.Contains($Refused)) { $rejected++ }
                if (-not $line.Contains($Anchor)) { continue }
                $l=ReadNumeric $line 'loaded'
                $m=ReadNumeric $line 'made'
                $e=ReadNumeric $line 'started_early'
                if ($null -eq $l -or $null -eq $m -or $null -eq $e) { continue }
                # Counts are per-process cumulative snapshots, not additive
                # events; retain the FINAL valid save record in each log.
                $last=@{ loaded=$l;made=$m;early=$e }
                $saves++
            }
            if ($perFile -ge 250000 -and -not $reader.EndOfStream) { $skipped++ }
        }
        finally {
            if ($null -ne $reader) { $reader.Dispose() }
            elseif ($null -ne $stream) { $stream.Dispose() }
        }
        if ($null -ne $last) {
            $filesWithSave++
            $loaded += [long]$last.loaded
            $made += [long]$last.made
            $early += [long]$last.early
        }
    }
    $status=if ($filesWithSave -gt 0) { 'SAVED_COUNTERS_FOUND' } else { 'NO_SAVED_COUNTERS_FOUND' }
    return @{
        status=$status;files=$fileCount;lines=$lines;skipped=$skipped
        saves=$saves;rejected=$rejected;files_with_saved=$filesWithSave
        loaded= $(if ($filesWithSave -gt 0) { [string]$loaded } else { 'UNKNOWN' })
        made= $(if ($filesWithSave -gt 0) { [string]$made } else { 'UNKNOWN' })
        early= $(if ($filesWithSave -gt 0) { [string]$early } else { 'UNKNOWN' })
    }
}
function Fields([string]$Id,[hashtable]$S) {
    return @(
        'format=VW092-offline-cache-observations-v1',
        ('source_run_id='+$Id),
        ('status='+$S.status),
        'source=existing_private_victory_runtime_logs',
        'game_relaunched=false',
        ('log_files_scanned='+$S.files),
        ('log_lines_scanned='+$S.lines),
        ('log_files_skipped_or_truncated='+$S.skipped),
        ('library_saved_counter_record_count='+$S.saves),
        ('log_files_with_saved_counter_records='+$S.files_with_saved),
        ('library_rejected_marker_count='+$S.rejected),
        ('library_load_successes_at_latest_saves='+$S.loaded),
        ('library_newly_made_at_latest_saves='+$S.made),
        ('library_started_early_at_latest_saves='+$S.early),
        'counter_scope=latest_valid_save_per_log',
        'counters_may_include_same_session_library_loads=true',
        'absent_saved_counter_means_unknown_not_zero=true',
        'saved_counter_snapshots_not_complete_session_totals=true',
        'unmatched_scene_and_no_causal_fps_claim=true',
        'raw_logs_paths_shader_hashes_or_title_assets_included=false'
    )
}
function WriteZip([string]$Path,[string[]]$Lines) {
    Add-Type -AssemblyName System.IO.Compression
    $fs=$null;$arc=$null;$writer=$null
    try {
        $fs=New-Object IO.FileStream($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $arc=[IO.Compression.ZipArchive]::new($fs,[IO.Compression.ZipArchiveMode]::Create,$false)
        $entry=$arc.CreateEntry($Member,[IO.Compression.CompressionLevel]::Optimal)
        $writer=[IO.StreamWriter]::new($entry.Open(),[Text.UTF8Encoding]::new($false))
        foreach ($line in $Lines) { $writer.WriteLine($line) }
        $writer.Flush()
    }
    finally {
        if ($null -ne $writer) { $writer.Dispose() }
        if ($null -ne $arc) { $arc.Dispose() }
        if ($null -ne $fs) { $fs.Dispose() }
    }
}
if ($Mode -eq 'SelfTest') {
    $temp=Join-Path $env:TEMP ('VW092-cache-audit-fixture-'+[guid]::NewGuid().ToString('N').Substring(0,8))
    try {
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
        $id='e127-20261128081213-a196c3'
        $log=Join-Path $temp 'synthetic.log'
        $private='PRIVATE C:\secret\title\shader 0123456789ABCDEF'
        @(
            ('INFO cache: host pipeline library saved bytes=88 early=9 made=20 loaded=8 started_early=3 '+$private),
            ('INFO cache: host pipeline library saved bytes=90 loaded=11 made=24 started_early=5 '+$private),
            ('INFO cache: host pipeline library rejected; starting an empty one error='+$private)
        ) | Set-Content -LiteralPath $log -Encoding UTF8
        $s=Scan $temp
        if ($s.status -cne 'SAVED_COUNTERS_FOUND' -or $s.saves -ne 2 -or
            $s.files_with_saved -ne 1 -or $s.loaded -cne '11' -or
            $s.made -cne '24' -or $s.early -cne '5' -or $s.rejected -ne 1) {
            throw 'Cache-counter synthetic saved snapshot/rejection classification failed'
        }
        $lines=Fields $id $s
        $joined=$lines -join "`n"
        if ($joined.Contains('PRIVATE') -or
            $joined.Contains('C:\secret') -or $joined.Contains('0123456789ABCDEF')) {
            throw 'Private synthetic log content leaked into report'
        }
        $zip=Join-Path $temp $ZipName
        WriteZip $zip $lines
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive=[IO.Compression.ZipFile]::OpenRead($zip)
        try {
            if ($archive.Entries.Count -ne 1 -or $archive.Entries[0].FullName -cne $Member) {
                throw 'ZIP member allowlist violated'
            }
            $reader=New-Object IO.StreamReader($archive.Entries[0].Open())
            try { $payload=$reader.ReadToEnd() } finally { $reader.Dispose() }
            if ($payload.Contains($private) -or $payload.Contains('PRIVATE') -or
                $payload.Contains('0123456789ABCDEF')) {
                throw 'Cache ZIP privacy fixture failed'
            }
        }
        finally { $archive.Dispose() }
        [IO.File]::WriteAllText($log,'INFO without any library saved counter record')
        $none=Scan $temp
        if ($none.status -cne 'NO_SAVED_COUNTERS_FOUND' -or
            $none.loaded -cne 'UNKNOWN' -or $none.made -cne 'UNKNOWN') {
            throw 'Missing cache records were incorrectly treated as zero loads'
        }
        Write-Host 'VW092 offline cache saved-counter/rejection audit, ZIP allowlist and privacy SelfTest PASS; no game launched'
    }
    finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force } }
    return
}
if ($RunId -cnotmatch '^e127-\d{14}-[a-f0-9]{6}$') { throw 'Exact E127 run ID required' }
if (-not (Test-Path -LiteralPath $ReportRoot -PathType Container)) { throw 'Private E127 report root missing' }
$root=(Resolve-Path -LiteralPath $ReportRoot).ProviderPath.TrimEnd('\')
if (((Get-Item -LiteralPath $root).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw 'Private report root may not be a symlink'
}
$session=Join-Path $root $RunId
if (-not (Test-Path -LiteralPath $session -PathType Container)) { throw 'E127 session missing; no game launched' }
if (((Get-Item -LiteralPath $session).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw 'E127 session may not be a symlink'
}
$logs=Join-Path $session 'home\logs'
$stats=Scan $logs
$outputDir=Join-Path $root ('VW092-cache-offline-'+$RunId)
if (Test-Path -LiteralPath $outputDir) { throw 'Output already exists; do not overwrite prior report' }
New-Item -ItemType Directory -Path $outputDir | Out-Null
$zip=Join-Path $outputDir $ZipName
WriteZip $zip (Fields $RunId $stats)
Write-Host ('VW092 CACHE STATUS: '+$stats.status)
Write-Host ('SAVED COUNTER RECORDS: '+$stats.saves)
Write-Host ('UPLOAD ONLY: '+$zip)
Write-Host 'No game launched; private logs not copied or exported.'
