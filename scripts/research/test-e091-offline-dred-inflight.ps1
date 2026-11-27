#Requires -Version 5.1
$ErrorActionPreference='Stop'
$Root=Join-Path $env:RUNNER_TEMP ('E091-synthetic-'+[guid]::NewGuid().ToString('N'))
$Dir=Join-Path $Root 'E087-supervised-20261127-015632-f1b10c'
$Priv=Join-Path $Dir 'PRIVATE-logs-do-not-upload'
$Safe=Join-Path $Dir 'upload-only'
New-Item -ItemType Directory -Path $Priv,$Safe -Force | Out-Null
$Path=(Resolve-Path 'scripts/research/owner-e091-dred-inflight-offline.ps1').ProviderPath
$Tokens=$null;$Errors=$null
[void][Management.Automation.Language.Parser]::ParseFile($Path,[ref]$Tokens,[ref]$Errors)
if($Errors.Count){throw ('E091 WinPS5.1 parse failed: '+($Errors | Out-String))}
$Code=Get-Content -LiteralPath $Path -Raw
foreach($Forbidden in @('Start-Process','Invoke-WebRequest','Invoke-RestMethod','victory.exe run','VICTORY_GAME_DIR')) {
  if($Code.Contains($Forbidden)){throw ('Non-offline operation in script: '+$Forbidden)}
}
[IO.File]::WriteAllLines((Join-Path $Safe 'E087-anonymous-status.txt'),[string[]]@('format=E087-durable-gpu-supervisor-v1','status=TITLE_EXITED'),[Text.UTF8Encoding]::new($false))
$Secret='fake-private-title-shader-dd11447700aabbee'
[IO.File]::WriteAllLines((Join-Path $Priv 'title-stderr-private.txt'),[string[]]@(
  ('2026 WARN victory_gpu::host: slow host submission ms=11777 lists=1 private: '+$Secret),
  '2026 ERROR device removed: page fault at 0x987654321; inside freed [private object]; inside [other object]',
  (('DRED: a list stopped at command 4 of 10 (op 6); commands 2..8 between its barriers; command 5 (op 6): dispatch 5x4 [compute '+$Secret+']; command 6 (op 5): execute indirect '+$Secret),
  (('DRED: a list stopped at command 4993 of 11602 (op 0); commands 4900..5000 between its barriers; command 4990 (op 3): draw 3 vertices ['+$Secret+']; command 4991 (op 9): copy resource'),
  'WARN no breadcrumb node named one of our lists',
  'WARN D3D12: debug text id=55 severity=1',
  'WARN fault at source +0xabc'
),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllLines((Join-Path $Priv 'title-stdout-private.txt'),[string[]]@('title exit 0x887A0005','this is a separate line'),[Text.UTF8Encoding]::new($false))
& $Path -RunFolder $Dir
$Zip=Join-Path $Dir 'E091-anonymous-inflight.zip'
if(-not(Test-Path -LiteralPath $Zip)){throw 'Missing E091 ZIP'}
$Extract=Join-Path $Root 'extract'
Expand-Archive -LiteralPath $Zip -DestinationPath $Extract -Force
$Found=@(Get-ChildItem -LiteralPath $Extract -File)
if($Found.Count -ne 1 -or $Found[0].Name -cne 'E091-anonymous-inflight.txt'){throw 'Unexpected E091 ZIP files'}
$Text=Get-Content -LiteralPath $Found[0].FullName -Raw
foreach($Expected in @(
'format=E091-offline-dred-inflight-v1',
'scanned_files=2',
'scanned_lines=9',
'dred_stopped_command_markers=2',
'dred_first_stopped_index=4',
'dred_first_stopped_total=10',
'dred_first_stopped_op=6',
'dred_first_stopped_op_present=1',
'dred_last_stopped_index=4993',
'dred_last_stopped_total=11602',
'dred_last_stopped_op=0',
'dred_last_stopped_op_present=1',
'dred_stopped_op_setmarker=1',
'dred_stopped_op_dispatch=1',
'dred_inflight_barrier_intervals=2',
'dred_shortest_barrier_span=6',
'dred_longest_barrier_span=100',
'dred_inflight_ops=4',
'dred_inflight_dispatch_ops=1',
'dred_inflight_draw_ops=1',
'dred_inflight_execute_indirect_ops=1',
'dred_inflight_copy_ops=1',
'dred_inflight_marker_dispatch_labels=1',
'dred_inflight_marker_draw_labels=1',
'page_fault_address_marker_lines=1',
'page_fault_recently_freed_marker_lines=1',
'page_fault_existing_allocation_marker_lines=1',
'dred_unmatched_host_list_marker_lines=1',
'd3d12_debug_message_lines=1',
'd3d12_debug_error_severity_lines=1',
'slow_submission_ms_parsed=1',
'slow_submission_max_ms=11777',
'slow_submission_max_lists=1'
)) {
 if(-not $Text.Contains($Expected)){throw ('Missing E091 expected metric '+$Expected+' in '+$Text)}
}
foreach($Bad in @($Secret,'987654321','0xabc','PRIVATE-logs','title-stderr',$Root)) {
 if($Text.Contains($Bad)){throw 'Sensitive source data leaked into E091 ZIP'}
}
foreach($Line in $Text -split '\r?\n') {
 if($Line.Trim() -and $Line -notmatch '^[a-z0-9_]+=[a-zA-Z0-9_-]*$'){throw ('Unsafe E091 output line: '+$Line)}
}
# Reuse without mutating source logs; same ZIP result.
& $Path -RunFolder $Dir
$Again=Join-Path $Root 'extract-again'
Expand-Archive -LiteralPath $Zip -DestinationPath $Again -Force
if((Get-Content -LiteralPath (Join-Path $Again 'E091-anonymous-inflight.txt') -Raw) -cne $Text){throw 'Non-repeatable E091 result'}
$Empty=Join-Path $Root 'E087-supervised-20261127-015633-ffffff'
New-Item -ItemType Directory -Path (Join-Path $Empty 'PRIVATE-logs-do-not-upload'),(Join-Path $Empty 'upload-only') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $Safe 'E087-anonymous-status.txt') -Destination (Join-Path $Empty 'upload-only\E087-anonymous-status.txt')
$Thrown=$false
try{& $Path -RunFolder $Empty | Out-Null}catch{$Thrown=$true}
if(-not $Thrown){throw 'Missing logs were not rejected'}
Write-Host 'E091 Windows 5.1 parse, stopped/between-barrier ops, page fault, privacy, repeatability, missing-logs: 6/6 PASS'
