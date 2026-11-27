#Requires -Version 5.1
# E091: Extract only anonymous D3D12 op categories from already-written E087 private logs.
# No game launch; no executable, asset, shader dump, network or environment changes.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunFolder)

$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$Folder=(Resolve-Path -LiteralPath $RunFolder -ErrorAction Stop).ProviderPath
if ([IO.Path]::GetFileName($Folder.TrimEnd('\','/')) -cnotmatch '^E087-supervised-[0-9]{8}-[0-9]{6}-[0-9a-f]{6}$') { throw 'Expected an E087 supervised run directory.' }
$Private=Join-Path $Folder 'PRIVATE-logs-do-not-upload'
$Safe=Join-Path $Folder 'upload-only'
$StatusPath=Join-Path $Safe 'E087-anonymous-status.txt'
if (-not (Test-Path -LiteralPath $StatusPath -PathType Leaf)) { throw 'E087 status file missing.' }
if (-not (Get-Content -LiteralPath $StatusPath -Raw).Contains('format=E087-durable-gpu-supervisor-v1')) { throw 'Unexpected E087 report format.' }

$M=[ordered]@{
  scanned_files=0
  scanned_lines=0
  dred_stopped_command_markers=0
  dred_first_stopped_index=0
  dred_first_stopped_total=0
  dred_first_stopped_op=0
  dred_first_stopped_op_present=0
  dred_last_stopped_index=0
  dred_last_stopped_total=0
  dred_last_stopped_op=0
  dred_last_stopped_op_present=0
  dred_stopped_op_setmarker=0
  dred_stopped_op_dispatch=0
  dred_stopped_op_draw=0
  dred_stopped_op_execute_indirect=0
  dred_stopped_op_other=0
  dred_inflight_barrier_intervals=0
  dred_shortest_barrier_span=0
  dred_longest_barrier_span=0
  dred_inflight_ops=0
  dred_inflight_dispatch_ops=0
  dred_inflight_draw_ops=0
  dred_inflight_execute_indirect_ops=0
  dred_inflight_copy_ops=0
  dred_inflight_barrier_ops=0
  dred_inflight_marker_ops=0
  dred_inflight_other_ops=0
  dred_inflight_marker_dispatch_labels=0
  dred_inflight_marker_draw_labels=0
  dred_inflight_marker_copy_labels=0
  page_fault_address_marker_lines=0
  page_fault_existing_allocation_marker_lines=0
  page_fault_recently_freed_marker_lines=0
  page_fault_source_range_marker_lines=0
  dred_unmatched_host_list_marker_lines=0
  no_breadcrumbs_marker_lines=0
  d3d12_debug_message_lines=0
  d3d12_debug_error_severity_lines=0
  slow_submission_lines=0
  slow_submission_ms_parsed=0
  slow_submission_max_ms=0
  slow_submission_lists_parsed=0
  slow_submission_max_lists=0
}
$StopPattern=[regex]::new('a list stopped at command\s+(?<n>[0-9]+)\s+of\s+(?<total>[0-9]+)(?:\s+\(op\s+(?<op>[0-9]+)\))?',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
$BarrierPattern=[regex]::new('commands\s+(?<from>[0-9]+)\.\.(?<to>[0-9]+)\s+between its barriers',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
$InflightPattern=[regex]::new('(?:^|;\s*)command\s+(?<n>[0-9]+)\s+\(op\s+(?<op>[0-9]+)\):\s*(?<note>[^;]*)',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
$Files=@('title-stdout-private.txt','title-stderr-private.txt')
foreach($Name in $Files) {
  $Path=Join-Path $Private $Name
  if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){continue}
  $M['scanned_files']=[long]$M['scanned_files']+1
  $Stream=$null; $Reader=$null
  try {
    $Stream=[IO.FileStream]::new($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    $Reader=[IO.StreamReader]::new($Stream)
    while($null -ne ($Line=$Reader.ReadLine())) {
      $M['scanned_lines']=[long]$M['scanned_lines']+1
      foreach($Hit in $StopPattern.Matches($Line)) {
        $N=[int]$Hit.Groups['n'].Value
        $Total=[int]$Hit.Groups['total'].Value
        $HasOp=$Hit.Groups['op'].Success
        $Op=if($HasOp){[int]$Hit.Groups['op'].Value}else{0}
        if($M['dred_stopped_command_markers'] -eq 0) {
          $M['dred_first_stopped_index']=$N; $M['dred_first_stopped_total']=$Total
          $M['dred_first_stopped_op']=$Op; $M['dred_first_stopped_op_present']=[int]$HasOp
        }
        $M['dred_stopped_command_markers']=[long]$M['dred_stopped_command_markers']+1
        $M['dred_last_stopped_index']=$N; $M['dred_last_stopped_total']=$Total
        $M['dred_last_stopped_op']=$Op; $M['dred_last_stopped_op_present']=[int]$HasOp
        $Key=switch ($Op) {
          0 {'dred_stopped_op_setmarker'}
          6 {'dred_stopped_op_dispatch'}
          {$_ -eq 3 -or $_ -eq 4} {'dred_stopped_op_draw'}
          5 {'dred_stopped_op_execute_indirect'}
          default {'dred_stopped_op_other'}
        }
        if(-not $HasOp){$Key='dred_stopped_op_other'}
        $M[$Key]=[long]$M[$Key]+1
      }
      foreach($Hit in $BarrierPattern.Matches($Line)) {
        $From=[long]$Hit.Groups['from'].Value; $To=[long]$Hit.Groups['to'].Value
        if($To -lt $From){continue}
        $Span=$To-$From
        $M['dred_inflight_barrier_intervals']=[long]$M['dred_inflight_barrier_intervals']+1
        if($M['dred_inflight_barrier_intervals'] -eq 1 -or $Span -lt $M['dred_shortest_barrier_span']){$M['dred_shortest_barrier_span']=$Span}
        if($Span -gt $M['dred_longest_barrier_span']){$M['dred_longest_barrier_span']=$Span}
      }
      foreach($Hit in $InflightPattern.Matches($Line)) {
        $Op=[int]$Hit.Groups['op'].Value
        $M['dred_inflight_ops']=[long]$M['dred_inflight_ops']+1
        $Key=switch($Op) {
          6 {'dred_inflight_dispatch_ops'}
          {$_ -eq 3 -or $_ -eq 4} {'dred_inflight_draw_ops'}
          5 {'dred_inflight_execute_indirect_ops'}
          {$_ -ge 7 -and $_ -le 11} {'dred_inflight_copy_ops'}
          15 {'dred_inflight_barrier_ops'}
          0 {'dred_inflight_marker_ops'}
          default {'dred_inflight_other_ops'}
        }
        $M[$Key]=[long]$M[$Key]+1
        $Note=$Hit.Groups['note'].Value
        if($Note -match '^\s*dispatch\b'){$M['dred_inflight_marker_dispatch_labels']++}
        if($Note -match '^\s*draw\b'){$M['dred_inflight_marker_draw_labels']++}
        if($Note -match '^\s*copy\b'){$M['dred_inflight_marker_copy_labels']++}
      }
      if($Line -match '(?i)page fault at\s+0x[0-9a-f]+'){$M['page_fault_address_marker_lines']++}
      if($Line -match '(?i);\s+inside\s+\['){$M['page_fault_existing_allocation_marker_lines']++}
      if($Line -match '(?i);\s+inside freed\s+\['){$M['page_fault_recently_freed_marker_lines']++}
      if($Line -match '(?i)\(fault\s+(?:at|below|past)\s+(?:source|its source)'){$M['page_fault_source_range_marker_lines']++}
      if($Line -match '(?i)no breadcrumb node named one of our lists'){$M['dred_unmatched_host_list_marker_lines']++}
      if($Line -match '(?i)no breadcrumbs'){$M['no_breadcrumbs_marker_lines']++}
      if($Line -match '(?i)\bD3D12:') {
        $M['d3d12_debug_message_lines']++
        if($Line -match '\bseverity=([0-9]+)' -and [int]$Matches[1] -le 1){$M['d3d12_debug_error_severity_lines']++}
      }
      if($Line -match '(?i)slow host submission') {
        $M['slow_submission_lines']++
        if($Line -match '\bms\s*=\s*(\d+)') {
          $M['slow_submission_ms_parsed']++
          $Ms=[long]$Matches[1]
          if($Ms -gt $M['slow_submission_max_ms']){$M['slow_submission_max_ms']=$Ms}
        }
        if($Line -match '\blists\s*=\s*(\d+)') {
          $M['slow_submission_lists_parsed']++
          $Lists=[long]$Matches[1]
          if($Lists -gt $M['slow_submission_max_lists']){$M['slow_submission_max_lists']=$Lists}
        }
      }
    }
  } finally {
    if($null -ne $Reader){$Reader.Dispose()}
    elseif($null -ne $Stream){$Stream.Dispose()}
  }
}
if($M['scanned_files'] -eq 0){throw 'No expected E087 private title logs found.'}
$Output=[Collections.Generic.List[string]]::new()
foreach($Head in @('format=E091-offline-dred-inflight-v1','mode=existing_logs_only','title_launched=false','privacy=fixed_integer_fields_no_source_text','stop_op_reference=Microsoft_D3D12_AUTO_BREADCRUMB_OP')){$Output.Add($Head)}
foreach($Key in $M.Keys){$Output.Add(('{0}={1}' -f $Key,[long]$M[$Key]))}
New-Item -ItemType Directory -Path $Safe -Force | Out-Null
$TextFile=Join-Path $Safe 'E091-anonymous-inflight.txt'
[IO.File]::WriteAllLines($TextFile,$Output,[Text.UTF8Encoding]::new($false))
$Zip=Join-Path $Folder 'E091-anonymous-inflight.zip'
$Next=Join-Path $Folder 'E091-anonymous-inflight.next.zip'
if([IO.File]::Exists($Next)){[IO.File]::Delete($Next)}
Compress-Archive -LiteralPath $TextFile -DestinationPath $Next -Force
if([IO.File]::Exists($Zip)){
    $Backup=$Zip+'.backup'
    if([IO.File]::Exists($Backup)){[IO.File]::Delete($Backup)}
    [IO.File]::Replace($Next,$Zip,$Backup)
}else{[IO.File]::Move($Next,$Zip)}
Write-Host ('E091 offline classification completed across '+$M['scanned_lines']+' existing log lines.')
Write-Host ('UPLOAD ONLY: '+$Zip)
Write-Host 'Do not upload private raw logs, shader hashes, addresses, executable, or game content.'
