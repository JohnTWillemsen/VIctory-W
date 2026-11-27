#Requires -Version 5.1
# E100 - summarize existing E087 D3D12 diagnostic IDs and DRED dispatch group shapes.
# Purely offline. Only fixed integers; never emit diagnostic messages, shader IDs or memory contents.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunFolder)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$Run=(Resolve-Path -LiteralPath $RunFolder -ErrorAction Stop).ProviderPath
if([IO.Path]::GetFileName($Run.TrimEnd('\','/')) -cnotmatch '^E087-supervised-[0-9]{8}-[0-9]{6}-[a-f0-9]{6}$'){
    throw 'Expected a supervised E087 run directory'
}
$Private=Join-Path $Run 'PRIVATE-logs-do-not-upload'
$Safe=Join-Path $Run 'upload-only'
$Status=Join-Path $Safe 'E087-anonymous-status.txt'
if(-not(Test-Path -LiteralPath $Status -PathType Leaf) -or
   -not(Get-Content -LiteralPath $Status -Raw).Contains('format=E087-durable-gpu-supervisor-v1')){
    throw 'Missing or unexpected E087 anonymous status'
}
$Counts=[ordered]@{
    scanned_files=0
    scanned_lines=0
    d3d12_debug_lines=0
    d3d12_id_parsed_lines=0
    d3d12_id_unparsed_lines=0
    d3d12_severity_0_corruption=0
    d3d12_severity_1_error=0
    d3d12_severity_2_warning=0
    d3d12_severity_3_info=0
    d3d12_severity_4_message=0
    d3d12_severity_missing_or_other=0
    dred_dispatch_op_lines=0
    dred_dispatch_geometry_parsed=0
    dred_dispatch_geometry_unparsed=0
    dispatch_group_1d=0
    dispatch_group_2d=0
    dispatch_group_3d=0
    dispatch_total_groups_small_le64=0
    dispatch_total_groups_mid_65_to4096=0
    dispatch_total_groups_large_gt4096=0
    dispatch_largest_group_count=0
    d3d12_id_622_wave_lane_count=0
    d3d12_id_940_descriptor_dimension=0
}
$IdCounts=@{}
$IdPattern=[regex]::new('\\bid\\s*=\\s*(?<id>[0-9]+)\\b',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
$SeverityPattern=[regex]::new('\\bseverity\\s*=\\s*(?<n>[0-9]+)\\b',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
$DispatchLine=[regex]::new('(?:^|;\\s*)command\\s+[0-9]+\\s+\\(op\\s+6\\):\\s*dispatch\\b',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
$DispatchPattern=[regex]::new('(?:^|;\\s*)command\\s+[0-9]+\\s+\\(op\\s+6\\):\\s*dispatch\\s+(?<x>[0-9]+)x(?<y>[0-9]+)x(?<z>[0-9]+)(?=\\s|$)',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
foreach($Name in @('title-stdout-private.txt','title-stderr-private.txt')){
    $P=Join-Path $Private $Name
    if(-not(Test-Path -LiteralPath $P -PathType Leaf)){continue}
    $Counts['scanned_files']++
    $FS=$null; $Reader=$null
    try {
        $FS=[IO.FileStream]::new($P,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
        $Reader=[IO.StreamReader]::new($FS)
        while($null -ne ($Line=$Reader.ReadLine())){
            $Counts['scanned_lines']++
            if($Line -match '(?i)\\bD3D12:'){
                $Counts['d3d12_debug_lines']++
                $I=$IdPattern.Match($Line)
                if($I.Success){
                    $IntId=0
                    if([int]::TryParse($I.Groups['id'].Value,[ref]$IntId) -and $IntId -ge 0 -and $IntId -le 65535) {
                        $Counts['d3d12_id_parsed_lines']++
                        if(-not $IdCounts.ContainsKey($IntId)){$IdCounts[$IntId]=0}
                        $IdCounts[$IntId]++
                        if($IntId -eq 622){$Counts['d3d12_id_622_wave_lane_count']++}
                        if($IntId -eq 940){$Counts['d3d12_id_940_descriptor_dimension']++}
                    } else {$Counts['d3d12_id_unparsed_lines']++}
                } else {$Counts['d3d12_id_unparsed_lines']++}
                $S=$SeverityPattern.Match($Line)
                if($S.Success){
                    switch($S.Groups['n'].Value){
                        '0' {$Counts['d3d12_severity_0_corruption']++}
                        '1' {$Counts['d3d12_severity_1_error']++}
                        '2' {$Counts['d3d12_severity_2_warning']++}
                        '3' {$Counts['d3d12_severity_3_info']++}
                        '4' {$Counts['d3d12_severity_4_message']++}
                        default {$Counts['d3d12_severity_missing_or_other']++}
                    }
                } else {$Counts['d3d12_severity_missing_or_other']++}
            }
            $RawMatch=$DispatchLine.Matches($Line)
            if($RawMatch.Count -gt 0){
                $Counts['dred_dispatch_op_lines']+=$RawMatch.Count
                $Matched=$DispatchPattern.Matches($Line)
                $Counts['dred_dispatch_geometry_parsed']+=$Matched.Count
                $Counts['dred_dispatch_geometry_unparsed']+=$RawMatch.Count-$Matched.Count
                foreach($Hit in $Matched){
                    $X=0L;$Y=0L;$Z=0L
                    if(-not([long]::TryParse($Hit.Groups['x'].Value,[ref]$X) -and
                            [long]::TryParse($Hit.Groups['y'].Value,[ref]$Y) -and
                            [long]::TryParse($Hit.Groups['z'].Value,[ref]$Z))){
                        continue
                    }
                    if($Z -gt 1){$Counts['dispatch_group_3d']++}
                    elseif($Y -gt 1){$Counts['dispatch_group_2d']++}
                    else {$Counts['dispatch_group_1d']++}
                    $Product=[double]$X*[double]$Y*[double]$Z
                    if($Product -le 64){$Counts['dispatch_total_groups_small_le64']++}
                    elseif($Product -le 4096){$Counts['dispatch_total_groups_mid_65_to4096']++}
                    else {$Counts['dispatch_total_groups_large_gt4096']++}
                    if($Product -gt $Counts['dispatch_largest_group_count']){
                        $Counts['dispatch_largest_group_count']=[long][Math]::Min($Product,[double][long]::MaxValue)
                    }
                }
            }
        }
    } finally {
        if($null -ne $Reader){$Reader.Dispose()}
        elseif($null -ne $FS){$FS.Dispose()}
    }
}
if($Counts['scanned_files'] -eq 0){throw 'Missing expected private E087 logs; no output generated'}
$Rows=[Collections.Generic.List[string]]::new()
foreach($S in @(
    'format=E100-anonymous-d3d12-ids-dispatch-geometry-v1'
    'mode=existing_logs_only'
    'title_launched=false'
    'privacy=fixed_integer_fields_no_source_text'
    'd3d12_id_source=public_D3D12_MESSAGE_ID'
    'note=counts_are_log_occurrences_not_unique_gpu_events'
)){$Rows.Add($S)}
foreach($Key in $Counts.Keys){$Rows.Add(('{0}={1}' -f $Key,[long]$Counts[$Key]))}
$Top=@($IdCounts.GetEnumerator() | Sort-Object -Property @{Expression={$_.Value};Descending=$true},@{Expression={$_.Key};Descending=$false} | Select-Object -First 12)
for($K=0;$K -lt 12;$K++){
    $N=$K+1
    $ID=if($K -lt $Top.Count){[int]$Top[$K].Key}else{-1}
    $Occurrences=if($K -lt $Top.Count){[long]$Top[$K].Value}else{0}
    $Rows.Add(('d3d12_top_{0:00}_id={1}' -f $N,$ID))
    $Rows.Add(('d3d12_top_{0:00}_count={1}' -f $N,$Occurrences))
}
New-Item -ItemType Directory -Path $Safe -Force | Out-Null
$Txt=Join-Path $Safe 'E100-anonymous-d3d12-ids.txt'
[IO.File]::WriteAllLines($Txt,$Rows,[Text.UTF8Encoding]::new($false))
$Zip=Join-Path $Run 'E100-anonymous-d3d12-ids.zip'
$Next=Join-Path $Run 'E100-anonymous-d3d12-ids.next.zip'
if([IO.File]::Exists($Next)){[IO.File]::Delete($Next)}
Compress-Archive -LiteralPath $Txt -DestinationPath $Next -Force
if([IO.File]::Exists($Zip)){
    $Backup=$Zip+'.backup'
    if([IO.File]::Exists($Backup)){[IO.File]::Delete($Backup)}
    [IO.File]::Replace($Next,$Zip,$Backup)
}else{[IO.File]::Move($Next,$Zip)}
Write-Host ('E100 analyzed '+$Counts['scanned_lines']+' existing log lines; NO title launch.')
Write-Host ('UPLOAD ONLY: '+$Zip)
Write-Host 'Keep PRIVATE logs and game files off GitHub.'
