#Requires -Version 5.1
# E082: OFFLINE-ONLY refinement of E078 title-wide shader warnings.
# Reads existing private logs and uploads only anonymous numeric counts.
[CmdletBinding()]
param([string]$ReportRoot='C:\VIctory-Tests',[string]$RunFolder='')
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
if (-not (Test-Path -LiteralPath $ReportRoot -PathType Container)) {
    throw 'Report root does not exist. No title was launched.'
}
if ($RunFolder) {
    if (-not (Test-Path -LiteralPath $RunFolder -PathType Container)) {
        throw 'Private E078 run folder not found.'
    }
    $Selected=(Resolve-Path -LiteralPath $RunFolder).ProviderPath
}
else {
    $Selected=$null
    $Reports=@(Get-ChildItem -LiteralPath $ReportRoot -Directory |
        Where-Object { $_.Name -like 'E078-RTX5090-BVH-reason-reuse-*' } |
        Sort-Object LastWriteTime -Descending)
    foreach ($Candidate in $Reports) {
        $Probe=Join-Path $Candidate.FullName 'PRIVATE-raw-logs-do-not-upload\title-stderr-private.txt'
        if (Test-Path -LiteralPath $Probe -PathType Leaf) {
            $Selected=$Candidate.FullName
            break
        }
    }
    if (-not $Selected) {
        throw 'No E078 raw log folder found. Supply -RunFolder if it was moved.'
    }
}
$Private=Join-Path $Selected 'PRIVATE-raw-logs-do-not-upload'
$Sources=@()
foreach ($Name in @('title-stderr-private.txt','title-stdout-private.txt')) {
    $P=Join-Path $Private $Name
    if (Test-Path -LiteralPath $P -PathType Leaf) { $Sources+=$P }
}
if ($Sources.Count -eq 0) { throw 'E078 raw logs missing; ZIP alone is insufficient.' }
function Clean-E082Line([string]$Value) {
    $Clean=[regex]::Replace($Value,'\x1b\[[0-?]*[ -/]*[@-~]','')
    return [regex]::Replace($Clean,'\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)','')
}
function Read-E082Count([string]$Line,[string]$Field) {
    $Pattern='(?<![A-Za-z0-9_])'+[regex]::Escape($Field)+'\s*[=:]\s*(\d+)'
    $Match=[regex]::Match($Line,$Pattern)
    if (-not $Match.Success) { return $null }
    return [uint64]::Parse($Match.Groups[1].Value)
}
$BVHKeys=@('large_group','implicit_sample','cross_half_lds','mask_data','other')
$Stats=[ordered]@{
    format='E082-anonymous-offline-v1'
    source_files=[uint64]0
    lines_scanned=[uint64]0
    ansi_lines=[uint64]0
    title_shader_warning_lines=[uint64]0
    title_warning_large_group=[uint64]0
    title_warning_implicit_derivative=[uint64]0
    title_warning_lane_mask_data=[uint64]0
    title_warning_ds_permute=[uint64]0
    title_warning_cross_half_phrase=[uint64]0
    title_warning_whole_wave_phrase=[uint64]0
    title_warning_other_lds_phrase=[uint64]0
    title_warning_other_unclassified=[uint64]0
    bvh_reason_markers=[uint64]0
    bvh_reason_complete=[uint64]0
    bvh_reason_incomplete=[uint64]0
    last_bvh_large_group='not_observed'
    last_bvh_implicit_sample='not_observed'
    last_bvh_cross_half_lds='not_observed'
    last_bvh_mask_data='not_observed'
    last_bvh_other='not_observed'
}
foreach ($Source in $Sources) {
    $Stats['source_files']++
    $Reader=New-Object System.IO.StreamReader($Source)
    try {
        while ($null -ne ($RawLine=$Reader.ReadLine())) {
            $Stats['lines_scanned']++
            $Line=Clean-E082Line $RawLine
            if ($Line -cne $RawLine) { $Stats['ansi_lines']++ }
            if ($Line.Contains('BVH shader translator failure classes (anonymous)')) {
                $Stats['bvh_reason_markers']++
                $Fields=@{}
                foreach ($Key in $BVHKeys) {
                    $Count=Read-E082Count $Line $Key
                    if ($null -ne $Count) { $Fields[$Key]=$Count }
                }
                if ($Fields.Count -eq $BVHKeys.Count) {
                    $Stats['bvh_reason_complete']++
                    foreach ($Key in $BVHKeys) { $Stats['last_bvh_'+$Key]=$Fields[$Key] }
                }
                else { $Stats['bvh_reason_incomplete']++ }
            }
            if (-not $Line.Contains("shader does not translate; its pipelines' draws are dropped")) {
                continue
            }
            # Each title-WIDE warning goes to one bucket. Cannot prove BVH membership.
            $Stats['title_shader_warning_lines']++
            $Lower=$Line.ToLowerInvariant()
            if ($Lower.Contains('group of more than 64 threads')) {
                $Stats['title_warning_large_group']++
            }
            elseif ($Lower.Contains('implicit-derivative')) {
                $Stats['title_warning_implicit_derivative']++
            }
            elseif ($Lower.Contains('lane mask read as data')) {
                $Stats['title_warning_lane_mask_data']++
            }
            elseif ($Lower.Contains('ds_permute')) {
                $Stats['title_warning_ds_permute']++
            }
            elseif ($Lower.Contains('cross') -and $Lower.Contains('half')) {
                $Stats['title_warning_cross_half_phrase']++
            }
            elseif ($Lower.Contains('whole-wave')) {
                $Stats['title_warning_whole_wave_phrase']++
            }
            elseif ($Lower.Contains('lds')) {
                $Stats['title_warning_other_lds_phrase']++
            }
            else { $Stats['title_warning_other_unclassified']++ }
        }
    }
    finally { $Reader.Dispose() }
}
$Sub=[uint64]0
foreach ($Key in @('title_warning_large_group','title_warning_implicit_derivative',
    'title_warning_lane_mask_data','title_warning_ds_permute',
    'title_warning_cross_half_phrase','title_warning_whole_wave_phrase',
    'title_warning_other_lds_phrase','title_warning_other_unclassified')) {
    $Sub += [uint64]$Stats[$Key]
}
if ($Sub -ne [uint64]$Stats['title_shader_warning_lines']) {
    throw 'Internal classification mismatch. No ZIP created.'
}
$Id='E082-offline-shader-error-audit-'+(Get-Date -Format 'yyyyMMdd-HHmmss')
$Folder=Join-Path $ReportRoot $Id
$Public=Join-Path $Folder 'upload-only'
$Zip=Join-Path $ReportRoot ($Id+'-summary.zip')
New-Item -ItemType Directory -Force -Path $Public | Out-Null
$Out=New-Object System.Collections.Generic.List[string]
foreach ($Key in $Stats.Keys) {
    $Out.Add($Key+'='+[string]$Stats[$Key])
}
$Out.Add('title_warning_scope=all_title_shaders_not_bvh_attribution')
$Out.Add('bvh_reason_scope=first_failed_shader_per_refused_bvh_pipeline')
$Out.Add('no_game_or_gpu_execution=true')
$Out.Add('raw_paths_logs_shaders_excluded=true')
$Out | Set-Content -LiteralPath (Join-Path $Public 'E082-anonymous-counts.txt') -Encoding UTF8
Compress-Archive -Path (Join-Path $Public '*') -DestinationPath $Zip -Force
Write-Host 'E082 offline scan complete. No game run, no compilation.'
Write-Host ('Title-wide warning lines: '+$Stats['title_shader_warning_lines'])
Write-Host ('Complete BVH reason records: '+$Stats['bvh_reason_complete'])
Write-Host ('UPLOAD ONLY THIS SUMMARY ZIP IN CHATGPT: '+$Zip)
