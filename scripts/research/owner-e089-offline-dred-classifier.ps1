#Requires -Version 5.1
# E089: inspect E087 PRIVATE logs locally; export only a fixed, anonymous count schema.
# Does not start a game, change configuration, access game assets, or upload anything.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RunFolder,
    [string]$OutputName = 'E089-offline-dred-counts.zip'
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Folder = (Resolve-Path -LiteralPath $RunFolder -ErrorAction Stop).ProviderPath
if ([IO.Path]::GetFileName($Folder.TrimEnd('\','/')) -notmatch '^E087-supervised-[0-9]{8}-[0-9]{6}-[0-9a-f]{6}$') {
    throw 'This tool only accepts an E087-supervised-* report folder.'
}
if ($OutputName -cne 'E089-offline-dred-counts.zip') {
    throw 'Custom output filenames are not supported by the privacy contract.'
}
$Private = Join-Path $Folder 'PRIVATE-logs-do-not-upload'
$Safe = Join-Path $Folder 'upload-only'
if (-not (Test-Path -LiteralPath $Private -PathType Container)) { throw 'Expected private E087 log folder missing.' }
$E087Status = Join-Path $Safe 'E087-anonymous-status.txt'
if (-not (Test-Path -LiteralPath $E087Status -PathType Leaf)) { throw 'Expected E087 initial checkpoint not found.' }
$SafeStatus = Get-Content -LiteralPath $E087Status -Raw
if (-not $SafeStatus.Contains('format=E087-durable-gpu-supervisor-v1')) { throw 'Unexpected E087 report format.' }

$Counts = [ordered]@{
    log_files=0
    total_log_bytes=0
    scanned_lines=0
    error_level_lines=0
    gpu_host_error_lines=0
    host_slow_submission_lines=0
    host_max_slow_ms=0
    host_lists_at_max_slow=0
    dxgi_device_removed_code_lines=0
    dxgi_device_hung_code_lines=0
    dxgi_unsupported_code_lines=0
    device_removed_text_lines=0
    device_hung_text_lines=0
    dred_marker_lines=0
    dred_no_breadcrumbs_lines=0
    dred_auto_breadcrumb_lines=0
    dred_page_fault_marker_lines=0
    dred_stopped_command_marker_lines=0
    dred_last_stopped_command_index=0
    dred_last_stopped_command_total=0
    dred_last_stopped_op_code=0
    gpu_pipeline_refused_lines=0
    shader_translation_refused_lines=0
    dropped_pipeline_marker_lines=0
    descriptor_missing_marker_lines=0
    d3d12_debug_error_marker_lines=0
    d3d12_debug_warning_marker_lines=0
    tail_512_device_removed_lines=0
    tail_512_device_hung_lines=0
    tail_512_dred_lines=0
    tail_512_compute_lines=0
    tail_512_mesh_lines=0
    tail_512_debug_error_lines=0
    tail_512_page_fault_lines=0
}
$Tail = [Collections.Generic.Queue[string]]::new()


foreach ($File in @('title-stdout-private.txt','title-stderr-private.txt')) {
    $Path = Join-Path $Private $File
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { continue }
    $Counts['log_files'] = [long]$Counts['log_files'] + 1
    $Counts['total_log_bytes'] = [long]$Counts['total_log_bytes'] + [long](Get-Item -LiteralPath $Path).Length
    $Stream = $null
    $Reader = $null
    try {
        # Read share-safe without copying contents to another location.
        $Stream = [IO.FileStream]::new($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
        $Reader = [IO.StreamReader]::new($Stream)
        while ($null -ne ($Line = $Reader.ReadLine())) {
            $Counts['scanned_lines'] = [long]$Counts['scanned_lines'] + 1
            if ($Line -match '(?i)\bERROR\b') { $Counts['error_level_lines'] = [long]$Counts['error_level_lines'] + 1 }
            if ($Line -match '(?i)ERROR victory_gpu::host') { $Counts['gpu_host_error_lines'] = [long]$Counts['gpu_host_error_lines'] + 1 }
            if ($Line -match '(?i)slow host submission') {
            $Counts['host_slow_submission_lines'] = [long]$Counts['host_slow_submission_lines'] + 1
            if ($Line -match 'ms=([0-9]+)\s+lists=([0-9]+)') {
            $Ms = [long]$Matches[1]
            if ($Ms -gt $Counts.host_max_slow_ms) {
            $Counts.host_max_slow_ms=$Ms
            $Counts.host_lists_at_max_slow=[long]$Matches[2]
            }
            }
            }
            if ($Line -match '(?i)(0x887a0005|DXGI_ERROR_DEVICE_REMOVED)') { $Counts['dxgi_device_removed_code_lines'] = [long]$Counts['dxgi_device_removed_code_lines'] + 1 }
            if ($Line -match '(?i)(0x887a0006|DXGI_ERROR_DEVICE_HUNG)') { $Counts['dxgi_device_hung_code_lines'] = [long]$Counts['dxgi_device_hung_code_lines'] + 1 }
            if ($Line -match '(?i)0x887a0004') { $Counts['dxgi_unsupported_code_lines'] = [long]$Counts['dxgi_unsupported_code_lines'] + 1 }
            if ($Line -match '(?i)device removed') { $Counts['device_removed_text_lines'] = [long]$Counts['device_removed_text_lines'] + 1 }
            if ($Line -match '(?i)device hung') { $Counts['device_hung_text_lines'] = [long]$Counts['device_hung_text_lines'] + 1 }
            if ($Line -match '(?i)(DRED|breadcrumb|page fault)') { $Counts['dred_marker_lines'] = [long]$Counts['dred_marker_lines'] + 1 }
            if ($Line -match '(?i)no breadcrumbs') { $Counts['dred_no_breadcrumbs_lines'] = [long]$Counts['dred_no_breadcrumbs_lines'] + 1 }
            if ($Line -match '(?i)(auto.?breadcrumb|breadcrumbs.*(completed|stopped))') { $Counts['dred_auto_breadcrumb_lines'] = [long]$Counts['dred_auto_breadcrumb_lines'] + 1 }
            if ($Line -match '(?i)page fault') { $Counts['dred_page_fault_marker_lines'] = [long]$Counts['dred_page_fault_marker_lines'] + 1 }
            if ($Line -match '(?i)(?:stopped at )?command\s+([0-9]+)\s+of\s+([0-9]+)(?:\s*\(op\s*([0-9]+)\))?') {
            $Counts['dred_stopped_command_marker_lines'] = [long]$Counts['dred_stopped_command_marker_lines'] + 1
            $Counts.dred_last_stopped_command_index = [int]$Matches[1]
            $Counts.dred_last_stopped_command_total = [int]$Matches[2]
            if ($Line -match '\(op\s*([0-9]+)\)') { $Counts['dred_last_stopped_op_code'] = [int]$Matches[1] }
            }
            if ($Line -match '(?i)host pipeline refused') { $Counts['gpu_pipeline_refused_lines'] = [long]$Counts['gpu_pipeline_refused_lines'] + 1 }
            if ($Line -match '(?i)(shader does not translate|shader translation (?:failed|refused))') { $Counts['shader_translation_refused_lines'] = [long]$Counts['shader_translation_refused_lines'] + 1 }
            if ($Line -match '(?i)(DROPPED indirect|dropped .*without a host pipeline)') { $Counts['dropped_pipeline_marker_lines'] = [long]$Counts['dropped_pipeline_marker_lines'] + 1 }
            if ($Line -match '(?i)(no descriptor slots|descriptor slot.*(?:null|missing)|no host pipeline)') { $Counts['descriptor_missing_marker_lines'] = [long]$Counts['descriptor_missing_marker_lines'] + 1 }
            if ($Line -match '(?i)(?:D3D12|debug layer).*(?:\bERROR\b|error:)') { $Counts['d3d12_debug_error_marker_lines'] = [long]$Counts['d3d12_debug_error_marker_lines'] + 1 }
            if ($Line -match '(?i)(?:D3D12|debug layer).*\bWARNING\b') { $Counts['d3d12_debug_warning_marker_lines'] = [long]$Counts['d3d12_debug_warning_marker_lines'] + 1 }
            $Tail.Enqueue($Line)
            if ($Tail.Count -gt 512) { [void]$Tail.Dequeue() }
        }
    } finally {
        if ($null -ne $Reader) { $Reader.Dispose() }
        elseif ($null -ne $Stream) { $Stream.Dispose() }
    }
}
if ($Counts.log_files -eq 0) { throw 'No expected local title stdout/stderr files; nothing to analyze.' }

foreach ($Line in $Tail) {
    if ($Line -match '(?i)device removed') { $Counts['tail_512_device_removed_lines'] = [long]$Counts['tail_512_device_removed_lines'] + 1 }
    if ($Line -match '(?i)(device hung|0x887a0006)') { $Counts['tail_512_device_hung_lines'] = [long]$Counts['tail_512_device_hung_lines'] + 1 }
    if ($Line -match '(?i)(DRED|breadcrumb|page fault)') { $Counts['tail_512_dred_lines'] = [long]$Counts['tail_512_dred_lines'] + 1 }
    if ($Line -match '(?i)(?:\bcompute\b|\[compute )') { $Counts['tail_512_compute_lines'] = [long]$Counts['tail_512_compute_lines'] + 1 }
    if ($Line -match '(?i)(?:\bmesh\b|\[mesh )') { $Counts['tail_512_mesh_lines'] = [long]$Counts['tail_512_mesh_lines'] + 1 }
    if ($Line -match '(?i)(?:D3D12|debug layer).*(?:\bERROR\b|error:)') { $Counts['tail_512_debug_error_lines'] = [long]$Counts['tail_512_debug_error_lines'] + 1 }
    if ($Line -match '(?i)page fault') { $Counts['tail_512_page_fault_lines'] = [long]$Counts['tail_512_page_fault_lines'] + 1 }
}
$Lines = New-Object System.Collections.Generic.List[string]
$Lines.Add('format=E089-private-offline-dred-aggregate-v1')
$Lines.Add('analysis_mode=offline_existing_logs_only')
$Lines.Add('new_title_launch=false')
$Lines.Add('contains_raw_log_text=false')
$Lines.Add('contains_paths_addresses_shader_hashes=false')
$Lines.Add('precision=marker_line_counts_not_unique_events')
foreach ($Entry in $Counts.GetEnumerator()) {
    # Fixed lowercase ASCII keys, bounded integer values; no dynamic identifiers in ZIP.
    $Lines.Add(([string]$Entry.Key + '=' + [string]([long]$Entry.Value)))
}
$Filename = Join-Path $Safe 'E089-anonymous-dred-counts.txt'
$Temp = $Filename + '.new'
[IO.File]::WriteAllLines($Temp,$Lines,[Text.UTF8Encoding]::new($false))
if ([IO.File]::Exists($Filename)) {
    $Backup = $Filename + '.backup'
    if ([IO.File]::Exists($Backup)) { [IO.File]::Delete($Backup) }
    [IO.File]::Replace($Temp,$Filename,$Backup)
} else { [IO.File]::Move($Temp,$Filename) }
$Zip = Join-Path $Folder 'E089-offline-dred-counts.zip'
$ZipTemp = Join-Path $Folder 'E089-offline-dred-counts.next.zip'
if ([IO.File]::Exists($ZipTemp)) { [IO.File]::Delete($ZipTemp) }
Compress-Archive -LiteralPath $Filename -DestinationPath $ZipTemp -Force
if ([IO.File]::Exists($Zip)) {
    $Backup = $Zip + '.backup'
    if ([IO.File]::Exists($Backup)) { [IO.File]::Delete($Backup) }
    [IO.File]::Replace($ZipTemp,$Zip,$Backup)
} else { [IO.File]::Move($ZipTemp,$Zip) }
Write-Host ('E089 offline analysis complete: ' + $Counts.scanned_lines + ' private lines scanned.')
Write-Host ('UPLOAD ONLY THIS ANONYMOUS ZIP PRIVATELY: ' + $Zip)
Write-Host 'Do not upload PRIVATE-logs-do-not-upload or any game assets to GitHub.'
