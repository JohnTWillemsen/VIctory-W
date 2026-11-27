#Requires -Version 5.1
# E-075 pure/offline numeric log parser. This script never copies raw log text.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$LogFile,
    [Parameter(Mandatory=$true)][string]$OutputFile
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    throw 'Local private log file not found.'
}

function Clean-E075Line {
    param([string]$Line)
    # Original tracing may color field keys, delimiters and values separately.
    $L = [regex]::Replace($Line, '\x1b\[[0-?]*[ -/]*[@-~]', '')
    return [regex]::Replace($L, '\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)', '')
}

function Read-E075Count {
    param([string]$Line,[string]$Field)
    $M = [regex]::Match($Line,
        '(?<![A-Za-z0-9_])' + [regex]::Escape($Field) + '\s*[=:]\s*(\d+)')
    if (-not $M.Success) { return $null }
    return [uint64]::Parse($M.Groups[1].Value)
}

$StateKeys = @('pipelines','made','refused','dropped')
$CategoryKeys = @('shader_translation','host_pipeline','pending')
$ReasonKeys = @('large_group','implicit_sample','cross_half_lds','mask_data','other')
$Data = [ordered]@{
    format = 'E075-anonymous-numeric-only-v1'
    lines_scanned = 0
    terminal_control_lines = 0
    bvh_status_lines = 0
    bvh_status_complete = 0
    bvh_category_lines = 0
    bvh_category_complete = 0
    bvh_reason_lines = 0
    bvh_reason_complete = 0
    shader_translation_warning_lines = 0
    heap_warning_lines = 0
}
foreach ($Name in ($StateKeys + $CategoryKeys + $ReasonKeys)) {
    $Data['last_' + $Name] = 'not_observed'
}
$Reader = New-Object System.IO.StreamReader($LogFile)
try {
    while ($null -ne ($Raw = $Reader.ReadLine())) {
        $Data['lines_scanned']++
        $Line = Clean-E075Line $Raw
        if ($Line -cne $Raw) { $Data['terminal_control_lines']++ }
        if ($Line.Contains("shader does not translate; its pipelines' draws are dropped")) {
            $Data['shader_translation_warning_lines']++
        }
        if ($Line.Contains('title slot past the host heap')) {
            $Data['heap_warning_lines']++
        }
        $Kind = $null
        $Keys = @()
        if ($Line.Contains('BVH builder unavailable pipeline categories (anonymous)')) {
            $Kind = 'bvh_category'
            $Keys = $CategoryKeys
        }
        elseif ($Line.Contains('BVH shader translator failure classes (anonymous)')) {
            $Kind = 'bvh_reason'
            $Keys = $ReasonKeys
        }
        elseif ($Line.Contains('BVH builder ') -and $Line.Contains('pipelines=')) {
            $Kind = 'bvh_status'
            $Keys = $StateKeys
        }
        if ($null -eq $Kind) { continue }
        $Data[$Kind + '_lines']++
        $Fields = @{}
        foreach ($Name in $Keys) {
            $Count = Read-E075Count $Line $Name
            if ($null -ne $Count) { $Fields[$Name] = $Count }
        }
        if ($Fields.Count -eq $Keys.Count) {
            $Data[$Kind + '_complete']++
            foreach ($Name in $Keys) { $Data['last_' + $Name] = $Fields[$Name] }
        }
    }
}
finally { $Reader.Dispose() }

# Deliberately emit only a fixed set of keys and integer literals / not_observed.
$Lines = New-Object System.Collections.Generic.List[string]
foreach ($Name in $Data.Keys) {
    $Lines.Add($Name + '=' + [string]$Data[$Name])
}
if ([int]$Data['bvh_reason_complete'] -eq 0) {
    $Lines.Add('interpretation=bvh_reason_histogram_not_observed_not_zero')
}
else {
    $Lines.Add('interpretation=anonymous_bvh_reason_histogram_recorded_not_a_rendering_fix')
}
$Lines.Add('privacy=no_raw_log_lines_or_paths_or_shader_ids_copied')
$Parent = Split-Path -Parent $OutputFile
if ($Parent) { New-Item -ItemType Directory -Force -Path $Parent | Out-Null }
$Lines | Set-Content -LiteralPath $OutputFile -Encoding UTF8
Write-Host ('E075 anonymous category records: ' + $Data['bvh_category_complete'] +
    '; reason histograms: ' + $Data['bvh_reason_complete'] + '.')
