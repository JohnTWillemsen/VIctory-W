#Requires -Version 5.1
# E-070: OFFLINE only. Scan the owner's existing E068 logs for aggregate metrics.
# No executable starts; no title files, shader identifiers, raw log lines or
# machine-specific paths are copied into the upload-only ZIP.
[CmdletBinding()]
param(
    [string]$ReportRoot = 'C:\VIctory-Tests',
    [string]$RunFolder = '',
    [string]$LogFile = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Source = @()

if ($LogFile) {
    # Only for synthetic CI fixtures or explicitly selected private log files.
    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        throw 'Supplied log file was not found.'
    }
    $Source = @((Resolve-Path -LiteralPath $LogFile).ProviderPath)
}
else {
    if ($RunFolder) {
        if (-not (Test-Path -LiteralPath $RunFolder -PathType Container)) {
            throw 'Supplied E068 report directory was not found.'
        }
        $Selected = (Resolve-Path -LiteralPath $RunFolder).ProviderPath
    }
    else {
        if (-not (Test-Path -LiteralPath $ReportRoot -PathType Container)) {
            throw 'E068 report root not found.'
        }
        $Reports = @(Get-ChildItem -LiteralPath $ReportRoot -Directory |
            Where-Object { $_.Name -like 'E068-RTX5090-BVH-categories-*' -and $_.Name -notlike '*-binary' } |
            Sort-Object LastWriteTime -Descending)
        if ($Reports.Count -eq 0) {
            throw 'No E068 report directory found. Use -RunFolder with the exact local report directory.'
        }
        $Selected = $Reports[0].FullName
    }
    $Private = Join-Path $Selected 'PRIVATE-raw-logs-do-not-upload'
    foreach ($Name in @('title-stderr-private.txt', 'title-stdout-private.txt')) {
        $Candidate = Join-Path $Private $Name
        if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
            $Source += $Candidate
        }
    }
    if ($Source.Count -eq 0) {
        throw 'No E068 private title logs were found. No new game launch is needed.'
    }
}

function Read-IntegerField {
    param([string]$Line, [string]$Name)
    $Pattern = '(?<![A-Za-z0-9_])' + [regex]::Escape($Name) + '\s*[=:]\s*(\d+)'
    $Match = [regex]::Match($Line, $Pattern)
    if (-not $Match.Success) { return $null }
    return [uint64]::Parse($Match.Groups[1].Value)
}

$Stats = [ordered]@{
    source_files_read = 0
    bytes_scanned = [uint64]0
    lines_scanned = [uint64]0
    bvh_builder_info_lines = 0
    bvh_builder_holdback_lines = 0
    bvh_builder_runs_lines = 0
    bvh_pipeline_state_records = 0
    last_bvh_pipelines = 'not_observed'
    last_bvh_made = 'not_observed'
    last_bvh_refused = 'not_observed'
    last_bvh_dropped = 'not_observed'
    max_bvh_refused = 'not_observed'
    anonymous_category_marker_lines = 0
    anonymous_complete_count_records = 0
    anonymous_missing_count_fields = 0
    last_shader_translation = 'not_observed'
    last_host_pipeline = 'not_observed'
    last_pending = 'not_observed'
    shader_translation_warning_lines = 0
    heap_overflow_warning_lines = 0
}
$MaxRefused = [uint64]0
$HasRefused = $false

foreach ($File in $Source) {
    $Stats['source_files_read']++
    $Stats['bytes_scanned'] = [uint64]$Stats['bytes_scanned'] +
        [uint64](Get-Item -LiteralPath $File).Length
    $Reader = New-Object System.IO.StreamReader($File)
    try {
        while ($null -ne ($Line = $Reader.ReadLine())) {
            $Stats['lines_scanned']++
            if ($Line.Contains('title slot past the host heap')) {
                $Stats['heap_overflow_warning_lines']++
            }
            if ($Line.Contains("shader does not translate; its pipelines' draws are dropped")) {
                $Stats['shader_translation_warning_lines']++
            }
            if ($Line.Contains('BVH builder ')) {
                $Stats['bvh_builder_info_lines']++
                if ($Line.Contains('held back')) { $Stats['bvh_builder_holdback_lines']++ }
                if ($Line.Contains('BVH builder runs')) { $Stats['bvh_builder_runs_lines']++ }
                if ($Line.Contains('pipelines=')) {
                    $Pipelines = Read-IntegerField $Line 'pipelines'
                    $Made = Read-IntegerField $Line 'made'
                    $Refused = Read-IntegerField $Line 'refused'
                    $Dropped = Read-IntegerField $Line 'dropped'
                    if ($null -ne $Pipelines -and $null -ne $Made -and
                        $null -ne $Refused -and $null -ne $Dropped) {
                        $Stats['bvh_pipeline_state_records']++
                        $Stats['last_bvh_pipelines'] = $Pipelines
                        $Stats['last_bvh_made'] = $Made
                        $Stats['last_bvh_refused'] = $Refused
                        $Stats['last_bvh_dropped'] = $Dropped
                        if (-not $HasRefused -or $Refused -gt $MaxRefused) {
                            $HasRefused = $true
                            $MaxRefused = $Refused
                        }
                    }
                }
            }
            if ($Line.Contains('BVH builder unavailable pipeline categories (anonymous)')) {
                $Stats['anonymous_category_marker_lines']++
                $Translated = Read-IntegerField $Line 'shader_translation'
                $Host = Read-IntegerField $Line 'host_pipeline'
                $Pending = Read-IntegerField $Line 'pending'
                if ($null -ne $Translated -and $null -ne $Host -and $null -ne $Pending) {
                    $Stats['anonymous_complete_count_records']++
                    $Stats['last_shader_translation'] = $Translated
                    $Stats['last_host_pipeline'] = $Host
                    $Stats['last_pending'] = $Pending
                }
                else {
                    $Stats['anonymous_missing_count_fields']++
                }
            }
        }
    }
    finally {
        $Reader.Close()
        $Reader.Dispose()
    }
}
if ($HasRefused) { $Stats['max_bvh_refused'] = $MaxRefused }

$Id = 'E070-offline-BVH-log-audit-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
$Folder = Join-Path $ReportRoot $Id
$Upload = Join-Path $Folder 'upload-only'
$Zip = Join-Path $ReportRoot ($Id + '-summary.zip')
New-Item -ItemType Directory -Force -Path $Upload | Out-Null
$Out = New-Object 'System.Collections.Generic.List[string]'
$Out.Add('E-070 local-only analysis of prior E068 log files; no game run, no rebuild.')
foreach ($Key in $Stats.Keys) {
    $Out.Add($Key + '=' + [string]$Stats[$Key])
}
if ([int]$Stats['anonymous_complete_count_records'] -eq 0) {
    if ([int]$Stats['anonymous_category_marker_lines'] -eq 0) {
        $Out.Add('interpretation=No anonymous BVH telemetry markers observed in scanned logs; category split UNKNOWN.')
    }
    else {
        $Out.Add('interpretation=BVH telemetry marker was observed but a count was not parseable; category split UNKNOWN.')
    }
}
else {
    $Out.Add('interpretation=Anonymous BVH category totals were parsed; this is diagnostic data, not a graphics fix.')
}
$Out.Add('privacy=Only aggregate integers and fixed messages; raw lines and private paths excluded.')
$Out | Set-Content -LiteralPath (Join-Path $Upload 'E070-anonymous-counts.txt') -Encoding UTF8
Compress-Archive -Path (Join-Path $Upload '*') -DestinationPath $Zip -Force -ErrorAction Stop
Write-Host 'E-070 read-only offline scan COMPLETE. The game was not started.'
Write-Host ('BVH events: ' + $Stats['bvh_builder_info_lines'] +
            ', anonymous count records: ' + $Stats['anonymous_complete_count_records'])
Write-Host ('Upload this sanitized ZIP privately in ChatGPT: ' + $Zip)
